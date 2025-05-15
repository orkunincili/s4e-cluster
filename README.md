# 🚀 Kubernetes Tabanlı Kuyruk Tüketim ve İzleme Sistemi

Bu proje, Kubernetes üzerinde mesaj kuyruklarına iş atan, bu işleri tüketen ve sistem durumunu izleyen tam entegre bir otomasyon çözümüdür. Sistem, kuyruk yoğunluğuna göre pod ölçeklemesi yaparak kaynak kullanımını optimize eder.

---

## 🧱 Genel Mimarî

```mermaid
flowchart TD
    JP[Job Publisher (CronJob)]
    MQ[LavinMQ]
    CS[Consumer Pods]
    SC[Scaler Service]
    MON[Prometheus + Grafana]
    LOG[EFK Stack (Elasticsearch-Fluentd-Kibana)]

    JP --> MQ
    MQ --> CS
    MQ --> SC
    CS --> LOG
    SC --> MON
    CS --> MON
```

---

## ⚙️ Kullanılan Bileşenler

| Bileşen | Açıklama |
|--------|----------|
| ☸️ **Kubernetes** | 3 node'lu cluster (1 master + 2 worker) |
| 🧰 **KubeSpray** | Cluster kurulumu |
| 🔧 **Helm** | Prometheus ve bazı bileşenlerin kurulumu |
| 📬 **LavinMQ** | Mesaj kuyruğu servisi |
| 📈 **Prometheus & Grafana** | Metrik toplama ve görselleştirme |
| 📄 **EFK Stack** | Log toplama (Elasticsearch, Fluentd, Kibana) |
| 🐍 **Job Publisher (Python)** | Kuyruğa düzenli iş ekler |
| 🐍 **Consumer (Python)** | İşleri tüketir |
| 🐍 **Scaler (Python)** | Kuyruktaki iş sayısına göre pod’ları ölçekler |

---

## 🔁 İş Akışı

### 🧨 Job Publisher

- Her **10 dakikada bir**, kuyruklara **100 adet job** gönderir.
- `CronJob` olarak çalışır.
- Python ile yazılmıştır.

### 🧲 Consumer

- Kuyruktan mesajları çeker ve işler.
- Varsayılan olarak **0 replica** olarak deploy edilmiştir. 

### 📈 Scaler Servisi

- 5 saniyede bir LavinMQ REST API’sini sorgular.
- Eğer job sayısı > 100 ise `consumer` deployment'ını **25 replica**'ya çıkarır.
- Job yoksa replica sayısını **0** yapar.

---

## 🖥️ İzleme ve Loglama

### 📊 Prometheus + Grafana

- CPU, bellek, pod sayısı gibi metrikler toplanır.
- LavinMQ ve scaler metrikleri de entegredir.
- Grafana’da özel dashboard'lar tanımlanmıştır.

### 📑 EFK (Elasticsearch, Fluentd, Kibana)

- Fluentd tüm pod loglarını Elasticsearch’e yollar.
- Kibana’dan tüm loglar aranabilir ve filtrelenebilir.

---

## 🚀 Kurulum
Projenin geliştirme ortamı
```

PRETTY_NAME="Ubuntu 22.04.4 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.4 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy

```

Tek komutla tüm sistemi kurabilirsiniz:


```bash
cd installation
./install.sh
```

### `install.sh` ne yapar?

1. Gerekli araçları kurar (`multipass`, `kubectl`, `helm`, vs).
2. 3 node’lu Kubernetes cluster'ı kurar.
3. CoreDNS ayarlarını yapar.
4. Prometheus + Grafana stack’ini kurar.
5. LavinMQ, job publisher, consumer, scaler, EFK stack kurulumlarını yapar.

---

## 📁 Proje Klasör Yapısı

```
.
├── consumer/                # Tüketici kodları ve deployment
├── efk/                     # Elasticsearch, Fluentd, Kibana manifest dosyaları
├── installation/            # Kurulum scriptleri
├── job-publisher/           # CronJob + Python kodu
├── prometheus-stack/        # Helm chart ve config'ler
├── scaler/                  # Otomatik scaler kodu ve deployment
├── service-monitor/         # LavinMQ metrikleri için Prometheus yapılandırması
└── scaledobject/            # (KEDA kullanılmadıysa boş bırakılabilir)
```

---

## 🔐 Güvenlik ve İzolasyon

- Her servis kendi `namespace` altında çalışır.
- LavinMQ API erişimi için `ServiceAccount` ve `Role` tanımları mevcuttur.
- Prometheus için `ServiceMonitor` ve `Secret`'lar tanımlıdır.

---

## 🧪 Test Edildi

- Kuyruğa her 10 dakikada bir 100 job eklendiğinde consumer pod’ları otomatik olarak ölçekleniyor.
- Kuyruk boşaldığında 0 pod’a düşülüyor.
- Monitoring ve loglama düzgün çalışıyor.

---

## 📌 Notlar

- Bu projede KEDA yerine custom scaler servisi yazılmıştır.
- `scaledobject/` klasörü, istenirse KEDA ile ilerlemek için hazır bırakılmıştır.

---


