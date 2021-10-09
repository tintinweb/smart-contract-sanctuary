// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Math.sol";

contract AYRA is ERC20, Ownable {

    using Math for uint256;

    address public walletOrigin = 0xE9fe09A55377f760128800e6813F2E2C07db60Ad;
    address public walletMarketProtection = 0x0bD042059368389fdC3968d671c40319dEb39F2c;
    address public walletFoundingPartners = 0x454d1252EC7c1Dc7E4D0A92A84A3Da2BD158b1D7;
    address public walletBlockedFoundingPartners = 0x8f7F2243A34169931741ba7eB257841C639Bc165;
    address public walletSocialPartners = 0xe307d66905D10e7e51B0BFb12E7e64C876a04215;
    address public walletProgrammersAndPartners = 0xc21713ef49a48396c1939233F3B24E1c4CCD09a4;
    address public walletPrivateInvestors = 0x252Fa9eD5F51e3A9CF1b1890f479775eFeaa653d;
    address public walletAidsAndDonations = 0x1EEffDA40C880a93E19ecAF031e529C723072e51;
    address public walletStakingAyra = 0xD55E7f6C6B8027Fa7FCdE6eFb4fD3f02d391130C;

    address public operatorAddress;

    uint256 public MAX_BURN_AMOUNT = 100_000_000_000_000 * (10 ** decimals());
    uint256 public BURN_AMOUNT = 5_000_000_000_000 * (10 ** decimals());
    uint256 public lastBurnDay = block.timestamp;
    uint256 public burnedAmount = 0;

    uint256 private _maxStakingAmount = 60_000_000_000_000 * (10 ** decimals());
    uint256 private _maxStakingAmountPerAccount = 100_000_000 * (10 ** decimals());
    uint256 private _totalStakingAmount = 0;
    uint256 private _stakingPeriod = block.timestamp + 730 days;
    uint256 private _stakingFirstPeriod = block.timestamp + 365 days;

    uint256 private _stakingFirstPeriodReward = 1644;
    uint256 private _stakingSecondPeriodReward = 822;
    
    uint256 public deployedTime = block.timestamp;

    uint256 public lastUnlockTime;
    uint256 public unlockAmountPerYear = 20_000_000_000_000 * (10 ** decimals());
    
    // Mapping owner address to staked token count
    mapping (address => uint) _stakedBalances;
    
    // Mapping from owner to last reward time
    mapping (address => uint) _rewardedLastTime;

    event StakingSucceed(address indexed account, uint256 totalStakedAmount);
    event WithdrawSucceed(address indexed account, uint256 remainedStakedAmount);

    /**
    * @dev modifier which requires that account must be operator
    */
    modifier onlyOperator() {
        require(_msgSender() == operatorAddress, "operator: wut?");
        _;
    }

    /**
    * @dev modifier which requires that walletAddress is not blocked address(walletMarketProtection),
    * until blocking period.
    */
    modifier onlyUnblock(address walletAddress) {
        require((walletAddress != walletMarketProtection && walletAddress != walletBlockedFoundingPartners)
                    || block.timestamp > deployedTime + 1825 days, "This wallet address is blocked for 5 years." );
        _;
    }

    /**
    * @dev Constructor: mint pre-defined amount of tokens to special wallets.
     */
    constructor() ERC20("AYRA", "AYRA") {
        operatorAddress = _msgSender();
        //uint totalSupply = 1_000_000_000_000_000 * (10 ** decimals());

        // 40% of total supply to walletOrigin
        _mint(walletOrigin, 400_000_000_000_000 * (10 ** decimals()));

        // 10% of total supply to walletMarketProtection
        _mint(walletMarketProtection, 100_000_000_000_000 * (10 ** decimals()));

        // 9% of total supply to walletFoundingPartners
        _mint(walletFoundingPartners, 90_000_000_000_000 * (10 ** decimals()));

        // 1% of total supply to walletBlockedFoundingPartners
        _mint(walletBlockedFoundingPartners, 10_000_000_000_000 * (10 ** decimals()));

        // 10% of total supply to walletSocialPartners
        _mint(walletSocialPartners, 100_000_000_000_000 * (10 ** decimals()));

        // 18% of total supply to walletProgrammersAndPartners
        _mint(walletProgrammersAndPartners, 180_000_000_000_000 * (10 ** decimals()));

        // 7% of total supply to walletPrivateInvestors
        _mint(walletPrivateInvestors, 70_000_000_000_000 * (10 ** decimals()));

        // 5% of total supply to walletAidsAndDonations
        _mint(walletAidsAndDonations, 50_000_000_000_000 * (10 ** decimals()));
    }

    /**
    * @dev set operator address
    * callable by owner
    */
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Cannot be zero address");
        operatorAddress = _operator;
    }

    /**
     * @dev Destroys `amount` tokens from `walletOrigin`, reducing the
     * total supply.
     *
     * Requirements:
     *
     * - total burning amount can not exceed `_maxBurnAmount`
     * - burning moment have to be 90 days later from `lastBurnDay`
     */
    function burn() external onlyOperator {
        
        require(burnedAmount + BURN_AMOUNT <= MAX_BURN_AMOUNT, "Burning too much.");
        require(lastBurnDay + 90 days <= block.timestamp, "It's not time to burn. 90 days aren't passed since last burn");
        lastBurnDay = block.timestamp;

        _burn(walletOrigin, BURN_AMOUNT);
        burnedAmount += BURN_AMOUNT;
    }

    /**
     * @dev Stake `amount` tokens from `msg.sender` to `walletOrigin`, calculate reward upto now.
     *
     * Emits a {StakingSucceed} event with `account` and total staked balance of `account`
     *
     * Requirements:
     *
     * - `account` must have at least `amount` tokens
     * - staking moment have to be in staking period
     * - staked balance of each account can not exceed `_maxStakingAmountPerAccount`
     * - total staking amount can not exceed `_totalStakingAmount`
     */
    function stake(uint amount) external {
        
        address account = _msgSender();

        require(balanceOf(account) >= amount, "insufficient balance for staking.");
        require(block.timestamp <= _stakingPeriod, "The time is over staking period.");

        _updateReward(account);

        _stakedBalances[account] += amount;
        require(_stakedBalances[account] <= _maxStakingAmountPerAccount, "This account overflows staking amount");
        
        _totalStakingAmount += amount;
        require(_totalStakingAmount <= _maxStakingAmount, "Total staking amount overflows its limit.");
        
        _transfer(account, walletStakingAyra, amount);
        
        emit StakingSucceed(account, _stakedBalances[account]);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`. Something different from ERC20 is
     * adding reward which is not yet appended to account wallet.
     */
    function balanceOf(address account) public view override returns (uint) {
        return ERC20.balanceOf(account) + getAvailableReward(account);
    }

    /**
     * @dev Get account's reward which is yielded after last rewarded time.
     *
     * @notice if getting moment is after stakingPeriod, the reward must be 0.
     * 
     * First `if` statement is in case of `lastTime` is before firstPeriod.
     *         `lastTime`  block.timestamp(if1)                   block.timestamp(if2)
     * ||----------|---------------|------------||------------------------|-----------||
     *              firstPeriod                             secondPeriod
     *
     * Second `if` statement is in case of block.timestamp is in secondPeriod.
     */
    function getAvailableReward(address account) public view returns (uint) {

        if (_rewardedLastTime[account] > _stakingPeriod) return 0;
        
        uint reward = 0;
        if (_rewardedLastTime[account] <= _stakingFirstPeriod) {
            uint rewardDays = _stakingFirstPeriod.min(block.timestamp) - _rewardedLastTime[account];
            rewardDays /= 1 days;
            reward = rewardDays * _stakedBalances[account] * _stakingFirstPeriodReward / 1000000;
        }

        if (block.timestamp > _stakingFirstPeriod) {
            uint rewardDays = _stakingPeriod.min(block.timestamp) - _rewardedLastTime[account].max(_stakingFirstPeriod);
            rewardDays /= 1 days;
            reward += rewardDays * _stakedBalances[account] * _stakingSecondPeriodReward / 1000000;
        }
        
        return reward;
    }

    /**
     * @dev Withdraw `amount` tokens from stakingPool(`walletOrigin`) to `msg.sender` address, calculate reward upto now.
     *
     * Emits a {WithdrawSucceed} event with `account` and total staked balance of `account`
     *
     * Requirements:
     *
     * - staked balance of `msg.sender` must be at least `amount`.
     */
    function withdraw(uint amount) external {
        address account = _msgSender();
        require (_stakedBalances[account] >= amount, "Can't withdraw more than staked balance");

        _updateReward(account);

        _stakedBalances[account] -= amount;
        _totalStakingAmount -= amount;
        _transfer(walletStakingAyra, account, amount);

        emit WithdrawSucceed(account, _stakedBalances[account]);
    } 

    /**
     * @dev Hook that is called before any transfer of tokens. 
     * Here, update from's balance by adding not-yet-appended reward.
     *
     * Requirements:
     *
     * - blocked wallet (walletMarketProtection) can't be tranferred or transfer any balance.
     */
    function _beforeTokenTransfer(address from, address to, uint256) internal override onlyUnblock(from) {
        if (from != address(0) && from != walletOrigin) {
            _updateReward(from);
        }
    }

    /**
     * @dev Get account's available reward which is yielded from last rewarded moment.
     * And append available reward to account's balance.
     */
    function _updateReward(address account) public {
        uint availableReward = getAvailableReward(account);
        _rewardedLastTime[account] = block.timestamp;
        _transfer(walletOrigin, account, availableReward);
    }

    /**
     * @dev Unlock `walletMarketProtection`, which means that transfer tokens from `walletMarketProtection`
     * to `walletOrigin`, so that it can be traded across users.ok
     */
    function unlockProtection() public onlyOperator {
        require (block.timestamp > deployedTime + 5 * 365 days, "Unlock is not allowed now");
        require (block.timestamp > lastUnlockTime + 365 days, "Unlock must be 1 year later from previous unlock");
        lastUnlockTime = block.timestamp;
        _transfer(walletMarketProtection, walletOrigin, unlockAmountPerYear);
    }
}