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
address  tokenAdr=0x350FE9D2c2A0058f1b39B86da63bF4C41aEf4076; 
address _dai=0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa;
address student_contract=0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
address agregator=0xE0D8bED6372D71e6Bed471aE230E0a491bB26Fdc; 
  
 uint256 pric=get_price()/success_done_count(); 

function buyTokensForETH() payable public{
uint val;

 val=msg.value*pric;
 uint bal_fin = ierc20(tokenAdr).balanceOf(address(this)); 
    if(bal_fin>val){  
token(tokenAdr).transfer(msg.sender,val);
    } else {
msg.sender.call{gas:255939,value:msg.value}("Sorry,there is not enough tokens");

    }
}

function buyTokensForDAI(uint _amount)  public{

 uint bal_fin = ierc20(tokenAdr).balanceOf(address(this)); 
    if(bal_fin>_amount){  
token_tr(_dai).transferFrom(msg.sender,address(this),_amount);
    } else {
revert("Sorry,there is not enough tokens to buy");

    }
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