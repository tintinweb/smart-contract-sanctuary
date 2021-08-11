/**
 *Submitted for verification at Etherscan.io on 2021-08-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MyNFT {

    string private _name;
    string private _symbol;
     struct Trait {
        uint trait1;
        uint trait2;
        uint trait3;
        uint trait4;
        uint trait5;
        uint trait6;
        uint trait7;
        uint trait8;
    }
    mapping(uint256 => Trait) traits;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;
    mapping(bytes32 => uint256[]) internal hashToValues;
    uint256[] private allTokens;
    uint256[] private traitValues;
    uint256[] private hashValues;

    constructor () {
        _name = "name";
        _symbol = "symbol";
        
    }
    
    function name() public view returns(string memory) {
        return _name;
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function mint( uint256 count) external {
        require(count < 4,"Exceeds maxMint default is 3");
        uint256 supply = totalSupply();
        for(uint256 i=0; i < count; i++){
          
          uint tokenId = supply + i;
          allTokens.push(tokenId);
          bytes32 hash = keccak256(abi.encodePacked(i,block.number, block.timestamp, msg.sender));
          tokenIdToHash[tokenId] = hash;
          hashToTokenId[hash] = tokenId;
          tokenHashToValue(tokenId,hash);
          _hashToValues(hash);
        }
    }
    
    function mint() external {
        
       uint256 tokenId = totalSupply();
       allTokens.push(tokenId);
       bytes32 hash = keccak256(abi.encodePacked(tokenId));
       tokenIdToHash[tokenId] = hash;
       hashToTokenId[hash] = tokenId;
       tokenHashToValue(tokenId,hash);
       _hashToValues(hash);
        
    }
    
    function nextTokenId() public view returns(uint256){
        return totalSupply();
    }
    
    
     function bytes1ToUint(bytes1  b)  internal pure returns (uint256){
    
        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
       
        }
        return  number;
    }
    
    
    function tokenHashToValue(uint tokenId, bytes32 hash ) internal {
         
         uint temp = 0;
         delete traitValues;
         for(uint i=0;i<hash.length;i++) {
            bytes1 a = hash[i];
            uint t =  bytes1ToUint(a); 
            temp = temp + t;
            if(i%4 == 0) {
                 traitValues.push(temp % 100);
                 temp = 0;
            }
         }
         
         traits[tokenId].trait1 = traitValues[0];
         traits[tokenId].trait2 = traitValues[1];
         traits[tokenId].trait3 = traitValues[2];
         traits[tokenId].trait4 = traitValues[3];
         traits[tokenId].trait5 = traitValues[4];
         traits[tokenId].trait6 = traitValues[5];
         traits[tokenId].trait7 = traitValues[6];
         traits[tokenId].trait8 = traitValues[7];
         
    }
    
     function tokenIdToTrait(uint256 tokenId) view public returns (uint256 trait1, uint256 trait2, uint256  trait3, uint256  trait4, uint256  trait5,uint256  trait6, uint256  trait7,uint256  trait8) {
        trait1 = traits[tokenId].trait1;
        trait2 = traits[tokenId].trait2;
        trait3 = traits[tokenId].trait3;
        trait4 = traits[tokenId].trait4;
        trait5 = traits[tokenId].trait5;
        trait6 = traits[tokenId].trait6;
        trait7 = traits[tokenId].trait7;
        trait8 = traits[tokenId].trait8;
    }
    
   
    
     function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }
    
    function _hashToValues(bytes32 hash ) internal {
        
         uint temp = 0;
         delete hashValues;
         for(uint i=0;i<hash.length;i++) {
            bytes1 a = hash[i];
            uint t =  bytes1ToUint(a); 
            temp = temp + t;
            if(i%4 == 0) {
                 hashValues.push(temp % 100);
                 temp = 0;
            }
         }
         
        hashToValues[hash] = hashValues;
         
    }
    
     function hashToUint(bytes32 hash) public view returns(uint256[] memory) {
        return hashToValues[hash];
    }
 
}