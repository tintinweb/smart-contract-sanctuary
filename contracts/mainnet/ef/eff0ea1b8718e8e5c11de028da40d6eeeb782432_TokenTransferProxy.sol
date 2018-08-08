/*

  Copyright 2018 Ethfinex Inc

  This is a derivative work based on software developed by ZeroEx Intl
  This and the original are licensed under Apache License, Version 2.0

  Original attribution:

  Copyright 2017 ZeroEx Intl.

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

pragma solidity 0.4.19;

interface Token {

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint);

    event Transfer(address indexed _from, address indexed _to, uint _value); // solhint-disable-line
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


//solhint-disable-next-line
/// @title TokenTransferProxy - Transfers tokens on behalf of exchange
/// @author Ahmed Ali <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="77361f1a121337151e03111e19120f5914181a">[email&#160;protected]</a>>
contract TokenTransferProxy {

    modifier onlyExchange {
        require(msg.sender == exchangeAddress);
        _;
    }

    address public exchangeAddress;


    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);

    function TokenTransferProxy() public {
        setExchange(msg.sender);
    }
    /*
     * Public functions
     */

    /// @dev Calls into ERC20 Token contract, invoking transferFrom.
    /// @param token Address of token to transfer.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param value Amount of token to transfer.
    /// @return Success of transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyExchange
        returns (bool)
    {
        return Token(token).transferFrom(from, to, value);
    }

    /// @dev Used to set exchange address
    /// @param _exchange the address of the exchange
    function setExchange(address _exchange) internal {
        require(exchangeAddress == address(0));
        exchangeAddress = _exchange;
    }
}