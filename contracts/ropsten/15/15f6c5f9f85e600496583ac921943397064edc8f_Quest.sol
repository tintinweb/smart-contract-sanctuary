pragma solidity ^0.4.25;

/**
 * @title SafeMath
 */
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

contract Quest is ERC20 {
    
    using SafeMath for uint256;
    address public owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public claimer;

    string public constant name = "QUEST0";
    string public constant symbol = "QST0";
    uint public constant decimals = 8;
    
    uint256 public maxSupply = 10000000000e8;
    uint256 public QSTPerEth = 30000000e8;
    uint256 public claimable = 20000e8;
    uint256 public constant minContrib = 1 ether / 100;
    uint256 public maxClaim = 0;
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event TransferEther(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    //mitigates the ERC20 short address attack
    //suggested by izqui9 @ http://bit.ly/2NMMCNv
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    modifier onlyAllowedClaimer() {
        require(claimer[msg.sender] == false);
        _;
    }
    
    constructor () public {
        totalSupply = maxSupply;
        owner = msg.sender;
        balances[owner] = maxSupply;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }
    
    function updateTokensPerEth(uint _QSTPerEth) public onlyOwner {        
        QSTPerEth = _QSTPerEth;
    }
           
    function () public payable {
        getQST();
     }
    
    function dividend(uint256 _amount) internal view returns (uint256){
        if(_amount >= QSTPerEth) return ((7*_amount).div(100)).add(_amount);
        return _amount;
    }
    
    function getQST() payable onlyAllowedClaimer public {
        address investor = msg.sender;
        if(msg.value >= minContrib){
            uint256 tokenAmt =  QSTPerEth.mul(msg.value) / 1 ether;
            tokenAmt = dividend(tokenAmt);
            require(balances[owner] >= tokenAmt);
            balances[owner] = balances[owner].sub(tokenAmt);
            balances[investor] = balances[investor].add(tokenAmt);
            emit Transfer(this, investor, tokenAmt);    
        }else{
            require(balances[owner] >= claimable && maxClaim <= 4999);
            claimer[investor] = true;
            maxClaim = maxClaim.add(1);
            balances[owner] = balances[owner].sub(claimable);
            balances[investor] = balances[investor].add(claimable);
            emit Transfer(this, investor, claimable);
        }
        
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function doDistro(address[] _addresses, uint256 _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) {transfer(_addresses[i], _amount);}
    }
    
    function doDistroAmount(address[] addresses, uint256[] amounts) onlyOwner public {
        require(addresses.length == amounts.length);
        for (uint i = 0; i < addresses.length; i++) {transfer(addresses[i], amounts[i]);}
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
        // mitigates the ERC20 spend/approval race condition
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transferEther(address _receiver, uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        emit TransferEther(this, _receiver, _amount);
        _receiver.transfer(_amount);
    }
    
    function doEthDistro(address[] _addresses, uint256 _amount) public onlyOwner {        
        for (uint i = 0; i < _addresses.length; i++) { transferEther(_addresses[i], _amount);}
    }
    
    function withdrawFund() onlyOwner public {
        address thisCont = this;
        uint256 ethBal = thisCont.balance;
        owner.transfer(ethBal);
    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
    
    function getForeignTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
    
     function disallowClaimer(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            claimer[addresses[i]] = true;
        }
    }

    function allowClaimer(address[] addresses) onlyOwner public {
        for (uint i = 0; i < addresses.length; i++) {
            claimer[addresses[i]] = false;
        }
    }

}