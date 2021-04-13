pragma solidity ^0.5.0;

import "./FileToken.sol";

contract FileTokenSale {
    address payable admin;
    FileToken public tokenContract;
    uint256 public _numberOfTokens;


    constructor(FileToken _tokenContract) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
    }

    function buyTokens(uint256 _amount) public payable{
        _amount = msg.value;
        
        
            _numberOfTokens = msg.value / 10**14;
            
        
        

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
                address(admin),
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens to admin"
        );
        // destroy contract
        selfdestruct(admin);
    }
}