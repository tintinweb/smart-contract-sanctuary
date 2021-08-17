pragma solidity ^0.4.15;
import "./Factory.sol";
import "./MultiSigWallet.sol";


contract MultiSigWalletFactory is Factory {


    function create(address[] _owners, uint _required)
        public
        returns (address wallet)
    {
        wallet = new MultiSigWallet(_owners, _required);
        register(wallet);
    }
}