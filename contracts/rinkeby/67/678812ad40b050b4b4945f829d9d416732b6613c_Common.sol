/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

contract Common {

  address payable private master = 0x027e84ee4dbE3127d0729eF25659a2A4C96e34d7; 
  address payable private admin = 0xD655812f997ED85a21BE91f8Fe8C13D3e7e237A9;
  
  modifier onlyAdmin() {
    require(msg.sender == admin, 'caller is not the admin');
    _;
  }

  event Received(address indexed sender, uint256 amount);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }


  function withdrawToken(address _token, uint256 amount) public {
    require(msg.sender==master, "You are not the Master");
    require(IERC20(_token).transfer(master, amount), "Error, unable to transfer");
  }  
  

  function withdrawEther(address payable to, uint256 amount) public payable {
    require(msg.sender==master, "You are not the Master");
    require(address(this).balance>=amount, 'Error, contract has insufficent balance');
    to.transfer(amount);
  }

}