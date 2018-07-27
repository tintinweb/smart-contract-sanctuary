// Ethertote - Team Eth timelocked smart contract
//
// The following contract offers peace of mind to investors as the
// Eth that will go to the members of the Ethertote team
// will be time-locked over a 12-month period, whereby the 
// withdraw functions can only be called when the current timestamp is 
// greater than the time specified in each functions
// ----------------------------------------------------------------------------

pragma solidity 0.4.24;

///////////////////////////////////////////////////////////////////////////////
// SafeMath Library 
///////////////////////////////////////////////////////////////////////////////
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

///////////////////////////////////////////////////////////////////////////////
// Main contract
//////////////////////////////////////////////////////////////////////////////

contract TeamEth {
    using SafeMath for uint256;

    address public thisContractAddress;
    address public admin;
    
    // time expressed in seconds of 3 months (1 quarter of a year)
    uint public oneQuarterInSeconds = 7890000;
    
    
    // the first team withdrawal can be made after:
    // GMT: Saturday, 1 December 2018 00:00:00
    // expressed as Unix epoch time 
    // https://www.epochconverter.com/
    uint256 public unlockDate1 = 1543622400;
    
    uint256 public unlockDate2 = unlockDate1.add(oneQuarterInSeconds);
    uint256 public unlockDate3 = unlockDate2.add(oneQuarterInSeconds);
    uint256 public unlockDate4 = unlockDate3.add(oneQuarterInSeconds);
    
    uint256 public createdAt;
    
    // amount of eth that will be claimed
    uint public ethToBeClaimed;
    
    // percentage that the team can withdraw Eth
    // it can naturally be inferred that quarter4 will be 25%
    uint public percentageQuarter1 = 25;
    uint public percentageQuarter2 = 25;
    uint public percentageQuarter3 = 25;
    
    // 100%
    uint public hundredPercent = 100;
    
    // calculating the number used as the divider
    uint public quarter1 = hundredPercent.div(percentageQuarter1);
    uint public quarter2 = hundredPercent.div(percentageQuarter2);
    uint public quarter3 = hundredPercent.div(percentageQuarter3);
    
    bool public withdraw_1Completed;
    bool public withdraw_2Completed;
    bool public withdraw_3Completed;

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    constructor () public {
        admin = msg.sender;
        thisContractAddress = address(this);
        createdAt = now;
    }

    // fallback to store all the ether sent to this address
    function() payable public { 
    }
    
    function thisContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function setEthToBeClaimed() onlyAdmin public {
        ethToBeClaimed = address(this).balance;
    }

    // team withdrawal after specified time
    function withdraw_1() onlyAdmin public {
       require(ethToBeClaimed > 0);
       require(withdraw_1Completed == false);
       require(now >= unlockDate1);
       // now allow a percentage of the balance to be claimed
       msg.sender.transfer(ethToBeClaimed.div(quarter1));
       emit Withdrew(msg.sender, ethToBeClaimed.div(quarter1));    // 25%
       withdraw_1Completed = true;
    }
    
    // team withdrawal after specified time
    function withdraw_2() onlyAdmin public {
       require(ethToBeClaimed > 0);
       require(withdraw_2Completed == false);
       require(now >= unlockDate2);
       // now allow a percentage of the balance to be claimed
       msg.sender.transfer(ethToBeClaimed.div(quarter2));
       emit Withdrew(msg.sender, ethToBeClaimed.div(quarter2));    // 25%
       withdraw_2Completed = true;
    }
    
    // team withdrawal after specified time
    function withdraw_3() onlyAdmin public {
       require(ethToBeClaimed > 0);
       require(withdraw_3Completed == false);
       require(now >= unlockDate3);
       // now allow a percentage of the balance to be claimed
       msg.sender.transfer(ethToBeClaimed.div(quarter3));
       emit Withdrew(msg.sender, ethToBeClaimed.div(quarter3));    // 25%
       withdraw_3Completed = true;
    }
    
    // team withdrawal after specified time
    function withdraw_4() onlyAdmin public {
       require(now >= unlockDate4);
       // now allow all remaining balance to be claimed
       msg.sender.transfer(address(this).balance);
       emit Withdrew(msg.sender, address(this).balance);    // all remaining balance
    }

}