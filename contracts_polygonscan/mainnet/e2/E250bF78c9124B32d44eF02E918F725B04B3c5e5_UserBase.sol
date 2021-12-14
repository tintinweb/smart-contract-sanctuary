/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
contract UserBase {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c=a*b;assert(a==0 || c / a==b);return c;}
  function div(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a / b;return c;}
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {assert(b <= a);return a - b;}
  function add(uint256 a, uint256 b) internal pure returns (uint256) {uint256 c = a + b;assert(c >= a);return c;}
  /*[ CONTRACT ADDRESSES ]----------------------------------------------------------------------------------------------------------*/
  address public owner = msg.sender;                                              /*                                                */
  address public developer = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551); /* Development Teams Address                      */
  address public governor = address(0x4f158D866CD0eb72bb642bBbD8D3c5Cc676E3551);  /* Address for future governance contract         */
  address public marketing = address(0x08BFcad8b37ee488cd43fdAa87700a4c7FA2A9A3); /* Marketing Departments Address                  */
  address public blank = address(0x0000000000000000000000000000000000000000);     /*                                                */
  /*[ USER DATA ]-------------------------------------------------------------------------------------------------------------------*/
  mapping(address => bool) public isUser;                           /* Wether a User exists                                         */
  mapping(address => address) public usersReferrer;                 /* Address of Referrer                                          */
  mapping(address => uint) public referralQty;                      /* Total Referral Quantity                                      */ 
  mapping(address => bool) public whitelisting;                        /* Whitelisted Contract Addresses                               */
  /*[ BASIC FUNCTIONS ]-------------------------------------------------------------------------------------------------------------*/
  function checkUser (address _addy, address _ref) public returns(address, address, uint256) {
    require(whitelisting[msg.sender],"BlackListd");
    if(isUser[_addy]){
      /*Yes, user exists*/
      _ref=usersReferrer[_addy];
    }else{
      isUser[_addy]=true;
      referralQty[_addy]=0;
        /*Make sure user is not referring themselves*/
      if(_ref==_addy){_ref=developer;}else
        /*Replace no-referrer with Marketing*/
      if(_ref==blank){_ref=marketing;}
        /*Check Referrers Status*/
      if(!isUser[_ref]) { 
          /*Referrer does NOT exist as User, make them a User and this users new Referrer*/
        isUser[_ref]=true;
        usersReferrer[_addy]=_ref;
        referralQty[_ref]=add(referralQty[_ref],1);
      }else{ 
          /*Referrer DOES exist as User, make them this users new Referrer*/
        usersReferrer[_addy]=_ref;
        referralQty[_ref]=add(referralQty[_ref],1);
      }
    }
    return(_addy,_ref,referralQty[_addy]);
  }
  function whitelist (address _addy, uint256 _meth) public {
    require(msg.sender==governor,"NotGov");
    if(_meth==1){/*Add a Whitelisted Address*/ whitelisting[_addy]=true;}else
    if(_meth==2){/*Remove a Whitelisted Address*/ whitelisting[_addy]=false;}
  }
}