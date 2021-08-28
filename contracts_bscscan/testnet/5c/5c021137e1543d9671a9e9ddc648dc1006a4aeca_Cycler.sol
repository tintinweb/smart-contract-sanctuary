/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Cycler {
    enum Status {Pending, Cycled}
    
    address Admin;
    address Token;
    //uint256 public Position_Cost = 0.005 * 10 ** 18;
    uint256 public Position_Cost = 5;
    
    IERC20 private token;
    
    uint256 _id;
    uint256 _levels = 5;
    uint256 _cost = Position_Cost;
    
    struct PositionDetail {
        Status status;
        uint256 level;
        address owner;
    }
    
    mapping(uint256 => PositionDetail) private positions;
    mapping(address => uint256) private balances;
    
    constructor() public {
        Admin = msg.sender;
        Token = 0xA832190e277f3b97cea80B9a428fC71E79866222;
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
    }
    
    
    function getBalance() public view returns(uint256){
        return balances[msg.sender];
    }
    function Position_Details(uint256 id) public view returns (Status, uint256, address){
        return (
            positions[id].status,
            positions[id].level,
            positions[id].owner
        );
    }
    function Total_Positions() public view returns (uint256){
        return _id;
    }
    
    function Purchase_Postion() public {
    //function Purchase_Postion() external payable returns (bool) {
        uint256 amount = Position_Cost;
        //uint256 allowance = IERC20(Token).allowance(address(this), msg.sender);
        //require(allowance >= amount, "Check the token allowance");
        IERC20(Token).transferFrom(msg.sender, address(this), amount);
        
        //require(msg.value == _cost, "Amount doesn't match position cost!");
        uint256 current = _id / _levels;
        positions[current].level = positions[current].level + 1;
        
        if(positions[current].level == _levels){
            positions[current].status = Status.Cycled;
            payable(positions[current].owner).transfer( _cost * _levels );
        }
        
        _id++;
        positions[_id] = PositionDetail(Status.Pending, 0, msg.sender);
        //return true;
    }
    function Budget() public view returns(uint256) {
        return IERC20(Token).balanceOf(address(this));
    }
    function transferToMe(address _owner, uint _amount) public {
        IERC20(Token).transferFrom(_owner, address(this), _amount);
    }
}