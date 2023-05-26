const Web3 = require("web3");
// var USDT = artifacts.require("./USD.sol");
// var JLMarket = artifacts.require("./JLMarket.sol");
 // var gStable = artifacts.require("./gStable.sol");
// var SwapStableCoin = artifacts.require("./SwapStableCoin.sol");
// var VaultStableCoin = artifacts.require("./VaultStableCoin.sol");
// var Rewards = artifacts.require("./Rewards.sol");

// var SwapGStable = artifacts.require("./SwapGStable.sol");


/****SORREL***/
// var BankDepository = artifacts.require("./BankDepository.sol");
// var TransferComptroller = artifacts.require("./comptrollers/TransferComptroller.sol");
// var ConvertComptroller = artifacts.require("./comptrollers/ConvertComptroller.sol");
// var Vault = artifacts.require("./Vault.sol");
// var VaultDepository = artifacts.require("./VaultDepository.sol");
// var MerchantDepository = artifacts.require("./MerchantDepository.sol");
var BatchTransferComptroller = artifacts.require("./comptrollers/BatchTransferComptroller.sol");

// var gStableManager = artifacts.require("./gStableManager.sol");



module.exports = function (deployer) {
// //   // USD
  // deployer.deploy(USDT);
// //   //
// //   //
//   // JLMarket
//   // deployer.deploy(
//   //   JLMarket,
//   //   "TRcaXTbZgy17H2oUGqEUsYEgePbELAN9i8",
//   //   "jUSDD",
//   //   "jUSDD"
//   // );

//   // JLMarket
//   deployer.deploy(
//     JLMarket,
//     "TMWEUK2VzCKb8J1KqzYSyenWgj9MfrhZjm",
//     "jUSDT",
//     "jUSDT"
//   );
// };


  // // Rewards
  // deployer.deploy(Rewards);

  // Swap
  // deployer.deploy(
  //   SwapStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS",
  //   "TUnRL112cmACzZoKr6UZRsfT9bRaVjNofz"
  // );

  // Vault
  // deployer.deploy(
  //   VaultStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS",
  //   "TUnRL112cmACzZoKr6UZRsfT9bRaVjNofz"
  // );

  // SwapGStable
  //   deployer.deploy(
  //   SwapGStable,
  //   "TQny4yNYvTmSvJqZNUgEzKtKW6gCzhym6x"
  // );

  // gStableManager
  //   deployer.deploy(
  //   gStableManager,
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f"
  // );

  // BankDepository
  // deployer.deploy(
  //   BankDepository,
  //   "TQoiXqruw4SqYPwHAd6QiNZ3ES4rLsejAj",
  //   "TFNqfwJtaimUAYk79Lsru6L7JWMss4Fboq");

  // TransferComptroller
  //   deployer.deploy(
  //     TransferComptroller,
  //     "TSEZNy1QMWpXuDMFsSeb1VnnhMrbskyGKf"
  // );

  // // ConversionComptroller
  //   deployer.deploy(
  //     ConvertComptroller,
  //     "TSEZNy1QMWpXuDMFsSeb1VnnhMrbskyGKf"
  // );

  // // VaultDepository
  //   deployer.deploy(
  //     VaultDepository,
  //     "TLumYZM6rRs5xHSZEzD6EQG9Kbwa2qvCym", //BankDepository
  //     "2", //credit limit %
  //     "TZDofabgTUK43589ow9zD3LseNPmVYqk6g" //gStableManager
  // );
  // // MerchantDepository
  //   deployer.deploy(
  //     MerchantDepository,
  //     "TLumYZM6rRs5xHSZEzD6EQG9Kbwa2qvCym", //BankDepository
  //     "20", //credit limit %
  //     "TZDofabgTUK43589ow9zD3LseNPmVYqk6g" //gStableManager
  // );
  // // BatchTransferComptroller
    deployer.deploy(
      BatchTransferComptroller,
      "TLumYZM6rRs5xHSZEzD6EQG9Kbwa2qvCym" //BankDepository Nile
  );

  
  
// //   //
};




// For Nile Testnet

// let currencies = ["gOMR","gMYR"];
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


// let currencies = ["gHTG","gEUR","gGBP"];
// module.exports = function (deployer) {
//   deployer.then(async () => {
//     for (let i = 0; i < currencies.length; i++) {
//       await deployer.deploy(gStable, currencies[i], currencies[i]);
//       console.log(currencies[i]);
//       console.log("gStable : ", gStable.address);
//     }
//   });
// };

// let currencies = ["gAWG","gDOP","gBSD","gKYD","gCUP","gHTG","gEUR","gGBP"];
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