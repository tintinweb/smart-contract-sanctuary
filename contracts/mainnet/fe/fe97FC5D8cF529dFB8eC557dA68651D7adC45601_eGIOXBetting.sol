// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./eGI.sol";
import "./Ownable.sol";
import "./BettingOXETH.sol";
import "./BettingOXToken.sol";

contract eGIOXBetting is Ownable{
    eGIToken _egi;

    constructor(address _storeAddress) {
        setStoreContract(_storeAddress);
    }

    function setStoreContract(address _storeAddress) public {
        require(_storeAddress != address(0));
        _egi = eGIToken(_storeAddress);
    }

    function reclaimStoreOwnership(address _owner) onlyOwner public{
        _egi.transferOwnership(_owner);
    }

    function createOXETH(uint256 _min, uint256 _fee) public returns(BettingOXETH Betting_address){
        return new BettingOXETH(_min, _fee);
    }

    function createOXToken(uint256 _min, uint256 _fee) public returns(BettingOXToken Betting_address){
        return new BettingOXToken(_min, _fee, _egi);
    }
}