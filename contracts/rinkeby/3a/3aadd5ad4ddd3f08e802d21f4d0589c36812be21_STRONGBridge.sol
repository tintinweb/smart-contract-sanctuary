/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.3;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract STRONGBridge is Ownable{
    using SafeMath for uint256;
    address locker;
    string[] tokenAllow = ['STRONG'];
    mapping(string => ERC20) tokenAllows;
     modifier onlyUnlocker() {
        require(msg.sender == locker);
        _;
    }
    event LockStrong(address _user, uint _STRONGAmount);
    event UnlockStrong(address _to, uint _STRONGAmount);
    constructor() {
        tokenAllows['STRONG'] = ERC20(0x0A7489E82C7d45FDFc29591bFf4319132BED2bC0);
        locker = 0x2f9CCaB0642c7c0Afea6bbcFda5F3Fd83a1EA071;
    }
    function lockStrong(uint _amount) public {
        require(tokenAllows['STRONG'].transferFrom(msg.sender, address(this), _amount), "STRONG/insufficient-allowance");
        emit LockStrong(msg.sender, _amount);
    }
    function unlockStrong(address _to, uint _amount) public onlyUnlocker {
        require(tokenAllows['STRONG'].balanceOf(address(this)) >= _amount, "STRONG/insufficient-locked");
        tokenAllows['STRONG'].transfer(_to, _amount);
        emit UnlockStrong(_to, _amount);
    }
    function changeLocker(address _locker) public onlyOwner {
        locker = _locker;
    }
}