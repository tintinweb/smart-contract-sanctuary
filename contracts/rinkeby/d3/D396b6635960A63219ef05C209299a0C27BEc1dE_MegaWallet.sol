pragma solidity ^0.4.23;

import "./Ownable.sol";
import "./DetailedERC20.sol";
import "./ERC20Wallet.sol";

contract MegaWallet is Ownable {

    address[] public wallets;

    event WalletEvent ( 
        address addr,
        string action,
        uint256 amount
    );
    
    constructor() public {
        owner = msg.sender;
    }

    function createWallet(address _token) public {
        ERC20Wallet wallet = new ERC20Wallet(DetailedERC20(_token), owner);
        wallets.push(wallet);
        emit WalletEvent(wallet, "Create", 0);
    }

    function getWallets() public view returns (address[]){
        return wallets;
    }
}