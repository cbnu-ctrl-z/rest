import 'package:event_bus/event_bus.dart';

// 글로벌 EventBus 인스턴스
EventBus eventBus = EventBus();

// 프로젝트 생성 이벤트
class ProjectCreatedEvent {}

// 프로젝트 탭으로 전환 이벤트
class SwitchToProjectTabEvent {}