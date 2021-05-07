pragma solidity ^0.6.0;

import "@opengsn/gsn/contracts/BaseRelayRecipient.sol";

contract SyntFunctionWithForwarder  is BaseRelayRecipient{
    address public portal;
    address public token;

    function versionRecipient() override view  public returns (string memory){
        return "2.0.1";
    }

    constructor (address portal_, address token_, address forwarder_) public {
        portal = portal_;
        token = token_;
        trustedForwarder = forwarder_;
    }

    function calcCallDataSyntSignature(address _token, uint256 _amount, address _to) pure public returns (bytes memory data){
        return abi.encodeWithSignature("synthesize(address,uint256,address)", _token, _amount, _to);
    }

    function calcCallDataApprovalSignature(address _to, uint _amount) pure public returns (bytes memory data){
        return abi.encodeWithSignature("approve(address,uint256)", _to, _amount);
    }


    function calcCallDataSynt(address _token, uint256 _amount, address _to ) pure public returns (bytes memory data){
        return abi.encode("synthesize(address,uint256,address)", _token, _amount, _to);
    }

    function calcCallDataApproval(address _to, uint _amount) pure public returns (bytes memory data){
        return abi.encode("approve(address,uint256)", _to, _amount);
    }

    function calcSyntFunctionWithSignature(address _to2chain, uint256 _amount) public returns (bytes memory data) {
        return abi.encodeWithSignature("syntFunction(address,uint)", _to2chain, _amount );

    }



    function syntFunction(address _to2chain, uint256 _amount ) public returns (bool success) {
        bytes memory approvalData   = calcCallDataApproval(portal, 999999999999999999999999999999999999999999999999);
        (bool _success1, ) = token.call(approvalData);
        require(_success1, "Approve call failed");
        bytes memory spendData   = calcCallDataSynt(token, _amount, _to2chain);
        (bool _success, ) = portal.call(spendData); // synt here
        // todo add to synt msgsender() support
        require(_success, "Spend call fails");
        return true;
    }

    function syntFunction2(bytes calldata approvalData, bytes calldata _spendData) public returns (bool success) {
        (bool _success1, ) = token.call(approvalData);
        require(_success1, "Approve call failed");
        (bool _success, ) = portal.call(_spendData); // synt here
        // todo add to synt msgsender() support
        require(_success, "Spend call fails");
        return true;

    }


}

// SPDX-License-Identifier:MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.6.2;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // we copy the msg.data , except the last 20 bytes (and update the total length)
            assembly {
                let ptr := mload(0x40)
                // copy only size-20 bytes
                let size := sub(calldatasize(),20)
                // structure RLP data as <offset> <length> <bytes>
                mstore(ptr, 0x20)
                mstore(add(ptr,32), size)
                calldatacopy(add(ptr,64), 0, size)
                return(ptr, add(size,64))
            }
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.2;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}