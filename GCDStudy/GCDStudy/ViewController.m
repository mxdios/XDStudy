//
//  ViewController.m
//  GCDStudy
//
//  Created by miaoxiaodong on 2018/4/8.
//  Copyright © 2018年 markmiao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self semaphore];

    [self deadLock];
}
//死锁
- (void)deadLock {
 //在主队列中同步执行，发生死锁问题。2会排在3后面执行，3又要等待2执行完后再执行，所以发生死锁
//    NSLog(@"1");
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        NSLog(@"2");
//    });
//    NSLog(@"3");
    
    //全局并行队列，不会发生死锁。执行顺序123
//    NSLog(@"1");
//    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        NSLog(@"2");
//    });
//    NSLog(@"3");
    
    //会发生死锁，在一个串行队列中，异步任务下执行同步任务会发生死锁。
    NSLog(@"1");
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        NSLog(@"2");
        dispatch_sync(queue, ^{
            NSLog(@"3");
        });
        NSLog(@"4");
    });
    NSLog(@"5");
}
//信号量
- (void)semaphore {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"开始");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"信号+1");
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"持续");
    
}
- (void)block {
    //创建block方式1
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_block_t block = dispatch_block_create(0, ^{
        NSLog(@"run block 1");
    });
    dispatch_async(queue, block);
    //创建block方式2
    dispatch_block_t block2 = dispatch_block_create_with_qos_class(0, QOS_CLASS_USER_INITIATED, -1, ^{
        NSLog(@"run block 2");
    });
    dispatch_async(queue, block2);
}
- (void)groups {
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, queue, ^{
        [NSThread sleepForTimeInterval:3.f];
        NSLog(@"1");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"2");
    });
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);//会等待上面的group执行完毕在执行后面的代码，会阻塞当前进场，所有go on会最后打印
//    NSLog(@"go on");
    dispatch_group_notify(group, queue, ^{//不会阻塞当前进场，“end”会率先打印，由于是并行，和上面的“2”一起打印，不一定谁先谁后。“1”是3s后打印，“结束了”最后打印
        NSLog(@"结束了");
    });
    NSLog(@"end");
}
- (void)apply {
    //类似for循环，可以在并发队列的情况下，并发执行block任务
    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(10, queue, ^(size_t i) {
        NSLog(@"=== %zu", i);
    });
    NSLog(@"end");
}
- (void)queueTest {
    //一些队列
    
    //    dispatch_get_main_queue()//主队列，串行队列
    
    //四个全局队列。用户不能创建只能获取
    //    dispatch_get_global_queue(<#long identifier#>, <#unsigned long flags#>)//全局队列，并行队列
    dispatch_queue_t high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);//优先级最高的后台全局队列
    dispatch_queue_t def = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//次高
    dispatch_queue_t low = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);//低
    dispatch_queue_t back = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);//最低的后台队列
    
    //自定义队列
    dispatch_queue_t serialQu = dispatch_queue_create("serialQuName", DISPATCH_QUEUE_SERIAL);//自定义串行队列
    dispatch_queue_t cocurrentQu = dispatch_queue_create("cocurrentQuName", DISPATCH_QUEUE_CONCURRENT);//自定义并行队列
    
    //自定义队列优先级
    //attr方式
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, -1);
    dispatch_queue_t queue = dispatch_queue_create("serialQu", attr);
    //target方式
    dispatch_queue_t serialQueue = dispatch_queue_create("serialQu", NULL);//NULL和DISPATCH_QUEUE_SERIAL效果一样，都是自定义串行队列
    dispatch_queue_t referQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);//全局队列的优先级作为参考优先级
    dispatch_set_target_queue(serialQueue, referQueue);//设置serialQueue队列的优先级和referQueue一样
    
}
- (void)targetQueue {
    //    dispatch_set_target_queue 可以设置队列优先级，也可以设置队列的层级体系
    dispatch_queue_t serialQueue = dispatch_queue_create("serialQueue", DISPATCH_QUEUE_SERIAL);//串行队列
    dispatch_queue_t firstQueue = dispatch_queue_create("firstQueue", DISPATCH_QUEUE_SERIAL);//串行队列
    dispatch_queue_t secondQueue = dispatch_queue_create("secondQueue", DISPATCH_QUEUE_CONCURRENT);//并行队列
    
    dispatch_set_target_queue(firstQueue, serialQueue);
    dispatch_set_target_queue(secondQueue, serialQueue);
    dispatch_async(firstQueue, ^{
        NSLog(@"1");
        [NSThread sleepForTimeInterval:3.f];
    });
    dispatch_async(secondQueue, ^{
        NSLog(@"2");
        [NSThread sleepForTimeInterval:2.f];
    });
    dispatch_async(serialQueue, ^{
        NSLog(@"3");
        [NSThread sleepForTimeInterval:1.f];
    });
}
- (void)qosClass {
    //四种通用的调度队列
    
//    QOS_CLASS_USER_INTERACTIVE//优先级最高，用户更新ui或响应事件
//    QOS_CLASS_USER_INITIATED//需要及时结果，同时又可以继续交互
//    QOS_CLASS_UTILITY//优先级低，用于计算，网络，持续数据填充等
//    QOS_CLASS_BACKGROUND//优先级最低，处理用户不易察觉的任务，预加载等不需要用户交互和对时间不敏感的任务
}
- (void)asyncDowldImg {
    //异步下载图片，在主队列上放置图片
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://oalg33nuc.bkt.clouddn.com/WX20171226-155140.png"];
        NSData *imgData = [[NSData alloc] initWithContentsOfURL:url];
        UIImage *img = [[UIImage alloc] initWithData:imgData];
        if (imgData != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image.image = img;
            });
        }
    });
}
//延迟执行
- (void)after {
    double delayInSeconds = 10.0;
    // dispatch_time(<#dispatch_time_t when#>, <#int64_t delta#>) //第一个参数DISPATCH_TIME_NOW表示当前，第二个参数表示多少纳秒
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);//推迟时间//NSEC_PER_SEC是每秒有多少纳秒
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        NSLog(@"asdasd");
    });
}
- (void)barrier {//栅栏
    //dispatch_barrier_async 确保提交的block是指定队列中的唯一执行的一个，在barrier之前的都执行完毕，才开始执行barrier的block，且在执行时会保证不会执行其他任务。当barrier的block执行完毕后，才会恢复队列
    //只有自己创建的并行队列上才有这种效果，在全局并行队列和串行队列上效果和dispatch_sync一样
    dispatch_queue_t queue = dispatch_queue_create("queeu", DISPATCH_QUEUE_CONCURRENT);//并行队列
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"1");//2秒后打印
    });
    dispatch_async(queue, ^{
        NSLog(@"2");//最先打印
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"barrier");//在1后面打印
    });
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"3");//再2秒后打印
    });
    dispatch_async(queue, ^{
        NSLog(@"4");//在barrier后面打印
    });
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
