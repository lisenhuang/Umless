import type { Dict } from './types'

/**
 * Simplified Chinese. UI labels quote the app's own zh-Hans strings exactly —
 * 选择视频, 灵敏度, 每处剪辑的余量, 预览剪辑结果, 尽量全部找出 — so that what a
 * reader looks for on this page is what they find on screen.
 */
export const zh: Dict = {
  nav: {
    home: '首页',
    support: '支持',
    privacy: '隐私政策',
    terms: '使用条款',
    otherLanguage: 'English',
    otherLanguageAria: '用英文阅读本页',
  },

  footer: {
    onDevice: '检测全程在本机运行。',
    modelCredit: '语气词检测模型由 Desert Ant Labs 提供',
    lastUpdated: '最后更新',
  },

  home: {
    metaTitle: 'Umless — 剪掉视频里的语气词',
    metaDescription:
      'Umless 能听出每一个「嗯」「呃」「唔」，在时间轴上逐一标出，再按原分辨率、原帧率导出干净的成片——全程在你的 iPhone、iPad 或 Mac 上完成。',
    platforms: '适用于 iPhone、iPad 与 Mac',
    title: '剪掉那些语气词。',
    body: 'Umless 能听出每一个「嗯」「呃」「唔」，在时间轴上逐一标出，再按原分辨率、原帧率导出干净的成片——全程在你的设备上完成。',
    download: '在 App Store 下载',
    privacyNote: '检测在本机运行，视频不会离开你的设备。',
    qrTitle: '扫码下载',
    qrBody: '用 iPhone 相机扫描此处，即可在 App Store 打开 Umless。',
    artCaption: '每个语气词，都标在时间轴上',
    stepsTitle: '四步，得到更干净的一条',
    steps: [
      {
        title: '打开视频',
        text: '在 iPhone 和 iPad 上从相册或文件中挑选，在 Mac 上直接把文件拖进窗口。',
      },
      {
        title: '等它听完',
        text: 'Umless 在设备上找出每个语气词，一分钟的素材只需几秒。',
      },
      {
        title: '核对标记',
        text: '每个语气词都会标在时间轴上。点一下就能听，想保留的取消勾选即可。',
      },
      {
        title: '导出',
        text: '成片保持原片的分辨率与帧率，存入相册，或保存到你选择的位置。',
      },
    ],
    featuresTitle: '为什么选 Umless',
    features: [
      {
        title: '从设计上保护隐私',
        text: '音频分析与视频重新编码都在本机完成，你打开的任何内容都不会上传。',
      },
      {
        title: '导出不打折扣',
        text: '分辨率、帧率、旋转方向与色彩都与原片一致，不缩放，也不加黑边。',
      },
      {
        title: '每一刀由你决定',
        text: '取消勾选即可保留。灵敏度与剪辑余量决定下刀的力度。',
      },
      {
        title: '导出前先预览',
        text: '打开「预览剪辑结果」即可看到成片。播放的就是最终写出的内容。',
      },
      {
        title: 'iPhone、iPad 与 Mac',
        text: '三个平台原生运行，同一个 Apple 账户下，Umless Pro 在每台设备上都可用。',
      },
      {
        title: '只听声音，不转文字',
        text: '它检测的是语气词的声音，而不是你说的话，因此不会生成任何语音文本。',
      },
    ],
    ctaTitle: '让下一个视频少一点「嗯」。',
  },

  support: {
    title: '支持',
    description: 'Umless 的使用方法、常见问题、订阅说明，以及联系方式。',
    intro: 'Umless 怎么用、出问题时怎么办，以及怎样找到人。',
    sections: [
      {
        title: '上手',
        blocks: [
          {
            kind: 'steps',
            items: [
              {
                title: '打开视频',
                text: '在 iPhone 和 iPad 上，用 **选择视频** 从相册中挑选，用 **浏览文件** 打开其他位置的文件。在 Mac 上，把文件拖到窗口里，或按 ⌘O。',
              },
              {
                title: '等它听完',
                text: 'Umless 会提取音轨，在本机运行检测。一分钟的素材只需几秒，全程不上传。',
              },
              {
                title: '核对标记',
                text: '每个语气词都会在时间轴上显示为琥珀色标记，并在列表中列出。点击标记可从该处播放，想保留的取消勾选即可。',
              },
              {
                title: '需要时微调',
                text: '**灵敏度** 决定 App 有多确信才会标记。**每处剪辑的余量** 会在每个剪切点前后多剪一点，把换气声一起带走。',
              },
              {
                title: '预览成片',
                text: '打开 **预览剪辑结果**，播放器就会播放剪好的版本而不是原片。看到的就是导出的结果。',
              },
              {
                title: '导出',
                text: '成片按原分辨率、原帧率写出。在 iPhone 和 iPad 上会自动存入相册；在 Mac 上由你选择保存位置。',
              },
            ],
          },
        ],
      },
      {
        title: '常见问题',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: '它能检测哪些声音？',
                a: [
                  '「um」「uh」「hmm」，以及被拖长的连接词「and」。它听的是声音，并不会把你的话转写成文字，因此不会生成任何语音文本。',
                  '模型基于英语语音训练。用在其他语言上通常也能工作，但检出会少一些。',
                ],
              },
              {
                q: '导出会不会损失画质？',
                a: [
                  '视频会被重新编码——要在一组画面中间下刀，就绕不开这一步——但使用的是原片的尺寸、帧率、旋转方向与色彩信息，码率也对齐原片。不会缩放，也不会加黑边。',
                ],
              },
              {
                q: '需要联网吗？',
                a: [
                  '做正事不需要。检测、预览和导出都在本机完成，开飞行模式一样能用。',
                  '只有三件事会用到网络：通过 App Store 购买或恢复 Umless Pro、在 iPhone 和 iPad 上偶尔检查新版本，以及检测模型每天一次的用量统计。[隐私政策](@privacy) 对每一项都有说明。',
                ],
              },
              {
                q: '支持哪些文件？',
                a: ['包含 H.264、HEVC 或 ProRes 视频的 MP4 与 MOV 文件。文件必须带音轨，否则没有可听的内容。'],
              },
              {
                q: '要花多久？',
                a: [
                  '检测很快——在较新的设备上，一分钟素材约几秒。导出耗时更长，因为要重新编码；4K 会明显慢于 1080p。',
                ],
              },
              {
                q: '漏掉了，或者标错了。',
                a: [
                  '调整 **灵敏度**。**尽量全部找出** 会标得更多，也会带上一些误判；**只找明显的** 标得更少。每个标记都可以单独取消勾选，切换灵敏度不会重新分析，结果即时更新。',
                ],
              },
              {
                q: '导出的视频在哪里？',
                a: [
                  '在 iPhone 和 iPad 上会保存到「照片」的「最近项目」。在 Mac 上保存到你在面板中选择的文件夹。原始文件不会被修改，也不会被删除。',
                ],
              },
              {
                q: '可以切换语言和外观吗？',
                a: [
                  '在 **设置** 里都可以。**语言** 支持 English 与简体中文，**外观** 支持浅色、深色或 **跟随系统**。两者默认都跟随系统。',
                ],
              },
            ],
          },
        ],
      },
      {
        title: 'Umless Pro 与购买',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: 'Umless Pro 包含什么？',
                a: [
                  'Umless Pro 可解锁无限次导出视频。可按周、按月或按年订阅，也可一次性购买终身版。确认购买前会以你所在地区的货币显示价格。',
                ],
              },
              {
                q: '购买后能在我所有设备上使用吗？',
                a: ['可以。Umless 是同一个 App Store App，支持 iPhone、iPad 与 Mac，只要登录同一个 Apple 账户，Umless Pro 在每台设备上都可用。'],
              },
              {
                q: '如何取消或更改订阅？',
                a: [
                  '订阅会自动续期，直到你取消为止。在 iPhone 或 iPad 上，打开 **设置**，轻点你的名字，再轻点 **订阅**。在 Mac 上，打开 App Store，点按你的名字，然后前往 **账户设置 › 订阅 › 管理**。',
                  '请至少在续期日前 24 小时取消，以免产生下一期费用。',
                ],
              },
              {
                q: '已经购买了 Umless Pro，但没有解锁。',
                a: ['请确认设备登录的是购买时使用的 Apple 账户，然后在 Umless 的设置中使用 **恢复购买**。'],
              },
              {
                q: '如何申请退款？',
                a: ['付款由 Apple 处理，退款也由 Apple 处理。请前往 [reportaproblem.apple.com](https://reportaproblem.apple.com) 申请。'],
              },
            ],
          },
        ],
      },
      {
        title: '遇到问题',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: '「这个视频没有音轨。」',
                a: [
                  'Umless 依靠声音工作，静音文件没有可处理的内容。请确认素材确实带有音轨——关闭麦克风录制的录屏通常没有。',
                ],
              },
              {
                q: '什么都没检测到',
                a: [
                  '可能录音本身就很干净，也可能语音所用的语言不在模型的强项范围内。把 **灵敏度** 调到 **尽量全部找出** 再看一次。',
                ],
              },
              {
                q: '无法存入相册',
                a: [
                  'Umless 首次会申请「仅添加」权限。如果当时拒绝了，可在 **设置 › App › Umless › 照片** 中重新开启，选择 **仅添加照片**。在此期间，旁边的共享按钮可以把文件发送到任何地方。',
                ],
              },
              {
                q: '导出失败',
                a: [
                  '先确认设备上还有足够空间再放下一份视频，然后重试。如果某个文件每次都失败，方便的话请把它发给我们——这是最快的修复途径。',
                ],
              },
            ],
          },
        ],
      },
      {
        title: '联系我们',
        blocks: [
          {
            kind: 'p',
            text: '问题、故障与功能建议都发到同一个邮箱，会有人逐封阅读。如果是某个视频的问题，请附上设备型号、系统版本，以及素材的录制方式，会更快定位。',
          },
          { kind: 'p', text: '{email}' },
        ],
      },
    ],
  },

  privacy: {
    title: '隐私政策',
    description: 'Umless 如何处理你的视频：在本机处理，从不上传；以及少数联网行为的内容与原因。',
    intro: 'Umless 如何处理你的视频，完整说明：视频始终不会离开你的设备。',
    sections: [
      {
        title: '简要说明',
        blocks: [
          {
            kind: 'list',
            items: [
              '你的视频及其音频完全在本机处理，打开的任何内容都不会上传。',
              '没有账号、没有广告、没有分析统计，也没有追踪。',
              'Umless 只会因为下面说明的三件事联网，其中任何一项都不包含你的视频、音频或关于你的信息。',
            ],
          },
        ],
      },
      {
        title: '你的视频留在你的设备上',
        blocks: [
          {
            kind: 'list',
            items: [
              '**在本机处理。** 音频分析与视频重新编码都在设备上完成，任何环节都不会上传。',
              '**不会转写语音。** 模型只检测语气词的声音，不会把你说的话转成文字。',
              '**相册权限为「仅添加」**（iPhone 与 iPad），只用于保存你导出的视频。Umless 从不读取你的相册；导入的视频通过系统选择器传入，不需要读取权限。',
              '**在 Mac 上，** Umless 只会访问你在打开与存储面板中选择的文件。',
              '**从不访问麦克风与摄像头。**',
              '**临时文件** 在导入与导出过程中产生，存放在 App 自己的临时目录中，由系统清理。',
            ],
          },
        ],
      },
      {
        title: '会联网的内容',
        blocks: [
          { kind: 'p', text: 'Umless 只会建立以下连接，没有其他：' },
          {
            kind: 'list',
            items: [
              '**通过 Apple 购买。** Umless Pro 的购买、恢复与续期均由 App Store 处理。我们看不到你的付款信息；App 只会知道你的 Apple 账户是否拥有有效的 Umless Pro。适用 [Apple 隐私政策](https://www.apple.com/legal/privacy/)。',
              '**检查更新（iPhone 与 iPad）。** App 大约每天一次向 Apple 公开的 App Store 查询服务获取 Umless 的最新版本号，以便提示你更新。请求中只包含 Umless 的 App Store ID。',
              '**检测模型的用量统计。** 语气词检测模型由 [Desert Ant Labs](https://desertant.com) 授权提供，对方需要统计每月使用该模型的设备数量。其软件每天最多一次向 Desert Ant Labs 发送一条简短记录：为此专门生成、只保存在 Umless 内的随机标识符、App 标识符、平台、软件版本，以及模型运行的次数。记录中不含你的视频、音频、检测结果，也不含任何能识别你的信息，且不会与你的 Apple 账户或其他 App 关联。该记录由 Desert Ant Labs B.V. 负责。删除 Umless 后，该标识符随之删除。',
            ],
          },
          {
            kind: 'p',
            text: '当你主动操作——为 App 评分、打开 App Store，或给我们写信——Umless 会转交给 Apple 的评分窗口、App Store 或你的邮件 App，届时适用它们各自的隐私条款。',
          },
        ],
      },
      {
        title: '保存在你设备上的内容',
        blocks: [
          {
            kind: 'list',
            items: [
              '你的语言与外观设置。',
              '你导出视频的次数（只用于决定何时请你评分），以及上次请求评分时的 App 版本。',
              'App 上次检查更新的时间。',
            ],
          },
          { kind: 'p', text: '这些内容都只保存在设备上，删除 Umless 后随之删除。' },
        ],
      },
      {
        title: '变更与联系',
        blocks: [
          {
            kind: 'p',
            text: '本政策如有变更，更新后的版本会连同新的日期发布在本页。相关问题可发送至 {email}。',
          },
        ],
      },
    ],
  },

  terms: {
    title: '使用条款',
    description: '使用 Umless 及购买 Umless Pro 的条款，包括订阅如何续期以及如何取消。',
    intro: '使用 Umless 及购买 Umless Pro 的条款。',
    sections: [
      {
        title: '协议',
        blocks: [
          {
            kind: 'p',
            text: 'Umless 依据 Apple 的 [许可应用程序最终用户许可协议](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/)（下称「标准 EULA」）授权给你使用。本条款补充了与 Umless 和 Umless Pro 相关的具体内容。下载或使用 Umless，即表示你同意两者；如有冲突，以标准 EULA 为准。',
          },
        ],
      },
      {
        title: 'Umless Pro',
        blocks: [
          {
            kind: 'list',
            items: [
              'Umless Pro 可解锁无限次导出视频。',
              '提供自动续期订阅——**按周**、**按月** 或 **按年**——以及一次性购买的 **终身版**。确认购买前会显示你所在国家或地区的价格。',
              '购买后，在登录同一 Apple 账户的所有 iPhone、iPad 与 Mac 上的 Umless 均可使用。',
            ],
          },
        ],
      },
      {
        title: '订阅',
        blocks: [
          {
            kind: 'list',
            items: [
              '确认购买时，费用将从你的 Apple 账户扣除。',
              '除非在当前周期结束前至少 24 小时取消，订阅将以相同价格、相同周期自动续期。',
              '续期费用会在当前周期结束前 24 小时内扣除。',
              '购买后，你可以随时在 Apple 账户设置中管理或取消订阅。取消后不再续期，当前周期在结束前仍然有效。',
              '如提供免费试用，购买订阅后，试用期中未使用的部分将随之失效。',
            ],
          },
        ],
      },
      {
        title: '退款',
        blocks: [
          {
            kind: 'p',
            text: '所有付款均由 Apple 处理，退款也由 Apple 按其政策处理。你可以前往 [reportaproblem.apple.com](https://reportaproblem.apple.com) 申请。',
          },
        ],
      },
      {
        title: '你的视频',
        blocks: [
          {
            kind: 'p',
            text: '你对打开和导出的视频保留全部权利。Umless 在本机处理它们，不会上传；哪些内容会发送、哪些不会，[隐私政策](@privacy) 中有完整说明。你需要确保自己有权编辑所使用的素材。',
          },
        ],
      },
      {
        title: '检测模型',
        blocks: [
          {
            kind: 'p',
            text: '语气词检测由 [Desert Ant Labs](https://desertant.com) 的 Uhm 模型提供。它可能漏掉语气词，也可能把不是语气词的声音标记出来，导出前请核对标记。',
          },
        ],
      },
      {
        title: '变更',
        blocks: [
          {
            kind: 'p',
            text: '功能可能随版本变化。本条款可能更新，新版本会连同新的日期发布在本页；此后继续使用 Umless，即表示你接受新版本。',
          },
        ],
      },
      {
        title: '免责声明',
        blocks: [
          {
            kind: 'p',
            text: 'Umless 按「现状」提供。在法律允许的范围内，我们不保证它没有错误或适合特定用途，也不对间接或后果性损失（包括数据丢失）承担责任。本条款不影响你依据消费者保护法享有、且不可放弃的权利。',
          },
        ],
      },
      {
        title: '联系',
        blocks: [{ kind: 'p', text: '有关本条款的问题，可发送至 {email}。' }],
      },
    ],
  },
}
