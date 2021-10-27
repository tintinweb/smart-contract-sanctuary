// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/utils/TokenTimelock.sol)

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private immutable _token;

    mapping(address => Grant) private userGrant;
    
    //Release time periods
    uint256 public _startTime;
    
    address private owner;
    
     //Number of Total Grants
    uint256 public nGrants;
    
     //Total Claimed
    uint256 public totalClaimed;
    
    //Release time periods
    uint256[] private _releaseTime;
    
     //Release percentages
    uint256[] private _releaseBlock;
    
    mapping(address => uint256) private userClaimed;
    
    modifier onlyOwner(){
        require(owner == owner, "Only owner allowed to call this function");
        _;
    }
    
    
    struct Grant{
        uint256 amount;
    }

    constructor(
        IERC20 token_, uint256 startTime, uint256 cliffTime, uint256 cliffPercentage, uint256 vestPeriod, uint256 numberVests, uint256 vestPercentage
    ) {
        require(startTime >= block.timestamp, "Invalid start time, you can only start time with values from the future");
        owner = msg.sender;
        _token = token_;
        _startTime = startTime;
        uint256 firstRelease = startTime + cliffTime;
        _releaseTime.push(firstRelease);
        _releaseBlock.push(cliffPercentage);
        
        uint256 n; 
        while( n <= numberVests){
            firstRelease = firstRelease + vestPeriod;
            _releaseTime.push(firstRelease);
            _releaseBlock.push(vestPercentage);
            n++;
        }
      
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }



    function batchAddBeneficiary(address[] calldata addressing, uint256[] calldata amounting) public  {
        require(addressing.length > 0 && amounting.length > 0 && addressing.length == amounting.length, "Invalid addresses or amounts");
        require(addressing.length < 50, "You can only batch 50 at each time");
        uint16 n = 0;
        while(n < addressing.length){
            address addr = addressing[n];
            uint256 amount = amounting[n];
            addBeneficiary(addr, amount);
            n++;
        }
        
    }
 
    function addBeneficiary(address addr, uint256 amount) public  {
        require(addr != address(0), "Address Invalid");
        nGrants++;
        userGrant[addr].amount = amount.mul(10 ** 18);
    }

    function getBeneficiaryTotalAmount(address addr) public view returns (uint256){
        require(addr != address(0), "Invalid index");
        return userGrant[addr].amount;
    }
    
    
    function getUserAmountClaimed(address addr) public view returns (uint256){
        require(addr != address(0), "Invalid address");
        return userClaimed[addr];
    }
    
   
    function availableAmount() public view  returns(uint256){
        uint256 am = getBeneficiaryTotalAmount(msg.sender);
        require(am > 0, "Grant not  attributed");
        
        uint256 n = 0; 
        uint256 avAmount = 0;
        while (n < _releaseTime.length) {
            if(_releaseTime[n] <= block.timestamp){
                avAmount = avAmount.add(_releaseBlock[n]);
            }
            n++;
        }
       return  avAmount.mul(am).div(100);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        require(block.timestamp >= _releaseTime[0], "TokenTimelock: current time is before first release time");

        uint256 amount = availableAmount().sub(getUserAmountClaimed(msg.sender));
        require(amount > 0, "TokenTimelock: no tokens to release");

        userClaimed[msg.sender] = userClaimed[msg.sender].add(amount);
        
        token().safeTransfer(msg.sender, amount);
    }
}