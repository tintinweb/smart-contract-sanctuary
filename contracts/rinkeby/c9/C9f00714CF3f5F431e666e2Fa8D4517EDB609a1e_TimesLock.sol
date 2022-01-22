//SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

contract TimesLock{
     //who can withdraw?
     //how much?
     //when?
     address payable benefciary;
     uint256 releaseTime;

    constructor(address payable _benefciary,uint256 _releaseTime)public {
    require(_releaseTime >= block.timestamp);
      benefciary = _benefciary;
      releaseTime = _releaseTime;
    }

    function release() public payable{
       // require(block.timestamp >= releaseTime);
        address(benefciary).transfer(address(this).balance);
    }

}