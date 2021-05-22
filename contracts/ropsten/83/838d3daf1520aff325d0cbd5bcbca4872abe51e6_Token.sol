/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.0;

    // Small library to test for overflow to prevent overflow attacks
library SafeMath { // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Token {
    using SafeMath for uint256;
        // MUST trigger when tokens are transferred, including zero value transfers.
        //A token contract which creates new tokens SHOULD trigger a Transfer event 
        // with the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
        // MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

        // Token constants
    string public constant tokenName = "905417287";
    string public constant tokenSymbol = "CS188";
    uint8 public constant numDecimals = 18;     // recommended value, common amongst most populat ERC20s
    uint256 totalSupply_= 100000000000;

        // Mappings for accounts->balances and for accounts approved to withdraw->withdrawal sum for each
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

        // In the constructor of the smart contract, give the deployer of the contract (msg.sender)
        // some tokens so that they can be sent later.
    constructor()
    {
            // Gives contract creator all tokens
        balances[msg.sender] = totalSupply_;
    }

        // Returns the name of the token, in this case my UID
    function name() public pure returns (string memory)
    {
        return tokenName;
    }

        // Returns the symbol of the token, or CS188, the course name
    function symbol() public pure returns (string memory)
    {
        return tokenSymbol;
    }

        // Returns the number of decimals the token uses
    function decimals() public pure returns (uint8)
    {
        return numDecimals;
    }

        // Returns total token supply
    function totalSupply() public view returns (uint256)
    {
        return totalSupply_;
    }

        // Returns account balance of another account with address _owner
    function balanceOf(address _owner) public view returns (uint256 balance)
    {
        return balances[_owner];
    }
        // Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
        // The function SHOULD throw if the message caller's account balance does not have 
        // enough tokens to spend.
    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

        // Transfers _value amount of tokens from address _from to address _to, 
        // and MUST fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

        // Allows _spender to withdraw from your account multiple times, up to the _value amount. 
        // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

        // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}