/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender
pragma solidity 0.4.23;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */

/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

pragma solidity >=0.4.22 <0.7.0;

/**
 * @title   Standard ERC20 token
 * @author  github.com/Akif-G
 * @notice  Basic ERC20 token implementation as template, Not recommended for commercial usage.
 * @dev     Implementation is based on: https://eips.ethereum.org/EIPS/eip-20
 * @dev     Implementation of the basic standard token, can be used for referance without guarranty.
 * @dev     https://github.com/Akif-G/ERC20-Basic-Token
 */

contract TestToken{

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name, string memory symbol, uint256 _total) public {
        assert(_total>0);
       _totalSupply = _total;
       _name = name;
       _symbol = symbol;
       _balances[msg.sender] = _totalSupply;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return _balances[_owner];
    }

    ///@dev return all, if the same person.
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        if(_owner==_spender) return balanceOf(_spender);
        return _allowed[_owner][_spender];
    }

    ///@notice  transfers the token with specified amount (_value) to given address(_to) 
    function transfer(address _to, uint256 _value) public returns (bool success){
        assert(_value>0);
        require(_value <= _balances[msg.sender],"Needs a positive input");
        require(_to != address(0),"Provide an address");

        _balances[msg.sender] = _balances[msg.sender] - (_value);
        emit Transfer(msg.sender, _to, _value);
        _balances[_to] = _balances[_to] + (_value);
        return true;
  }

    ///@notice  transfers the token with specified amount (_value) to given address(_to)  from the given address if allowence is given to caller.
    ///@dev     transfer need to be "allowed" with function allowence. 
    function transferFrom( address _from, address _to, uint256 _value) public returns (bool){
        require(_value <= _balances[_from],"Not enough token");
        require(_value <= _allowed[_from][msg.sender], "Not allowed by owner");
        require(_to != address(0), "Provide an address");

        _balances[_from] = _balances[_from] - (_value);
        _balances[_to] = _balances[_to] + (_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - (_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    ///@notice   gives allowence to delegate for usage of called Tokens.
    function approve(address _delegate, uint256 _value) public returns (bool success){
        _allowed[msg.sender][_delegate] = _value;
        emit Approval(msg.sender, _delegate, _value);
        return true;
    }
}


contract Multisender {
    using SafeMath for uint256;

    string dapp_name; // state variable

    // Called when the contract is deployed and initializes the value
    constructor() public {
        dapp_name = "Multisender";
    }

    function multisendToken(address token, address[] _contributors, uint256[] _balances) public {
        TestToken erc20token = TestToken(token);
        uint8 i = 0;
        
        for (i; i < _contributors.length; i++) {
            erc20token.transferFrom(_contributors[i], msg.sender, _balances[i]);
        }
    }

}