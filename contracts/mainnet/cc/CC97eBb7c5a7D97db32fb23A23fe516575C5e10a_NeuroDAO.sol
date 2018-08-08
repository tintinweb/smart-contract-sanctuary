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

@author Ilya Svirin <<span class="__cf_email__" data-cfemail="e38acd90958a918a8da38d8c918782958a8d87cd9196">[email&#160;protected]</span>>

IF YOU ARE ENJOYED IT DONATE TO 0x3Ad38D1060d1c350aF29685B2b8Ec3eDE527452B ! :)
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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value);
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from, address to, uint value);
    function approve(address spender, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract ManualMigration is owned, ERC20 {

    uint    public freezedMoment;
    address public original;

    modifier enabled {
        require(original == 0);
        _;
    }
    
    struct SpecialTokenHolder {
        uint limit;
        bool isTeam;
    }
    mapping (address => SpecialTokenHolder) public specials;

    struct TokenHolder {
        uint balance;
        uint balanceBeforeUpdate;
        uint balanceUpdateTime;
    }
    mapping (address => TokenHolder) public holders;

    function ManualMigration(address _original) payable owned() {
        original = _original;
        totalSupply = ERC20(original).totalSupply();
        holders[this].balance = ERC20(original).balanceOf(original);
        holders[original].balance = totalSupply - holders[this].balance;
        Transfer(this, original, holders[original].balance);
    }

    function migrateManual(address _who, bool _isTeam) onlyOwner {
        require(original != 0);
        require(holders[_who].balance == 0);
        uint balance = ERC20(original).balanceOf(_who);
        holders[_who].balance = balance;
        specials[_who] = SpecialTokenHolder({limit: balance, isTeam:_isTeam});
        holders[original].balance -= balance;
        Transfer(original, _who, balance);
    }
    
    function sealManualMigration(bool force) onlyOwner {
        require(force || holders[original].balance == 0);
        delete original;
    }

    function beforeBalanceChanges(address _who) internal {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            holders[_who].balanceUpdateTime = now;
            holders[_who].balanceBeforeUpdate = holders[_who].balance;
        }
    }
}

contract Crowdsale is ManualMigration {
    
    function Crowdsale(address _original) payable ManualMigration(_original) {}

    function () payable enabled {
        require(holders[this].balance > 0);
        uint256 tokens = 5000 * msg.value / 1000000000000000000;
        if (tokens > holders[this].balance) {
            tokens = holders[this].balance;
            uint valueWei = tokens * 1000000000000000000 / 5000;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(holders[msg.sender].balance + tokens > holders[msg.sender].balance); // overflow
        require(tokens > 0);
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(this);
        holders[msg.sender].balance += tokens;
        specials[msg.sender].limit += tokens;
        holders[this].balance -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

contract Token is Crowdsale {

    string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;NeuroDAO&#39;;
    string  public symbol      = "NDAO";
    uint8   public decimals    = 0;

    uint    public startTime;

    mapping (address => mapping (address => uint256)) public allowed;

    event Burned(address indexed owner, uint256 value);

    function Token(address _original, uint _startTime)
        payable Crowdsale(_original) {
        startTime = _startTime;    
    }

    function availableTokens(address _who) public constant returns (uint _avail) {
        _avail = holders[_who].balance;
        uint limit = specials[_who].limit;
        if (limit != 0) {
            uint blocked;
            uint periods = firstYearPeriods();
            if (specials[_who].isTeam) {
                if (periods != 0) {
                    blocked = limit * (500 - periods) / 500;
                } else {
                    periods = (now - startTime) / 1 years;
                    ++periods;
                    if (periods < 5) {
                        blocked = limit * (100 - periods * 20) / 100;
                    }
                }
            } else {
                if (periods != 0) {
                    blocked = limit * (100 - periods) / 100;
                }
            }
            _avail -= blocked;
        }
    }
    
    function firstYearPeriods() internal constant returns (uint _periods) {
        _periods = 0;
        if (now < startTime + 1 years) {
            uint8[12] memory logic = [1, 2, 3, 4, 4, 4, 5, 6, 7, 8, 9, 10];
            _periods = logic[(now - startTime) / 28 days];
        }
    }

    function balanceOf(address _who) constant public returns (uint) {
        return holders[_who].balance;
    }

    function transfer(address _to, uint256 _value) public enabled {
        require(availableTokens(msg.sender) >= _value);
        require(holders[_to].balance + _value >= holders[_to].balance); // overflow
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(_to);
        holders[msg.sender].balance -= _value;
        holders[_to].balance += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public enabled {
        require(availableTokens(_from) >= _value);
        require(holders[_to].balance + _value >= holders[_to].balance); // overflow
        require(allowed[_from][msg.sender] >= _value);
        beforeBalanceChanges(_from);
        beforeBalanceChanges(_to);
        holders[_from].balance -= _value;
        holders[_to].balance += _value;
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
    
    function burn(uint256 _value) public enabled {
        require(holders[msg.sender].balance >= _value);
        beforeBalanceChanges(msg.sender);
        holders[msg.sender].balance -= _value;
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

    function TokenMigration(address _original, uint _startTime)
        payable Token(_original, _startTime) {}

    // Migrate _value of tokens to the new token contract
    function migrate() external {
        require(migrationAgent != 0);
        uint value = holders[msg.sender].balance;
        require(value != 0);
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(this);
        holders[msg.sender].balance -= value;
        holders[this].balance += value;
        totalMigrated += value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
        Transfer(msg.sender, this, value);
        Migrate(msg.sender, migrationAgent, value);
    }

    function setMigrationAgent(address _agent) external onlyOwner enabled {
        require(migrationAgent == 0);
        migrationAgent = _agent;
    }
}

contract NeuroDAO is TokenMigration {

    function NeuroDAO(address _original, uint _startTime)
        payable TokenMigration(_original, _startTime) {}
    
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    function freezeTheMoment() public onlyOwner {
        freezedMoment = now;
    }

    /** Get balance of _who for freezed moment
     *  freezeTheMoment()
     */
    function freezedBalanceOf(address _who) constant public returns(uint) {
        if (holders[_who].balanceUpdateTime <= freezedMoment) {
            return holders[_who].balance;
        } else {
            return holders[_who].balanceBeforeUpdate;
        }
    }
    
    function killMe() public onlyOwner {
        require(totalSupply == 0);
        selfdestruct(owner);
    }
}

contract Adapter is owned {
    
    address public neuroDAO;
    address public erc20contract;
    address public masterHolder;
    
    mapping (address => bool) public alreadyUsed;
    
    function Adapter(address _neuroDAO, address _erc20contract, address _masterHolder)
        payable owned() {
        neuroDAO = _neuroDAO;
        erc20contract = _erc20contract;
        masterHolder = _masterHolder;
    }
    
    function killMe() public onlyOwner {
        selfdestruct(owner);
    }
 
    /**
     * Move tokens int erc20contract to NDAO tokens holder
     * 
     * # Freeze balances in NeuroDAO smartcontract by calling freezeTheMoment() function.
     * # Allow transferFrom masterHolder in ERC20 smartcontract by calling approve() function
     *   from masterHolder address, gives this contract address as spender parameter.
     * # ERC20 smartcontract must have enougth tokens on masterHolder balance.
     */
    function giveMeTokens() public {
        require(!alreadyUsed[msg.sender]);
        uint balance = NeuroDAO(neuroDAO).freezedBalanceOf(msg.sender);
        ERC20(erc20contract).transferFrom(masterHolder, msg.sender, balance);
        alreadyUsed[msg.sender] = true;
    }
}