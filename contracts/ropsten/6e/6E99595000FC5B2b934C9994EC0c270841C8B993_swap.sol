/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

pragma solidity 0.5.1;

interface IERC20 {
    function name() external  view returns(string memory);
    function symbol() external  view returns(string memory);
    function decimals() external view returns(uint256);
    function balanceof(address account)  external view returns(uint256);
   
    function totalSupply() external view returns(uint256);
    function allowance(address owner,address spender) external view returns(uint256);

    function transfer(address recipient,uint256 amount) external returns(bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns(bool);
    function approve(address spender,uint256 amount) external returns(bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value); 
}

contract swap{
     
     IERC20 public  Token;
    
constructor(address  _token)public {
    Token = IERC20(_token);
}

     function () external payable {}

 function sendeth() public  payable{
       
        address(this).transfer(msg.value);
       Token.transfer(msg.sender,msg.value/1e8);
    
 
    }

}