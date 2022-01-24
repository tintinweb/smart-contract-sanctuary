/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// registered to their address as the owner of the nft 


// accessment contract is done:

// ----------------------

pragma solidity ^0.5.10;

contract Nft_InitialOwner{
    address public owner;
    uint256 public TokenId;

    
    event newOwner(address owner,string indexed data);


    constructor(uint256 _id) public payable{
        owner = msg.sender;
        TokenId = _id;
    }

    function balanceof() public view returns(uint256 balanceofaccount){
        return address(this).balance;
    }

    function _transferOwnership(address _newOwner) public{
        owner = _newOwner;
        emit newOwner(_newOwner,"Transfership is set");
    }
}