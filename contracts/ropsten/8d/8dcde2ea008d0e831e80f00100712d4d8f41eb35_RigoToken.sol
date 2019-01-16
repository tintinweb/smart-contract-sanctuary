/*

 Copyright 2017-2018 RigoBlock, Rigo Investment Sagl.

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

pragma solidity 0.4.25;
pragma experimental "v0.5.0";

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface ERC20Face {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract ERC20 is ERC20Face {

    function transfer(address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success)
    {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        external
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function balanceOf(address _owner)
        external
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    uint256 public totalSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract UnlimitedAllowanceToken is ERC20 {

    uint256 constant MAX_UINT = 2**256 - 1;

    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(
            balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        );
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }
}

/// @title Rigo Token - Rules of the Rigo token.
/// @author Gabriele Rigo - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0562646745776c626a67696a666e2b666a68">[email&#160;protected]</a>>
/// @notice UnlimitedAllowanceToken is ERC20
contract RigoToken is UnlimitedAllowanceToken, SafeMath {

    string constant public name = "Rigo Token";
    string constant public symbol = "GRG";
    uint8 constant public decimals = 18;

    uint256 public totalSupply = 10**25; // 10 million tokens, 18 decimal places
    address public minter;
    address public rigoblock;

    /*
     * EVENTS
     */
    event TokenMinted(address indexed recipient, uint256 amount);

    /*
     * MODIFIERS
     */
    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    modifier onlyRigoblock {
        require(msg.sender == rigoblock);
        _;
    }

    constructor(address _setMinter, address _setRigoblock) public {
        minter = _setMinter;
        rigoblock = _setRigoblock;
        balances[msg.sender] = totalSupply;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @dev Allows minter to create new tokens
    /// @param _recipient Address of who receives new tokens
    /// @param _amount Number of new tokens
    function mintToken(
        address _recipient,
        uint256 _amount)
        external
        onlyMinter
    {
        balances[_recipient] = safeAdd(balances[_recipient], _amount);
        totalSupply = safeAdd(totalSupply, _amount);
        emit TokenMinted(_recipient, _amount);
    }

    /// @dev Allows rigoblock dao to change minter
    /// @param _newAddress Address of the new minter
    function changeMintingAddress(address _newAddress)
        external
        onlyRigoblock
    {
        minter = _newAddress;
    }

    /// @dev Allows rigoblock dao to upgrade dao
    /// @param _newAddress Address of the new rigoblock dao
    function changeRigoblockAddress(address _newAddress)
        external
        onlyRigoblock
    {
        rigoblock = _newAddress;
    }
}