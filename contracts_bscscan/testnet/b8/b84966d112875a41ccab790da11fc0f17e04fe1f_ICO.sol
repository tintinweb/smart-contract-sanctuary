//pragma solidity >= 0.7.0;
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import './ACRYPTOSNFT.sol';

contract ICO{
   
     // The token being sold
    ACRYPTOSNFT public _token;
    uint256 public _rate; 
    address Owner = 0x84E519c487be8123dD1eBe283aEb0989213260A2;

    // Address where funds are collected
    address payable public _wallet;
   
      // Amount of wei raised
    uint256 public _weiRaised;
    
    event SendToken(address _senderAddress, uint256 _amount);

   
   constructor (uint256 rate, address payable wallet,  ACRYPTOSNFT token) public {
        require(rate > 0, "ICO: rate is 0");
        require(wallet != address(0), "ICO: wallet is the zero address");
        require(address(token) != address(0), "ICO: token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = ACRYPTOSNFT(token);
    }
   
    //   receive() external payable{
    //   }
    //   fallback () external payable {
    //   buyTokens(msg.sender);
    // }


  function buyTokens(address payable _senderAddress) public  payable {
    
        require(_senderAddress != address(0), "Crowdsale: beneficiary is the zero address");
        require(msg.value != 0, "Crowdsale: weiAmount is 0");
        _token.allowance(Owner, _wallet);
        _token.transferFrom(_wallet, msg.sender, msg.value*_rate);
        emit SendToken(msg.sender, msg.value);
    }
 
//  function ShareToken() payable public{
//      require(msg.sender != address(0), "Crowdsale: beneficiary is the zero address");
//      require(msg.value != 0, "Crowdsale: weiAmount is 0");
//      _token.transfer(msg.sender, msg.value* _rate);
//       emit SendToken(msg.sender, msg.value);
     
     
//  }
    function endsale() internal {
         require(msg.sender == _wallet , ' you are not the admin');
          selfdestruct(_wallet);
    }
}