//SourceUnit: TRC20 Crowdsale.sol

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
   
contract PANIPURI_ICO {
   
    using SafeMath for uint256;
    
    address tokenContract;
	uint256 public currentRate;

    address tokenContractAddress;
    
     modifier ownerOnly(){
        require(msg.sender == creator || msg.sender == wallet);
        _;
    }

    address public owner;
    address public wallet = 0xA2bd9279C6e5F5c02dfD3203F8419824fF859b2c;
	address private creator = 0x28517d9ae32A293b5a6b064B5f150F3eC669846f; 
    
    mapping(address=>uint256) private trxContributedBy;
    uint256 public totalTrxRaised;
    uint256 public totalTrxpresent;
    uint256 public totalTokensSoldTillNow;
	uint256 precision = 1;

    constructor(address _tokenContractAddress) public {
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;
		currentRate=26;
    }

   function () payable public{
        createTokens(msg.sender);
    }   
   
    function createTokens(address) payable public{
        require(msg.sender.balance >= msg.value, "Validate InternalTransfer error, balance is not sufficient."); 
        
        uint256 tokens = msg.value;
        address self = address(this);
        
        TokenContract tokencontract = TokenContract(tokenContractAddress);
        tokencontract.transferFrom(wallet, msg.sender, ((tokens.div(1000000000000000000)).mul(precision)).mul(currentRate));
        
        totalTokensSoldTillNow = totalTokensSoldTillNow.add(((tokens.div(1000000000000000000)).mul(precision)).mul(currentRate)); 
       
        trxContributedBy[msg.sender] = trxContributedBy[msg.sender].add(tokens);
        totalTrxRaised = totalTrxRaised.add(tokens);
        totalTrxpresent = totalTrxpresent.add(tokens);

   }
	function setCurrentRate(uint256 val) ownerOnly returns(bool success){
		currentRate=val;
		return true;
	}
	
    function getTrx(uint256 trxValue) ownerOnly external{
        totalTrxpresent = totalTrxRaised - trxValue;
        msg.sender.transfer(trxValue);
    }

    function killContract() ownerOnly external{
        selfdestruct(owner);
    }

    function getTrxContributedBy(address _address) view public returns(uint256){
        return trxContributedBy[_address];
    }

    function transferOwnership(address newOwner) ownerOnly external{
        if (newOwner != address(0)) {
          owner = newOwner;
        }
    }
}