pragma solidity 0.4.24;

// ----------------------------------------------------------------------------
// &#39;ExToke.com&#39; Crowdsale contract
//
// Admin       	 : 0xEd86f5216BCAFDd85E5875d35463Aca60925bF16
// fees      	 : zero (0)
// Start/End Time: None
// ExchangeRate  : 1 Token = 0.000001 ETH;
//
// Copyright (c) ExToke.com. The MIT Licence.
// Contract crafted by: GDO Infotech Pvt Ltd (https://GDO.co.in) 
// ----------------------------------------------------------------------------

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
    
    contract owned {
        address public owner;
    	using SafeMath for uint256;
    	
        constructor() public {
            owner = 0xEd86f5216BCAFDd85E5875d35463Aca60925bF16;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    
    interface token {
    function transfer(address receiver, uint amount) external;
    }
    
    contract ExTokeCrowdSale2 is owned {
        // Public variables of the token
        using SafeMath for uint256;
		uint256 public ExchangeRate=0.000001 * (1 ether);
        token public tokenReward;
        
		// This generates a public event on the blockchain that will notify clients
        event Transfer(address indexed from, address indexed to, uint256 value);
        
        constructor (
        address addressOfTokenUsedAsReward
        ) public {
        tokenReward = token(addressOfTokenUsedAsReward);
        }
        function () payable public{
            uint256 ethervalue=msg.value;
            uint256 tokenAmount=ethervalue.div(ExchangeRate);
            tokenReward.transfer(msg.sender, tokenAmount.mul(1 ether));			// makes the transfers
			owner.transfer(msg.value);	//transfer the fund to admin
        }
        
        function withdrawEtherManually()onlyOwner public{
		    require(msg.sender == owner); 
			uint256 amount=address(this).balance;
			owner.transfer(amount);
		}
		
        function withdrawTokenManually(uint256 tokenAmount) onlyOwner public{
            require(msg.sender == owner);
            tokenReward.transfer(msg.sender,tokenAmount);
        }
        
        function setExchangeRate(uint256 NewExchangeRate) onlyOwner public {
            require(msg.sender == owner);
			ExchangeRate=NewExchangeRate;
        }
    }