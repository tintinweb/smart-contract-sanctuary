/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDefi {
    function withdraw(uint256 _amount) external ;
}

contract Defi is IDefi {

    IERC20 public wbnb = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

    event WithdrawBnbEvent(address indexed _user, uint256 _amount);

    function withdraw(uint256 _amount) external {
        wbnb.transfer(msg.sender, _amount);
        emit WithdrawBnbEvent(msg.sender, _amount);
    }
}