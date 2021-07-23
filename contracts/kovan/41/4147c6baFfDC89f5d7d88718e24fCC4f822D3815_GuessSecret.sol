/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity 0.8.0;

contract GuessSecret {
    string private secret;

    constructor(string memory _secret) payable {
        secret = _secret;
    }

    function play(string memory _secret) external {
        // I have to hash a string to compare it
        require(keccak256(abi.encode(_secret)) == keccak256(abi.encode(secret)), "You lose");        

        payable(msg.sender).send(address(this).balance);
    }
}