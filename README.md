# <img src="logo.png" alt="drawing" width="40"/> Admission Controller 


The controller applies sensible defaults for pod's securityContext `runAsUser` value. It validates that security context `runAsNonRoot` is not defined when `runAsUser` is set to 0, as you cannot run as nonRoot and run as user 0. If no `runAsUser` value is defined, it will assign a default value of 2000.

- [Prepare Images](#prepare-images)
- [Deploy Admission Controller](#deploy-admission-controller)
- [Verify Admission Controller](#verify-admission-controller)

## Prepare Images

The project can be built by running `make`. The images are pushed by running `make push-image`.  

## Deploy Admission Controller

To deploy, run the `prepare.sh` in your terminal to create a CA, certificate, and private key for the controller and generate the secret, and the deployment manifests.
```bash
kubectl apply -f k8s/ns.yaml

kubectl apply -f k8s/secret-webhook-server-tls.yaml

kubectl apply -f k8s/admission-controller.yaml
```

## Verify Admission Controller

First, apply a pod with a conflicting securityContext. We will define `runAsUser` equal to 0, and `runAsNonRoot`.

```yaml
kubectl apply -f -<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: conflict
  labels:
    app: conflict
spec:
  restartPolicy: Never
  securityContext:
    runAsNonRoot: true
    runAsUser: 0
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "echo Running as user $(id -u)"]
EOF
```

output

```bash
Error from server: error when creating "STDIN": admission webhook "admission-controller.admission.svc" denied the request: runAsNonRoot specified, but runAsUser set to 0 (the root user, contradictory)
```

Apply a pod without `runAsUser` defined

```yaml
kubectl apply -f -<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: defaults
  labels:
    app: defaults
spec:
  restartPolicy: OnFailure
  containers:
    - name: busybox
      image: nginx
      command: ["sh","-c","sleep 9999"]
EOF

kubectl wait --for=condition=ready pod/defaults

kubectl get po defaults -ojsonpath='{ .spec.securityContext }' | jq
```

output

```json
{
  "runAsNonRoot": true,
  "runAsUser": 20000
}
```


Define `runAsUser` and override admission controller

```yaml
kubectl apply -f -<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: override
  labels:
    app: override
spec:
  restartPolicy: OnFailure
  securityContext:
    runAsNonRoot: false
  containers:
    - name: root
      securityContext:
        runAsUser: 0
      image: nginx
      command: ["sh","-c","sleep 9999"]
EOF

kubectl wait --for=condition=ready pod/override

kubectl get po override -ojsonpath='{ .spec.containers[*].securityContext }' | jq

kubectl get po override -ojsonpath='{ .spec.securityContext }' | jq
```

output

```json
{
  "runAsUser": 0
}
```

output

```json
{
  "runAsNoneRoot": false
}
```
