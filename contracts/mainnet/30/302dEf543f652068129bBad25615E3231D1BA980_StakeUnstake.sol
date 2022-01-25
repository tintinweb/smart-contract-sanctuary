/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "StakingStateV2.sol";
import "StakingPausableGuardian.sol";
import "IMasterChefSushi.sol";
import "VoteDelegator.sol";
import "IVestingToken.sol";
import "Common.sol";

contract StakeUnstake is Common {
    function initialize(address target) external onlyOwner {
        _setTarget(this.totalSupplyByAsset.selector, target);
        _setTarget(this.stake.selector, target);
        _setTarget(this.unstake.selector, target);
        _setTarget(this.claim.selector, target);
        _setTarget(this.claimAltRewards.selector, target);
        _setTarget(this.claimBzrx.selector, target);
        _setTarget(this.claim3Crv.selector, target);
        _setTarget(this.claimSushi.selector, target);
        _setTarget(this.earned.selector, target);
        _setTarget(this.addAltRewards.selector, target);
        _setTarget(this.balanceOfByAsset.selector, target);
        _setTarget(this.balanceOfByAssets.selector, target);
        _setTarget(this.balanceOfStored.selector, target);
        _setTarget(this.vestedBalanceForAmount.selector, target);
        _setTarget(this.exit.selector, target);
    }


    function totalSupplyByAsset(
        address token)
    external
    view
    returns (uint256)
    {
        return _totalSupplyPerToken[token];
    }

    function _pendingSushiRewards(address _user) internal view returns (uint256) {
        uint256 pendingSushi = IMasterChefSushi(SUSHI_MASTERCHEF).pendingSushi(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this));

        uint256 totalSupply = _totalSupplyPerToken[OOKI_ETH_LP];
        return _pendingAltRewards(SUSHI, _user, balanceOfByAsset(OOKI_ETH_LP, _user), totalSupply != 0 ? pendingSushi.mul(1e12).div(totalSupply) : 0);
    }


    function _pendingAltRewards(
        address token,
        address _user,
        uint256 userSupply,
        uint256 extraRewardsPerShare
    ) internal view returns (uint256) {
        uint256 _altRewardsPerShare = altRewardsPerShare[token].add(extraRewardsPerShare);
        if (_altRewardsPerShare == 0) return 0;

        IStakingV2.AltRewardsUserInfo memory altRewardsUserInfo = userAltRewardsPerShare[_user][token];
        return altRewardsUserInfo.pendingRewards.add((_altRewardsPerShare.sub(altRewardsUserInfo.rewardsPerShare)).mul(userSupply).div(1e12));
    }

    function _depositToSushiMasterchef(uint256 amount) internal {
        uint256 sushiBalanceBefore = IERC20(SUSHI).balanceOf(address(this));
        IMasterChefSushi(SUSHI_MASTERCHEF).deposit(OOKI_ETH_SUSHI_MASTERCHEF_PID, amount);
        uint256 sushiRewards = IERC20(SUSHI).balanceOf(address(this)) - sushiBalanceBefore;
        if (sushiRewards != 0) {
            _addAltRewards(SUSHI, sushiRewards);
        }
    }

    function _withdrawFromSushiMasterchef(uint256 amount) internal {
        uint256 sushiBalanceBefore = IERC20(SUSHI).balanceOf(address(this));
        IMasterChefSushi(SUSHI_MASTERCHEF).withdraw(OOKI_ETH_SUSHI_MASTERCHEF_PID, amount);
        uint256 sushiRewards = IERC20(SUSHI).balanceOf(address(this)) - sushiBalanceBefore;
        if (sushiRewards != 0) {
            _addAltRewards(SUSHI, sushiRewards);
        }
    }

    function stake(address[] memory tokens, uint256[] memory values) public pausable updateRewards(msg.sender) {
        require(tokens.length == values.length, "count mismatch");
        VoteDelegator _voteDelegator = VoteDelegator(voteDelegator);
        address currentDelegate = _voteDelegator.delegates(msg.sender);

        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token == OOKI || token == vBZRX || token == iOOKI || token == OOKI_ETH_LP, "invalid token");

            uint256 stakeAmount = values[i];
            if (stakeAmount == 0) {
                continue;
            }
            uint256 pendingBefore = (token == OOKI_ETH_LP) ? _pendingSushiRewards(msg.sender) : 0;
            _balancesPerToken[token][msg.sender] = _balancesPerToken[token][msg.sender].add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(stakeAmount);

            IERC20(token).safeTransferFrom(msg.sender, address(this), stakeAmount);
            // Deposit to sushi masterchef
            if (token == OOKI_ETH_LP) {
                _depositToSushiMasterchef(IERC20(OOKI_ETH_LP).balanceOf(address(this)));

                userAltRewardsPerShare[msg.sender][SUSHI] = IStakingV2.AltRewardsUserInfo({rewardsPerShare: altRewardsPerShare[SUSHI], pendingRewards: pendingBefore});
            }

            emit Stake(msg.sender, token, currentDelegate, stakeAmount);
        }

        _voteDelegator.moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function unstake(address[] memory tokens, uint256[] memory values) public pausable updateRewards(msg.sender) {
        require(tokens.length == values.length, "count mismatch");

        VoteDelegator _voteDelegator = VoteDelegator(voteDelegator);
        address currentDelegate = _voteDelegator.delegates(msg.sender);

        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token == OOKI || token == vBZRX || token == iOOKI || token == OOKI_ETH_LP, "invalid token");

            uint256 unstakeAmount = values[i];
            uint256 stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            // Withdraw from sushi masterchef
            if (token == OOKI_ETH_LP) {
                _withdrawFromSushiMasterchef(unstakeAmount);
                userAltRewardsPerShare[msg.sender][SUSHI] = IStakingV2.AltRewardsUserInfo({rewardsPerShare: altRewardsPerShare[SUSHI], pendingRewards: _pendingSushiRewards(msg.sender)});
            }

            _balancesPerToken[token][msg.sender] = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] - unstakeAmount; // will not overflow

            if (token == OOKI && IERC20(OOKI).balanceOf(address(this)) < unstakeAmount) {
                // settle vested BZRX only if needed
                IVestingToken(vBZRX).claim();
                CONVERTER.convert(address(this), IERC20(BZRX).balanceOf(address(this)));
            }

            IERC20(token).safeTransfer(msg.sender, unstakeAmount);
            emit Unstake(msg.sender, token, currentDelegate, unstakeAmount);
        }
        _voteDelegator.moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function claim(bool restake) external pausable updateRewards(msg.sender) returns (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned) {
        return _claim(restake);
    }

    function claimAltRewards() external pausable returns (uint256 sushiRewardsEarned, uint256 crvRewardsEarned) {
        sushiRewardsEarned = _claimSushi();

        if (sushiRewardsEarned != 0) {
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function claimBzrx() external pausable updateRewards(msg.sender) returns (uint256 ookiRewardsEarned) {
        ookiRewardsEarned = _claimBzrx(false);

        emit Claim(msg.sender, ookiRewardsEarned, 0);
    }

    function claim3Crv() external pausable updateRewards(msg.sender) returns (uint256 stableCoinRewardsEarned) {
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(msg.sender, 0, stableCoinRewardsEarned);
    }

    function claimSushi() external pausable returns (uint256 sushiRewardsEarned) {
        sushiRewardsEarned = _claimSushi();
        if (sushiRewardsEarned != 0) {
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function _claim(bool restake) internal returns (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned) {
        ookiRewardsEarned = _claimBzrx(restake);
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(msg.sender, ookiRewardsEarned, stableCoinRewardsEarned);
    }

    function _claimBzrx(bool restake) internal returns (uint256 ookiRewardsEarned) {
        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);

        ookiRewardsEarned = ookiRewards[msg.sender];
        if (ookiRewardsEarned != 0) {
            ookiRewards[msg.sender] = 0;
            if (restake) {
                _restakeBZRX(msg.sender, ookiRewardsEarned);
            } else {
                if (IERC20(OOKI).balanceOf(address(this)) < ookiRewardsEarned) {
                    // settle vested BZRX only if needed
                    IVestingToken(vBZRX).claim();
                    CONVERTER.convert(address(this), IERC20(BZRX).balanceOf(address(this)));
                }

                IERC20(OOKI).transfer(msg.sender, ookiRewardsEarned);
            }
        }
        VoteDelegator(voteDelegator).moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function _claim3Crv() internal returns (uint256 stableCoinRewardsEarned) {
        stableCoinRewardsEarned = stableCoinRewards[msg.sender];
        if (stableCoinRewardsEarned != 0) {
            uint256 curve3CrvBalance = curve3Crv.balanceOf(address(this));
            stableCoinRewards[msg.sender] = 0;
            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }
    }

    function _claimSushi() internal returns (uint256) {
        address _user = msg.sender;
        uint256 lptUserSupply = balanceOfByAsset(OOKI_ETH_LP, _user);

        //This will trigger claim rewards from sushi masterchef
        _depositToSushiMasterchef(IERC20(OOKI_ETH_LP).balanceOf(address(this)));

        uint256 pendingSushi = _pendingAltRewards(SUSHI, _user, lptUserSupply, 0);

        userAltRewardsPerShare[_user][SUSHI] = IStakingV2.AltRewardsUserInfo({rewardsPerShare: altRewardsPerShare[SUSHI], pendingRewards: 0});
        if (pendingSushi != 0) {
            IERC20(SUSHI).safeTransfer(_user, pendingSushi);
        }

        return pendingSushi;
    }

    function _restakeBZRX(address account, uint256 amount) internal {
        _balancesPerToken[OOKI][account] = _balancesPerToken[OOKI][account].add(amount);

        _totalSupplyPerToken[OOKI] = _totalSupplyPerToken[OOKI].add(amount);

        emit Stake(
            account,
            OOKI,
            account, //currentDelegate,
            amount
        );
    }

    modifier updateRewards(address account) {
        uint256 _ookiPerTokenStored = ookiPerTokenStored;
        uint256 _stableCoinPerTokenStored = stableCoinPerTokenStored;

        (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned, uint256 ookiRewardsVesting, uint256 stableCoinRewardsVesting) = _earned(
            account,
            _ookiPerTokenStored,
            _stableCoinPerTokenStored
        );
        ookiRewardsPerTokenPaid[account] = _ookiPerTokenStored;
        stableCoinRewardsPerTokenPaid[account] = _stableCoinPerTokenStored;

        // vesting amounts get updated before sync
        bzrxVesting[account] = ookiRewardsVesting;
        stableCoinVesting[account] = stableCoinRewardsVesting;

        (ookiRewards[account], stableCoinRewards[account]) = _syncVesting(account, ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting);

        vestingLastSync[account] = block.timestamp;

        _;
    }

    function earned(address account)
        external
         
        returns (
            uint256 ookiRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 ookiRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        )
    {
        (ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting) = _earned(account, ookiPerTokenStored, stableCoinPerTokenStored);

        (ookiRewardsEarned, stableCoinRewardsEarned) = _syncVesting(account, ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting);

        // discount vesting amounts for vesting time
        uint256 multiplier = vestedBalanceForAmount(1e36, 0, block.timestamp);
        ookiRewardsVesting = ookiRewardsVesting.sub(ookiRewardsVesting.mul(multiplier).div(1e36));
        stableCoinRewardsVesting = stableCoinRewardsVesting.sub(stableCoinRewardsVesting.mul(multiplier).div(1e36));

        uint256 pendingSushi = IMasterChefSushi(SUSHI_MASTERCHEF).pendingSushi(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this));

        sushiRewardsEarned = _pendingAltRewards(
            SUSHI,
            account,
            balanceOfByAsset(OOKI_ETH_LP, account),
            (_totalSupplyPerToken[OOKI_ETH_LP] != 0) ? pendingSushi.mul(1e12).div(_totalSupplyPerToken[OOKI_ETH_LP]) : 0
        );
    }

    function _earned(
        address account,
        uint256 _ookiPerToken,
        uint256 _stableCoinPerToken
    )
        internal
        
        returns (
            uint256 ookiRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 ookiRewardsVesting,
            uint256 stableCoinRewardsVesting
        )
    {
        uint256 ookiPerTokenUnpaid = _ookiPerToken.sub(ookiRewardsPerTokenPaid[account]);
        uint256 stableCoinPerTokenUnpaid = _stableCoinPerToken.sub(stableCoinRewardsPerTokenPaid[account]);

        ookiRewardsEarned = ookiRewards[account];
        stableCoinRewardsEarned = stableCoinRewards[account];
        ookiRewardsVesting = bzrxVesting[account];
        stableCoinRewardsVesting = stableCoinVesting[account];

        if (ookiPerTokenUnpaid != 0 || stableCoinPerTokenUnpaid != 0) {
            uint256 value;
            uint256 multiplier;
            uint256 lastSync;

            (uint256 vestedBalance, uint256 vestingBalance) = balanceOfStored(account);
            value = vestedBalance.mul(ookiPerTokenUnpaid);
            value /= 1e36;
            ookiRewardsEarned = value.add(ookiRewardsEarned);
            value = vestedBalance.mul(stableCoinPerTokenUnpaid);
            value /= 1e36;
            stableCoinRewardsEarned = value.add(stableCoinRewardsEarned);

            if (vestingBalance != 0 && ookiPerTokenUnpaid != 0) {
                // add new vesting amount for BZRX
                value = vestingBalance.mul(ookiPerTokenUnpaid);
                value /= 1e36;
                ookiRewardsVesting = ookiRewardsVesting.add(value);
                // true up earned amount to vBZRX vesting schedule
                lastSync = vestingLastSync[account];
                multiplier = vestedBalanceForAmount(1e36, 0, lastSync);
                value = value.mul(multiplier);
                value /= 1e36;
                ookiRewardsEarned = ookiRewardsEarned.add(value);
            }
            if (vestingBalance != 0 && stableCoinPerTokenUnpaid != 0) {
                
                // add new vesting amount for 3crv
                value = vestingBalance.mul(stableCoinPerTokenUnpaid);
                value /= 1e36;
                stableCoinRewardsVesting = stableCoinRewardsVesting.add(value);

                // true up earned amount to vBZRX vesting schedule
                if (lastSync == 0) {
                    lastSync = vestingLastSync[account];
                    multiplier = vestedBalanceForAmount(1e36, 0, lastSync);
                }
                value = value.mul(multiplier);
                value /= 1e36;
                stableCoinRewardsEarned = stableCoinRewardsEarned.add(value);
            }
        }
    }

    function _syncVesting(
        address account,
        uint256 ookiRewardsEarned,
        uint256 stableCoinRewardsEarned,
        uint256 ookiRewardsVesting,
        uint256 stableCoinRewardsVesting
    ) internal view returns (uint256, uint256) {
        uint256 lastVestingSync = vestingLastSync[account];

        if (lastVestingSync != block.timestamp) {
            uint256 rewardsVested;
            uint256 multiplier = vestedBalanceForAmount(1e36, lastVestingSync, block.timestamp);

            if (ookiRewardsVesting != 0) {
                rewardsVested = ookiRewardsVesting.mul(multiplier).div(1e36);
                ookiRewardsEarned += rewardsVested;
            }

            if (stableCoinRewardsVesting != 0) {
                rewardsVested = stableCoinRewardsVesting.mul(multiplier).div(1e36);
                stableCoinRewardsEarned += rewardsVested;
            }

            // OOKI is 10x BZRX
            uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
            if (vBZRXBalance != 0) {
                // add vested OOKI to rewards balance
                rewardsVested = vBZRXBalance.mul(multiplier)
                    .div(1e35);  // OOKI is 10x BZRX
                ookiRewardsEarned += rewardsVested;
            }
        }

        return (ookiRewardsEarned, stableCoinRewardsEarned);
    }

    function addAltRewards(address token, uint256 amount) public {
        if (amount != 0) {
            _addAltRewards(token, amount);
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
    }

    function _addAltRewards(address token, uint256 amount) internal {
        address poolAddress = token == SUSHI ? OOKI_ETH_LP : token;

        uint256 totalSupply = _totalSupplyPerToken[poolAddress];
        require(totalSupply != 0, "no deposits");

        altRewardsPerShare[token] = altRewardsPerShare[token].add(amount.mul(1e12).div(totalSupply));

        emit AddAltRewards(msg.sender, token, amount);
    }

    function balanceOfByAsset(address token, address account) public view returns (uint256 balance) {
        balance = _balancesPerToken[token][account];
    }

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 ookiBalance,
            uint256 iBZRXBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        )
    {
        return (balanceOfByAsset(OOKI, account), balanceOfByAsset(iOOKI, account), balanceOfByAsset(vBZRX, account), balanceOfByAsset(OOKI_ETH_LP, account));
    }

    function balanceOfStored(address account) public view returns (uint256 vestedBalance, uint256 vestingBalance) {
        uint256 balance = _balancesPerToken[vBZRX][account];
        if (balance != 0) {
            vestingBalance = balance.mul(vBZRXWeightStored)
                .div(1e17); // OOKI is 10x BZRX
        }

        vestedBalance = _balancesPerToken[OOKI][account];

        balance = _balancesPerToken[iOOKI][account];
        if (balance != 0) {
            vestedBalance = balance.mul(iOOKIWeightStored).div(1e50).add(vestedBalance);
        }

        balance = _balancesPerToken[OOKI_ETH_LP][account];
        if (balance != 0) {
            vestedBalance = balance.mul(LPTokenWeightStored).div(1e18).add(vestedBalance);
        }
    }


    function exit()
        public
        // unstake() does check pausable
    {
        address[] memory tokens = new address[](4);
        uint256[] memory values = new uint256[](4);
        tokens[0] = iOOKI;
        tokens[1] = OOKI_ETH_LP;
        tokens[2] = vBZRX;
        tokens[3] = OOKI;
        values[0] = uint256(-1);
        values[1] = uint256(-1);
        values[2] = uint256(-1);
        values[3] = uint256(-1);
        
        unstake(tokens, values); // calls updateRewards
        _claim(false);
    }

    
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "SafeMath.sol";
import "SafeERC20.sol";
import "EnumerableBytes32Set.sol";
import "IStakingV2.sol";
import "Ownable.sol";
import "StakingConstantsV2.sol";

contract StakingStateV2 is StakingConstantsV2, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    mapping(bytes4 => address) public logicTargets;
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;

    mapping(address => uint256) public _totalSupplyPerToken; // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken; // token => account => value

    uint256 public ookiPerTokenStored;
    mapping(address => uint256) public ookiRewardsPerTokenPaid; // user => value
    mapping(address => uint256) public ookiRewards; // user => value
    mapping(address => uint256) public bzrxVesting; // user => value

    uint256 public stableCoinPerTokenStored;
    mapping(address => uint256) public stableCoinRewardsPerTokenPaid; // user => value
    mapping(address => uint256) public stableCoinRewards; // user => value
    mapping(address => uint256) public stableCoinVesting; // user => value

    uint256 public vBZRXWeightStored;
    uint256 public iOOKIWeightStored;
    uint256 public LPTokenWeightStored;

    uint256 public lastRewardsAddTime;
    mapping(address => uint256) public vestingLastSync;

    struct ProposalState {
        uint256 proposalTime;
        uint256 iOOKIWeight;
        uint256 lpOOKIBalance;
        uint256 lpTotalSupply;
    }
    address public governor;
    mapping(uint256 => ProposalState) internal _proposalState;

    mapping(address => uint256[]) public altRewardsRounds; // depreciated
    mapping(address => uint256) public altRewardsPerShare; // token => value

    // Token => (User => Info)
    mapping(address => mapping(address => IStakingV2.AltRewardsUserInfo)) public userAltRewardsPerShare;

    address public voteDelegator;

    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes32Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            output[i-start] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function getAddress(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (address)
    {
        bytes32 value = set.values[index];
        address addrvalue;
        assembly {
            addrvalue := value
        }
        return addrvalue;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IStakingV2 {
    struct ProposalState {
        uint256 proposalTime;
        uint256 iOOKIWeight;
        uint256 lpOOKIBalance;
        uint256 lpTotalSupply;
    }

    struct AltRewardsUserInfo {
        uint256 rewardsPerShare;
        uint256 pendingRewards;
    }

    function getCurrentFeeTokens() external view returns (address[] memory);

    function maxUniswapDisagreement() external view returns (uint256);

    function fundsWallet() external view returns (address);

    function callerRewardDivisor() external view returns (uint256);

    function maxCurveDisagreement() external view returns (uint256);

    function rewardPercent() external view returns (uint256);

    function addRewards(uint256 newOOKI, uint256 newStableCoin) external;

    function stake(address[] calldata tokens, uint256[] calldata values) external;

    function unstake(address[] calldata tokens, uint256[] calldata values) external;

    function earned(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function pendingCrvRewards(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function getVariableWeights()
        external
        view
        returns (
            uint256 vBZRXWeight,
            uint256 iOOKIWeight,
            uint256 LPTokenWeight
        );

    function balanceOfByAsset(address token, address account) external view returns (uint256 balance);

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iOOKIBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        );

    function balanceOfStored(address account) external view returns (uint256 vestedBalance, uint256 vestingBalance);

    function totalSupplyStored() external view returns (uint256 supply);

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime
    ) external view returns (uint256 vested);

    function votingBalanceOf(address account, uint256 proposalId) external view returns (uint256 totalVotes);

    function votingBalanceOfNow(address account) external view returns (uint256 totalVotes);

    function votingFromStakedBalanceOf(address account) external view returns (uint256 totalVotes);

    function _setProposalVals(address account, uint256 proposalId) external returns (uint256);

    function exit() external;

    function addAltRewards(address token, uint256 amount) external;

    function governor() external view returns (address);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function claim(bool restake) external;

    function claimAltRewards() external;

    function _totalSupplyPerToken(address) external view returns(uint256);
    

    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    // Admin functions

    // Withdraw all from sushi masterchef
    function exitSushi() external;

    function setGovernor(address _governor) external;

    function setApprovals(
        address _token,
        address _spender,
        uint256 _value
    ) external;

    function setVoteDelegator(address stakingGovernance) external;

    function updateSettings(address settingsTarget, bytes calldata callData) external;

    function claimSushi() external returns (uint256 sushiRewardsEarned);

    function totalSupplyByAsset(address token)
        external
        view
        returns (uint256);
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "SafeERC20.sol";
import "IUniswapV2Router.sol";
import "ICurve3Pool.sol";
import "ICurveMinter.sol";
import "ICurve3PoolGauge.sol";
import "IBZx.sol";
import "IBZRXv2Converter.sol";

contract StakingConstantsV2 {
    address internal constant ZERO_ADDRESS = address(0);

    address public constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    address public constant vBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address public constant iOOKI = 0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da;
    address public constant OOKI_ETH_LP = 0xEaaddE1E14C587a7Fb4Ba78eA78109BB32975f1e; // sushiswap

    uint256 internal constant cliffDuration = 15768000; // 86400 * 365 * 0.5
    uint256 internal constant vestingDuration = 126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff = 110376000; // 86400 * 365 * 3.5
    uint256 internal constant vestingStartTimestamp = 1594648800; // start_time
    uint256 internal constant vestingCliffTimestamp = vestingStartTimestamp + cliffDuration;
    uint256 internal constant vestingEndTimestamp = vestingStartTimestamp + vestingDuration;

    // these are 10x original balances for BZRX because of OOKI split
    uint256 internal constant _startingVBZRXBalance = 8893899330e18;
    // uint256 public constant initialCirculatingSupply = 10300000000e18 - _startingVBZRXBalance;

    address internal constant SUSHI_MASTERCHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    uint256 internal constant OOKI_ETH_SUSHI_MASTERCHEF_PID = 335;
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    ICurve3Pool public constant curve3pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IERC20 public constant curve3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    ICurveMinter public constant curveMinter = ICurveMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    IBZRXv2Converter public constant CONVERTER = IBZRXv2Converter(0x6BE9B7406260B6B6db79a1D4997e7f8f5c9D7400);

    event Stake(address indexed user, address indexed token, address indexed delegate, uint256 amount);

    event Unstake(address indexed user, address indexed token, address indexed delegate, uint256 amount);

    event Claim(address indexed user, uint256 ookiAmount, uint256 stableCoinAmount);

    event AddAltRewards(address indexed sender, address indexed token, uint256 amount);

    event ClaimAltRewards(address indexed user, address indexed token, uint256 amount);

    event AddRewards(address indexed sender, uint256 ookiAmount, uint256 stableCoinAmount);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IUniswapV2Router {
    // 0x38ed1739
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline)
        external
        returns (uint256[] memory amounts);

    // 0x8803dbee
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline)
        external
        returns (uint256[] memory amounts);

    // 0x1f00ca74
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    // 0xd06ca61f
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;

interface ICurve3Pool {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount)
        external;

    function get_virtual_price()
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

//0xd061D61a4d941c39E5453435B6345Dc261C2fcE0 eth mainnet
interface ICurveMinter {

    function mint(
        address _addr
    )
    external;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

//0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A eth mainnet
interface ICurve3PoolGauge {
    function balanceOf(
        address _addr
    )
        external
        view
        returns (uint256);

    function working_balances(address)
        external view
        returns (uint256);

    function claimable_tokens(address)
        external
        returns (uint256);

    function deposit(
        uint256 _amount
    )
        external;

    function deposit(
        uint256 _amount,
        address _addr
    )
    external;

    function withdraw(
        uint256 _amount
    )
        external;

    function set_approve_deposit(
        address _addr,
        bool can_deposit
    )
        external;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

/// @title A proxy interface for The Protocol
/// @author bZeroX
/// @notice This is just an interface, not to be deployed itself.
/// @dev This interface is to be used for the protocol interactions.
interface IBZx {
    ////// Protocol //////

    /// @dev adds or replaces existing proxy module
    /// @param target target proxy module address
    function replaceContract(address target) external;

    /// @dev updates all proxy modules addreses and function signatures.
    /// sigsArr and targetsArr should be of equal length
    /// @param sigsArr array of function signatures
    /// @param targetsArr array of target proxy module addresses
    function setTargets(
        string[] calldata sigsArr,
        address[] calldata targetsArr
    ) external;

    /// @dev returns protocol module address given a function signature
    /// @return module address
    function getTarget(string calldata sig) external view returns (address);

    ////// Protocol Settings //////

    /// @dev sets price feed contract address. The contract on the addres should implement IPriceFeeds interface
    /// @param newContract module address for the IPriceFeeds implementation
    function setPriceFeedContract(address newContract) external;

    /// @dev sets swaps contract address. The contract on the addres should implement ISwapsImpl interface
    /// @param newContract module address for the ISwapsImpl implementation
    function setSwapsImplContract(address newContract) external;

    /// @dev sets loan pool with assets. Accepts two arrays of equal length
    /// @param pools array of address of pools
    /// @param assets array of addresses of assets
    function setLoanPool(address[] calldata pools, address[] calldata assets)
        external;

    /// @dev updates list of supported tokens, it can be use also to disable or enable particualr token
    /// @param addrs array of address of pools
    /// @param toggles array of addresses of assets
    /// @param withApprovals resets tokens to unlimited approval with the swaps integration (kyber, etc.)
    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles,
        bool withApprovals
    ) external;

    /// @dev sets lending fee with WEI_PERCENT_PRECISION
    /// @param newValue lending fee percent
    function setLendingFeePercent(uint256 newValue) external;

    /// @dev sets trading fee with WEI_PERCENT_PRECISION
    /// @param newValue trading fee percent
    function setTradingFeePercent(uint256 newValue) external;

    /// @dev sets borrowing fee with WEI_PERCENT_PRECISION
    /// @param newValue borrowing fee percent
    function setBorrowingFeePercent(uint256 newValue) external;

    /// @dev sets affiliate fee with WEI_PERCENT_PRECISION
    /// @param newValue affiliate fee percent
    function setAffiliateFeePercent(uint256 newValue) external;

    /// @dev sets liquidation inncetive percent per loan per token. This is the profit percent
    /// that liquidator gets in the process of liquidating.
    /// @param loanTokens array list of loan tokens
    /// @param collateralTokens array list of collateral tokens
    /// @param amounts array list of liquidation inncetive amount
    function setLiquidationIncentivePercent(
        address[] calldata loanTokens,
        address[] calldata collateralTokens,
        uint256[] calldata amounts
    ) external;

    /// @dev sets max swap rate slippage percent.
    /// @param newAmount max swap rate slippage percent.
    function setMaxDisagreement(uint256 newAmount) external;

    /// TODO
    function setSourceBufferPercent(uint256 newAmount) external;

    /// @dev sets maximum supported swap size in ETH
    /// @param newAmount max swap size in ETH.
    function setMaxSwapSize(uint256 newAmount) external;

    /// @dev sets fee controller address
    /// @param newController address of the new fees controller
    function setFeesController(address newController) external;

    /// @dev withdraws lending fees to receiver. Only can be called by feesController address
    /// @param tokens array of token addresses.
    /// @param receiver fees receiver address
    /// @return amounts array of amounts withdrawn
    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeClaimType feeType
    ) external returns (uint256[] memory amounts);

    /// @dev withdraw protocol token (BZRX) from vesting contract vBZRX
    /// @param receiver address of BZRX tokens claimed
    /// @param amount of BZRX token to be claimed. max is claimed if amount is greater than balance.
    /// @return rewardToken reward token address
    /// @return withdrawAmount amount
    function withdrawProtocolToken(address receiver, uint256 amount)
        external
        returns (address rewardToken, uint256 withdrawAmount);

    /// @dev depozit protocol token (BZRX)
    /// @param amount address of BZRX tokens to deposit
    function depositProtocolToken(uint256 amount) external;

    function grantRewards(address[] calldata users, uint256[] calldata amounts)
        external
        returns (uint256 totalAmount);

    // NOTE: this doesn't sanitize inputs -> inaccurate values may be returned if there are duplicates tokens input
    function queryFees(address[] calldata tokens, FeeClaimType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid);

    function priceFeeds() external view returns (address);

    function swapsImpl() external view returns (address);

    function logicTargets(bytes4) external view returns (address);

    function loans(bytes32) external view returns (Loan memory);

    function loanParams(bytes32) external view returns (LoanParams memory);

    // we don't use this yet
    // function lenderOrders(address, bytes32) external returns (Order memory);
    // function borrowerOrders(address, bytes32) external returns (Order memory);

    function delegatedManagers(bytes32, address) external view returns (bool);

    function lenderInterest(address, address)
        external
        view
        returns (LenderInterest memory);

    function loanInterest(bytes32) external view returns (LoanInterest memory);

    function feesController() external view returns (address);

    function lendingFeePercent() external view returns (uint256);

    function lendingFeeTokensHeld(address) external view returns (uint256);

    function lendingFeeTokensPaid(address) external view returns (uint256);

    function borrowingFeePercent() external view returns (uint256);

    function borrowingFeeTokensHeld(address) external view returns (uint256);

    function borrowingFeeTokensPaid(address) external view returns (uint256);

    function protocolTokenHeld() external view returns (uint256);

    function protocolTokenPaid() external view returns (uint256);

    function affiliateFeePercent() external view returns (uint256);

    function liquidationIncentivePercent(address, address)
        external
        view
        returns (uint256);

    function loanPoolToUnderlying(address) external view returns (address);

    function underlyingToLoanPool(address) external view returns (address);

    function supportedTokens(address) external view returns (bool);

    function maxDisagreement() external view returns (uint256);

    function sourceBufferPercent() external view returns (uint256);

    function maxSwapSize() external view returns (uint256);

    /// @dev get list of loan pools in the system. Ordering is not guaranteed
    /// @param start start index
    /// @param count number of pools to return
    /// @return loanPoolsList array of loan pools
    function getLoanPoolsList(uint256 start, uint256 count)
        external
        view
        returns (address[] memory loanPoolsList);

    /// @dev checks whether addreess is a loan pool address
    /// @return boolean
    function isLoanPool(address loanPool) external view returns (bool);

    ////// Loan Settings //////

    /// @dev creates new loan param settings
    /// @param loanParamsList array of LoanParams
    /// @return loanParamsIdList array of loan ids created
    function setupLoanParams(LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    /// @dev Deactivates LoanParams for future loans. Active loans using it are unaffected.
    /// @param loanParamsIdList array of loan ids
    function disableLoanParams(bytes32[] calldata loanParamsIdList) external;

    /// @dev gets array of LoanParams by given ids
    /// @param loanParamsIdList array of loan ids
    /// @return loanParamsList array of LoanParams
    function getLoanParams(bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList);

    /// @dev Enumerates LoanParams in the system by owner
    /// @param owner of the loan params
    /// @param start number of loans to return
    /// @param count total number of the items
    /// @return loanParamsList array of LoanParams
    function getLoanParamsList(
        address owner,
        uint256 start,
        uint256 count
    ) external view returns (bytes32[] memory loanParamsList);

    /// @dev returns total loan principal for token address
    /// @param lender address
    /// @param loanToken address
    /// @return total principal of the loan
    function getTotalPrincipal(address lender, address loanToken)
        external
        view
        returns (uint256);

    ////// Loan Openings //////

    /// @dev This is THE function that borrows or trades on the protocol
    /// @param loanParamsId id of the LoanParam created beforehand by setupLoanParams function
    /// @param loanId id of existing loan, if 0, start a new loan
    /// @param isTorqueLoan boolean whether it is toreque or non torque loan
    /// @param initialMargin in WEI_PERCENT_PRECISION
    /// @param sentAddresses array of size 4:
    ///         lender: must match loan if loanId provided
    ///         borrower: must match loan if loanId provided
    ///         receiver: receiver of funds (address(0) assumes borrower address)
    ///         manager: delegated manager of loan unless address(0)
    /// @param sentValues array of size 5:
    ///         newRate: new loan interest rate
    ///         newPrincipal: new loan size (borrowAmount + any borrowed interest)
    ///         torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
    ///         loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
    ///         collateralTokenReceived: total collateralToken deposit
    /// @param loanDataBytes required when sending ether
    /// @return principal of the loan and collateral amount
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId,
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
        uint256[5] calldata sentValues,
        bytes calldata loanDataBytes
    ) external payable returns (LoanOpenData memory);

    /// @dev sets/disables/enables the delegated manager for the loan
    /// @param loanId id of the loan
    /// @param delegated delegated manager address
    /// @param toggle boolean set enabled or disabled
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle
    ) external;

    /// @dev estimates margin exposure for simulated position
    /// @param loanToken address of the loan token
    /// @param collateralToken address of collateral token
    /// @param loanTokenSent amout of loan token sent
    /// @param collateralTokenSent amount of collateral token sent
    /// @param interestRate yearly interest rate
    /// @param newPrincipal principal amount of the loan
    /// @return estimated margin exposure amount
    function getEstimatedMarginExposure(
        address loanToken,
        address collateralToken,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        uint256 interestRate,
        uint256 newPrincipal
    ) external view returns (uint256);

    /// @dev calculates required collateral for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param newPrincipal principal amount of the loan
    /// @param marginAmount margin amount of the loan
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return collateralAmountRequired amount required
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 collateralAmountRequired);

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal
    ) external view returns (uint256 collateralAmountRequired);

    /// @dev calculates borrow amount for simulated position
    /// @param loanToken address of loan token
    /// @param collateralToken address of collateral token
    /// @param collateralTokenAmount amount of collateral token sent
    /// @param marginAmount margin amount
    /// @param isTorqueLoan boolean torque or non torque loan
    /// @return borrowAmount possible borrow amount
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan
    ) external view returns (uint256 borrowAmount);

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount
    ) external view returns (uint256 borrowAmount);

    ////// Loan Closings //////

    /// @dev liquidates unhealty loans
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount amount of the collateral token of the loan
    /// @return seizedAmount sezied amount in the collateral token
    /// @return seizedToken loan token address
    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev rollover loan
    /// @param loanId id of the loan
    /// @param loanDataBytes reserved for future use.
    function rollover(bytes32 loanId, bytes calldata loanDataBytes)
        external
        returns (address rebateToken, uint256 gasRebate);

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param depositAmount amount of loan token to deposit
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param swapAmount amount of loan token to swap
    /// @param returnTokenIsCollateral boolean whether to return tokens is collateral
    /// @param loanDataBytes reserved for future use
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Closings With Gas Token //////

    /// @dev liquidates unhealty loans by using Gas token
    /// @param loanId id of the loan
    /// @param receiver address receiving liquidated loan collateral
    /// @param gasTokenUser user address of the GAS token
    /// @param closeAmount amount to close denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return seizedAmount loan token withdraw amount
    /// @return seizedToken loan token address
    function liquidateWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 closeAmount // denominated in loanToken
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    /// @dev rollover loan
    /// @param loanId id of the loan
    /// @param gasTokenUser user address of the GAS token
    function rolloverWithGasToken(
        bytes32 loanId,
        address gasTokenUser,
        bytes calldata /*loanDataBytes*/
    ) external returns (address rebateToken, uint256 gasRebate);

    /// @dev close position with loan token deposit
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param depositAmount amount of loan token to deposit denominated in loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithDepositWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 depositAmount
    )
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    /// @dev close position with swap
    /// @param loanId id of the loan
    /// @param receiver collateral token reciever address
    /// @param gasTokenUser user address of the GAS token
    /// @param swapAmount amount of loan token to swap denominated in collateralToken
    /// @param returnTokenIsCollateral  true: withdraws collateralToken, false: withdraws loanToken
    /// @return loanCloseAmount loan close amount
    /// @return withdrawAmount loan token withdraw amount
    /// @return withdrawToken loan token address
    function closeWithSwapWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes calldata loanDataBytes
    )
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    ////// Loan Maintenance //////

    /// @dev deposit collateral to existing loan
    /// @param loanId existing loan id
    /// @param depositAmount amount to deposit which must match msg.value if ether is sent
    function depositCollateral(bytes32 loanId, uint256 depositAmount)
        external
        payable;

    /// @dev withdraw collateral from existing loan
    /// @param loanId existing lona id
    /// @param receiver address of withdrawn tokens
    /// @param withdrawAmount amount to withdraw
    /// @return actualWithdrawAmount actual amount withdrawn
    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount
    ) external returns (uint256 actualWithdrawAmount);

    /// @dev withdraw accrued interest rate for a loan given token address
    /// @param loanToken loan token address
    function withdrawAccruedInterest(address loanToken) external;

    /// @dev extends loan duration by depositing more collateral
    /// @param loanId id of the existing loan
    /// @param depositAmount amount to deposit
    /// @param useCollateral boolean whether to extend using collateral or deposit amount
    /// @return secondsExtended by that number of seconds loan duration was extended
    function extendLoanDuration(
        bytes32 loanId,
        uint256 depositAmount,
        bool useCollateral,
        bytes calldata // for future use /*loanDataBytes*/
    ) external payable returns (uint256 secondsExtended);

    /// @dev reduces loan duration by withdrawing collateral
    /// @param loanId id of the existing loan
    /// @param receiver address to receive tokens
    /// @param withdrawAmount amount to withdraw
    /// @return secondsReduced by that number of seconds loan duration was extended
    function reduceLoanDuration(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount
    ) external returns (uint256 secondsReduced);

    function setDepositAmount(
        bytes32 loanId,
        uint256 depositValueAsLoanToken,
        uint256 depositValueAsCollateralToken
    ) external;

    function claimRewards(address receiver)
        external
        returns (uint256 claimAmount);

    function transferLoan(bytes32 loanId, address newOwner) external;

    function rewardsBalanceOf(address user)
        external
        view
        returns (uint256 rewardsBalance);

    /// @dev Gets current lender interest data totals for all loans with a specific oracle and interest token
    /// @param lender The lender address
    /// @param loanToken The loan token address
    /// @return interestPaid The total amount of interest that has been paid to a lender so far
    /// @return interestPaidDate The date of the last interest pay out, or 0 if no interest has been withdrawn yet
    /// @return interestOwedPerDay The amount of interest the lender is earning per day
    /// @return interestUnPaid The total amount of interest the lender is owned and not yet withdrawn
    /// @return interestFeePercent The fee retained by the protocol before interest is paid to the lender
    /// @return principalTotal The total amount of outstading principal the lender has loaned
    function getLenderInterestData(address lender, address loanToken)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid,
            uint256 interestFeePercent,
            uint256 principalTotal
        );

    /// @dev Gets current interest data for a loan
    /// @param loanId A unique id representing the loan
    /// @return loanToken The loan token that interest is paid in
    /// @return interestOwedPerDay The amount of interest the borrower is paying per day
    /// @return interestDepositTotal The total amount of interest the borrower has deposited
    /// @return interestDepositRemaining The amount of deposited interest that is not yet owed to a lender
    function getLoanInterestData(bytes32 loanId)
        external
        view
        returns (
            address loanToken,
            uint256 interestOwedPerDay,
            uint256 interestDepositTotal,
            uint256 interestDepositRemaining
        );

    /// @dev gets list of loans of particular user address
    /// @param user address of the loans
    /// @param start of the index
    /// @param count number of loans to return
    /// @param loanType type of the loan: All(0), Margin(1), NonMargin(2)
    /// @param isLender whether to list lender loans or borrower loans
    /// @param unsafeOnly booleat if true return only unsafe loans that are open for liquidation
    /// @return loansData LoanReturnData array of loans
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        LoanType loanType,
        bool isLender,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    function getUserLoansCount(address user, bool isLender)
        external
        view
        returns (uint256);

    /// @dev gets existing loan
    /// @param loanId id of existing loan
    /// @return loanData array of loans
    function getLoan(bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData);

    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly
    ) external view returns (LoanReturnData[] memory loansData);

    /// @dev get current active loans in the system
    /// @param start of the index
    /// @param count number of loans to return
    /// @param unsafeOnly boolean if true return unsafe loan only (open for liquidation)
    /// @param isLiquidatable boolean if true return liquidatable loans only
    function getActiveLoansAdvanced(
        uint256 start,
        uint256 count,
        bool unsafeOnly,
        bool isLiquidatable
    ) external view returns (LoanReturnData[] memory loansData);

    function getActiveLoansCount() external view returns (uint256);

    ////// Swap External //////

    /// @dev swap thru external integration
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev swap thru external integration using GAS
    /// @param sourceToken source token address
    /// @param destToken destintaion token address
    /// @param receiver address to receive tokens
    /// @param returnToSender TODO
    /// @param gasTokenUser user address of the GAS token
    /// @param sourceTokenAmount source token amount
    /// @param requiredDestTokenAmount destination token amount
    /// @param swapData TODO
    /// @return destTokenAmountReceived destination token received
    /// @return sourceTokenAmountUsed source token amount used
    function swapExternalWithGasToken(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        address gasTokenUser,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData
    )
        external
        payable
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    /// @dev calculate simulated return of swap
    /// @param sourceToken source token address
    /// @param destToken destination token address
    /// @param sourceTokenAmount source token amount
    /// @return amoun denominated in destination token
    function getSwapExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount
    ) external view returns (uint256);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;


    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    /// Loan Cleanup Interface

    function cleanupLoans(
        address loanToken,
        bytes32[] calldata loanIds)
        external
        payable
        returns (uint256 totalPrincipalIn);

    struct LoanParams {
        bytes32 id;
        bool active;
        address owner;
        address loanToken;
        address collateralToken;
        uint256 minInitialMargin;
        uint256 maintenanceMargin;
        uint256 maxLoanTerm;
    }

    struct LoanOpenData {
        bytes32 loanId;
        uint256 principal;
        uint256 collateral;
    }

    enum LoanType {
        All,
        Margin,
        NonMargin
    }

    struct LoanReturnData {
        bytes32 loanId;
        uint96 endTimestamp;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 startRate;
        uint256 startMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
    }

    enum FeeClaimType {
        All,
        Lending,
        Trading,
        Borrowing
    }

    struct Loan {
        bytes32 id; // id of the loan
        bytes32 loanParamsId; // the linked loan params id
        bytes32 pendingTradesId; // the linked pending trades id
        uint256 principal; // total borrowed amount outstanding
        uint256 collateral; // total collateral escrowed for the loan
        uint256 startTimestamp; // loan start time
        uint256 endTimestamp; // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin; // initial margin when the loan opened
        uint256 startRate; // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower; // borrower of this loan
        address lender; // lender of this loan
        bool active; // if false, the loan has been fully closed
    }

    struct LenderInterest {
        uint256 principalTotal; // total borrowed amount outstanding of asset
        uint256 owedPerDay; // interest owed per day for all loans of asset
        uint256 owedTotal; // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal; // total interest paid so far for asset
        uint256 updatedTimestamp; // last update
    }

    struct LoanInterest {
        uint256 owedPerDay; // interest owed per day for loan
        uint256 depositTotal; // total escrowed interest for loan
        uint256 updatedTimestamp; // last update
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IBZRXv2Converter {
    function convert(address receiver, uint256 _tokenAmount) external;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "StakingStateV2.sol";
import "PausableGuardian.sol";


contract StakingPausableGuardian is StakingStateV2, PausableGuardian {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this._isPaused.selector, target);
        _setTarget(this.toggleFunctionPause.selector, target);
        _setTarget(this.toggleFunctionUnPause.selector, target);
        _setTarget(this.changeGuardian.selector, target);
        _setTarget(this.getGuardian.selector, target);
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "Ownable.sol";


contract PausableGuardian is Ownable {

    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable {
        require(!_isPaused(msg.sig), "paused");
        _;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 1)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public {
        // only DAO can unpause, and adding guardian temporarily
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            sstore(slot, 0)
        }
    }

    function changeGuardian(address newGuardian) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        assembly {
            sstore(Pausable_GuardianAddress, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        assembly {
            guardian := sload(Pausable_GuardianAddress)
        }
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IMasterChefSushi {

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function deposit(uint256 _pid, uint256 _amount)
        external;

    function withdraw(uint256 _pid, uint256 _amount)
        external;

    // Info of each user that stakes LP tokens.
    function userInfo(uint256, address)
        external
        view
        returns (UserInfo memory);


    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        external;

    function updatePool(uint256 _pid)
        external;

    function owner()
        external
        view
        returns (address);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "SafeMath.sol";
import "SafeERC20.sol";
import "GovernorBravoDelegate.sol";
import "PausableGuardian.sol";
import "IStakingV2.sol";
import "VoteDelegatorState.sol";
import "VoteDelegatorConstants.sol";




contract VoteDelegator is VoteDelegatorState, VoteDelegatorConstants, PausableGuardian {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Getter
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) pausable external {
        if(delegatee == msg.sender){
            delegatee = ZERO_ADDRESS;
        }
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) pausable external {
        if(delegatee == msg.sender){
            delegatee = ZERO_ADDRESS;
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("STAKING")),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != ZERO_ADDRESS, "Staking::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Staking::delegateBySig: invalid nonce");
        require(now <= expiry, "Staking::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "Staking::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        if(delegatee == delegator || delegator == ZERO_ADDRESS)
            return;

        address oldDelegate = _delegates[delegator];

        uint256 delegatorBalance = staking.votingFromStakedBalanceOf(delegator);
        _delegates[delegator] = delegatee;

        //ZERO_ADDRESS means that user wants to revoke delegation
        if(delegatee == ZERO_ADDRESS && oldDelegate != ZERO_ADDRESS){
            if(totalDelegators[oldDelegate] > 0)
                totalDelegators[oldDelegate]--;

            if(totalDelegators[oldDelegate] == 0 && oldDelegate != ZERO_ADDRESS){
                uint32 dstRepNum = numCheckpoints[oldDelegate];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[oldDelegate][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = 0;
                _writeCheckpoint(oldDelegate, dstRepNum, dstRepOld, dstRepNew);
                return;
            }
        }
        else if(delegatee != ZERO_ADDRESS){
            totalDelegators[delegatee]++;
            if(totalDelegators[oldDelegate] > 0)
                totalDelegators[oldDelegate]--;
        }

        emit DelegateChanged(delegator, oldDelegate, delegatee);
        _moveDelegates(oldDelegate, delegatee, delegatorBalance);
    }

    function moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) public {
        require(msg.sender == address(staking), "unauthorized");
        _moveDelegates(srcRep, dstRep, amount);
    }

    function moveDelegatesByVotingBalance(
        uint256 votingBalanceBefore,
        uint256 votingBalanceAfter,
        address account
    )
    public
    {
        require(msg.sender == address(staking), "unauthorized");
        address currentDelegate = _delegates[account];
        if(currentDelegate == ZERO_ADDRESS)
            return;

        if(votingBalanceBefore > votingBalanceAfter){
            _moveDelegates(currentDelegate, ZERO_ADDRESS,
                votingBalanceBefore.sub(votingBalanceAfter)
            );
        }
        else{
            _moveDelegates(ZERO_ADDRESS, currentDelegate,
                votingBalanceAfter.sub(votingBalanceBefore)
            );
        }
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != ZERO_ADDRESS) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub((amount > srcRepOld)? srcRepOld : amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != ZERO_ADDRESS) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "Staking::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function setStaking(address _staking) public onlyOwner {
        staking = IStakingV2(_staking);
    }

}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "GovernorBravoInterfaces.sol";

contract GovernorBravoDelegate is GovernorBravoDelegateStorageV1, GovernorBravoEvents {

    /// @notice The name of this contract
    string public constant name = "Ooki Governor Bravo";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 0.5e18; // 0.5% of OOKI

    /// @notice The maximum setable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 2e18; // 2% of OOKI

    /// @notice The minimum setable voting period
    uint public constant MIN_VOTING_PERIOD = 5760; // About 24 hours

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

    /// @notice The min setable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The min setable quorum percentage
    uint public constant MIN_QUORUM_PERCENTAGE = 2e18; // 2% of total OOKI supply

    /// @notice The max setable quorum percentage
    uint public constant MAX_QUORUM_PERCENTAGE = 6e18; // 6% of total OOKI supply

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 100; // 100 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");


    /**
      * @notice Used to initialize the contract during delegator contructor
      * @param timelock_ The address of the Timelock
      * @param staking_ The address of the STAKING
      * @param votingPeriod_ The initial voting period
      * @param votingDelay_ The initial voting delay
      * @param proposalThresholdPercentage_ The initial proposal threshold percentage
      */
    function initialize(address timelock_, address staking_, uint votingPeriod_, uint votingDelay_, uint proposalThresholdPercentage_, uint quorumPercentage_) public {
        require(address(timelock) == address(0), "GovernorBravo::initialize: can only initialize once");
        require(msg.sender == admin, "GovernorBravo::initialize: admin only");
        require(timelock_ != address(0), "GovernorBravo::initialize: invalid timelock address");
        require(staking_ != address(0), "GovernorBravo::initialize: invalid STAKING address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "GovernorBravo::initialize: invalid voting period");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "GovernorBravo::initialize: invalid voting delay");
        require(proposalThresholdPercentage_ >= MIN_PROPOSAL_THRESHOLD && proposalThresholdPercentage_ <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::initialize: invalid proposal threshold");
        require(quorumPercentage_ >= MIN_QUORUM_PERCENTAGE && quorumPercentage_ <= MAX_QUORUM_PERCENTAGE, "GovernorBravo::initialize: invalid quorum percentage");

        timelock = TimelockInterface(timelock_);
        staking = StakingInterface(staking_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThresholdPercentage = proposalThresholdPercentage_;
        quorumPercentage = quorumPercentage_;

        guardian = msg.sender;
    }

    /**
      * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
      * @param targets Target addresses for proposal calls
      * @param values Eth values for proposal calls
      * @param signatures Function signatures for proposal calls
      * @param calldatas Calldatas for proposal calls
      * @param description String description of the proposal
      * @return Proposal id of new proposal
      */
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorBravo::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorBravo::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "GovernorBravo::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "GovernorBravo::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint proposalId = proposalCount + 1;
        require(staking._setProposalVals(msg.sender, proposalId) > proposalThreshold(), "GovernorBravo::propose: proposer votes below proposal threshold");
        proposalCount = proposalId;

        uint startBlock = add256(block.number, votingDelay);
        uint endBlock = add256(startBlock, votingPeriod);

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[proposalId] = newProposal;
        latestProposalIds[msg.sender] = proposalId;
        quorumVotesForProposal[proposalId] = quorumVotes();

        emit ProposalCreated(proposalId, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return proposalId;
    }

    /**
      * @notice Queues a proposal of state succeeded
      * @param proposalId The id of the proposal to queue
      */
    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorBravo::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorBravo::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
      * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
      * @param proposalId The id of the proposal to cancel
      */
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "GovernorBravo::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || staking.votingBalanceOfNow(proposal.proposer) < proposalThreshold() || msg.sender == guardian, "GovernorBravo::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
      * @notice Gets the current voting quroum
      * @return The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
      */
    function quorumVotes() public view returns (uint256) {
        uint256 totalSupply = IERC20(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B) // OOKI
            .totalSupply();
        return totalSupply * quorumPercentage / 1e20;
    }

    /**
      * @notice Gets the current proposal threshold
      * @return The number of votes required to create new proposal
      */
    function proposalThreshold() public view returns (uint256) {
        uint256 totalSupply = IERC20(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B) // OOKI
            .totalSupply();
        return totalSupply * proposalThresholdPercentage / 1e20;
    }

    /**
      * @notice Gets actions of a proposal
      * @param proposalId the id of the proposal
      * @return Targets, values, signatures, and calldatas of the proposal actions
      */
    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
      * @notice Gets the receipt for a voter on a given proposal
      * @param proposalId the id of proposal
      * @param voter The address of the voter
      * @return The voting receipt
      */
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
      * @notice Gets the state of a proposal
      * @param proposalId The id of the proposal
      * @return Proposal state
      */
    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > initialProposalId, "GovernorBravo::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotesForProposal[proposalId]) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      */
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }

    /**
      * @notice Cast a vote for a proposal with a reason
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @param reason The reason given for the vote by the voter
      */
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }

    /**
      * @notice Cast a vote for a proposal by signature
      * @dev External function that accepts EIP-712 signatures for voting on proposals.
      */
    function castVoteBySig(uint proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainIdInternal(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorBravo::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
    }


    /**
      * @dev Allows batching to castVote function
      */
    function castVotes(uint[] calldata proposalIds, uint8[] calldata supportVals) external {
        require(proposalIds.length == supportVals.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            emit VoteCast(msg.sender, proposalIds[i], supportVals[i], castVoteInternal(msg.sender, proposalIds[i], supportVals[i]), "");
        }
    }

    /**
      * @dev Allows batching to castVoteWithReason function
      */
    function castVotesWithReason(uint[] calldata proposalIds, uint8[] calldata supportVals, string[] calldata reasons) external {
        require(proposalIds.length == supportVals.length && proposalIds.length == reasons.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            emit VoteCast(msg.sender, proposalIds[i], supportVals[i], castVoteInternal(msg.sender, proposalIds[i], supportVals[i]), reasons[i]);
        }
    }

    /**
      * @dev Allows batching to castVoteBySig function
      */
    function castVotesBySig(uint[] calldata proposalIds, uint8[] calldata supportVals, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(proposalIds.length == supportVals.length && proposalIds.length == vs.length && proposalIds.length == rs.length && proposalIds.length == ss.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            castVoteBySig(proposalIds[i], supportVals[i], vs[i], rs[i], ss[i]);
        }
    }

    /**
      * @notice Internal function that caries out voting logic
      * @param voter The voter that is casting their vote
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @return The number of votes cast
      */
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint96) {
        require(state(proposalId) == ProposalState.Active, "GovernorBravo::castVoteInternal: voting is closed");
        require(support <= 2, "GovernorBravo::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorBravo::castVoteInternal: voter already voted");
        // 2**96-1 is greater than total supply of OOKI thus guaranteeing it won't ever overflow
        uint96 votes = uint96(staking.votingBalanceOf(voter, proposalId));

        if (support == 0) {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        } else if (support == 1) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else if (support == 2) {
            proposal.abstainVotes = add256(proposal.abstainVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
      * @notice Admin function for setting the voting delay
      * @param newVotingDelay new voting delay, in blocks
      */
    function __setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == admin, "GovernorBravo::__setVotingDelay: admin only");
        require(newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY, "GovernorBravo::__setVotingDelay: invalid voting delay");
        uint oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
      * @notice Admin function for setting the voting period
      * @param newVotingPeriod new voting period, in blocks
      */
    function __setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == admin, "GovernorBravo::__setVotingPeriod: admin only");
        require(newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD, "GovernorBravo::__setVotingPeriod: invalid voting period");
        uint oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
      * @notice Admin function for setting the quorum percentage
      * @param newQuorumPercentage new quorum percentage
      */
    function __setQuorumPercentage(uint newQuorumPercentage) external {
        require(msg.sender == admin, "GovernorBravo::__setQuorumPercentage: admin only");
        require(newQuorumPercentage >= MIN_QUORUM_PERCENTAGE && newQuorumPercentage <= MAX_QUORUM_PERCENTAGE, "GovernorBravo::__setQuorumPercentage: invalid quorum percentage");
        uint oldQuorumPercentage = quorumPercentage;
        quorumPercentage = newQuorumPercentage;

        emit QuorumPercentageSet(oldQuorumPercentage, newQuorumPercentage);
    }

    /**
      * @notice Admin function for setting the staking address
      * @param newStaking address of new staking
      */
    function __setStaking(address newStaking) external {
        require(msg.sender == admin, "GovernorBravo::__setStaking: admin only");
        require(newStaking != address(0) , "GovernorBravo::__setStaking: invalid address");
        address oldStaking = address(staking);
        staking = StakingInterface(newStaking);

        emit StakingAddressSet(oldStaking, newStaking);
    }

    /**
      * @notice Admin function for setting the proposal threshold
      * @dev newProposalThresholdPercentage must be greater than the hardcoded min
      * @param newProposalThresholdPercentage new proposal threshold
      */
    function __setProposalThresholdPercentage(uint newProposalThresholdPercentage) external {
        require(msg.sender == admin, "GovernorBravo::__setProposalThreshold: admin only");
        require(newProposalThresholdPercentage >= MIN_PROPOSAL_THRESHOLD && newProposalThresholdPercentage <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::__setProposalThreshold: invalid proposal threshold");
        uint oldProposalThresholdPercentage = proposalThresholdPercentage;
        proposalThresholdPercentage = newProposalThresholdPercentage;

        emit ProposalThresholdSet(oldProposalThresholdPercentage, proposalThresholdPercentage);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `__acceptLocalAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `__acceptLocalAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function __setPendingLocalAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "GovernorBravo:__setPendingLocalAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function __acceptLocalAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "GovernorBravo:__acceptLocalAdmin: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function __changeGuardian(address guardian_) public {
        require(msg.sender == guardian, "GovernorBravo::__changeGuardian: sender must be gov guardian");
        require(guardian_ != address(0), "GovernorBravo::__changeGuardian: not allowed");
        guardian = guardian_;
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorBravo::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorBravo::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorBravo::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorBravo::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainIdInternal() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


contract GovernorBravoEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint proposalId, uint8 support, uint votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint oldVotingDelay, uint newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint oldVotingPeriod, uint newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when quorum percentage is set
    event QuorumPercentageSet(uint oldQuorumPercentage, uint newQuorumPercentage);

    /// @notice Emitted when staking address is set
    event StakingAddressSet(address oldStaking, address newStaking);

    /// @notice Emitted when proposal threshold is set
    event ProposalThresholdSet(uint oldProposalThreshold, uint newProposalThreshold);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);
}

contract GovernorBravoDelegatorStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;

    /// @notice The address of the Governor Guardian
    address public guardian;
}


/**
 * @title Storage for Governor Bravo Delegate
 * @notice For future upgrades, do not change GovernorBravoDelegateStorageV1. Create a new
 * contract which implements GovernorBravoDelegateStorageV1 and following the naming convention
 * GovernorBravoDelegateStorageVX.
 */
contract GovernorBravoDelegateStorageV1 is GovernorBravoDelegatorStorage {

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice The number of votes as a percentage of total supply required in order for a voter to become a proposer
    uint public proposalThresholdPercentage;

    /// @notice Initial proposal id set at become
    uint public initialProposalId;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The address of the Ooki Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Ooki staking contract
    StakingInterface public staking;

    /// @notice The quorum as a percentage of total supply
    uint public quorumPercentage;


    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice proposalId => quorum votes required
    mapping (uint => uint) public quorumVotesForProposal;


    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Current number of votes for abstaining for this proposal
        uint abstainVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;

        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}


interface StakingInterface {
    function votingBalanceOf(
        address account,
        uint proposalCount)
        external
        view
        returns (uint totalVotes);

    function votingBalanceOfNow(
        address account)
        external
        view
        returns (uint totalVotes);

    function _setProposalVals(
        address account,
        uint proposalCount)
        external
        returns (uint);
}


interface GovernorAlpha {
    /// @notice The total number of proposals
    function proposalCount() external returns (uint);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "SafeMath.sol";
import "SafeERC20.sol";
import "VoteDelegationUpgradeable.sol";
import "EnumerableBytes32Set.sol";
import "IStakingV2.sol";


contract VoteDelegatorState is VoteDelegationUpgradeable {

    // A record of each accounts delegate
    // delegator => delegatee
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    mapping (address => uint256) public totalDelegators;

    IStakingV2 staking;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "Ownable.sol";


contract VoteDelegationUpgradeable is Ownable {
    address public implementation;
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

contract VoteDelegatorConstants {
    address internal constant ZERO_ADDRESS = address(0);

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "SafeERC20.sol";


contract IVestingToken is IERC20 {
    function claim()
        external;

    function vestedBalanceOf(
        address _owner)
        external
        view
        returns (uint256);

    function claimedBalanceOf(
        address _owner)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "StakingStateV2.sol";
import "PausableGuardian.sol";
import "MathUtil.sol";

contract Common is StakingStateV2, PausableGuardian {
    using MathUtil for uint256;

    function _getProposalState() internal view returns (ProposalState memory) {
        return
            ProposalState({
                proposalTime: block.timestamp - 1,
                iOOKIWeight: _calcIOOKIWeight(),
                lpOOKIBalance: 0, // IERC20(OOKI).balanceOf(LPToken),
                lpTotalSupply: 0 //IERC20(LPToken).totalSupply()
            });
    }

    function _calcIOOKIWeight() internal view returns (uint256) {
        uint256 total = IERC20(iOOKI).totalSupply();
        if(total != 0)
            return IERC20(OOKI).balanceOf(iOOKI).mul(1e50).div(total);
        return 0;
    }
 
    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime
    ) public view returns (uint256 vested) {
        vestingEndTime = vestingEndTime.min256(block.timestamp);
        if (vestingEndTime > lastUpdate) {
            if (vestingEndTime <= vestingCliffTimestamp || lastUpdate >= vestingEndTimestamp) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return 0;
            }
            if (lastUpdate < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastUpdate = vestingCliffTimestamp;
            }
            if (vestingEndTime > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                vestingEndTime = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = vestingEndTime.sub(lastUpdate);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }

    // Voting balance not including delegated votes
    function _votingFromStakedBalanceOf(
        address account,
        ProposalState memory proposal,
        bool skipVestingLastSyncCheck
    ) internal view returns (uint256 totalVotes) {
        uint256 _vestingLastSync = vestingLastSync[account];
        if (proposal.proposalTime == 0 || (!skipVestingLastSyncCheck && _vestingLastSync > proposal.proposalTime - 1)) {
            return 0;
        }

        uint256 _vOOKIBalance = _balancesPerToken[vBZRX][account] * 10; // 10x for OOKI
        if (_vOOKIBalance != 0) {
            if (vestingEndTimestamp > proposal.proposalTime && vestingCliffTimestamp < proposal.proposalTime) {
                // staked vBZRX is prorated based on total vested
                totalVotes = _vOOKIBalance * (vestingEndTimestamp - proposal.proposalTime) / vestingDurationAfterCliff;
            }

            // user is attributed a staked balance of vested OOKI, from their last update to the present (10x for OOKI)
            totalVotes = vestedBalanceForAmount(
                _vOOKIBalance,
                _vestingLastSync,
                proposal.proposalTime
            ).add(totalVotes);
        }

        totalVotes = _balancesPerToken[OOKI][account].add(ookiRewards[account]).add(totalVotes); // unclaimed BZRX rewards count as votes

        totalVotes = _balancesPerToken[iOOKI][account].mul(proposal.iOOKIWeight).div(1e50).add(totalVotes);

        // LPToken votes are measured based on amount of underlying BZRX staked
        /*totalVotes = proposal.lpBZRXBalance
            .mul(_balancesPerToken[LPToken][account])
            .div(proposal.lpTotalSupply)
            .add(totalVotes);*/
    }
}

/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.8.0;

library MathUtil {

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        return divCeil(a, b, "SafeMath: division by zero");
    }

    /**
    * @dev Integer division of two numbers, rounding up and truncating the quotient
    */
    function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);

        if (a == 0) {
            return 0;
        }
        uint256 c = ((a - 1) / b) + 1;

        return c;
    }

    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}