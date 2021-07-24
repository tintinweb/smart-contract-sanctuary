/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**

GateKeeper by Statler @ IMGuild.com

The GateKeeper's purpose is to provide a cleaner trading environment.

You can run this as a stand alone contract or with the GateKeeperRouter.

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


contract GateKeeper {

    string  constant name = "GateKeeper v0.2.2";
    string  constant symbol = "ZUUL";
    mapping(address => bool) public _isWhiteListed;
    mapping(address => bool) public _isBlackListed;
    mapping(address => bool) public _isKeyMaster;
    address public Gozer;
    
   
    event ChangeRouter (address contractOld, address contractNew);
   
    constructor() {
        Gozer = msg.sender;
        _isKeyMaster[Gozer] = true;
        _isWhiteListed[Gozer] = true;
    }
    
    modifier onlyGozer() {
        require(Gozer == msg.sender, "You are not a God.");
        _;
    }
    
    modifier onlyKeyMasters() {
        require(_isKeyMaster[msg.sender] == true, "You are not a Keymaster.");
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

    function manageBlackList(address[] calldata addresses, bool status) external onlyKeyMasters {
        for (uint256 i; i < addresses.length; i++) {
            _isBlackListed[addresses[i]] = status;
        }
    }    
    
    function manageWhiteList(address[] calldata addresses, bool status) external onlyKeyMasters {
        for (uint256 i; i < addresses.length; i++) {
            _isWhiteListed[addresses[i]] = status;
        }
    }
        
    function manageKeyMasters(address[] calldata addresses, bool status) external onlyKeyMasters {
        for (uint256 i; i < addresses.length; i++) {
            _isKeyMaster[addresses[i]] = status;
        }
    }
    
    
    
}