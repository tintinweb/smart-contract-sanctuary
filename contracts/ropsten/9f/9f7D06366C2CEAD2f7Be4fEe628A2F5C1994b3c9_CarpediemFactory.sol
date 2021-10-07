//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CarpeDiem.sol";

// Created by Carpe Diem Savings and SFXDX

contract CarpediemFactory is Ownable {

    address[] public allPools;

    uint256 constant percentBase = 100;

    event NewPool(
        address token,
        address poolAddress,
        uint256 initialPrice,
        uint256 bBonusAmount,
        uint256 lBonusPeriod,
        uint256 bBonusMaxPercent,
        uint256 lBonusMaxPercent
    );

    function createPool(
        address _token,
        uint256 _initialPrice,
        uint256 _bBonusAmount,
        uint256 _lBonusPeriod,
        uint256 _bBonusMaxPercent,
        uint256 _lBonusMaxPercent,
        uint16[] memory _distributionPercents,
        address[] memory _distributionAddresses
    ) external onlyOwner {
        require(_token != address(0), "token cannot be zero");
        require(_initialPrice != 0, "price cannot be zero");
        require(_bBonusAmount != 0, "B bonus amount cannot be zero");
        require(_lBonusPeriod != 0, "L bonus period cannot be zero");
        require(_distributionPercents.length == 5, "distributionPercents length must be == 5");
        require(_distributionAddresses.length == 3, "distributionAddresses length must be == 3");
        uint256 sum;
        for (uint256 i = 0; i < _distributionPercents.length; i++) {
            sum += _distributionPercents[i];
        }
        require(sum == percentBase, "percent sum must be == 100");
        for (uint256 i = 0; i < _distributionAddresses.length; i++) {
            require(_distributionAddresses[i] != address(0), "wallet cannot be == 0");
        }
        bytes32 salt = keccak256(abi.encodePacked(allPools.length));
        bytes memory bytecode = abi.encodePacked(
            type(CarpeDiem).creationCode,
            abi.encode(
                _token,
                _initialPrice,
                _bBonusAmount,
                _lBonusPeriod,
                _bBonusMaxPercent,
                _lBonusMaxPercent,
                _distributionPercents,
                _distributionAddresses
            )
        );
        address pool;
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        CarpeDiem(pool).transferOwnership(msg.sender);
        allPools.push(pool);
        emit NewPool(
            _token,
            pool,
            _initialPrice,
            _bBonusAmount,
            _lBonusPeriod,
            _bBonusMaxPercent,
            _lBonusMaxPercent
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Created by Carpe Diem Savings and SFXDX

contract CarpeDiem is Ownable {
    mapping(address => StakeInfo[]) public stakes; // user address => StakeInfo

    struct StakeInfo {
        uint256 amount;
        uint256 term;
        uint256 ts;
        uint256 shares;
        uint256 sharesWithBonuses;
        uint256 lastLambda;
        uint256 assignedReward;
    }

    address public immutable token;
    uint256 public immutable initialPrice; // initial shares price
    uint256 public immutable bBonusAmount; // amount for maximum B bonus
    uint256 public immutable lBonusPeriod; // period for maximum L bonus
    uint256 public immutable bBonusMaxPercent; // maximum value of B bonus
    uint256 public immutable lBonusMaxPercent; // maximum value of L bonus
    uint256 public totalShares; // total shares with the bonuses in the pool
    uint256 public currentPrice; // current shares price
    uint256 public lambda;
    uint16[] public distributionPercents; // percents to distribute
    address[] public distributionAddresses; // addresses for penalty distribution. wallet[0] corresponds to reward pool and can be equal any address != address(0)

    address constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant percentBase = 100;
    uint256 private constant MULTIPLIER = 1e18; // used for multiplying numerators in lambda and price calculations
    uint256 private constant WEEK = 7 * 86400;

    uint256 public constant FREE_LATE_PERIOD = WEEK; // period of free claiming after stake matured
    uint256 public constant PENALTY_PERCENT_PER_WEEK = 2; // amount of penalty percents applied to reward every late week
    uint256 public constant MAX_PRICE = 1e12 * MULTIPLIER; // max price (1 share for 1 trillion tokens) to prevent overflow

    event Deposit(address depositor, uint256 id, uint256 amount, uint256 term);

    event UpgradedStake(
        address depositor,
        uint256 id,
        uint256 amount,
        uint256 term
    );

    event Withdraw(
        address who,
        uint256 id,
        uint256 deposit,
        uint256 reward,
        uint256 penalty
    );

    event NewPrice(uint256 oldPrice, uint256 newPrice);

    constructor(
        address _token,
        uint256 _initialPrice,
        uint256 _bBonusAmount,
        uint256 _lBonusPeriod,
        uint256 _bBonusMaxPercent,
        uint256 _lBonusMaxPercent,
        uint16[] memory _distributionPercents,
        address[] memory _distributionAddresses
    ) {
        token = _token;
        lambda = 0;
        totalShares = 0;
        currentPrice = _initialPrice;
        initialPrice = _initialPrice;
        bBonusAmount = _bBonusAmount;
        lBonusPeriod = _lBonusPeriod;
        distributionPercents = _distributionPercents;
        bBonusMaxPercent = _bBonusMaxPercent;
        lBonusMaxPercent = _lBonusMaxPercent;
        distributionAddresses = _distributionAddresses;
    }

    function getDistributionAddresses() external view returns (address[] memory) {
        return distributionAddresses;
    }

    function getDistributionPercents() external view returns (uint16[] memory) {
        return distributionPercents;
    }

    function getUserStakes(address _user) external view returns (StakeInfo[] memory) {
        return stakes[_user];
    }

    function setDistributionAddresses(address[] calldata _newDistributionAddresses) external onlyOwner {
        require(
            _newDistributionAddresses.length == 3, 
            "distributionAddresses length must be == 3"
        );
        distributionAddresses = _newDistributionAddresses;
    }

    function deposit(uint256 _amount, uint256 _term) external {
        address sender = _msgSender();
        require(_amount > 0, "deposit cannot be zero");
        require(_term > 0, "term cannot be zero");
        uint256 shares = _buyShares(_amount, sender);
        uint256 boostedShares = _getBoostedShares(shares, _term, _amount);
        totalShares += boostedShares;
        stakes[sender].push(
            StakeInfo(
                _amount,
                _term,
                block.timestamp,
                shares,
                boostedShares,
                lambda,
                0
            )
        );

        emit Deposit(sender, stakes[sender].length - 1, _amount, _term);
    }

    function upgradeStake(uint256 _stakeId, uint256 _amount) external {
        address sender = _msgSender();
        require(_amount > 0, "deposit cannot be zero");
        require(_stakeId < stakes[sender].length, "no such stake id");
        uint256 stakeTerm = stakes[sender][_stakeId].term;
        uint256 stakeTs = stakes[sender][_stakeId].ts;
        require(stakeTs > 0, "stake was deleted");
        require(block.timestamp < stakeTerm + stakeTs, "stake matured");
        uint256 stakeDeposit = stakes[sender][_stakeId].amount;
        uint256 extraShares = _buyShares(_amount, sender);
        uint256 shares = stakes[sender][_stakeId].shares;
        uint256 boostedSharesBefore = stakes[sender][_stakeId]
            .sharesWithBonuses;
        uint256 boostedShares = _getBoostedShares(
            shares + extraShares,
            stakeTs + stakeTerm - block.timestamp,
            stakeDeposit + _amount
        );

        totalShares += boostedShares - boostedSharesBefore;
        stakes[sender][_stakeId] = StakeInfo(
            stakeDeposit + _amount,
            stakeTs + stakeTerm - block.timestamp,
            block.timestamp,
            shares + extraShares,
            boostedShares,
            lambda,
            getReward(sender, _stakeId)
        );

        emit UpgradedStake(
            sender,
            _stakeId,
            _amount,
            stakeTs + stakeTerm - block.timestamp
        );
    }

    function withdraw(uint256 _stakeId) external {
        address sender = _msgSender();
        require(_stakeId < stakes[sender].length, "no such stake id");
        uint256 deposit = stakes[sender][_stakeId].amount;
        require(deposit > 0, "stake was deleted");
        uint256 reward = getReward(sender, _stakeId);
        uint256 penalty = _getPenalty(sender, deposit, reward, _stakeId);
        uint256 userShares = stakes[sender][_stakeId].shares;
        _changeSharesPrice(deposit + reward - penalty, userShares);
        _distributePenalty(penalty);
        totalShares -= stakes[sender][_stakeId].sharesWithBonuses;
        if (totalShares == 0) {
            lambda = 0;
        } else {
            lambda +=
                (penalty *
                    MULTIPLIER *
                    MULTIPLIER *
                    uint256(distributionPercents[4])) /
                (percentBase * totalShares);
        }
        delete stakes[sender][_stakeId];
        IERC20(token).transfer(sender, deposit + reward - penalty);
        emit Withdraw(sender, _stakeId, deposit, reward, penalty);
    }

    function getPenalty(address _user, uint256 _stakeId)
        external
        view
        returns (uint256)
    {
        uint256 deposit = stakes[_user][_stakeId].amount;
        uint256 reward = getReward(_user, _stakeId);
        return _getPenalty(_user, deposit, reward, _stakeId);
    }

    function getReward(address _user, uint256 _stakeId)
        public
        view
        returns (uint256)
    {
        uint256 lastLambda = stakes[_user][_stakeId].lastLambda;
        uint256 reward = stakes[_user][_stakeId].assignedReward;
        uint256 poolLambda = lambda;
        if (poolLambda - lastLambda > 0) {
            reward +=
                ((poolLambda - lastLambda) *
                    stakes[_user][_stakeId].sharesWithBonuses) /
                (MULTIPLIER * MULTIPLIER);
        }
        return reward;
    }

    // buys shares for user for current share price
    function _buyShares(uint256 _amount, address _user)
        internal
        returns (uint256)
    {
        IERC20(token).transferFrom(_user, address(this), _amount); // take tokens
        uint256 sharesToBuy = (_amount * MULTIPLIER) / currentPrice; // calculate corresponding amount of shares
        return sharesToBuy * MULTIPLIER;
    }

    // boost user shares for both deposit and extraDeposit
    function _getBoostedShares(
        uint256 _shares,
        uint256 _term,
        uint256 _deposit
    ) internal view returns (uint256) {
        return
            _shares +
            _getBonusB(_shares, _deposit) +
            _getBonusL(_shares, _term);
    }

    function _getBonusB(uint256 _shares, uint256 _deposit)
        internal
        view
        returns (uint256)
    {
        uint256 poolBBonus = bBonusAmount;
        if (_deposit < poolBBonus)
            return
                (_shares * bBonusMaxPercent * _deposit) /
                (poolBBonus * percentBase);
        return (bBonusMaxPercent * _shares) / percentBase;
    }

    function _getBonusL(uint256 _shares, uint256 _term)
        internal
        view
        returns (uint256)
    {
        uint256 poolLBonus = lBonusPeriod;
        if (_term < poolLBonus)
            return
                (_shares * lBonusMaxPercent * _term) / (poolLBonus * percentBase);
        return (lBonusMaxPercent * _shares) / percentBase;
    }

    function _getPenalty(
        address _user,
        uint256 _deposit,
        uint256 _reward,
        uint256 _stakeId
    ) internal view returns (uint256) {
        uint256 term = stakes[_user][_stakeId].term;
        uint256 stakeTs = stakes[_user][_stakeId].ts;
        if (stakeTs + term <= block.timestamp) {
            if (stakeTs + term + FREE_LATE_PERIOD > block.timestamp) return 0;
            uint256 lateWeeks = (block.timestamp - (stakeTs + term)) / WEEK;
            if (lateWeeks >= 50) return _reward;
            return (_reward *
                PENALTY_PERCENT_PER_WEEK *
                lateWeeks) / percentBase;
        }
        return
            ((_deposit + _reward) * (term - (block.timestamp - stakeTs))) /
            term;
    }

    function _distributePenalty(
        uint256 _penalty
    ) internal {
        address[] memory addresses = distributionAddresses;
        uint16[] memory poolPercents = distributionPercents;
        uint256 base = percentBase;
        address poolToken = token;
        for (uint256 i = 0; i < addresses.length; i++) {
            if (poolPercents[i] > 0)
                IERC20(poolToken).transfer(
                    addresses[i],
                    (_penalty * poolPercents[i]) / base
                );
        }
        if (poolPercents[3] > 0) IERC20(poolToken).transfer(
                    DEAD_WALLET,
                    (_penalty * poolPercents[3]) / base
                );

    }

    function _changeSharesPrice(uint256 _profit, uint256 _shares) private {
        uint256 oldPrice = currentPrice;
        if (_profit > (oldPrice * _shares) / (MULTIPLIER * MULTIPLIER)) {
            // equivalent to _profit / shares > oldPrice
            uint256 newPrice = (_profit * MULTIPLIER * MULTIPLIER) / _shares;
            if (newPrice > MAX_PRICE) newPrice = MAX_PRICE;
            currentPrice = newPrice;
            emit NewPrice(oldPrice, newPrice);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}