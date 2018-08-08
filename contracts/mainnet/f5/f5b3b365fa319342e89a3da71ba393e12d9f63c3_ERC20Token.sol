/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
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
pragma solidity 0.4.21;
/// @title Utility Functions for uint
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0561646b6c606945696a6a75776c6b622b6a7762">[email&#160;protected]</a>>
library MathUint {
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function tolerantSub(uint a, uint b) internal pure returns (uint c) {
        return (a >= b) ? a - b : 0;
    }
    /// @dev calculate the square of Coefficient of Variation (CV)
    /// https://en.wikipedia.org/wiki/Coefficient_of_variation
    function cvsquare(
        uint[] arr,
        uint scale
        )
        internal
        pure
        returns (uint)
    {
        uint len = arr.length;
        require(len > 1);
        require(scale > 0);
        uint avg = 0;
        for (uint i = 0; i < len; i++) {
            avg += arr[i];
        }
        avg = avg / len;
        if (avg == 0) {
            return 0;
        }
        uint cvs = 0;
        uint s;
        uint item;
        for (i = 0; i < len; i++) {
            item = arr[i];
            s = item > avg ? item - avg : avg - item;
            cvs += mul(s, s);
        }
        return ((mul(mul(cvs, scale), scale) / avg) / avg) / (len - 1);
    }
}
/*
    Copyright 2017 Loopring Project Ltd (Loopring Foundation).
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
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
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
/// @title Utility Functions for address
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="aecacfc0c7cbc2eec2c1c1dedcc7c0c980c1dcc9">[email&#160;protected]</a>>
library AddressUtil {
    function isContract(address addr)
        internal
        view
        returns (bool)
    {
        if (addr == 0x0) {
            return false;
        } else {
            uint size;
            assembly { size := extcodesize(addr) }
            return size > 0;
        }
    }
}
/*
  Copyright 2017 Loopring Project Ltd (Loopring Foundation).
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
/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="284c4946414d4468444747585a41464f06475a4f">[email&#160;protected]</a>>
contract ERC20 {
    function balanceOf(address who) view public returns (uint256);
    function allowance(address owner, address spender) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}
/// @title ERC20 Token Implementation
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="cda9aca3a4a8a18da1a2a2bdbfa4a3aae3a2bfaa">[email&#160;protected]</a>>
contract ERC20Token is ERC20 {
    using MathUint for uint;
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint    public totalSupply_;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function ERC20Token(
        string  _name,
        string  _symbol,
        uint8   _decimals,
        uint    _totalSupply,
        address _firstHolder
        )
        public
    {
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        require(_totalSupply > 0);
        require(_firstHolder != 0x0);
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;
        balances[_firstHolder] = totalSupply_;
    }
    function () payable public
    {
        revert();
    }
    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(
        address _to,
        uint256 _value
        )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return balances[_owner];
    }
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
        )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(
        address _spender,
        uint256 _value
        )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint _addedValue
        )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
        )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}