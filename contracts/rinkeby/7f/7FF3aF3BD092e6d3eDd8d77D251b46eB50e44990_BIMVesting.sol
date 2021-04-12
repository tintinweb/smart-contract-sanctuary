// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @dev BIM Vesting contract
 */
contract BIMVesting is Ownable, IBIMVesting {
    using SafeMath for uint;
    using SafeERC20 for IBIMToken;

    uint256 internal constant DAY = 10; // @dev MODIFY TO 86400 BEFORE PUBLIC RELEASE
    uint256 internal constant MONTH = DAY * 30;
    
    IBIMToken public BIMContract;
    IERC20 public BIMLockupContract;

    // @dev vestable group
    mapping(address => bool) public vestableGroup;
    
    modifier onlyVestableGroup() {
        require(vestableGroup[msg.sender], "not in vestable group");
        _;
    }
    
    // @dev vesting assets are grouped by day
    struct Round {
        mapping (address => uint256) balances;
        uint startDate;
    }
    
    /// @dev round index mapping
    mapping (int256 => Round) public rounds;
    /// @dev a monotonic increasing index
    int256 public currentRound = 0;

    /// @dev current vested BIMS    
    mapping (address => uint256) private balances;

    constructor(IBIMToken bimContract, IERC20 bimLockupContract) 
        public {
        BIMContract = bimContract;
        BIMLockupContract = bimLockupContract;
        rounds[0].startDate = block.timestamp;
    }
    
    /**
     * @dev set or remove address to vestable group
     */
    function setVestable(address account, bool allow) external onlyOwner {
        vestableGroup[account] = allow;
        if (allow) {
            emit Vestable(account);
        }  else {
            emit Unvestable(account);
        }
    }

    /**
     * @dev vest some BIM tokens for an account
     * Contracts that will call vest function(vestable group):
     * 
     * 1. LPStaking
     * 2. EHCStaking
     */
    function vest(address account, uint256 amount) external override onlyVestableGroup {
        update();

        rounds[currentRound].balances[account] += amount;
        balances[account] += amount;
        
        // emit amount vested
        emit Vested(account, amount);
    }
    
    /**
     * @dev check total vested bims
     */
    function checkVestedBims(address account) public view returns(uint256) {
        return balances[account];
    }
    
    /**
     * @dev check current locked BIMS
     */
    function checkLockedBims(address account) public view returns(uint256) {
        uint256 monthAgo = block.timestamp - MONTH;
        uint256 lockedAmount;
        for (int256 i= currentRound; i>=0; i--) {
            if (rounds[i].startDate < monthAgo) {
                break;
            } else {
                lockedAmount += rounds[i].balances[account];
            }
        }
        
        return lockedAmount;
    }

    /**
     * @dev check current claimable BIMS without penalty
     */
    function checkUnlockedBims(address account) public view returns(uint256) {
        uint256 lockedAmount = checkLockedBims(account);
        return balances[account].sub(lockedAmount);
    }
    
    /**
     * @dev claim unlocked BIMS without penalty
     */
    function claimUnlockedBims() external {
        update();
        
        uint256 unlockedAmount = checkUnlockedBims(msg.sender);
        balances[msg.sender] -= unlockedAmount;
        BIMContract.safeTransfer(msg.sender, unlockedAmount);
        
        emit Claimed(msg.sender, unlockedAmount);
    }

    /**
     * @dev claim all BIMS with penalty
     */
    function claimAllBims() external {
        update();
        
        uint256 lockedAmount = checkLockedBims(msg.sender);
        uint256 penalty = lockedAmount/2;
        uint256 bimsToClaim = balances[msg.sender].sub(penalty);

        // reset balances in this month(still locked) to 0
        uint256 monthAgo = block.timestamp - MONTH;
        for (int256 i= currentRound; i>=0; i--) {
            if (rounds[i].startDate < monthAgo) {
                break;
            } else {
                delete rounds[i].balances[msg.sender];
            }
        }
        
        // reset user's total balance to 0
        delete balances[msg.sender];
        
        // transfer BIMS to msg.sender        
        if (bimsToClaim > 0) {
            BIMContract.safeTransfer(msg.sender, bimsToClaim);
            emit Claimed(msg.sender, bimsToClaim);
        }
        
        // 50% penalty BIM goes to BIMLockup contract
        if (penalty > 0) {
            BIMContract.safeTransfer(address(BIMLockupContract), penalty);
            emit Penalty(msg.sender, penalty);
        }
    }
    
    /**
     * @dev round update operation
     */
    function update() public {
        uint numDays = block.timestamp.sub(rounds[currentRound].startDate).div(DAY);
        if (numDays > 0) {
            currentRound++;
            rounds[currentRound].startDate = rounds[currentRound-1].startDate + numDays * DAY;
        }
    }
    
    /**
     * @dev Events
     * ----------------------------------------------------------------------------------
     */
     
    event Vestable(address account);
    event Unvestable(address account);
    event Penalty(address account, uint256 amount);
    event Vested(address account, uint256 amount);
    event Claimed(address account, uint256 amount);
    
}