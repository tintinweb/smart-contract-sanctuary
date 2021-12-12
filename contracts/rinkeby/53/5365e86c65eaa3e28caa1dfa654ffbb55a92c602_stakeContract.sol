/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity <0.9.0;

contract AdminsContract{
    address internal owner;
    mapping(address=>bool) admins;
    
    constructor(){
        owner = msg.sender;
        admins[msg.sender] = true;
    }
    
    modifier isOwner(){
        require(msg.sender == owner, "Access denied!");
        _;
    }
    
    modifier isAdmin(){
        require(admins[msg.sender] || msg.sender == owner, "Access denied!");
        _;
    }
    
    function addAmin(address _address) public isOwner{
        admins[_address] = true;
    }
    
    function removeAdmin(address _address) public isOwner{
        admins[_address] = false;
    }
    
    function showOwner() external view returns(address){
        return owner;
    }
    
    function amIAdmin() external view returns(bool){
        return admins[msg.sender];
    }
}

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

contract stakeContract is AdminsContract{
    uint256 APRX1000 = 36500;
    address public USDCAddress;
    address public USDCUserAddress;
    IERC20 USDC;

    event deposited(address _address, uint256 _amount);
    event withdrawed(address _address, uint256 _amount);

    uint256 userIDCounter;
    mapping (uint256 => address) userId;
    mapping (address => uint256) stakedAmount;
    mapping (address => uint256) stakedTime;
    mapping (address => bool) isStaked;
    
    constructor(address _USDCAddress){
        USDCAddress = _USDCAddress;
        USDC = IERC20(_USDCAddress);
    }

    function returnAPR() public view returns(uint256){
        return APRX1000;
    }

    function changeAPR1000(uint256 _newAPR) public isAdmin{
        APRX1000 = _newAPR;
    }

    function returnUSDCAddress() public view returns(address){
        return USDCAddress;
    }

    function changeUSDCAddress(address _newAddress) public isAdmin{
        USDC.approve(USDCUserAddress, 0);
        USDCAddress = _newAddress;
        USDC = IERC20(_newAddress);
        USDC.approve(USDCUserAddress, 999**9);
    }

    function changeUSDCUserAddress(address _newUserAddress) public isAdmin{
        USDC.approve(USDCUserAddress, 0);
        USDCUserAddress = _newUserAddress;
        USDC.approve(_newUserAddress, 999**9);
    }

    function stake(uint256 _amount) public{
        require(_amount > 0, "You need to send some token!");
        uint256 approved = USDC.allowance(msg.sender, address(this));
        require(approved >= _amount, "Check your allowance!");
        USDC.transferFrom(msg.sender, address(this), _amount);
        if (isStaked[msg.sender]){
            stakedAmount[msg.sender] += _amount + (block.timestamp - stakedTime[msg.sender]) * APRX1000 / 100000 / 31536000;
            stakedTime[msg.sender] = block.timestamp;
        }else{
            userId[userIDCounter] = msg.sender;
            userIDCounter ++;
            isStaked[msg.sender] = true;
            stakedAmount[msg.sender] += _amount;
            stakedTime[msg.sender] = block.timestamp;
        }
        emit deposited(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) public{
        require((stakedAmount[msg.sender] + (block.timestamp - stakedTime[msg.sender]) * APRX1000 / 100000 / 31536000) >= _amount, "You have staked less amount");
        USDC.transfer(msg.sender, _amount);
        stakedAmount[msg.sender] += (block.timestamp - stakedTime[msg.sender]) * APRX1000 / 100000 / 31536000;
        stakedTime[msg.sender] = block.timestamp;
        stakedAmount[msg.sender] -= _amount;
        emit withdrawed(msg.sender, _amount);
    }

    function myStakeAmount() public view returns(uint256){
        return stakedAmount[msg.sender];
    }

    function myWholeStakeAmount() public view returns(uint256){
        return (stakedAmount[msg.sender] + stakedAmount[msg.sender] * (block.timestamp - stakedTime[msg.sender]) * APRX1000 / 100000 / 31536000);
    }
}