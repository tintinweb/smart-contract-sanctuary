pragma solidity ^0.5.0;

import "./token.sol";

contract FILXTokenSale {
    address payable admin;
    FilxToken public tokenContract;


    constructor(FilxToken _tokenContract) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
    }

    function buyTokens(uint256 _numberOfTokens) public payable{
        
        require(
            _numberOfTokens == msg.value / 10**14,
            "Number of tokens does not match with the value"
        );
        

        require(
            tokenContract.balanceOf(address(this)) >= _numberOfTokens,
            "Contact does not have enough tokens"
        );
        require(
            tokenContract.transfer(msg.sender, _numberOfTokens),
            "Some problem with token transfer"
        );
    }

    function endSale() public {
        require(msg.sender == admin, "Only the admin can call this function");
        require(
            tokenContract.transfer(
                address(0),
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens to 0x0000"
        );
        // destroy contract
        selfdestruct(admin);
    }
}