<a href="https://www.instagram.com/ttomasferrari/">
    <img align="right" alt="Abhishek's Instagram" width="22px" 
    src="https://i.imgur.com/EzpyGdV.png" />
</a>
<a href="https://twitter.com/tomasferrari">
    <img align="right" alt="Abhishek Naidu | Twitter" width="22px"         
    src="https://i.imgur.com/eFVBTVz.png" />
</a>
<a href="https://www.linkedin.com/in/tomas-ferrari-devops/">
    <img align="right" alt="Abhishek's LinkedIN" width="22px" 
    src="https://i.imgur.com/pMzVPqj.png" />
</a>
<p align="right">
    <a >Find me here: </a>
</p>
<!-- <p align="right">
    <a  href="/docs/readme_es.md">Versión en Español</a>
</p> -->

<p title="Banner" align="center"> <img src="https://i.imgur.com/FbsIwSJ.jpg"> </p>

# INDEX

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Run Backstage Locally](#run-backstage-locally)
- [Customising Backstage](#customising-backstage)
  - [Plugins I've Added](#plugins-ive-added)
  - [Templates I've Created](#templates-ive-created)
  - [My Arbitrary Rules](#my-arbitrary-rules)
- [Run Backstage In Minikube](#run-backstage-in-minikube)
- [Conclusion](#conclusion)

</br>
</br>

# INTRODUCTION
This is a spin-off of my [Automate All The Things](https://github.com/tferrari92/automate-all-the-things) DevOps project. While working on the [Nirvana Edition](https://github.com/tferrari92/automate-all-the-things-nirvana) - which will include a Developer Portal built with Backstage - I'm creating this smaller lab for anyone who wants to start experimenting with this tool.

Backstage is a framework for creating developer portals. This developer portal should act as a centralized hub for your organization, providing access to documentation, infrastructure, tooling, and code standards. It gives developers everything they need to create and manage their projects in a consistent and standardized manner. If you are new to Backstage, I invite you to read [this brilliant series of articles](https://www.kosli.com/blog/evaluating-backstage-1-why-backstage/) by Alexandre Couedelo.

We'll be using a GitOps methodology with Helm, ArgoCD and the App Of Apps Pattern. There is some extra information [here](/docs/argocd-notes.md), but you are expected to know about these things.

</br>
</br>

# PREREQUISITES
- Active DockerHub account
- minikube installed
- kubectl installed
- helm installed
- nodejs installed
- nvm installed
- yarn installed

</br>
</br>


# INITIAL SETUP
Before deploying Backstage in a Kubernetes environment (Minikube), we need to build it locally.

<!-- Install nvm:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
``` -->

Make sure you are using Node.js version 18
```bash
nvm install 18
nvm use 18
nvm alias default 18
```
<!-- 
Install nodejs and npm
```bash
sudo apt update
sudo apt install nodejs
sudo apt install npm
``` -->

Make sure you are using Yarn version 1.22.19
<!-- # sudo npm install --global yarn -->
```bash
yarn set version 1.22.19
yarn --version
```
<!-- # yarn global add concurrently -->
</br>

### Get GitHub PAT (Personal Access Token)

Navigate to the GitHub PAT creation page. Select "Generate new token (classic)". 

Choose a name and a value for expiration. Under scopes select "repo" and "workflow". It should look something like this:

<p title="GitHub Token" align="center"> <<img width="650" src="https://i.imgur.com/zTn7gDI.png"> </p>

Click Generate token. Store the token somewhere safe.

</br>

### Set up secrets for GitHub workflows
This is only required if you intend to use GitHub workflows.

Create these two repository secrets on your GitHub repo:
- DOCKER_USERNAME: <your-dockerhub-username\>
- DOCKER_PASSWORD: <your-dockerhub-password\>

### Set up GitHub OAuth
https://github.com/settings/applications/new
Application name	Backstage
Homepage URL	http://localhost:3000/
Authorization callback URL	http://localhost:7007/api/auth/github/handler/frame

save client id and secret in a safe fplace

</br>

### Fork and clone the repo
Let's turn this whole deployment into your own thing.

1. Fork this repo. Keep the repository name "backstage-minikube-lab-reloaded".
1. Clone the repo from your fork:

```bash
git clone https://github.com/<your-github-username>/backstage-minikube-lab-reloaded.git
```

2. Move into the directory:

```bash
cd backstage-minikube-lab-reloaded
```

2. Run the initial setup script. Come back when you are done:

```bash
chmod +x initial-setup.sh
./initial-setup.sh
```

4. Commit and push your customized repo to GitHub:

```bash
git add .
git commit -m "customized repo"
git push
```

</br>
</br>

# RUN BACKSTAGE LOCALLY
Everything's ready to start playing with Backstage.

Create env var for your GitHub token
```bash
export GITHUB_TOKEN=<your-github-token> AUTH_GITHUB_CLIENT_ID=<your-github-auth-client-id> AUTH_GITHUB_CLIENT_SECRET=<your-github-auth-client-secret>
```

cd into my-backstage directory
```bash
cd backstage/my-backstage/
```

Then run
```bash
cd backstage/my-backstage/
yarn install
yarn tsc
yarn dev
```

Open your browser and go to localhost:3000. You should see the Backstage web UI.

Every time you make changes to the Backstage code, it's recommended you test it by running it locally with "yarn dev" like you just did. This will be much faster that testing every change in Minikube.

</br>
</br>

# CUSTOMISING BACKSTAGE
Before deploying to Minikube, lets go over some things you'll find in this Backstage deployment.

Backstage is designed to be flexible and allow every organization to adapt it to their own needs. It is not a black-box application where you install plugins; rather, you maintain your own source code and can modify it as needed.

I've already added some custom stuff to the default Backstage installation that I think are essential. 

</br>

## OAuth with GitHub
This allows the user to sign in using their GitHub account.

You can add a Sign in page by uncommenting these lines in the [App.tsx file](/backstage/my-backstage/packages/app/src/App.tsx):
```js
// import { githubAuthApiRef } from '@backstage/core-plugin-api';
// import { SignInPage } from '@backstage/core-components';

  // components: {
  //   SignInPage: props => (
  //     <SignInPage
  //       {...props}
  //       auto
  //       provider={{
  //         id: 'github-auth-provider',
  //         title: 'GitHub',
  //         message: 'Sign in using GitHub',
  //         apiRef: githubAuthApiRef,
  //       }}
  //     />
  //   ),
  // },
```

</br>

## Plugins I've added

### Kubernetes plugin
The [Kubernetes plugin](https://backstage.io/docs/features/kubernetes/) in Backstage is a tool that's designed around the needs of service owners, not cluster admins. Now developers can easily check the health of their services no matter how or where those services are deployed — whether it's on a local host for testing or in production on dozens of clusters around the world.

It will elevate the visibility of errors where identified, and provide drill down about the deployments, pods, and other objects for a service.

### GitHub Discovery plugin 
The [GitHub Discovery plugin](https://backstage.io/docs/integrations/github/discovery) automatically discovers catalog entities within a GitHub organization. The provider will crawl the GitHub organization and register entities matching the configured path. This can be useful as an alternative to static locations or manually adding things to the catalog. This is the preferred method for ingesting entities into the catalog.

I've installed it without events support. Updates to the catalog will rely on periodic scanning rather than real-time updates.

You can check the automatic discovery configuration under catalog.providers.github in the [app-config.yaml](/backstage/my-backstage/app-config.yaml) and [app-config.production.yaml](/backstage/my-backstage/app-config.production.yaml) files.

**IMPORTANT**: We use [app-config.yaml](/backstage/my-backstage/app-config.yaml) for local testing (when running `yarn dev`) and [app-config.production.yaml](/backstage/my-backstage/app-config.production.yaml) when deploying to Minikube.

### GitHub Actions plugin 
The [GitHub Actions plugin](https://roadie.io/backstage/plugins/github-actions/) actually cames by default, but I added "Recent Workflow Runs" card to the overview tab of Components. All workflows will be mixed up because we are using monorepo. If we had a repo for each service, then this would make a lot more sense.

### GitHub Insights plugin
The [GitHub Insights plugin](https://roadie.io/backstage/plugins/github-insights/) lets you see the GitHub insights of the repo like what languages are used, who are the contributors and a preview of the README.

### ArgoCD plugin
The [ArgoCD plugin](https://roadie.io/backstage/plugins/argo-cd/) will display (on the Overview tab of each component) the state of all ArgoCD applications related to it.

### Grafana plugin
I didn't take the time to build an appropiate dashboard for each of our services. Building dashboards is out of the scope of this lab. I've linked to a random dashboard just to demosntrate how the integration works.
https://roadie.io/docs/integrations/grafana/

<!-- ### Homepage plugin
https://backstage.io/docs/getting-started/homepage/ 
https://www.kosli.com/blog/succeeding-with-backstage-part-1-customizing-the-look-and-feel-of-backstage/

### Changed App Theme
https://www.kosli.com/blog/succeeding-with-backstage-part-1-customizing-the-look-and-feel-of-backstage/ -->

<!-- ### GitHub Security Insights plugin 
https://www.kosli.com/blog/implementing-backstage-4-security-and-compliance/
https://roadie.io/backstage/plugins/security-insights/ -->

</br>

## Templates I've created

### New Backstage System
Creates a new Backstage System with the provided information. A System in Backstage is a collection of entities (services, resources, APIs, etc.) that cooperate to perform a some function. For example, we will have a System called "my-app" that includes the my-app-frontend service, the my-app-backend service, the my-app-redis database and the my-app-backend API.

It generates a Pull Request which includes a new System manifest. When merged, the System catalog entity will be automatically added to the Backstage catalog by the GitHub Discovery plugin.

</br>

### New Backstage Group
Creates a new Backstage group with the provided information. 

It generates a Pull Request which includes a new Group manifest. When merged, the Group catalog entity will be automatically added to the Backstage catalog by the GitHub Discovery plugin.

</br>

### New Backstage User
Creates a new Backstage user with the provided information. 

It generates a Pull Request which includes a new User manifest. When merged, the User catalog entity will be automatically added to the Backstage catalog by the GitHub Discovery plugin.

</br>

### New Node.js in existing repo
Creates all the boilerplate files and directories in an existing repo for deploying a new Node.js service in Kubernetes:
1. The application code directory and files, which will saved in [the application-code directory](/application-code/).
2. The kubernetes manifests directory and files, which will be saved in [the k8s-manifests directory](/k8s-manifests/).
RELAODED
3. The [backend service argocd application manifests](/argo-cd/applications/my-app/backend/): These are read by the App of Apps to 
3. The build and push GitHub workflow manifest, which will be saved [the .github/workflows directory](/.github/workflows/) (working with GitHub Workflows is out of the scope of this lab).

It generates a Pull Request which includes all these files al directories.

</br>

### New NGINX in existing repo
Creates all the boilerplate files and directories in an existing repo for deploying a new NGINX service in Kubernetes:
1. The application code directory and files, which will saved in [the application-code directory](/application-code/).
2. The kubernetes manifests directory and files, which will be saved in [the k8s-manifests directory](/k8s-manifests/).
RELAODED
3. The [backend service argocd application manifests](/argo-cd/applications/my-app/backend/): These are read by the App of Apps to 
3. The build and push GitHub workflow manifest, which will be saved [the .github/workflows directory](/.github/workflows/) (working with GitHub Workflows is out of the scope of this lab).

It generates a Pull Request which includes all these files al directories.

</br>

## My Arbitrary Rules

### App-config management 
The app-config is the file that defines the Backstage configuration. You will find three instances of app-config:
1. [The app-config.yaml file](/backstage/my-backstage/app-config.yaml): This is the config that will be used for development and testing purposes when running locally with `yarn dev` command.
2. [The app-config.production.yaml file](/backstage/my-backstage/app-config.yaml): This is the config that will be used for building the Docker image that will be deployed in Minikube. You will notice that it's missing the catalog configuration. That's because the catalog configuration will be passed in through a ConfigMap.
3. [The helm chart values-custom.yaml file](/backstage/helm-chart/values-custom.yaml): Since the catalog configuration is something that might need to be modified more often, I decided it should be specified in a ConfigMap and not hard coded into the Docker image. You can find the catalog configuration in the values-custom.yaml file of the Backstage helm chart. Helm will create a ConfigMap with these values and pass it in to the Backstage pod at the time of creation.

</br>

### Users and groups hierarchy
I decided that user and group hierarchy should be defined from the bottom up. To me, it makes more sense that childs should keep track of their parents than parents of their childs.

So we will not define the members of a group in the Group manifest, but we will define the group a user belongs to in the spec.memberOf of the User manifest. 

Also, we will always have the spec.children value of Group manifests as an empty array and the spec.parent value filled with whoever the parent group of that group is. If it has no parent, the value of spec.parent should be "root".

</br>
</br>


# RUN BACKSTAGE IN MINIKUBE
Ok, lets run Backstage in Minikube. `Ctrl + C` to kill the `yarn dev` process.

We first need to build and push the Backstage Docker image. Login to Docker
```bash
docker login
```
Then run the build-push-image.sh script
```bash
chmod +x build-push-image.sh
./build-push-image.sh
```

cd to the root of the repo:
```bash
cd ../..
```

Update the value of backstage.image.tag in the backstage values-custom.yaml 
```bash
vim helm-charts/infra/backstage/values-custom.yaml
```

Save and push to repo
```bash
git add .
git commit -m "Updated backstage image tag"
git push
```

If you have a Minikube cluster running, delete it first with `minikube delete`.

Now run the deploy-in-minikube.sh script to get everything setup:
```bash
chmod +x deploy-in-minikube.sh
./deploy-in-minikube.sh
```

Now go to localhost:8080 on your browser and Voilá!

You can also port-forward ArgoCD server to check everything is runnin fine:
```bash
chmod +x deploy-in-minikube.sh
./deploy-in-minikube.sh
```

</br>
</br>

# CONCLUSION
That's it! This is your own Backstage implementation now. 

Feel free to add your own plugins, templates and whatever else you might think of. Customize to fit your own needs.

For more DevOps and Platform Engineering goodness, check out my [Automate All The Things](https://github.com/tferrari92/automate-all-the-things) project.

Happy automating!

<!-- # EXCERCISE

## What we are starting off with
We are starting off with a Redis database and a backend. Everytime the backend recieves a request it gets the value of "count" from the Redis db and returns it to the user. Before returning it, it adds +1 to "count".

You can test it like this:
```bash
kubectl get pods -n my-app-dev -l app=my-app-backend-dev -o name | xargs -I {} kubectl exec -n my-app-dev {} -- curl -s localhost:3000
```

You should get:
```bash
{"count":1}%
```

You can test it on the other environments too:
```bash
kubectl get pods -n my-app-stage -l app=my-app-backend-stage -o name | xargs -I {} kubectl exec -n my-app-stage {} -- curl -s localhost:3000
kubectl get pods -n my-app-prod -l app=my-app-backend-prod -o name | xargs -I {} kubectl exec -n my-app-prod {} -- curl -s localhost:3000
```

## What we are doing
We are going to create the missing piece with the help of backstage, the frontend.

Let's analyze the backend. With this Gitops setup we have, there's a number of things that need to exist in order for the backend service to be deployed. These are:
1. The [my-app/backend directory](/my-app/backend/): In a real world scenario, the backend service would have its own repo where we would store all the application code. In this small lab we'll just save it in its own directory.
2. The [helm/my-app/backend directory](/helm/my-app/backend/): Here we save the Helm chart for our backend service. This of course would also be in its own repo on a real world scenario.
3. The [backend service argocd application manifests](/argo-cd/applications/my-app/backend/): These are read by the App of Apps to 
4. The [backend build pipeline]():

All of these files and directories we need to create for any new service we want to deploy. Luckily, we have Backstage Software Templates.

## How we are doing it

</br>
</br>










#### Backstage needs github api token to access software catalog. Get one on github console.

When creating a personal access token on GitHub, you must select scopes to define the level of access for the token. The scopes required vary depending on your use of the integration: https://backstage.io/docs/integrations/github/locations/#token-scopes
Reading software components:
    repo        
Reading organization data:
    read:org
    read:user
    user:email
Publishing software templates:
    repo
    workflow (if templates include GitHub workflows)



























##### Info interesante:
https://backstage.spotify.com/learn/backstage-for-all/software-catalog/4-modeling/
https://backstage.spotify.com/learn/standing-up-backstage/putting-backstage-into-action/8-integration/
https://backstage.spotify.com/learn/onboarding-software-to-backstage/onboarding-software-to-backstage/5-register-component/

##### Info datallada sobre objetos de tipo template:
https://backstage.io/docs/features/software-catalog/descriptor-format#kind-template
##### Aqui las acciones q puede hacer el template:
http://localhost:3000/create/actions
##### Para acciones q no existen default:
https://backstage.io/docs/features/software-templates/writing-custom-actions/
##### A note on RepoUrlPicker
In the template.yaml file of the template we created, you must have noticed ui:field: RepoUrlPicker in the spec.parameters field. This is known as Scaffolder Field Extensions.

These field extensions are used in taking certain types of input from users like GitHub repository URL, teams registered in catalog for the owners field, etc. Such field extensions can also be customized for your own organization. See https://backstage.io/docs/features/software-templates/writing-custom-field-extensions/

##### Aca hay ejemplos de templates:
https://github.com/backstage/software-templates

##### Software Templates at Spotify
At Spotify, we have dozens of Software Templates. We divide them into several disciples like Backend, Frontend, Data pipelines, etc. Inside Spotify, we also have stakeholder groups for Web, Backend, Data, etc. separately. These Software Templates are hosted on our internal GitHub enterprise, maintained and reviewed by the concerned experts in the discipline.

The Technical Architecture Group (TAG) at Spotify is the body responsible for reducing fragmentation by deciding on the various Backend, Frontend, Data frameworks to be used inside Spotify. Hence, new Software Templates with completely new frameworks are carefully discussed and reviewed.

Our Software Templates are fundamental to the concept of Golden Paths at Spotify. The Golden Path is the opinionated and supported way to build something (for example, build a backend service, put up a website, create a data pipeline). The Golden Path Tutorial is a step-by-step instructions that walks you through this opinionated and supported path.

The blessed tools — those on the Golden Path — are visualized in the Explore section of Backstage. Read more https://engineering.atspotify.com/2020/08/how-we-use-golden-paths-to-solve-fragmentation-in-our-software-ecosystem/


##### Component objects:
https://backstage.io/docs/features/software-catalog/descriptor-format/#overall-shape-of-an-entity





# Following this approach, no template will load in the UI if any one of those is broken!!!
  locations:
    - type: url
      target: https://github.com/tomasferrarisenda/backstage/blob/main/templates/all-templates.yaml
      rules:
        - allow: [Template]


## USAR PLUGIN DE AUTODISCOVERY POR LA MODALIDAD ACTUAL NO BORRA USERSAL SACARLOS DEL REPO
# EXPLICAR LO DE app-config.yaml y app-config.production.ymal
uno se usa para local (yarn dev), el otro apra el cluster. Ppalmente por la config para la bbdd postgress (en local no la utilizamos)




# BACKSTAGE
If the only change you've made is to the app-config.yaml (or other configuration files) and not to the application code itself, you don't necessarily need to run yarn build or yarn build:backend. The Docker image build process should copy the updated configuration files into the image.





# COSAS MODIFICADAS:
values custom de argo, ingress.enabled cambiado a false


AGREGARLE DESCRIPTION AL REPO DE GHUB -->
