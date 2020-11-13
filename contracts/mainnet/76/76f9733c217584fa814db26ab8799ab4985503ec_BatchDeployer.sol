pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface DharmaSmartWalletFactoryV1Interface {
  function newSmartWallet(
    address userSigningKey
  ) external returns (address wallet);
  
  function getNextSmartWallet(
    address userSigningKey
  ) external view returns (address wallet);
}


struct Wallet {
    address wallet;
    address initialUserSigningKey;
}


contract BatchDeployer {
    DharmaSmartWalletFactoryV1Interface private _FACTORY = DharmaSmartWalletFactoryV1Interface(
        0xfc00C80b0000007F73004edB00094caD80626d8D
    );
    
    function batchDeploy(Wallet[] calldata wallets) external returns (uint256) {
        uint256 deployed = 0;
        for (uint256 i = 0; i < wallets.length; i++) {
            if (gasleft() < 100000) {
                return deployed;
            }
            
            Wallet memory wallet = wallets[i];
            
            if (_FACTORY.getNextSmartWallet(wallet.initialUserSigningKey) == wallet.wallet) {
                _FACTORY.newSmartWallet(wallet.initialUserSigningKey);
                deployed++;
            }
        }
    }
}