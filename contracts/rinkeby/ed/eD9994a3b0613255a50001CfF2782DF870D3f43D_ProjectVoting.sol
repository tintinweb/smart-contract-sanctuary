/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.0;

contract ProjectVoting {

    mapping(address => uint256) public balanceOf;
    mapping(address => uint8) public register;
    mapping(uint8 => uint8) public score;
    address private owner;
    address private mod;

    constructor(){
        owner = msg.sender;
    }

    function registerVoter(uint8 legajo) external {
        require(legajo > 0, "legajo es inferior a 0");
        require(legajo < 70_000, "legajo superior a 70.000");
        register[msg.sender] = legajo;
        balanceOf[msg.sender] = 100;
    }

    function vote(uint8 proposal_id, uint8 amount) external {
        require(proposal_id > 0, "id es inferior a 0");
        require(proposal_id < 17, "id superior a 70.000");
        require(balanceOf[msg.sender] > 0, "no podes votar mas");
        if(balanceOf[msg.sender] >= amount){
            score[proposal_id] += amount;
        }
        balanceOf[msg.sender] -= amount;
    }

    //only mod
    function retocar(uint8 proposal_id, uint8 amount) external {
        require(msg.sender == mod, "qui hace?");
        //hace lo que quieras, sos mod
        score[proposal_id] += amount;
    }
    
    function setMod(address _mod) external {
        require(msg.sender == owner, "JAJAJ ya quisieras");
        mod = _mod;
    }

}