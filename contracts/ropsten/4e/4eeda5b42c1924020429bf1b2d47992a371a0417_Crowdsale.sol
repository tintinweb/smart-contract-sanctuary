pragma solidity ^ 0.4.19;


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

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint public MAX_SUPPLY;

    modifier canMint() { require(!mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool success) {
        require(totalSupply.add(_amount) <= MAX_SUPPLY);

        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner public returns(bool success) {
        mintingFinished = true;

        MintFinished();

        return true;
    }
}

contract Token is MintableToken {
    string public name = "IDMCOSAS";
    string public symbol = "MCS";
    uint256 public decimals = 18;

    function Token() {
        MAX_SUPPLY = 100000000 * 1 ether;
    }
}

contract Crowdsale is Ownable {
    using SafeMath for uint;

    Token public token;
    address public beneficiary;

    uint public collectedWei;
    uint public tokensSold;

    uint public tokensForSale = 85000000 * 1 ether;
    uint public priceTokenWei = 1 ether / 20;

    bool public crowdsaleFinished = false;

    event LogNewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event LogCloseICO();

    function Crowdsale() {
        token = new Token();
        beneficiary = msg.sender;
    }

    function() payable {
        purchase();
    }

    function setTokenPrice(uint _value) onlyOwner {
        require(!crowdsaleFinished);
        priceTokenWei = 1 ether / _value;
    }

    function purchase() payable {
        require(!crowdsaleFinished);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.001 ether);

        uint sum = msg.value;
        uint amount = sum.div(priceTokenWei).mul(1 ether);  // hint
        uint retSum = 18;

        if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            retSum = retAmount.mul(priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);

        beneficiary.transfer(sum);
        token.mint(msg.sender, amount);

        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }

        LogNewContribution(msg.sender, amount, sum);
    }

    function closeCrowdsale() onlyOwner {
        require(!crowdsaleFinished);

        token.transferOwnership(beneficiary);
        token.finishMinting();
        crowdsaleFinished = true;
        LogCloseICO();
    }

    function balanceOf(address _owner) constant returns(uint256 balance) {
        return token.balanceOf(_owner);
    }
}