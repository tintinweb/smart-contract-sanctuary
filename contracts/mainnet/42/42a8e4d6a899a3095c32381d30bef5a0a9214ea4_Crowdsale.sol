/*! iam.sol | (c) 2018 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.4.21;

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

contract Withdrawable is Ownable {
    function withdrawEther(address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));
        require(this.balance >= _value);

        _to.transfer(_value);

        return true;
    }

    function withdrawTokens(ERC20 _token, address _to, uint _value) onlyOwner public returns(bool) {
        require(_to != address(0));

        return _token.transfer(_to, _value);
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
    ICO IAM
*/
contract Token is CappedToken, BurnableToken, Withdrawable {
    function Token() CappedToken(70000000 * 1 ether) StandardToken("IAM Aero", "IAM", 18) public {
        
    }

    function transferOwner(address _from, address _to, uint256 _value) onlyOwner canMint public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);

        return true;
    }
}

contract Crowdsale is Pausable, Withdrawable {
    using SafeMath for uint;

    struct Step {
        uint priceTokenWei;
        uint tokensForSale;
        uint minInvestEth;
        uint tokensSold;
        uint collectedWei;

        bool transferBalance;
        bool sale;
        bool issue;
    }

    Token public token;
    address public beneficiary = 0x4ae7bdf9530cdB666FC14DF79C169e14504c621A;

    Step[] public steps;
    uint8 public currentStep = 0;

    bool public crowdsaleClosed = false;

    mapping(address => uint256) public canSell;

    event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Issue(address indexed holder, uint256 tokenAmount);
    event Sell(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event NewRate(uint256 rate);
    event NextStep(uint8 step);
    event CrowdsaleClose();

    function Crowdsale() public {
        token = new Token();

        steps.push(Step(1 ether / 1000, 1000000 * 1 ether, 0.01 ether, 0, 0, true, false, true));
        steps.push(Step(1 ether / 1000, 1500000 * 1 ether, 0.01 ether, 0, 0, true, false, true));
        steps.push(Step(1 ether / 1000, 3000000 * 1 ether, 0.01 ether, 0, 0, true, false, true));
        steps.push(Step(1 ether / 1000, 9000000 * 1 ether, 0.01 ether, 0, 0, true, false, true));
        steps.push(Step(1 ether / 1000, 35000000 * 1 ether, 0.01 ether, 0, 0, true, false, true));
        steps.push(Step(1 ether / 1000, 20500000 * 1 ether, 0.01 ether, 0, 0, true, true, true));
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

        Step memory step = steps[currentStep];

        require(msg.value >= step.minInvestEth);
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

        if(currentStep == 0) {
            canSell[msg.sender] = canSell[msg.sender].add(amount);
        }

        if(step.transferBalance) {
            uint p1 = sum.div(200);
            (0xD8C7f2215f90463c158E91b92D81f0A1E3187C1B).transfer(p1.mul(3));
            (0x8C8d80effb2c5C1E4D857e286822E0E641cA3836).transfer(p1.mul(3));
            beneficiary.transfer(sum.sub(p1.mul(6)));
        }
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

        if(currentStep == 0) {
            canSell[_to] = canSell[_to].add(_value);
        }

        token.mint(_to, _value);

        Issue(_to, _value);
    }

    function sell(uint256 _value) whenNotPaused public {
        require(!crowdsaleClosed);

        require(canSell[msg.sender] >= _value);
        require(token.balanceOf(msg.sender) >= _value);

        Step memory step = steps[currentStep];
        
        require(step.sale);

        canSell[msg.sender] = canSell[msg.sender].sub(_value);
        token.transferOwner(msg.sender, beneficiary, _value);

        uint sum = _value.mul(step.priceTokenWei).div(1 ether);

        msg.sender.transfer(sum);

        Sell(msg.sender, _value, sum);
    }

    function nextStep(uint _value) onlyOwner public {
        require(!crowdsaleClosed);
        require(steps.length - 1 > currentStep);
        
        currentStep += 1;

        setTokenRate(_value);

        NextStep(currentStep);
    }

    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        
        beneficiary.transfer(this.balance);
        token.mint(beneficiary, token.cap().sub(token.totalSupply()));
        token.finishMinting();
        token.transferOwnership(beneficiary);

        crowdsaleClosed = true;

        CrowdsaleClose();
    }
}