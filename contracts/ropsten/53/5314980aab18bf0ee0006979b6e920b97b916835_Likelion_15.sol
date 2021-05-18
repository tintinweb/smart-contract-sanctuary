/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_15 {
    struct TX {
        uint index;
        string sender;
        string recipient;
        uint value;
    }
    
    TX[] TXs;
    
    uint index = 0;
    
    function addTX(string memory _sender,string memory _recipient,uint _value) public {
        TXs.push(TX(index,_sender,_recipient,_value));
        index++;
    }
    
    /*function getMerkleRoot() public view returns(bytes32){
        
        bytes32[] trees;
        
        
        for(uint i=0; i<index/2; i++){
            
            trees.push(keccak256(abi.encodePacked(TXs[index].index,TXs[index].sender,TXs[index].recipient,TXs[index].value)));
            cnt++;
        }
    }*/
}