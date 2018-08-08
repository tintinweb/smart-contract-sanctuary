pragma solidity ^0.4.13;

// &#169;The Alfa-Tower shares contract
// +35799057557
// &#169;IT Consulting Group Ltd
// There is no law stronger than the code

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
      throw;
    }
  }
}
contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/* &#169;IT Consulting Group Ltd
 <p1> Alfa-tower. </p1>
Alfa-Tower shares contract. Implements
  @notice See https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract SharesContract is ERC20Basic {
  
  using SafeMath for uint;
  
  mapping(address => uint) balances;
  
  /*
   * Fix for the ERC20 short address attack  
  */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}
contract StandardToken is SharesContract, ERC20 {
  mapping (address => mapping (address => uint)) allowed;
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint _value) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract AlfaTowerShares is StandardToken, Ownable {
  string public constant name = "Alfa-Tower";
  string public constant symbol = "Alfa-Tower";
  uint public constant decimals = 0;
  // Constructor
  function AlfaTowerShares() {
      totalSupply = 12000000; //  total amount of shares 
      balances[msg.sender] = totalSupply; //there are only 12 000 000 shares
  }
}
/* &#169;IT Consulting Group Ltd
Alfa-Tower - the investment project of a high-rise building with elite offices and luxury apartments.
The construction of the tower is in the center of Limassol on a plot of land 3600 m2.
The total cost of the investment is 12 million euros.
Since July 2017, the full development of the territory has been started. Geodesic miscalculations, measurements, and sysmic tests were carried out.
Received all the necessary licenses and permits for full-fledged construction. The package of attracted investments will be divided into 4 stages.
The first stage-July - December 2017 - 4 million euros, the second stage-January-March 2018-3 million euros, April-June 2018- 2 million euros, July-September 2018 - 3 million euros.
The completion of the construction is planned for October 2018. The advertising program for sales of offices and apartments has started. The average payback period of the project is 100-120% in 20 - 22 months. Such a large percentage of profit is due to several factors. 
1. Cyprus, a fast-growing and financially stable country, located in the European Union.
2. This investment project is located on the last vacant plot of land in the business center of Limassol, next to the central municipal court. 
3. The land is in the management of the company, thereby giving guarantees that the project is financially attractive.
4. The most respected company in the world, which participated in the construction of Jumeirah palms in Dubai, is engaged in the architectural and construction part.
5. The demand for class "A" office premises. 
6. This project is one of the first in Cyprus, which will have the status of an office-residential building.

The project consists of 8 ground floors, 3 underground floors, parking, an elite restaurant on the roof of the building, a fitness room, a beauty salon, 4 modern elevators, all offices have sea views, and the business part of the city.

At this stage, there are already applications for the purchase of office space for the restaurant, the office of plastic surgery, the crewing company, and several apartments.

At this stage, it is possible to purchase 80% of the total project, with 12 million euros costs. 
Accordingly, this equals 12 million shares. 
 */