/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.5.0;

// From https://ethereum.stackexchange.com/a/88292
contract Ownable {

    address private owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }
}

contract Claims is Ownable {

//    uint claimCount = 0;

    event Claim(string publicHash, string publicLocator, string privateHash);

    function claim(string memory publicHash, string memory publicLocator, string memory privateHash) public onlyOwner {

//        claimCount += 1;
        
        emit Claim(publicHash, publicLocator, privateHash);
        
    }

//    function getClaimCount() public view returns (uint) {
//
//        return claimCount;
//
//    }

}