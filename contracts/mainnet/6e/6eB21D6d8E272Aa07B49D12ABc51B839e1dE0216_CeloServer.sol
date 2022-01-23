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
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefV1 {
    function withdraw(uint256 _pid, uint256 _amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBridgeAdapter {
    function bridge() external;
}

abstract contract BaseServer is Ownable {
    IMasterChefV1 public constant masterchefV1 =
        IMasterChefV1(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IERC20 public constant sushi =
        IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);

    uint256 public immutable pid;

    address public immutable minichef;

    address public bridgeAdapter;

    event Harvested(uint256 indexed pid);
    event Withdrawn(uint256 indexed pid, uint256 indexed amount);
    event Deposited(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnSushi(uint256 indexed pid, uint256 indexed amount);
    event WithdrawnDummyToken(uint256 indexed pid);
    event BridgeUpdated(address indexed newBridgeAdapter);

    constructor(uint256 _pid, address _minichef) {
        pid = _pid;
        minichef = _minichef;
        bridgeAdapter = address(this);
    }

    function harvestAndBridge() public {
        masterchefV1.withdraw(pid, 0);
        bridge();
        emit Harvested(pid);
    }

    function withdraw() public onlyOwner {
        masterchefV1.withdraw(pid, 1);
        emit Withdrawn(pid, 1);
    }

    function deposit(address token) public onlyOwner {
        IERC20(token).approve(address(masterchefV1), 1);
        masterchefV1.deposit(pid, 1);
        emit Deposited(pid, 1);
    }

    function withdrawSushiToken(address recipient) public onlyOwner {
        uint256 sushiBalance = sushi.balanceOf(address(this));
        sushi.transfer(recipient, sushiBalance);
        emit WithdrawnSushi(pid, sushiBalance);
    }

    function withdrawDummyToken(address token, address recipient)
        public
        onlyOwner
    {
        IERC20(token).transfer(recipient, 1);
        emit WithdrawnDummyToken(pid);
    }

    function updateBridgeAdapter(address newBridgeAdapter) public onlyOwner {
        require(newBridgeAdapter != address(0), "zero address");
        bridgeAdapter = newBridgeAdapter;
        emit BridgeUpdated(newBridgeAdapter);
    }

    function bridge() public {
        if (bridgeAdapter == address(this)) {
            _bridge();
        } else {
            uint256 sushiBalance = sushi.balanceOf(address(this));
            sushi.transfer(bridgeAdapter, sushiBalance);
            IBridgeAdapter(bridgeAdapter).bridge();
        }
    }

    function _bridge() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../BaseServer.sol";

interface ICeloBridge {
    function send(
        address _token,
        uint256 _amount,
        uint32 _destination,
        bytes32 _recipient
    ) external;
}

contract CeloServer is BaseServer {
    address public constant bridgeAddr =
        0x4fc16De11deAc71E8b2Db539d82d93BE4b486892;

    event BridgedSushi(address indexed minichef, uint256 indexed amount);

    constructor(uint256 _pid, address _minichef) BaseServer(_pid, _minichef) {}

    function _bridge() internal override {
        uint256 sushiBalance = sushi.balanceOf(address(this));

        sushi.approve(bridgeAddr, sushiBalance);
        ICeloBridge(bridgeAddr).send(
            address(sushi),
            sushiBalance,
            1667591279,
            bytes32(uint256(uint160(minichef)))
        );
        emit BridgedSushi(minichef, sushiBalance);
    }
}