pragma solidity ^0.4.23;

contract EtherMiddle {
    
    uint nonce;
    
    event DataEmitter(
        address owner , 
        string indexed topic,
        bytes32 indexed hash,
        string data
        );
        
    function HashGenerator() public returns(bytes32){
        bytes32 hashed = keccak256(block.number , msg.data , nonce++);
        return hashed;
    }
    
    function SetData(string _topic , string _data)public returns(bytes32) {
        bytes32 generator = HashGenerator();
        emit DataEmitter(msg.sender , _topic , generator , _data);
        return generator;
    }
}