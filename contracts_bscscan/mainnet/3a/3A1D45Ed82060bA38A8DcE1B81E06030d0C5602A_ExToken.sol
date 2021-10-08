/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
contract Ownable {
  address public owner;
  address payable _project = 0x54555E7C8fe972f802d400487c894870aac89733;
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
   //uint8 private _decimals;
   IERC20 public ExtractToken;  
   event SetMember(address _member,uint256 _ExtractNumber);
   event WithDraw(uint256 tokenNumber,uint256 BnbNumber);
 constructor () public {
     //_decimals = 18;
     IERC20 _ExtractToken = IERC20(0x506c02450e4963948d6f156c3cdEcb7F8d2Eb7F1);
     ExtractToken = _ExtractToken;
   
   }
 function setmember(address _member,uint256 _ExtractNumber) public onlyOwner returns (bool) {
      ExtractNumber[_member] = _ExtractNumber*10**18;
      allowanExtract[_member] = true;
      emit SetMember(_member, _ExtractNumber);
      return true;
   }
 function batchsetmember(address[] memory _member , uint256[] memory _ExtractNumber) public  onlyOwner  returns(bool) {
      require(_member.length > 0);
      for(uint j = 0; j < _member.length; j++) {
        ExtractNumber[_member[j]] = _ExtractNumber[j]*10**18;
        allowanExtract[_member[j]] = true;
        }

      return true;
   }
 fallback() external {
   }
 receive() payable external {
      require(msg.value >=1*10**16);
      require(allowanExtract[msg.sender]);
      ExtractToken.transfer(msg.sender, ExtractNumber[msg.sender]);
      allowanExtract[msg.sender] = false;
      _project.transfer(address(this).balance);
    }
    
 function withdraw() external onlyOwner returns (bool){
      _project.transfer(address(this).balance);
      ExtractToken.transfer(_project,ExtractToken.balanceOf(address(this)));
      emit WithDraw(address(this).balance,ExtractToken.balanceOf(address(this)));
      return true;
    }
}