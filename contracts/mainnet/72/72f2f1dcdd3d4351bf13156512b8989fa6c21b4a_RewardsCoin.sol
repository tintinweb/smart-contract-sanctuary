pragma solidity ^0.4.18;

library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract owned {
    address public owner;

    function owned () public {
        owner = msg.sender; 
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { 
    function receiveApproval (address _from, uint256 _value, address _token, bytes _extraData) public; 
    
}

contract RewardsCoin is owned {
    using SafeMath for uint256;

    uint256 internal maxSupply;  
    string public name; 
    string public symbol; 
    uint256 public decimals;  
    uint256 public totalSupply; 
    address public beneficiary;
    address public dev1; 
    address public dev2;
    address public market1;
    address public market2; 
    address public bounty;
    address public lockedTokens;
    uint256 public burnt;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Burnfrom(address indexed _from, uint256 value);

    function RewardsCoin() public {
            
        name = "Rewards Coin";    
        symbol = "REW";    
        decimals = 18;
        burnt = 0;
        maxSupply = 25000000 * (10 ** decimals);   
        totalSupply = totalSupply.add(maxSupply);
        beneficiary = 0x89F2843837Ba5363b3550560184AC181924aCE4E;

        //Dev 1 Account
        dev1 = 0x4a194a5560a8DA2eaDAfc2F82B5793848685e1d3;

        //Dev 2 Account
        dev2 = 0x94e77bd7C7a53C533014d53F1965bea2BbD89744;

        //Advertising & Exchanges account
        market1 = 0xd08F5062378d4DC60127AF6c86AA5224678725DD;
        market2 = 0xA6f5C8AaD4f88894E7eA844C29AcebF5A1110435;

        //Bounties Account
        bounty = 0x6171a92418fFd0F7CD2687d83B323BaF6A2987A9;

        //Locked Tokens Account
        lockedTokens = 0x0778DDC022A0ffaB843c6F3Cb49763Bdeb7C79C4;

        //Distribution of Tokens to wallets
        balanceOf[beneficiary]  = balanceOf[beneficiary].add(maxSupply.sub(7500000 * (10 ** decimals))); //17,500,000 (ICO + Pre-sale)
        balanceOf[dev1]         = balanceOf[dev1].add(maxSupply.sub(24812500 * (10 ** decimals))); //187,500
        balanceOf[dev2]         = balanceOf[dev2].add(maxSupply.sub(24437500 * (10 ** decimals))); //562,500
        balanceOf[market1]      = balanceOf[market1].add(maxSupply.sub(24625000 * (10 ** decimals))); //375,000
        balanceOf[market2]      = balanceOf[market2].add(maxSupply.sub(24625000 * (10 ** decimals))); //375,000
        balanceOf[bounty]       = balanceOf[bounty].add(maxSupply.sub(24000000 * (10 ** decimals))); //1,000,000
        balanceOf[lockedTokens] = balanceOf[lockedTokens].add(maxSupply.sub(20000000 * (10 ** decimals))); //5,000,000

    }
    
    function nameChange(string _name, string _symbol) public onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address _to, uint256 _value) public {
        if (frozenAccount[msg.sender]) revert(); 
        if (balanceOf[msg.sender] < _value) revert() ;           
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);          
    }
    
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (frozenAccount[_from]) revert();                        // Check if frozen  
        if (balanceOf[_from] < _value) revert();                
        if (balanceOf[_to] + _value < balanceOf[_to]) revert(); 
        if (_value > allowance[_from][msg.sender]) revert(); 
        balanceOf[_to] = balanceOf[_to].sub(_value);                     
        balanceOf[_to] = balanceOf[_to].add(_value);                          
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function burn(uint256 _value) public {
        require(_value <= balanceOf[msg.sender]);
        address burner = msg.sender;
        balanceOf[burner] = balanceOf[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        burnt = burnt.add(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
  
    function burnFrom(address _from, uint256 _value) public onlyOwner returns  (bool success) {
        require (balanceOf[_from] >= _value);            
        require (msg.sender == owner);   
        totalSupply = totalSupply.sub(_value);
        burnt = burnt.add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);                      
        emit Burnfrom(_from, _value);
        return true;
    }
    
    function freezeAccount(address target) public onlyOwner {
        require (msg.sender == owner);   // Check allowance
        frozenAccount[target] = true;
        emit FrozenFunds(target, true);
    }
    
    function unFreezeAccount(address target) public onlyOwner {
        require (msg.sender == owner);   // Check allowance
        require(frozenAccount[target]);
        frozenAccount[target] = false;
        emit FrozenFunds(target, false);
    }

    function () private {
        revert();  
    }
}