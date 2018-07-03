pragma solidity ^0.4.24;
contract Test {
    address Need1 = 0x3A00654b7A48aa3f1DB1C0f9e04F53DEfECFAD68;
    address Need2 = 0xa57093CFf7002698cA2dfCcE6c71A19f11D4527D;
    
    function splitter() external payable {
        uint value = msg.value;
        Need1.transfer(value/2);
        Need2.transfer(value/2);
    }
}