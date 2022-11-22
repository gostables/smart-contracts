const Web3 = require("web3");
var USDD = artifacts.require("./USD.sol");
var JLMarket = artifacts.require("./JLMarket.sol");
var gStable = artifacts.require("./gStable.sol");
var Swap = artifacts.require("./Swap.sol");
var Vault = artifacts.require("./Vault.sol");


// Mock USDD and JLMarket creation on Testnets
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

//   // Swap
//   deployer.deploy(
//     Swap,
//     "TRcaXTbZgy17H2oUGqEUsYEgePbELAN9i8",
//     "TEP9rJhjRkKieNAvWQKoPmXYk7FeMVFZs8",
//     "TGdqn3S1SeUJHqWJEHBAq7MbcQLjsc3utw"
//   );

//   // Vault
  deployer.deploy(
    Vault,
    "TRcaXTbZgy17H2oUGqEUsYEgePbELAN9i8",
    "TEP9rJhjRkKieNAvWQKoPmXYk7FeMVFZs8",
    "TGdqn3S1SeUJHqWJEHBAq7MbcQLjsc3utw"
  );


// //   //
};




// For Nile Testnet

// let currencies = ["gGBP"];
// const nileUSDD = "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU";
// const nileJLUSDD = "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f";

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