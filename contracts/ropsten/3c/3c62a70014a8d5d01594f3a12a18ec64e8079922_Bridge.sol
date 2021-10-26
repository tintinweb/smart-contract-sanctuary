/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bridge {
    
    uint64 epoch;
    uint64[2] scanRange;
    
    /* tokens */
    address[] srcContracts;
    address[] destContracts;
    uint256[] minTokenAmounts;
    
    mapping(uint256 => uint64) tokenIdxMatchBlock;
    
    function getScanRange() public view returns (uint64[2] memory) {
        return scanRange;
    }
    
    function getAvailableTokens(uint256 searchBlock) public view returns(address[] memory, address[] memory, uint256[] memory) {
        
        uint256 n = srcContracts.length;
        address[] memory retSrcContracts = new address[](n);
        address[] memory retDestContracts = new address[](n);
        uint256[] memory retMinTokenAmounts = new uint256[](n);
    
        for (uint i=0; i<srcContracts.length; i++) {
            if (tokenIdxMatchBlock[i] > searchBlock) {
                 retSrcContracts[i] = srcContracts[i]; 
                 retDestContracts[i] = destContracts[i];
                 retMinTokenAmounts[i] = minTokenAmounts[i];
                 
            }
        }
        
       return (retSrcContracts,retDestContracts,retMinTokenAmounts);
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
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), address(this),epochBlock,encodeAddressArray(signers)));
        
      
        /*ecrecover for further check*/
        
        //for each $key as $signers {
            //address recovered = ecrecover(msgHash, v, r, s);
        //}
        
        //if ok {
            epoch = epochBlock;
        //}
        
        return msgHash;/*ignore, chiew test usage*/
        
    }
    
    function processPack(/*pack header*/uint64[2] memory scanRange, /*pack body*/uint256[] memory txHash, address[] memory tokenContract, address[] memory recipient, uint256[] memory amount, uint8[11] memory v, bytes32[11] memory r, bytes32[11] memory s) public returns(bytes32) {
        //follow eip191 standard https://eips.ethereum.org/EIPS/eip-191
        bytes32 msgHash = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0), address(this),epoch,scanRange[0],scanRange[1],encodeUint256Array(txHash), encodeAddressArray(tokenContract), encodeAddressArray(recipient),encodeUint256Array(amount)));
        
         /*ecrecover for further check*/
         
        //for each $key as $signers {
         //address recovered = ecrecover(msgHash, v[key], r[key], s[key]);
        //}
        
        return msgHash;/*ignore, chiew test usage*/
    }
 
    /* chiew test, set state variables */
    function setScanRange(uint64[2] memory fakeData) public {
        scanRange = fakeData;
    }
    
    function setAvailableTokens(address fakeEthContracts,address fakeAntContracts,uint256  fakeAmounts, uint64 futureBlock) public {
        srcContracts.push(fakeEthContracts);
        destContracts.push(fakeAntContracts);
        minTokenAmounts.push(fakeAmounts);
        
        tokenIdxMatchBlock[srcContracts.length-1] = futureBlock;
        
    }
     
     
    
    
}