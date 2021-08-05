/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

/**
 *Submitted for verification at Etherscan.io on 2018-05-21
*/

pragma solidity ^0.4.18;

// File: ../../ropsten/smart-contracts/contracts/mockContracts/TestToken.sol

/* all this file is based on code from open zepplin
 * https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token */


/**
 * Standard ERC20 token
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */


/**
 * Math operations with safety checks
 */
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

////////////////////////////////////////////////////////////////////////////////

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns(bool);
    function approve(address spender, uint value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

////////////////////////////////////////////////////////////////////////////////

/*
 * Basic token
 * Basic version of StandardToken, with no allowances
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) balances;

    /*
     * Fix for the ERC20 short address attack
     */
    modifier onlyPayloadSize(uint size) {
        if (msg.data.length < size + 4) {
         revert();
        }
        _;
    }

    function transfer(address _to, uint _value)  public onlyPayloadSize(2 * 32) returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
      return balances[_owner];
    }
}


////////////////////////////////////////////////////////////////////////////////

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) allowed;

    function transferFrom(address _from, address _to, uint _value) public returns(bool){

        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already revert if this condition is not met
        if (_value > _allowance) revert();

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public returns(bool){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

////////////////////////////////////////////////////////////////////////////////

/*
 * SimpleToken
 *
 * Very simple ERC20 Token example, where all tokens are pre-assigned
 * to the creator. Note they can later distribute these tokens
 * as they wish using `transfer` and other `StandardToken` functions.
 */
contract TestToken is StandardToken {

    string public name = "Test";
    string public symbol = "TST";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10**(50+18);

    function TestToken(string _name, string _symbol, uint _decimals) public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) public returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

    // save some gas by making only one contract call
    function burnFrom(address _from, uint256 _value) public returns (bool) {
        transferFrom( _from, msg.sender, _value );
        return burn(_value);
    }
}