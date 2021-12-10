/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
interface token{
function transfer(address _to, uint256 _value) external returns (bool);
}
interface token_tr{
 function transferFrom(
    address sender,address recipient,uint256 amount
    ) external returns (bool)  ;
}
interface get_interface {
     function getStudentsList() external view returns (string[] memory stdents); 
}
interface ierc20{
     function balanceOf(address account)  view external returns (uint);
}
interface get_pr{
    function getLatestPrice() external view returns (uint);
}
contract Exchange{
address  tokenAdr=0xF687dD45b10A29dcB79769038f57f2e52e52f1aC; 
address _dai=0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
address student_contract=0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
address agregator=0xE0D8bED6372D71e6Bed471aE230E0a491bB26Fdc; 
address sigma=0x515Dcbe2cCF7d159CBc7C74DA99DeeD04F671725;  
 

function buyTokensForETH() payable public {
uint val;
uint256 pric=get_price()/success_done_count(); 
 val=msg.value*pric;
 uint bal_fin = ierc20(tokenAdr).balanceOf(address(this)); 
    if(bal_fin>val){  
token(tokenAdr).transfer(msg.sender,val);
    } else {
msg.sender.call{gas:255939,value:msg.value}("Sorry,there is not enough tokens");

    }
}

function buyTokensForToken(address _token,uint _amount)  public{
address _to=msg.sender;
address exch=address(this);
 uint bal_fin = ierc20(tokenAdr).balanceOf(address(this)); 
    if(bal_fin>_amount){  
token_tr(_token).transferFrom(_to,exch,_amount);
token(tokenAdr).transfer(_to,_amount);
    } else {
revert("Sorry,there is not enough tokens to buy");

    }
}
function buyTokens(address _token,uint _amount) public payable{
address _to=msg.sender;
address exch=address(this);
uint bal_sigma = ierc20(sigma).balanceOf(_to); //check sigma balans of sender
uint val;
uint256 pric=get_price()/success_done_count(); 
if(msg.value!=0){ val=msg.value*pric;}
if(msg.value==0){ val=_amount;}

if(bal_sigma>0) {
     uint bal_fin = ierc20(tokenAdr).balanceOf(address(this)); 
if(bal_fin>val) {
if(_token==address(0)){
require(msg.value>0);
} else { 
token_tr(_token).transferFrom(_to,exch,_amount);
token(tokenAdr).transfer(_to,_amount);
}
} else {revert("sorry,we dont have so much tokens as you need"); }
} else {revert("you have no SigmaToken"); }



}

function success_done_count() public view returns(uint) {
  string[] memory students =get_interface(student_contract).getStudentsList();
  uint lengt=students.length;
  return lengt;
  } 
function get_price() public view returns(uint){
    uint price=get_pr(agregator).getLatestPrice();
    uint delprice=price/100000000;
    return delprice;
}

}