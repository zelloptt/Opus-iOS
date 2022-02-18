# Opus-iOS

> Opus is a totally open, royalty-free, highly versatile audio codec. Opus is unmatched for interactive speech and music transmission over the Internet, but is also intended for storage and streaming applications. It is standardized by the Internet Engineering Task Force (IETF) as RFC 6716 which incorporated technology from Skype's SILK codec and Xiph.Org's CELT codec.

iOS build scripts for the [Opus Codec](http://www.opus-codec.org). These scripts download and build libopus 1.3.1 as an xcframework.

These scripts are based on [Chris Ballinger's build scripts](https://github.com/chrisballinger/Opus-iOS).

## Requirements
I have only tested these build scripts using Xcode 13, with a minimum iOS target of 12.1. If you want to target earlier versions of iOS, you will need to update the `MINIOSVERSION` variable in `opus/scripts/build-libopus.sh` and may need to make other changes to the scripts.

## Usage

1. [Build the framework](#building-the-framework)
2. (Optionally) Use the [CocoaPod spec](/zello-opus-ios.podspec)

## Building the framework

```sh
% cd opus
% xcodebuild
```

`opus.xcframework` will be built in the `opus/build` directory.

## License

MIT
