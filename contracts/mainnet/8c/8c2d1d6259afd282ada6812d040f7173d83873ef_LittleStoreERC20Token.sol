/*
This Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This Contract is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.
You should have received a copy of the GNU lesser General Public License
<http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.18;

contract InterfaceERC20Token
{
    function balanceOf (address tokenOwner) public constant returns (uint balance);
    function transfer (address to, uint tokens) public returns (bool success);
    function allowance (address _owner, address _spender) public constant returns (uint remaining);
    function transferFrom (address _from, address _to, uint _value) public returns (bool success);
}

contract LittleStoreERC20Token
{

    mapping (address => bool) public agents;
    address public addressERC20Token;
    InterfaceERC20Token internal ERC20Token;

    bool public sale;
    uint public price;
    uint public bonusLine;
    uint public bonusSize;

    event ChangePermission (address indexed _called, address indexed _to, bool _permission);
    event ChangeSaleSettings (address indexed _called, address indexed _token, uint _price, uint _bonusLine, uint _bonusSize);
    event Buy (address indexed _called, address indexed _token, uint _count, uint _bonusCount, uint _value);
    event Donate (address indexed _from, uint _value);

    function LittleStoreERC20Token () public
    {
        agents[msg.sender] = true;
        sale = true;
    }

    modifier onlyAdministrators ()
    {
        require (agents[msg.sender]);
        _;
    }

    function changePermission (address _agent, bool _permission) public onlyAdministrators ()
    {
        if (msg.sender != _agent)
        {
            agents[_agent] = _permission;
            ChangePermission (msg.sender, _agent, _permission);
        }
    }

    function changeSaleSettings (address _addressERC20Token, uint _priceGwei, uint _bonusLine, uint _bonusSize) public onlyAdministrators ()
    {
        addressERC20Token = _addressERC20Token;
        ERC20Token = InterfaceERC20Token (_addressERC20Token);
        price = _priceGwei * 1000000000; //calculation of gwei in wei
        bonusLine = _bonusLine;
        bonusSize = _bonusSize;
        ChangeSaleSettings (msg.sender, _addressERC20Token, _priceGwei * 1000000000, _bonusLine, _bonusSize);
    }

    function saleValve (bool _sale) public onlyAdministrators ()
    {
        sale = _sale;
    }

    function allowanceTransfer () public onlyAdministrators ()
    {
        ERC20Token.transferFrom (msg.sender, this, ERC20Token.allowance (msg.sender, this));
    }

    function withdrawalToken (address _to) public onlyAdministrators ()
    {
        ERC20Token.transfer (_to, ERC20Token.balanceOf (this));
    }

    function withdrawal (address _to) public onlyAdministrators ()
    {
        _to.transfer (this.balance);
    }
    
    function destroy (address _to) public onlyAdministrators ()
    {
        withdrawalToken (_to);
        selfdestruct (_to);
    }

    function totalSale () public constant returns (uint)
    {
        return ERC20Token.balanceOf (this); 
    }

    function () payable
    {
       Donate (msg.sender, msg.value);
    }

    function buy () payable
    {
        uint thisBalance = ERC20Token.balanceOf (this);
        require (thisBalance > 0 && sale);
        
        uint countToken;
        uint countBonusToken;
        
        countToken = msg.value / price;
        require (countToken > 0);
        
        if (thisBalance > countToken)
        {
            thisBalance -= countToken;
            countBonusToken = (countToken / bonusLine) * bonusSize;
            
            if (countBonusToken > 0 && thisBalance <= countBonusToken)
            {
                countBonusToken = thisBalance;
            }
        }
        else
        {
            countToken = thisBalance;
        }
            
        require (ERC20Token.transfer (msg.sender, countToken + countBonusToken));
        msg.sender.transfer (msg.value - (countToken * price));
        Buy (msg.sender, addressERC20Token, countToken, countBonusToken, msg.value);
    }
}