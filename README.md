# 🥊 Roblox GetAmped-style Game

겟앰프드 스타일의 Roblox 난투형 대전 게임.

## 🎮 핵심 시스템

- **콤보 전투** — Z/X/C 키 기반 공격 체인 + 넉백
- **악세서리 시스템** — 장착 아이템별 고유 스킬
- **멀티플레이어** — RemoteEvent 기반 동기화
- **맵 탈락 판정** — 아레나 아웃 시 탈락

## 📁 구조

```
src/
  server/          # 서버 로직 (신뢰 영역)
    systems/       # 전투, 악세서리, 플레이어 관리
  client/          # 클라이언트 로직 (입력, UI)
    systems/       # 입력 처리, UI
  shared/          # 서버/클라이언트 공유
    accessories/   # 악세서리 정의
    modules/       # 상수, 타입
```

## 🚀 개발 단계

- [ ] Phase 1: 코어 전투 (이동, 공격, 체력, 넉백)
- [ ] Phase 2: 악세서리 시스템
- [ ] Phase 3: 멀티플레이 + 아레나 맵
- [ ] Phase 4: 이펙트 + 폴리싱
