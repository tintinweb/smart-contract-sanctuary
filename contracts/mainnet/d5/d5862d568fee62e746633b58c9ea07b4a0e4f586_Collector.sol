/**
 *Submitted for verification at Etherscan.io on 2020-12-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

// Use context
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function isOwner(address account) public view returns (bool) {
        return _owner == account;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SafeMath default libray
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ICREW {
    function sendTokenFromPresale(address account, uint256 amount) external;
}

contract Collector is Ownable {
    using SafeMath for uint256;
     
    uint256 private _depositMinAmount;
    uint256 private _hardCap = 0;
    address private _crewAddress;

    mapping(address => uint256) _depositedAmounts;

    event Deposited(address account, uint256 amount);
    event SentToken(address account, uint256 amount);
    
    constructor(uint256 hardCap, uint256 depositMinAmount) {
        _depositMinAmount = depositMinAmount;
        _hardCap = hardCap;
    }    

    // get hard cap
    function getHardCap() external view returns (uint256) {
        return _hardCap;
    }

    // get min amount to deposite by user
    function getDepositeMinAmount() external view returns (uint256) {
        return _depositMinAmount;
    }

    // get user's deposited amount
    function getDepositedAmount(address account) external view returns (uint256) {
        return _depositedAmounts[account];
    }

    // get the total ether balance deposited by users
    function getTotalDepositedAmount() public view returns (uint256){
        return address(this).balance;
    }

    function setCrewAddress(address address_) public onlyOwner {
        _crewAddress = address_;
    }

    function getCrewAddress() public view returns (address) {
        return _crewAddress;
    }
    
    // fall back function to receive ether
    receive() external payable {
       _deposite();
    }
    
    function _deposite() private {
        require(!_isContract(_msgSender()), "Could not be a contract");
        require(!isOwner(_msgSender()), "You are onwer.");
        require(msg.value >= _depositMinAmount, "Should be great than minimum deposit amount.");
        require(getTotalDepositedAmount().add(msg.value) <= _hardCap, "Overflowed the hard cap.");

        uint256 ethValue = msg.value;
        _depositedAmounts[_msgSender()] = _depositedAmounts[_msgSender()].add(ethValue);
        emit Deposited(_msgSender(), msg.value);

        // send token to user
        uint256 amount = ethValue.mul(8888).div(1000);
        ICREW(_crewAddress).sendTokenFromPresale(_msgSender(), amount);

        emit SentToken(_msgSender(), amount);
    }

    // Withdraw eth to owner (colletor) when need it
    function withdraw() external payable onlyOwner {
        require(getTotalDepositedAmount() > 0, "Ether balance is zero.");
        msg.sender.transfer(getTotalDepositedAmount());
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}