const Web3 = require("web3");
var USD = artifacts.require("./USD.sol");
var JLMarket = artifacts.require("./JLMarket.sol");
var gStable = artifacts.require("./gStable.sol");
var Swap = artifacts.require("./Swap.sol");
var Vault = artifacts.require("./Vault.sol");

module.exports = function (deployer) {
  // USD
  // deployer.deploy(USD);
  //
  // gStable
  // deployer.deploy(gStable, "gTTD", "gTTD");
  //
  // JLMarket
  // deployer.deploy(
  //   JLMarket,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "jUSDD",
  //   "jUSDD"
  // );
  //
  // Swap
  deployer.deploy(
    Swap,
    "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
    "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
    "TY72rJ9tjnQSxgsqUDuXPUh2oPWC7cRmY6"
  );
  // Vault
  // deployer.deploy(
  //   Vault,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TY72rJ9tjnQSxgsqUDuXPUh2oPWC7cRmY6"
  // );
};
