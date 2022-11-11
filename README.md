# Telegram Contest 2022, Media Editing

Implemetation for Telegram contest 2022 for media editing.

<img src="https://user-images.githubusercontent.com/964601/200111856-82fa2cdc-b36b-4307-895d-7957ed4cdfd8.jpg" width="500">

## Notes

This work done with huge impact from [Azat](https://github.com/azatZul). Telegram always give short period of time for contests. So you only can win if you will leave the rest of your life. Or.. you can invite friend and implement it together.

In this competition we took 4'th place. The quality of line drawing [is not smooth](https://contest.com/ios2022-r1/entry4203).

## Bugs and improvements

- [ ] Photo gallery zoom (one of challenge, for several days more to spend)
- [ ] Video editing (no challenge, need to adapt background blur eraser and regualr eraser for video)
- [ ] Update plume with `CADisplayLink`
- [x] Draw brush on tap
- [ ] On change in history with active `BackgroundBlurEraser` we don't update blured content
- [x] Arrow shape detection
- [ ] Fix joints in `ToolDrawSplitOptimizer` (speed and  path creation)
- [ ] Animate text edit and place mode change
- [ ] Save image to gallery with `Neon` drawings require a lot of time

## Implementation details

> // Todo
