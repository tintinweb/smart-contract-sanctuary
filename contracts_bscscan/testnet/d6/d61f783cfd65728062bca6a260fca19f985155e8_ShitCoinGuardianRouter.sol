/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**

The router will interface with ShitCoinGuardian.

Update currentShitCoinGuardianContract to point to any future versions of ShitCoinGuardian

Disclaimer:
It is our policy that these features are for Buying only.
We do not believe any of these features should be used to prevent selling.
It is our belief that blocking of a sell is unethical.
We offer this contract without warranty.

**/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

interface IShitCoinGuardian {
    function isHolding(address addressWallet, address addressToken, uint tokenAmountRequired) external view returns(bool);
    function isWhiteListed(address addressWallet) external view returns(bool);
    function isBlackListed(address addressWallet) external view returns(bool);
}

contract ShitCoinGuardianRouter {
    
    string  constant name = "ShitCoinGuardianRouter.1.2";
    string  constant symbol = "SCGR";
    address public Captain;
    address public currentShitCoinGuardianContract;
    IShitCoinGuardian _iShitCoinGuardian;
    
    event ChangeContract (address contractOld, address contractNew);
    
    constructor () {
         Captain = msg.sender;
    }
    
    modifier onlyCaptain() {
        require(Captain == msg.sender, "You are not the Captain.");
        _;
    }
    
    function isWhiteListed (address addressWallet) external view returns(bool) {
        return(_iShitCoinGuardian.isWhiteListed(addressWallet) && !_iShitCoinGuardian.isBlackListed(addressWallet));
    }
    
    function checkIsHolding (address addressWallet, address addressToken, uint tokenAmountRequired) external view returns(bool) {
        return(_iShitCoinGuardian.isHolding(addressWallet, addressToken, tokenAmountRequired));
    }
    
    function checkIsWhiteListed (address addressWallet) external view returns(bool) {
        return _iShitCoinGuardian.isWhiteListed(addressWallet);
    }
 
    function checkIsBlackListed (address addressWallet) external view returns(bool) {
        return _iShitCoinGuardian.isBlackListed(addressWallet);
    }
    
    function setShitCoinGuardianContract(address addressContract) external onlyCaptain() {
        address _oldcontract = currentShitCoinGuardianContract;
        currentShitCoinGuardianContract = addressContract;
        _iShitCoinGuardian = IShitCoinGuardian(currentShitCoinGuardianContract);
        emit ChangeContract (_oldcontract, addressContract);
    }
    
}