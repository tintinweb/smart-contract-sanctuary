// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./libraries/SafeMath.sol";

contract Erc20Token {
    using SafeMath for uint256;
    uint256 public totalSupply;
    uint8 public decimals; //
    string public name; //
    string public symbol; //

    mapping(address => uint256) balances; //

    mapping(address => mapping(address => uint256)) allowed; //

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(
        uint256 _totalSupply,
        uint8 _decimals,
        string memory _name,
        string memory _symbol,
        address _adminAddress
    ) {
        totalSupply = SafeMath.mul(_totalSupply, 10**uint256(_decimals));
        balances[_adminAddress] = totalSupply;
        name = _name;
        decimals = _decimals;
        symbol = _symbol;
        emit Transfer(address(0), _adminAddress, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "to address error");
        require(balances[msg.sender] >= value, "lack of balance");
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(allowed[from][msg.sender] >= value, "lack of allowed");
        require(balances[from] >= value, "lack of balance");
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
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
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }
}