// Update the funkos list
update_funkos = function () {
  document.getElementById("update-funkos").click();
};

// Utility functions for secrets dialog
update_secrets = function () {
  document.getElementById("update-secrets").click();
};
add_secret = function () {
  clean_secret();
  document.getElementById("add-secret").show();
};
show_secret = function () {
  document.getElementById("add-secret").show();
};
clean_secret = function () {
  document.getElementById("new-secret-funko").value = "";
  document.getElementById("new-secret-name").value = "";
  document.getElementById("new-secret-password").value = "";
};
hide_secret = function () {
  document.getElementById("add-secret").close();
  update_secrets();
};

// Set/disable tab active state
const nodeList = document.querySelectorAll('nav[role="tab-control"] label');
const eventListenerCallback = setActiveState.bind(null, nodeList);

nodeList[0].classList.add("active"); /** add active class to first node  */

nodeList.forEach((node) => {
  node.addEventListener(
    "click",
    eventListenerCallback
  ); /** add click event listener to all nodes */
});

/** the click handler */
function setActiveState(nodeList, event) {
  nodeList.forEach((node) => {
    node.classList.remove("active"); /** remove active class from all nodes */
  });
  event.target.classList.add("active"); /* set active class on current node */
}
