# GWAS-demo
starter scripts for GWAS

## Start an Image

Go to [JetStream](https://jetstream2.exosphere.app/)

Login and select the IntDemo allocation

Click `Create > Instance` on the right-hand side

Click `By Image` and search for `IntBio-2026-image`, click `Create Instance` 

Choose a name e.g. `Julin-GWAS` 

Choose flavor `m3.large`

Select Custom Disk Size of `100GB`

Enable Web Desktop: `Yes`

If you select `JM-Public-Key` it will make it easier for me to access your instance for troubleshooting

Click `Create`

## Use your image

Once it has booted, then click `web desktop`

If the screen resolution is not good, `settings > displays`

(Note there are other connection options, including SSH from the terminal, and VS code remote server)

## SSH keys

Will need to set up an SSH key for github authentication.  See instructions [here](https://jnmaloof.github.io/BIS180L_web/2026/03/31/1-public-key-private-key/)

## Set your git rebase strategy
If you don't do this you may encounter issues when pulling changes from the remote repository.
```bash
git config --global pull.rebase false
``` 


## REMEMBER TO SHELVE YOUR INSTANCE WHEN YOU ARE NOT USING IT!

