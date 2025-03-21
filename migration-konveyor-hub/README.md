# Konveyor Hub Migration Journey

This repository documents our experience deploying and using Konveyor Hub, a comprehensive application modernization platform that helps organizations analyze, assess, and plan the migration of their applications to cloud-native environments. We tracked everything along the way, from setting up the infrastructure to running analyses, to learn how the platform was designed and how it operates.

> **Note**: This documentation is based on our reverse engineering of Konveyor Hub's behavior and architecture. While we've made every effort to accurately document our findings, please refer to the [official Konveyor documentation](https://www.konveyor.io/docs/) for authoritative information and the most up-to-date details.

## Our Journey

### Step 1: Core Services Architecture

Our analysis of the system revealed a microservices-based setup with clear seperation of concerns. The main pods—tackle-hub, tackle-ui, tackle-operator, and konveyor—each had specific roles while staying loosely connected. The Konveyor operator's function in handling lifecycle management and resource allocation was aligned with Kubernetes 'Native' principles.

### Step 2: Job Management

Our review of the Konveyor Hub job system revealed a workflow system architecture. The init job, with its three-container design (extract, util, and pull), further showed careful separation of concerns in the setup process. The manifest processing sequence, particularly the order of processing various YAML files, suggests a well defined dependency management strategy.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Azure Kubernetes Service                        │
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   Tackle UI  │     │ Tackle Hub  │     │  Tackle      │                │
│  │  (Port 8181) │◄───►│ (Port 8080) │◄───►│  Operator    │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│       ▲                      ▲                      ▲                       │
│       │                      │                      │                       │
│       ▼                      ▼                      ▼                       │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   Analysis   │     │   Analysis   │     │   Analysis   │                │
│  │   Results    │     │   Tasks      │     │   Jobs       │                │
│  └──────────────┘     └──────────────┘     └──────────────┘                │
│       ▲                      ▲                      ▲                       │
│       │                      │                      │                       │
│       ▼                      ▼                      ▼                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐
│  │                                                                         │
│  │                              Analysis Pod                               │
│  │                                                                         │
│  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│  │  │   Extract   │     │     Util     │     │    Pull      │            │
│  │  │ Container   │◄───►│  Container   │◄───►│  Container   │            │
│  │  └──────────────┘     └──────────────┘     └──────────────┘            │
│  │                                                                         │
│  └─────────────────────────────────────────────────────────────────────────┘
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐
│  │                                                                         │
│  │                              Storage Layer                              │
│  │                                                                         │
│  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐            │
│  │  │   SQLite    │     │   Bucket     │     │   Analysis   │            │
│  │  │  Database   │◄───►│   Storage    │◄───►│   Artifacts  │            │
│  │  │  (10Gi)     │     │  (100Gi)     │     │             │            │
│  │  └──────────────┘     └──────────────┘     └──────────────┘            │
│  │                                                                         │
│  └─────────────────────────────────────────────────────────────────────────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Legend:
──► : Internal Communication
◄──► : Bidirectional Communication
┌─┐ : Pod/Container

The Konveyor Hub system is built with three main parts working together: the UI, Hub, and Operator. The system uses two types of storage: a small SQLite database for quick access to information, and a larger bucket storage for big files. The bucket storage system is implemented as a 100Gi persistent volume mounted at `/buckets` inside the tackle-hub pod, managed through the `tackle-hub-bucket-volume-claim`. This storage is used for managing large analysis artifacts, temporary files, and binary data. The analysis system uses three containers: extract for pulling code, util for processing, and pull for repository management.

## Core Components

### 1. Infrastructure Layer

We deployed Konveyor Hub to Azure Kubernetes Service (AKS) using Terraform. Our infrastructure setup included:

- AKS cluster with 8-core nodes
- Azure Managed Disks for persistent storage
- Kubectl port forwards to access the hub running in AKS

The deployment was managed through Terraform modules.

### 2. Data Persistence Layer

The storage system is designed to handle different types of data efficiently. The SQLite database is optimized for quick queries and metadata management, while the bucket storage system is better suited for handling large files and analysis artifacts. All data access is made through REST endpoints, following common web service patterns.

### 3. Core Services

#### Tackle Hub (Backend)

The Hub service is the main control center of the system. It manages applications and schedules analysis tasks, coordinating work across different parts of the system. The service handles database operations for storing application information and organizing data with tags and categories. It provides API endpoints that the UI uses to communicate with the backend, keeping the frontend and backend cleanly separated.

#### Tackle UI (Frontend)

The UI service handles all user interactions and keeps the interface up to date in real-time. Built with the [GIN web framework](https://gin-gonic.com/), which we identified through the service's HTTP request handling patterns and logging output, it routes requests to the Hub service through a proxy, with special handling for `/hub/*` paths.

#### Tackle Operator

The operator service manages the system through Kubernetes Custom Resource Definitions (CRDs). It handles four main types of resources:

1. **Addons**
   - Manages addon components and their lifecycle
   - Sets up resources and security settings
   - Handles health checks and monitoring
   - Manages storage access

2. **Extensions**
   - Manages extension components
   - Handles container setup and resources
   - Sets up security and health monitoring
   - Manages storage access

3. **Tackles**
   - Manages application configurations
   - Tracks application state and updates
   - Handles status updates
   - Supports future extensions

4. **Tasks**
   - Manages task execution
   - Handles task dependencies
   - Manages data flow between components
   - Tracks task progress

### 4. Analysis Components

#### Analysis Task Pod

The analysis pods use three containers to handle different parts of the analysis process. The extract container pulls code from repositories, the util container processes the code, and the pull container manages repository access. These pods are temporary.

#### Rule Sets

The system uses different types of rules to analyze code. These rules are organized into categories for discovering code patterns, checking cloud readiness, and identifying technology usage.

### 5. Resource Configuration

The system manages resources through Kubernetes Custom Resource Definitions (CRDs). The main configurations for CPU, memory, and other resources are handled by the `addons.tackle.konveyor.io` and `extensions.tackle.konveyor.io` CRDs. These handle:

1. **Container Resources**
   - CPU and memory limits
   - Storage requirements
   - Resource quotas

2. **Component Settings**
   - Health checks
   - Security settings
   - Volume mounts

3. **System Settings**
   - Namespace limits
   - Pod scheduling
   - Network policies

## Analysis Process

The analysis process follows a workflow. First, it creates tasks and sets up pods to handle the analysis. Then it processes repositories by pulling code and setting up the environment. Finally, it runs the analysis while keeping users updated on progress in the UI.

## Configuration Files

The system uses a simple configuration setup. It separates basic settings and rule sets into different files, making it easy to maintain and update.

## Monitoring and Logging

The system keeps track of its operation through logs and monitoring. Each component logs its activities, and the system tracks analysis progress. Users can see real-time updates about the system's health and status.

Please refer to the [official Konveyor documentation](https://www.konveyor.io/docs/) for the most up-to-date information. 