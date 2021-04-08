/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

contract Ticket{
    
    //投票人
    struct Voter{
        //投票权重
        uint weight;
        //是否已投票
        bool voted;
        //投票人地址
        address delegate;
        //投票人索引
        uint vote;
    }
    
    //议案
    struct Proposal{
        //议案名
        string name;
        //议案得票数
        uint voteCount;
    }
    
    //投票发起人
    address public chairperson;
    
    //投票人字典
    mapping(address => Voter) public voters;
    
    //议案数组
    Proposal[] public proposals;
    
    //构造方法
    constructor(string[] memory proposalNames) public {
        //初始化发起人、投票人、议案
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for(uint i = 0;i<proposalNames.length;i++){
            proposals.push(
                Proposal(
                    {
                        name:proposalNames[i],
                        voteCount:0
                    })
                );
        }
    }
    
    //分配权限
    function assignPermissions(address voter) public {
        require(msg.sender == chairperson,"Only chairperson can give right to vote.");
        require(!voters[voter].voted,"The voter already voted.");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    
    //委托投票
    function voteByProxy(address to) public {
        //找出委托发起人，如果已经投票，终止程序
        Voter storage sender = voters[msg.sender];
        require(!sender.voted,"You already voted.");
        require(to != msg.sender,"Self-delegation is disallowed.");
        while(voters[to].delegate != address(0)){
            to = voters[to].delegate;
            //发起人、委托人不能是同一个，否则终止程序
            require(to != msg.sender,"Found loop in delegation.");
        }
        //标识发起人已经投过票
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if(delegate_.voted){
            //投票成功，投票总数加上相应的weight
            proposals[delegate_.vote].voteCount += sender.weight;
        }else{
            //如果还没投票，发起人weight赋值给委托人
            delegate_.weight += sender.weight;
        }
    }
    
    //进行投票
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted,"Already voted.");
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }
    
    //优胜议案
    function winningProposal() public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for(uint i = 0; i < proposals.length; i++){
            if(proposals[i].voteCount > winningVoteCount){
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }
    
    function winningName() public view returns (string memory winningName_){
        winningName_ = proposals[winningProposal()].name;
    }
}