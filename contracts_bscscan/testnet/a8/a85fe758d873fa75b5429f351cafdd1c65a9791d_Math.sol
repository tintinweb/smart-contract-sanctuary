/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;


contract Math {

         

    function Add(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function Subtract(uint256 x, uint256 y) internal pure returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function Mult(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

contract Token {
    uint256 public totalSupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 

/*  BEP 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
      
    }

    function balanceOf(address _owner) public view returns (uint256 ) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)public payable returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract PPMToken is StandardToken, Math {

    // metadata
    string public constant name = "P2P Messenger Token";
    string public constant symbol = "PPM";
    uint256 public constant decimals = 18;
    

    // contracts
    address public bnbFundDeposit;      // deposit address for bnb for p2p messenger
    address public ppmFundDeposit;      // deposit address for p2p messenger
    
    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant ppmFund = 300 * (10**6) * 10**decimals;   // 300m PPM reserved for p2p messenger ususge
    uint256 public constant tokenExchangeRate = 1000; // 1000 PPM tokens per 1 BNB
    uint256 public constant tokenCreationCap =  1500 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin =  675 * (10**6) * 10**decimals;


    // events
    event LogRefund(address indexed _to, uint256 _value);
    event CreatePpm(address indexed _to, uint256 _value);

    // below function constructor only executes at the time of deployment
    constructor ( 
        address _bnbFundDeposit,
        address _ppmFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFinalized = false;                   //controls pre through crowdsale state
      bnbFundDeposit = _bnbFundDeposit;
      ppmFundDeposit = _ppmFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = ppmFund;
      balances[ppmFundDeposit] = ppmFund;    // Deposit p2p messenger share
      emit CreatePpm(ppmFundDeposit, ppmFund);  // logs p2p messenger fund
    }

    /// @dev Accepts BNB and creates new PPM tokens.
    function createTokens() payable external {
      if (isFinalized) revert();
      if (block.number < fundingStartBlock) revert();
      if (block.number > fundingEndBlock) revert();
      if (msg.value == 0) revert();

      uint256 tokens = Mult(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = Add(totalSupply, tokens);

      // return money if something went wrong
      if (tokenCreationCap < checkedSupply) revert();  // odd fractions won't be found

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;  // Add not needed; bad semantics to use here
      emit CreatePpm(msg.sender, tokens);  // logs token creation
    }
}