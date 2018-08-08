/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
pragma solidity ^0.4.11;

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract RCCCToken  {
    string public constant name = "RCCC Token";
    string public constant symbol = "RCCC";
    uint public constant decimals = 18;
    uint256 _totalSupply    = 500000000 * 10**decimals;

    function totalSupply() constant returns (uint256 supply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances; //list of balance of each address
    mapping(address => mapping (address => uint256)) allowed;

    uint public baseStartTime; //All other time spots are calculated based on this time spot.

    address public founder = 0x5e06E608959D68Cf33584BEa9bF6e5CF3975EDe4;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //constructor
    function RCCCToken() {
        balances[founder] = _totalSupply;
    }

    function setStartTime(uint _startTime) {
        if (msg.sender!=founder) revert();
        baseStartTime = _startTime;
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     *
     * Applicable tests:
     *
     * - Test restricted early transfer
     * - Test transfer after restricted period
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (now < baseStartTime) revert();

        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * Change founder address (where ICO ETH is being forwarded).
     *
     * Applicable tests:
     *
     * - Test founder change by hacker
     * - Test founder change
     * - Test founder token allocation twice
     */
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) revert();
        founder = newFounder;
    }

    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (msg.sender != founder) revert();

        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {

            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    // forward all eth to founder
    function() payable {
        if (!founder.call.value(msg.value)()) revert(); 
    }

    // only owner can kill
    function kill() { 
        if (msg.sender == founder) {
            suicide(founder); 
        }
    }

}