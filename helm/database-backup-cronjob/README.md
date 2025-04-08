# Values.yaml
Before applying the values.yaml, please ensure below values have been replaced based on your case

`cronjob.schedule` : This will define the point in time whith that interval when the job should start. More detail please refer to [here](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

`cronjob.image`: This image is built on [here](https://git.indocresearch.org/platform/platform_maintenance/tree/master/kubernetes/database-backup-cronjob/dockerfiles/single-db). (Note: This image is for single db backup, which db server has only one database needs to be backed up)

`pghost`: This is the internal domain name of the database server which is going to be backed up. The format is `<ServiceName>.<Namespace>`

`dbUsernameInVault`: This is the database username variable in valut, which is referring to the actual database username. You have to add the username value in the valut before applying this deployment

`dbPwdInVault`: This is the database password variable in valut, which is referring to the actual database password. You have to add the password value in the valut before applying this deployment

`dbNameInVault`: This is the database name variable in valut, which is referring to the actual database name. You have to add the db name value in the valut before applying this deployment

`vault_token`: This is the vault token which has read access in order to fetch the values of the database username/password/name.

`db_max_backup`: This defines the maximum number of database backup files to retain

---

# Usage
First, you need to **add the repository** to your local repo list:
```
helm repo add --username <gitlabUsername> --password <gitlabAccessToken> charite-kubernetes-repo https://git.bihealth.org/api/v4/projects/860/packages/helm/stable
```
> Note:  Please replace  **gitlabUsername** and **gitlabAccessToken** accordingly. Also, since the repo is in Charite Gitlab. Please make sure to connect to Charite's VPN before proceeding this step.

Second, **update your helm reop** with below command:
```
helm repo update
helm search repo charite-kubernetes-repo
```

Third, **install the helm chart** with the updated values.yaml:
```
helm install -n <namespace>  <releaseName> charite-kubernetes-repo/database-backup -f values.yaml
```
> Note: Please replace **namespace** and **releaseName** accordingly