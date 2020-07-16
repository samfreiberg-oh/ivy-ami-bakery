# ivy ami-bakery

Bakes tasty AMIs, just for you!

`Packer + Ansible = <3` 

# How to create an Ivy environment

Go [here](https://github.com/nxtlytics/ivy-documentation/blob/master/howto/Processes/Creating_new_AWS_GovCloud_accounts.md#setup-ivy-environment-works-on-commercial-and-govcloud-aws)

## Structure

- `providers` - cloud providers and their image sets  
  - `images` - sets of Ansible roles that can be ran against an instance to create a machine image for the given provider  
    An `image` will translate into an `ami` or the provider-specific version of a machine image.
  
- `roles` - ansible roles applied against a given image  
  Plain Jane Ansible roles.

## How do I use this?

This requires:
- packer
- docker (on the host)
- IAM role

```
Bake AMI from Ansible roles using Packer

 Usage: build.sh -p PROVIDER -i IMAGE -r REGIONS -m MULTI-ACCOUNT_PROFILE [-d]

 Options:
   -p    provider to use (amazon|google|nocloud|...)
   -r    regions to copy this image to (comma separated values)
   -m    awscli profile that can assume role to list all accounts in this org
   -i    image to provision
   -d    enable debug mode
```

Sample:
```
AWS_PROFILE=your-profile ./build.sh -p amazon -i ivy-base
```
