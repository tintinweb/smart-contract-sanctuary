/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// File: contracts/interfaces/IWZYX.sol

pragma solidity ^0.6.12;

interface IWZYX {
    function mint(address _to, uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/interfaces/IZYX20.sol

pragma solidity ^0.6.12;

interface IZYX20 {
    function mint(address _to, uint256 _amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/lib/ChainId.sol

library ChainId {
    function getChainId() internal pure returns (int chainId) {
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
    bool public isPausable;

    modifier isPause() {
        require(isPausable, "Pausable: paused");
        _;
    }

    function togglePause() public virtual onlyOwner {
        isPausable = !isPausable;
    }
}

// File: contracts/ZyxBridge.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;








contract ZyxBridge is Ownable, Pausable {
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
        int chainIdFrom;
        bytes32 hash;
    }

    int public chainId;

    address public oracle;
    address public wzyx;
    address public feeTo;
    address public migrator;

    mapping(address => bool) public listOfSupportedTokens;
    mapping(address => uint256) public minLimitForSwap;
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

    event NewSwap(
        address token,
        address user,
        address oracle,
        uint256 amount,
        uint256 fee,
        int chainIdFrom,
        int chainIdTo,
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
        int chainIdFrom,
        int chainIdTo
    );

    function newTransfer(Swap calldata swapInfo) public payable onlyOracle supportedToken(swapInfo.token) isPause {
        User storage user = users[swapInfo.token][swapInfo.user];
        user.amount = user.amount.add(swapInfo.amount);
        user.fee = user.fee.add(swapInfo.fee);
        emit NewSwap(
            swapInfo.token,
            swapInfo.user,
            msg.sender,
            swapInfo.amount,
            swapInfo.fee,
            swapInfo.chainIdFrom,
            chainId,
            swapInfo.hash
        );
        payable(swapInfo.user).transfer(msg.value);
    }

    function redeem(address token) public payable supportedToken(token) {
        User storage user = users[token][msg.sender];
        require(user.amount > 0, "ZyxBridge: nothing to withdraw");
        if (token == wzyx) {
            msg.sender.transfer(user.amount);
            payable(feeTo).transfer(user.fee);
        } else {
            IZYX20(token).mint(msg.sender, user.amount);
            IZYX20(token).mint(feeTo, user.fee);
        }
        user.totalRedeem = user.totalRedeem.add(user.amount);
        uint256 amount = user.amount;
        uint256 fee = user.fee;
        user.amount = 0;
        user.fee = 0;
        emit Redeem(token, msg.sender, amount, fee);
    }


    function deposit(address token, uint256 amount, int chainIdTo) public payable supportedToken(token) isPause {
        require(amount >= minLimitForSwap[token], "ZyxBridge: amount is too small");
        if (token == wzyx) {
            require(msg.value == amount, "ZyxBridge: amount and value are not exact");
        } else {
            IZYX20(token).burnFrom(msg.sender, amount);
        }
        emit NewDeposit(token, msg.sender, amount, chainId, chainIdTo);
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

    function migrate() public onlyOwner {
        uint256 currentBalance = address(this).balance;
        payable(migrator).transfer(currentBalance);
    }
}