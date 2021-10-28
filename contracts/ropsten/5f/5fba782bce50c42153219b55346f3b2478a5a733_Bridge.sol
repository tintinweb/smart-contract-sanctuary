/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bridge {
    
    uint64 epoch;
    
    mapping(uint8/*networkid*/ => uint64[]) scanRange;
    
    /* tokens */
    address[] srcContracts;
    address[] destContracts;
    uint256[] minTokenAmounts;
    
    mapping(uint256 => uint64) tokenIdxMatchBlock;
    
    function blockScanRange(uint8 networkId) public view returns (uint64[] memory) {
        return scanRange[networkId];
    }
    
    function tokens(uint64 searchBlock) public view returns(address[] memory, address[] memory, uint256[] memory, uint8[] memory charges, uint64[] memory blockIndexs) {
        
        uint256 n = srcContracts.length;
       
        uint256 items =0;
        for (uint i=n; i>0; i--) {
            if (tokenIdxMatchBlock[i-1] <= searchBlock) {
               items++;
                 
            }
        }
        
        address[] memory retSrcContracts = new address[](items);
        address[] memory retDestContracts = new address[](items);
        uint256[] memory retMinTokenAmounts = new uint256[](items);
        uint8[] memory retCharges = new uint8[](items);
        uint64[] memory retBlockIndexs = new uint64[](items);
        
        items = 0;
        for (uint i=n; i>0; i--) {
            if (tokenIdxMatchBlock[i-1] <= searchBlock) {
                retSrcContracts[items] = srcContracts[i-1];
                retDestContracts[items] = destContracts[i-1];
                retMinTokenAmounts[items] = minTokenAmounts[i-1];
                items++;
                 
            }
        }
        
       return (retSrcContracts,retDestContracts,retMinTokenAmounts,retCharges, retBlockIndexs);
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
    
    function encodeScanRangeArray(uint64[2] memory items) internal pure returns(bytes memory data) {
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
 
    /* ignore, chiew test, change state variables */
    function resetScanRange(uint8 networkId, uint64[] memory sr) public {
        scanRange[networkId] = sr;
    }
    
    function addAvailableTokens(address fakeEthContracts,address fakeAntContracts,uint256  fakeAmounts, uint64 futureBlock) public {
        srcContracts.push(fakeEthContracts);
        destContracts.push(fakeAntContracts);
        minTokenAmounts.push(fakeAmounts);
        
        tokenIdxMatchBlock[srcContracts.length-1] = futureBlock;
        
    }
    
    function emptyAvailableTokens() public {
        
        for (uint i=0; i<srcContracts.length; i++) {
            delete tokenIdxMatchBlock[i];    
        }
        
        delete srcContracts;
        delete destContracts;
        delete minTokenAmounts;
        
    }
     
     
    
    
}