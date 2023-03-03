const Web3 = require("web3");
var USDD = artifacts.require("./USD.sol");
var JLMarket = artifacts.require("./JLMarket.sol");
var gStable = artifacts.require("./gStable.sol");
var SwapStableCoin = artifacts.require("./SwapStableCoin.sol");
var VaultStableCoin = artifacts.require("./VaultStableCoin.sol");
var Rewards = artifacts.require("./Rewards.sol");


module.exports = function (deployer) {
// //   // USD
//   // deployer.deploy(USDD);
// //   //
// //   //
//   // JLMarket
//   // deployer.deploy(
//   //   JLMarket,
//   //   "TRcaXTbZgy17H2oUGqEUsYEgePbELAN9i8",
//   //   "jUSDD",
//   //   "jUSDD"
//   // );

  // // Rewards
  // deployer.deploy(Rewards);

  // // Swap
  // deployer.deploy(
  //   SwapStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS"
  // );

  // // Vault
  // deployer.deploy(
  //   VaultStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS"
  // );


// //   //
};




// For Nile Testnet

// let currencies = ["gXCD"];
// const nileUSDD = "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU";
// const nileJLUSDD = "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f";

// module.exports = function (deployer) {
//   deployer.then(async () => {
//     for (let i = 0; i < currencies.length; i++) {
//       await deployer.deploy(gStable, currencies[i], currencies[i]);
//       console.log(currencies[i]);
//       console.log("gStable : ", gStable.address);
//     }
//   });
// };



// For Shasta Testnet

// let currencies = ["gXCD"];
// const shastaUSDD = "TRcaXTbZgy17H2oUGqEUsYEgePbELAN9i8";
// const shastaJLUSDD = "TEP9rJhjRkKieNAvWQKoPmXYk7FeMVFZs8";

// module.exports = function (deployer) {
//   deployer.then(async () => {
//     for (let i = 0; i < currencies.length; i++) {
//       await deployer.deploy(gStable, currencies[i], currencies[i]);
//       await deployer.deploy(
//         Swap,
//         shastaUSDD,
//         shastaJLUSDD,
//         gStable.address
//       );
//       await deployer.deploy(
//         Vault,
//         shastaUSDD,
//         shastaJLUSDD,
//         gStable.address
//       );
//       console.log(currencies[i]);
//       console.log("gStable : ", gStable.address);
//       console.log("Swap : ", Swap.address);
//       console.log("Vault : ", Vault.address);
//     }
//   });
// };




// // For Tron Mainnet

// let currencies = ["gTTD","gXCD","gBBD","gJMD","gAWG","gDOP","gBSD","gKYD","gCUP","gHTG","gEUR"];
// const mainnetUSDD = "TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn";
// const mainnetJLUSDD = "TX7kybeP6UwTBRHLNPYmswFESHfyjm9bAS";

// module.exports = function (deployer) {
//   deployer.then(async () => {
//     for (let i = 0; i < currencies.length; i++) {
//       await deployer.deploy(gStable, currencies[i], currencies[i]);
//       await deployer.deploy(
//         Swap,
//         mainnetUSDD,
//         mainnetJLUSDD,
//         gStable.address
//       );
//       await deployer.deploy(
//         Vault,
//         mainnetUSDD,
//         mainnetJLUSDD,
//         gStable.address
//       );
//       console.log(currencies[i]);
//       console.log("gStable : ", gStable.address);
//       console.log("Swap : ", Swap.address);
//       console.log("Vault : ", Vault.address);
//     }
//   });
// };