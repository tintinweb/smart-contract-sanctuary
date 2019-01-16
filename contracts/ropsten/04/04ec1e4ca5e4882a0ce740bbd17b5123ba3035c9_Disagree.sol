pragma solidity 0.4.25;

/*
 * Anonplayer : INSERT_STATEMENT_HERE
 * betting time ends INSERT_UNIX_HERE UNIX
 * main contract at INSERT_ADDRESS_HERE
 * The fallback function allows you to bet disagree / 2nd-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */
contract Justice {
    function disagree(address) public payable {}
}

contract Disagree {
    address constant jadd = 0xA4735b86aedFf304B351029245ff0780b442e09D;
    Justice constant jc = Justice(jadd);
    
    function() public payable {
        jc.disagree.value(msg.value)(msg.sender);
    }
         

//    if (!(INSERT_ADDRESS_HERE).call.value(msg.value)(bytes4(keccak256("disagree()")), msg.sender)) revert();

}