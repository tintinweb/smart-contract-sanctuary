// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;
import "../../contracts/BaseRelayRecipient.sol";

//make sure that "payable" function that uses _msgSender() still works
// (its not required to use _msgSender(), since the default function
// will never be called through GSN, but still, if someone uses it,
// it should work)
contract PayableWithEmit is BaseRelayRecipient {

  string public override versionRecipient = "2.0.0+opengsn.payablewithemit.irelayrecipient";

  event Received(address sender, uint value, uint gasleft);

  receive () external payable {

    emit Received(_msgSender(), msg.value, gasleft());
  }


  //helper: send value to another contract
  function doSend(address payable target) public payable {

    uint before = gasleft();
    // solhint-disable-next-line check-send-result
    bool success = target.send(msg.value);
    uint gasAfter = gasleft();
    emit GasUsed(before-gasAfter, success);
  }
  event GasUsed(uint gasUsed, bool success);
}
