---
theme: juejin
---
# 引言

&emsp;&emsp;一直对缓存很感兴趣，之前看的是`TMCache`，但是`TMCache`存在死锁的问题，并且`TMCache`也没有继续维护，不过PIN团队基于`TMCache`重写了一套缓存框架`PINCache`。
 在看`PINCache`前，先推荐下一篇非常优秀的文章：[TMCache源码分析](https://chengzhipeng.github.io/2016/02/27/TMCache%E6%BA%90%E7%A0%81%E5%88%86%E6%9E%90%E4%B9%8BTMMemoryCache%E5%86%85%E5%AD%98%E7%BC%93%E5%AD%98/)，可以先看完这篇文章后再去阅读`PINCahce`的源码。
 
 &emsp;&emsp;今天主要讲的内容是`PINCache`中的核心`PINOperationQueue`。我们都知道`NSOperationQueue`是基于`GCD`实现的，但是要你基于GCD来实现一套`NSOperationQueue`，你会怎么做呢？`PINOperationQueue`为我们提供了参考。
 
&emsp;&emsp;为了更深刻的理解`PINOperationQueue`，我仿写了`Swift`版的`PINOperationQueue`，名字是`BEOperationQueue`。[PINCahce](https://github.com/pinterest/PINCache)和[BECache](https://github.com/CoderHuiYu/BECache)的GitHub地址。本文是以`BEOperationQueue`的代码作为基础来进行分析。

## 1.BEOperatiopnQueue(PINOperationQueue)
### 1.核心属性
#### 1.1 存储operation的数组
- queueOperations
- lowPriorityOperations
- defaultPriorityOperations
- highPriorityOperations
 包括低优先级、default优先级、高优先级数组以及总数组
 #### 1.2 队列和信号量
- serialQueue： DispatchQueue(label: "BEOperation Serial Queue")
- semaphoreQueue ： DispatchQueue(label: "BEOperation Semaphore Queue")
- concurrentQueue ：DispatchQueue(label: "BEOperation Concurrent Queue", attributes: .concurrent)
 - concurrentSemaphore: DispatchSemaphore
 
 2个串行队列和一个并发队列以及一个信号量
 
### 2.核心方法
#### 1.1 func scheduleOperation

&emsp;&emsp;`BEOperatiopnQueue`初始化后就会执行这个方法进行任务的调度和执行，所以从`scheduleOperation`方法开始，执行后

```swift
func scheduleOperation(with workItem: @escaping OperationItem, priority: BEOperationQueuePriority = .default) -> BEOperationReference{
    let operation = BEOperation.operation(with: priority, reference: nextOperationReference(), workitem: workItem)
    lockOperation { locked_addOperation(with: operation) }
    scheduleNextOperation(with: false)
    return operation.reference!
}
```
1. 先将传进来的任务包装成BEOperation对象
2. 然后根据优先级，加入到low、default、high优先级数组中
3. 开始执行，也就是调用`scheduleNextOperation` 这个方法

&emsp;&emsp;`scheduleNextOperation`是整个OPeratiuonQueue的核心方法，也是任务执行的中枢，swift版的代码就简短的三十几行，但是却十分的高效。因为这个方法不好理解，我也是反复调试和思考，才慢慢的理解，记录一下自己的理解过程，有不对的地方，欢迎指出。

#### 1.2 func scheduleNextOperation
&emsp;&emsp;`scheduleNextOperation`是整个OPeratiuonQueue的核心方法，负责任务的调度和执行，主要分上部分和下部分，被`if onlyCheckSerial { return }`这段代码隔断，其中上半部分有一个递归调用来进行驱动。
```swift
private func scheduleNextOperation(with onlyCheckSerial: Bool) {
    lock()
    if serialQueueBusy == false {
        if let operation = locked_nextOperationByQueue() {
            serialQueueBusy = true
            serialQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.lockOperation { self.serialQueueBusy = false }
                self.scheduleNextOperation(with: true) // 递归
            }
        }
    }
    unlock()
    
    if onlyCheckSerial { return }
    if maxConcurrentOperations < 2 { return }
    semaphoreQueue.async {
        self.concurrentSemaphore?.wait()
        self.lock()
        let op = self.locked_nextOperationByPriority()
        self.unlock()
        if let operation = op {
            self.concurrentQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.concurrentSemaphore?.signal()
            }
        } else {
            self.concurrentSemaphore?.signal()
        }
    }
}
```

## 2.scheduleNextOperation(with onlyCheckSerial: Bool)方法分析
&emsp;&emsp;为了更直观的理解`scheduleNextOperation`的执行流程，我在测试代码中添加9个任务。`test()`方法调用后，经过`scheduleOperation`方法后执行到`scheduleNextOperation(with onlyCheckSerial: Bool)`方法。下面将详细的讲解下任务的执行过程。
```swift
func test() {
    let opQueue =  BEOperationQueue.init(maxConcurrentOperations: 2)
    opQueue.scheduleOperation(with: { sleep(10); print("BE-1-default") }, priority: .default)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-2-high") }, priority: .high)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-3-low") }, priority: .low)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-4-low") }, priority: .low)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-5-low") }, priority: .low)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-6-low") }, priority: .low)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-7-low") }, priority: .low)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-8-high") }, priority: .high)
    opQueue.scheduleOperation(with: { sleep(5); print("BE-9-high") }, priority: .high)
  }
```

**任务执行过程：**
1. 任务1进来后，会进入到下面这段代码

```swift
lock()
    if serialQueueBusy == false {
        if let operation = locked_nextOperationByQueue() {
            serialQueueBusy = true
            serialQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.lockOperation { self.serialQueueBusy = false }
                self.scheduleNextOperation(with: true) // 递归
            }
        }
    }
 unlock()
```
进入后，会将`serialQueueBusy`置为`true`,意思就是串行队列忙；然后`serialQueue`串行队列异步执行任务，任务执行完成后，再将`serialQueueBusy`置为`false`，意思就是串行队列现在不忙了，然后**递归**调用自己，不过参数传的是`true`,意外着不会进入到下面的这段代码。然后递归的取出任务，一次执行一个任务的这样继续用下去，直到没有任务。

```swift
    if onlyCheckSerial { return } // 传true 就直接return了
    if maxConcurrentOperations < 2 { return }
    semaphoreQueue.async {
        self.concurrentSemaphore?.wait()
        self.lock()
        let op = self.locked_nextOperationByPriority()
        self.unlock()
        if let operation = op {
            self.concurrentQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.concurrentSemaphore?.signal()
            }
        } else {
            self.concurrentSemaphore?.signal()
        }
    }
```
2. 经典的来了，就是上述那段代码
当我们一次传9个任务过来的时候，假定我们设置的最大并发量是2。那么开始的时候有一个任务会执行第1步的代码也就是在`serialQueue`串行队列执行，也有的任务会执行下面的这段代码
```swift
    semaphoreQueue.async {
        self.concurrentSemaphore?.wait()
        self.lock()
        let op = self.locked_nextOperationByPriority()
        self.unlock()
        if let operation = op {
            self.concurrentQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.concurrentSemaphore?.signal()
            }
        } else {
            self.concurrentSemaphore?.signal()
        }
    }
```
会先进入`semaphoreQueue` 串行队列里面，每进入一个任务后，`self.concurrentSemaphore?.wait()`，信号量就减1，当进入2个任务后，其它任务就被卡主了，等待信号量大于0。然后任务会被安排在`concurrentQueue`并发队列进行执行，执行完一个就会`self.concurrentSemaphore?.signal()`， 信号量加1，接着就会有任务进入`semaphoreQueue`串行队列里面...继续上述部分。**与此同时**，第一步的递归代码依然在执行，依然在取出任务然后在`serialQueue`中执行。

&emsp;&emsp;至此，scheduleNextOperation(with onlyCheckSerial: Bool)分析完成，其任务的执行流程是如何被驱动的应该很清楚了。

### 3.思考
&emsp;&emsp;那接下来，我们思考一个问题，下面的这段代码中，作者为什么要这样设计？为什么要在串行队列里嵌一个并发队列来执行任务？
```swift
    semaphoreQueue.async {
        self.concurrentSemaphore?.wait()
        self.lock()
        let op = self.locked_nextOperationByPriority()
        self.unlock()
        if let operation = op {
            self.concurrentQueue.async {
                operation.workItems.forEach { $0() }
                self.group.leave()
                self.concurrentSemaphore?.signal()
            }
        } else {
            self.concurrentSemaphore?.signal()
        }
    }
```
思考上述问题前，我先说下我从这个方法里面学到的：

1. 驱动钟数方法，可以灵活的使用递归
2. 信号量和并发队列的合并使用来控制任务的最大并发量
3. 串行队列中嵌套一个并发队列来执行任务的使用

关于第3点，也就是什么要在串行队列里嵌一个并发队列来执行任务？通过调试，我的实验结果：

假设我们去掉上面的`semaphoreQueue.async` 这段代码，也就是直接并发队列执行任务。
我们调用上述的`test()`代码,会发现主线程被卡住，因为每个任务都会`sleep(5)`。

既然这样，那我们就在**子线程（假设是全局并发队列**里面执行`test()`，主线程确实不会被卡主了。但是任务的执行顺序却不是按照我们设定的优先级执行的。因为任务的添加是异步的，导致queueOPerations数组和地、中、高优先级数组里面存储的任务也是不确定，不像在串行队列中，是依次加入的。【因为任务的添加可以很快，但是执行可能会很慢】





