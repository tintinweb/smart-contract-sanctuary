pragma solidity ^0.4.24;
//
// Hello World: Simple SHA3() Function Test
// WARNING: DO NOT USE THIS CONTRACT OR YOU LOSE EVERYTHING!!!!!!!!!!!
// KECCAK256("test") = 0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664cb9a3cb658
// 
//
contract Simple_SHA3_Test {
    
    event test(string result);
    
    address private owner;
    bytes32 hash = 0x9c22ff5f21f0b81b113e63f7db6da94fedef11b2119b4088b89664cb9a3cb658;

    function () payable public {}
    
    constructor () public payable {
        owner = msg.sender;
    }

    function withdraw(string preimage) public payable {
        require(msg.value >= 10 ether);
        require(bytes(preimage).length > 0);

        bytes32 solution = keccak256(bytes(preimage));
        if (solution == hash) {
            emit test("SHA works");
            msg.sender.transfer(address(this).balance);
        }else{
            emit test("SHA doesnt work");
        }
    }
    
    function test_withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
    
    function test_suicide() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }
}