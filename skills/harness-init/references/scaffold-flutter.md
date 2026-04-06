# Flutter 项目脚手架模板

## 目录结构

lib/
├── domain/
│   ├── entities/
│   │   └── .gitkeep          # 业务实体（纯 Dart，无 Flutter 依赖）
│   └── repositories/
│       └── .gitkeep          # 抽象接口定义
├── data/
│   ├── datasources/
│   │   └── .gitkeep          # 远程/本地数据源
│   └── repositories/
│       └── .gitkeep          # 接口实现
├── application/
│   └── providers/
│       └── .gitkeep          # Riverpod providers / BLoC
└── presentation/
    ├── pages/
    │   └── .gitkeep          # 页面级 Widget
    └── widgets/
        └── .gitkeep          # 可复用 Widget
test/
analysis_options.yaml
pubspec.yaml

## 层级说明

依赖方向（严格单向）：
  domain → data → application → presentation
  ↑         ↑          ↑              ↑
纯业务类型  数据实现    状态管理       UI 渲染

规则：
- domain/ 不得导入任何 Flutter 包（纯 Dart）
- data/ 实现 domain/ 中定义的抽象接口
- application/ 通过 Riverpod/BLoC 协调 data 与 presentation
- presentation/ 只读取状态，不直接调用 data

## analysis_options.yaml

include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    must_be_immutable: error

linter:
  rules:
    always_declare_return_types: true
    avoid_dynamic_calls: true
    avoid_print: true
    avoid_unnecessary_containers: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    sized_box_for_whitespace: true
    use_key_in_widget_constructors: true

## pubspec.yaml 初始内容

name: <项目名>
description: <项目描述>
version: 0.1.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.0.0
  go_router: ^13.0.0
  freezed_annotation: ^2.0.0
  json_annotation: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.0.0
  freezed: ^2.0.0
  json_serializable: ^6.0.0
  mocktail: ^1.0.0

## Lint 验证命令

flutter analyze
