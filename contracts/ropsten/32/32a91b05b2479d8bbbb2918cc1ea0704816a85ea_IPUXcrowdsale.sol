pragma solidity 0.5.2; /*

___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   &#39; /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


 .----------------.   .----------------.   .----------------.   .----------------. 
| .--------------. | | .--------------. | | .--------------. | | .--------------. |
| |     _____    | | | |   ______     | | | | _____  _____ | | | |  ____  ____  | |
| |    |_   _|   | | | |  |_   __ \   | | | ||_   _||_   _|| | | | |_  _||_  _| | |
| |      | |     | | | |    | |__) |  | | | |  | |    | |  | | | |   \ \  / /   | |
| |      | |     | | | |    |  ___/   | | | |  | &#39;    &#39; |  | | | |    > `&#39; <    | |
| |     _| |_    | | | |   _| |_      | | | |   \ `--&#39; /   | | | |  _/ /&#39;`\ \_  | |
| |    |_____|   | | | |  |_____|     | | | |    `.__.&#39;    | | | | |____||____| | |
| |              | | | |              | | | |              | | | |              | |
| &#39;--------------&#39; | | &#39;--------------&#39; | | &#39;--------------&#39; | | &#39;--------------&#39; |
 &#39;----------------&#39;   &#39;----------------&#39;   &#39;----------------&#39;   &#39;----------------&#39; 

                                __________________________________________________________________
                                      __                                      __                  
                                    /    )                          /       /    )         /      
                                ---/--------)__----__-----------__-/--------\--------__---/----__-
                                  /        /   ) /   )| /| /  /   /          \     /   ) /   /___)
                                _(____/___/_____(___/_|/_|/__(___/_______(____/___(___(_/___(___ _
                                                                                                  
                                                                  
  
// ----------------------------------------------------------------------------
// &#39;IPUX&#39; Crowdsale contract with following features
//      => Token address change
//      => SafeMath implementation 
//      => Ether sent to owner immediately
//      => Phased ICO
//
// Copyright (c) 2019 TradeWeIPUX Limited ( https://ipux.io )
// Contract designed by EtherAuthority ( https://EtherAuthority.io )
// ----------------------------------------------------------------------------
  
*/ 

//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
    
contract owned {
    address payable public owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface TokenRecipient { function transfer(address _to, uint256 _value) external; }

contract IPUXcrowdsale is owned {
    
    /*==============================
    =   TECHNICAL SPECIFICATIONS   =
    ===============================
    => ICO period 1 start:  15 Jan 2019 00:00:00 GMT
    => ICO period 1 end:    17 Feb 2019 00:00:00 GMT
    => ICO period 1 bonus:  30%
    => ICO period 2 start:  01 Mar 2019 00:00:00 GMT
    => ICO period 2 end:    31 Mar 2019 00:00:00 GMT
    => ICO period 2 bonus:  20%
    => ICO period 3 start:  15 Apr 2019 00:00:00 GMT
    => ICO period 3 end:    30 Apr 2019 00:00:00 GMT
    
    => Token distribution only if ICO phases are going on. Else, it will accept ether but no tokens given
    => There is no minimum or maximum of contrubution
    => No acceptance of ether if hard cap is reached
    */
    

    /*==============================
    =       PUBLIC VARIABLES       =
    ==============================*/
    address public tokenAddress;
    uint256 public tokenDecimal;
    using SafeMath for uint256;
    TokenRecipient tokenContract = TokenRecipient(tokenAddress);
    
    /*==============================
    =        ICO VARIABLES         =
    ==============================*/
    uint256 public icoPeriod1start  = 1547510400;   //15 Jan 2019 00:00:00 GMT
    uint256 public icoPeriod1end    = 1550361600;   //17 Feb 2019 00:00:00 GMT
    uint256 public icoPeriod2start  = 1551398400;   //01 Mar 2019 00:00:00 GMT
    uint256 public icoPeriod2end    = 1553990400;   //31 Mar 2019 00:00:00 GMT
    uint256 public icoPeriod3start  = 1555286400;   //15 Apr 2019 00:00:00 GMT
    uint256 public icoPeriod3end    = 1556582400;   //30 Apr 2019 00:00:00 GMT
    uint256 public softcap          = 70000 ether;
    uint256 public hardcap          = 400000 ether;
    uint256 public fundRaised       = 0;
    uint256 public exchangeRate     = 50;           //1 ETH = 50 Tokens which equals to 0.02 ETH / token
    


    /*==============================
    =       PUBLIC FUNCTIONS       =
    ==============================*/
    
    /**
     * @notice Initializes contract with initial tokens associated with crowdsale 
     * @param _tokenAddress Addess of token contract
     */
    constructor (address _tokenAddress, uint256 _tokenDecimal) public {
        tokenAddress = _tokenAddress;
        tokenDecimal = _tokenDecimal;
    }
    
    /**
     * @notice Function to update the token address
     * @param _tokenAddress Address of the token
     */
    function updateToken(address _tokenAddress, uint256 _tokenDecimal) public onlyOwner {
        require(_tokenAddress != address(0), &#39;Address is invalid&#39;);
        tokenAddress = _tokenAddress;
        tokenDecimal = _tokenDecimal;
    }
    
    /**
     * @notice Payble fallback function which accepts ether and sends tokens to caller according to ETH amount
     */
    function () payable external {
        // no acceptance of ether if hard cap is reached
        require(fundRaised < hardcap, &#39;hard cap is reached&#39;);
        // token distribution only if ICO is going on. Else, it will accept ether but no tokens given
		if((icoPeriod1start < now && icoPeriod1end > now) || (icoPeriod2start < now && icoPeriod2end > now) || icoPeriod3start < now && icoPeriod3end > now){
        // calculate token amount to be sent, as pe weiamount * exchangeRate
		uint256 token = msg.value.mul(exchangeRate);                    
		// adding purchase bonus if application
		uint256 finalTokens = token.add(calculatePurchaseBonus(token));
        // makes the token transfers
		tokenContract.transfer(msg.sender, finalTokens);
		}
		fundRaised += msg.value;
		// transfer ether to owner
		owner.transfer(msg.value);                                           
	}

    /**
     * @notice Internal function to calculate the purchase bonus
     * @param token Amount of total tokens
     * @return uint256 total payable purchase bonus
     */
    function calculatePurchaseBonus(uint256 token) internal view returns(uint256){
	    if(icoPeriod1start < now && icoPeriod1end > now){
	        return token.mul(30).div(100);  //30% bonus in period 1
	    }
	    else if(icoPeriod2start < now && icoPeriod2end > now){
	        return token.mul(20).div(100);  //20% bonus in period 2
	    }
	    else{
	        return 0;                       // No bonus otherwise
	    }
	}
      
    /**
     * @notice Just in rare case, owner wants to transfer Ether from contract to owner address
     */
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
}