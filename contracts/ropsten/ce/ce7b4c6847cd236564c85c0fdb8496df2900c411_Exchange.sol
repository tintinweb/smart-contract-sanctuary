pragma solidity ^0.4.24;

/*
Testnet
Token:
0xd1d397a5010d9a6a98bb275aeaaa5aa9dd2990ce
https://ropsten.etherscan.io/token/0xd1d397a5010d9a6a98bb275aeaaa5aa9dd2990ce

Exchange:
https://ropsten.etherscan.io/address/0x91f837ae732712a18a23fcbc20ac1d667aee9194

// Demo transaction:

*/

contract Exchange {
    address public owner;
    constructor() public {
        owner=msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    
    function gotFiatSendLDCToEscrow(erc20 token,uint256 fiat,string currency,string symbol,uint256 rate,uint256 leads_count,address to) public onlyOwner {
        token.transfer(to,rate * fiat);
        emit GotFiat( token, fiat, currency, symbol, rate, to,rate*fiat,leads_count) ;
        emit SendLDCToEscrow( token, fiat, currency, symbol, rate, to,rate*fiat,leads_count) ;
    }
    function gotLDCSendFiat(erc20 token,uint256 fiat,string currency,string symbol,uint256 rate,address to,uint256 amount) public  onlyOwner{
        emit GotLDCSendFiat( token, fiat, currency, symbol, rate, to,amount) ;
    }
    event GotFiat(erc20 token,uint256 fiat,string currency,string symbol,uint256 rate,address to,uint256 total,uint256 leads_count) ;
    event SendLDCToEscrow(erc20 token,uint256 fiat,string currency,string symbol,uint256 rate,address to,uint256 total,uint256 leads_count) ;
    event GotLDCSendFiat(erc20 token,uint256 fiat,string currency,string symbol,uint256 rate,address to,uint256 amount) ;
}

contract erc20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}