import type { Dict } from './types'

export const en: Dict = {
  nav: {
    home: 'Home',
    support: 'Support',
    privacy: 'Privacy',
    terms: 'Terms',
    otherLanguage: '中文',
    otherLanguageAria: 'Read this page in Chinese',
  },

  footer: {
    onDevice: 'Detection runs entirely on your device.',
    modelCredit: 'Filler detection by Desert Ant Labs',
    lastUpdated: 'Last updated',
  },

  home: {
    metaTitle: 'Umless — Cut filler words from your videos',
    metaDescription:
      'Umless hears every um, uh and hmm, marks each one on the timeline, and exports a clean cut at the original resolution and frame rate — all on your iPhone, iPad or Mac.',
    platforms: 'For iPhone, iPad and Mac',
    title: 'Cut the ums out.',
    body: 'Umless hears every um, uh and hmm, marks each one on the timeline, and exports a clean cut at the original resolution and frame rate — all on your device.',
    download: 'Download on the App Store',
    privacyNote: 'Detection runs on your device. Your videos never leave it.',
    qrTitle: 'Scan to download',
    qrBody: 'Point your iPhone camera here to open Umless on the App Store.',
    artCaption: 'Every filler, marked on the timeline',
    stepsTitle: 'Four steps to a cleaner take',
    steps: [
      {
        title: 'Open a video',
        text: 'Pick a clip from Photos or Files on iPhone and iPad, or drop one on the window on Mac.',
      },
      {
        title: 'Let it listen',
        text: 'Umless finds every filler right on the device. A minute of video takes a few seconds.',
      },
      {
        title: 'Review the marks',
        text: 'Each filler appears on the timeline. Tap one to hear it, and untick anything you would rather keep.',
      },
      {
        title: 'Export',
        text: 'Get the finished cut at the source’s own resolution and frame rate — saved to Photos, or wherever you choose.',
      },
    ],
    featuresTitle: 'Why Umless',
    features: [
      {
        title: 'Private by design',
        text: 'The audio is analysed and the video re-encoded on your device. Nothing you open is uploaded.',
      },
      {
        title: 'Nothing lost in the export',
        text: 'Resolution, frame rate, rotation and colour all match the original. No rescaling, no letterboxing.',
      },
      {
        title: 'Every cut is your call',
        text: 'Untick a mark to keep it. Sensitivity and trim decide how eager the cuts are.',
      },
      {
        title: 'Preview before you export',
        text: 'Turn on Preview the cut to watch the finished edit. What plays is exactly what gets written.',
      },
      {
        title: 'iPhone, iPad and Mac',
        text: 'Native on all three, and Umless Pro carries across every device on the same Apple ID.',
      },
      {
        title: 'Listens, never transcribes',
        text: 'It detects the sound of a filler, not your words, so no transcript of your speech is ever made.',
      },
    ],
    ctaTitle: 'Take the um out of your next video.',
  },

  support: {
    title: 'Support',
    description: 'How to use Umless, answers to common questions, subscriptions, and how to reach us.',
    intro: 'How Umless works, what to do when it doesn’t, and how to reach a person.',
    sections: [
      {
        title: 'Getting started',
        blocks: [
          {
            kind: 'steps',
            items: [
              {
                title: 'Open a video',
                text: 'On iPhone and iPad, **Choose Video** picks from your library and **Browse Files** opens anything else. On Mac, drop a file on the window or press ⌘O.',
              },
              {
                title: 'Let it listen',
                text: 'Umless pulls out the audio and runs the detector on your device. A minute of video takes a few seconds, and nothing is uploaded.',
              },
              {
                title: 'Check the marks',
                text: 'Each filler appears as an amber mark on the timeline and a row in the list. Tap a mark to play from that moment, and untick anything you would rather keep.',
              },
              {
                title: 'Tune it if you need to',
                text: '**Sensitivity** sets how sure the app has to be before it marks something. **Trim around each cut** takes a little extra either side of each cut, so the breath goes with it.',
              },
              {
                title: 'Preview the edit',
                text: 'Turn on **Preview the cut** and the player shows the finished edit rather than the original. What plays is exactly what gets written.',
              },
              {
                title: 'Export',
                text: 'The file is written at the source’s resolution and frame rate. On iPhone and iPad it saves to Photos automatically; on Mac you choose where it goes.',
              },
            ],
          },
        ],
      },
      {
        title: 'Questions',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: 'Which sounds does it detect?',
                a: [
                  '“Um”, “uh”, “hmm” and a drawn-out filler “and”. It listens to the sound rather than transcribing your words, so no text of your speech is ever produced.',
                  'The model is trained on English speech. It often works on other languages, but expect it to find fewer.',
                ],
              },
              {
                q: 'Does exporting reduce the quality?',
                a: [
                  'The video is re-encoded — a cut in the middle of a group of frames cannot be made without it — but at the source’s own dimensions, frame rate, rotation and colour, and aimed at the source’s own bit rate. Nothing is rescaled and nothing is letterboxed.',
                ],
              },
              {
                q: 'Does it need an internet connection?',
                a: [
                  'Not to do its job. Detection, preview and export all run on your device and work in Airplane Mode.',
                  'A connection is used for three things only: buying or restoring Umless Pro through the App Store, an occasional check for a newer version on iPhone and iPad, and a small daily usage count for the detection model. The [Privacy Policy](@privacy) describes each one.',
                ],
              },
              {
                q: 'Which files can it open?',
                a: [
                  'MP4 and MOV files with H.264, HEVC or ProRes video. The file has to have an audio track — there is nothing to listen to otherwise.',
                ],
              },
              {
                q: 'How long does it take?',
                a: [
                  'Detection is quick — a few seconds a minute of video on a recent device. Exporting is the longer half, because the video is re-encoded; 4K takes noticeably longer than 1080p.',
                ],
              },
              {
                q: 'It missed one, or flagged something that isn’t a filler.',
                a: [
                  'Move **Sensitivity**. **Catch everything** marks more and will include some false alarms; **Only obvious ones** marks fewer. Every mark can be unticked individually, and changing sensitivity never re-analyses — the result is instant.',
                ],
              },
              {
                q: 'Where did my exported video go?',
                a: [
                  'On iPhone and iPad it is saved to Photos, in Recents. On Mac it goes to the folder you chose in the save panel. Your original file is never modified or deleted.',
                ],
              },
              {
                q: 'Can I change the language or the theme?',
                a: [
                  '**Settings** has both. **Language** offers English and 简体中文, and **Appearance** offers Light, Dark or **Follow System**. Both default to your system setting.',
                ],
              },
            ],
          },
        ],
      },
      {
        title: 'Umless Pro and purchases',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: 'What does Umless Pro include?',
                a: [
                  'Umless Pro unlocks unlimited video exports. It is available as a weekly, monthly or yearly subscription, or as a one-time Lifetime purchase. The price in your currency is shown before you confirm.',
                ],
              },
              {
                q: 'Does my purchase work on all my devices?',
                a: [
                  'Yes. Umless is a single App Store app for iPhone, iPad and Mac, so Umless Pro works on every device signed in to the same Apple ID.',
                ],
              },
              {
                q: 'How do I cancel or change a subscription?',
                a: [
                  'Subscriptions renew automatically until you cancel. On iPhone or iPad, open **Settings**, tap your name, then **Subscriptions**. On Mac, open the App Store, click your name, then **Account Settings › Subscriptions › Manage**.',
                  'Cancel at least 24 hours before the renewal date to avoid the next charge.',
                ],
              },
              {
                q: 'I bought Umless Pro, but it isn’t unlocked.',
                a: [
                  'Make sure the device is signed in with the Apple ID you bought it with, then use **Restore Purchases** in Umless’s Settings.',
                ],
              },
              {
                q: 'How do I get a refund?',
                a: [
                  'Payments are handled by Apple, and so are refunds. Request one at [reportaproblem.apple.com](https://reportaproblem.apple.com).',
                ],
              },
            ],
          },
        ],
      },
      {
        title: 'If something goes wrong',
        blocks: [
          {
            kind: 'qa',
            items: [
              {
                q: '“This video has no audio track.”',
                a: [
                  'Umless works from sound, so a silent file has nothing for it to do. Check that the clip really carries audio — screen recordings made with the microphone off often do not.',
                ],
              },
              {
                q: 'Nothing was detected',
                a: [
                  'Either the recording is genuinely clean, or the speech is in a language the model handles less well. Set **Sensitivity** to **Catch everything** and look again.',
                ],
              },
              {
                q: 'It can’t save to Photos',
                a: [
                  'Umless asks for add-only access the first time. If it was declined, turn it back on in **Settings › Apps › Umless › Photos** and choose **Add Photos Only**. The share button next to it can send the file anywhere in the meantime.',
                ],
              },
              {
                q: 'The export failed',
                a: [
                  'Check there is free space for a second copy of the video, then try again. If a particular file fails every time, send it to us if you can — that is the fastest way to get it fixed.',
                ],
              },
            ],
          },
        ],
      },
      {
        title: 'Contact',
        blocks: [
          {
            kind: 'p',
            text: 'Questions, bugs and feature requests all go to the same place, and a person reads them. For a problem with a specific video, it helps to include your device, its system version, and how the clip was recorded.',
          },
          { kind: 'p', text: '{email}' },
        ],
      },
    ],
  },

  privacy: {
    title: 'Privacy Policy',
    description:
      'How Umless handles your videos: processed on your device, never uploaded. What little goes over the network, and why.',
    intro: 'What Umless does with your videos, in full: they never leave your device.',
    sections: [
      {
        title: 'The short version',
        blocks: [
          {
            kind: 'list',
            items: [
              'Your videos and their audio are processed entirely on your device. Nothing you open is ever uploaded.',
              'There is no account, no advertising, no analytics and no tracking.',
              'Umless uses the network for three things, described below. None of them carries your videos, your audio, or anything about you.',
            ],
          },
        ],
      },
      {
        title: 'Your videos stay on your device',
        blocks: [
          {
            kind: 'list',
            items: [
              '**Processing is local.** Audio is analysed and the video is re-encoded on the device itself. Nothing is uploaded, at any point.',
              '**No speech is transcribed.** The model detects the sound of a filler word; it never produces text of what you said.',
              '**Photos access is add-only** on iPhone and iPad, and is used for one thing: saving the video you exported. Umless never reads your library. Videos you import come through the system picker, which needs no read permission.',
              '**On Mac,** Umless reaches only the files you choose in the open and save panels.',
              '**The microphone and camera are never accessed.**',
              '**Temporary files** made while importing or exporting live in the app’s own temporary folder and are cleared by the system.',
            ],
          },
        ],
      },
      {
        title: 'What goes over the network',
        blocks: [
          { kind: 'p', text: 'Umless makes these connections, and no others:' },
          {
            kind: 'list',
            items: [
              '**Purchases, through Apple.** Buying, restoring and renewing Umless Pro are handled by the App Store. We never see your payment details; the app learns only whether your Apple ID has an active Umless Pro purchase. [Apple’s Privacy Policy](https://www.apple.com/legal/privacy/) applies.',
              '**Update checks, on iPhone and iPad.** About once a day, the app asks Apple’s public App Store lookup service for the newest version of Umless, so it can offer an update. The request contains only Umless’s App Store ID.',
              '**A usage count for the detection model.** The filler-detection model is licensed from [Desert Ant Labs](https://desertant.com), which counts how many devices use it each month. At most once a day, its software sends Desert Ant Labs a short record: a random identifier it creates for this purpose and keeps only inside Umless, the app’s identifier, the platform, the software version, and how many times the model ran. It never includes your videos, audio, results or anything that identifies you, and it is not linked to your Apple ID or to other apps. Desert Ant Labs B.V. is responsible for that record. The identifier is deleted when you delete Umless.',
            ],
          },
          {
            kind: 'p',
            text: 'When you ask for it — rating the app, opening the App Store, or writing to us — Umless hands you to Apple’s rating prompt, the App Store or your mail app, and their own privacy terms apply.',
          },
        ],
      },
      {
        title: 'What is stored on your device',
        blocks: [
          {
            kind: 'list',
            items: [
              'Your language and appearance settings.',
              'How many videos you have exported, used only to decide when to ask for a rating, and the app version it last asked in.',
              'When the app last checked for an update.',
            ],
          },
          { kind: 'p', text: 'All of it stays on the device and is deleted when you delete Umless.' },
        ],
      },
      {
        title: 'Changes and contact',
        blocks: [
          {
            kind: 'p',
            text: 'If this policy changes, the updated version will appear on this page with a new date. Questions about it can go to {email}.',
          },
        ],
      },
    ],
  },

  terms: {
    title: 'Terms of Use',
    description: 'The terms for using Umless and buying Umless Pro, including how subscriptions renew and how to cancel.',
    intro: 'The terms for using Umless and buying Umless Pro.',
    sections: [
      {
        title: 'Agreement',
        blocks: [
          {
            kind: 'p',
            text: 'Umless is licensed to you under Apple’s [Licensed Application End User License Agreement](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) (the “Standard EULA”). These terms add what is specific to Umless and Umless Pro. By downloading or using Umless you agree to both; where they conflict, the Standard EULA governs.',
          },
        ],
      },
      {
        title: 'Umless Pro',
        blocks: [
          {
            kind: 'list',
            items: [
              'Umless Pro unlocks unlimited video exports.',
              'It is offered as an auto-renewing subscription — **weekly**, **monthly** or **yearly** — or as a one-time **Lifetime** purchase. The price for your country or region is shown before you confirm.',
              'A purchase applies to Umless on every iPhone, iPad and Mac signed in to the same Apple ID.',
            ],
          },
        ],
      },
      {
        title: 'Subscriptions',
        blocks: [
          {
            kind: 'list',
            items: [
              'Payment is charged to your Apple ID account when you confirm the purchase.',
              'A subscription renews automatically, at the same price and for the same period, unless it is cancelled at least 24 hours before the end of the current period.',
              'Your account is charged for the renewal within the 24 hours before the current period ends.',
              'You can manage or cancel a subscription in your Apple ID account settings at any time after purchase. Cancelling stops future renewals; the current period stays active until it ends.',
              'If a free trial is offered, any unused part of it ends when you buy a subscription.',
            ],
          },
        ],
      },
      {
        title: 'Refunds',
        blocks: [
          {
            kind: 'p',
            text: 'All payments are processed by Apple, and refunds are handled by Apple under its policies. You can request one at [reportaproblem.apple.com](https://reportaproblem.apple.com).',
          },
        ],
      },
      {
        title: 'Your videos',
        blocks: [
          {
            kind: 'p',
            text: 'You keep every right to the videos you open and export. Umless processes them on your device and does not upload them; the [Privacy Policy](@privacy) explains exactly what is and is not sent. You are responsible for having the rights to the material you edit.',
          },
        ],
      },
      {
        title: 'The detection model',
        blocks: [
          {
            kind: 'p',
            text: 'Filler detection is powered by the Uhm model from [Desert Ant Labs](https://desertant.com). It can miss a filler or mark a sound that is not one, so review the marks before you export.',
          },
        ],
      },
      {
        title: 'Changes',
        blocks: [
          {
            kind: 'p',
            text: 'Features may change between versions. These terms may be updated; the new version will appear on this page with a new date, and continuing to use Umless afterwards means you accept it.',
          },
        ],
      },
      {
        title: 'Disclaimer',
        blocks: [
          {
            kind: 'p',
            text: 'Umless is provided “as is”. To the extent the law allows, we make no warranty that it will be error-free or suit a particular purpose, and we are not liable for indirect or consequential loss, including loss of data. Nothing here limits rights you have under consumer law that cannot be waived.',
          },
        ],
      },
      {
        title: 'Contact',
        blocks: [{ kind: 'p', text: 'Questions about these terms can go to {email}.' }],
      },
    ],
  },
}
