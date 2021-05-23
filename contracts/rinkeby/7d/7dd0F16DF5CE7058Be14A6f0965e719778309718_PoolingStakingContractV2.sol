// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;

import "Ownable.sol";
import "SafeMath.sol";
import "AbstractStakingContract.sol";

/**
 * @notice Contract acts as delegate for sub-stakers
 **/
contract PoolingStakingContractV2 is InitializableStakingContract, Ownable {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for NuCypherToken;

    event TokensDeposited(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event TokensWithdrawn(
        address indexed sender,
        uint256 value,
        uint256 depositedTokens
    );
    event ETHWithdrawn(address indexed sender, uint256 value);
    event WorkerOwnerSet(address indexed sender, address indexed workerOwner);

    struct Delegator {
        uint256 depositedTokens;
        uint256 withdrawnReward;
        uint256 withdrawnETH;
    }

    /**
     * Defines base fraction and precision of worker fraction.
     * E.g., for a value of 10000, a worker fraction of 100 represents 1% of reward (100/10000)
     */
    uint256 public constant BASIS_FRACTION = 10000;

    StakingEscrow public escrow;
    address public workerOwner;

    uint256 public totalDepositedTokens;
    uint256 public totalWithdrawnReward;
    uint256 public totalWithdrawnETH;

    uint256 workerFraction;
    uint256 public workerWithdrawnReward;

    mapping(address => Delegator) public delegators;

    /**
     * @notice Initialize function for using with OpenZeppelin proxy
     * @param _workerFraction Share of token reward that worker node owner will get.
     * Use value up to BASIS_FRACTION (10000), if _workerFraction = BASIS_FRACTION -> means 100% reward as commission.
     * For example, 100 worker fraction is 1% of reward
     * @param _router StakingInterfaceRouter address
     * @param _workerOwner Owner of worker node, only this address can withdraw worker commission
     */
    function initialize(
        uint256 _workerFraction,
        StakingInterfaceRouter _router,
        address _workerOwner
    ) external initializer {
        require(_workerOwner != address(0) && _workerFraction <= BASIS_FRACTION);
        InitializableStakingContract.initialize(_router);
        _transferOwnership(msg.sender);
        escrow = _router.target().escrow();
        workerFraction = _workerFraction;
        workerOwner = _workerOwner;
        emit WorkerOwnerSet(msg.sender, _workerOwner);
    }

    /**
     * @notice withdrawAll() is allowed
     */
    function isWithdrawAllAllowed() public view returns (bool) {
        // no tokens in StakingEscrow contract which belong to pool
        return escrow.getAllTokens(address(this)) == 0;
    }

    /**
     * @notice deposit() is allowed
     */
    function isDepositAllowed() public view returns (bool) {
        // tokens which directly belong to pool
        uint256 freeTokens = token.balanceOf(address(this));

        // no sub-stakes and no earned reward
        return isWithdrawAllAllowed() && freeTokens == totalDepositedTokens;
    }

    /**
     * @notice Set worker owner address
     */
    function setWorkerOwner(address _workerOwner) external onlyOwner {
        workerOwner = _workerOwner;
        emit WorkerOwnerSet(msg.sender, _workerOwner);
    }

    /**
     * @notice Calculate worker's fraction depending on deposited tokens
     * Override to implement dynamic worker fraction.
     */
    function getWorkerFraction() public view virtual returns (uint256) {
        return workerFraction;
    }

    /**
     * @notice Transfer tokens as delegator
     * @param _value Amount of tokens to transfer
     */
    function depositTokens(uint256 _value) external {
        require(isDepositAllowed(), "Deposit must be enabled");
        require(_value > 0, "Value must be not empty");
        totalDepositedTokens = totalDepositedTokens.add(_value);
        Delegator storage delegator = delegators[msg.sender];
        delegator.depositedTokens = delegator.depositedTokens.add(_value);
        token.safeTransferFrom(msg.sender, address(this), _value);
        emit TokensDeposited(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Get available reward for all delegators and owner
     */
    function getAvailableReward() public view returns (uint256) {
        // locked + unlocked tokens in StakingEscrow contract which belong to pool
        uint256 stakedTokens = escrow.getAllTokens(address(this));
        // tokens which directly belong to pool
        uint256 freeTokens = token.balanceOf(address(this));
        // tokens in excess of the initially deposited
        uint256 reward = stakedTokens.add(freeTokens).sub(totalDepositedTokens);
        // check how many of reward tokens belong directly to pool
        if (reward > freeTokens) {
            return freeTokens;
        }
        return reward;
    }

    /**
     * @notice Get cumulative reward.
     * Available and withdrawn reward together to use in delegator/owner reward calculations
     */
    function getCumulativeReward() public view returns (uint256) {
        return getAvailableReward().add(totalWithdrawnReward);
    }

    /**
     * @notice Get available reward in tokens for worker node owner
     */
    function getAvailableWorkerReward() public view returns (uint256) {
        // total current and historical reward
        uint256 reward = getCumulativeReward();

        // calculate total reward for worker including historical reward
        uint256 maxAllowableReward;
        // usual case
        if (totalDepositedTokens != 0) {
            uint256 fraction = getWorkerFraction();
            maxAllowableReward = reward.mul(fraction).div(BASIS_FRACTION);
        // special case when there are no delegators
        } else {
            maxAllowableReward = reward;
        }

        // check that worker has any new reward
        if (maxAllowableReward > workerWithdrawnReward) {
            return maxAllowableReward - workerWithdrawnReward;
        }
        return 0;
    }

    /**
     * @notice Get available reward in tokens for delegator
     */
    function getAvailableDelegatorReward(address _delegator) public view returns (uint256) {
        // special case when there are no delegators
        if (totalDepositedTokens == 0) {
            return 0;
        }

        // total current and historical reward
        uint256 reward = getCumulativeReward();
        Delegator storage delegator = delegators[_delegator];
        uint256 fraction = getWorkerFraction();

        // calculate total reward for delegator including historical reward
        // excluding worker share
        uint256 maxAllowableReward = reward.mul(delegator.depositedTokens).mul(BASIS_FRACTION - fraction).div(
            totalDepositedTokens.mul(BASIS_FRACTION)
        );

        // check that worker has any new reward
        if (maxAllowableReward > delegator.withdrawnReward) {
            return maxAllowableReward - delegator.withdrawnReward;
        }
        return 0;
    }

    /**
     * @notice Withdraw reward in tokens to worker node owner
     */
    function withdrawWorkerReward() external {
        require(msg.sender == workerOwner);
        uint256 balance = token.balanceOf(address(this));
        uint256 availableReward = getAvailableWorkerReward();

        if (availableReward > balance) {
            availableReward = balance;
        }
        require(
            availableReward > 0,
            "There is no available reward to withdraw"
        );
        workerWithdrawnReward = workerWithdrawnReward.add(availableReward);
        totalWithdrawnReward = totalWithdrawnReward.add(availableReward);

        token.safeTransfer(msg.sender, availableReward);
        emit TokensWithdrawn(msg.sender, availableReward, 0);
    }

    /**
     * @notice Withdraw reward to delegator
     * @param _value Amount of tokens to withdraw
     */
    function withdrawTokens(uint256 _value) public override {
        uint256 balance = token.balanceOf(address(this));
        require(_value <= balance, "Not enough tokens in the contract");

        Delegator storage delegator = delegators[msg.sender];
        uint256 availableReward = getAvailableDelegatorReward(msg.sender);

        require( _value <= availableReward, "Requested amount of tokens exceeded allowed portion");
        delegator.withdrawnReward = delegator.withdrawnReward.add(_value);
        totalWithdrawnReward = totalWithdrawnReward.add(_value);

        token.safeTransfer(msg.sender, _value);
        emit TokensWithdrawn(msg.sender, _value, delegator.depositedTokens);
    }

    /**
     * @notice Withdraw reward, deposit and fee to delegator
     */
    function withdrawAll() public {
        require(isWithdrawAllAllowed(), "Withdraw deposit and reward must be enabled");
        uint256 balance = token.balanceOf(address(this));

        Delegator storage delegator = delegators[msg.sender];
        uint256 availableReward = getAvailableDelegatorReward(msg.sender);
        uint256 value = availableReward.add(delegator.depositedTokens);
        require(value <= balance, "Not enough tokens in the contract");

        // TODO remove double reading: availableReward and availableWorkerReward use same calls to external contracts
        uint256 availableWorkerReward = getAvailableWorkerReward();

        // potentially could be less then due reward
        uint256 availableETH = getAvailableDelegatorETH(msg.sender);

        // prevent losing reward for worker after calculations
        uint256 workerReward = availableWorkerReward.mul(delegator.depositedTokens).div(totalDepositedTokens);
        if (workerReward > 0) {
            require(value.add(workerReward) <= balance, "Not enough tokens in the contract");
            token.safeTransfer(workerOwner, workerReward);
            emit TokensWithdrawn(workerOwner, workerReward, 0);
        }

        uint256 withdrawnToDecrease = workerWithdrawnReward.mul(delegator.depositedTokens).div(totalDepositedTokens);

        workerWithdrawnReward = workerWithdrawnReward.sub(withdrawnToDecrease);
        totalWithdrawnReward = totalWithdrawnReward.sub(withdrawnToDecrease).sub(delegator.withdrawnReward);
        totalDepositedTokens = totalDepositedTokens.sub(delegator.depositedTokens);

        delegator.withdrawnReward = 0;
        delegator.depositedTokens = 0;

        token.safeTransfer(msg.sender, value);
        emit TokensWithdrawn(msg.sender, value, 0);

        totalWithdrawnETH = totalWithdrawnETH.sub(delegator.withdrawnETH);
        delegator.withdrawnETH = 0;
        if (availableETH > 0) {
            emit ETHWithdrawn(msg.sender, availableETH);
            msg.sender.sendValue(availableETH);
        }
    }

    /**
     * @notice Get available ether for delegator
     */
    function getAvailableDelegatorETH(address _delegator) public view returns (uint256) {
        Delegator storage delegator = delegators[_delegator];
        uint256 balance = address(this).balance;
        // ETH balance + already withdrawn
        balance = balance.add(totalWithdrawnETH);
        uint256 maxAllowableETH = balance.mul(delegator.depositedTokens).div(totalDepositedTokens);

        uint256 availableETH = maxAllowableETH.sub(delegator.withdrawnETH);
        if (availableETH > balance) {
            availableETH = balance;
        }
        return availableETH;
    }

    /**
     * @notice Withdraw available amount of ETH to delegator
     */
    function withdrawETH() public override {
        Delegator storage delegator = delegators[msg.sender];
        uint256 availableETH = getAvailableDelegatorETH(msg.sender);
        require(availableETH > 0, "There is no available ETH to withdraw");
        delegator.withdrawnETH = delegator.withdrawnETH.add(availableETH);

        totalWithdrawnETH = totalWithdrawnETH.add(availableETH);
        emit ETHWithdrawn(msg.sender, availableETH);
        msg.sender.sendValue(availableETH);
    }

    /**
     * @notice Calling fallback function is allowed only for the owner
     */
    function isFallbackAllowed() public override view returns (bool) {
        return msg.sender == owner();
    }
}