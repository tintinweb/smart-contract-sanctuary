/*! mlmc.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        OwnershipTransferred(owner, newOwner);
    }
}

contract Pausable is Ownable {
    bool public paused = false;

    event Pause();
    event Unpause();

    modifier whenNotPaused() { require(!paused); _; }
    modifier whenPaused() { require(paused); _; }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract ERC20 {
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns(uint256);
    function approve(address spender, uint256 value) public returns(bool);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function StandardToken(string _name, string _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function balanceOf(address _owner) public view returns(uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }
    
    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        require(_to.length == _value.length);

        for(uint i = 0; i < _to.length; i++) {
            transfer(_to[i], _value[i]);
        }

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
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

    modifier canMint() { require(!mintingFinished); _; }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);

        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;

        MintFinished();

        return true;
    }
}

contract CappedToken is MintableToken {
    uint256 public cap;

    function CappedToken(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        require(totalSupply.add(_amount) <= cap);

        return super.mint(_to, _amount);
    }
}

contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;

        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(burner, _value);
    }
}

/*
    ICO Multi level marketing coin
*/
contract Token is CappedToken, BurnableToken {
    function Token() CappedToken(1000000000 * 1 ether) StandardToken("World Online Sports Coin", "WOSC", 18) public {
        
    }
}

contract Crowdsale is Pausable {
    using SafeMath for uint;

    struct Step {
        uint priceTokenWei;
        uint tokensForSale;
        uint tokensSold;
        uint collectedWei;

        bool purchase;
        bool issue;
    }

    Token public token;
    address public beneficiary = 0x45674a9bB2ed1081C6c9798b30A1F72482c92Ac6;

    Step[] public steps;
    uint8 public currentStep = 0;

    bool public crowdsaleClosed = false;

    event NewRate(uint256 rate);
    event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Issue(address indexed holder, uint256 tokenAmount);
    event NextStep(uint8 step);
    event CrowdsaleClose();

    function Crowdsale() public {
        token = new Token();

        steps.push(Step(1e14, 200000000 ether, 0, 0, true, true));
        steps.push(Step(1e14, 300000000 ether, 0, 0, true, true));
        steps.push(Step(1e14, 400000000 ether, 0, 0, true, true));
    }

    function() payable public {
        purchase();
    }

    function setTokenRate(uint _value) onlyOwner public {
        require(!crowdsaleClosed);
        
        steps[currentStep].priceTokenWei = 1 ether / _value;

        NewRate(steps[currentStep].priceTokenWei);
    }
    
    function purchase() whenNotPaused payable public {
        require(!crowdsaleClosed);
        require(msg.value >= 0.001 ether);

        Step memory step = steps[currentStep];

        require(step.purchase);
        require(step.tokensSold < step.tokensForSale);

        uint sum = msg.value;
        uint amount = sum.mul(1 ether).div(step.priceTokenWei);
        uint retSum = 0;
        
        if(step.tokensSold.add(amount) > step.tokensForSale) {
            uint retAmount = step.tokensSold.add(amount).sub(step.tokensForSale);
            retSum = retAmount.mul(step.priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        steps[currentStep].tokensSold = step.tokensSold.add(amount);
        steps[currentStep].collectedWei = step.collectedWei.add(sum);

        beneficiary.transfer(sum);
        token.mint(msg.sender, amount);

        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }

        Purchase(msg.sender, amount, sum);
    }

    function issue(address _to, uint256 _value) onlyOwner whenNotPaused public {
        require(!crowdsaleClosed);

        Step memory step = steps[currentStep];
        
        require(step.issue);
        require(step.tokensSold.add(_value) <= step.tokensForSale);

        steps[currentStep].tokensSold = step.tokensSold.add(_value);

        token.mint(_to, _value);

        Issue(_to, _value);
    }

    function nextStep() onlyOwner public {
        require(!crowdsaleClosed);
        require(steps.length - 1 > currentStep);
        
        currentStep += 1;

        NextStep(currentStep);
    }

    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        
        token.mint(this, 100000000 ether);
        token.transferOwnership(beneficiary);

        crowdsaleClosed = true;

        CrowdsaleClose();
    }

    function withdrawTokens() onlyOwner public {
        require(crowdsaleClosed);
        require(now >= 1548990000); // 2019-02-01T00:00:00+00:00

        token.transfer(beneficiary, token.balanceOf(this));
    }
}