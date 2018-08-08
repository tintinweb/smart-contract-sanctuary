pragma solidity ^0.4.18;
// адрес теста https://ropsten.etherscan.io/token/0x1fcbe22ce0c2d211c51866966152a70490dd8045?a=0x1fcbe22ce0c2d211c51866966152a70490dd8045
contract owned {

    address public owner;
    address public candidat;
   event OwnershipTransferred(address indexed _from, address indexed _to);

    function owned() public payable {
        owner = msg.sender;
    }
    
    function changeOwner(address _owner) public {
        require(owner == msg.sender);
        candidat = _owner;
    }
    function confirmOwner() public {
        require(candidat == msg.sender);
        emit OwnershipTransferred(owner,candidat);
        owner = candidat;
        candidat = address(0);
    }
}
 
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract ERC20Interface {
    //function totalSupply() public constant returns (uint);
    //function balanceOf(address tokenOwner) public constant returns (uint balance);
    //function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptoloans is ERC20Interface, owned {
    using SafeMath for uint256;
    //uint256 public totalSupply;
    //mapping (address => uint256) public balanceOf;
    //mapping (address => mapping (address => uint)) public allowance;

    //function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    //    require(state != State.Disabled);
    //    return allowance[_owner][_spender];
    //}

    //string  public standard    = &#39;Token 0.1&#39;;
    string  public name        = &#39;Cryptoloans&#39;;
    string  public symbol      = "LCN";
    uint8   public decimals    = 18;
    uint256 public tokensPerOneEther = 300;
    uint    public min_tokens = 30;

    // Fix for the ERC20 short address attack
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
    
    enum State { Disabled, TokenSale, Failed, Enabled }
    State   public state = State.Disabled;
    
    modifier inState(State _state) {
        require(state == _state);
        _;
    }    

    event NewState(State state);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function Cryptoloans() public payable owned() {
        totalSupply = 10000000 * 10**uint(decimals);
        balanceOf[this] = 540000 * 10**uint(decimals);
        balanceOf[owner] = totalSupply - balanceOf[this];
        emit Transfer(address(0), this, totalSupply);
        emit Transfer(this, owner, balanceOf[owner]);
    }

    function () public payable {
        require(state==State.TokenSale);
        require(balanceOf[this] > 0);
        uint256 tokens = tokensPerOneEther.mul(msg.value);//.div(1 ether);
        require(min_tokens.mul(10**uint(decimals))<=tokens || tokens > balanceOf[this]);
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint256 valueWei = tokens.div(tokensPerOneEther);
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokens);
        balanceOf[this] = balanceOf[this].sub(tokens);
        emit Transfer(this, msg.sender, tokens);
    }

	function _transfer(address _from, address _to, uint _value) internal
	{
        require(state != State.Disabled);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
	}
	
	
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns(bool success){
		_transfer(msg.sender,_to,_value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32)  returns(bool success){
        require(state != State.Disabled);
		require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint _value) public  returns(bool success){
        require(state != State.Disabled);
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }



    function withdrawBack() public { // failed tokensale
        require(state == State.Failed);
        require(balanceOf[msg.sender]>0);
        uint256 amount = balanceOf[msg.sender].div(tokensPerOneEther);// ethers wei
        uint256 balance_sender = balanceOf[msg.sender];
        
        require(address(this).balance>=amount && amount > 0);
        balanceOf[this] = balanceOf[this].add(balance_sender);
        balanceOf[msg.sender] = 0;
        emit Transfer(msg.sender, this,  balance_sender);
        msg.sender.transfer(amount);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender==owner);
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    
    function killMe() public {
        require(owner == msg.sender);
        selfdestruct(owner);
    }
    
    function startTokensSale(uint _volume_tokens, uint token_by_ether, uint min_in_token) public {
        require(owner == msg.sender);
        //require(state == State.Disabled);
        require((_volume_tokens * 10**uint(decimals))<(balanceOf[owner]+balanceOf[this]));
        tokensPerOneEther = token_by_ether;
        min_tokens = min_in_token;
        
        //if(balanceOf[this]>0)
        if(balanceOf[this]>(_volume_tokens * 10**uint(decimals)))
            emit Transfer(this, owner, balanceOf[this]-(_volume_tokens * 10**uint(decimals)));
        else if(balanceOf[this]<(_volume_tokens * 10**uint(decimals)))
            emit Transfer(owner, this, (_volume_tokens * 10**uint(decimals)) - balanceOf[this]);

        balanceOf[owner] = balanceOf[owner].add(balanceOf[this]).sub(_volume_tokens * 10**uint(decimals));
        balanceOf[this] = _volume_tokens * 10**uint(decimals);
        
        if (state != State.TokenSale)
        {
            state = State.TokenSale;
            emit NewState(state);
        }
    }
    

    function SetState(uint _state) public 
    {
        require(owner == msg.sender);
        State old = state;
        //require(state!=_state);
        if(_state==0)
            state = State.Disabled;
        else if(_state==1) 
            state = State.TokenSale;
        else if(_state==2) 
            state = State.Failed;
        else if(_state==3) 
            state = State.Enabled;
        if(old!=state)
            emit NewState(state);
    }
    

    function withdraw() public {
        require(owner == msg.sender);
        owner.transfer(address(this).balance);
    }

}