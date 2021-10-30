/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bridge {
    
    uint64 epoch;
    
    mapping(uint8/*networkid*/ => uint64[]) scanRange;
    
    /* tokens */
    address[] allCrossContracts;
    uint8[] allCrossNetworks;
    address[] allOwnContracts;
    uint256[] allMinAmounts;
    
    mapping(uint256 => uint64) tokenIdxMatchBlock;
    
    function blockScanRange(uint8 networkId) public view returns (uint64[] memory) {
        return scanRange[networkId];
    }
    
    function processPack(/*pack header*/uint64[2] memory scanRange, uint8 networkId, /*pack body*/uint256[] memory txHash, address[] memory tokenContract, address[] memory recipient, uint256[] memory amount, uint8[11] memory v, bytes32[11] memory r, bytes32[11] memory s) public returns(bytes32) {
        //follow eip191 standard https://eips.ethereum.org/EIPS/eip-191
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), address(this),epoch,encodeScanRangeArray(scanRange), networkId, encodeUint256Array(txHash), encodeAddressArray(tokenContract), encodeAddressArray(recipient),encodeUint256Array(amount)));
        
         /*ecrecover for further check*/
         
        //for each $key as $signers {
            //address recovered = ecrecover(msgHash, v[key], r[key], s[key]);
        //}
        
        /*update scanRange*/
        //if ok {
            //scanRange[networkId] = new scan range;
        //}
        
        return msgHash;/*ignore, chiew test usage*/
    }
    
    function encodeScanRangeArray(uint64[2] memory items) internal pure returns(bytes memory data) {
        for(uint i=0; i<items.length; i++){
            data = abi.encodePacked(data, items[i]);
        }
    }
 
    
    function tokens(uint64 searchBlock) public view returns(address[] memory crossTokens, address[] memory owntokens, uint256[] memory minAmounts, uint8[] memory crossNetworks, uint8[] memory charges, uint64[] memory blockIndexs) {
        
        uint256 n = allOwnContracts.length;
       
        uint256 items =0;
        for (uint i=n; i>0; i--) {
            if (tokenIdxMatchBlock[i-1] <= searchBlock) {
                items++;
            }
        }
        
        address[] memory retOwnContracts = new address[](items);
        address[] memory retCrossContracts = new address[](items);
        uint256[] memory retMinAmounts = new uint256[](items);
        uint8[] memory retCrossNetworks = new uint8[](items);
        uint8[] memory retCharges = new uint8[](items);
        uint64[] memory retBlockIndexs = new uint64[](items);
        
        items = 0;
        for (uint i=n; i>0; i--) {
            if (tokenIdxMatchBlock[i-1] <= searchBlock) {
                retOwnContracts[items] = allOwnContracts[i-1];
                retCrossContracts[items] = allCrossContracts[i-1];
                retCrossNetworks[items] = allCrossNetworks[i-1];
                retMinAmounts[items] = allMinAmounts[i-1];
                items++;
                 
            }
        }
        
       return (retCrossContracts,retOwnContracts,retMinAmounts,retCrossNetworks, retCharges, retBlockIndexs);
    }
  
    function encodeAddressArray(address[] memory addresses) internal pure returns(bytes memory data){
        for(uint i=0; i<addresses.length; i++){
            data = abi.encodePacked(data, addresses[i]);
        }
    }
    
    function encodeUint256Array(uint256[] memory items) internal pure returns(bytes memory data) {
        for(uint i=0; i<items.length; i++){
            data = abi.encodePacked(data, items[i]);
        }
    }
    
    function processSigners(uint64 epochBlock, address[] memory signers, uint8[11] memory v, bytes32[11] memory r, bytes32[11] memory s) public returns(bytes32 /*bytes32*/) {
        //follow eip191 standard https://eips.ethereum.org/EIPS/eip-191
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), address(0),epochBlock,encodeAddressArray(signers)));
        
      
        /*ecrecover for further check*/
        
        //for each $key as $signers {
            //address recovered = ecrecover(msgHash, v, r, s);
        //}
        
        //if ok {
            epoch = epochBlock;
        //}
        
        return msgHash;/*ignore, chiew test usage*/
        
    }
    
   
    /* ignore, chiew test, change state variables */
    function resetScanRange(uint8 networkId, uint64[] memory sr) public {
        scanRange[networkId] = sr;
    }
    
    function addTokens(address _crossContracts,address _ownContracts,uint256 _minAmounts, uint8 _crossNetwork, uint64 _futureBlock) public {
        allCrossContracts.push(_crossContracts);
        allCrossNetworks.push(_crossNetwork);
        allOwnContracts.push(_ownContracts);
        allMinAmounts.push(_minAmounts);
        
        tokenIdxMatchBlock[allCrossContracts.length-1] = _futureBlock;
        
    }
    
    function emptyAvailableTokens() public {
        
        for (uint i=0; i<allOwnContracts.length; i++) {
            delete tokenIdxMatchBlock[i];    
        }
        
        delete allOwnContracts;
        delete allCrossNetworks;
        delete allCrossContracts;
        delete allMinAmounts;
        
    }
     
     
    
    
}