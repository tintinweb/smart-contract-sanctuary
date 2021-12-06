//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IKeysStaking.sol";

/**
 *
 * KEYS Token Locking Contract
 * Contract Developed By DeFi Mark (MoonMark)
 *
 */
contract KEYSStakingContract is ReentrancyGuard, IERC20, IKeysStaking{

    using SafeMath for uint256;
    using Address for address;
    
    // KEYS Contract
    address constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // precision factor
    uint256 constant precision = 10**36;
    
    // Total Dividends Per Farm
    uint256 public dividendsPerToken;
 
    // 88 day lock time
    uint256 public lockTime = 633600;
    
    // Locker Structure
    struct StakedUser {
        uint256 tokensLocked;
        uint256 timeLocked;
        uint256 lastClaim;
        uint256 totalExcluded;
    }
    
    // Users -> StakedUser
    mapping ( address => StakedUser ) users;
    
    // total locked across all lockers
    uint256 totalLocked;
    
    // minimum stake amount
    uint256 public minToStake = 100 * 10**9;
    
    // reduced purchase fee
    uint256 public fee = 20;
    
    // fee for unstaking too early
    uint256 public earlyFee = 80;
    
    // multisignature wallet
    address public multisig = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;

    // Ownership
    address public owner;
    modifier onlyOwner(){require(owner == msg.sender, 'Only Owner'); _;}
    
    // Events
    event TransferOwnership(address newOwner);
    event UpdateFee(uint256 newFee);
    event UpdateLockTime(uint256 newTime);
    event UpdatedStakingMinimum(uint256 minimumKeys);
    event UpdatedFeeReceiver(address feeReceiver);
    event UpdatedEarlyFee(uint256 newFee);
    
    constructor() {
        owner = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
    }
    
    function totalSupply() external view override returns (uint256) { return totalLocked; }
    function balanceOf(address account) public view override returns (uint256) { return users[account].tokensLocked; }
    function allowance(address holder, address spender) external view override returns (uint256) { return holder == spender ? balanceOf(holder) : 0; }
    function name() public pure override returns (string memory) {
        return "Locked Keys";
    }
    function symbol() public pure override returns (string memory) {
        return "LOCKEDKEYS";
    }
    function decimals() public pure override returns (uint8) {
        return 9;
    }
    function approve(address spender, uint256 amount) public view override returns (bool) {
        return users[msg.sender].tokensLocked >= amount && spender != msg.sender;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // ensure claim requirements
        if (recipient == KEYS) {
            _unlock(msg.sender, msg.sender, amount);
        } else if (recipient == address(this)){
            _reinvestKeys(msg.sender);
        } else {
            _makeClaim(msg.sender);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (recipient == KEYS) {
            _unlock(msg.sender, msg.sender, amount);
        } else if (recipient == address(this)){
            _reinvestKeys(msg.sender);
        } else {
            _makeClaim(msg.sender);
        }
        return true && sender == recipient;
    }
    
    
    ///////////////////////////////////
    //////    OWNER FUNCTIONS   ///////
    ///////////////////////////////////

    function updateState(address[] calldata oldStakers) external onlyOwner {

        address old = 0xF09504B63a199158312807c5f05DaEcA734855D9;
        for (uint i = 0; i < oldStakers.length; i++) {
            uint256 bal = IERC20(old).balanceOf(oldStakers[i]);
            totalLocked += bal;
            users[oldStakers[i]].tokensLocked = bal;
            users[oldStakers[i]].timeLocked = block.number - 60000;
            emit Transfer(address(0), oldStakers[i], bal);
        }
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit TransferOwnership(newOwner);
    }
    
    function updateFee(uint256 newFee) external onlyOwner {
        fee = newFee;
        emit UpdateFee(newFee);
    }
    
    function updateFeeReceiver(address newReceiver) external onlyOwner {
        multisig = newReceiver;
        emit UpdatedFeeReceiver(newReceiver);
    }

    function setEarlyFee(uint256 newFee) external onlyOwner {
        earlyFee = newFee;
        emit UpdatedEarlyFee(newFee);
    }
    
    function setMinimumToStake(uint256 minimum) external onlyOwner {
        minToStake = minimum;
        emit UpdatedStakingMinimum(minimum);
    }
    
    function setLockTime(uint256 newTime) external onlyOwner {
        require(newTime <= 10**6, 'Lock Time Too Long');
        lockTime = newTime;
        emit UpdateLockTime(newTime);
    }
    
    function withdraw(bool eth, address token, uint256 amount, address recipient) external onlyOwner {
        if (eth) {
            require(address(this).balance >= amount, 'Insufficient Balance');
            (bool s,) = payable(recipient).call{value: amount}("");
            require(s, 'Failure on ETH Withdrawal');
        } else {
            IERC20(token).transfer(recipient, amount);
        }
    }
    
    
    ///////////////////////////////////
    //////   PUBLIC FUNCTIONS   ///////
    ///////////////////////////////////

    /** Adds KEYS To The Pending Rewards Of KEYS Stakers */
    function deposit(uint256 amount) external override {
        uint256 received = _transferIn(amount);
        dividendsPerToken += received.mul(precision).div(totalLocked);
    }

    function claimReward() external nonReentrant {
        _makeClaim(msg.sender);      
    }
    
    function claimRewardForUser(address user) external nonReentrant {
        _makeClaim(user);
    }
    
    function unlock(uint256 amount) external nonReentrant {
        _unlock(msg.sender, msg.sender, amount);
    }
    
    function unlockFor(uint256 amount, address keysRecipient) external nonReentrant {
        _unlock(msg.sender, keysRecipient, amount);
    }
    
    function unlockAll() external nonReentrant {
        _unlock(msg.sender, msg.sender, users[msg.sender].tokensLocked);
    }
    
    function stakeKeys(uint256 numKeys) external nonReentrant {
        uint256 received = _transferIn(numKeys);
        require(received >= minToStake, 'Minimum To Stake Not Reached');
        _lock(msg.sender, received);
    }

    function reinvestKeys() external nonReentrant {
        _reinvestKeys(msg.sender);
    }

    function _reinvestKeys(address user) internal {

        uint256 amount = pendingRewards(user);
        require(amount > 0, 'Zero Amount');

        // set locker data
        users[user].tokensLocked += amount;
        users[user].lastClaim = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        
        // increment total locked
        totalLocked += amount;
        
        // Transfer StakedKeys
        emit Transfer(address(0), user, amount);
    }
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    function _makeClaim(address user) internal {
        // ensure claim requirements
        require(users[user].tokensLocked > 0, 'Zero Tokens Locked');
        require((users[user].lastClaim + 10) < block.number, 'Claim Wait Time Not Reached');
        
        uint256 amount = pendingRewards(user);
        require(amount > 0,'Zero Rewards');
        _claimReward(user);
    }
    
    function _claimReward(address user) internal {
        
        uint256 amount = pendingRewards(user);
        if (amount == 0) return;
        
        // update claim stats 
        users[user].lastClaim = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        // transfer tokens
        bool s = IERC20(KEYS).transfer(user, amount);
        require(s,'Failure On Token Transfer');
    }
    
    function _transferIn(uint256 amount) internal returns (uint256) {
        
        uint256 before = IERC20(KEYS).balanceOf(address(this));
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount);
        
        uint256 difference = IERC20(KEYS).balanceOf(address(this)).sub(before);
        require(s && difference <= amount, 'Error On Transfer In');
        return difference;
    }
    
    function _buyKeys() internal returns (uint256) {
        
        uint256 feeAmount = msg.value.mul(fee).div(1000);
        uint256 purchaseAmount = msg.value.sub(feeAmount);
        
        (bool success,) = payable(multisig).call{value: feeAmount}("");
        require(success, 'Failure on Dev Payment');
        
        uint256 before = IERC20(KEYS).balanceOf(address(this));
        (bool s,) = payable(KEYS).call{value: purchaseAmount}("");
        require(s, 'Failure on KEYS Purchase');
        return IERC20(KEYS).balanceOf(address(this)).sub(before);
    }
    
    function _lock(address user, uint256 received) private {
        
        if (users[user].tokensLocked > 0) { // recurring locker
            _claimReward(user);
        } else { // new user
            users[user].lastClaim = block.number;
        }
        
        // add locker data
        users[user].tokensLocked += received;
        users[user].timeLocked = block.number;
        users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        
        // increment total locked
        totalLocked += received;
        
        emit Transfer(address(0), user, received);
    }

    function _unlock(address user, address recipient, uint256 nTokens) private {
        
        // Ensure Lock Requirements
        require(users[user].tokensLocked > 0, 'Zero Tokens Locked');
        require(users[user].tokensLocked >= nTokens && nTokens > 0, 'Insufficient Tokens');
        
        // expiration
        uint256 lockExpiration = users[user].timeLocked + lockTime;
        
        // claim reward 
        _claimReward(user);
        
        // Update Staked Balances
        if (users[user].tokensLocked == nTokens) {
            delete users[user]; // Free Storage
        } else {
            users[user].tokensLocked = users[user].tokensLocked.sub(nTokens, 'Insufficient Lock Amount');
            users[user].totalExcluded = currentDividends(users[user].tokensLocked);
        }
        
        // Update Total Locked
        totalLocked = totalLocked.sub(nTokens, 'Negative Locked');

        // Calculate Tokens To Send Recipient
        uint256 tokensToSend = lockExpiration > block.number ? _calculateAndReflect(nTokens) : nTokens;

        // Transfer KEYS Tokens To User
        bool s = IERC20(KEYS).transfer(recipient, tokensToSend);
        require(s, 'Failure on LP Token Transfer');

        // tell Blockchain
        emit Transfer(user, address(0), nTokens);
    }
    
    function _calculateAndReflect(uint256 nTokens) internal returns (uint256) {
        
        // apply early leave tax
        uint256 tax = nTokens.mul(earlyFee).div(1000);
        
        // Reflect Tax To KEYS Stakers
        dividendsPerToken += tax.mul(precision).div(totalLocked);
        
        // Return Send Amount
        return nTokens.sub(tax);
    }
    
    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////
    
    
    function getTimeUntilUnlock(address user) external view returns (uint256) {
        uint256 endTime = users[user].timeLocked + lockTime;
        return endTime > block.number ? endTime.sub(block.number) : 0;
    }
    
    function currentDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerToken).div(precision);
    }
    
    function pendingRewards(address user) public view returns (uint256) {
        uint256 amount = users[user].tokensLocked;
        if(amount == 0){ return 0; }

        uint256 shareholderTotalDividends = currentDividends(amount);
        uint256 shareholderTotalExcluded = users[user].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
    
    function totalPendingRewards() external view returns (uint256) {
        return IERC20(KEYS).balanceOf(address(this)).sub(totalLocked);
    }
    
    function calculateKEYSBalance(address user) external view returns (uint256) {
        return IERC20(KEYS).balanceOf(user);
    }
    
    function calculateKEYSContractBalance() external view returns (uint256) {
        return IERC20(KEYS).balanceOf(address(this));
    }

    receive() external payable {
        uint256 received = _buyKeys();
        require(received >= minToStake, 'Minimum To Stake Not Reached');
        _lock(msg.sender, received);
    }

}