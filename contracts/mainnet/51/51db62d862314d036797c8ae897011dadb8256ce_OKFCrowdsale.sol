pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }
    
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}

contract ERC20 {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function allowance(address owner, address spender) constant returns (uint256);
    function approve(address spender, uint256 value) returns (bool);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) returns(bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) returns(bool success) {
        uint oldValue = allowed[msg.sender][_spender];

        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        
        return true;
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

contract OKFToken is BurnableToken, Ownable {
    string public name = "KickingOff Cinema Token";
    string public symbol = "OKF";
    uint256 public decimals = 18;
    
    uint256 public INITIAL_SUPPLY = 11000000 * 1 ether;                                // Amount tokens

    function OKFToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}

contract OKFCrowdsale is Pausable {
    using SafeMath for uint;

    OKFToken public token;
    address public beneficiary = 0x97F795fbdEf69ee530d54e7Dc4eCDCc0244aAf00;        // Beneficiary 90%
    address public command = 0xEe7410eCf01988A61Ba2C3f66283c08859414F6B;            // Command 10%

    uint public collectedWei;
    uint public collectedUSD;
    uint public tokensSold;

    uint public tokensForSale = 10000000 * 1 ether;                                 // Amount tokens for sale
    uint public priceETHUSD = 250;                                                  // Ether price USD
    uint public softCapUSD = 1500000;                                               // Soft cap USD
    uint public hardCapUSD = 2500000;                                               // Hard cap USD
    uint public softCapWei = softCapUSD * 1 ether / priceETHUSD;
    uint public hardCapWei = hardCapUSD * 1 ether / priceETHUSD;
    uint public priceTokenWei = 1 ether / 1000;

    uint public startTime = 1507032000;                                             // Date start 03.10.2017 12:00 +0
    uint public endTime = 1517659200;                                               // Date end 03.02.2018 12:00 +0
    bool public crowdsaleFinished = false;

    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event SoftCapReached(uint256 etherAmount);
    event HardCapReached(uint256 etherAmount);
    event Withdraw();

    function OKFCrowdsale() {
        token = new OKFToken();
        require(token.transfer(0x915c517cB57fAB7C532262cB9f109C875bEd7d18, 1000000 * 1 ether));    // Bounty tokens
    }

    function() payable {
        purchase();
    }
    
    function purchase() whenNotPaused payable {
        require(!crowdsaleFinished);
        require(now >= startTime && now < endTime);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.001 * 1 ether);
        require(msg.value <= 50 * 1 ether);

        uint sum = msg.value;
        uint amount = sum.div(priceTokenWei).mul(1 ether);
        
        if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            uint retSum = retAmount.mul(priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);

            require(msg.sender.send(retSum));
        }

        require(token.transfer(msg.sender, amount));
        require(beneficiary.send(sum.div(100).mul(90)));
        require(command.send(sum.sub(sum.div(100).mul(90))));

        if(collectedWei < softCapWei && collectedWei.add(sum) >= softCapWei) {
            SoftCapReached(collectedWei);
        }

        if(collectedWei < hardCapWei && collectedWei.add(sum) >= hardCapWei) {
            HardCapReached(collectedWei);
        }

        tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);
        collectedUSD = collectedWei * priceETHUSD / 1 ether;

        NewContribution(msg.sender, amount, sum);
    }

    function withdraw() onlyOwner {
        require(!crowdsaleFinished);

        token.transfer(beneficiary, token.balanceOf(this));
        token.transferOwnership(beneficiary);
        crowdsaleFinished = true;

        Withdraw();
    }
}