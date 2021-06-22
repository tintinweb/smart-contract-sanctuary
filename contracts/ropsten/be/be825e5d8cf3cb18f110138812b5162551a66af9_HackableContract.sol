/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// Solidity Riddle:
// Break the contract and keep all deposited $SCAM
// No initial $SCAM holdings are required to break this contract


// Social Media
// https://www.reddit.com/r/scam_coin/
// https://t.me/SCAM_Coin_Community


// Website
// https://scam-coin.org/


// WARNING
// This scamart contract is designed to be exploitable!
// Don't deposit any $SCAM that you are not willing to lose!



pragma solidity =0.7.6;


contract HackableContract {

    address public constant SCAM_ADDRESS = 0xdb78FcBb4f1693FDBf7a85E970946E4cE466E2A9;
        
    uint8 public Count = 0;
    mapping(address => bool) addressRegistered;
	mapping(address => uint8) addressToId;
	mapping(uint8 => uint256) balances;
	
	
	function DepositScam(address origin, uint256 amount) external
	{
	    BEP20 scamToken = BEP20(SCAM_ADDRESS);
	    
	    if (!addressRegistered[origin])
	    {
	        Count++;
	        addressRegistered[origin] = true;
	        addressToId[origin] = Count;
	        balances[Count] = 0;
	    }
	    
	    uint8 id = addressToId[origin];
	    balances[id] += amount;
	    scamToken.transferFrom(origin, address(this), amount);
	}



    function WithdrawScam(uint256 amount) external 
    {
        BEP20 scamToken = BEP20(SCAM_ADDRESS);
        uint256 bal = balances[addressToId[msg.sender]];
        
        require(amount <= bal);
        scamToken.transfer(msg.sender, bal);
    }

}





// Interface for BEP20
abstract contract BEP20 {
    
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function transferFrom(address owner, address buyer, uint numTokens) virtual external returns (bool);
    function totalSupply() virtual external view returns (uint256);
}