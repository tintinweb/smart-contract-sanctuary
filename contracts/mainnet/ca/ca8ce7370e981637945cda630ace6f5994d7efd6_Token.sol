pragma solidity ^0.4.15;

contract Token {
    
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => address) public addresses;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public addressIndex;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public numberOfAddress = 0;
    
    string public physicalString;
    string public cryptoString;
    
    bool public isSecured;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    bool public canMintBurn;
    uint256 public txnTax;
    uint256 public holdingTax;
    //In Weeks, on Fridays
    uint256 public holdingTaxInterval;
    uint256 public lastHoldingTax;
    uint256 public holdingTaxDecimals = 2;
    bool public isPrivate;
    
    address public owner;
    
    function Token(string n, string a, uint256 totalSupplyToUse, bool isSecured, bool cMB, string physical, string crypto, uint256 txnTaxToUse, uint256 holdingTaxToUse, uint256 holdingTaxIntervalToUse, bool isPrivateToUse) {
        name = n;
        symbol = a;
        totalSupply = totalSupplyToUse;
        balanceOf[msg.sender] = totalSupplyToUse;
        isSecured = isSecured;
        physicalString = physical;
        cryptoString = crypto;
        canMintBurn = cMB;
        owner = msg.sender;
        txnTax = txnTaxToUse;
        holdingTax = holdingTaxToUse;
        holdingTaxInterval = holdingTaxIntervalToUse;
        if(holdingTaxInterval!=0) {
            lastHoldingTax = now;
            while(getHour(lastHoldingTax)!=21) {
                lastHoldingTax -= 1 hours;
            }
            while(getWeekday(lastHoldingTax)!=5) {
                lastHoldingTax -= 1 days;
            }
            lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
        }
        isPrivate = isPrivateToUse;
        
        addAddress(owner);
    }
    
    function transfer(address _to, uint256 _value) payable returns (bool success) {
        chargeHoldingTax();
        if (balanceOf[msg.sender] < _value) return false;
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;
        if (msg.sender != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                return false;
            }
        }
        if(isPrivate && msg.sender != owner && !addressExists[_to]) {
            return false;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        addAddress(_to);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(
         address _from,
         address _to,
         uint256 _amount
     ) payable returns (bool success) {
        if (_from != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                return false;
            }
        }
        if(isPrivate && _from != owner && !addressExists[_to]) {
            return false;
        }
        if (balanceOf[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balanceOf[_to] + _amount > balanceOf[_to]) {
            balanceOf[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balanceOf[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function changeTxnTax(uint256 _newValue) {
        if(msg.sender != owner) throw;
        txnTax = _newValue;
    }
    
    function mint(uint256 _value) {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] + _value < balanceOf[msg.sender]) throw;
            balanceOf[msg.sender] += _value;
            totalSupply += _value;
            Transfer(0, msg.sender, _value);
        }
    }
    
    function burn(uint256 _value) {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] < _value) throw;
            balanceOf[msg.sender] -= _value;
            totalSupply -= _value;
            Transfer(msg.sender, 0, _value);
        }
    }
    
    function chargeHoldingTax() {
        if(holdingTaxInterval!=0) {
            uint256 dateDif = now - lastHoldingTax;
            bool changed = false;
            while(dateDif >= holdingTaxInterval * (1 weeks)) {
                changed=true;
                dateDif -= holdingTaxInterval * (1 weeks);
                for(uint256 i = 0;i<numberOfAddress;i++) {
                    if(addresses[i]!=owner) {
                        uint256 amtOfTaxToPay = ((balanceOf[addresses[i]]) * holdingTax)  / (10**holdingTaxDecimals)/ (10**holdingTaxDecimals);
                        balanceOf[addresses[i]] -= amtOfTaxToPay;
                        balanceOf[owner] += amtOfTaxToPay;
                    }
                }
            }
            if(changed) {
                lastHoldingTax = now;
                while(getHour(lastHoldingTax)!=21) {
                    lastHoldingTax -= 1 hours;
                }
                while(getWeekday(lastHoldingTax)!=5) {
                    lastHoldingTax -= 1 days;
                }
                lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
            }
        }
    }
    
    function changeHoldingTax(uint256 _newValue) {
        if(msg.sender != owner) throw;
        holdingTax = _newValue;
    }
    
    function changeHoldingTaxInterval(uint256 _newValue) {
        if(msg.sender != owner) throw;
        holdingTaxInterval = _newValue;
    }
    
    function addAddress (address addr) private {
        if(!addressExists[addr]) {
            addressIndex[addr] = numberOfAddress;
            addresses[numberOfAddress++] = addr;
            addressExists[addr] = true;
        }
    }
    
    function addAddressManual (address addr) {
        if(msg.sender == owner && isPrivate) {
            addAddress(addr);
        } else {
            throw;
        }
    }
    
    function removeAddress (address addr) private {
        if(addressExists[addr]) {
            numberOfAddress--;
            addresses[addressIndex[addr]] = 0x0;
            addressExists[addr] = false;
        }
    }
    
    function removeAddressManual (address addr) {
        if(msg.sender == owner && isPrivate) {
            removeAddress(addr);
        } else {
            throw;
        }
    }
    
    function getWeekday(uint timestamp) returns (uint8) {
            return uint8((timestamp / 86400 + 4) % 7);
    }
    
    function getHour(uint timestamp) returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) returns (uint8) {
            return uint8(timestamp % 60);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}