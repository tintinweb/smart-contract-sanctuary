pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface InstaMakerMerkleInterface {
    function claim(
        uint256 index,
        uint256 vaultId,
        address dsa, 
        address owner,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof
    ) external;
}

interface ManagerLike {
    function ilks(uint256) external view returns (bytes32);
    function owns(uint256) external view returns (address);
    function urns(uint256) external view returns (address);
    function give(uint, address) external;
}

interface InstaListInterface {
    function accountID(address) external view returns (uint64);
}

interface InstaAccountInterface {
    function isAuth(address) external view returns (bool);
    function version() external view returns (uint256);
}


contract Variables {
    ManagerLike public constant managerContract =
        ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);

    InstaListInterface public constant instaList = 
        InstaListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

    InstaMakerMerkleInterface public immutable instaMakerMerkle;

    constructor(address _instaMakerMerkle) {
        instaMakerMerkle = InstaMakerMerkleInterface(_instaMakerMerkle);
    }
}

contract VaultResolver is Variables {
    constructor(address _instaMakerMerkle) Variables(_instaMakerMerkle) {}

    function transfer (
        uint256 index,
        uint256 vaultId,
        address dsa,
        address owner,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof
    ) public {
        require(instaList.accountID(dsa) != 0 && InstaAccountInterface(dsa).version() == 2, "InstaMakerDAOMerkleClaimer:: not a dsa");
        require(InstaAccountInterface(dsa).isAuth(msg.sender), "InstaMakerdaoMerkleDistributor:: msg.sender is not owner of DSAv2 wallet");

        managerContract.give(vaultId, dsa);
        instaMakerMerkle.claim(
            index,
            vaultId,
            dsa,
            owner,
            rewardAmount,
            networthAmount,
            merkleProof
        );
    }
}

contract InstaDSProxyMakerDAOClaimer is VaultResolver {
    constructor(address _instaMakerMerkle) public VaultResolver(_instaMakerMerkle) {}

    string public constant name = "DSProxy-MakerDAO-Merkle-Claimer-v1.0";
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