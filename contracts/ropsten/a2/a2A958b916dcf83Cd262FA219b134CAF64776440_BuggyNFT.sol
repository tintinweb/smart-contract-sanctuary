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

