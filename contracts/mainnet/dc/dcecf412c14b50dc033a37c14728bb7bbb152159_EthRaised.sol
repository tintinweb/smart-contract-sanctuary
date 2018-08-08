// Ethertote - Eth Raised from Token Sale
//
// The following contract automatically distributes the Eth raised from the
// token sale.

// 1. 40% of the Eth raised will go into a "development" ethereum wallet, immediately
// accessible to the team, to be used for marketing, promotion, development, 
// running costs, exchange listing fees, bug bounties and other aspects of 
// running the company.
//
// 2. 30% of the Eth will go into a "Tote Liquidator" ethereum wallet, which will be
// used by the team purely to to liquidate the ethertote over the the opening
// 12 weeks. It will be very easy to see the transactions on Etherscan as 
// they will match the CryptoPot smart contracts that make up the Ethertote
// ecosystem.
//
// 3. 30% of the Eth will go into a time-locked smart contract called "Team Eth"
// which will be available to claim by the Ethertote team over a 12-month period
//
//
// Note that ALL Eth raised from the token sale will initially go to this 
// smart contract
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

contract EthRaised {
    using SafeMath for uint256;

    address public thisContractAddress;
    address public admin;
    
    // time contract was deployed
    uint public createdAt;
    
    // address of the time-locked contract
    address public teamEthContract = 0x9c229Dd7546eb8f5A12896e03e977b644a96B961;
    
    // address of the ToteLiquidator wallet
    address public toteLiquidatorWallet = 0x8AF2dA3182a3dae379d51367a34480Bd5d04F4e2;
    
    // address of the Ethertote Development wallet
    address public ethertoteDevelopmentWallet = 0x1a3c1ca46c58e9b140485A9B0B740d42aB3B4a26;
    
    // ensure call to each function is only made once
    bool public teamEthTransferComplete;
    bool public toteLiquidatorTranserComplete;
    bool public ethertoteDevelopmentTransferComplete;
    
    // amount of eth that will be distributed
    uint public ethToBeDistributed;

    // percentages to be sent 
    uint public percentageToEthertoteDevelopmentWallet = 40;
    uint public percentageToTeamEthContract = 30;
    uint public percentageToToteLiquidatorWallet = 30;
    
    // used as helper to calculate amounts to be transferred
    uint public oneHundred = 100;
    
    // value to be used as dividers
    uint public toEthertoteDevelopmentWallet = oneHundred.div(percentageToEthertoteDevelopmentWallet);
    uint public toTeamEthContract = oneHundred.div(percentageToTeamEthContract);
    uint public toToteLiquidatorWallet = oneHundred.div(percentageToToteLiquidatorWallet);
    
    event Received(address from, uint256 amount);
    event SentToTeamEth(address to, uint256 amount);
    event SentToLiquidator(address to, uint256 amount);
    event SentToDev(address to, uint256 amount);
    
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
        emit Received(msg.sender, msg.value);
    }
    
    function thisContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    // move Eth to team eth time-locked contract
    function sendToTeamEthContract() onlyAdmin public {
       require(teamEthTransferComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       address(teamEthContract).transfer(ethToBeDistributed.div(toTeamEthContract));
       emit SentToTeamEth(msg.sender, ethToBeDistributed.div(toTeamEthContract)); 
       //ensure function can only ever be called once
       teamEthTransferComplete = true;
    }
    
    // move Eth to tote liquidator wallet
    function sendToToteLiquidatorWallet() onlyAdmin public {
       require(toteLiquidatorTranserComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       address(toteLiquidatorWallet).transfer(ethToBeDistributed.div(toToteLiquidatorWallet));
       emit SentToLiquidator(msg.sender, ethToBeDistributed.div(toToteLiquidatorWallet)); 
       //ensure function can only ever be called once
       toteLiquidatorTranserComplete = true;
    }
    
    // move Eth to Ethertote development wallet
    function sendToEthertoteDevelopmentWallet() onlyAdmin public {
       require(ethertoteDevelopmentTransferComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       address(ethertoteDevelopmentWallet).transfer(ethToBeDistributed.div(toEthertoteDevelopmentWallet));
       emit SentToDev(msg.sender, ethToBeDistributed.div(toEthertoteDevelopmentWallet)); 
       //ensure function can only ever be called once
       ethertoteDevelopmentTransferComplete = true;
    }
    
    // declare the token sale is complete, and reference the balance
    function tokenSaleCompleted() onlyAdmin public {
        ethToBeDistributed = address(this).balance;
    }



}