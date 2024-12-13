from __future__ import annotations
from dataclasses import dataclass
import logging
import subprocess

from kubernetes import client, config
from prometheus_client import Gauge
from kubernetes.client.models.v1_persistent_volume_list import V1PersistentVolumeList
from kubernetes.client.models.v1_persistent_volume import V1PersistentVolume


_logger = logging.getLogger(__name__)


@dataclass
class Volume:
    pvc_name: str
    pv_name: str
    storage_path: str


class LocalMetricsExporter:
    gauge: Gauge
    volumes: list[Volume]
    k8s_client: client.CoreV1Api

    def __init__(self, incluster: bool = True, config_file: str | None = None):
        try:
            if incluster:
                config.load_incluster_config()
            elif config_file:    
                config.load_config(config_file)
            else:
                config.load_config()
            self.k8s_client = client.CoreV1Api()
        except config.ConfigException as e:
            _logger.error(f"Failed to load k8s config: {e}")
            raise

        self.volumes = []
        self.gauge = Gauge(
            name="lse_pv_used_bytes",
            documentation="The amount of bytes used by local storage volume",
            labelnames=["pvc_name", "pv_name", "storage_path"],
        )

    def get_volumes(self) -> list[Volume]:
        volumes = []
        pvs: V1PersistentVolumeList = self.k8s_client.list_persistent_volume()
        for pv in pvs.items:
            if pv.spec.local:
                volumes.append(
                    Volume(
                        pvc_name=pv.spec.claim_ref.name,
                        pv_name=pv.metadata.name,
                        storage_path=pv.spec.local.path,
                    )
                )
        return volumes

    @staticmethod
    def get_volume_usage(volume: Volume) -> int | None:
        try:
            result = result = subprocess.run(
                ["du", "-sb", f"/volumes/{volume.pv_name}"],
                capture_output=True,
                text=True,
                check=True,
            )
            size = result.stdout.split("\t")[0]
            return int(size)
        except Exception as e:
            _logger.error(f"Failed to get volume usage for {volume.storage_path}: {e}")
            return None


def main():
    lme = LocalMetricsExporter()
    volumes = lme.get_volumes()
    total = 0
    for v in volumes:
        # print(lme.get_volume_usage(v))
        result = lme.get_volume_usage(v)
        total += result if result is not None else 0
        print(result, v.pv_name, v.pvc_name)

    print(f"total: {total}")


if __name__ == "__main__":
    main()
