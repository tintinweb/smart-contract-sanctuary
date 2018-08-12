// Ethertote - Reward/Recogniton contract
// 09.08.18 
//
// ----------------------------------------------------------------------------
// Overview
// ----------------------------------------------------------------------------
//
// There are various individuals we would like to reward over the coming 
// weeks with TOTE tokens. Admins will add an ethereum wallet address and a 
// number of tokens for each individual to this smart contract. 
// The individual simply needs to click on the claim button and claim their tokens.
//
// This function will open immediately after the completion of the token sale, and will 
// remain open for 60 days, after which time admin will be able to recover any 
// unclaimed tokens 
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



// ----------------------------------------------------------------------------
// EXTERNAL CONTRACTS
// ----------------------------------------------------------------------------

contract EthertoteToken {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}

contract TokenSale {
    function closingTime() public pure returns (uint) {}
}


// ----------------------------------------------------------------------------


// MAIN CONTRACT

contract Reward {
        using SafeMath for uint256;
        
    // VARIABLES
    address public admin;
    address public thisContractAddress;
    address public tokenContractAddress = 0x42be9831FFF77972c1D0E1eC0aA9bdb3CaA04D47;
    
    address public tokenSaleAddress = 0x1C49d3c4895E7b136e8F8b804F1279068d4c3c96;
    
    uint public contractCreationBlockNumber;
    uint public contractCreationBlockTime;
    
    uint public tokenSaleClosingTime;
    
    bool public claimTokenWindowOpen;
    uint public windowOpenTime;
  
    // ENUM
    EthertoteToken token;       
    TokenSale tokensale;
    

    // EVENTS 
	event Log(string text);
        
    // MODIFIERS
    modifier onlyAdmin { 
        require(
            msg.sender == admin
        ); 
        _; 
    }
        
    modifier onlyContract { 
        require(
            msg.sender == admin ||
            msg.sender == thisContractAddress
        ); 
        _; 
    }   
        
 
    // CONSTRUCTOR
    constructor() public payable {
        admin = msg.sender;
        thisContractAddress = address(this);
        contractCreationBlockNumber = block.number;
        token = EthertoteToken(tokenContractAddress);
        tokensale = TokenSale(tokenSaleAddress);

	    emit Log("Reward contract created.");
    }
    
    // FALLBACK FUNCTION
    function () private payable {}
    
        
// ----------------------------------------------------------------------------
// Admin Only Functions
// ----------------------------------------------------------------------------

    // STRUCT 
    Claimant[] public claimants;  // special struct variable
    
        struct Claimant {
        address claimantAddress;
        uint claimantAmount;
        bool claimantHasClaimed;
    }


    // Admin fuction to add claimants
    function addClaimant(address _address, uint _amount, bool) onlyAdmin public {
            Claimant memory newClaimant = Claimant ({
                claimantAddress: _address,
                claimantAmount: _amount,
                claimantHasClaimed: false
                });
                claimants.push(newClaimant);
    }
    
    
    function adjustEntitlement(address _address, uint _amount) onlyAdmin public {
        for (uint i = 0; i < claimants.length; i++) {
            if(_address == claimants[i].claimantAddress) {
                claimants[i].claimantAmount = _amount;
            }
            else revert();
            }  
    }
    
    // recover tokens tha were not claimed 
    function recoverTokens() onlyAdmin public {
        require(now < (showTokenSaleClosingTime().add(61 days)));
        token.transfer(admin, token.balanceOf(thisContractAddress));
    }


// ----------------------------------------------------------------------------
// This method can be used by admin to extract Eth accidentally 
// sent to this smart contract.
// ----------------------------------------------------------------------------
    function ClaimEth() onlyAdmin public {
        address(admin).transfer(address(this).balance);

    }  
    
    
    
// ----------------------------------------------------------------------------
// PUBLIC FUNCTION - To be called by people claiming reward 
// ----------------------------------------------------------------------------

    // callable by claimant after token sale is completed
    function claimTokens() public {
        require(now > showTokenSaleClosingTime());
        require(now < (showTokenSaleClosingTime().add(60 days)));
          for (uint i = 0; i < claimants.length; i++) {
            if(msg.sender == claimants[i].claimantAddress) {
                require(claimants[i].claimantHasClaimed == false);
                token.transfer(msg.sender, claimants[i].claimantAmount);
                claimants[i].claimantHasClaimed = true;
            }
          }
    }
    
    
// ----------------------------------------------------------------------------
// public view Functions
// ----------------------------------------------------------------------------
    
    // check claim entitlement
    function checkClaimEntitlement() public view returns(uint) {
        for (uint i = 0; i < claimants.length; i++) {
            if(msg.sender == claimants[i].claimantAddress) {
                require(claimants[i].claimantHasClaimed == false);
                return claimants[i].claimantAmount;
            }
            else return 0;
        }  
    }
    
    
    // check claim entitlement of any wallet
    function checkClaimEntitlementofWallet(address _address) public view returns(uint) {
        for (uint i = 0; i < claimants.length; i++) {
            if(_address == claimants[i].claimantAddress) {
                require(claimants[i].claimantHasClaimed == false);
                return claimants[i].claimantAmount;
            }
            else return 0;
        }  
    }
    
    
    
    // check Eth balance of this contract
    function thisContractBalance() public view returns(uint) {
      return address(this).balance;
    }

    // check balance of this smart contract
    function thisContractTokenBalance() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
    }


    function showTokenSaleClosingTime() public view returns(uint) {
        return tokensale.closingTime();
    }


}