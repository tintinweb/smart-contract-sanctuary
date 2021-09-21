/**
 *Submitted for verification at polygonscan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

 interface IERCRandom {
    function getRandomNumber(uint256 _tokenId, address  _contractaddress) external returns (bytes32);
    function getRandomResult(uint256 _tokenId) external view returns(uint256);
 }

contract TestContract{
    address targetcontract;
    uint256 randomresult;
    
    function settargetcontract(address _targetcontract) public {
        targetcontract=_targetcontract;
    }

    function assetcustomizationcheck(uint256 _tokenId) public returns(uint256){
        IERCRandom RandomNumberConsumer = IERCRandom(address(targetcontract));
        randomresult = RandomNumberConsumer.getRandomResult(_tokenId);
        return randomresult;
    }

}