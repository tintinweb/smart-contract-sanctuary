// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./eGI.sol";
import "./Ownable.sol";
import "./ETHTournament.sol";
import "./TokenTournament.sol";

contract eGITournament is Ownable{
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

    function createETHTournament(uint256 _fee, uint256 _min) public returns(ETHTournament Tournament_address){
        return new ETHTournament(_fee, _min);
    }

    function createTokenTournament(uint256 _fee, uint256 _min) public returns(TokenTournament Tournament_address){
        return new TokenTournament(_fee, _min, _egi);
    }
}