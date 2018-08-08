pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}





/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       revert();
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}
/*

  Copyright 2017 Bitnan.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/


contract BitnanRewardToken is StandardToken {
    /* constants */
    string public constant NAME = "BitnanRewardToken";
    string public constant SYMBOL = "BRT";
    uint public constant DECIMALS = 18;
    uint256 public constant ETH_MIN_GOAL = 3000 ether;
    uint256 public constant ETH_MAX_GOAL = 6000 ether;
    uint256 public constant ORIGIN_ETH_BRT_RATIO = 3000;
    uint public constant UNSOLD_SOLD_RATIO = 50;
    uint public constant PHASE_NUMBER = 5;
    uint public constant BLOCKS_PER_PHASE = 30500;
    uint8[5] public bonusPercents = [
      20,
      15,
      10,
      5,
      0
    ];

    /* vars */
    address public owner;
    uint public totalEthAmount = 0;
    uint public tokenIssueIndex = 0;
    uint public deadline;
    uint public durationInDays;
    uint public startBlock = 0;
    bool public isLeftTokenIssued = false;


    /* events */
    event TokenSaleStart();
    event TokenSaleEnd();
    event FakeOwner(address fakeOwner);
    event CommonError(bytes error);
    event IssueToken(uint index, address addr, uint ethAmount, uint tokenAmount);
    event TokenSaleSucceed();
    event TokenSaleFail();
    event TokenSendFail(uint ethAmount);

    /* modifier */
    modifier onlyOwner {
      if(msg.sender != owner) {
        FakeOwner(msg.sender);
        revert();
      }
      _;        
    }
    modifier beforeSale {
      if(!saleInProgress()) {
        _;
      }
      else {
        CommonError(&#39;Sale has not started!&#39;);
        revert();
      }
    }
    modifier inSale {
      if(saleInProgress() && !saleOver()) {
        _;
      }
      else {
        CommonError(&#39;Token is not in sale!&#39;);
        revert();
      }
    }
    modifier afterSale {
      if(saleOver()) {
        _;
      }
      else {
        CommonError(&#39;Sale is not over!&#39;);
        revert();
      }
    }
    /* functions */
    function () payable {
      issueToken(msg.sender);
    }
    function issueToken(address recipient) payable inSale {
      assert(msg.value >= 0.01 ether);
      uint tokenAmount = generateTokenAmount(msg.value);
      totalEthAmount = totalEthAmount.add(msg.value);
      totalSupply = totalSupply.add(tokenAmount);
      balances[recipient] = balances[recipient].add(tokenAmount);
      IssueToken(tokenIssueIndex, recipient, msg.value, tokenAmount);
      if(!owner.send(msg.value)) {
        TokenSendFail(msg.value);
        revert();
      }
    }
    function issueLeftToken() internal {
      if(isLeftTokenIssued) {
        CommonError("Left tokens has been issued!");
      }
      else {
        require(totalEthAmount >= ETH_MIN_GOAL);
        uint leftTokenAmount = totalSupply.mul(UNSOLD_SOLD_RATIO).div(100);
        totalSupply = totalSupply.add(leftTokenAmount);
        balances[owner] = balances[owner].add(leftTokenAmount);
        IssueToken(tokenIssueIndex++, owner, 0, leftTokenAmount);
        isLeftTokenIssued = true;
      }
    }
    function BitnanRewardToken(address _owner) {
      owner = _owner;
    }
    function start(uint _startBlock) public onlyOwner beforeSale {
      startBlock = _startBlock;
      TokenSaleStart();
    }
    function close() public onlyOwner afterSale {
      if(totalEthAmount < ETH_MIN_GOAL) {
        TokenSaleFail();
      }
      else {
        issueLeftToken();
        TokenSaleSucceed();
      }
    }
    function generateTokenAmount(uint ethAmount) internal constant returns (uint tokenAmount) {
      uint phase = (block.number - startBlock).div(BLOCKS_PER_PHASE);
      if(phase >= bonusPercents.length) {
        phase = bonusPercents.length - 1;
      }
      uint originTokenAmount = ethAmount.mul(ORIGIN_ETH_BRT_RATIO);
      uint bonusTokenAmount = originTokenAmount.mul(bonusPercents[phase]).div(100);
      tokenAmount = originTokenAmount.add(bonusTokenAmount);
    }
    /* constant functions */
    function saleInProgress() constant returns (bool) {
      return (startBlock > 0 && block.number >= startBlock);
    }
    function saleOver() constant returns (bool) {
      return startBlock > 0 && (saleOverInTime() || saleOverReachMaxETH());
    }
    function saleOverInTime() constant returns (bool) {
      return block.number >= startBlock + BLOCKS_PER_PHASE * PHASE_NUMBER;
    }
    function saleOverReachMaxETH() constant returns (bool) {
      return totalEthAmount >= ETH_MAX_GOAL;
    }
}