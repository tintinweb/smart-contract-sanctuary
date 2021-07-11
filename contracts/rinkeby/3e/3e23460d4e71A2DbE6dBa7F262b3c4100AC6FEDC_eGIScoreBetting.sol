// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./eGI.sol";
import "./Ownable.sol";
import "./BettingScoreETH.sol";
import "./BettingScoreToken.sol";

contract eGIScoreBetting is Ownable{
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

    function createScoreETH(uint256 _min, uint256 _fee) public returns(BettingScoreETH Betting_address){
        return new BettingScoreETH(_min, _fee);
    }

    function createScoreToken(uint256 _min, uint256 _fee) public returns(BettingScoreToken Betting_address){
        return new BettingScoreToken(_min, _fee, _egi);
    }
}