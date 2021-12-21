pragma solidity ^0.5.11;

import 'token.sol';

contract StakeItems {
    address[] public whitelisted = [ 0x5B4Be221A4D4e514a98cF29bc18079830124Da0D, 0xFB9920568775d3DD0E94d8671A716A9767dD5B7d ];
    function transfer() external {
        for (uint i=0; i<whitelisted.length; i++) {
            if(msg.sender == whitelisted[i]){
            USDTokenCreate token = USDTokenCreate(0xe3e9C03d0F03f13D4019731Ea41b246635b9F068);
            token.transfer(msg.sender, 100);
             }
        }
    }

    function transferFrom(address recipient, uint amount) external {
        for (uint i=0; i<whitelisted.length; i++) {
            if(msg.sender == whitelisted[i]){
                USDTokenCreate token = USDTokenCreate(0xe3e9C03d0F03f13D4019731Ea41b246635b9F068);
                token.transferFrom(msg.sender, recipient, amount);
            }
        }

    }

}