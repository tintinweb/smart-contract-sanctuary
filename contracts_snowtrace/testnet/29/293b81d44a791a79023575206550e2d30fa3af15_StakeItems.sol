pragma solidity ^0.5.11;

import 'token.sol';

contract StakeItems {

    function transfer() external {
        USDTokenCreate token = USDTokenCreate(0xe3e9C03d0F03f13D4019731Ea41b246635b9F068);
        token.transfer(msg.sender, 100);
    }

    function transferFrom(address recipient, uint amount) external {
        USDTokenCreate token = USDTokenCreate(0xe3e9C03d0F03f13D4019731Ea41b246635b9F068);
        token.transferFrom(msg.sender, recipient, amount);
    }

}