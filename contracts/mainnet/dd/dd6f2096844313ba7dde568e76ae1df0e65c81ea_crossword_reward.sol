/**
 *Submitted for verification at Etherscan.io on 2019-07-06
*/

pragma solidity >=0.5.1 <0.6.0;

contract crossword_reward {
    bytes32 solution_hash;
    
    // Contract constructor
    constructor () public {
        solution_hash = 0x2d64478620cf2836ecf1a6ef9ec90e5a540899939c5e411ae44656ddadc6081e;
    }
    
    // Claim the reward
    function claim(bytes20 solution, bytes32 salt) public {
        require(keccak256(abi.encodePacked(solution, salt)) == solution_hash, "Mauvaise solution ou mauvais sel.");
        msg.sender.transfer(address(this).balance);
    }
    
    // Accept any incoming amount
    function () external payable {}
}