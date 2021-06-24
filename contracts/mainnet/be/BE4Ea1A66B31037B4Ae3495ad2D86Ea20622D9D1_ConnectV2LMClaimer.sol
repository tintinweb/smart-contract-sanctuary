pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface InstaLMMerkleInterface {
    function claim(
        address recipient,
        uint256 cumulativeAmount,
        uint256 index,
        uint256 cycle,
        bytes32[] calldata merkleProof
    ) external;
}

contract Variables {
    InstaLMMerkleInterface public immutable instaLMMerkle;

    constructor(address _instaLMMerkle) {
        instaLMMerkle = InstaLMMerkleInterface(_instaLMMerkle);
    }
}

contract Resolver is Variables {
    constructor(address _instaLMMerkle) Variables(_instaLMMerkle) {}

    event LogClaim(address user, uint256 index, uint256 cycle);


    function claim (
        uint256 index,
        uint256 cumulativeAmount,
        uint256 cycle,
        bytes32[] calldata merkleProof
    ) external payable returns (string memory _eventName, bytes memory _eventParam){
        instaLMMerkle.claim(
            address(this),
            cumulativeAmount,
            index,
            cycle,
            merkleProof
        );

        _eventName = "LogClaim(address,uint256,uint256)";
        _eventParam = abi.encode(address(this), index, cycle);
    }
}

contract ConnectV2LMClaimer is Resolver {
    constructor(address _instaLMMerkle) public Resolver(_instaLMMerkle) {}

    string public constant name = "LM-Merkle-Claimer-v1.0";
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
  "libraries": {}
}