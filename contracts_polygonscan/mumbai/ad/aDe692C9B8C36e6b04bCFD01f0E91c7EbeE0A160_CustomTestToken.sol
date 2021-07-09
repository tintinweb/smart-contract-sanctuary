/**
 *Submitted for verification at polygonscan.com on 2021-07-09
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

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
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/protocol/interfaces/IERC20.sol

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

/**
 * @title IERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
interface IERC20 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply(
    )
    external
    view
    returns (uint256);

    function balanceOf(
        address who
    )
    external
    view
    returns (uint256);

    function allowance(
        address owner,
        address spender
    )
    external
    view
    returns (uint256);

    function transfer(
        address to,
        uint256 value
    )
    external
    returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    external
    returns (bool);

    function approve(
        address spender,
        uint256 value
    )
    external
    returns (bool);

    function name()
    external
    view
    returns (string memory);

    function symbol()
    external
    view
    returns (string memory);

    function decimals()
    external
    view
    returns (uint8);
}

// File: contracts/testing/TestToken.sol

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;



contract TestToken is IERC20 {
    using SafeMath for uint256;

    uint256 supply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Issue(address indexed token, address indexed owner, uint256 value);

    // Allow anyone to get new token
    function issue(uint256 amount) public {
        issueTo(msg.sender, amount);
    }

    function setBalance(address _target, uint _value) public {
        balances[_target] = _value;
        emit Transfer(address(0x0), _target, _value);
    }

    function addBalance(
        address _target,
        uint _value
    )
    public
    {
        uint currBalance = balanceOf(_target);
        require(_value + currBalance >= currBalance, "INVALID_VALUE");
        balances[_target] = currBalance.add(_value);
        emit Transfer(address(0x0), _target, _value);
    }

    function issueTo(address who, uint256 amount) public {
        supply = supply.add(amount);
        balances[who] = balances[who].add(amount);
        emit Issue(address(this), who, amount);
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function symbol() public view returns (string memory) {
        return "TEST";
    }

    function name() public view returns (string memory) {
        return "Test Token";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balances[msg.sender] >= value, "#transfer: INSUFFICIENT_BALANCE");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(
            msg.sender,
            to,
            value
        );
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(balances[from] >= value, "#transferFrom: INSUFFICIENT_BALANCE");
        require(allowed[from][msg.sender] >= value, "#transferFrom: INSUFFICIENT_ALLOWANCE");

        balances[to] = balances[to].add(value);
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(
            from,
            to,
            value
        );
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(
            msg.sender,
            spender,
            value
        );
        return true;
    }
}

// File: contracts/testing/CustomTestToken.sol

/*

    Copyright 2021 Dolomite

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;

contract CustomTestToken is TestToken {

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals
    ) public {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

}