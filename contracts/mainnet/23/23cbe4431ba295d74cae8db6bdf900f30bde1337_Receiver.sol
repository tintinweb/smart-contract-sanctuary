/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: contracts/Receiver.sol



pragma solidity ^0.8.0;


contract Receiver is Ownable {

    uint private _totalReceived;
    mapping(address => uint) private _paidByAddr;
    mapping(address => uint) private _percentByAddr;


    event Received(address indexed caller, uint amount, string message);
    event BalanceWithdraw(address indexed recipient, uint amount);

    constructor(address[] memory _addrs, uint[] memory _percents) {
        require(_addrs.length == _percents.length, "Receiver: two array args of constructor do not have a same length");
        uint sum;
        for(uint i=0; i < _addrs.length; i++) {
            _percentByAddr[_addrs[i]] = _percents[i];
            sum += _percents[i];
        }
        require(sum == uint(100), "Receiver: Sum is not 100%");
    }

    fallback() external payable {
        _totalReceived += msg.value;
        emit Received(_msgSender(), msg.value, "fallback was called");
    }

    receive() external payable {
        _totalReceived += msg.value;
        emit Received(_msgSender(), msg.value, "receive was called");
    } 

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getPercent(address _account) public view returns (uint) {
        return _percentByAddr[_account];
    }    

    function totalReceived() public view returns (uint) {
        return _totalReceived;
    }

    function getTotalByAddr(address _addr) public view returns (uint) {
        uint percent = _percentByAddr[_addr];
        return _totalReceived * percent / 100;
    }

    function getPaidByAddr(address _addr) public view returns (uint) {
        return _paidByAddr[_addr];
    }

    function getBalanceByAddr(address _addr) public view returns (uint) {
        return getTotalByAddr(_addr) - getPaidByAddr(_addr);
    }

    function withdrawByAddr() public returns (bool) {

        address recipient = payable(_msgSender());        
        uint percent = _percentByAddr[recipient];
        require(percent > 0, "Receiver: This address has no share");
        uint amount = getBalanceByAddr(recipient);
        _paidByAddr[recipient] += amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Receiver: Failed to send Ether");
        emit BalanceWithdraw(recipient, amount); 
        return true;
    }
}