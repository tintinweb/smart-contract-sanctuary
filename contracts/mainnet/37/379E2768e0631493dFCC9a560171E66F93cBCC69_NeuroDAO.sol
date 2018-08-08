/*
This file is part of the NeuroDAO Contract.

The NeuroDAO Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The NeuroDAO Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the NeuroDAO Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <<span class="__cf_email__" data-cfemail="fa93d4898c93889394ba9495889e9b8c93949ed4888f">[email&#160;protected]</span>>
*/


pragma solidity ^0.4.0;

contract owned {

    address public owner;
    address public newOwner;

    function owned() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}

contract Crowdsale is owned {
    
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function Crowdsale() payable owned() {
        totalSupply = 21000000;
        balanceOf[this] = 5000000;
        balanceOf[owner] = totalSupply - balanceOf[this];
        Transfer(this, owner, balanceOf[owner]);
    }

    function () payable {
        require(balanceOf[this] > 0);
        uint256 tokens = 5000 * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / 5000;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(balanceOf[msg.sender] + tokens > balanceOf[msg.sender]); // overflow
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is Crowdsale {
    
    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;NeuroDAO&#39;;
    string  public symbol      = "NDAO";
    uint8   public decimals    = 0;

    mapping (address => mapping (address => uint256)) public allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed owner, uint256 value);

    function Token() payable Crowdsale() {}

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burned(msg.sender, _value);
    }
}

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract TokenMigration is Token {
    
    address public migrationAgent;
    uint256 public totalMigrated;

    event Migrate(address indexed from, address indexed to, uint256 value);

    function TokenMigration() payable Token() {}

    // Migrate _value of tokens to the new token contract
    function migrate(uint256 _value) external {
        require(migrationAgent != 0);
        require(_value != 0);
        require(_value <= balanceOf[msg.sender]);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    function setMigrationAgent(address _agent) external onlyOwner {
        require(migrationAgent == 0);
        migrationAgent = _agent;
    }
}

contract NeuroDAO is TokenMigration {
    function NeuroDAO() payable TokenMigration() {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function killMe() public onlyOwner {
        require(totalSupply == 0);
        selfdestruct(owner);
    }
}