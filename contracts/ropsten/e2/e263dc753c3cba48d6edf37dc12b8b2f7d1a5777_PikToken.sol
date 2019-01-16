pragma solidity 0.4.25;
   
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
    
    contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PikToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    string public constant name = "Pik Token";
    string public constant symbol = "PIK";
    uint public constant decimals = 8;
    
        uint256 public totalSupply          = 20000000000e8;
        uint256 public tokensForSale        = 10000000000e8;
        uint256 public tokensForTeam        = 1400000000e8;
        uint256 public tokensForOwner       = 2000000000e8;
        uint256 public tokensForAdvisor     = 400000000e8;
        uint256 public tokensForDevelopment = 2400000000e8;
        uint256 public tokensForMarketing   = 1400000000e8;
        uint256 public totalDistributed;
        uint256 public totalTokenSold; 
        uint256 public totalWeiReceived;
        uint256 public constant requestMinimum = 1 ether / 100;
        uint256 public tokensPerEth = 20000000e8;
        uint public deadline = 9999999999999;
        uint public round1   = 99999999999;
        
        address public teamWallet = 0xbe3bccedd52aab5f96bcc6496da560a39aa6edc1;
        address public ownerWallet = 0x887f8959ebd83cc61f4ade9eea577267ec7e86e5;
        address public advisorWallet = 0x31a863dee1aab223f2d87478fed06d84341034a8;
        address public developmentWallet = 0x144f543448755094048ffe0927e017c8262fcc19;
        address public marketingWallet = 0x55f4425321e491b2fdb15945c62ec7722f6e0c98;
        
        address multisig = 0x144f543448755094048Ffe0927e017c8262fcc19;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event ICOStarted();
    
    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);
    event FrozenFunds(address target, bool frozen);
    

    bool public distributionFinished = false;
    bool public icoStarted = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function startICO() onlyOwner public returns (bool) {
        icoStarted = true;
        distributionFinished = false;
        emit ICOStarted();
        return true;
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function transferTokenTo(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function transferTokenToMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }
    
    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    
    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr  public {
        require(icoStarted);
        uint256 tokens = 0;
        uint256 bonus = 0;
        uint256 countbonus = 0;
        uint256 bonusCond1 = 1 ether;
        uint256 bonusCond2 = 5 ether;
        uint256 bonusCond3 = 10 ether;

        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;

        if (msg.value >= requestMinimum && now < deadline && now < round1) {
            if(msg.value >= bonusCond1 && msg.value < bonusCond2){
                countbonus = tokens * 10 / 100;
            }else if(msg.value >= bonusCond2 && msg.value < bonusCond3){
                countbonus = tokens * 15 / 100;
            }else if(msg.value >= bonusCond3){
                countbonus = tokens * 20 / 100;
            }
        }else{
            countbonus = 0;
        }

        bonus = tokens + countbonus;
        
         if (tokens > 0 && msg.value >= requestMinimum){
            if( now >= deadline && now >= round1){
                distr(investor, tokens);
                totalWeiReceived = totalWeiReceived.add(msg.value);
                totalTokenSold = totalTokenSold.add(tokens);
            }else{
                if(msg.value >= bonusCond1){
                    distr(investor, bonus);
                    totalWeiReceived = totalWeiReceived.add(msg.value);
                    totalTokenSold = totalTokenSold.add(tokens);
                }else{
                    distr(investor, tokens);
                    totalWeiReceived = totalWeiReceived.add(msg.value);
                    totalTokenSold = totalTokenSold.add(tokens);
                }   
            }
        }else{
            require( msg.value >= requestMinimum );
            
        }

        if (totalTokenSold >= tokensForSale) {
            distributionFinished = true;
        }
        
         multisig.transfer(msg.value);
    }
    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        if (frozenAccount[msg.sender]) return false;
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {
        if (frozenAccount[msg.sender]) return false;
        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawAll() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        owner.transfer(wantAmount);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
        
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
      emit  FrozenFunds(target, freeze);
    }
}