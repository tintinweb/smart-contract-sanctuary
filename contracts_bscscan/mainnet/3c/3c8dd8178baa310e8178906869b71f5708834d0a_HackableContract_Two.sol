/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// Solidity Riddle:
// Break the contract and keep all deposited $SCAM tokens.
// No initial $SCAM holdings are required to solve the problem, just some BNB to pay for gas


// Website
// https://scam-coin.org/

// GitHub
// https://github.com/scamcoincrypto

// Reddit
// https://www.reddit.com/r/scam_coin/

// Telegram
// https://t.me/SCAM_Coin_Community


// WARNING
// This smart contract is designed to be exploitable!
// Don't deposit anything that you are not willing to lose!



pragma solidity =0.7.6;


contract HackableContract_Two {

    address public constant SCAM_TOKEN_ADDRESS = 0xdb78FcBb4f1693FDBf7a85E970946E4cE466E2A9;
        
    uint256 public Count = 0;
    mapping(address => bool) addressRegistered;
	
	mapping(address => uint256) addressToId;
	mapping(uint256 => uint256) balancesScam;
	mapping(uint256 => uint256) balancesBnb;
	
	event Deposit(address indexed depositor, string currency, uint256 amount);
	
	using SafeMath for uint256;
	
	
	modifier onlyRegistered
	{
		require(addressRegistered[msg.sender]);
        _;
    }
	
	
	function getScamBalance(address adr) public view returns(uint256)
	{
	    return balancesScam[addressToId[adr]];
	}
	
	
	function getBnbBalance(address adr) public view returns(uint256)
	{
	    return balancesBnb[addressToId[adr]];
	}
	
	
	function DepositScam(uint256 amount) external
	{
	    require(amount > 0);
	    BEP20 scamToken = BEP20(SCAM_TOKEN_ADDRESS);
	    
	    if (!addressRegistered[msg.sender])
	    {
	        registerAccount();
	    }
	    
	    uint256 id = addressToId[msg.sender];
	    balancesScam[id] = balancesScam[id].add(amount);
	    scamToken.transferFrom(msg.sender, address(this), amount);
	    
	    emit Deposit(msg.sender, "SCAM", amount);
	}
	
	
	function DepositBnb() public payable
	{
	    if(!addressRegistered[msg.sender])
        {
            registerAccount();
        }
	    
	    uint256 id = addressToId[msg.sender];
	    balancesBnb[id] = balancesBnb[id].add(msg.value);
	    
	    emit Deposit(msg.sender, "BNB", msg.value);
	}



    receive() external payable
    {
        DepositBnb();
    }



    function WithdrawScam(uint256 amount) public onlyRegistered
    {
        BEP20 scamToken = BEP20(SCAM_TOKEN_ADDRESS);
        
        uint256 id = addressToId[msg.sender];
        balancesScam[id] = balancesScam[id].sub(amount);
        scamToken.transfer(msg.sender, amount);
        
        checkAccountEmpty(id);
    }
    
    
    function withdrawBnb(uint256 amount) public onlyRegistered
    {
		uint256 id = addressToId[msg.sender];
        balancesBnb[id] = balancesBnb[id].sub(amount);
        
		msg.sender.call{value: amount}("");
		
		checkAccountEmpty(id);
    }
    
    
    function deleteAccount() external onlyRegistered
    {
        BEP20 scamToken = BEP20(SCAM_TOKEN_ADDRESS);
        
        uint256 id = addressToId[msg.sender];
        addressToId[msg.sender] = 0;
        
        scamToken.transfer(msg.sender, balancesScam[id]);
        msg.sender.call{value: balancesBnb[id]}("");
        
        checkAccountEmpty(id);
    }
    
    
    function checkAccountEmpty(uint256 id) private
    {
        if (balancesBnb[id] == 0 && balancesScam[id] == 0)
        {
            addressToId[msg.sender] = 0;
            addressRegistered[msg.sender] = false;
        }
    }
    
    
    
    function registerAccount() private
    {
        addressRegistered[msg.sender] = true;
	    addressToId[msg.sender] = Count;
	    
	    balancesScam[Count] = 0;
	    balancesBnb[Count] = 0;
		
		Count = Count.add(1);
    }

}





// Interface for BEP20
abstract contract BEP20 {
    
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function transferFrom(address owner, address buyer, uint numTokens) virtual external returns (bool);
    function totalSupply() virtual external view returns (uint256);
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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