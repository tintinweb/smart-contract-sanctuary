/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract airDropBillz{
    
    using SafeMath for uint256;

    address payable public owner;
    IBEP20 public token;
    
    uint256 public claimAmount;
    uint256 public referalAmount;
    uint256 public airdropfee;
    
    mapping(address => bool) public claimed;

    modifier onlyOwner(){
        require(msg.sender == owner,"not an owner");
        _;
    } 
    
    event Claimed(address _user, address _referrer);
    
    constructor(IBEP20 _token) public{
        owner = payable(msg.sender);
        token = _token;
        claimAmount = 300000e18;
        referalAmount = 100e18;
        airdropfee = 0.0017 ether;
    }
    
    receive() payable external{}
    
    function claimAirDrop(address _referrer) public payable {
        require(msg.value == airdropfee,"Pay required amount");
        require(claimed[msg.sender] == false,"can not claim twice");
        require(_referrer != address(0) && _referrer != msg.sender,"invalid referrer");
        
        owner.transfer(msg.value);
        token.transferFrom(owner, msg.sender, claimAmount);
        token.transferFrom(owner, _referrer, referalAmount);
        
        claimed[msg.sender] = true;
        
        emit Claimed(msg.sender, _referrer);
    }
    
    function setClaimAmount(uint256 _claimAmount, uint256 _refAmount, uint256 _claimFee) external onlyOwner{
        claimAmount = _claimAmount;
        referalAmount = _refAmount;
        airdropfee = _claimFee;
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner{
        owner.transfer(_value);
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function contractBalanceBnb() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.allowance(owner, address(this));
    }
    
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}