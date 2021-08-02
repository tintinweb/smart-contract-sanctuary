/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.5;
pragma abicoder v2;

contract BinanceSmartChainVerify{
    string contractName;
    constructor(string memory contractName_){
        contractName = contractName_;

    }


    function getCOntractName() public view returns(string memory){
        return contractName;
    }
}