// Ethertote - Eth Raised from Token Sale
//
// The following contract automatically distributes the Eth raised from the
// token sale.

// 1. 50% of the Eth raised will go into a "development" ethereum wallet, immediately
// accessible to the team, to be used for marketing, promotion, development, 
// running costs, exchange listing fees, bug bounties and other aspects of 
// running the company.
//
// 2. 25% of the Eth will go into a "Tote Liquidator" ethereum wallet, which will be
// used by the team purely to to liquidate the ethertote over the the opening
// 12 weeks. It will be very easy to see the transactions on Etherscan as 
// they will match the CryptoPot smart contracts that make up the Ethertote
// ecosystem.
//
// 3. 25% of the Eth will go into a time-locked smart contract called "Team Eth"
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
    
    // address of the Ethertote Development wallet
    address public ethertoteDevelopmentWallet = 
    0x1a3c1ca46c58e9b140485A9B0B740d42aB3B4a26;
    
    // address of the ToteLiquidator wallet
    address public toteLiquidatorWallet = 
    0x8AF2dA3182a3dae379d51367a34480Bd5d04F4e2;
    
    // address of the TeamEth time-locked contract
    address public teamEthContract = 
    0x67ed24A0dB2Ae01C4841Cd8aef1DA519B588E2B2;
    

    // ensure call to each function is only made once
    bool public ethertoteDevelopmentTransferComplete;
    bool public toteLiquidatorTransferComplete;
    bool public teamEthTransferComplete;


    
    // amount of eth that will be distributed
    uint public ethToBeDistributed;
    
    // ensure the function is called once
    bool public ethToBeDistributedSet;

///////////////////////////////////////////////////////////////////////////////    
// percentages to be sent
//////////////////////////////////////////////////////////////////////////////

    // 50% to the development wallet
    // 100/50 = 2
    uint public divForEthertoteDevelopmentWallet = 2;
    
    // 25% to the liquidator wallet
    // 100/25 = 4
    uint public divForEthertoteLiquidatorWallet = 4;
    
    // 25% to the TeamEth Smart Contract
    // 100/25 = 4
    uint public divForTeamEthContract = 4;

/////////////////////////////////////////////////////////////////////////////
    
    // EVENTS
    event Received(uint256);
    event SentToTeamEth(uint256);
    event SentToLiquidator(uint256);
    event SentToDev(uint256);
    
    // MODIFIER
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
    
    
    // declare the token sale is complete, reference the balance, and make
    // the necessary transfers
    function _A_tokenSaleCompleted() onlyAdmin public {
        require(ethToBeDistributedSet == false);
        ethToBeDistributed = address(this).balance;
        ethToBeDistributedSet = true;
        emit Received(now);
    }   
    
    
    // move Eth to Ethertote development wallet
    function _B_sendToEthertoteDevelopmentWallet() onlyAdmin public {
       require(ethertoteDevelopmentTransferComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       // total balance divided by 5 = 50% of balance
       address(ethertoteDevelopmentWallet).transfer(ethToBeDistributed.div(divForEthertoteDevelopmentWallet));
       emit SentToDev(ethToBeDistributed.div(divForEthertoteDevelopmentWallet)); 
       //ensure function can only ever be called once
       ethertoteDevelopmentTransferComplete = true;
    }
    
    // move Eth to tote liquidator wallet
    function _C_sendToToteLiquidatorWallet() onlyAdmin public {
       require(toteLiquidatorTransferComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       // total balance divided by 4 = 25% of balance
       address(toteLiquidatorWallet).transfer(ethToBeDistributed.div(divForEthertoteLiquidatorWallet));
       emit SentToLiquidator(ethToBeDistributed.div(divForEthertoteLiquidatorWallet)); 
       //ensure function can only ever be called once
       toteLiquidatorTransferComplete = true;
    }

    // move Eth to team eth time-locked contract
    function _D_sendToTeamEthContract() onlyAdmin public {
       require(teamEthTransferComplete == false);
       require(ethToBeDistributed > 0);
       // now allow a percentage of the balance
       // total balance divided by 4 = 25% of balance
       address(teamEthContract).transfer(ethToBeDistributed.div(divForTeamEthContract));
       emit SentToTeamEth(ethToBeDistributed.div(divForTeamEthContract)); 
       //ensure function can only ever be called once
       teamEthTransferComplete = true;
    }
    
// ----------------------------------------------------------------------------
// This method can be used by admin to extract Eth accidentally 
// sent to this smart contract after all previous transfers have been made
// to the correct addresses
// ----------------------------------------------------------------------------
    function ClaimEth() onlyAdmin public {
        require(ethertoteDevelopmentTransferComplete == true);
        require(toteLiquidatorTransferComplete == true);
        require(teamEthTransferComplete == true);
        
        // now withdraw any accidental Eth sent to this contract
        require(address(this).balance > 0);
        address(admin).transfer(address(this).balance);

    }
}