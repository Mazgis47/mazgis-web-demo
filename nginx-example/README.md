# Kubernetes

https://aws.amazon.com/premiumsupport/knowledge-center/eks-kubernetes-services-cluster/

kubectl apply -f nginx-deployment.yaml
kubectl get pods -l 'app=nginx' -o wide | awk {'print $1" " $3 " " $6'} | column -t
kubectl create -f clusterip.yaml
kubectl expose deployment nginx-deployment  --type=ClusterIP  --name=nginx-service-cluster-ip
kubectl get service nginx-service-cluster-ip
kubectl create -f nodeport.yaml
kubectl expose deployment nginx-deployment  --type=NodePort  --name=nginx-service-nodeport
kubectl get service/nginx-service-nodeport
kubectl get nodes -o wide |  awk {'print $1" " $2 " " $6'} | column -t
kubectl create -f loadbalancer.yaml
kubectl expose deployment nginx-deployment  --type=LoadBalancer  --name=nginx-service-loadbalancer
kubectl get service/nginx-service-loadbalancer |  awk {'print $1" " $2 " " $4 " " $5'} | column -t
curl ...
