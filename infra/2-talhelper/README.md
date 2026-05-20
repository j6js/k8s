# `2-talhelper` | 2. Talhelper

Step 2 in the infra deployment is to bootstrap and prepare the cluster for step 3 (which requires that a kubeconfig file exists, and the default CNI is disabled). This folder will also be required when upgrading and/or rebooting nodes, or the whole cluster.

This step requires talhelper and talosctl (both in mise config), as well as step 1 to have finished.