const Web3 = require("web3");
var USD = artifacts.require("./USD.sol");
var JLMarket = artifacts.require("./JLMarket.sol");
var gStable = artifacts.require("./gStable.sol");
var Swap = artifacts.require("./Swap.sol");
var Vault = artifacts.require("./Vault.sol");

let currencies = ["gEUR"];

module.exports = function (deployer) {
  deployer.then(async () => {
    for (let i = 0; i < currencies.length; i++) {
      await deployer.deploy(gStable, currencies[i], currencies[i]);
      await deployer.deploy(
        Swap,
        "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
        "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
        gStable.address
      );
      await deployer.deploy(
        Vault,
        "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
        "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
        gStable.address
      );
      console.log(currencies[i]);
      console.log("gStable : ", gStable.address);
      console.log("Swap : ", Swap.address);
      console.log("Vault : ", Vault.address);
    }
  });
};

// module.exports = function (deployer) {
//   // USD
//   // deployer.deploy(USD);
//   //
//   //
//   // JLMarket
//   // deployer.deploy(
//   //   JLMarket,
//   //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
//   //   "jUSDD",
//   //   "jUSDD"
//   // );
//   //
//   // gStable
//   // deployer.deploy(gStable, "gAWG", "gAWG");
//   // Swap
//   deployer.deploy(
//     Swap,
//     "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
//     "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
//     "TP7RNcfoSkmTSA5ZSdKeXfUnBb1KoU51VY"
//   );
//   // Vault
//   // deployer.deploy(
//   //   Vault,
//   //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
//   //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
//   //   "TP7RNcfoSkmTSA5ZSdKeXfUnBb1KoU51VY"
//   // );
// };
