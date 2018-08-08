pragma solidity ^0.4.13;

contract ERC20 {

    function totalSupply() constant returns (uint totalSupply);

    function balanceOf(address _owner) constant returns (uint balance);

    function transfer(address _to, uint _value) returns (bool success);

    function transferFrom(address _from, address _to, uint _value) returns (bool success);

    function approve(address _spender, uint _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint remaining);

    event Transfer(address indexed _from, address indexed _to, uint _value);

    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract owned {
    address public _owner;

    function owned() {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        _owner = newOwner;
    }
}

contract mortal is owned {
    function mortal() { 
    }

    function kill() onlyOwner {
        selfdestruct(_owner);
    }
}

contract hackethereumIco is mortal {
    uint256 public _amountRaised;
    uint256 public _deadline;

    uint256 private _timeBetweenWithdrawCalls;
    uint256 private _timeBetweenControlFlipCalls;

    uint256 private _priceIncrease1;
    uint256 private _priceIncrease2;

    bool private _hackedTenuous;
    bool private _hackedEducated;
    bool private _hackedAdept;
    bool private _whitehatActive;

    bool private _initialised;
    
    address private _beneficiary;
    address private _hackerTenuous;
    address private _hackerEducated;
    address private _hackerAdept;
    address private _hackerDecisive;
    address private _whitehat;

    uint256 private _lastHack;
    uint256 private _lastWhitehat;
    uint256 private _lastControlFlip;

    uint256 private _initialPrice;

    uint256 private constant _participationThreshold =  50000000000000000;
    uint256 private constant _participationMax       = 500000000000000000;

    uint256 private constant _hackTokenThreshold     =  10000000000000000;

    hackoin public _hackoinToken;
    hackoin public _tenuousToken;
    hackoin public _educatedToken;
    hackoin public _adeptToken;

    mapping(address => uint256) private _balanceOf;

    event FundTransfer(address indexed backer, string indexed transferType, uint256 amount);

    function hackethereumIco(
        address ifSuccessfulSendTo,
        address hackerTenuousAddress,
        address hackerEducatedAddress,
        address hackerAdeptAddress,
        address hackerDecisiveAddress,
        address whitehatAddress
        // uint256 durationInMinutes,
        // uint256 timeBetweenWithdrawMinutes,
        // uint256 timeBetweenFlipMinutes
        
    ) {
        _beneficiary = ifSuccessfulSendTo;
        _hackerTenuous = hackerTenuousAddress;
        _hackerEducated = hackerEducatedAddress;
        _hackerAdept = hackerAdeptAddress;
        _hackerDecisive = hackerDecisiveAddress;
        _whitehat = whitehatAddress;
    
        _initialised = false;
    }

    function initialise() onlyOwner {
        require(!_initialised);

        _deadline = 1504301337; // Fri, 01 Sep 2017 21:28:57 // now + durationInMinutes * 1 minutes; //1504231337

        _timeBetweenWithdrawCalls = 30 minutes;
        _timeBetweenControlFlipCalls = 300 minutes;

        _priceIncrease2 = _deadline - 4 days;
        _priceIncrease1 = _priceIncrease2 - 6 days;

        _lastHack = now;//_deadline + 1 days;
        _lastWhitehat = now;//_deadline + 1 days;
        _lastControlFlip = now;//_deadline + 1 days;

        _initialPrice = 1;

        address tokenContractAddress = new hackoin("Hackoin", "HK");
        _hackoinToken = hackoin(tokenContractAddress);

        address tenuousTokenContractAddress = new hackoin("Hackoin_Tenuous", "HKT");
        address educatedTokenContractAddress = new hackoin("Hackoin_Educated", "HKE");
        address adeptTokenContractAddress = new hackoin("Hackoin_Adept", "HKA");

        _tenuousToken = hackoin(tenuousTokenContractAddress);
        _educatedToken = hackoin(educatedTokenContractAddress);
        _adeptToken = hackoin(adeptTokenContractAddress);

        _hackoinToken.mintToken(msg.sender, _participationMax*2);
        _tenuousToken.mintToken(msg.sender, _hackTokenThreshold*2);
        _educatedToken.mintToken(msg.sender, _hackTokenThreshold*2);
        _adeptToken.mintToken(msg.sender, _hackTokenThreshold*2);
        _initialised = true;
    }

    function adjustTiming(uint256 timeBetweenWithdrawMinutes, uint256 timeBetweenFlipMinutes) onlyOwner {
        _timeBetweenWithdrawCalls = timeBetweenWithdrawMinutes * 1 minutes;
        _timeBetweenControlFlipCalls = timeBetweenFlipMinutes * 1 minutes;
    }

    function () payable {
        require(now < _deadline);

        uint256 amount = msg.value;

        uint256 currentPrice;
        if(now < _priceIncrease1)
        {
            currentPrice = _initialPrice;
        }
        else if (now < _priceIncrease2)
        {
            currentPrice = _initialPrice * 2;
        }
        else
        {
            currentPrice = _initialPrice * 4;
        }

        uint256 tokenAmount = amount / currentPrice;

        require(tokenAmount > 0);
        require(_balanceOf[msg.sender] + amount >= _balanceOf[msg.sender]);
        require(this.balance + amount >= this.balance);

        _balanceOf[msg.sender] += amount;
        _amountRaised += amount;

        _hackoinToken.mintToken(msg.sender, tokenAmount);
        FundTransfer(msg.sender, "Ticket Purchase", amount);
    }

    modifier afterDeadline()
    { 
        require (now >= _deadline); 
        _;
    }

    function withdrawFunds(uint256 amount) afterDeadline {
        require(_beneficiary == msg.sender);

        require(this.balance > 0);
        require(amount <= this.balance);

        if (_beneficiary.send(amount))
        {
            FundTransfer(_beneficiary, "Withdrawal", amount);
        }
    }

    function hackDecisive(address targetAddress, uint256 amount) afterDeadline {
        require(msg.data.length == 32*2+4);
        require(_hackerDecisive == msg.sender);

        require(_hackoinToken.balanceOf(targetAddress) >= _participationMax*2);

        require(this.balance > 0);
        require(amount <= this.balance);

        if (targetAddress.send(amount))
        {
            FundTransfer(targetAddress, "Decisive hack", amount);
        }
    }

    function whitehatRecover() afterDeadline {
        require(_whitehat == msg.sender);
        require(_whitehatActive);

        require(_lastWhitehat + _timeBetweenWithdrawCalls < now);

        require(this.balance > 0);

        uint amount;
        if(_amountRaised > 500 ether)
        {
            amount = _amountRaised / 50;
        }
        else if(_amountRaised > 100 ether)
        {
            amount = _amountRaised / 20;
        }
        else
        {
            amount = _amountRaised / 10;
        }
        
        if(amount > this.balance)
        {
            amount = this.balance;
        }

        _lastWhitehat = now;

        if (_whitehat.send(amount))
        {
            FundTransfer(_whitehat, "Whitehat recovery", amount);
        }
    }

    function hack(address targetAddress) afterDeadline {
        require(msg.data.length == 32+4);

        require(_hackerTenuous == msg.sender || _hackerEducated == msg.sender || _hackerAdept == msg.sender);
        require(_hackedTenuous);
        require(_hackedEducated);
        require(_hackedAdept);
        require(!_whitehatActive);

        require(_lastHack + _timeBetweenWithdrawCalls < now);

        require(this.balance > 0);

        require(_hackoinToken.balanceOf(targetAddress) >= _participationThreshold);

        require(_tenuousToken.balanceOf(targetAddress) >= _hackTokenThreshold);
        require(_educatedToken.balanceOf(targetAddress) >= _hackTokenThreshold);
        require(_adeptToken.balanceOf(targetAddress) >= _hackTokenThreshold);

        uint minAmount;
        if(_amountRaised > 500 ether)
        {
            minAmount = _amountRaised / 500;
        }
        else if(_amountRaised > 100 ether)
        {
            minAmount = _amountRaised / 200;
        }
        else
        {
            minAmount = _amountRaised / 100;
        }


        uint256 participationAmount = _hackoinToken.balanceOf(targetAddress);
        if(participationAmount > _participationMax)
        {
            participationAmount = _participationMax;
        }

        uint256 ratio = participationAmount / _participationThreshold;
        uint256 amount = minAmount * ratio;
        
        if(amount > this.balance)
        {
            amount = this.balance;
        }

        _lastHack = now;

        if (targetAddress.send(amount))
        {
            FundTransfer(targetAddress, "Hack", amount);
        }
    }

    function hackTenuous(address targetAddress) afterDeadline {
        require(msg.data.length == 32+4);
        require(_hackerTenuous == msg.sender);

        if(!_hackedTenuous) {
            require(_lastControlFlip + _timeBetweenControlFlipCalls < now);
        }

        _hackedTenuous = true;

        if(_tenuousToken.balanceOf(targetAddress) == 0) {
            _tenuousToken.mintToken(targetAddress, _hackTokenThreshold);
        }
    }

    function hackEducated(address targetAddress) afterDeadline {
        require(msg.data.length == 32+4);
        require(_hackerEducated == msg.sender);
        require(_hackedTenuous);

        if(!_hackedEducated) {
            require(_lastControlFlip + _timeBetweenControlFlipCalls < now);
        }

        _hackedEducated = true;

        if(_educatedToken.balanceOf(targetAddress) == 0) {
            _educatedToken.mintToken(targetAddress, _hackTokenThreshold);
        }
    }

    function hackAdept(address targetAddress) afterDeadline {
        require(msg.data.length == 32+4);
        require(_hackerAdept == msg.sender);
        require(_hackedTenuous && _hackedEducated);

        if(!_hackedAdept) {
            require(_lastControlFlip + _timeBetweenControlFlipCalls < now);
            _lastControlFlip = now;
        }

        _whitehatActive = false;
        _hackedAdept = true;

        if(_adeptToken.balanceOf(targetAddress) == 0) {
            _adeptToken.mintToken(targetAddress, _hackTokenThreshold);
        }
    }

    function whiteHat() afterDeadline {
        require(_whitehat == msg.sender);
        require(_lastControlFlip + _timeBetweenControlFlipCalls < now);
        _hackedTenuous = false;
        _hackedEducated = false;
        _hackedAdept = false;

        if(!_whitehatActive){
            _lastControlFlip = now;
        }

        _whitehatActive = true;
    }

    function kill() onlyOwner {
        _hackoinToken.kill();
        _tenuousToken.kill();
        _educatedToken.kill();
        _adeptToken.kill();
        mortal.kill();
    }

    // function transferHackoinTokenOwnership(address newOwner) onlyOwner afterDeadline {
    //     require(msg.data.length == 32+4);
    //     _hackoinToken.transferOwnership(newOwner);
    // }

    // function transferTenuousTokenOwnership(address newOwner) onlyOwner afterDeadline {
    //     require(msg.data.length == 32+4);
    //     _tenuousToken.transferOwnership(newOwner);
    // }

    // function transferEducatedTokenOwnership(address newOwner) onlyOwner afterDeadline {
    //     require(msg.data.length == 32+4);
    //     _educatedToken.transferOwnership(newOwner);
    // }

    // function transferAdeptTokenOwnership(address newOwner) onlyOwner afterDeadline {
    //     require(msg.data.length == 32+4);
    //     _adeptToken.transferOwnership(newOwner);
    // }
}

contract hackoin is ERC20, owned, mortal {
    string public name;
    string public symbol;
    uint8 public constant decimals = 16;

    uint256 public _totalSupply;


    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function hackoin(string _name, string _symbol) {
        name = _name;
        symbol = _symbol;
        _totalSupply = 0;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        require(msg.data.length == 32*2+4);

        require(balances[msg.sender] >= _value);
        require(_value > 0);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(msg.data.length == 32*3+4);

        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);
        require(_amount > 0);
        require(balances[_to] + _amount > balances[_to]);

        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        require(msg.data.length == 32*2+4);

        balances[target] += mintedAmount;
        _totalSupply += mintedAmount;
        Transfer(0, _owner, mintedAmount);
        Transfer(_owner, target, mintedAmount);
    }

    function totalSupply() constant returns (uint256 totalSupply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        require(msg.data.length == 32+4);
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require(msg.data.length == 32*2+4);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        require(msg.data.length == 32*2+4);
        return allowed[_owner][_spender];
    }
}