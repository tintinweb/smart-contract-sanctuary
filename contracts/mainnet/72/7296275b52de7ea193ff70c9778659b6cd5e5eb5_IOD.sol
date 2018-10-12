pragma solidity ^0.4.24;

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

contract IOD is ERC20 {

    using SafeMath for uint256;
    address public owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    string public constant name = "IOD Token";
    string public constant symbol = "IOD";
    string public version  = "v.0.1";
    uint public constant decimals = 8;

    uint256 public maxSupply = 13000000000e8;
    uint256 public constant minContrib = 1 ether / 100;
    uint256 public IODPerEther = 15000000e8;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
    constructor () public {
        totalSupply = maxSupply;
        balances[msg.sender] = maxSupply;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function () public payable {
        buyIOD();
     }

    function dividend(uint256 _amount) internal view returns (uint256){
        if(_amount >= IODPerEther.div(2) && _amount < IODPerEther){ return ((20*_amount).div(100)).add(_amount);}
        else if(_amount >= IODPerEther && _amount < IODPerEther.mul(5)){return ((40*_amount).div(100)).add(_amount);}
        else if(_amount >= IODPerEther.mul(5)){return ((70*_amount).div(100)).add(_amount);}
        return _amount;
    }

    function buyIOD() payable public {
        address investor = msg.sender;
        uint256 tokenAmt =  IODPerEther.mul(msg.value) / 1 ether;
        require(msg.value >= minContrib && msg.value > 0);
        tokenAmt = dividend(tokenAmt);
        require(balances[owner] >= tokenAmt);
        balances[owner] -= tokenAmt;
        balances[investor] += tokenAmt;
        emit Transfer(this, investor, tokenAmt);
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

    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
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

}