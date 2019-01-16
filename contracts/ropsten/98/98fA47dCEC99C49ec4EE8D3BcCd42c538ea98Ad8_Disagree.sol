pragma solidity 0.4.25;

/*
 * Anonplayer : Will ETH break 200$ before New Year ?
 * betting time ends 1546300800 UNIX
 * main contract at 0x04E0668401C6c6ed1C308081ADdf223983C518a1
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */
contract Justice {
    function disagree(address) public payable {}
}

contract Disagree {
    address constant jadd = 0x04E0668401C6c6ed1C308081ADdf223983C518a1;
    Justice constant jc = Justice(jadd);

    function() public payable {
        jc.disagree.value(msg.value)(msg.sender);
    }
}