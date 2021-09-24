/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SeaEagleToken{
    string public name;
    uint256 public balance;
    struct Eagle {
        uint256 eggs;
        string color;
    }
    Eagle[] public eagles;

    struct Project{
        uint256 projectId;
        uint256 strategyId;
        address token;// foregift token contract address,eth:0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        address investor;
        address strategist;
        uint256 foregift;
        uint256 balance;
        uint256 totalFee;
        uint256 endblock; // The end date of the project. In 5 days after this date, if the status == 1, the user can withdraw the pledge deposit
        uint256 status; //1,creative;2.end;3.forceSettle
    }

    Project[] public projects;

    constructor(string memory _name){
        name = _name;
        projects.push(Project(100,
        88,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
        8*1e18,
        2*1e18,
        0,
        0,
        1));
    }

    function query(uint256 _projectId) external view returns(
        uint256 projectId_,
        uint256 strategyId,
        address token_,
        address investor_,
        address strategist_,
        uint256 foregift_,
        uint256 balance_,
        uint256 totalFee_,
        uint256 endblock_,
        uint256 status_){
            Project memory project = projects[_projectId];
            projectId_ = project.projectId;
            strategyId = project.strategyId;
            token_ = project.token;
            investor_ = project.investor;
            strategist_ = project.strategist;
            foregift_ = project.foregift;
            balance_ = project.balance;
            totalFee_ = project.totalFee;
            endblock_ = project.endblock;
            status_ = project.status;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function setBalance(uint256 _balance) external {
        balance = _balance;
    }

    function setEagle(uint256 _eggs, string memory _color) external {
        eagles.push(Eagle(_eggs,_color));
    }

    function getEagle(uint256 eid) external view returns( Eagle memory){
        return eagles[eid];
    }

    function getEagles() external view returns(Eagle[] memory){
        return eagles;
    }

    ///@dev 给合约发送msg.value的ETH，balance自动加上传送的eth数。仅测试而已，函数没有特别意义。web3调用方式 addBalance({value:100*10**9})
    function addBalance() payable external {
        require(msg.value>0, "No ETH");
        balance += msg.value;
    }

    receive() external payable {}
}