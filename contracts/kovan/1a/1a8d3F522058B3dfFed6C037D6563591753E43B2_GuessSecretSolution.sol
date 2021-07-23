/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity 0.8.0;

contract GuessSecretSolution {
    bytes32 private secretHashed;
    
    constructor(bytes32 _secretHashed) payable {
        secretHashed = _secretHashed;
    }
    
    function play(string memory _secret) external {
        // I have to hash a string to compare it
        require(keccak256(abi.encode(_secret)) == secretHashed, "You lose");
        
        payable(msg.sender).send(address(this).balance);
    }
}