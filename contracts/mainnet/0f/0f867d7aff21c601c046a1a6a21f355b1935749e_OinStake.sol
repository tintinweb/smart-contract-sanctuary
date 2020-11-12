// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Owned.sol";
import "./IDparam.sol";
import "./WhiteList.sol";

interface IOracle {
    function val() external returns (uint256);

    function poke(uint256 price) external;

    function peek() external;
}

interface IESM {
    function isStakePaused() external view returns (bool);

    function isRedeemPaused() external view returns (bool);

    function isClosed() external view returns (bool);

    function time() external view returns (uint256);
}

interface ICoin {
    function burn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract OinStake is Owned, WhiteList {
    using Math for uint256;
    using SafeMath for uint256;

    /**
     * @notice Struct reward pools state
     * @param index Accumulated earnings index
     * @param block Update index, updating blockNumber together
     */
    struct RewardState {
        uint256 index;
        uint256 block;
    }
    /**
     * @notice reward pools state
     * @param index Accumulated earnings index by staker
     * @param reward Accumulative reward
     */
    struct StakerState {
        uint256 index;
        uint256 reward;
    }

    /// @notice TThe reward pool put into by the project side
    uint256 public reward;
    /// @notice The number of token per-block
    uint256 public rewardSpeed = 5e8;
    /// @notice Inital index
    uint256 public initialIndex = 1e16;
    /// @notice Amplification factor
    uint256 public doubleScale = 1e16;
    /// @notice The instance reward pools state
    RewardState public rewardState;

    /// @notice All staker-instances state
    mapping(address => StakerState) public stakerStates;

    /// @notice The amount by staker with token
    mapping(address => uint256) public tokens;
    /// @notice The amount by staker with coin
    mapping(address => uint256) public coins;
    /// @notice The total amount of out-coin in sys
    uint256 public totalCoin;
    /// @notice The total amount of stake-token in sys
    uint256 public totalToken;
    /// @notice Cumulative  service fee, it will be burn, not join reward.
    uint256 public sFee;
    uint256 constant ONE = 10**8;
    address constant blackhole = 0x1111111111111111111111111111111111111111;

    /// @notice Dparam address
    IDparam params;
    /// @notice Oracle address
    IOracle orcl;
    /// @notice Esm address
    IESM esm;
    /// @notice Coin address
    ICoin coin;
    /// @notice Token address
    IERC20 token;

    /// @notice Setup Oracle address success
    event SetupOracle(address orcl);
    /// @notice Setup Dparam address success
    event SetupParam(address param);
    /// @notice Setup Esm address success
    event SetupEsm(address esm);
    /// @notice Setup Token&Coin address success
    event SetupCoin(address token, address coin);
    /// @notice Stake success
    event StakeEvent(uint256 token, uint256 coin);
    /// @notice redeem success
    event RedeemEvent(uint256 token, uint256 move, uint256 fee, uint256 coin);
    /// @notice Update index success
    event IndexUpdate(uint256 delt, uint256 block, uint256 index);
    /// @notice ClaimToken success
    event ClaimToken(address holder, uint256 amount);
    /// @notice InjectReward success
    event InjectReward(uint256 amount);
    /// @notice ExtractReward success
    event ExtractReward(address reciver, uint256 amount);

    /**
     * @notice Construct a new OinStake, owner by msg.sender
     * @param _param Dparam address
     * @param _orcl Oracle address
     * @param _esm Esm address
     */
    constructor(
        address _param,
        address _orcl,
        address _esm
    ) public Owned(msg.sender) {
        params = IDparam(_param);
        orcl = IOracle(_orcl);
        esm = IESM(_esm);
        rewardState = RewardState(initialIndex, getBlockNumber());
    }

    modifier notClosed() {
        require(!esm.isClosed(), "System closed");
        _;
    }

    /**
     * @notice reset Dparams address.
     * @param _params Configuration dynamic params contract address
     */
    function setupParams(address _params) public onlyWhiter {
        params = IDparam(_params);
        emit SetupParam(_params);
    }

    /**
     * @notice reset Oracle address.
     * @param _orcl Configuration Oracle contract address
     */
    function setupOracle(address _orcl) public onlyWhiter {
        orcl = IOracle(_orcl);
        emit SetupOracle(_orcl);
    }

    /**
     * @notice reset Esm address.
     * @param _esm Configuration Esm contract address
     */
    function setupEsm(address _esm) public onlyWhiter {
        esm = IESM(_esm);
        emit SetupEsm(_esm);
    }

    /**
     * @notice get Dparam address.
     * @return Dparam contract address
     */
    function getParamsAddr() public view returns (address) {
        return address(params);
    }

    /**
     * @notice get Oracle address.
     * @return Oracle contract address
     */
    function getOracleAddr() public view returns (address) {
        return address(orcl);
    }

    /**
     * @notice get Esm address.
     * @return Esm contract address
     */
    function getEsmAddr() public view returns (address) {
        return address(esm);
    }

    /**
     * @notice get token of staking address.
     * @return ERC20 address
     */
    function getCoinAddress() public view returns (address) {
        return address(coin);
    }

    /**
     * @notice get StableToken address.
     * @return ERC20 address
     */
    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    /**
     * @notice inject token address & coin address only once.
     * @param _token token address
     * @param _coin coin address
     */
    function setup(address _token, address _coin) public onlyWhiter {
        require(
            address(token) == address(0) && address(coin) == address(0),
            "setuped yet."
        );
        token = IERC20(_token);
        coin = ICoin(_coin);

        emit SetupCoin(_token, _coin);
    }

    /**
     * @notice Get the number of debt by the `account`
     * @param account token address
     * @return (tokenAmount,coinAmount)
     */
    function debtOf(address account) public view returns (uint256, uint256) {
        return (tokens[account], coins[account]);
    }

    /**
     * @notice Get the number of debt by the `account`
     * @param coinAmount The amount that staker want to get stableToken
     * @return The amount that staker want to transfer token.
     */
    function getInputToken(uint256 coinAmount)
        public
        view
        returns (uint256 tokenAmount)
    {
        tokenAmount = coinAmount.mul(params.stakeRate());
    }

    /**
     * @notice Normally redeem anyAmount internal
     * @param coinAmount The number of coin will be staking
     */
    function stake(uint256 coinAmount) external notClosed {
        require(!esm.isStakePaused(), "Stake paused");
        require(coinAmount > 0, "The quantity is less than the minimum");
        require(orcl.val() > 0, "Oracle price not initialized.");
        require(params.isNormal(orcl.val()), "Oin's price is too low.");

        address from = msg.sender;

        if (coins[from] == 0) {
            require(
                coinAmount >= params.minMint(),
                "First make coin must grater than 100."
            );
        }

        accuredToken(from);

        uint256 tokenAmount = getInputToken(coinAmount);

        token.transferFrom(from, address(this), tokenAmount);
        coin.mint(from, coinAmount);

        totalCoin = totalCoin.add(coinAmount);
        totalToken = totalToken.add(tokenAmount);
        coins[from] = coins[from].add(coinAmount);
        tokens[from] = tokens[from].add(tokenAmount);

        emit StakeEvent(tokenAmount, coinAmount);
    }

    /**
     * @notice Normally redeem anyAmount internal
     * @param coinAmount The number of coin will be redeemed
     * @param receiver Address of receiving
     */
    function _normalRedeem(uint256 coinAmount, address receiver)
        internal
        notClosed
    {
        require(!esm.isRedeemPaused(), "Redeem paused");
        address staker = msg.sender;
        require(coins[staker] > 0, "No collateral");
        require(coinAmount > 0, "The quantity is less than zero");
        require(coinAmount <= coins[staker], "input amount overflow");

        accuredToken(staker);

        uint256 tokenAmount = getInputToken(coinAmount);

        uint256 feeRate = params.feeRate();
        uint256 fee = tokenAmount.mul(feeRate).div(1000);
        uint256 move = tokenAmount.sub(fee);
        sFee = sFee.add(fee);

        token.transfer(blackhole, fee);
        coin.burn(staker, coinAmount);
        token.transfer(receiver, move);

        coins[staker] = coins[staker].sub(coinAmount);
        tokens[staker] = tokens[staker].sub(tokenAmount);
        totalCoin = totalCoin.sub(coinAmount);
        totalToken = totalToken.sub(tokenAmount);

        emit RedeemEvent(tokenAmount, move, fee, coinAmount);
    }

    /**
     * @notice Abnormally redeem anyAmount internal
     * @param coinAmount The number of coin will be redeemed
     * @param receiver Address of receiving
     */
    function _abnormalRedeem(uint256 coinAmount, address receiver) internal {
        require(esm.isClosed(), "System not Closed yet.");
        address from = msg.sender;
        require(coinAmount > 0, "The quantity is less than zero");
        require(coin.balanceOf(from) > 0, "The coin no balance.");
        require(coinAmount <= coin.balanceOf(from), "Coin balance exceed");

        uint256 tokenAmount = getInputToken(coinAmount);

        coin.burn(from, coinAmount);
        token.transfer(receiver, tokenAmount);

        totalCoin = totalCoin.sub(coinAmount);
        totalToken = totalToken.sub(tokenAmount);

        emit RedeemEvent(tokenAmount, tokenAmount, 0, coinAmount);
    }

    /**
     * @notice Normally redeem anyAmount
     * @param coinAmount The number of coin will be redeemed
     * @param receiver Address of receiving
     */
    function redeem(uint256 coinAmount, address receiver) public {
        _normalRedeem(coinAmount, receiver);
    }

    /**
     * @notice Normally redeem anyAmount to msg.sender
     * @param coinAmount The number of coin will be redeemed
     */
    function redeem(uint256 coinAmount) public {
        redeem(coinAmount, msg.sender);
    }

    /**
     * @notice normally redeem them all at once
     * @param holder reciver
     */
    function redeemMax(address holder) public {
        redeem(coins[msg.sender], holder);
    }

    /**
     * @notice normally redeem them all at once to msg.sender
     */
    function redeemMax() public {
        redeemMax(msg.sender);
    }

    /**
     * @notice System shutdown under the redemption rule
     * @param coinAmount The number coin
     * @param receiver Address of receiving
     */
    function oRedeem(uint256 coinAmount, address receiver) public {
        _abnormalRedeem(coinAmount, receiver);
    }

    /**
     * @notice System shutdown under the redemption rule
     * @param coinAmount The number coin
     */
    function oRedeem(uint256 coinAmount) public {
        oRedeem(coinAmount, msg.sender);
    }

    /**
     * @notice Refresh reward speed.
     */
    function setRewardSpeed(uint256 speed) public onlyWhiter {
        updateIndex();
        rewardSpeed = speed;
    }

    /**
     * @notice Used to correct the effect of one's actions on one's own earnings
     *         System shutdown will no longer count
     */
    function updateIndex() public {
        if (esm.isClosed()) {
            return;
        }

        uint256 blockNumber = getBlockNumber();
        uint256 deltBlock = blockNumber.sub(rewardState.block);

        if (deltBlock > 0) {
            uint256 accruedReward = rewardSpeed.mul(deltBlock);
            uint256 ratio = totalToken == 0
                ? 0
                : accruedReward.mul(doubleScale).div(totalToken);
            rewardState.index = rewardState.index.add(ratio);
            rewardState.block = blockNumber;
            emit IndexUpdate(deltBlock, blockNumber, rewardState.index);
        }
    }

    /**
     * @notice Used to correct the effect of one's actions on one's own earnings
     *         System shutdown will no longer count
     * @param account staker address
     */
    function accuredToken(address account) internal {
        updateIndex();
        StakerState storage stakerState = stakerStates[account];
        stakerState.reward = _getReward(account);
        stakerState.index = rewardState.index;
    }

    /**
     * @notice Calculate the current holder's mining income
     * @param staker Address of holder
     */
    function _getReward(address staker) internal view returns (uint256 value) {
        StakerState storage stakerState = stakerStates[staker];
        value = stakerState.reward.add(
            rewardState.index.sub(stakerState.index).mul(tokens[staker]).div(
                doubleScale
            )
        );
    }

    /**
     * @notice Estimate the mortgagor's reward
     * @param account Address of staker
     */
    function getHolderReward(address account)
        public
        view
        returns (uint256 value)
    {
        uint256 blockReward2 = (totalToken == 0 || esm.isClosed())
            ? 0
            : getBlockNumber()
                .sub(rewardState.block)
                .mul(rewardSpeed)
                .mul(tokens[account])
                .div(totalToken);
        value = _getReward(account) + blockReward2;
    }

    /**
     * @notice Extract the current reward in one go
     * @param holder Address of receiver
     */
    function claimToken(address holder) public {
        accuredToken(holder);
        StakerState storage stakerState = stakerStates[holder];
        uint256 value = stakerState.reward.min(reward);
        require(value > 0, "The reward of address is zero.");

        token.transfer(holder, value);
        reward = reward.sub(value);

        stakerState.index = rewardState.index;
        stakerState.reward = stakerState.reward.sub(value);
        emit ClaimToken(holder, value);
    }

    /**
     * @notice Get block number now
     */
    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }

    /**
     * @notice Inject token to reward
     * @param amount The number of injecting
     */
    function injectReward(uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
        reward = reward.add(amount);
        emit InjectReward(amount);
    }

    /**
     * @notice Extract token from reward
     * @param account Address of receiver
     * @param amount The number of extracting
     */
    function extractReward(address account, uint256 amount) external onlyOwner {
        require(amount <= reward, "withdraw overflow.");
        token.transfer(account, amount);
        reward = reward.sub(amount);
        emit ExtractReward(account, amount);
    }
}
