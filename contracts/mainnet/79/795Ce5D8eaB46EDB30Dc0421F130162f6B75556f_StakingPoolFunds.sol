// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
/**
 * @title Ownership Contract
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Interface of DefiBids
 */
interface BIDSInterface { 
    function transfer(address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function BURN_RATE() external view returns(uint256);
    function isStackingActive() external view returns(bool);
} 


contract StakingPoolFunds is Ownable {
    
    using SafeMath for uint256;

    address public divPoolAddress;
    address public constant bidsTokenAddress = 0x912B38134F395D1BFAb4C6F9db632C31667ACF98;
    
    modifier onlyDivPool() {
        require(divPoolAddress == msg.sender, "Ownable: caller is not the authorized.");
        _;
    }
    
    /*
        Fallback function. It just accepts incoming ETH
    */
    function () payable external {}
    
    function requestDividendRewards() external onlyDivPool returns(uint256 ethRewards, uint256 bidsRewards){
        
        bidsRewards = BIDSInterface(bidsTokenAddress).balanceOf(address(this));
        
        // Calculate remaining amount to be tranferred at staking portal
        uint256 BURN_RATE = BIDSInterface(bidsTokenAddress).BURN_RATE();
        bool isStakingActive = BIDSInterface(bidsTokenAddress).isStackingActive();
        
        uint256 remainingAmount = bidsRewards;
        if(BURN_RATE > 0){
            uint256 burnAmount = bidsRewards.mul(BURN_RATE).div(1000);
            remainingAmount = remainingAmount.sub(burnAmount);

        }
        
        if(isStakingActive){
            uint256 amountToStakePool = bidsRewards.mul(10).div(1000);
            remainingAmount = remainingAmount.sub(amountToStakePool);
        }
        
        if(bidsRewards > 0){
            BIDSInterface(bidsTokenAddress).transfer(msg.sender, bidsRewards);
        }
        
        ethRewards = address(this).balance;
        if(ethRewards > 0){
            msg.sender.transfer(ethRewards);
        }
        
        return (ethRewards, remainingAmount);
        
    }
    
    function availableDividendRewards() external view returns(uint256 ethRewards, uint256 bidsRewards){
        
        bidsRewards = BIDSInterface(bidsTokenAddress).balanceOf(address(this));
        ethRewards = address(this).balance;
        
         // Calculate remaining amount to be tranferred at staking portal
        uint256 BURN_RATE = BIDSInterface(bidsTokenAddress).BURN_RATE();
        bool isStakingActive = BIDSInterface(bidsTokenAddress).isStackingActive();
        
        uint256 remainingAmount = bidsRewards;
        if(BURN_RATE > 0){
            uint256 burnAmount = bidsRewards.mul(BURN_RATE).div(1000);
            remainingAmount = remainingAmount.sub(burnAmount);
        }
        
        if(isStakingActive){
            uint256 amountToStakePool = bidsRewards.mul(10).div(1000);
            remainingAmount = remainingAmount.sub(amountToStakePool);
        }
        
        return (ethRewards, remainingAmount);
        
    }
    
    function setDivPoolAddress(address _a) public onlyOwner returns(bool){
        divPoolAddress = _a;
        return true;
    }
    
}