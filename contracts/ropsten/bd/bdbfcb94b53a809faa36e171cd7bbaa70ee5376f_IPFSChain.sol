/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract IPFSChain {
    mapping(address => mapping(uint=>string[]))  userChars;
    uint index =0;
    function createNewChar(string memory _ipfsHash)public returns(uint charID)  {
        userChars[msg.sender][index].push(_ipfsHash);
        index++;
        return index-1;
    }

    function progressChar(uint _charID, string memory _ipfsHash)public returns(string[] memory){
         getCharacterWithID(_charID);
         userChars[msg.sender][_charID].push(_ipfsHash);
         return userChars[msg.sender][_charID];
        
    }
    function getCharacterWithID ( uint _charID)public view returns (string[] memory) {
        if(userChars[msg.sender][_charID].length==0){
            revert("Char not found");
        }       
        else{
            return userChars[msg.sender][_charID];
        }
    }
}