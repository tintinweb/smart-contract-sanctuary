/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

pragma solidity ^0.4.19;

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

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract StandardToken {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

    function totalSupply() public constant returns (uint256 supply) {
        return totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract ERC20Token is StandardToken, Ownable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    string public version = '1.0';
    uint256 public totalCoin;
    uint8 public decimals;
    uint8 public exchangeRate;

    event TokenNameChanged(string indexed previousName, string indexed newName);
    event TokenSymbolChanged(string indexed previousSymbol, string indexed newSymbol);
    event ExhangeRateChanged(uint8 indexed previousRate, uint8 indexed newRate);

    function ERC20Token() public {
        decimals        = 18;
        totalCoin       = 10000000;                       // Total Supply of Coin
        totalSupply     = totalCoin * 10**uint(decimals); // Total Supply of Coin
        balances[owner] = totalSupply;                    // Total Supply sent to Owner's Address
        exchangeRate    = 100;                            // 100 Coins per ETH   (changable)
        symbol          = "TICKER";                       // Your Ticker Symbol  (changable)
        name            = "YourCoinNameHere";             // Your Coin Name      (changable)
    }

    function changeTokenName(string newName) public isOwner returns (bool success) {
        TokenNameChanged(name, newName);
        name = newName;
        return true;
    }

    function changeTokenSymbol(string newSymbol) public isOwner returns (bool success) {
        TokenSymbolChanged(symbol, newSymbol);
        symbol = newSymbol;
        return true;
    }

    function changeExhangeRate(uint8 newRate) public isOwner returns (bool success) {
        ExhangeRateChanged(exchangeRate, newRate);
        exchangeRate = newRate;
        return true;
    }

    function () public payable {
        fundTokens();
    }

    function fundTokens() public payable {
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(exchangeRate);
        require(balances[owner].sub(tokens) > 0);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[owner] = balances[owner].sub(tokens);
        Transfer(msg.sender, owner, msg.value);
        forwardFunds();
    }

    function forwardFunds() internal {
        owner.transfer(msg.value);
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    ) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        if(!_spender.call(
            bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender,
            _value,
            this,
            _extraData
        )) { revert(); }
        return true;
    }

}