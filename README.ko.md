[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Русский](README.ru.md)

# Snow-Love Module

> 원클릭 숨김 모듈 — 플래시하면 바로 사용할 수 있습니다.

## 무엇인가

자주 쓰이는 탐지 우회 구성요소를 하나의 모듈로 묶어,
플래시 후 환경을 자동으로 준비합니다.

| 구성요소 | 역할 |
|---|---|
| Zygisk Next | Zygisk 런타임 |
| LSPosed | 모듈 프레임워크 |
| HMA | 앱 목록 숨김 |
| PIF | Play Integrity 수정 |
| SUSFS 규칙 | 경로 / 마운트 지점 숨김 |

목표는 하나입니다: **수동 작업과 시행착오를 줄인다**.

## 특징

- **원클릭 설치** — zip 하나, 한 번 플래시
- **자동 설정** — 허용/차단 목록, denylist, 마운트 숨김 자동 생성
- **되돌리기 가능** — `uninstall.sh` 포함, 흔적을 남기지 않음
- **호환** — KernelSU / SukiSU / APatch, Hybrid Mount 와 함께 쓰면 최적

## 설치

1. 커널 레벨 root(KernelSU 계열) 확인
2. 메타 모듈 **Hybrid Mount** 를 먼저 설치
3. 매니저 → 모듈 → 설치 → 이 zip 선택
4. 재부팅

## 호환성

| 환경 | 상태 |
|---|---|
| KernelSU / SukiSU | ✅ 지원 |
| APatch | ✅ 지원 |
| Magisk | ⚠️ 미검증 |
| 비 GKI 4.x 커널 | ⚠️ 일부 기능 사용 불가 |

## 면책 조항

이 모듈은 **개인 기기의 환경 격리와 프라이버시 보호**를 위한 것입니다.
합법적인 리스크 관리를 우회하는 용도로 사용하지 마세요.

사용으로 인한 계정 정지, 데이터 손실, 기기 이상에 대해 작성자는 책임지지 않습니다.
플래시에는 위험이 있습니다. 먼저 boot 파티션을 백업하세요.

## 피드백

- Issues: https://github.com/HuijuiSU-NEXT/Snow-love-Module/issues
- Telegram: https://t.me/Huijui123
- 채널: https://t.me/HuijuiSU
