pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "./BaseToken.sol";

interface ICascadeV1 {
    function depositInfo(address user) external view
        returns (
            uint256 _lpTokensDeposited,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _mostRecentBASEWithdrawal,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds
        );
}

/**
 * @title CascadeV2 is a liquidity mining contract.
 */
contract CascadeV2 is OwnableUpgradeSafe {
    using SafeMath for uint256;

    mapping(address => uint256)   public userDepositsNumDeposits;
    mapping(address => uint256[]) public userDepositsNumLPTokens;
    mapping(address => uint256[]) public userDepositsDepositTimestamp;
    mapping(address => uint8[])   public userDepositsMultiplierLevel;
    mapping(address => uint256)   public userTotalLPTokensLevel1;
    mapping(address => uint256)   public userTotalLPTokensLevel2;
    mapping(address => uint256)   public userTotalLPTokensLevel3;
    mapping(address => uint256)   public userDepositSeconds;
    mapping(address => uint256)   public userLastAccountingUpdateTimestamp;

    uint256 public totalDepositedLevel1;
    uint256 public totalDepositedLevel2;
    uint256 public totalDepositedLevel3;
    uint256 public totalDepositSeconds;
    uint256 public lastAccountingUpdateTimestamp;

    uint256[] public rewardsNumShares;
    uint256[] public rewardsVestingStart;
    uint256[] public rewardsVestingDuration;
    uint256[] public rewardsSharesWithdrawn;

    IERC20 public lpToken;
    BaseToken public BASE;
    ICascadeV1 public cascadeV1;

    event Deposit(address indexed user, uint256 tokens, uint256 timestamp);
    event Withdraw(address indexed user, uint256 withdrawnLPTokens, uint256 withdrawnBASETokens, uint256 timestamp);
    event UpgradeMultiplierLevel(address indexed user, uint256 depositIndex, uint256 oldLevel, uint256 newLevel, uint256 timestamp);
    event Migrate(address indexed user, uint256 lpTokens, uint256 rewardTokens);
    event AddRewards(uint256 tokens, uint256 shares, uint256 vestingStart, uint256 vestingDuration, uint256 totalTranches);
    event SetBASEToken(address token);
    event SetLPToken(address token);
    event SetCascadeV1(address cascadeV1);
    event UpdateDepositSeconds(address user, uint256 totalDepositSeconds, uint256 userDepositSeconds);
    event AdminRescueTokens(address token, address recipient, uint256 amount);

    /**
     * @dev Called by the OpenZeppelin "upgrades" library to initialize the contract in lieu of a constructor.
     */
    function initialize() external initializer {
        __Ownable_init();

        // Copy over the rewards tranche from Cascade v1
        rewardsNumShares.push(0);
        rewardsVestingStart.push(1606763901);
        rewardsVestingDuration.push(7776000);
        rewardsSharesWithdrawn.push(0);
    }

    /**
     * Admin
     */

    /**
     * @notice Changes the address of the LP token for which staking is allowed.
     * @param _lpToken The address of the LP token.
     */
    function setLPToken(address _lpToken) external onlyOwner {
        require(_lpToken != address(0x0), "zero address");
        lpToken = IERC20(_lpToken);
        emit SetLPToken(_lpToken);
    }

    /**
     * @notice Changes the address of the BASE token.
     * @param _baseToken The address of the BASE token.
     */
    function setBASEToken(address _baseToken) external onlyOwner {
        require(_baseToken != address(0x0), "zero address");
        BASE = BaseToken(_baseToken);
        emit SetBASEToken(_baseToken);
    }

    /**
     * @notice Changes the address of Cascade v1 (for purposes of migration).
     * @param _cascadeV1 The address of Cascade v1.
     */
    function setCascadeV1(address _cascadeV1) external onlyOwner {
        require(address(_cascadeV1) != address(0x0), "zero address");
        cascadeV1 = ICascadeV1(_cascadeV1);
        emit SetCascadeV1(_cascadeV1);
    }

    /**
     * @notice Allows the admin to withdraw tokens mistakenly sent into the contract.
     * @param token The address of the token to rescue.
     * @param recipient The recipient that the tokens will be sent to.
     * @param amount How many tokens to rescue.
     */
    function adminRescueTokens(address token, address recipient, uint256 amount) external onlyOwner {
        require(token != address(0x0), "zero address");
        require(recipient != address(0x0), "bad recipient");
        require(amount > 0, "zero amount");

        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");

        emit AdminRescueTokens(token, recipient, amount);
    }

    /**
     * @notice Allows the owner to add another tranche of rewards.
     * @param numTokens How many tokens to add to the tranche.
     * @param vestingStart The timestamp upon which vesting of this tranche begins.
     * @param vestingDuration The duration over which the tokens fully unlock.
     */
    function addRewards(uint256 numTokens, uint256 vestingStart, uint256 vestingDuration) external onlyOwner {
        require(numTokens > 0, "zero amount");
        require(vestingStart > 0, "zero vesting start");

        uint256 numShares = tokensToShares(numTokens);
        rewardsNumShares.push(numShares);
        rewardsVestingStart.push(vestingStart);
        rewardsVestingDuration.push(vestingDuration);
        rewardsSharesWithdrawn.push(0);

        bool ok = BASE.transferFrom(msg.sender, address(this), numTokens);
        require(ok, "transfer");

        emit AddRewards(numTokens, numShares, vestingStart, vestingDuration, rewardsNumShares.length);
    }

    function setRewardsTrancheTiming(uint256 tranche, uint256 vestingStart, uint256 vestingDuration) external onlyOwner {
        rewardsVestingStart[tranche] = vestingStart;
        rewardsVestingDuration[tranche] = vestingDuration;
    }

    /**
     * Public methods
     */

    /**
     * @notice Allows a user to deposit LP tokens into the Cascade.
     * @param amount How many tokens to stake.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "zero amount");

        uint256 allowance = lpToken.allowance(msg.sender, address(this));
        require(amount <= allowance, "allowance");

        updateDepositSeconds(msg.sender);

        totalDepositedLevel1 = totalDepositedLevel1.add(amount);
        userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].add(1);
        userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].add(amount);
        userDepositsNumLPTokens[msg.sender].push(amount);
        userDepositsDepositTimestamp[msg.sender].push(now);
        userDepositsMultiplierLevel[msg.sender].push(1);

        bool ok = lpToken.transferFrom(msg.sender, address(this), amount);
        require(ok, "transferFrom");

        emit Deposit(msg.sender, amount, now);
    }

    /**
     * @notice Allows a user to withdraw LP tokens from the Cascade.
     * @param numLPTokens How many tokens to unstake.
     */
    function withdrawLPTokens(uint256 numLPTokens) external {
        require(numLPTokens > 0, "zero tokens");

        updateDepositSeconds(msg.sender);

        (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        ) = removeDepositSeconds(numLPTokens);

        uint256 totalRewardShares = unlockedRewardsPoolShares().mul(totalDepositSecondsToBurn).div(totalDepositSeconds);
        removeRewardShares(totalRewardShares);

        totalDepositedLevel1 = totalDepositedLevel1.sub(amountToWithdrawLevel1);
        totalDepositedLevel2 = totalDepositedLevel2.sub(amountToWithdrawLevel2);
        totalDepositedLevel3 = totalDepositedLevel3.sub(amountToWithdrawLevel3);

        userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].sub(totalDepositSecondsToBurn);
        totalDepositSeconds = totalDepositSeconds.sub(totalDepositSecondsToBurn);

        uint256 rewardTokens = sharesToTokens(totalRewardShares);

        bool ok = lpToken.transfer(msg.sender, totalAmountToWithdraw);
        require(ok, "transfer deposit");
        ok = BASE.transfer(msg.sender, rewardTokens);
        require(ok, "transfer rewards");

        emit Withdraw(msg.sender, totalAmountToWithdraw, rewardTokens, block.timestamp);
    }

    function removeDepositSeconds(uint256 numLPTokens) private
        returns (
            uint256 totalAmountToWithdraw,
            uint256 totalDepositSecondsToBurn,
            uint256 amountToWithdrawLevel1,
            uint256 amountToWithdrawLevel2,
            uint256 amountToWithdrawLevel3
        )
    {
        for (uint256 i = userDepositsNumLPTokens[msg.sender].length; i > 0; i--) {
            uint256 lpTokensToRemove;
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][i-1]);
            uint8   multiplier = userDepositsMultiplierLevel[msg.sender][i-1];

            if (totalAmountToWithdraw.add(userDepositsNumLPTokens[msg.sender][i-1]) <= numLPTokens) {
                lpTokensToRemove = userDepositsNumLPTokens[msg.sender][i-1];
                userDepositsNumDeposits[msg.sender] = userDepositsNumDeposits[msg.sender].sub(1);
                userDepositsNumLPTokens[msg.sender].pop();
                userDepositsDepositTimestamp[msg.sender].pop();
                userDepositsMultiplierLevel[msg.sender].pop();
            } else {
                lpTokensToRemove = numLPTokens.sub(totalAmountToWithdraw);
                userDepositsNumLPTokens[msg.sender][i-1] = userDepositsNumLPTokens[msg.sender][i-1].sub(lpTokensToRemove);
            }

            if (multiplier == 1) {
                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel1 = amountToWithdrawLevel1.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(age.mul(lpTokensToRemove));
            } else if (multiplier == 2) {
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel2 = amountToWithdrawLevel2.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + (age - 30 days).mul(2)));
            } else if (multiplier == 3) {
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].sub(lpTokensToRemove);
                amountToWithdrawLevel3 = amountToWithdrawLevel3.add(lpTokensToRemove);
                totalDepositSecondsToBurn = totalDepositSecondsToBurn.add(lpTokensToRemove.mul(30 days + uint256(30 days).mul(2) + (age - 60 days).mul(3)));
            }
            totalAmountToWithdraw = totalAmountToWithdraw.add(lpTokensToRemove);

            if (totalAmountToWithdraw >= numLPTokens) {
                break;
            }
        }
        return (
            totalAmountToWithdraw,
            totalDepositSecondsToBurn,
            amountToWithdrawLevel1,
            amountToWithdrawLevel2,
            amountToWithdrawLevel3
        );
    }

    function removeRewardShares(uint256 totalSharesToRemove) private {
        uint256 totalSharesRemovedSoFar;

        for (uint256 i = rewardsNumShares.length; i > 0; i--) {
            uint256 sharesAvailable = unlockedRewardSharesInTranche(i-1);
            if (sharesAvailable == 0) {
                continue;
            }

            uint256 sharesStillNeeded = totalSharesToRemove.sub(totalSharesRemovedSoFar);
            if (sharesAvailable > sharesStillNeeded) {
                rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesStillNeeded);
                return;
            }

            rewardsSharesWithdrawn[i-1] = rewardsSharesWithdrawn[i-1].add(sharesAvailable);
            totalSharesRemovedSoFar = totalSharesRemovedSoFar.add(sharesAvailable);
            if (rewardsNumShares[i-1].sub(rewardsSharesWithdrawn[i-1]) == 0) {
                rewardsNumShares.pop();
                rewardsVestingStart.pop();
                rewardsVestingDuration.pop();
                rewardsSharesWithdrawn.pop();
            }
        }
    }

    /**
     * @notice Allows a user to upgrade their deposit-seconds multipler for the given deposits.
     * @param deposits A list of the indices of deposits to be upgraded.
     */
    function upgradeMultiplierLevel(uint256[] memory deposits) external {
        require(deposits.length > 0, "no deposits");

        updateDepositSeconds(msg.sender);

        for (uint256 i = 0; i < deposits.length; i++) {
            uint256 idx = deposits[i];
            uint256 age = now.sub(userDepositsDepositTimestamp[msg.sender][idx]);

            if (age <= 30 days || userDepositsMultiplierLevel[msg.sender][idx] == 3) {
                continue;
            }

            uint8 oldLevel = userDepositsMultiplierLevel[msg.sender][idx];
            uint256 tokensDeposited = userDepositsNumLPTokens[msg.sender][idx];

            if (age > 30 days && userDepositsMultiplierLevel[msg.sender][idx] == 1) {
                uint256 secondsSinceLevel2 = age - 30 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel2);
                totalDepositedLevel1 = totalDepositedLevel1.sub(tokensDeposited);
                totalDepositedLevel2 = totalDepositedLevel2.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel1[msg.sender] = userTotalLPTokensLevel1[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 2;
            }

            if (age > 60 days && userDepositsMultiplierLevel[msg.sender][idx] == 2) {
                uint256 secondsSinceLevel3 = age - 60 days;
                uint256 extraDepositSeconds = tokensDeposited.mul(secondsSinceLevel3);
                totalDepositedLevel2 = totalDepositedLevel2.sub(tokensDeposited);
                totalDepositedLevel3 = totalDepositedLevel3.add(tokensDeposited);
                totalDepositSeconds  = totalDepositSeconds.add(extraDepositSeconds);

                userTotalLPTokensLevel2[msg.sender] = userTotalLPTokensLevel2[msg.sender].sub(tokensDeposited);
                userTotalLPTokensLevel3[msg.sender] = userTotalLPTokensLevel3[msg.sender].add(tokensDeposited);
                userDepositSeconds[msg.sender] = userDepositSeconds[msg.sender].add(extraDepositSeconds);
                userDepositsMultiplierLevel[msg.sender][idx] = 3;
            }
            emit UpgradeMultiplierLevel(msg.sender, idx, oldLevel, userDepositsMultiplierLevel[msg.sender][idx], block.timestamp);
        }
    }

    /**
     * @notice Called by Cascade v1 to migrate funds into Cascade v2.
     * @param user The user for whom to migrate funds.
     */
    function migrate(address user) external {
        require(msg.sender == address(cascadeV1), "only cascade v1");
        require(user != address(0x0), "zero address");

        (
            uint256 numLPTokens,
            uint256 depositTimestamp,
            uint8   multiplier,
            ,
            uint256 userDS,
            uint256 totalDS
        ) = cascadeV1.depositInfo(user);
        uint256 numRewardShares = BASE.sharesOf(address(cascadeV1)).mul(userDS).div(totalDS);

        require(numLPTokens > 0, "no stake");
        require(multiplier > 0, "zero multiplier");
        require(depositTimestamp > 0, "zero timestamp");
        require(userDS > 0, "zero seconds");

        updateDepositSeconds(user);

        userDepositsNumDeposits[user] = userDepositsNumDeposits[user].add(1);
        userDepositsNumLPTokens[user].push(numLPTokens);
        userDepositsMultiplierLevel[user].push(multiplier);
        userDepositsDepositTimestamp[user].push(depositTimestamp);
        userDepositSeconds[user] = userDS;
        userLastAccountingUpdateTimestamp[user] = now;
        totalDepositSeconds = totalDepositSeconds.add(userDS);

        rewardsNumShares[0] = rewardsNumShares[0].add(numRewardShares);

        if (multiplier == 1) {
            totalDepositedLevel1 = totalDepositedLevel1.add(numLPTokens);
            userTotalLPTokensLevel1[user] = userTotalLPTokensLevel1[user].add(numLPTokens);
        } else if (multiplier == 2) {
            totalDepositedLevel2 = totalDepositedLevel2.add(numLPTokens);
            userTotalLPTokensLevel2[user] = userTotalLPTokensLevel2[user].add(numLPTokens);
        } else if (multiplier == 3) {
            totalDepositedLevel3 = totalDepositedLevel3.add(numLPTokens);
            userTotalLPTokensLevel3[user] = userTotalLPTokensLevel3[user].add(numLPTokens);
        }

        emit Migrate(user, numLPTokens, sharesToTokens(numRewardShares));
    }

    /**
     * @notice Updates the global deposit-seconds accounting as well as that of the given user.
     * @param user The user for whom to update the accounting.
     */
    function updateDepositSeconds(address user) public {
        (totalDepositSeconds, userDepositSeconds[user]) = getUpdatedDepositSeconds(user);
        lastAccountingUpdateTimestamp = now;
        userLastAccountingUpdateTimestamp[user] = now;
        emit UpdateDepositSeconds(user, totalDepositSeconds, userDepositSeconds[user]);
    }

    /**
     * Getters
     */

    /**
     * @notice Returns the global deposit-seconds as well as that of the given user.
     * @param user The user for whom to fetch the current deposit-seconds.
     */
    function getUpdatedDepositSeconds(address user) public view returns (uint256 _totalDepositSeconds, uint256 _userDepositSeconds) {
        uint256 delta = now.sub(lastAccountingUpdateTimestamp);
        _totalDepositSeconds = totalDepositSeconds.add(delta.mul(totalDepositedLevel1
                                                                       .add( totalDepositedLevel2.mul(2) )
                                                                       .add( totalDepositedLevel3.mul(3) ) ));

        delta = now.sub(userLastAccountingUpdateTimestamp[user]);
        _userDepositSeconds  = userDepositSeconds[user].add(delta.mul(userTotalLPTokensLevel1[user]
                                                                       .add( userTotalLPTokensLevel2[user].mul(2) )
                                                                       .add( userTotalLPTokensLevel3[user].mul(3) ) ));
        return (_totalDepositSeconds, _userDepositSeconds);
    }

    /**
     * @notice Returns the BASE rewards owed to the given user.
     * @param user The user for whom to fetch the current rewards.
     */
    function owedTo(address user) public view returns (uint256) {
        require(user != address(0x0), "zero address");

        (uint256 totalDS, uint256 userDS) = getUpdatedDepositSeconds(user);
        if (totalDS == 0) {
            return 0;
        }
        return sharesToTokens(unlockedRewardsPoolShares().mul(userDS).div(totalDS));
    }

    /**
     * @notice Returns the total number of unlocked BASE in the rewards pool.
     */
    function unlockedRewardsPoolTokens() public view returns (uint256) {
        return sharesToTokens(unlockedRewardsPoolShares());
    }

    function unlockedRewardsPoolShares() private view returns (uint256) {
        uint256 totalShares;
        for (uint256 i = 0; i < rewardsNumShares.length; i++) {
            totalShares = totalShares.add(unlockedRewardSharesInTranche(i));
        }
        return totalShares;
    }

    function unlockedRewardSharesInTranche(uint256 rewardsIdx) private view returns (uint256) {
        if (rewardsVestingStart[rewardsIdx] >= now || rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]) == 0) {
            return 0;
        }
        uint256 secondsIntoVesting = now.sub(rewardsVestingStart[rewardsIdx]);
        if (secondsIntoVesting > rewardsVestingDuration[rewardsIdx]) {
            return rewardsNumShares[rewardsIdx].sub(rewardsSharesWithdrawn[rewardsIdx]);
        } else {
            return rewardsNumShares[rewardsIdx].mul( secondsIntoVesting )
                                               .div( rewardsVestingDuration[rewardsIdx] == 0 ? 1 : rewardsVestingDuration[rewardsIdx] )
                                               .sub( rewardsSharesWithdrawn[rewardsIdx] );
        }
    }

    function sharesToTokens(uint256 shares) private view returns (uint256) {
        return shares.mul(BASE.totalSupply()).div(BASE.totalShares());
    }

     function tokensToShares(uint256 tokens) private view returns (uint256) {
        return tokens.mul(BASE.totalShares().div(BASE.totalSupply()));
    }

    /**
     * @notice Returns various statistics about the given user and deposit.
     * @param user The user to fetch.
     * @param depositIdx The index of the given user's deposit to fetch.
     */
    function depositInfo(address user, uint256 depositIdx) public view
        returns (
            uint256 _numLPTokens,
            uint256 _depositTimestamp,
            uint8   _multiplierLevel,
            uint256 _userDepositSeconds,
            uint256 _totalDepositSeconds,
            uint256 _owed
        )
    {
        require(user != address(0x0), "zero address");

        (_totalDepositSeconds, _userDepositSeconds) = getUpdatedDepositSeconds(user);
        return (
            userDepositsNumLPTokens[user][depositIdx],
            userDepositsDepositTimestamp[user][depositIdx],
            userDepositsMultiplierLevel[user][depositIdx],
            _userDepositSeconds,
            _totalDepositSeconds,
            owedTo(user)
        );
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
import "../Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

import "./lib/SafeMathInt.sol";
import "./ERC20UpgradeSafe.sol";
import "./ERC677Token.sol";

interface ISync {
    function sync() external;
}

interface IGulp {
    function gulp(address token) external;
}

/**
 * @title BASE ERC20 token
 * @dev This is part of an implementation of the BASE Index Fund protocol.
 *      BASE is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      BASE balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'BASE'.
 */
contract BaseToken is ERC20UpgradeSafe, ERC677Token, OwnableUpgradeSafe {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of shares that equals 1 BASE.
    //    The inverse rate must not be used--totalShares is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert shares to BASE instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Share balances converted into BaseToken are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x BaseToken to address 'B'. A's resulting external balance will
    //   be decreased by precisely x BaseToken, and B's external balance will be precisely
    //   increased by x BaseToken.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogMonetaryPolicyUpdated(address monetaryPolicy);
    event AdminRescueTokens(address token, address recipient, uint256 amount);

    // Used for authentication
    address public monetaryPolicy;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_SUPPLY = 8795645 * 10**DECIMALS;
    uint256 private constant INITIAL_SHARES = (MAX_UINT256 / (10 ** 36)) - ((MAX_UINT256 / (10 ** 36)) % INITIAL_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalShares;
    uint256 private _totalSupply;
    uint256 private _sharesPerBASE;
    mapping(address => uint256) private _shareBalances;

    mapping(address => bool) public bannedUsers; // Deprecated

    // This is denominated in BaseToken, because the shares-BASE conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedBASE;

    bool private transfersPaused;
    bool public rebasesPaused;

    mapping(address => bool) private transferPauseExemptList;

    function setRebasesPaused(bool _rebasesPaused)
        public
        onlyOwner
    {
        rebasesPaused = _rebasesPaused;
    }

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_)
        external
        onlyOwner
    {
        monetaryPolicy = monetaryPolicy_;
        emit LogMonetaryPolicyUpdated(monetaryPolicy_);
    }

    /**
     * @notice Allows the admin to withdraw tokens mistakenly sent into the contract.
     * @param token The address of the token to rescue.
     * @param recipient The recipient that the tokens will be sent to.
     */
    function adminRescueTokens(address token, address recipient) external onlyOwner {
        require(token != address(0x0), "zero address");
        require(recipient != address(0x0), "bad recipient");

        uint256 amount = IERC20(token).balanceOf(address(this));
        bool ok = IERC20(token).transfer(recipient, amount);
        require(ok, "transfer");

        emit AdminRescueTokens(token, recipient, amount);
    }

    /**
     * @dev Notifies BaseToken contract about a new rebase cycle.
     * @param supplyDelta The number of new BASE tokens to add into circulation via expansion.
     * @return The total number of BASE after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        returns (uint256)
    {
        require(msg.sender == monetaryPolicy, "only monetary policy");
        require(!rebasesPaused, "rebases paused");

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _sharesPerBASE = _totalShares.div(_totalSupply);

        // From this point forward, _sharesPerBASE is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _sharesPerBASE
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(totalShares - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.

        emit LogRebase(epoch, _totalSupply);

        ISync(0xdE5b7Ff5b10CC5F8c95A2e2B643e3aBf5179C987).sync();              // Uniswap BASE/ETH
        ISync(0xD8B8B575c943f3d63638c9563B464D204ED8B710).sync();              // Sushiswap BASE/ETH
        IGulp(0x19B770c8F9d5439C419864d8458255791f7e736C).gulp(address(this)); // Value BASE/USDC #1
        ISync(0x90A6DBC347CA01b2077f6e6729Cd6e16c5E669Bc).sync();              // Value BASE/USDC #2

        return _totalSupply;
    }

    function totalShares()
        public
        view
        returns (uint256)
    {
        return _totalShares;
    }

    function sharesOf(address user)
        public
        view
        returns (uint256)
    {
        return _shareBalances[user];
    }

    function initialize()
        public
        initializer
    {
        __ERC20_init("Base Protocol", "BASE");
        _setupDecimals(uint8(DECIMALS));
        __Ownable_init();

        _totalShares = INITIAL_SHARES;
        _totalSupply = INITIAL_SUPPLY;
        _shareBalances[owner()] = _totalShares;
        _sharesPerBASE = _totalShares.div(_totalSupply);

        emit Transfer(address(0x0), owner(), _totalSupply);
    }

    /**
     * @return The total number of BASE.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        public
        override
        view
        returns (uint256)
    {
        return _shareBalances[who].div(_sharesPerBASE);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        override(ERC20UpgradeSafe, ERC677)
        validRecipient(to)
        returns (bool)
    {
        uint256 shareValue = value.mul(_sharesPerBASE);
        _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        override
        view
        returns (uint256)
    {
        return _allowedBASE[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        override
        validRecipient(to)
        returns (bool)
    {
        _allowedBASE[from][msg.sender] = _allowedBASE[from][msg.sender].sub(value);

        uint256 shareValue = value.mul(_sharesPerBASE);
        _shareBalances[from] = _shareBalances[from].sub(shareValue);
        _shareBalances[to] = _shareBalances[to].add(shareValue);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        override
        returns (bool)
    {
        _allowedBASE[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        _allowedBASE[msg.sender][spender] = _allowedBASE[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedBASE[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 oldValue = _allowedBASE[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedBASE[msg.sender][spender] = 0;
        } else {
            _allowedBASE[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedBASE[msg.sender][spender]);
        return true;
    }
}

pragma solidity ^0.6.0;
import "../Initializable.sol";

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Copyright (c) 2020 Base Protocol, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.6.12;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


        _name = name;
        _symbol = symbol;
        _decimals = 18;

    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    uint256[44] private __gap;
}

pragma solidity 0.6.12;

import "./interfaces/ERC677.sol";
import "./interfaces/ERC677Receiver.sol";


abstract contract ERC677Token is ERC677 {
    /**
    * @dev transfer token to a contract address with additional data if the recipient is a contact.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data The extra data to be passed to the receiving contract.
    */
    function transferAndCall(address _to, uint _value, bytes memory _data)
        public
        override
        returns (bool success)
    {
        transfer(_to, _value);
        // emit Transfer(msg.sender, _to, _value, _data);
        if (isContract(_to)) {
            contractFallback(_to, _value, _data);
        }
        return true;
    }

    function contractFallback(address _to, uint _value, bytes memory _data)
        private
    {
        ERC677Receiver receiver = ERC677Receiver(_to);
        receiver.onTokenTransfer(msg.sender, _value, _data);
    }

    function isContract(address _addr)
        private
        view
        returns (bool hasCode)
    {
        uint length;
        // solhint-disable-next-line no-inline-assembly
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.6.12;


abstract contract ERC677 {
    function transfer(address to, uint256 value) public virtual returns (bool);
    function transferAndCall(address to, uint value, bytes memory data) public virtual returns (bool success);
}

pragma solidity 0.6.12;


abstract contract ERC677Receiver {
    function onTokenTransfer(address _sender, uint _value, bytes memory _data) virtual public;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}