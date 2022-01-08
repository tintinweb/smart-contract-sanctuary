// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

// largely borrowed from
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/proxy/Proxy.sol

error notOwner();
error badAddr();

/**
 * @title SoladayRegistry
 * @dev 
 * @author kethcode (https://github.com/kethcode)
 */
contract SoladaySimpleProxy {

    /*********
    * Events *
    **********/

    /************
    * Modifiers *
    *************/ 

    modifier isOwner(address addr)
    {
        if(addr != owner) revert notOwner();
        _;
    }
    
    modifier validAddr(address addr)
    {
        if(addr == address(0)) revert badAddr();
        _;
    }
    
    /************
    * Variables *
    *************/

    address internal owner;
    address internal remote;

    /*******************
    * Public Functions *
    ********************/

    constructor() {
        owner = msg.sender;
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _implementation() internal view returns (address) {
        return remote;
    }

    function _fallback() internal {
        _delegate(_implementation());
    }

    fallback() external payable { _fallback(); }
    receive() external payable  { _fallback(); }

    function setRemote(address addr) public isOwner(msg.sender) validAddr(addr) {
        remote = addr;
    }

    function getRemote() public view returns(address) {
        return remote;
    }
}