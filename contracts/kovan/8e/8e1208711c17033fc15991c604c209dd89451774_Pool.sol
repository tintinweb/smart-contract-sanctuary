/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.6.8;

contract Pool {
    
    event LiquidityCapSet(uint256 newLiquidityCap);
    event LoanFunded(address indexed loan, address debtLocker, uint256 amountFunded);
    event LockupPeriodSet(uint256 newLockupPeriod);
    event PoolOpenedToPublic(bool open);
    event StakingFeeSet(uint256 newStakingFee);
    event LossesDistributed(address whom, uint256 value);
    event PoolAdminSet(address poolAdmin, bool allowed);
    event LogA(address loan, address dlFactory);
    event Cooldown(address depositor, uint256 amt);
    event Claim(address indexed loan, uint256 interest, uint256 principal, uint256 fee, uint256 stakeLockerPortion, uint256 poolDelegatePortion);
    event CustodyAllowanceChanged(address indexed liquidityProvider, address indexed custodian, uint256 oldAllowance, uint256 newAllowance);
    event TotalCustodyAllowanceUpdated(address indexed liquidityProvider, uint256 newTotalAllowance);
    
    function setLiquidityCap(uint256 newLiquidityCap) external {
        emit LiquidityCapSet(newLiquidityCap);
    }
    
     function fundLoan(
        address loan,
        address debtLocker,
        uint256 amt
    ) external {
        emit LoanFunded(loan, debtLocker, amt);
    }
    
    function setLockupPeriod(uint256 newLockupPeriod) external {
        emit LockupPeriodSet(newLockupPeriod);
    }
    
    function distributeLosses(uint256 value) external {
        emit LossesDistributed(msg.sender, value);
    }
    
    function setOpenToPublic(bool open) external {
        emit PoolOpenedToPublic(open);
    }
    
    function setStakingFee(uint256 newStakingFee) external {
        emit StakingFeeSet(newStakingFee);
    }
    
    function setPoolAdmin(address poolAdmin, bool allowed) external {
        emit PoolAdminSet(poolAdmin, allowed);
    }
    
    function triggerDefault(address loan, address dlFactory) external {
       emit LogA(loan, dlFactory);
    }
    
    function deposit(uint256 amt) external {
        emit Cooldown(msg.sender, uint256(0));
    }
    
    function claim(address loan, address dlFactory) external returns (uint256[7] memory claimInfo) {
        claimInfo = [uint256(1),2,3,4,5,6,7];
        emit Claim(loan, 5, 6, 7, 3, 2);
    }
    
    function increaseCustodyAllowance(address custodian, uint256 amount) external {
        emit CustodyAllowanceChanged(msg.sender, custodian, 45, 60);
        emit TotalCustodyAllowanceUpdated(msg.sender, 60);
    }
    
    function withdraw(uint256 amt) external {
        emit LogA(address(amt), address(2));
    }
    
}