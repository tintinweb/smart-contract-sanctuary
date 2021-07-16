//SourceUnit: TokenSwap.sol

    pragma solidity ^0.4.25;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
       
    interface TokenContract {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function allowance(address tokenOwner, address spender) external  view returns (uint remaining);
        function transfer(address to, uint tokens) external returns (bool success);
        function approve(address spender, uint tokens) external  returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
    } 
    
    contract SWAP_FSTER_TO_1UP {
        using SafeMath for uint256;
    	uint256 public currentRate;
        address tokenContractAddress;					  
    	address public wallet = 0xbfF80C4aa25d2015110D428999dCcE11D46531B6;
    	address private creator = 0x28517d9ae32A293b5a6b064B5f150F3eC669846f;																   
        uint256 public totalTokensSwappedTillNow;
        mapping(address=>uint256) public tokensContributedBy;				  
    	uint256 precision = 100000000;																	 
        trcToken tokenId = 1002226;
        uint toToken;
        
        constructor(address _tokenContractAddress) public {
            tokenContractAddress = _tokenContractAddress;
    		currentRate=10;
        }
        
        modifier ownerOnly(){
            require(msg.sender == creator || msg.sender == wallet);
            _;
        }

       function () payable public{
		tokenSwap(toToken);
	}
	
        function tokenSwap(uint toToken) payable public returns (uint){
		trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
		
		totalTokensSwappedTillNow = totalTokensSwappedTillNow.add(value); 
       
        tokensContributedBy[msg.sender] = tokensContributedBy[msg.sender].add(value);   
    									  
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transferFrom(wallet, msg.sender, value.mul(precision).div(currentRate));
       }
    	
    	function setCurrentRate(uint256 val) public ownerOnly returns(bool success){
    		currentRate=val;
    		return true;
    	}		  
    
        function getTokenBalance(trcToken id) public view returns (uint256) {
        return address(this).tokenBalance(id);
        }
        
        function getFster(uint256 tokens) public ownerOnly returns(bool success){
            msg.sender.transferToken(tokens, 1002226);
            return true;
        }
        
        function getTokensContributedBy(address _address) view public returns(uint256){
            return tokensContributedBy[_address];
        }
    
        function getTotalTokensSwappedTillNow() view public returns(uint256){
            return totalTokensSwappedTillNow;
        }
    	
    }