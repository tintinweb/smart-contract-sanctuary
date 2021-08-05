/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract XFT_DAO {
    
    struct proposal {
        string[4] propsal_info;
        uint256 expiry_time;
        uint256 poll_id;
    }
    
    event push_vote(
        address indexed voter,
        uint256 indexed poll_id,
        bool[4] answers
    );
    
    address owner;
    proposal public running_proposal;
    IERC20 weight_token;

    constructor(address _addy) {
        owner = msg.sender;
        weight_token = IERC20(_addy);
    }
    
    
    function create_proposal(string[4] memory text_info, uint256 _expiry) public{
        require(msg.sender == owner, "only Owner");
        running_proposal = proposal(text_info, _expiry, block.number);
    }
    
    function vote(bool[4] memory y_n) public{
        require(weight_token.balanceOf(msg.sender) > 0, "0 XFT balance: you aren't allowed to vote!");
        require(block.timestamp < running_proposal.expiry_time, "proposal expired");

        emit push_vote(msg.sender, running_proposal.poll_id, y_n);
    }
    
    function done() view public returns(uint256, bool){
        return (block.timestamp, block.timestamp < running_proposal.expiry_time);
    }
    
    function show_questions() view public returns(string[4] memory){
        return running_proposal.propsal_info;
    }
}