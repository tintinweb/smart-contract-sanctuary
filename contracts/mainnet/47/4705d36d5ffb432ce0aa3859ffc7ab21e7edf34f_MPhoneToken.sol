pragma solidity ^0.4.13;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract Ownable {

    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function ChangeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

contract BaseMPHToken is Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    uint256 public maxtokens;
    address public owner;

    function BaseMPHToken() public {
        owner = msg.sender;
        maxtokens = 200000000000000;
    }

    modifier IsNoMax() {
        require(totalSupply <= maxtokens);
        _;
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        var _allowance = allowed[_from][msg.sender];
        require (_value <= _allowance); 
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function mint(address _to, uint256 _amount) onlyOwner IsNoMax public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        mint0(_to, _amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed Apowner, address indexed spender, uint256 value);
    event mint0(address indexed to, uint256 amount);
}


contract MPhoneToken is BaseMPHToken {

    string public constant name = "MPhone Token";
    string public constant symbol = "MPH";
    uint32 public constant decimals = 6;

}

contract MPhoneSeller is Ownable {

    using SafeMath for uint256;

    address public mainwallet;
    uint public rate;
    uint256 public MaxTokens;
    MPhoneToken public token = new MPhoneToken();

    function MPhoneSeller() public {
        rate = 1000000;
        owner = msg.sender;
        MaxTokens = token.maxtokens();
        mainwallet = msg.sender;
    }

    function ChangeMainWallet(address newWallet) onlyOwner public {
        require(newWallet != address(0));
        mainwallet = newWallet;
    }

    function ChangeRate(uint newrate) onlyOwner public {
        require(newrate > 0 );
        rate = newrate;
    }

    function MintTokens(address _to, uint256 _amount) onlyOwner public returns (bool) {
        Mint(_to,_amount);
        return token.mint(_to,_amount);
    }

    function GetBalance(address _owner) constant public returns (uint256 balance) {
        return token.balanceOf(_owner);
    }

    function GetTotal() constant public returns (uint256 Total) {
        return token.totalSupply();
    }

    function CreateTokens() payable public {
        mainwallet.transfer(msg.value);
        uint tokens = rate.mul(msg.value).div(1 ether);
        token.mint(msg.sender, tokens);
        SaleToken(msg.sender, tokens);
    }

    function() external payable {
        CreateTokens();
    }

    event SaleToken( address indexed to, uint amount);
    event Mint(address indexed to, uint256 amount);
}