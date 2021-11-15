// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

contract AccessRestriction {
    address public owner;
    bytes32 private accessHash;

    modifier onlyOwner(){
        require(owner == msg.sender, "NOT_OWNER_CALL");
        _;
    }

    modifier onlyOwnerBy(address sender){
        require(owner == sender, "NOT_OWNER_CALL");
        _;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "NOT_CALLED_BY_RIGHT_ADDRESS");
        _;
    }

    modifier onlyByHash(bytes32 hash) {
        require(accessHash == hash, "NOT_RIGHT_HASH");
        _;
    }

    function getAccessHash() onlyOwner external view returns (bytes32)
    {
        return accessHash;
    }

    constructor() public {
        owner = msg.sender;
        accessHash = keccak256(abi.encode(block.timestamp)); //todo generate truly random hash
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.17;

import "./AccessRestriction.sol";

contract Challenger is AccessRestriction {

    function unlockChallenge() internal {}

    function submitData(bytes32 hash) onlyByHash(hash) external {

    }
}

