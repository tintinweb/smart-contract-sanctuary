/*
@website https://boogie.finance
@authors Proof, sol_dev, Zoma, Mr Fahrenheit, Boogie
@auditors Aegis DAO, Sherlock Security
*/

pragma solidity ^0.6.12;

import './Ownable.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './IUniswapV2Router02.sol';
import './BOOGIE.sol';
import './Bar.sol';

// The Rave staking contract becomes active after the max supply it hit, and is where BOOGIE-ETH LP token stakers will continue to receive dividends from other projects in the BOOGIE ecosystem
contract Rave is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user
    struct UserInfo {
        uint256 staked; // How many BOOGIE-ETH LP tokens the user has staked
        uint256 rewardDebt; // Reward debt. Works the same as in the Bar contract
        uint256 claimed; // Tracks the amount of BOOGIE claimed by the user
    }

    // The BOOGIE TOKEN!
    BOOGIE public boogie;
    // The Bar contract
    Bar public bar;
    // The BOOGIE-ETH Uniswap LP token
    IERC20 public boogiePool;
    // The Uniswap v2 Router
    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // WETH
    IERC20 public weth;

    // Info of each user that stakes BOOGIE-ETH LP tokens
    mapping (address => UserInfo) public userInfo;
    // The amount of BOOGIE sent to this contract before it became active
    uint256 public initialBoogieReward = 0;
    // 5% of the initialBoogieReward will be rewarded to stakers per day for 100 days
    uint256 public initialBoogieRewardPerDay;
    // How often the initial 5% payouts can be processed
    uint256 public constant INITIAL_PAYOUT_INTERVAL = 24 hours;
    // Number of days over which the initial payouts will be distributed
    uint256 public constant NUM_PAYOUT_DAYS = 20;
    // The unstaking fee that is used to increase locked liquidity and reward Rave stakers (1 = 0.1%). Defaults to 10%
    uint256 public unstakingFee = 100;
    // The amount of BOOGIE-ETH LP tokens kept by the unstaking fee that will be converted to BOOGIE and distributed to stakers (1 = 0.1%). Defaults to 50%
    uint256 public unstakingFeeConvertToBoogieAmount = 500;
    // When the first 1% payout can be processed (timestamp). It will be 24 hours after the Rave contract is activated
    uint256 public startTime;
    // When the last 1% payout was processed (timestamp)
    uint256 public lastPayout;
    // The total amount of pending BOOGIE available for stakers to claim
    uint256 public totalPendingBoogie;
    // Accumulated BOOGIEs per share, times 1e12.
    uint256 public accBoogiePerShare;
    // The total amount of BOOGIE-ETH LP tokens staked in the contract
    uint256 public totalStaked;
    // Becomes true once the 'activate' function called by the Bar contract when the max BOOGIE supply is hit
    bool public active = false;

    event Stake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 boogieAmount);
    event Withdraw(address indexed user, uint256 amount);
    event BoogieRewardAdded(address indexed user, uint256 boogieReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    constructor(BOOGIE _boogie, Bar _bar) public {
        bar = _bar;
        boogie = _boogie;
        boogiePool = IERC20(bar.boogiePoolAddress());
        weth = IERC20(uniswapRouter.WETH());
    }

    receive() external payable {
        emit EthRewardAdded(msg.sender, msg.value);
    }

    function activate() public {
        require(active != true, "already active");
        require(boogie.maxSupplyHit() == true, "too soon");

        active = true;

        // Now that the Rave staking contract is active, reward 5% of the initialBoogieReward per day for 20 days
        startTime = block.timestamp + INITIAL_PAYOUT_INTERVAL; // The first payout can be processed 24 hours after activation
        lastPayout = startTime;
        initialBoogieRewardPerDay = initialBoogieReward.div(NUM_PAYOUT_DAYS);
    }

    // The _transfer function in the BOOGIE contract calls this to let the Rave contract know that it received the specified amount of BOOGIE to be distributed to stakers 
    function addBoogieReward(address _from, uint256 _amount) public {
        require(msg.sender == address(boogie), "not boogie contract");
        require(bar.boogiePoolActive() == true, "no boogie pool");
        require(_amount > 0, "no boogie");

        if (active != true || totalStaked == 0) {
            initialBoogieReward = initialBoogieReward.add(_amount);
        } else {
            totalPendingBoogie = totalPendingBoogie.add(_amount);
            accBoogiePerShare = accBoogiePerShare.add(_amount.mul(1e12).div(totalStaked));
        }

        emit BoogieRewardAdded(_from, _amount);
    }

    // Allows external sources to add ETH to the contract which is used to buy and then distribute BOOGIE to stakers
    function addEthReward() public payable {
        require(bar.boogiePoolActive() == true, "no boogie pool");

        // We will purchase BOOGIE with all of the ETH in the contract in case some was sent directly to the contract instead of using addEthReward
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "no eth");

        // Use the ETH to buyback BOOGIE which will be distributed to stakers
        _buyBoogie(ethBalance);

        // The _transfer function in the BOOGIE contract calls the Rave contract's updateBoogieReward function so we don't need to update the balances after buying the BOOGIE
        emit EthRewardAdded(msg.sender, msg.value);
    }

    // Internal function to buy back BOOGIE with the amount of ETH specified
    function _buyBoogie(uint256 _amount) internal {
        uint256 deadline = block.timestamp + 5 minutes;
        address[] memory boogiePath = new address[](2);
        boogiePath[0] = address(weth);
        boogiePath[1] = address(boogie);
        uniswapRouter.swapExactETHForTokens{value: _amount}(0, boogiePath, address(this), deadline);
    }

    // Handles paying out the initialBoogieReward over 20 days
    function _processInitialPayouts() internal {
        if (active != true || block.timestamp < startTime || initialBoogieReward == 0 || totalStaked == 0) return;

        // How many days since last payout?
        uint256 daysSinceLastPayout = (block.timestamp - lastPayout) / INITIAL_PAYOUT_INTERVAL;

        // If less than 1, don't do anything
        if (daysSinceLastPayout == 0) return;

        // Work out how many payouts have been missed
        uint256 nextPayoutNumber = (block.timestamp - startTime) / INITIAL_PAYOUT_INTERVAL;
        uint256 previousPayoutNumber = nextPayoutNumber - daysSinceLastPayout;

        // Calculate how much additional reward we have to hand out
        uint256 boogieReward = rewardAtPayout(nextPayoutNumber) - rewardAtPayout(previousPayoutNumber);
        if (boogieReward > initialBoogieReward) boogieReward = initialBoogieReward;
        initialBoogieReward = initialBoogieReward.sub(boogieReward);

        // Payout the boogieReward to the stakers
        totalPendingBoogie = totalPendingBoogie.add(boogieReward);
        accBoogiePerShare = accBoogiePerShare.add(boogieReward.mul(1e12).div(totalStaked));

        // Update lastPayout time
        lastPayout += (daysSinceLastPayout * INITIAL_PAYOUT_INTERVAL);
    }

    // Handles claiming the user's pending BOOGIE rewards
    function _claimReward(address _user) internal {
        UserInfo storage user = userInfo[_user];
        if (user.staked > 0) {
            uint256 pendingBoogieReward = user.staked.mul(accBoogiePerShare).div(1e12).sub(user.rewardDebt);
            if (pendingBoogieReward > 0) {
                totalPendingBoogie = totalPendingBoogie.sub(pendingBoogieReward);
                user.claimed += pendingBoogieReward;
                _safeBoogieTransfer(_user, pendingBoogieReward);
                emit Claim(_user, pendingBoogieReward);
            }
        }
    }

    // Stake BOOGIE-ETH LP tokens to get rewarded with more BOOGIE
    function stake(uint256 _amount) public {
        stakeFor(msg.sender, _amount);
    }

    // Stake BOOGIE-ETH LP tokens on behalf of another address
    function stakeFor(address _user, uint256 _amount) public {
        require(active == true, "not active");
        require(_amount > 0, "stake something");

        _processInitialPayouts();

        // Claim any pending BOOGIE
        _claimReward(_user);

        boogiePool.safeTransferFrom(address(msg.sender), address(this), _amount);

        UserInfo storage user = userInfo[_user];
        totalStaked = totalStaked.add(_amount);
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.staked.mul(accBoogiePerShare).div(1e12);
        emit Stake(_user, _amount);
    }

    // Claim earned BOOGIE. Claiming won't work until active == true
    function claim() public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(user.staked > 0, "no stake");
        
        _processInitialPayouts();

        // Claim any pending BOOGIE
        _claimReward(msg.sender);

        user.rewardDebt = user.staked.mul(accBoogiePerShare).div(1e12);
    }

    // Unstake and withdraw BOOGIE-ETH LP tokens and any pending BOOGIE rewards. There is a 10% unstaking fee, meaning the user will only receive 90% of their LP tokens back.
    // For the LP tokens kept by the unstaking fee, 50% will get locked forever in the BOOGIE contract, and 50% will get converted to BOOGIE and distributed to stakers.
    function withdraw(uint256 _amount) public {
        require(active == true, "not active");
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0 && user.staked >= _amount, "withdraw: not good");
        
        _processInitialPayouts();

        uint256 unstakingFeeAmount = _amount.mul(unstakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(unstakingFeeAmount);

        // Half of the LP tokens kept by the unstaking fee will be locked forever in the BOOGIE contract, the other half will be converted to BOOGIE and distributed to stakers
        uint256 lpTokensToConvertToBoogie = unstakingFeeAmount.mul(unstakingFeeConvertToBoogieAmount).div(1000);
        uint256 lpTokensToLock = unstakingFeeAmount.sub(lpTokensToConvertToBoogie);

        // Remove the liquidity from the Uniswap BOOGIE-ETH pool and buy BOOGIE with the ETH received
        // The _transfer function in the BOOGIE.sol contract automatically calls rave.addBoogieReward() so we don't have to in this function
        if (lpTokensToConvertToBoogie > 0) {
            boogiePool.safeApprove(address(uniswapRouter), lpTokensToConvertToBoogie);
            uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(boogie), lpTokensToConvertToBoogie, 0, 0, address(this), block.timestamp + 5 minutes);
            addEthReward();
        }

        // Permanently lock the LP tokens in the BOOGIE contract
        if (lpTokensToLock > 0) boogiePool.transfer(address(boogie), lpTokensToLock);

        // Claim any pending BOOGIE
        _claimReward(msg.sender);

        totalStaked = totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        boogiePool.safeTransfer(address(msg.sender), remainingUserAmount);
        user.rewardDebt = user.staked.mul(accBoogiePerShare).div(1e12);
        emit Withdraw(msg.sender, remainingUserAmount);
    }

    // Internal function to safely transfer BOOGIE in case there is a rounding error
    function _safeBoogieTransfer(address _to, uint256 _amount) internal {
        uint256 boogieBal = boogie.balanceOf(address(this));
        if (_amount > boogieBal) {
            boogie.transfer(_to, boogieBal);
        } else {
            boogie.transfer(_to, _amount);
        }
    }

    // Sets the unstaking fee. Can't be higher than 10%. _convertToBoogieAmount is the % of the LP tokens from the unstaking fee that will be converted to BOOGIE and distributed to stakers.
    // unstakingFee - unstakingFeeConvertToBoogieAmount = The % of the LP tokens from the unstaking fee that will be permanently locked in the BOOGIE contract
    function setUnstakingFee(uint256 _unstakingFee, uint256 _convertToBoogieAmount) public onlyOwner {
        require(_unstakingFee <= 100, "over 10%");
        require(_convertToBoogieAmount <= 1000, "bad amount");
        unstakingFee = _unstakingFee;
        unstakingFeeConvertToBoogieAmount = _convertToBoogieAmount;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // BOOGIE and BOOGIE-ETH LP tokens (the only 2 ERC2O's that should be in this contract) can't be withdrawn this way.
    function recoverERC20(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(boogie) && _tokenAddress != address(boogiePool));
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenBalance);
    }

    function payoutNumber() public view returns (uint256) {
        if (block.timestamp < startTime) return 0;

        uint256 payout = (block.timestamp - startTime).div(INITIAL_PAYOUT_INTERVAL);
        if (payout > NUM_PAYOUT_DAYS) return NUM_PAYOUT_DAYS;
        else return payout;
    }

    function timeUntilNextPayout() public view returns (uint256) {
        if (initialBoogieReward == 0) return 0;
        else {
            uint256 payout = payoutNumber();
            uint256 nextPayout = startTime.add((payout + 1).mul(INITIAL_PAYOUT_INTERVAL));
            return nextPayout - block.timestamp;
        }
    }

    function rewardAtPayout(uint256 _payoutNumber) public view returns (uint256) {
        if (_payoutNumber == 0) return 0;
        return initialBoogieRewardPerDay * _payoutNumber;
    }

    function getAllInfoFor(address _user) external view returns (bool isActive, uint256[12] memory info) {
        isActive = active;
        info[0] = boogie.balanceOf(address(this));
        info[1] = initialBoogieReward;
        info[2] = totalPendingBoogie;
        info[3] = startTime;
        info[4] = lastPayout;
        info[5] = totalStaked;
        info[6] = boogie.balanceOf(_user);
        if (bar.boogiePoolActive()) {
            info[7] = boogiePool.balanceOf(_user);
            info[8] = boogiePool.allowance(_user, address(this));
        }
        info[9] = userInfo[_user].staked;
        info[10] = userInfo[_user].staked.mul(accBoogiePerShare).div(1e12).sub(userInfo[_user].rewardDebt);
        info[11] = userInfo[_user].claimed;
    }
}