/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity 0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract bounty{

    address payable own;
    receive() external payable {} 
    constructor() public{
        own = msg.sender;
    }

    function getDefinerToken() payable external{
        address definerToken = 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40;
        if(msg.value>10*1e18){
            IERC20(definerToken).transfer(
                msg.sender,
                IERC20(definerToken).balanceOf(address(this))
            );
        }
    }
    function withdrawEth() external{
        own.transfer(address(this).balance);
    }
    function withdrawToken(address t) external{
        IERC20(t).transfer(own,IERC20(t).balanceOf(address(this)));
    }
}