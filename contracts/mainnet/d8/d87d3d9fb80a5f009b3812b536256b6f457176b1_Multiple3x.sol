pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        // Result must be a positive or zero
        assert(b <= a); 
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        // Result must be a positive or zero
        if (0 < c) c = 0;   
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}

contract Ownable {
  address public owner;

  // The Ownable constructor sets the original `owner` of the contract to the sender account.
  function Ownable() {
    owner = msg.sender;
  }

  // Throws if called by any account other than the owner.
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

/**
 *  Main contract: 
 *  *) You can refund eth*3 only between "refundTime" and "ownerTime".
 *  *) The creator can only get the contract balance after "ownerTime".  
 *  *) IMPORTANT! If the contract balance is less (you eth*3) then you get only half of the balance.
 *  *) For 3x refund you must pay a fee 0.1 Eth.
*/
contract Multiple3x is Ownable{

    using SafeMath for uint256;
    mapping (address=>uint) public deposits;
    uint public refundTime = 1507719600;     // GMT: 11 October 2017, 11:00
    uint public ownerTime = (refundTime + 1 minutes);   // +1 minute
    uint maxDeposit = 1 ether;  
    uint minDeposit = 100 finney;   // 0.1 eth


    function() payable {
        deposit();
    }
    
    function deposit() payable { 
        require(now < refundTime);
        require(msg.value >= minDeposit);
        
        uint256 dep = deposits[msg.sender];
        uint256 sumDep = msg.value.add(dep);

        if (sumDep > maxDeposit){
            msg.sender.send(sumDep.sub(maxDeposit)); // return of overpaid eth 
            deposits[msg.sender] = maxDeposit;
        }
        else{
            deposits[msg.sender] = sumDep;
        }
    }
    
    function refund() payable { 
        require(now >= refundTime && now < ownerTime);
        require(msg.value >= 100 finney);        // fee for refund
        
        uint256 dep = deposits[msg.sender];
        uint256 depHalf = this.balance.div(2);
        uint256 dep3x = dep.mul(3);
        deposits[msg.sender] = 0;

        if (this.balance > 0 && dep3x > 0){
            if (dep3x > this.balance){
                msg.sender.send(dep3x);     // refund 3x
            }
            else{
                msg.sender.send(depHalf);   // refund half of balance
            }
        }
    }
    
    function refundOwner() { 
        require(now >= ownerTime);
        if(owner.send(this.balance)){
            suicide(owner);
        }
    }
}