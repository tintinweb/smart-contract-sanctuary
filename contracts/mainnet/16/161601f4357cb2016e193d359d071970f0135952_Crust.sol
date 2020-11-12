// File: localhost/contracts/interfaces/IMiniMeToken.sol

pragma solidity 0.4.24;

interface IMiniMeToken {
    function decimals() external view returns(uint8);
    function balanceOf(address _account) external view returns(uint256);
    function balanceOfAt(address _account, uint256 _block) external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function totalSupplyAt(uint256 _block) external view returns(uint256);
}
// File: @aragon/os/contracts/lib/math/SafeMath.sol

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// File: localhost/contracts/Crust.sol

pragma solidity 0.4.24;



// ❤️ Thanks Rohini for coming up with the name
contract Crust is IMiniMeToken {
    using SafeMath for uint256;
    IMiniMeToken[] public crumbs;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(address[] memory _crumbs, string _name, string _symbol, uint8 _decimals) public {
        require(_crumbs.length > 0, "Crust.constructor: Crust must at least have one crumb");
        for(uint256 i = 0; i < _crumbs.length; i ++) {
            crumbs.push(IMiniMeToken(_crumbs[i]));
            require(crumbs[i].decimals() == _decimals, "Crumbs must have same number of decimals as crust");
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
    * @notice Tells the balance of `_account`.
    * @param _account Address of the account.
    * @return The balance of the account.
    */
    function balanceOf(address _account) external view returns(uint256) {
        return this.balanceOfAt(_account, block.number);
    }

    /**
    * @notice Tells the balance of `_account` at block `_block`.
    * @param _account Address of the account.
    * @param _block Block number.
    * @return The balance of the account.
    */
    function balanceOfAt(address _account, uint256 _block) external view returns(uint256) {
        uint256 result = 0;
        for(uint256 i = 0; i < crumbs.length; i++) {
            result = result.add(crumbs[i].balanceOfAt(_account, _block));
        }
        return result;
    }

    /**
    * @notice Tells the total supply of this token.
    * @return The total supply.
    */
    function totalSupply() external view returns(uint256) {
        return this.totalSupplyAt(block.number);
    }

    /**
    * @notice Tells the total supply of this token at block `_block`.
    * @return The total supply.
    */
    function totalSupplyAt(uint256 _block) external view returns(uint256) {
        uint256 result = 0;
        for(uint256 i = 0; i < crumbs.length; i++) {
            result = result.add(crumbs[i].totalSupplyAt(_block));
        }
        return result;
    }

    /**
    * @notice Gets the amount of decimals.
    * @dev Necesary because otherwise typechain does not generate working artifacts
    */
    function decimals() external view returns(uint8) {
        return decimals;
    }
}