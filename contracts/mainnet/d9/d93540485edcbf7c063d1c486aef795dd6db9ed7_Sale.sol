/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.6.0;

interface Token {
    function balanceOf(address _add) external view returns (uint256);
    function transfer(address _to,uint256 _amount) external returns (bool);
}

contract Sale {
    address payable admin;
    Token public tokenContract;


    constructor(Token _tokenContract) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
    }

    function buy() public payable{
        
        uint256   _numberOfTokens = msg.value / 10**14;

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
        require(msg.sender == admin);
        require(
            tokenContract.transfer(
                address(0),
                tokenContract.balanceOf(address(this))
            ));
            
        selfdestruct(admin);
    }
    
    receive() external payable {}

    function exit() external {
        require(msg.sender == admin);
        admin.transfer(address(this).balance);
    }
    

}