#!/usr/bin/env python3
from diagrams import Cluster, Diagram, Edge
from diagrams.k8s.compute import Pod, Deployment, StatefulSet
from diagrams.k8s.network import Ingress, Service
from diagrams.k8s.storage import PersistentVolumeClaim as PVC
from diagrams.onprem.gitops import ArgoCD
from diagrams.onprem.client import Users
from diagrams.onprem.vcs import Github
from diagrams.onprem.container import Docker
from diagrams.onprem.monitoring import Grafana
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.network import Nginx

# Graph attributes for better visualization
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white",
    "pad": "0.8",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.2",
}

node_attr = {
    "fontsize": "11",
}

edge_attr = {
    "fontsize": "10",
}

with Diagram(
    "Kind Cluster Architecture",
    filename="architecture",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    # External
    users = Users("Users")
    github = Github("GitHub")
    
    with Cluster("Kind Cluster (dev01)"):
        
        # Ingress
        ingress = Nginx("Ingress\n*.localtest.me")
        
        with Cluster("GitOps"):
            argocd = ArgoCD("ArgoCD")
        
        with Cluster("Monitoring"):
            grafana = Grafana("Grafana")
            vmagent = Pod("vmagent")
            vmsingle = Pod("vmsingle")
            vmalert = Pod("vmalert")
            vm_pvc = PVC("vmsingle-pvc")
        
        with Cluster("Database"):
            cnpg = Deployment("CNPG\nOperator")
            postgres = PostgreSQL("PostgreSQL")
            pvc = PVC("PVC")
        
        with Cluster("Apps"):
            echo = Deployment("http-echo")
    
    # User flow
    users >> Edge(label="HTTP") >> ingress
    
    # Ingress routing
    ingress >> grafana
    ingress >> argocd
    ingress >> echo
    
    # GitOps
    github >> Edge(label="sync") >> argocd
    argocd >> Edge(style="dashed", color="gray") >> grafana
    argocd >> Edge(style="dashed", color="gray") >> cnpg
    argocd >> Edge(style="dashed", color="gray") >> echo
    
    # Monitoring
    vmagent >> vmsingle
    vmalert >> vmsingle
    grafana >> vmsingle
    vmsingle - vm_pvc
    
    # Database
    cnpg >> postgres
    postgres - pvc
    
    # Scraping (simplified)
    vmagent >> Edge(style="dotted", color="blue") >> postgres
    vmagent >> Edge(style="dotted", color="blue") >> argocd

