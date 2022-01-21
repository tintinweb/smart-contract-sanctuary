// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ReentrancyGuard.sol";

contract BetGame is Ownable, ReentrancyGuard {

    IERC20 public betGameToken;
    uint256 public rewardMultiplier;
    enum GameState {Opening, Waiting, Running} //, Finished}

    constructor(address _tokenAddress) {
        betGameToken = IERC20(_tokenAddress);
        rewardMultiplier = 90;
    }

    struct GamePool {
        uint256 id;
        GameState state;
        uint256 tokenAmount; // token amount needed to enter each pool. must e18, important when init
        address[] players;
    }

    GamePool[] public pools;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event LogClaimAward(uint256 indexed pid, address indexed winnerAddress, uint256 award);

    // get number of games
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    // add pool
    function addPool(
        uint256 _tokenAmount
    ) external onlyOwner {
        pools.push(
            GamePool({
                id : pools.length + 1,
                state: GameState.Opening,
                tokenAmount : _tokenAmount,
                players: new address[](0)
            })
        );
    }

    // update pool
    function updatePool(
        uint256 _pid,
        uint256 _tokenAmount
    ) external onlyOwner {
        uint256 poolIndex = _pid - 1;
        if(_tokenAmount > 0) {
            pools[poolIndex].tokenAmount = _tokenAmount;
        }
    }

    // bet game
    function bet(uint256 _pid) external {
        uint256 poolIndex = _pid - 1;
        // check balance
        require(betGameToken.balanceOf(msg.sender) >= pools[poolIndex].tokenAmount, "insufficient funds");
        // check game status
        require(pools[poolIndex].state != GameState.Running, "game is running");
        // add user
        if(pools[poolIndex].state == GameState.Opening) {
            pools[poolIndex].players.push(msg.sender);
            pools[poolIndex].state = GameState.Waiting;
        } else if(pools[poolIndex].state == GameState.Waiting) {
            pools[poolIndex].players.push(msg.sender);
            pools[poolIndex].state = GameState.Running;
        }
        // deposit token
        betGameToken.transferFrom(msg.sender, address(this), pools[poolIndex].tokenAmount);
        emit Transfer(msg.sender, address(this), pools[poolIndex].tokenAmount);
    }

    // update game status
    // function updateStatus(uint256 _pid) external onlyOwner {
    //     uint256 poolIndex = _pid - 1;
    //     require(pools[poolIndex].state == GameState.Running, 'No time to finish the game');
    //     pools[poolIndex].state = GameState.Finished;
    // }

    // claim award
    function claimAward(uint256 _pid, address _winnerAddress) external onlyOwner nonReentrant {
        uint256 poolIndex = _pid - 1;
        // check game status
        require(pools[poolIndex].state == GameState.Running, "no valid time");
        require(pools[poolIndex].players[0] == _winnerAddress || pools[poolIndex].players[1] == _winnerAddress, "player not found");
        // send award
        uint256 award = pools[poolIndex].tokenAmount * 2 * rewardMultiplier / 100;
        uint256 gasFee = pools[poolIndex].tokenAmount * 2 * (100 - rewardMultiplier) / 100;
        betGameToken.transferFrom(address(this), _winnerAddress, award);
        betGameToken.transferFrom(address(this), msg.sender, gasFee);
        emit LogClaimAward(_pid, _winnerAddress, award);
        // initialize game
        pools[poolIndex].state = GameState.Opening;
        pools[poolIndex].players = new address[](0);
    }

    // withdraw funds
    function withdrawFund() external onlyOwner {
        uint256 balance = betGameToken.balanceOf(address(this));
        require(balance > 0, "not enough fund");
        betGameToken.transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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