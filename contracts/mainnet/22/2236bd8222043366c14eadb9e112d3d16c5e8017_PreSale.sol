/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

// SPDX-License-Identifier: UNLICENSED

//openzeppelin-contracts/contracts/access/roles

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

// File: contracts\open-zeppelin-contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Context {

    constructor () internal { }
   
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a onlyOwner to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are onlyOwner (who can also remove
 * it).
 */
contract WhitelistedRole is Ownable {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyOwner {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyOwner {
        _removeWhitelisted(account);
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }

}

/**
 * @title PreSale
 * @dev Presale contract accept ether from whitelsted address. there are certain condition must be required to fulfill.
 * Private Sale target set 30 ETH 
 */
contract PreSale is WhitelistedRole {

    using SafeMath for uint256;
    mapping (address => uint256) public investors;
    address payable investorWallet;
    uint256 public collectedEther;

    /**
     * @dev Constructor.
     * @param _investorWallet address able to withdraw investment
     */
    constructor(address payable _investorWallet) public payable {
        investorWallet = _investorWallet;
        
        // <!-- Whitelisted wallet -->
        _addWhitelisted(0xD8b3b1b185c9A278BD20265c846a5F4c1010CD0f);
        _addWhitelisted(0x2d55748cE1b792d1Ba65f42AFcF189fdc386BBcF);
        _addWhitelisted(0xEF9EFf0479d57032cda12e0d6bBEDb55B9b8c9E7);
        _addWhitelisted(0xdF55AcD44102FA7dd9C1b7f95ADC2eDB1129B8d8);
        _addWhitelisted(0xBfe663805129915942980bC86BD832aB031Bb2f9);
        _addWhitelisted(0x5fd8Eb9B9958E88698fa64F0e4a418f6C9C563e2);
        _addWhitelisted(0xcC174625b93437098591C6B1d3b526F730cb6346);
        _addWhitelisted(0xc221f41c08656E9Fd49141306a9365FF8702b8A5);
        _addWhitelisted(0x1C5f7635a4A302d72E652486907051f84cd55005);
        _addWhitelisted(0x0E49d6eC5E22daA59bC845B3353D81E59A45eE0d);
        _addWhitelisted(0xEf92D1638b63dd82BD744fFfb96f9d46B0eEc50E);
        _addWhitelisted(0xA50341f5e72eD061cD0adbD338cbF070DC45784C);
        _addWhitelisted(0x29Bf6652e795C360f7605be0FcD8b8e4F29a52d4);
        _addWhitelisted(0xdb820EdEe02c9ee0D9a95910AF34031f17989660);
        _addWhitelisted(0xE12D52275eB64FF18680aA2b081Fef8b736CD66d);
        _addWhitelisted(0xAE5d528177A6273dC022ecA11496B89298e4654F);
        _addWhitelisted(0xA59c52b97c2cDcbBe9D5fCB3240233e3868314C1);
        _addWhitelisted(0x7C0Bf6BB2356aAaa60C04072C73a5DBe67dAc25e);
        _addWhitelisted(0x6F1E02F7853a7614F11C1909ED00310713d2E5cf);
        _addWhitelisted(0x1F4a6756Da7592fc0f9a031D127d016ACc0BfcB2);
        _addWhitelisted(0xD8c91ec53E8d236F9a15D6B42e878393bF413515);
        _addWhitelisted(0xfD026dFFfDf66BBecfC9F8bc26caf2A425ea0467);

    }

    // It is important to also provide the
    // `payable` keyword here, otherwise the function will
    // automatically reject all Ether sent to it.
    function () payable external onlyWhitelisted {
        require(2 ether <= msg.value &&  msg.value <= 5 ether, "Ether investment range must be required between 2 to 5 ether.");
        require(collectedEther <= 30 ether, "Pre Sale target fulfilled, Unable to accept more funds.");
        
        investors[_msgSender()] = investors[_msgSender()].add(msg.value);

        collectedEther = collectedEther.add(msg.value);
    }
    
    // WithDraw ether 
    function withDraw() public onlyOwner returns (bool) {
        investorWallet.transfer(collectedEther);
        collectedEther = 0;
        return true;
    }

}