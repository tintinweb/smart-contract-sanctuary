pragma solidity ^0.4.21;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) { return 0; }
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
        require(newOwner != address(this));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
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
contract StandardToken is ERC20{
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    mapping(address => uint256) public balances;
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
        require(_to != address(this));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
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
        require(_to != address(this));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}
contract MintableToken is StandardToken, Ownable{
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;
    modifier canMint(){require(!mintingFinished); _;}
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
		emit Mint(_to, _amount);
        emit Transfer(address(this), _to, _amount);
        return true;
    }
    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        emit MintFinished();
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
        emit Burn(burner, _value);
    }
}
contract RewardToken is StandardToken, Ownable {
    struct Payment {
        uint time;
        uint amount;
    }
    Payment[] public repayments;
    mapping(address => Payment[]) public rewards;

    event Reward(address indexed to, uint256 amount);

    function repayment() onlyOwner payable public {
        require(msg.value >= 0.000085 * 1 ether);
        repayments.push(Payment({time : now, amount : msg.value}));
    }
    function _reward(address _to) private returns(bool) {
        if(rewards[_to].length < repayments.length) {
            uint sum = 0;
            for(uint i = rewards[_to].length; i < repayments.length; i++) {
                uint amount = balances[_to] > 0 ? (repayments[i].amount * balances[_to] / totalSupply) : 0;
                rewards[_to].push(Payment({time : now, amount : amount}));
                sum += amount;
            }
            if(sum > 0) {
                _to.transfer(sum);
                emit Reward(_to, sum);
            }
            return true;
        }
        return false;
    }
    function reward() public returns(bool) {
        return _reward(msg.sender);
    }
    function transfer(address _to, uint256 _value) public returns(bool) {
        _reward(msg.sender);
        _reward(_to);
        return super.transfer(_to, _value);
    }
    function multiTransfer(address[] _to, uint256[] _value) public returns(bool) {
        _reward(msg.sender);
        for(uint i = 0; i < _to.length; i++) {
            _reward(_to[i]);
        }
        return super.multiTransfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        _reward(_from);
        _reward(_to);
        return super.transferFrom(_from, _to, _value);
    }
}
contract Token is CappedToken, BurnableToken, RewardToken {
    function Token() CappedToken(1000000000 * 1 ether) StandardToken("JULLAR", "JUL", 18) public {
        
    }
}
contract JullarCrowdsale is Ownable{
    using SafeMath for uint;
    Token public token;
    address private BeneficiaryA = 0x87CC179C88B593Ff7DBDD1B6e9A9F7437Df1880E; 
    address private BenefB = 0x8ae64056f409BbC00ed03eDC6B350eaB7d842A15; 
    address private JullarBountyAdr = 0xA2Df1e14632Ed83B1e7A35848dAe7c8623e1D030; // BountyAddress	
    address private JullarPartnersAdr = 0x3d6D84c26a11Ed1123dB68791c80aa7F7ce767C8; // Partner
    uint public collectedWei;
	address[] public JullarTeamAdr;
	string public ActiveSalesPhase = "Super PreICO"; // Stage Name
	
    string public TokenPriceETH = "0.000085";  
	uint public tokensSold = 0; 
	uint private tokensForSale = 20000000 * 1 ether; 
	uint public priceTokenWei = 85000000000000;  // 0.000085 ETH = 1 JUL superPreICO
	
	uint private Sb = 1 ether;
    uint private oSbA = Sb * 10000000; // BeneficiaryA 10m JUL
    uint private oSbB = Sb * 10000000; // BeneficiaryB 10m JUL
	
    uint private JULLARbounty = Sb * 20000000; // BountyAmout 20m JUL
    uint private JULLARpartner = Sb * 10000000; // Partners 10m JUL
    bool public crowdsaleClosed = false;
    event Rurchase(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    event CrowdsaleClose();
	bool public paused = false;
	uint public pausestatus = 1;
    event Pause();
    event StartNextIcoStage();
	
	function pause() onlyOwner public  {
        pausestatus = 0;
		paused = true;
        emit Pause();
    }	
	function JullarCrowdsale() public {
     token = new Token();	
	 emit Rurchase(BeneficiaryA, oSbA, 0);
	 emit Rurchase(BenefB, oSbB, 0);
	 emit Rurchase(JullarBountyAdr, JULLARbounty, 0);
	 emit Rurchase(JullarPartnersAdr, JULLARpartner, 0);
	 token.mint(BeneficiaryA, oSbA);
	 token.mint(BenefB, oSbB);
	 token.mint(JullarBountyAdr, JULLARbounty);
	 token.mint(JullarPartnersAdr, JULLARpartner);
	}
    function() payable public {
		if(crowdsaleClosed == false){
		       purchase();
		}
    }	
	function purchase() payable public {		
		require(pausestatus != 0);
        require(!crowdsaleClosed);
        require(tokensSold < tokensForSale);
        require(msg.value >= 0.000085 * 1 ether); 
        uint sum = msg.value;         
        uint amount = sum.mul(1 ether).div(priceTokenWei);
        uint retSum = 0;
        if(tokensSold.add(amount) > tokensForSale) {
            uint retAmount = tokensSold.add(amount).sub(tokensForSale);
            retSum = retAmount.mul(priceTokenWei).div(1 ether);
            amount = amount.sub(retAmount);
            sum = sum.sub(retSum);
        }
		tokensSold = tokensSold.add(amount);
        collectedWei = collectedWei.add(sum);
        token.mint(msg.sender, amount);
        if(retSum > 0) {
            msg.sender.transfer(retSum);
        }
        emit Rurchase(msg.sender, amount, sum);		
    }

	function StartNextStage() onlyOwner public {
        require(!crowdsaleClosed);
        require(pausestatus != 1);
		pausestatus = 1;
        paused = false;
        emit StartNextIcoStage();
    }

	function NewStage(uint _newpricewei, string _stagename, string _TokenPriceETH, uint _TokenForSale) onlyOwner public  {
		require(!crowdsaleClosed);
        require(pausestatus != 1);
		tokensForSale = _TokenForSale * 1 ether;
		ActiveSalesPhase = _stagename;
		priceTokenWei = _newpricewei; 
		TokenPriceETH = _TokenPriceETH;
	}
	
	function AddAdrJullarTeam(address _address) onlyOwner public{
		require(JullarTeamAdr.length < 6);
		JullarTeamAdr.push(_address);
	}
	
	function WithdrawalofFunds(uint _arraynum) onlyOwner public {
		require(_arraynum / 1 ether < 6);
        JullarTeamAdr[_arraynum].transfer(address(this).balance);
	}

    function closeCrowdsale() onlyOwner public {
        require(!crowdsaleClosed);
		uint bensum = address(this).balance / 2;		
        BeneficiaryA.transfer(bensum);
        BenefB.transfer(bensum);
        token.mint(BeneficiaryA, token.cap().sub(token.totalSupply()));
        token.transferOwnership(BeneficiaryA);
        crowdsaleClosed = true;
        emit CrowdsaleClose();
    }
}