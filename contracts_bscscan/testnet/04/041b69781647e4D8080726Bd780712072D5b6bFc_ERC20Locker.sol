// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

/******************* Imports **********************/
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";


// @title A time locking smart contract
// @author M.Armaghan Raza
// @notice User's can use this contract for locking ERC20 based only supported tokens for either 3, 6, 9 or 12 months.
// @dev All function calls are currently implemented without side effects.
// @custom:experimental This contract is experimental.
contract ERC20Locker is Ownable, ReentrancyGuard {

    /******************* State Variables **********************/
    // @notice This struct stores information regarding locked tokens.
    struct LockedRecords {
        uint256 amount;
        uint256 validity;
        address payable addr;
        address token;
        bool doesExist;
        uint256 insertedAt;
        uint256 updatedAt;
    }

    // @notice This struct shall contain address of admin who added the token and a bool for temorarily enabling and disabling support for the token.
    struct SupportedToken {
        address token;
        address added_by;
        bool enabled;
        uint256 insertedAt;
        uint256 updatedAt;
    }

    // @notice Mapping for storing supported tokens information.
    mapping (address => SupportedToken) private supportedTokens;

    // @notice Following is a mapping where we map every locked token's information against a unique number.
    mapping (address => mapping(address => LockedRecords)) private userLockRecords;

    address private _owner;
    constructor () {
        _owner = msg.sender;
    }

    /******************* Events **********************/
    event Locked(
        address indexed _of,
        uint256 _amount,
        address token,
        uint256 _validity
    );

    event Unlocked(
        address indexed _of,
        uint256 _amount,
        address token,
        uint256 timestamp
    );

    /******************* Modifiers **********************/
    modifier ValidateLockParams (uint256 _amount, uint256 _time) {
        require (_amount > 0, "Amount should be greater than zero");
        require (_time == 3 || _time == 6 || _time == 9 || _time == 12, "Please enter a digit as 3, 6, 9 or 12");
        require(address(msg.sender).balance >= _amount, "Amount to be locked exceeds total balance!");
        _;
    }

    modifier isContract(address token) {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        require(size > 0, "Please provide valid token address!!!");
        _;
    }

    modifier ValidateUserBalance (address _token, uint256 _amount) {
        IERC20 token = IERC20(_token);
        require(token.balanceOf(msg.sender) > _amount, "Insufficient balance");
        _;
    }

    modifier IsSupportedToken (address _token) {
        require(supportedTokens[_token].token == _token && supportedTokens[_token].enabled, "Address of token provided is not supported!");
        _;
    }

    modifier HasUserAlreadyLockedSameToken (address _token) {
        require(!userLockRecords[msg.sender][_token].doesExist, "You've already locked this token, please unlock them all before locking again.");
        _;
    }

    modifier IsTokenAdded (address _token) {
        require(supportedTokens[_token].token == _token, "Added of token doesnot exist in supported tokens, please use addSupportedToken method for adding this token.");
        _;
    }

    modifier IsNewToken (address _token) {
        require(supportedTokens[_token].token != _token, "Token is already added as supported token!");
        _;
    }

    modifier IsTokenEnabled (address _token) {
        require(supportedTokens[_token].enabled, "Token already disabled");
        _;
    }

    modifier IsTokenDisabled (address _token) {
        require(!supportedTokens[_token].enabled, "Token already enabled");
        _;
    }


    /******************* Admin Methods **********************/
    /// @notice Admin method to add new supported token
    /// @param _token Address of token to be added as supported token
    function addSupportedToken (address _token) public onlyOwner isContract(_token) IsNewToken(_token) {
        supportedTokens[_token] = SupportedToken(_token, msg.sender, true, block.timestamp, 0);
    }

    /// @notice Admin method to diable an already added supported token
    /// @param _token Address of token to be disabled
    function disableSupportedToken (address _token) public onlyOwner IsTokenAdded(_token) IsTokenEnabled(_token) {
        supportedTokens[_token].enabled = false;
        supportedTokens[_token].updatedAt = block.timestamp;
    }

    /// @notice Admin method to enable an already added but disabled supported token
    /// @param _token Address of token to be enabled
    function enableSupportedToken (address _token) public onlyOwner IsTokenAdded(_token) IsTokenDisabled(_token) {
        supportedTokens[_token].enabled = true;
        supportedTokens[_token].updatedAt = block.timestamp;
    }

    /******************* Private Methods **********************/
    /// @notice This private method transfers `_amount` from user's account to this contract for locking purpose
    /// @param _token Addess of user's ERC20 based token smart contract
    /// @param _amount Amount of tokens/funds user wishes to lock
    /// @param validUntil Amount of time for which user wishes to lock their funds.
    function lockUserFunds (address _token, uint _amount, uint validUntil) private nonReentrant {
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        userLockRecords[msg.sender][_token] = LockedRecords(_amount, validUntil, payable(msg.sender), _token, true, block.timestamp, 0);
        
        emit Locked(msg.sender, _amount, _token, validUntil);
    }


    /******************* Public Methods **********************/
    /// @notice This method locks `_amount` token(s) for `_time` months
    /// @dev Validate if prodvided `_token` is a supported token before locking
    /// @param _token Address of token that user wants to lock.
    /// @param _amount Number of token to be locked.
    /// @param _time Number of months for locking `_amount` token(s).
    function lock (address _token, uint256 _amount, uint256 _time) public payable isContract(_token)
      ValidateLockParams(_amount, _time) IsSupportedToken(_token) 
      ValidateUserBalance(_token, _amount) HasUserAlreadyLockedSameToken(_token) {        
        // @notice Please uncomment this line and comment out next line when need to be locked for `_time` months.
        uint256 validUntil =  (_time * 30 days) + block.timestamp;
        // uint256 validUntil =  (_time * 1 minutes) + block.timestamp; // For testing purpose, please comment this line.
        // Following call to private method solves, stack too deep compile time error.
        lockUserFunds(_token, _amount, validUntil);
    }

    /// @notice This method unlock user's all tokens for a given address
    /// @param _token Address of token to be unlocked
    function unlockAll (address _token) public nonReentrant {
        if (userLockRecords[msg.sender][_token].addr == msg.sender && userLockRecords[msg.sender][_token].token == _token) {
            if (userLockRecords[msg.sender][_token].validity < block.timestamp) {
                IERC20 token = IERC20(_token);
                token.transfer(msg.sender, userLockRecords[msg.sender][_token].amount);

                delete userLockRecords[msg.sender][_token];

                emit Unlocked(
                    msg.sender, userLockRecords[msg.sender][_token].amount,
                    _token, block.timestamp
                );

            } else {
                revert("You can not unlock funds right now!");
            }
        } else {
            revert("You do not have any funds locked for the provided token address!");
        }
    }

    /// @notice This method unlock `_amount` tokens for a given token address
    /// @param _token Address of token to be unlocked
    /// @param _amount Amount of tokens to be unlocked
    function unlock (address _token, uint256 _amount) public nonReentrant {
        if (userLockRecords[msg.sender][_token].addr == msg.sender && userLockRecords[msg.sender][_token].token == _token) {
            if (userLockRecords[msg.sender][_token].validity <= block.timestamp) {
                if (userLockRecords[msg.sender][_token].amount >= _amount) {
                    uint remainingBalance = userLockRecords[msg.sender][_token].amount - _amount;  

                    if (remainingBalance == 0) delete userLockRecords[msg.sender][_token];
                    else userLockRecords[msg.sender][_token].amount = remainingBalance;

                    IERC20 token = IERC20(_token);
                    token.transfer(msg.sender, _amount);

                    emit Unlocked(msg.sender, _amount, _token, block.timestamp);
                } else {
                    revert(
                        string (
                            abi.encodePacked (
                                "Amount you want to unlock exceeds your balance by ",
                                _amount - userLockRecords[msg.sender][_token].amount,
                                " tokens."
                            )
                        )
                    );
                }
            } else {
                revert("You can not unlock funds right now!");
            }
        } else {
            revert("You do not have any funds locked for the provided token address!");
        }
    }

    function checkFunds (address _token) public view returns (uint256) {
        return userLockRecords[msg.sender][_token].amount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../GSN/Context.sol";
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}