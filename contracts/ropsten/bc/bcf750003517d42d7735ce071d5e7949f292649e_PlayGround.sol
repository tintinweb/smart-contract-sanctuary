/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract PlayGround{
   // using SafeERC20 for IERC20;
    address  public  _token;

     
    address public _owner  ;
    event testEv(bool success,bytes  returndata);
    constructor (){
        _token =  address(0xaf7115E9958b17c5C359C09D2180cCcE1bcD673B)  ;
        _owner = msg.sender;
    }
    
    /*function transferTest( uint256 _amount) public  {
         require(_token.balanceOf(address(msg.sender)) >= _amount,"Bache bia paein");
         
         _token.transfer( address(this) ,_amount);
    }*/
    function transferEncoded(uint amount) public {
        
                
        bytes memory data = abi.encodeWithSelector(0x837cf435,msg.sender,address(this), amount) ;
        
        (bool success, bytes memory returndata) = address(_token).call(data);
        
        emit testEv(success,returndata);
        

    }
    function balance() view public returns(uint256){
       // return _token.balanceOf(address(msg.sender));
    }
    function getAddress() view public returns(address){
        return address(this);
    }
    function myBalance() view public returns(uint256){
       // return _token.balanceOf(address(this));
    }
}