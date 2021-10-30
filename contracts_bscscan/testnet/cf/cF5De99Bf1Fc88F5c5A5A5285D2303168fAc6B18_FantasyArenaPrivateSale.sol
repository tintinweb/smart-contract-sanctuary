/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract FantasyArenaPrivateSale {
    using SafeMath for uint256;
        
    IERC20 private fasyToken;
    address public owner;
    bool public presaleEnabled;
    uint256 public fasyPerBnb;
    uint256 public maxPurchase;
    uint256 public minPurchase;
    mapping (address => bool) public whitelist;
    mapping (address => uint256) public purchased;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "no permissions");
        _;
    }
    
    modifier onWhitelist() {
        require(whitelist[msg.sender], "this address is not on the whitelist");
        _;
    }
    
    modifier isPresaleEnabled() {
        require(presaleEnabled, "presale not enabled");
        _;
    }
    
    constructor() {
        fasyToken = IERC20(0x9BeBC64004bc867Cb0eD7d6595A10FD9cFBA624A);
        owner = msg.sender;
        fasyPerBnb = 100;
        maxPurchase = 4000000000000000000;
        minPurchase = 200000000000000000;
    }
    
    function userStatus() public view returns (bool, uint256) {
        return (whitelist[msg.sender], purchased[msg.sender]);
    }
    
    function preview(uint256 value) public view onWhitelist isPresaleEnabled returns (uint256) {
        uint256 receivedFasy = value.mul(fasyPerBnb);
        uint256 p = purchased[msg.sender].add(value);
        require(fasyToken.balanceOf(address(this)) >= receivedFasy, "not enough tokens left");
        require(p <= maxPurchase, "you cannot purchase this many tokens");
        require(p >= minPurchase, "minimum spend not met");
        return value.mul(fasyPerBnb);
    }

    function exchange(uint256 expected) public payable onWhitelist isPresaleEnabled {
        uint256 receivedFasy = msg.value.mul(fasyPerBnb);
        require(fasyToken.balanceOf(address(this)) >= receivedFasy, "not enough tokens left");
        require(receivedFasy == expected, "rate has changed");
        uint256 p = purchased[msg.sender].add(msg.value);
        require(p <= maxPurchase, "you cannot purchase this many tokens");
        require(p >= minPurchase, "minimum spend not met");
        purchased[msg.sender] = p;
        fasyToken.transfer(msg.sender, receivedFasy);
    }
    
    // Admin methods
    function changeOwner(address who) public onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }
    
    function configure(uint256 _fasyPerBnb, uint256 _minPurchase, uint256 _maxPurchase) public onlyOwner {
        fasyPerBnb = _fasyPerBnb;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    function enablePresale(bool enabled) public onlyOwner {
        presaleEnabled = enabled;
    }
    
    function removeBnb() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function transferTokens(address token, address to) public onlyOwner returns(bool){
        require(token != address(this), "You cannot remove the native token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        return IERC20(token).transfer(to, balance);
    }
    
    function editWhitelist(address who, bool whitelisted) public onlyOwner {
        whitelist[who] = whitelisted;
    }
    
    function bulkAddWhitelist(address[] memory people) public onlyOwner {
        for (uint256 i = 0; i < people.length; i++) {
            editWhitelist(people[i], true);
        }
    }
}