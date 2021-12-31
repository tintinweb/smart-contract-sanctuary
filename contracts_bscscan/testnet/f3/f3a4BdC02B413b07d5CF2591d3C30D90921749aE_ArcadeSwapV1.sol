// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IBEP20Price.sol";
import "./libraries/Requests.sol";
import "./GameCurrency.sol";

contract ArcadeSwapV1 is Ownable, Pausable, ReentrancyGuard {
    using Requests for Requests.Request;
    using SafeERC20 for IERC20;

    IBEP20Price public bep20Price;
    IERC20 public arcToken;

    struct GameInfo {
        uint256 id; // game id
        uint256 gcPerArc;
        IERC20 gcToken;
        string gcName;
        string gcSymbol;
        bool isActive;
        bool isPartnership; // true if the game is a partnership game
    }

    struct UserInfo {
        uint256 weightedAverage; // in 18 digits
        uint256 arcAmount; // in 18 digits
        uint256 gcAmount; // in 18 digits
    }

    // <game id => <user address => UserInfo>>
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => GameInfo) public gameInfo;
    mapping (uint256 => address[]) public gameWhitelists;
    mapping (uint256 => mapping (address => bool)) public isWhitelists;

    struct Commission {
        uint256 commission1; // 100% in 10000
        uint256 commission2; // 100% in 10000
        address treasuryAddress1;
        address treasuryAddress2;
    }
    mapping(uint256 => Commission) internal _commissions;

    uint256 public txDuration;
    // <user address, <game id => timestamp>>
    mapping (address => mapping(uint256 => uint256)) public lastTxTime;

    bytes32 public immutable DOMAIN_SEPARATOR;
    address public backendSigner;

    event NewGame(
        uint256 indexed _gameId,
        uint256 indexed _gcPerArc,
        address indexed _gcToken,
        string _gcName,
        string _gcSymbol,
        bool _isPartnership
    );

    event GameActive(uint256 indexed _gameId, bool _active);

    event GameGcPerArc(uint256 indexed _gameId, uint256 _gcPerArc);

    event GamePartnership(uint256 indexed _gameId, bool _partnership);

    event BuyGameCurrency(
        uint256 indexed _gameId,
        address indexed _user,
        uint256 _arcAmount,
        uint256 _received,
        uint256 _minted
    );

    event SellGameCurrency(
        uint256 indexed _gameId,
        address indexed _user,
        uint256 _gcAmount,
        uint256 _received,
        uint256 _burned
    );

    // emit event when user transfer Gc from wallet to the game
    event TransferWalletToGame(
        uint256 indexed _gameId,
        address indexed _user,
        uint256 _gcAmount
    );

    // emit event when user transfer Gc from game to wallet
    event TransferGameToWallet(
        uint256 indexed _gameId,
        address indexed _user,
        uint256 _gcAmount
    );

    event SetTxDuration(uint256 _duration);

    modifier isActiveGame(uint256 _gameId) {
        require(gameInfo[_gameId].id == _gameId, "not initialized game");
        require(gameInfo[_gameId].isActive, "inactive game");
        _;
    }

    constructor(
        IBEP20Price _bep20Price,
        IERC20 _token
    ) {
        bep20Price = _bep20Price;
        arcToken = _token;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("ArcadeSwap"),
                keccak256("1"),
                chainId,
                address(this)
            )
        );
    }

    function setBackendSigner(address _signer) external {
        require(_signer != address(0), "invalid signer address");
        backendSigner = _signer;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setNewGame(
        uint256 _gameId,
        uint256 _gcPerArc,
        string memory _gcName,
        string memory _gcSymbol,
        bool isPartnership
    ) external onlyOwner {
        require(gameInfo[_gameId].id != _gameId, "Already initialized");
        require(_gcPerArc > 0, "invalid game currency amount per arc token");
        GameCurrency gcToken = new GameCurrency(_gcName, _gcSymbol);
        gameInfo[_gameId] = GameInfo({
            id: _gameId,
            gcPerArc: _gcPerArc,
            gcName: _gcName,
            gcSymbol: _gcSymbol,
            gcToken: IERC20(gcToken),
            isActive: true,
            isPartnership: isPartnership
        });

        emit NewGame(
            _gameId,
            _gcPerArc,
            address(gcToken),
            _gcName,
            _gcSymbol,
            isPartnership
        );
    }

    function setGameActive(uint256 _gameId, bool _active) external onlyOwner {
        gameInfo[_gameId].isActive = _active;

        emit GameActive(_gameId, _active);
    }

    function setGameGcPerArc(uint256 _gameId, uint256 _gcPerArc)
        external onlyOwner isActiveGame(_gameId)
    {
        require(_gcPerArc > 0, "invalid game currency amount per arc token");
        gameInfo[_gameId].gcPerArc = _gcPerArc;

        emit GameGcPerArc(_gameId, _gcPerArc);
    }

    function setPartnership(uint256 _gameId, bool _partnership)
        external onlyOwner isActiveGame(_gameId)
    {
        gameInfo[_gameId].isPartnership = _partnership;

        emit GamePartnership(_gameId, _partnership);
    }

    function setGameWhitelist(uint256 _gameId, address _user, bool _status)
        external onlyOwner isActiveGame(_gameId)
    {
        require(
            gameInfo[_gameId].isPartnership,
            "only available for partnership game"
        );
        if (_status) {
            gameWhitelists[_gameId].push(_user);
        }
        isWhitelists[_gameId][_user] = _status;
    }

    function setGameWhitelists(
        uint256 _gameId,
        address[] calldata _addrs,
        bool _status
    ) external onlyOwner isActiveGame(_gameId) {
        require(
            gameInfo[_gameId].isPartnership,
            "only available for partnership game"
        );
        for (uint256 i = 0; i < _addrs.length; i++) {
            if (_status) {
                gameWhitelists[_gameId].push(_addrs[i]);
            }
            isWhitelists[_gameId][_addrs[i]] = _status;
        }
    }

    function buyGc(Requests.Request memory request)
        public
        virtual
        nonReentrant
        whenNotPaused
        isActiveGame(request.gameId)
    {
        request.validate();
        request.verify(DOMAIN_SEPARATOR);
        require(request.maker == backendSigner, "invalid signer");
        require(request.requester == msg.sender, "invalid requester");
        require(
            request.gcToken == address(gameInfo[request.gameId].gcToken),
            "invalid game currency token"
        );
        uint256 gameId = request.gameId;
        require(
            block.timestamp - lastTxTime[msg.sender][gameId] >= txDuration,
            "Not time to buy Game Point"
        );

        if (gameInfo[gameId].isPartnership) {
            require(isWhitelists[gameId][msg.sender], "not a whitelist");
        }

        // distribute commission
        uint256 commission1 =
            request.amount * _commissions[gameId].commission1 / 10000;
        uint256 commission2 =
            request.amount * _commissions[gameId].commission2 / 10000;
        if (commission1 > 0) {
            arcToken.safeTransferFrom(
                msg.sender,
                _commissions[gameId].treasuryAddress1,
                commission1
            );
        }
        if (commission2 > 0) {
            arcToken.safeTransferFrom(
                msg.sender,
                _commissions[gameId].treasuryAddress2,
                commission2
            );
        }

        arcToken.safeTransferFrom(
            msg.sender,
            address(this),
            request.amount - commission1 - commission2
        );

        uint256 arcPrice = bep20Price.getTokenPrice(address(arcToken), 18);
        // GC token amount to be received in 18 digits
        uint256 toReceive =
            gameInfo[gameId].gcPerArc * arcPrice * request.amount / 10 ** 18;

        uint256 weightedAverage = userInfo[gameId][msg.sender].weightedAverage;
        weightedAverage =
            weightedAverage * userInfo[gameId][msg.sender].arcAmount /
            10 ** 18 +
            request.amount * arcPrice / 10 ** 18;
        userInfo[gameId][msg.sender].arcAmount += request.amount;
        userInfo[gameId][msg.sender].weightedAverage =
            weightedAverage * 10 ** 18 /
            userInfo[gameId][msg.sender].arcAmount;
        userInfo[gameId][msg.sender].gcAmount += toReceive;

        GameCurrency(request.gcToken).mint(msg.sender, toReceive);

        lastTxTime[msg.sender][gameId] = block.timestamp;

        emit BuyGameCurrency(
            gameId,
            msg.sender,
            request.amount,
            toReceive,
            toReceive
        );

        // if not partnership, directly transfer purchased Gc to the game
        if (!gameInfo[gameId].isPartnership) {
            GameCurrency(request.gcToken).burn(msg.sender, toReceive);
            emit TransferWalletToGame(gameId, msg.sender, toReceive);
        }
    }

    function sellGc(Requests.Request memory request)
        public
        virtual
        nonReentrant
        whenNotPaused
        isActiveGame(request.gameId)
    {
        request.validate();
        request.verify(DOMAIN_SEPARATOR);
        require(request.maker == backendSigner, "invalid signer");
        require(request.requester == msg.sender, "invalid requester");
        require(
            request.gcToken == address(gameInfo[request.gameId].gcToken),
            "invalid game currency token"
        );
        uint256 gameId = request.gameId;
        require(
            block.timestamp - lastTxTime[msg.sender][gameId] >= txDuration,
            "Not time to buy Game Point"
        );

        if (gameInfo[gameId].isPartnership) {
            require(isWhitelists[gameId][msg.sender], "not a whitelist");
        }

        require(
            userInfo[gameId][msg.sender].gcAmount >= request.amount,
            "not enough game currency"
        );
        require(
            userInfo[gameId][msg.sender].weightedAverage > 0,
            "invalid weighted average"
        );

        uint256 toReceive =
            request.amount * (10 ** 18) /
            (
                gameInfo[gameId].gcPerArc * userInfo[gameId][msg.sender].weightedAverage
            );

        // distribute commission
        uint256 commission1 =
            toReceive * _commissions[gameId].commission1 / 10000;
        uint256 commission2 =
            toReceive * _commissions[gameId].commission2 / 10000;
        if (commission1 > 0) {
            arcToken.safeTransfer(
                _commissions[gameId].treasuryAddress1,
                commission1
            );
        }
        if (commission2 > 0) {
            arcToken.safeTransfer(
                _commissions[gameId].treasuryAddress2,
                commission2
            );
        }

        arcToken.safeTransfer(
            msg.sender,
            toReceive - commission1 - commission2
        );
        GameCurrency(request.gcToken).burn(msg.sender, request.amount);

        userInfo[gameId][msg.sender].arcAmount -= toReceive;
        userInfo[gameId][msg.sender].gcAmount -= request.amount;

        lastTxTime[msg.sender][gameId] = block.timestamp;

        emit SellGameCurrency(
            gameId,
            msg.sender,
            request.amount,
            toReceive,
            request.amount
        );

        // if not partnership, directly transfer purchased Gc to the game
        if (!gameInfo[gameId].isPartnership) {
            emit TransferGameToWallet(gameId, msg.sender, request.amount);
        }
    }

    /** 
     * @notice withdraw Arcade token
     * @param _to "to" address of withdraw request
     * @param _amount amount to withdraw
     */
    function transferTo(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Transfer to zero address.");
        require(arcToken.balanceOf(address(this)) >= _amount, "invalid amount");
        arcToken.safeTransfer(_to, _amount);
    }

    /**
     * @notice Set commission per game
     * @param _gameId game id
     * @param _commission1 first commission percent in 10000(100%)
     * @param _commission2 second commission percent in 10000(100%)
     * @param _treasury1 first treasury address
     * @param _treasury2 second treasury address
     */
    function setCommission(
        uint256 _gameId,
        uint256 _commission1,
        uint256 _commission2,
        address _treasury1,
        address _treasury2
    ) external onlyOwner {
        require(_gameId != 0, "game id can't be zero");
        _commissions[_gameId] = Commission({
            commission1: _commission1,
            commission2: _commission2,
            treasuryAddress1: _treasury1,
            treasuryAddress2: _treasury2
        });
    }

    /**
     * @notice View commission per game
     * @param _gameId game id
     * @return commission structure
     */
    function viewCommission(uint256 _gameId)
        external
        view
        returns (Commission memory)
    {
        require(_gameId != 0, "game id can't be zero");
        return _commissions[_gameId];
    }

    /**
     * @notice Set transaction duration
     * @param _duration duration  in seconds
     */
    function setTxDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Non-zero duration");
        require(txDuration != _duration, "Different duration");
        txDuration = _duration;
        emit SetTxDuration(_duration);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

pragma solidity ^0.8.4;

interface IBEP20Price {
  /**
   * @notice Return BNB price in USD
   * @return returns in 18 digits
   */
  function getBNBPrice() external view returns (uint256);

  /**
   * @notice Calculate token price in USD
   * @param _token BEP20 token address
   * @param _digits BEP20 token digits
   * @return return in 18 digits
   */
  function getTokenPrice(
    address _token,
    uint256 _digits
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./EIP712.sol";

library Requests {
    // keccak256("Request(address maker,address requester,uint256 gameId,uint256 amount,uint256 reserved1,uint256 reserved2)")
    bytes32 public constant REQUEST_TYPEHASH =
        0xd32aee5345fa208c941f81688a0bd6baed57015ace9fce44cfd25c5fb8a5fbf7;

    struct Request {
        address maker;
        address requester;
        address gcToken;
        uint256 gameId;
        uint256 amount;
        uint256 reserved1;
        uint256 reserved2;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function hash(Request memory request) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    REQUEST_TYPEHASH,
                    request.maker,
                    request.requester,
                    request.gcToken,
                    request.gameId,
                    request.amount,
                    request.reserved1,
                    request.reserved2
                )
            );
    }

    function validate(Request memory request) internal pure {
        require(request.maker != address(0), "invalid maker");
        require(request.requester != address(0), "invalid requester");
        require(request.gcToken != address(0), "invalid game currency token");
        require(request.gameId > 0, "invalid gameId");
        require(request.amount > 0, "invalid amount");
    }

    function verify(Request memory request, bytes32 DOMAIN_SEPARATOR)
        internal pure
    {
        bytes32 calcHash = hash(request);
        address signer =
            EIP712.recover(
                DOMAIN_SEPARATOR,
                calcHash,
                request.v,
                request.r,
                request.s
            );
        require(
            signer != address(0) && signer == request.maker,
            "invalid signature"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameCurrency is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}
    
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library EIP712 {
    function recover(
        bytes32 DOMAIN_SEPARATOR,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    hash
                )
            );
        return ecrecover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}