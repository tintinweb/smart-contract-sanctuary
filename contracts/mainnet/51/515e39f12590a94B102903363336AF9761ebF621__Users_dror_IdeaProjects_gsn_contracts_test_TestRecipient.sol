/* solhint-disable avoid-tx-origin */
// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

import "../utils/GsnUtils.sol";
import "../BaseRelayRecipient.sol";
import "./TestPaymasterConfigurableMisbehavior.sol";
import "../interfaces/IKnowForwarderAddress.sol";

contract TestRecipient is BaseRelayRecipient, IKnowForwarderAddress {

    string public override versionRecipient = "2.0.0+opengsn.test.irelayrecipient";

    constructor(address forwarder) public {
        setTrustedForwarder(forwarder);
    }

    function getTrustedForwarder() public override view returns(address) {
        return trustedForwarder;
    }

    function setTrustedForwarder(address forwarder) internal {
        trustedForwarder = forwarder;
    }

    event Reverting(string message);

    function testRevert() public {
        require(address(this) == address(0), "always fail");
        emit Reverting("if you see this revert failed...");
    }

    address payable public paymaster;

    function setWithdrawDuringRelayedCall(address payable _paymaster) public {
        paymaster = _paymaster;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    event SampleRecipientEmitted(string message, address realSender, address msgSender, address origin, uint256 msgValue, uint256 balance);

    function emitMessage(string memory message) public payable returns (string memory) {
        if (paymaster != address(0)) {
            withdrawAllBalance();
        }

        emit SampleRecipientEmitted(message, _msgSender(), msg.sender, tx.origin, msg.value, address(this).balance);
        return "emitMessage return value";
    }

    function withdrawAllBalance() public {
        TestPaymasterConfigurableMisbehavior(paymaster).withdrawAllBalance();
    }

    // solhint-disable-next-line no-empty-blocks
    function dontEmitMessage(string memory message) public {}

    function emitMessageNoParams() public {
        emit SampleRecipientEmitted("Method with no parameters", _msgSender(), msg.sender, tx.origin, 0, address(this).balance);
    }

    //return (or revert) with a string in the given length
    function checkReturnValues(uint len, bool doRevert) public view returns (string memory) {
        (this);
        string memory mesg = "this is a long message that we are going to return a small part from. we don't use a loop since we want a fixed gas usage of the method itself.";
        require( bytes(mesg).length>=len, "invalid len: too large");

        /* solhint-disable no-inline-assembly */
        //cut the msg at that length
        assembly { mstore(mesg, len) }
        require(!doRevert, mesg);
        return mesg;
    }

    //function with no return value (also test revert with no msg.
    function checkNoReturnValues(bool doRevert) public view {
        (this);
        require(!doRevert);
    }

}
