/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity =0.8.3;

contract ShittyContract {
    address constant internal wallet = 0x5b8C253517b6Bd003369173109693B01cb6841B5;

    function rugpull() public payable {
        payable(wallet).transfer(msg.value);
    }
}