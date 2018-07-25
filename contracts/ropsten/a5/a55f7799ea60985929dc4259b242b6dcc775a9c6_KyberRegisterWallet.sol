pragma solidity ^0.4.18;

// File: contracts/wrapperContracts/KyberRegisterWallet.sol

interface FeeBurnerWrapperProxy {
    function registerWallet(address wallet) public;
}


contract KyberRegisterWallet {

    FeeBurnerWrapperProxy public feeBurnerWrapperProxyContract;

    function KyberRegisterWallet(FeeBurnerWrapperProxy feeBurnerWrapperProxy) public {
        require(feeBurnerWrapperProxy != address(0));

        feeBurnerWrapperProxyContract = feeBurnerWrapperProxy;
    }

    function registerWallet(address wallet) public {
        feeBurnerWrapperProxyContract.registerWallet(wallet);
    }
}