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
    modifier notMint() { require(mintingFinished); _; }

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

ICO Gap

    - Crowdsale goes in 4 steps:
    - 1st step PreSale 0: the administrator can issue tokens; purchase and sale are closed; Max. tokens 5 000 000
    - 2nd step PreSale 1: the administrator can not issue tokens; the sale is open; purchase is closed; Max. tokens 5 000 000 + 10 000 000
    - The third step of PreSale 2: the administrator can not issue tokens; the sale is open; purchase is closed; Max. tokens 5 000 000 + 10 000 000 + 15 000 000
    - 4th step ICO: administrator can not issue tokens; the sale is open; the purchase is open; Max. tokens 5 000 000 + 10 000 000 + 15 000 000 + 30 000 000

    Addition:
    - Total emissions are limited: 100,000,000 tokens
    - at each step it is possible to change the price of the token
    - the steps are not limited in time and the step change is made by the nextStep administrator
    - funds are accumulated on a contract basis
    - at any time closeCrowdsale can be called: the funds and management of the token are transferred to the beneficiary; the release of + 65% of tokens to the beneficiary; minting closes
    - at any time, refundCrowdsale can be called: funds remain on the contract; withdraw becomes unavailable; there is an opportunity to get refund 
    - transfer of tokens before closeCrowdsale is unavailable
    - you can buy no more than 500 000 tokens for 1 purse.
*/

contract Token is CappedToken, BurnableToken {
    function Token() CappedToken(100000000 * 1 ether) StandardToken("GAP Token", "GAP", 18) public {
        
    }
    
    function transfer(address _to, uint256 _value) notMint public returns(bool) {
        return super.transfer(_to, _value);
    }
    
    function multiTransfer(address[] _to, uint256[] _value) notMint public returns(bool) {
        return super.multiTransfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) notMint public returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burnOwner(address _from, uint256 _value) onlyOwner canMint public {
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(_from, _value);
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
        bool sale;
    }

    Token public token;
    address public beneficiary = 0x4B97b2938844A775538eF0b75F08648C4BD6fFFA;

    Step[] public steps;
    uint8 public currentStep = 0;

    bool public crowdsaleClosed = false;
    bool public crowdsaleRefund = false;
    uint public refundedWei;

    mapping(address => uint256) public canSell;
    mapping(address => uint256) public purchaseBalances; 

    event Purchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Sell(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event Issue(address indexed holder, uint256 tokenAmount);
    event Refund(address indexed holder, uint256 etherAmount);
    event NextStep(uint8 step);
    event CrowdsaleClose();
    event CrowdsaleRefund();

    function Crowdsale() public {
        token = new Token();

        steps.push(Step(1 ether / 1000, 5000000 * 1 ether, 0, 0, false, true, false));
        steps.push(Step(1 ether / 1000, 10000000 * 1 ether, 0, 0, true, false, false));
        steps.push(Step(1 ether / 500, 15000000 * 1 ether, 0, 0, true, false, false));
        steps.push(Step(1 ether / 100, 30000000 * 1 ether, 0, 0, true, false, true));
    }

    function() payable public {
        purchase();
    }

    function setTokenRate(uint _value) onlyOwner whenPaused public {
        require(!crowdsaleClosed);
        steps[currentStep].priceTokenWei = 1 ether / _value;
    }
    
    function purchase() whenNotPaused payable public {
        require(!crowdsaleClosed);
        require(msg.value >= 0.001 ether);

        Step memory step = steps[currentStep];

        require(step.purchase);
        require(step.tokensSold < step.tokensForSale);
        require(token.balanceOf(msg.sender) < 500000 ether);

        uint sum = msg.value;
        uint amount = sum.mul(1 ether).div(step.priceTokenWei);
        uint retSum = 0;
        uint retAmount;
        
        if(step.tokensSold.add(amount) > step.tokensForSale) {
            retAmount = step.tokensSold.add(amount).sub(step.tokensForSale);
            retSum = retAmount.mul(step.priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        if(token.balanceOf(msg.sender).add(amount) > 500000 ether) {
            retAmount = token.balanceOf(msg.sender).add(amount).sub(500000 ether);
            retSum = retAmount.mul(step.priceTokenWei).div(1 ether);

            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }

        steps[currentStep].tokensSold = step.tokensSold.add(amount);
        steps[currentStep].collectedWei = step.collectedWei.add(sum);
        purchaseBalances[msg.sender] = purchaseBalances[msg.sender].add(sum);

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
        canSell[_to] = canSell[_to].add(_value).div(100).mul(20);

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
        token.burnOwner(msg.sender, _value);

        uint sum = _value.mul(step.priceTokenWei).div(1 ether);

        msg.sender.transfer(sum);

        Sell(msg.sender, _value, sum);
    }
    
    function refund() public {
        require(crowdsaleRefund);
        require(purchaseBalances[msg.sender] > 0);

        uint sum = purchaseBalances[msg.sender];

        purchaseBalances[msg.sender] = 0;
        refundedWei = refundedWei.add(sum);

        msg.sender.transfer(sum);
        
        Refund(msg.sender, sum);
    }

    function nextStep() onlyOwner public {
        require(!crowdsaleClosed);
        require(steps.length - 1 > currentStep);
        
        currentStep += 1;

        NextStep(currentStep);
    }

    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
        
        beneficiary.transfer(this.balance);
        token.mint(beneficiary, token.totalSupply().div(100).mul(65));
        token.finishMinting();
        token.transferOwnership(beneficiary);

        crowdsaleClosed = true;

        CrowdsaleClose();
    }

    function refundCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);

        crowdsaleRefund = true;
        crowdsaleClosed = true;

        CrowdsaleRefund();
    }
}