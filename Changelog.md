# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-01-04

### Added
- **720p Vertical Video Support:** Updated stream configuration to request High resolution (1280x720) from the Meta Wearables SDK.
- **VideoCodecSettings:** Explicitly enforced H.264 High Profile and 9:16 aspect ratio in HaishinKit to prevent default landscape handling.

### Fixed
- **1x1 Aspect Ratio Bug:** Solved a race condition where the RTMP stream would initialize with 0x0 or 1x1 dimensions.
- **Encoder Priming:** Removed the broadcasting guard to allow video buffers to "prime" the encoder immediately upon app launch, ensuring correct metadata is sent during the handshake.

### Changed
- Updated dependency compatibility to HaishinKit 2.2.3.