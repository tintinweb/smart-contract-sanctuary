pragma solidity ^0.4.22;
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure  returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure  returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure  returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure  returns (uint256) {
        return a < b ? a : b;
    }

    function asserti(bool assertion) internal pure {
        if (!assertion) {
            revert();
        }
    }



}

contract FixedSupplyGo7Token  {
    using SafeMath for uint;

    string public constant symbol = &quot;Go7&quot;;
    string public constant name = &quot;Go7Token&quot;;
    uint8 public constant decimals = 5;
    uint256 _totalSupply ;
    uint256 public buyPrice ;
    uint256 public sellPrice;
    string public buyPriceFormatted ;
    string public sellPriceFormatted;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    // Owner of this contract
    address public owner;

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }




    // Constructor
    constructor ()  public {
        _totalSupply = 100000000000;
        buyPrice = 4400;
        sellPrice = 4000;
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }


    function totalSupply() constant public returns (uint256 ts) {
        ts = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to,uint256 _value) public returns (bool success) {
         uint256 _allowance;
        _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        if ( (keccak256(_from) != keccak256(this)) && (keccak256(_to) != keccak256(this)) )
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    // Fallback function throws when called.
    function() public {
        revert();
    }

    function setBuyPrice(uint256 _bid, string _bidStr) onlyOwner public returns (bool success)
    {
        assert(_bid > 0) ;
        buyPrice = _bid ;
        buyPriceFormatted = _bidStr ;
        return true;
    }

    function setSellPrice(uint256 _ask, string _askStr) onlyOwner public returns (bool success)
    {
        assert(_ask> 0) ;
        sellPrice = _ask ;
        sellPriceFormatted = _askStr ;
        return true;
    }

    function setPrices(uint256 _bid, uint256 _ask,string _bidStr,string _askStr ) onlyOwner public returns (bool success)
    {
        assert(_bid > 0) ;
        buyPrice = _bid ;
        buyPriceFormatted = _bidStr;
        assert(_ask> 0) ;
        sellPrice = _ask ;
        sellPriceFormatted = _askStr;
        return true;
    }

    function getPrice(uint8 _BS) constant public returns (string  price) {
        if (_BS == 1) return buyPriceFormatted ;
        else return sellPriceFormatted ;
    }

    function getMinUnitPrice(uint8 _BS) constant public returns (uint256 price) {
        if (_BS == 1) return buyPrice ;
        else return sellPrice;
    }

    // 1 token equal to 0.001 GOLD Unit
    function buyToken() payable public returns (bool success)
    {
         uint256 _tokenNumber  = 0;
        _tokenNumber = msg.value.div(buyPrice);
        _tokenNumber = _tokenNumber.div(1000000000000) ;
        if (_tokenNumber == 0) revert();
        transferFrom(this,msg.sender,_tokenNumber);
        uint256 _weiToSend = msg.value - _tokenNumber.mul(buyPrice*1000000000000) ;
        msg.sender.transfer(_weiToSend) ;
        return true ;
    }

    function sellToken(uint256 _tokenNumber) public returns (bool success)
    {
        uint256 _weiToSend = _tokenNumber.mul(sellPrice*1000000000000) ;
        transferFrom(msg.sender,this,_tokenNumber);
        msg.sender.transfer(_weiToSend);
        return true ;
    }

}