/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

pragma solidity ^0.6.12;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  }

contract MyContract {

    IERC20 usdt = IERC20(address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee));
    IERC20 token = IERC20(address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee));

    function swap(uint256 amount) public {
        usdt.transferFrom(msg.sender, address(this), amount);

        amount = amount * 66/100;
        token.transfer(msg.sender, amount);
    }
}