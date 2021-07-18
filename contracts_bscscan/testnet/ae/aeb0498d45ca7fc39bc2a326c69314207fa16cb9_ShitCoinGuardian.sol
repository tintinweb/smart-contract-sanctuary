/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**

The ShitCoinGuardian's purpose is to provide a cleaner trading environment.

You can run this as a stand alone contract or with the ShitCoinGuardianRouter.

Functionality allows clients to utilize three key features:
    isWhiteListed - Useful for bot free launches
    isBlackListed - Can be used to block snipper buys and front running bots
    isHolding -  Limit buys to people who hold specific token amounts


Disclaimer:
It is our policy that these features are for Buying only.
We do not believe any of these features should be used to prevent selling.
It is our belief that blocking of a sell is unethical.
We offer this contract without warranty.

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


contract ShitCoinGuardian {

    string  constant name = "ShitCoinGuardian.2.2";
    string  constant symbol = "SCG";
    mapping(address => bool) public _isWhiteListed;
    mapping(address => bool) public _isBlackListed;
    mapping(address => bool) public _isGuardian;
    address public Captain;
    
   
    event ChangeRouter (address contractOld, address contractNew);
   
    constructor() {
        Captain = msg.sender;
        _isGuardian[Captain] = true;
        _isWhiteListed[Captain] = true;
    }
    
    modifier onlyCaptain() {
        require(Captain == msg.sender, "You are not the Captain.");
        _;
    }
    
    modifier onlyGuardians() {
        require(_isGuardian[msg.sender] == true, "You are not a Guardian.");
        _;
    }

    //Checks a token for a wallet holding >= amount
    function isHolding(address addressWallet, address addressToken, uint tokenAmountRequired) external  view returns(bool) {
        IERC20 targetToken = IERC20(addressToken);
        uint tokenBalance = targetToken.balanceOf(addressWallet);
        if(tokenBalance >= tokenAmountRequired) 
            return true;
        return false;
    }

    function isWhiteListed(address addressWallet) external view  returns(bool) {
        return _isWhiteListed[addressWallet];
    }
    
    function isBlackListed(address addressWallet) external view  returns(bool) {
        return _isBlackListed[addressWallet];
    }

    function manageBlackList(address[] calldata addresses, bool status) external onlyGuardians {
        for (uint256 i; i < addresses.length; i++) {
            _isBlackListed[addresses[i]] = status;
        }
    }    
    
    function manageWhiteList(address[] calldata addresses, bool status) external onlyGuardians {
        for (uint256 i; i < addresses.length; i++) {
            _isWhiteListed[addresses[i]] = status;
        }
    }
        
    function manageGuardians(address[] calldata addresses, bool status) external onlyCaptain {
        for (uint256 i; i < addresses.length; i++) {
            _isGuardian[addresses[i]] = status;
        }
    }
    
    
    
}