const Web3 = require("web3");
// var USDT = artifacts.require("./USD.sol");
// var JLMarket = artifacts.require("./JLMarket.sol");
 var gStable = artifacts.require("./gStable.sol");
// var SwapStableCoin = artifacts.require("./SwapStableCoin.sol");
// var VaultStableCoin = artifacts.require("./VaultStableCoin.sol");
// var Rewards = artifacts.require("./Rewards.sol");

// var SwapGStable = artifacts.require("./SwapGStable.sol");


/****SORREL***/
// var BankDepository = artifacts.require("./sorrel/BankDepository.sol");
// var BatchTransferComptroller = artifacts.require("./sorrel/BatchTransferComptroller.sol");
// var TransferComptroller = artifacts.require("./sorrel/TransferComptroller.sol");
// var ConvertComptroller = artifacts.require("./sorrel/ConvertComptroller.sol");
// var VaultDepository = artifacts.require("./sorrel/VaultDepository.sol");
// var MerchantDepository = artifacts.require("./MerchantDepository.sol");


// var gStableManager = artifacts.require("./gStableManager.sol");


/****LAUNCHBOX***/
// var gAsset = artifacts.require("./gAsset.sol");
// var LaunchBox = artifacts.require("./launchbox/LaunchBox.sol");
// var EvaluatorModel = artifacts.require("./launchbox/EvaluatorModel.sol");


// module.exports = function (deployer) {
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

  // Swap on Nile
  // deployer.deploy(
  //   SwapStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU", //USDD Token
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f", // USDD JLMarket
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS", // JL Rewards
  //   "TF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw"  //gStableManager
  // );

  // Vault on Nile
  // deployer.deploy(
  //   VaultStableCoin,
  //   "THJ6CYd8TyNzHFrdLTYQ1iAAZDrf5sEsZU",
  //   "TQq9o4PahyoLociVzCnBMRRDdPZrNNkW1f",
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS",
  //   "TF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw"
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

  // BankDepository Nile
  // deployer.deploy(
  //   BankDepository,
  //   "TNk57JydfHSnyh95gdRwvt8XFarEHaLDnS", //JL merkledistributor rewards
  //   "TF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw"); //gStableManager

  // BankDepository Mainnet
  // deployer.deploy(
  //   BankDepository,
  //   "TQoiXqruw4SqYPwHAd6QiNZ3ES4rLsejAj",
  //   "TNcjtBJuqUeGU7QBDwHD7moif7PMtT5au1");

  // TransferComptroller
  //   deployer.deploy(
  //     TransferComptroller,
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36" // Nile depository
  // );

  // // ConversionComptroller
  //   deployer.deploy(
  //     ConvertComptroller,
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36"
  // );

  // // VaultDepository
  //   deployer.deploy(
  //     VaultDepository,
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36", //BankDepository
  //     "100", //credit basis points
  //     "TTF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw" //gStableManager
  // );
  // // MerchantDepository
  //   deployer.deploy(
  //     MerchantDepository,
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36", //BankDepository
  //     "20", //credit limit %
  //     "TTF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw" //gStableManager
  // );
  // // BatchTransferComptroller
  //   deployer.deploy(
  //     BatchTransferComptroller,
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36" //BankDepository Nile
  // );

 
  // // LaunchBox
  //   deployer.deploy(
  //     LaunchBox,
  //     "TF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw", //gStableManager
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36"  //BankDepository
  // ); 

  // // EvaluatorModel
  //   deployer.deploy(
  //     EvaluatorModel,
  //     "TF6GzQVGWk5PKcidG7bCCmQHYVqRQDtHNw", //gStableManager
  //     "TUR4za3qj9bZed33hJc9oBQrwTEz8JMq36",  //BankDepository
  //     "TBouPjF4Z7FCCxB1zZKciDKKtC3HALpZDu",  //launchbox
  //     "prompt-not-set"
  // );

  
// //   //
// };




// // goStables Protocol on Tron Mainnet


let currencies = ["gAWG","gKYD","gDOP"];
 module.exports = function (deployer) {

  // gStables
  deployer.then(async () => {
    for (let i = 0; i < currencies.length; i++) {
      await deployer.deploy(gStable, currencies[i], currencies[i]);
      console.log(currencies[i]);
      console.log("gStable : ", gStable.address);
    }
  });


  // gStableManager Mainnet
  //   deployer.deploy(
  //   gStableManager,
  //   "TX7kybeP6UwTBRHLNPYmswFESHfyjm9bAS" //JL USDD Market
  // );

  // Swap Mainnet
  // deployer.deploy(
  //   SwapStableCoin,
  //   "TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn", // USDD Token
  //   "TX7kybeP6UwTBRHLNPYmswFESHfyjm9bAS", // JL USDD Market
  //   "TQoiXqruw4SqYPwHAd6QiNZ3ES4rLsejAj", // JL MerkleDistributor Rewards
  //   "TNcjtBJuqUeGU7QBDwHD7moif7PMtT5au1"  // gStableManager
  // );

  // Vault Mainnet
  // deployer.deploy(
  //   VaultStableCoin,
  //   "TPYmHEhy5n8TCEfYGqW2rPxsghSfzghPDn",
  //   "TX7kybeP6UwTBRHLNPYmswFESHfyjm9bAS",
  //   "TQoiXqruw4SqYPwHAd6QiNZ3ES4rLsejAj",
  //   "TNcjtBJuqUeGU7QBDwHD7moif7PMtT5au1"
  // );


};
