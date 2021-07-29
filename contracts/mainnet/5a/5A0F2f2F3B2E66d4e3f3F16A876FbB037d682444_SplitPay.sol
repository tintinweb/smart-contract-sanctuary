/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/SplitPay.sol

// contracts/SplitPay.sol
pragma solidity 0.8.6;

contract SplitPay is Ownable {

  event Deposit(address indexed receiver, uint256 amount, uint256 receiverPerc);
  event DepositReferral(address indexed receiver, address indexed referral, uint256 amount, uint256 receiverPerc, uint256 referralPerc);
  event Withdraw(address indexed receiver, uint256 amount);

  mapping(address => uint256) private deposited;

  function depositsOf(address addr) external view returns (uint256) {
    return deposited[addr];
  }

  function deposit(address receiver, uint256 receiverPerc) external payable {
    require(receiver != address(0));
    require(receiverPerc <= 100, "Percentage is higher than 100");
    uint256 amount = msg.value;
    require(amount != 0, "Can not deposit 0 wei");

    uint256 receiverAmount = amount * receiverPerc / 100;
    deposited[receiver] += receiverAmount;
    address owner = owner();
    deposited[owner] += amount - receiverAmount;
    emit Deposit(receiver, amount, receiverPerc);
  }

  function depositReferral(address receiver, uint256 receiverPerc, address referral, uint256 referralPerc) external payable {
    require(receiver != address(0));
    require(referral != address(0));
    uint256 amount = msg.value;
    require(amount != 0, "Can not split deposit 0 wei");
    require(receiverPerc + referralPerc <= 100, "Percentages add up to more than 100");

    uint256 receiverAmount = amount * receiverPerc / 100;
    uint256 referralAmount = amount * referralPerc / 100;
    deposited[receiver] += receiverAmount;
    deposited[referral] += referralAmount;
    address owner = owner();
    deposited[owner] += amount - receiverAmount - referralAmount;
    emit DepositReferral(receiver, referral, amount, receiverPerc, referralPerc);
  }

  function withdraw() external {
    address sender = msg.sender;
    uint256 amount = deposited[sender];
    require(address(this).balance >= amount, "Contract balance too low");
    deposited[sender] = 0;
    (bool success, ) = sender.call{value: amount}("");
    require(success, "Transfer failed, recipient may have reverted.");
    emit Withdraw(sender, amount);
  }
}