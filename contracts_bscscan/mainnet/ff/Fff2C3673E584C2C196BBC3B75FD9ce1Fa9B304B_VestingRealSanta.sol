// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract VestingRealSanta {
    IERC20 public token;
    address public owner;
    address public rewardsReciever;
    IERC20 public BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
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
  
    constructor(address _token, address _rewardsReciever)  {
        owner = msg.sender;
        token = IERC20(_token);
        rewardsReciever = _rewardsReciever;
        addVesting();
    }
    
    
    function addVesting() internal onlyOwner{
        uint256 dayPayAmount = 1_000_000_000_000_000 * 10**9 / 100 / 1000 * 5;
        vestings[rewardsReciever] = Vesting(100, rewardsReciever, dayPayAmount, block.timestamp); 
    }
    
    function removeVesting(address _paymentAddress) public onlyOwner nonZeroAddress(_paymentAddress) {
        delete vestings[_paymentAddress];
    }
    
    function calculateClaim() public view returns(uint256) {
        uint256 count =  SafeMath.sub(block.timestamp,vestings[msg.sender].lastPayment) / 86400;
        
        if(count == 0) return 0;
        
        if(vestings[msg.sender].paymentCount < count) count = vestings[msg.sender].paymentCount;
        
        return SafeMath.mul(count, vestings[msg.sender].paymentSummDay);
    }

    function claimSantaToken() public {
        uint256 count =  SafeMath.sub(block.timestamp,vestings[msg.sender].lastPayment) / 86400;
        if(vestings[msg.sender].paymentCount < count){
          count = vestings[msg.sender].paymentCount;
        } 
        if(count > 25) {
            count = 25;
        }
        require(count > 0, 'nothing to claim');
        uint256 amount = SafeMath.mul(count, vestings[msg.sender].paymentSummDay);
        vestings[msg.sender].paymentCount = SafeMath.sub(vestings[msg.sender].paymentCount, count);
        vestings[msg.sender].lastPayment = SafeMath.add(vestings[msg.sender].lastPayment, SafeMath.mul(86400,count));
        if(vestings[msg.sender].paymentCount == 0) {
            delete vestings[msg.sender];
        } 
        token.transfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, SafeMath.mul(count, vestings[msg.sender].paymentSummDay));
    }

    function claimRewards() public {
        BUSD.transfer(rewardsReciever, BUSD.balanceOf(address(this)));
    }

    function claimRewardsCustomToken(IERC20 _token) public {
        require(_token != token, "Can't claim vesting token");
        _token.transfer(rewardsReciever, _token.balanceOf(address(this)));
    }

    function getClaimableRewards() public view returns(uint256){
        return BUSD.balanceOf(address(this));
    }

    function getClaimableRewardsCustomToken(IERC20 _token) public view returns(uint256){
        require(_token != token, "Can't claim vesting token");
        return _token.balanceOf(address(this));
    }
}