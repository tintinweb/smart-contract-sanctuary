pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

import "./presalecontract.sol";


contract CreatePresale{

    PresaleContract public presale;

    IBEP20[] public deployedPresaleAddresses;
    //address payable public owner;

    uint256 public fee = 0.5 ether;




    function createPresaleCreation (IBEP20 _token) external {

        require(address(this).balance > fee,"Not enough balance in parent contract");

        presale = new PresaleContract(_token);
        deployedPresaleAddresses.push(_token);
        //tokenOwner.transfer(fee);

    }


    function getAllAddresses() public view returns (IBEP20[] memory){
        return deployedPresaleAddresses;
    }




    function setFee(uint256 _fee) public {
        fee = _fee;
    }



    /*function withdraw() public {
        require(msg.sender == owner, "Only owner is allowed!");
        owner.transfer(address(this).balance);
    }*/


}