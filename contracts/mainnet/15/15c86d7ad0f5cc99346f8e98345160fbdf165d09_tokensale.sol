pragma solidity ^0.4.10;

contract Token {
    
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => address) public addresses;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public addressIndex;
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
    
    function transfer(address _to, uint256 _value) payable {
        chargeHoldingTax();
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (msg.sender != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                throw;
            }
        }
        if(isPrivate && msg.sender != owner && !addressExists[_to]) {
            throw;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        addAddress(_to);
        Transfer(msg.sender, _to, _value);
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
}

contract tokensale {
    
    Token public token;
    uint256 public totalSupply;
    uint256 public numberOfTokens;
    uint256 public numberOfTokensLeft;
    uint256 public pricePerToken;
    uint256 public tokensFromPresale = 0;
    uint256 public tokensFromPreviousTokensale = 0;
    uint8 public decimals = 2;
    uint256 public withdrawLimit = 200000000000000000000;
    
    address public owner;
    string public name;
    string public symbol;
    
    address public finalAddress = 0x5904957d25D0c6213491882a64765967F88BCCC7;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public addressExists;
    mapping (uint256 => address) public addresses;
    mapping (address => uint256) public addressIndex;
    uint256 public numberOfAddress = 0;
    
    mapping (uint256 => uint256) public dates;
    mapping (uint256 => uint256) public percents;
    uint256 public numberOfDates = 8;
    
    tokensale ps = tokensale(0xa67d97d75eE175e05BB1FB17529FD772eE8E9030);
    tokensale pts = tokensale(0xED6c0654cD61De5b1355Ae4e9d9C786005e9D5BD);
    
    function tokensale(address tokenAddress, uint256 noOfTokens, uint256 prPerToken) {
        dates[0] = 1505520000;
        dates[1] = 1506038400;
        dates[2] = 1506124800;
        dates[3] = 1506816000;
        dates[4] = 1507420800;
        dates[5] = 1508112000;
        dates[6] = 1508630400;
        dates[7] = 1508803200;
        percents[0] = 35000;
        percents[1] = 20000;
        percents[2] = 10000;
        percents[3] = 5000;
        percents[4] = 2500;
        percents[5] = 0;
        percents[6] = 9001;
        percents[7] = 9001;
        token = Token(tokenAddress);
        numberOfTokens = noOfTokens * 100;
        totalSupply = noOfTokens * 100;
        numberOfTokensLeft = noOfTokens * 100;
        pricePerToken = prPerToken;
        owner = msg.sender;
        name = "Autonio ICO";
        symbol = "NIO";
        updatePresaleNumbers();
    }
    
    function addAddress (address addr) private {
        if(!addressExists[addr]) {
            addressIndex[addr] = numberOfAddress;
            addresses[numberOfAddress++] = addr;
            addressExists[addr] = true;
        }
    }
    
    function endPresale() {
        if(msg.sender == owner) {
            if(now > dates[numberOfDates-1]) {
                finish();
            } else if(numberOfTokensLeft == 0) {
                finish();
            } else {
                throw;
            }
        } else {
            throw;
        }
    }
    
    function finish() private {
        if(!finalAddress.send(this.balance)) {
            throw;
        }
    }
    
    function withdraw(uint256 amount) {
        if(msg.sender == owner) {
            if(amount <= withdrawLimit) {
                withdrawLimit-=amount;
                if(!finalAddress.send(amount)) {
                    throw;
                }
            } else {
                throw;
            }
        } else {
            throw;
        }
    }
    
    function updatePresaleNumbers() {
        if(msg.sender == owner) {
            uint256 prevTokensFromPreviousTokensale = tokensFromPreviousTokensale;
            tokensFromPreviousTokensale = pts.numberOfTokens() - pts.numberOfTokensLeft();
            uint256 diff = tokensFromPreviousTokensale - prevTokensFromPreviousTokensale;
            numberOfTokensLeft -= diff;
        } else {
            throw;
        }
    }
    
    function () payable {
        uint256 prevTokensFromPreviousTokensale = tokensFromPreviousTokensale;
        tokensFromPreviousTokensale = pts.numberOfTokens() - pts.numberOfTokensLeft();
        uint256 diff = tokensFromPreviousTokensale - prevTokensFromPreviousTokensale;
        numberOfTokensLeft -= diff;
        
        uint256 weiSent = msg.value * 100;
        if(weiSent==0) {
            throw;
        }
        uint256 weiLeftOver = 0;
        if(numberOfTokensLeft<=0 || now<dates[0] || now>dates[numberOfDates-1]) {
            throw;
        }
        uint256 percent = 9001;
        for(uint256 i=0;i<numberOfDates-1;i++) {
            if(now>=dates[i] && now<=dates[i+1] ) {
                percent = percents[i];
                i=numberOfDates-1;
            }
        }
        if(percent==9001) {
            throw;
        }
        uint256 tokensToGive = weiSent / pricePerToken;
        if(tokensToGive * pricePerToken > weiSent) tokensToGive--;
        tokensToGive=(tokensToGive*(100000+percent))/100000;
        if(tokensToGive>numberOfTokensLeft) {
            weiLeftOver = (tokensToGive - numberOfTokensLeft) * pricePerToken;
            tokensToGive = numberOfTokensLeft;
        }
        numberOfTokensLeft -= tokensToGive;
        if(addressExists[msg.sender]) {
            balanceOf[msg.sender] += tokensToGive;
        } else {
            addAddress(msg.sender);
            balanceOf[msg.sender] = tokensToGive;
        }
        Transfer(0x0,msg.sender,tokensToGive);
        if(weiLeftOver>0)msg.sender.send(weiLeftOver);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}