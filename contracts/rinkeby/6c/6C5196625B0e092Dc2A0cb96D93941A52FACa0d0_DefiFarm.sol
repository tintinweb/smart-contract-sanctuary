// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "IERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";

contract DefiFarm is Ownable {
    struct User {
        address addr;
        mapping(address => uint256) token2Balance;
        address[] stakingTokens;
    }

    User[] users;
    address[] allowedTokens;
    mapping(address => address) token2PriceFeed;
    IERC20 dappToken;

    constructor(address _dappToken) {
        dappToken = IERC20(_dappToken);
    }

    function stake(address _token, uint256 _amount) public {
        require(_token != address(0) && _amount > 0);
        require(
            isTokenAllowed(_token),
            "This token is not spport by our service!"
        );
        // sendFrom
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // update user balance & add this user to list user
        (bool isExist, uint256 index) = findUser(msg.sender);

        if (isExist) {
            User storage user = users[index];
            user.token2Balance[_token] += _amount;
            addToken2ListTokenOfUser(_token, user);
        } else {
            User storage user = users.push();
            user.token2Balance[_token] += _amount;
            addToken2ListTokenOfUser(_token, user);
        }
    }

    function issueToken() public onlyOwner {
        for (uint256 index = 0; index < users.length; index++) {
            User storage user = users[index];
            uint256 totalReward = getTotalRewardAmount(user);
            if (totalReward > 0) {
                dappToken.transfer(user.addr, totalReward);
            }
        }
    }

    function unstake(address _token, uint256 _amount) public {
        (bool isExist, uint256 index) = findUser(msg.sender);
        require(isExist, "You have not staked anything!");
        require(_amount > 0, "The unstake amount must be greater than zero");
        require(
            isTokenAllowed(_token),
            "This token is not spport by our service!"
        );

        // transfer token
        User storage user = users[index];
        uint256 availableAmount = user.token2Balance[_token];
        uint256 unstakeAmount = getMax(availableAmount, _amount);
        IERC20(_token).transfer(msg.sender, unstakeAmount);

        // update token balance
        uint256 availableAmountAfterUnstaking = availableAmount - unstakeAmount;
        user.token2Balance[_token] = availableAmountAfterUnstaking;
    }

    function getMax(uint256 _availableAmount, uint256 _amount)
        internal
        returns (uint256)
    {
        if (_amount >= _availableAmount) {
            return _availableAmount;
        } else {
            return _amount;
        }
    }

    function getTotalRewardAmount(User storage _user)
        internal
        returns (uint256)
    {
        // address[] memory stakingTokens = _user.stakingTokens;
        // mapping(address => uint256) memory token2Balance = _user.token2Balance;
        uint256 total = 0;
        //get reward amount in DAPP token for each token this user possess
        for (uint256 index = 0; index < _user.stakingTokens.length; index++) {
            address tokenAddr = _user.stakingTokens[index];
            uint256 tokenBalance = _user.token2Balance[tokenAddr];
            total += getRewardAmountOfSingleToken(tokenAddr, tokenBalance);
        }
        return total;
    }

    function getRewardAmountOfSingleToken(
        address _tokenAddress,
        uint256 _tokenBalance
    ) internal returns (uint256) {
        //in case balance equals zero, return 0 without calling priceFeed contract
        if (_tokenBalance == 0) return 0;

        address priceFeedAddr = token2PriceFeed[_tokenAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);

        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());

        return ((_tokenBalance * uint256(price)) / (10**decimals));
    }

    function addToken2ListTokenOfUser(address _token, User storage _user)
        internal
    {
        address[] storage stakingTokens = _user.stakingTokens;
        bool isAddedBefore = false;
        for (uint256 index = 0; index < stakingTokens.length; index++) {
            if (_token == stakingTokens[index]) isAddedBefore = true;
        }
        if (!isAddedBefore) _user.stakingTokens.push(_token);
    }

    function findUser(address _userAddress) internal returns (bool, uint256) {
        for (uint256 index = 0; index < users.length; index++) {
            if (users[index].addr == _userAddress) return (true, index);
        }
        return (false, users.length);
    }

    function isTokenAllowed(address _address) internal returns (bool) {
        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (allowedTokens[index] == _address) return true;
        }
        return false;
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {
        token2PriceFeed[_token] = _priceFeed;
    }

    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}