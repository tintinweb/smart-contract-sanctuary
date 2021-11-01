/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

// File: contracts/interfaces/IWZYX.sol

pragma solidity ^0.6.12;

interface IWZYX {
    function mint(address _to, uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/lib/ChainId.sol

pragma solidity 0.6.12;

library ChainId {
    int256 public constant zyxChainId = 55;


    function getChainId() internal pure returns (int256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// File: contracts/lib/SafeMath.sol

pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.6.12;

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
    function transfer(address recipient, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

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
    ) external;

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

// File: contracts/lib/Context.sol

pragma solidity 0.6.12;

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

// File: contracts/lib/Ownable.sol

pragma solidity 0.6.12;



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
    constructor() public {
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

// File: contracts/lib/Pausable.sol

pragma solidity ^0.6.12;



abstract contract Pausable is Ownable {
    bool public pause;

    modifier isPause() {
        require(!pause, "Pausable: paused");
        _;
    }

    function togglePause() public virtual onlyOwner {
        pause = !pause;
    }
}

// File: contracts/WzyxBridge.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;








contract WZyxBridge is Pausable {
    using SafeMath for *;

    struct User {
        uint256 amount;
        uint256 fee;
        uint256 totalRedeem;
    }

    struct Swap {
        address token;
        address user;
        uint256 amount;
        uint256 fee;
        bytes32 hash;
    }

    int256 public chainId;

    address public oracle;
    address public wzyx;
    address public feeTo;
    address public migrator;

    mapping(address => bool) public listOfSupportedTokens;
    mapping(address => uint256) public minLimitForSwap;
    mapping(address => uint256) public tokensBalances;
    mapping(bytes32 => bool) public checkedHashes;
    mapping(address => mapping(address => User)) public users;


    constructor() public {
        chainId = ChainId.getChainId();
    }


    /**** Modifiers ****/
    modifier onlyOracle() {
        require(msg.sender == oracle, "ZyxBridge: Not oracle");
        _;
    }

    modifier supportedToken(address token) {
        require(listOfSupportedTokens[token], "ZyxBridge: Not supported token");
        _;
    }

    modifier newHash(bytes32 hash) {
        require(!checkedHashes[hash], "ZyxBridge: Duplicated hash");
        _;
    }

    event NewSwap(
        address token,
        address user,
        address oracle,
        uint256 amount,
        uint256 fee,
        int256 chainIdFrom,
        int256 chainIdTo,
        bytes32 hash
    );

    event Redeem(
        address token,
        address user,
        uint256 amount,
        uint256 fee
    );

    event NewDeposit(
        address token,
        address user,
        uint256 amount,
        int256 chainIdFrom,
        int256 chainIdTo
    );

    function newTransfer(Swap calldata swapInfo) public onlyOracle
        supportedToken(swapInfo.token)
        isPause
        newHash(swapInfo.hash)
    {
        User storage user = users[swapInfo.token][swapInfo.user];
        user.amount = user.amount.add(swapInfo.amount);
        user.fee = user.fee.add(swapInfo.fee);

        if (wzyx != swapInfo.token) {
            tokensBalances[swapInfo.token] = tokensBalances[swapInfo.token].sub(swapInfo.amount).sub(swapInfo.fee);
        }

        checkedHashes[swapInfo.hash] = true;

        emit NewSwap(
            swapInfo.token,
            swapInfo.user,
            msg.sender,
            swapInfo.amount,
            swapInfo.fee,
            ChainId.zyxChainId,
            chainId,
            swapInfo.hash
        );
    }

    function redeemToken(address token) public supportedToken(token) {
        User storage user = users[token][msg.sender];
        require(user.amount > 0, "ZyxBridge: nothing to withdraw");
        if (token == wzyx) {
            IWZYX(wzyx).mint(msg.sender, user.amount);
            IWZYX(wzyx).mint(feeTo, user.fee);
        } else {
            IERC20(token).transfer(msg.sender, user.amount);
            IERC20(token).transfer(feeTo, user.fee);
        }
        user.totalRedeem = user.totalRedeem.add(user.amount);
        uint256 amount = user.amount;
        uint256 fee = user.fee;
        user.amount = 0;
        user.fee = 0;
        emit Redeem(token, msg.sender, amount, fee);
    }

    function depositToken(address token, uint256 amount) public supportedToken(token) isPause {
        require(amount >= minLimitForSwap[token], "ZyxBridge: amount is too small");
        if (token == wzyx) {
            IWZYX(wzyx).burnFrom(msg.sender, amount);
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            tokensBalances[token] = tokensBalances[token].add(amount);
        }
        emit NewDeposit(token, msg.sender, amount, chainId, ChainId.zyxChainId);
    }


    /**** Admin functions  ****/
    function addCoin(address _token, uint256 _minSwap) public onlyOwner {
        listOfSupportedTokens[_token] = true;
        minLimitForSwap[_token] = _minSwap;
    }

    function removeCoin(address _token) public onlyOwner {
        delete listOfSupportedTokens[_token];
        delete minLimitForSwap[_token];
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setMigrator(address _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function setWzyx(address _wzyx) public onlyOwner {
        wzyx = _wzyx;
    }

    function setFeeTo(address _feeTo) public onlyOwner {
        feeTo = _feeTo;
    }

    function migrate(address _token) public onlyOwner {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(migrator,currentBalance);
        delete listOfSupportedTokens[_token];
        delete minLimitForSwap[_token];
        delete tokensBalances[_token];
    }
}