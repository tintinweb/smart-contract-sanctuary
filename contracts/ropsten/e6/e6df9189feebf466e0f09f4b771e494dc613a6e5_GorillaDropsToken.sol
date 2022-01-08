/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity ^0.4.26;

 interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
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

contract GorillaDropsToken is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public Claimed; 


    string public symbol;
    string public  name;
    address public admin;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalDistributed;
    uint256 public requestMinimum;
    uint256 public tokensPerEth;
    uint256 public nonPresaleBal; // 6m owner wallet
    uint256 public presaleBal; // 4m owner wallet



    // ============================================================================
    // Constructor
    // ============================================================================
    constructor() public {
        symbol = "GDrops";
        name = "GorillaDrops.org";
        decimals = 18;
        totalSupply = 10000000000000000000000000;
        requestMinimum = 20000000000000000;
        admin = 0x5A2d843Db97F7E2914b34306b316F7807399Ad83;
        tokensPerEth = 50000000000000000000;
        nonPresaleBal = 6000000000000000000000000; // 6m owner wallet
        presaleBal = 4000000000000000000000000; // 4m presale wallet 


        // place presale balance in this contract
        balances[this] = presaleBal;
        emit Transfer(this, this, presaleBal);

        balances[admin] = nonPresaleBal;
        emit Transfer(this, admin, nonPresaleBal);

        

    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TokensPerEthUpdated(uint _tokensPerEth);
    event Burn(address indexed burner, uint256 value);


    bool public distributionFinished = false;
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }


     
           
    function () external payable {
        getTokens();
     }

    function getTokens() payable public {
        uint256 tokens = 0;

        tokens = tokensPerEth.mul(msg.value) / 1 ether;       

        uint256 selfdropTokens = 1 ether;

        uint256 etherBalance = address(this).balance;


        
        if (tokens > 0 && msg.value >= requestMinimum)
        {
            
            emit Transfer(address(this), msg.sender, tokens);

            balances[this] = balances[this].sub(tokens);
            balances[msg.sender] = balances[msg.sender].add(tokens);

            owner.transfer(etherBalance);        

        }


        if (tokens <= 0 && msg.value < requestMinimum)
        {
            // do self drop 

            emit Transfer(address(this), msg.sender, selfdropTokens);

            balances[this] = balances[this].sub(selfdropTokens);
            balances[msg.sender] = balances[msg.sender].add(selfdropTokens);

            owner.transfer(etherBalance); 

        }

    }


    function doAirdrop (address recipient) onlyOwner external
    {
        
            uint256 airdropTokens = 10 ether;

            emit Transfer(address(this), recipient, airdropTokens);

            balances[this] = balances[this].sub(airdropTokens);
            balances[recipient] = balances[recipient].add(airdropTokens);

    }






    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) public returns (bool success) {

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
    

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        owner.transfer(wantAmount);
    }


}