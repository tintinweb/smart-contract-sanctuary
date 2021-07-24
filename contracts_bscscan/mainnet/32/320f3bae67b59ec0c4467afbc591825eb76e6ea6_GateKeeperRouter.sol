/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

/**

GateKeeper Router by Statler @ IMGuild.com

Point your contract to the router.

The router will interface with GateKeeper.

Update currentGateKeeperContract to point to any future versions of GakeKeeper

Disclaimer:
It is our policy that these features are for Buying only.
We do not believe any of these features should be used to prevent selling.
It is our belief that blocking of a sell is unethical.
We offer this contract without warranty.

**/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;

interface IGateKeeper {
    function isHolding(address addressWallet, address addressToken, uint tokenAmountRequired) external view returns(bool);
    function isWhiteListed(address addressWallet) external view returns(bool);
    function isBlackListed(address addressWallet) external view returns(bool);
}

contract GateKeeperRouter {
    
    string  constant name = "GateKeeperRouter v0.2.2";
    string  constant symbol = "ZuulRouter";
    address public KeyMaster;
    address public currentGateKeeperContract;
    IGateKeeper _iGateKeeper;
    
    event ChangeContract (address contractOld, address contractNew);
    
    constructor () {
         KeyMaster = msg.sender;
    }
    
    modifier onlyKeyMaster() {
        require(KeyMaster == msg.sender, "You are not the Keymaster.");
        _;
    }
    
    function isWhiteListed (address addressWallet) external view returns(bool) {
        return(_iGateKeeper.isWhiteListed(addressWallet) && !_iGateKeeper.isBlackListed(addressWallet));
    }
    
    function checkIsHolding (address addressWallet, address addressToken, uint tokenAmountRequired) external view returns(bool) {
        return(_iGateKeeper.isHolding(addressWallet, addressToken, tokenAmountRequired));
    }
    
    function checkIsWhiteListed (address addressWallet) external view returns(bool) {
        return _iGateKeeper.isWhiteListed(addressWallet);
    }
 
    function checkIsBlackListed (address addressWallet) external view returns(bool) {
        return _iGateKeeper.isBlackListed(addressWallet);
    }
    
    function setGateKeeperContract(address addressContract) external onlyKeyMaster() {
        address _oldcontract = currentGateKeeperContract;
        currentGateKeeperContract = addressContract;
        _iGateKeeper = IGateKeeper(currentGateKeeperContract);
        emit ChangeContract (_oldcontract, addressContract);
    }
    
}