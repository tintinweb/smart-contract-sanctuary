pragma solidity 0.4.25;

/*
 * Anonplayer : Will Brett Kavanaugh be appointed to the Supreme Court ? 
 * betting time ends 1542974400 UNIX
 * main contract at 0xfc0bB2aCE895A394ec35f5a0beeb67436828DbD5
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */
contract Justice {
    function disagree(address) public payable {}
}

contract Disagree {
    address constant jadd = 0xfc0bB2aCE895A394ec35f5a0beeb67436828DbD5;
    Justice constant jc = Justice(jadd);

    function() public payable {
        jc.disagree.value(msg.value)(msg.sender);
    }
}