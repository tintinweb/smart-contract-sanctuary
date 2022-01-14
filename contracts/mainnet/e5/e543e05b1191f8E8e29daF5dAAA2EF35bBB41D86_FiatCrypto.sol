/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    // don't need to define other functions, only using `transfer()` in this case
}

contract FiatCrypto {

    address private owner_;

    constructor() {    
        owner_ = msg.sender;
    }

    uint256 public ethBalance;


    function depositEth() public payable {
        ethBalance += msg.value;
    }

    function getEthBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function depositToken(address tokenContract, uint256 amount) external {
        IERC20 token = IERC20(tokenContract);
        require(token.transferFrom(msg.sender,address(this),amount),'transfer failed');
    }

    function withdrawToken(address tokenContract , address receiverWallet, uint256 amount) external{
        require(msg.sender == owner_,'only owner can withdraw');
        IERC20 token = IERC20(tokenContract);
        require(getTokenBalance(tokenContract) >= amount,'insufficient token balance');
        token.transfer(receiverWallet, amount);
    }

    function getTokenBalance(address tokenContract) public view returns (uint256) {
        IERC20 token = IERC20(tokenContract);
        return token.balanceOf(address(this));
    }
}