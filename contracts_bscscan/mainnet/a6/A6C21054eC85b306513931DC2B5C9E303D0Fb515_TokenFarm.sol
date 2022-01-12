//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IUniswapV2Router02.sol";
import "./IStaking.sol";

/**
 *
 * GNL Farming Contract
 * Grants Passive GNL To Users Who Stake + Lock GNL + BNB Into Liquidity
 * Developed by DeFi Mark (MoonMark)
 *
 */
contract TokenFarm is ReentrancyGuard, IERC20, IStaking {
 
    using SafeMath for uint256;
    using Address for address;
    
    // Token Contracts
    address constant REWARD = 0x128699dBEaFd83Ad25D16D394b7849e27A7C4607;
    address constant TOKEN_LP = 0x1eb44ba7e065aa6536029298097D189f703f606f;
    
    // Uniswap Router
    IUniswapV2Router02 router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // precision factor
    uint256 constant precision = 10**36;
    
    // Total Dividends Per Farm
    uint256 public dividendsPerToken;
 
    // 31 day lock time
    uint256 public lockTime = 900000;
    
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
    
    // reduced purchase fee
    uint256 public fee = 20;
    
    // fee for unstaking too early
    uint256 public earlyFee = 100;
    
    // Fee Receiver wallet
    address public feeReceiver = 0x9FDa2176717ea4F0d2bf73ba6F3b2Ca544855875;
    
    bool receiveDisabled;
    address[] path;
    
    // Ownership
    address public owner;
    modifier onlyOwner(){require(owner == msg.sender, 'Only Owner'); _;}
    
    // Events
    event TransferOwnership(address newOwner);
    event UpdateFee(uint256 newFee);
    event UpdateLockTime(uint256 newTime);
    event UpdatedStakingMinimum(uint256 minimumGram);
    event UpdatedFeeReceiver(address feeReceiver);
    event UpdatedEarlyFee(uint256 newFee);
    
    constructor() {
        owner = feeReceiver;
        
        // BNB -> Token
        path = new address[](2);
        path[0] = router.WETH();
        path[1] = REWARD;
    }
    
    function totalSupply() external view override returns (uint256) { return totalLocked; }
    function balanceOf(address account) public view override returns (uint256) { return users[account].tokensLocked; }
    function allowance(address holder, address spender) external view override returns (uint256) { return holder == spender ? balanceOf(holder) : 0; }
    function name() public pure override returns (string memory) {
        return "GNL Farm";
    }
    function symbol() public pure override returns (string memory) {
        return "GNL FARM";
    }
    function decimals() public pure override returns (uint8) {
        return 18;
    }
    function approve(address spender, uint256 amount) public view override returns (bool) {
        return users[msg.sender].tokensLocked >= amount && spender != msg.sender;
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        // ensure claim requirements
        if (recipient == REWARD) {
            _unlock(msg.sender, msg.sender, amount, false);
        } else {
            _makeClaim(msg.sender);
        }
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (recipient == REWARD) {
            _unlock(msg.sender, msg.sender, amount, false);
        } else {
            _makeClaim(msg.sender);
        }
        return true && sender == recipient;
    }
    
    
    ///////////////////////////////////
    //////    OWNER FUNCTIONS   ///////
    ///////////////////////////////////
    
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit TransferOwnership(newOwner);
    }
    
    function updateFee(uint256 newFee) external onlyOwner {
        require(earlyFee <= 500, 'Fee Too Large');
        fee = newFee;
        emit UpdateFee(newFee);
    }
    
    function updateFeeReceiver(address newReceiver) external onlyOwner {
        feeReceiver = newReceiver;
        emit UpdatedFeeReceiver(newReceiver);
    }
    
    function setEarlyFee(uint256 newFee) external onlyOwner {
        require(earlyFee <= 30, 'Fee Too Large');
        earlyFee = newFee;
        emit UpdatedEarlyFee(newFee);
    }
    
    function setLockTime(uint256 newTime) external onlyOwner {
        require(newTime <= 10**7, 'Lock Time Too Long');
        lockTime = newTime;
        emit UpdateLockTime(newTime);
    }
    
    function withdraw(bool ETH, address token, uint256 amount, address recipient) external onlyOwner {
        if (ETH) {
            require(address(this).balance >= amount, 'Insufficient Balance');
            (bool s,) = payable(recipient).call{value: amount}("");
            require(s, 'Failure on ETH Withdrawal');
        } else {
            require(token != TOKEN_LP, 'Cannot Withdraw Token LP');
            IERC20(token).transfer(recipient, amount);
        }
    }
    
    
    ///////////////////////////////////
    //////   PUBLIC FUNCTIONS   ///////
    ///////////////////////////////////

    /** Adds REWARD To The Pending Rewards Of TOKEN_LP Stakers */
    function deposit(uint256 amount) external override {
        uint256 received = _transferIn(REWARD, amount);
        dividendsPerToken += received.mul(precision).div(totalLocked);
    }

    function claimReward() external nonReentrant {
        _makeClaim(msg.sender);      
    }
    
    function claimRewardForUser(address user) external nonReentrant {
        _makeClaim(user);
    }
    
    function unlock(uint256 amount) external nonReentrant {
        _unlock(msg.sender, msg.sender, amount, false);
    }
    
    function unlockFor(uint256 amount, address recipient) external nonReentrant {
        _unlock(msg.sender, recipient, amount, false);
    }
    
    function unlockAll() external nonReentrant {
        _unlock(msg.sender, msg.sender, users[msg.sender].tokensLocked, false);
    }
    
    function unstake(uint256 amount) external nonReentrant {
        _unlock(msg.sender, msg.sender, amount, true);
    }
    
    function unstakeAll() external nonReentrant {
        _unlock(msg.sender, msg.sender, users[msg.sender].tokensLocked, true);
    }
    
    function unstakeFor(uint256 amount, address recipient) external nonReentrant {
        _unlock(msg.sender, recipient, amount, true);
    }
    
    function stakeLP(uint256 numLPTokens) external nonReentrant {
        uint256 received = _transferIn(TOKEN_LP, numLPTokens);
        _lock(msg.sender, received);
    }
    
    function stakeTokensAndBNB(uint256 numTokens) external payable nonReentrant {
        require(numTokens >= 10 && msg.value >= 10**9, 'Minimum Amount');
        
        // transfer in tokens
        uint256 received = _transferIn(REWARD, numTokens);
        
        // Estimated Tokens To Receive From BNB
        uint256 estimate = router.getAmountsOut(msg.value, path)[1];
        
        // Estimate Difference
        uint256 diff = estimate < received ? received - estimate : estimate - received;
        
        // Ensure Difference Within Bounds
        require(diff <= estimate.div(10), 'Error: Over 10% Slippage Detected');
        
        // Pair Halves Into Liquidity + Lock LP Received
        _pairAndLock(received, msg.value);
    }
    
    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////
    
    function _pairAndLock(uint256 amount, uint256 ethAmount) internal {
        
        // balance of LP Tokens Before
        uint256 lBefore = IERC20(TOKEN_LP).balanceOf(address(this));
        
        // approve router to move tokens
        IERC20(REWARD).approve(address(router), amount);
        
        // check slippage
        (uint256 minAmountToken, uint256 minETH) = (amount.mul(75).div(100), ethAmount.mul(75).div(100));
        
        // Disable Receive 
        receiveDisabled = true;
        
        // Calculated Expected Amounts After LP Pairing
        uint256 expectedTokens = IERC20(REWARD).balanceOf(address(this)).sub(amount, 'ERR Amount To Pair');
        uint256 expectedETH = address(this).balance.sub(ethAmount, 'ERR ETH Amount');
        
        // add liquidity
        router.addLiquidityETH{value: ethAmount}(
            REWARD,
            amount,
            minAmountToken,
            minETH,
            address(this),
            block.timestamp.add(30)
        );
        
        // Re Enable Receive
        receiveDisabled = false;
        
        uint256 tokensAfter = IERC20(REWARD).balanceOf(address(this));
        uint256 ETHAfter = address(this).balance;

        // note LP Tokens Received
        uint256 lpReceived = IERC20(TOKEN_LP).balanceOf(address(this)).sub(lBefore);
        require(lpReceived > 0, 'Zero LP Tokens Received');
        
        // Lock LP Tokens Received
        _lock(msg.sender, lpReceived);
        
        if (tokensAfter > expectedTokens) {
            uint256 diff = tokensAfter.sub(expectedTokens);
            IERC20(REWARD).transfer(msg.sender, diff);
        }
    
        if (ETHAfter > expectedETH) {
            uint256 diff = ETHAfter.sub(expectedETH);
            (bool s,) = payable(msg.sender).call{value: diff, gas: 2600}("");
            require(s, 'Failure on ETH Refund');
        }
    }
    
    function _removeLiquidity(uint256 nLiquidity, address recipient) private {
        
        IERC20(TOKEN_LP).approve(address(router), 2*nLiquidity);
        
        router.removeLiquidityETHSupportingFeeOnTransferTokens(
            REWARD,
            nLiquidity,
            0,
            0,
            recipient,
            block.timestamp.add(30)
        );
        
    }
    
    function _makeClaim(address user) internal {
        // ensure claim requirements
        require(users[user].tokensLocked > 0, 'Zero Tokens Locked');
        require(users[user].lastClaim + 10 < block.number, 'Claim Wait Time Not Reached');
        
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
        bool s = IERC20(REWARD).transfer(user, amount);
        require(s,'Failure On Token Transfer');
    }
    
    function _transferIn(address token, uint256 amount) internal returns (uint256) {
        
        uint256 before = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        uint256 difference = IERC20(token).balanceOf(address(this)).sub(before);
        require(s && difference > 0, 'Error On Transfer In');
        return difference;
    }
    
    function _buyAndStake() internal {
        
        uint256 feeAmount = msg.value.mul(fee).div(1000);
        uint256 purchaseAmount = msg.value.sub(feeAmount);
        
        uint256 tokenAmount = purchaseAmount.div(2);
        uint256 bnbAmount = purchaseAmount.sub(tokenAmount);
        
        (bool success,) = payable(feeReceiver).call{value: feeAmount}("");
        require(success, 'Failure on Dev Payment');
        
        uint256 before = IERC20(REWARD).balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: tokenAmount}(
            0,
            path,
            address(this),
            block.timestamp + 30
        );        
        uint256 tokensReceived = IERC20(REWARD).balanceOf(address(this)).sub(before);
        require(tokensReceived > 0, 'Zero Received');
        
        _pairAndLock(tokensReceived, bnbAmount);
    }
    
    function _lock(address user, uint256 received) private {
        
        if (users[user].tokensLocked > 0) { // recurring staker
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

    function _unlock(address user, address recipient, uint256 nTokens, bool removeLiquidity) private {
        
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
        uint256 tokensToSend = lockExpiration > block.number ? _calculateEarlyFee(nTokens) : nTokens;

        if (removeLiquidity) {
            // Remove LP Send To User
            _removeLiquidity(tokensToSend, recipient);
        } else {
            // Transfer LP Tokens To User
            bool s = IERC20(TOKEN_LP).transfer(recipient, tokensToSend);
            require(s, 'Failure on LP Token Transfer');
        }
        
        if (tokensToSend < nTokens) {
            uint256 dif = nTokens.sub(tokensToSend);
            IERC20(TOKEN_LP).transfer(feeReceiver, dif);
        }
        
        // tell Blockchain
        emit Transfer(user, address(0), nTokens);
    }
    
    function _calculateEarlyFee(uint256 nTokens) internal view returns (uint256) {
        
        // apply early leave tax
        uint256 tax = nTokens.mul(earlyFee).div(1000);
        
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
        return IERC20(REWARD).balanceOf(address(this)).sub(totalLocked);
    }

    receive() external payable {
        if (receiveDisabled || msg.sender == address(router) || msg.sender == TOKEN_LP) return;
        _buyAndStake();
    }

}