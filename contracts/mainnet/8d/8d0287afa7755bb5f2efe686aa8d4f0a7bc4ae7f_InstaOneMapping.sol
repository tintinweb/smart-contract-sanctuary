/**
 *Submitted for verification at Etherscan.io on 2020-08-14
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IndexInterface {
    function master() external view returns (address);
}

interface ConnectorsInterface {
  function chief(address) external view returns (bool);
}

contract Helpers {

    event LogChangeOneProto(address oneProto);

    address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    address public oneProtoAddress;

    modifier isChief {
        require(
        ConnectorsInterface(connectors).chief(msg.sender) ||
        IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
        _;
    }

    function changeOneProtoAddress(address _oneProtoAddr) external isChief {
        require(_oneProtoAddr != address(0), "oneProtoAddress-is-address(0)");
        require(oneProtoAddress != _oneProtoAddr, "Same-oneProtoAddress");

        oneProtoAddress = _oneProtoAddr;
        emit LogChangeOneProto(_oneProtoAddr);
    }
}

contract InstaOneMapping is Helpers {
    constructor () public {
        oneProtoAddress = 0x6cb2291A3c3794fcA0F5b6E34a8E6eA7933CA667;
    }
}