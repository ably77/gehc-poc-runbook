[Back to Table of Contents](./README.md) :blue_book:

## Lab6 - Create the gateways workspace

An interesting item here is that we create the `Workspace` on the management plane but can create the `WorkspaceSettings` on any cluster we want.  

If you look on any of the other remote clusters, however, you will not find the `WorkspaceSettings` nor will you find it in the management cluster.

The `importFrom` and `exportTo` concepts can be difficult to explain in the abstract, particularly if your audience is thinking about translated resources.  At this point, simply explain that we are using label selectors to allow bookinfo to expose their services to the gateways namespace and defer explanation until we can see the `VirtualGateway` and `RouteTable` in action.

| Previous | Next |
| :------- | ---: |
| :arrow_left: [Previous - Lab5 - Deploy and register Gloo Mesh](./lab5.md) | [Next - Lab7 - Create the bookinfo workspace](./lab7.md) :arrow_right: | 

