pragma solidity ^0.4.24;

interface karaOmTokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
contract KaraOmToken {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    uint256 public totalDistributed = 0;    
    uint256 public constant MIN_CONTRIBUTION = 1 ether / 100; // 0.01 Ether
    uint256 public tokensPerEth = 17000000e8;
   bool public distributionFinished = false;
    address owner = msg.sender;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Distr(address indexed to, uint256 amount);
    event DistrFinished();

    event Airdrop(address indexed _owner, uint _amount, uint _balance);

    event TokensPerEthUpdated(uint _tokensPerEth);

    event Burn(address indexed from, uint256 value);

    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    function KaraOmToken () public {
        totalSupply = 690000000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        name = "KaraOm Token";                                   // Set the name for display purposes
        symbol = "KOM";                               // Set the symbol for display purposes
        owner = msg.sender;    
        distr(owner, totalDistributed);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

     function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }

     function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    function doAirdrop(address _participant, uint _amount) internal {

        require( _amount > 0 );      

        require( totalDistributed < totalSupply );
        
        balanceOf[_participant] = balanceOf[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balanceOf[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }

    function adminClaimAirdrop(address _participant, uint _amount) public onlyOwner {        
        doAirdrop(_participant, _amount);
    }

    function adminClaimAirdropMultiple(address[] _addresses, uint _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) doAirdrop(_addresses[i], _amount);
    }

    function () external payable {
        getTokens();
     }
    
    function getTokens() payable canDistr  public {
        uint256 tokens = 0;

        // minimum contribution
        require( msg.value >= MIN_CONTRIBUTION );

        require( msg.value > 0 );

        // get baseline number of tokens
        tokens = tokensPerEth.mul(msg.value) / 1 ether;        
        address investor = msg.sender;
        
        if (tokens > 0) {
            distr(investor, tokens);
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }


    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
            if (_value != 0 && allowance[msg.sender][_spender] != 0) { return false; }
            allowance[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        karaOmTokenRecipient spender = karaOmTokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    function withdraw() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }
 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); 
        balanceOf[msg.sender] -= _value;           
        totalSupply -= _value;                    
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);               
        require(_value <= allowance[_from][msg.sender]);  
        balanceOf[_from] -= _value;                        
        allowance[_from][msg.sender] -= _value;      
        totalSupply -= _value;                            
        emit Burn(_from, _value);
        return true;
    }
     function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}