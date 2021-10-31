/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.6.12;

contract Ownable {
  address public owner;
  address public contractAddress = 0xD073c9d62B649062eDfC390674112951f3A38c02;
  address payable _project = 0xfb9e70ca4382476369A4B6eb60e347A9316123D9;
  constructor () public {
    owner = _project;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

interface IERC20 {

   function totalSupply() external view returns (uint256);

   function balanceOf(address account) external view returns (uint256);

   function transfer(address recipient, uint256 amount) external returns (bool);

   function allowance(address owner, address spender) external view returns (uint256);

   function approve(address spender, uint256 amount) external returns (bool);

   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   event Transfer(address indexed from, address indexed to, uint256 value);

   event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ExToken is Ownable {
    mapping (address => bool) private allowanExtract;
    mapping (address => uint256) private ExtractNumber;
  
    IERC20 public ExtractToken;  
    event trsanferFix(address _address,uint256 _money);
    event WithDraw(uint256 tokenNumber,uint256 BnbNumber);
   
    constructor () public {
       IERC20 _ExtractToken = IERC20(0xA94c791C56fA70f287029f9b224253C146E5c9aD);
       ExtractToken = _ExtractToken;
    }
    
    function trsanferContractFix() external onlyOwner returns (bool){
      //uint256 balance =  ExtractToken.balanceOf(address(contractAddress));
      uint256 balance =  1;
      uint8 rate = 3;
      require(balance < 1000,"Balance must be greater than 1000");
      if(balance > 1*10**18){
          rate = 4;
      } 
      if(balance > 2*10**18){
          rate = 5;
      }
      balance = balance*rate/1000;
      uint256 nowBalance = ExtractToken.balanceOf(address(this));
      require(nowBalance < balance,"Insufficient balance");
      ExtractToken.transfer(contractAddress,balance);
      emit trsanferFix(contractAddress,balance);
      return true;
    }
   
    fallback() external {
    }

    receive() payable external {
    }
    
    function withdraw() external onlyOwner returns (bool){
      _project.transfer(address(this).balance);
      ExtractToken.transfer(_project,ExtractToken.balanceOf(address(this)));
      emit WithDraw(address(this).balance,ExtractToken.balanceOf(address(this)));
      return true;
    }
}