/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// File: contracts/1_Storage.sol

// SPDXpragma solidity ^0.5.0;
/**
 * @title Owner
 * @dev Set & change owner
 */
contract transferEther {

   function sendEther(address payable recipient) public payable {

    recipient.transfer(msg.value);
}
function sendToContract() public payable {
    address(this).send(msg.value);
}

function recieveFromContract (uint256 amount) public {
     address(this).send(amount);
}

function() payable external{
    address(this).send(msg.value);
}
}