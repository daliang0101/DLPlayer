# 模块划分
 ## 音频输出: AudioOutput
 - 功能：渲染音频
 - 接口：DLAudioOutput
 - 协议：DLAudioOutputProtocol / DLAudioOutputPrivateProtocol
 - 概述：消费音频数据，提供填充音频数据的回调，平台音频库内部线程主动请求数据  
 
 &emsp;&emsp;&emsp;&emsp;&emsp;请求方式：   
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;`void(^DLAudioOutputFillDataBlock)(float *data, UInt32 numFrames, UInt32 numChannels)`
 
 
 &emsp;&emsp;&emsp;&emsp;AudioOutput主动调用此Block以请求音频数据，   
 &emsp;&emsp;&emsp;&emsp;由调度器(PlayerController)决定如何实现Block以响应音频请求
 
 ## 视频输出: VideoOutput
 - 功能：渲染视频
 - 接口：DLVideoOutput
 - 协议：DLVideoOutputProtocol / DLVideoOutputPrivateProtocol
 - 概述：消费视频数据，提供接收视频帧的接口
 
 &emsp;&emsp;&emsp;&emsp;&emsp;接收方式：- (void)render:(nullable id<DLVideoFrameProtocol>)frame
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;由调度器(PlayerController)决议何时发送视频帧
 
 ## 音视频对齐: AVSync
 - 功能：音画同步
 - 接口：DLAVSynchronizer
 - 协议：DLAVSynchronizerProtocol / DLSynchronizerPrivateProtocol
 - 概述：为AudioOutput和VideoOutput提供音视频数据，维护解码线程，处理对齐逻辑  
 
 &emsp;&emsp;&emsp;&emsp;&emsp;音频接口：  
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;`- (void)fillAudioData:(float *_Nullable)outData numFrames:(UInt32 )numFrames`  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;numChannels:(UInt32 )numChannels;
 
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;由调度器(PlayerController)调用，把音频请求传递给AVSync，AVSync向outData地址填充数据
 
 &emsp;&emsp;&emsp;&emsp;&emsp;视频接口：- (void)fillVideoData:(id<DLVideoFrameProtocol>_Nullable)frame;       
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;委托方法，AVSync把准备好的视频帧通过此方法交给其委托对象，   
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;由委托对象(这里是PlayerController)决定视频帧的去向
    
 &emsp;&emsp;&emsp;&emsp;&emsp;音视频对齐：内部逻辑，外界无需知道  
  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;对齐策略：目前采用音频向视频对齐
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;视频对齐模型：  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;理想情况：当前视频帧PTS - 参考视频帧PTS == 当前系统时间 - 参考系统时间(参考帧渲染时间)
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;即视频帧之间展示到屏幕上的时间间隔 == 它们PTS之间的间隔；
    
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;播放较快：两帧展示到屏幕上的时间差 < 它们PTS差值；   
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;修正策略：增大下一次调用tick函数的时间，给“理想时间”加上一个“修正值”
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;播放较慢：两帧展示到屏幕上的时间差 > 它们PTS差值；  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;修正策略：减小下一次调用tick函数的时间，给“理想时间”减去一个“修正值”
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;词语说明：  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;tick函数：控制渲染视频的节拍，内部不断在修正下一次渲染的时间  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;理想时间：当前帧的duration，即展示多久  
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;修正值：根据播放速度快慢，计算出来一个时间值，决定下一次调用tick函数时间
 
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;音频对齐模型：每次从音频队列取出待渲染的音频帧，和播放器时钟(视频渲染时钟)对比；
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;若音频渲染过慢或过快(超出预设的阈值)，则丢弃，反之拷贝音频数据到目标地址；
 &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;
 
 
 ## 解码: Decoder
 - 功能：解协议、解封装、解码，生产音视频数据，供AVSync调用
 - 接口：DLDecoder
 - 协议：DLDecoderProtocol / DLDecoderPrivateProtocol
 - 概述：提供解析协议、解码接口，其工作线程由调用方在决定  
 &emsp;&emsp;&emsp;打开文件：- (BOOL)openFile:(NSString *)path error:(NSError **)perror;  
 &emsp;&emsp;&emsp;解封装、解码：- (NSArray *)decodeFrames:(NSTimeInterval)minDuration;
 
 ## 控制器: PlayerController
 - 功能：负责调度AudioOutput、VideoOutput、AVSync三个模块，供客户端调用
 - 接口：DLPlayerController
 - 协议：DLPlayerControllerProtocol / DLPlayerControllerPrivateProtocol
 - 概述：播放器入口，传递用户交互行为，输出播放器状态信息  
 &emsp;&emsp;&emsp;关键属性：playerView，输出视频画面，客户端获取之后将其添加到指定的view即可
