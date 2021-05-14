//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFoT {
    function mint(address to, uint256 value) external;
}

contract Presale is Ownable, Pausable {
    bool public privateSale = true;
    address public token;
    IFoT public fot;
    address payable public presale;
    address payable public liquidity;
    address public airdrop;
    address public dev;

    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public softCapEthAmount = 300 ether;
    uint256 public hardCapEthAmount = 500 ether;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositEthAmount = 0.5 ether;
    uint256 public maximumDepositEthAmount = 25 ether;

    mapping(address => uint256) public deposits;

    constructor(address payable _liquidity) {
        presale = payable(0x1f30356Bc014A692DDa90d18198B861c98d35A7F);
        airdrop = 0x315B97BAffA12B47F4C251b2985fc1a1979eA28A;
        dev = 0xb3d773430d3A13cFef4e42b7e3A9b0B7D827f025;
        liquidity = _liquidity;
    }

    function setToken(address _token) public onlyOwner {
        require(token == address(0), 'already set');
        token = _token;
        fot = IFoT(_token);
    }

    receive() external payable {
        if (privateSale == true) {
            depositPhase1();
        } else {
            depositPhase2();
        }
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function endPrivateSale() external onlyOwner {
        require(privateSale == true, 'Private sale is ended');
        privateSale = false;
        presaleStartTimestamp = block.timestamp;
        presaleEndTimestamp = block.timestamp + (2 weeks);
    }

    function depositPhase1() public payable whenNotPaused {
        require(privateSale == true, 'Private sale is ended');
        uint256 rewardTokenCount = 0.004 ether; // 250 tokens per ETH
        uint256 tokenAmount = (msg.value * (1e18)) / (rewardTokenCount);
        fot.mint(msg.sender, tokenAmount);
        emit Deposited(msg.sender, msg.value);
    }

    function depositPhase2() public payable whenNotPaused {
        require(privateSale == false, 'Private sale is not ended');
        require(
            block.timestamp >= presaleStartTimestamp && block.timestamp <= presaleEndTimestamp,
            'presale is not active'
        );
        require(totalDepositedEthBalance + (msg.value) <= hardCapEthAmount, 'deposit limits reached');
        require(
            deposits[msg.sender] + (msg.value) >= minimumDepositEthAmount &&
                deposits[msg.sender] + (msg.value) <= maximumDepositEthAmount,
            'incorrect amount'
        );

        uint256 rewardTokenCount;

        if (totalDepositedEthBalance <= softCapEthAmount) {
            rewardTokenCount = 0.00666 ether; // 150 tokens per ETH
        } else {
            rewardTokenCount = 0.01 ether; // 100 tokens per ETH
        }

        uint256 tokenAmount = (msg.value * (1e18)) / (rewardTokenCount);
        fot.mint(msg.sender, tokenAmount);
        fot.mint(airdrop, tokenAmount / (20));
        fot.mint(dev, tokenAmount / (20));
        totalDepositedEthBalance = totalDepositedEthBalance + (msg.value);
        deposits[msg.sender] = deposits[msg.sender] + (msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        require(privateSale == true, 'Private sale is ended');
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function releaseFunds() external onlyOwner {
        require(
            block.timestamp >= presaleEndTimestamp || totalDepositedEthBalance == hardCapEthAmount,
            'presale is active'
        );
        uint256 liquidityEth = address(this).balance / (2);
        presale.transfer(address(this).balance - (liquidityEth));
        liquidity.transfer(liquidityEth);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    constructor () {
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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