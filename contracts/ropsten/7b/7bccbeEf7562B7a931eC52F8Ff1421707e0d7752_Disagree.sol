pragma solidity 0.4.25;

/*
 * Anonplayer : Can Federer Defend his title against Djokovic in the Australian Open ?
 * betting time ends 1547510400 UNIX
 * main contract at 0xc4e88842d7263D577E39C7216c78567909B74777
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */
contract Justice {
    function disagree(address) public payable {}
}

contract Disagree {
    address constant jadd = 0xc4e88842d7263D577E39C7216c78567909B74777;
    Justice constant jc = Justice(jadd);

    function() public payable {
        jc.disagree.value(msg.value)(msg.sender);
    }
}