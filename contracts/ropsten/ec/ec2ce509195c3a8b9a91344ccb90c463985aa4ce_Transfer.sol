pragma solidity ^0.4.20;

contract Transfer { 
    
    struct RelayNode {
        uint256 trust;
    }

    address public owner;
    uint256 public minimumTrust;
    uint256 public donationPool;
    uint256 public nodesCount;
    RelayNode[] public relayNodes;

    function Transfer(uint256 _minimumTrust) public { 
        owner = msg.sender;
        if(_minimumTrust >= 0 ) minimumTrust = _minimumTrust; 
    }

    function() public payable {
        donationPool += msg.value;
    } 

    function kill() public { 
        if(msg.sender == owner) selfdestruct(owner); 
    }

    function register() public returns(uint256){
        uint256 randomTrust = block.number % 10 + 5;
        relayNodes.push(RelayNode(randomTrust));
        nodesCount++;
        return nodesCount - 1;
    }

    function getTrustValue(uint256 _index) public constant returns(uint256){
        return relayNodes[_index].trust;
    }
    
    function setTrustValue(uint256 _index, uint256 _trust) public returns(uint256){
        relayNodes[_index].trust = _trust;
        return relayNodes[_index].trust;
    }
}