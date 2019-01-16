pragma solidity 0.4.25;

/*
 * Anonplayer : Who will win the 2019 Indian general election ?(Modi|Gandhi)
 * betting time ends 1554076800 UNIX
 * main contract at 0x392bF3c9C006AC464d9eD658e96Cae06b23120BA
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */
contract Justice {
    function disagree(address) public payable {}
}

contract Disagree {
    address constant jadd = 0x392bF3c9C006AC464d9eD658e96Cae06b23120BA;
    Justice constant jc = Justice(jadd);

    function() public payable {
        jc.disagree.value(msg.value)(msg.sender);
    }
}