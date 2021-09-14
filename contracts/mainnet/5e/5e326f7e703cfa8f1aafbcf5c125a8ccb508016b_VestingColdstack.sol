// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract VestingColdstack {
    IERC20 public token;
    address public owner;
    
    struct Vesting {
        uint paymentCount;
        address paymentAddress;
        uint256 paymentSummDay;
        uint lastPayment;
    }
    
    mapping(address => Vesting) public vestings;
    
    event TokensClaimed(address paymentAddress, uint256 amountClaimed);
    
    modifier nonZeroAddress(address x) {
        require(x != address(0), "token-zero-address");
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "unauthorized");
        _;
    }
  
    constructor(address _token) nonZeroAddress(_token) {
        owner = msg.sender;
        token = IERC20(_token);
    }
    
    
    function addVesting(address _paymentAddress, uint256 _paymentSummDay) public onlyOwner nonZeroAddress(_paymentAddress) {
        vestings[_paymentAddress] = Vesting(270, _paymentAddress, _paymentSummDay, block.timestamp);
    
    }
    
    function removeVesting(address _paymentAddress) public onlyOwner nonZeroAddress(_paymentAddress) {
        delete vestings[_paymentAddress];
    }
    
    function calculateClaim() public view returns(uint256) {
        uint count = SafeMath.sub(block.timestamp,vestings[msg.sender].lastPayment) / 86400;
        
        if(count == 0) return 0;
        
        if(vestings[msg.sender].paymentCount < count) count = vestings[msg.sender].paymentCount;
        
        return SafeMath.mul(count, vestings[msg.sender].paymentSummDay);
    }
    
    function ClaimedToken() public payable returns(bool){
        require(calculateClaim() != 0, 'Claimed zero tokens');
        require(token.transferFrom(owner,msg.sender, calculateClaim()), 'token transfer error');
        
        uint  count = (SafeMath.sub(block.timestamp,vestings[msg.sender].lastPayment) / 86400);
        
        if(count == 0) return false;
        
        if(vestings[msg.sender].paymentCount < count) count = vestings[msg.sender].paymentCount;
        
        vestings[msg.sender].paymentCount = SafeMath.sub(vestings[msg.sender].paymentCount, count);
        vestings[msg.sender].lastPayment = SafeMath.add(vestings[msg.sender].lastPayment,SafeMath.mul(86400,count));
        
        emit TokensClaimed(msg.sender, SafeMath.mul(count, vestings[msg.sender].paymentSummDay));
        
        if(vestings[msg.sender].paymentCount == 0) delete vestings[msg.sender];
        
        return true;
        
    }
}