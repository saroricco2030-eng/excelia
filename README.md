# Security Kit — SECURITY_MASTER v1.0

## 파일 구조
```
프로젝트 루트에 아래와 같이 배치
my_app/
├── CLAUDE.md                         ← 기존 파일 (건드리지 않음)
├── docs/
│   ├── DESIGN_MASTER_v3.2.md         ← 기존 파일 (건드리지 않음)
│   └── SECURITY_MASTER_v1.0.md       ← 이 kit에서 복사
├── hooks/
│   └── pre-commit                    ← 이 kit에서 복사
├── install_hooks.sh                  ← 이 kit에서 복사
└── analysis_options.yaml             ← 기존 파일에 스니펫 병합
```

## 설치 순서

### 1. 파일 복사
```bash
cp docs/SECURITY_MASTER_v1.0.md  내프로젝트/docs/
cp hooks/pre-commit               내프로젝트/hooks/
cp install_hooks.sh               내프로젝트/
```

### 2. analysis_options.yaml 병합
`analysis_options_security.yaml` 내용을 기존 `analysis_options.yaml` 하단에 붙여넣기

### 3. hook 설치 (딱 한 번)
```bash
cd 내프로젝트
bash install_hooks.sh
```

### 4. 완료
이후 `git commit` 할 때마다 자동 보안 검사 실행됩니다.
별도 명령 불필요.
