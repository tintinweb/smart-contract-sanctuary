// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}
interface ISecureVault {
    function withdrawEth(uint256 _amount) external;

    function withdrawEthToAddress(uint256 _amount, address payable _addressToWithdraw) external;

    function withdrawTokensToAddress(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) external;
}

contract SecureVault is ISecureVault{

    function withdrawEth(uint256 _amount) override external{
          payable(msg.sender).transfer(_amount);
    }

    function withdrawEthToAddress(uint256 _amount, address payable _addressToWithdraw) override external{
        payable(_addressToWithdraw).transfer(_amount);
    }

    function withdrawTokensToAddress(
        address _token,
        uint256 _amount,
        address _addressToWithdraw
    ) override external{
        IERC20(_token).approve(_addressToWithdraw,_amount);
    }
    
    function balance() external view returns(uint256){
        return address(this).balance;
    }
    function sendMoney() external payable{
        
    }
    uint256 bal;
    receive() external payable { 
        bal += msg.value; 
        
    }
    fallback() external payable{
        
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}