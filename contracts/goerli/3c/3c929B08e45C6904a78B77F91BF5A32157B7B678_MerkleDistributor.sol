// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./libraries/MerkleProofLib.sol";
import "./interfaces/IMerkleDrop.sol";
import "./interfaces/IERC20.sol";

contract MerkleDistributor is IMerkleDrop {

    struct Config {
        IERC20 token;
        address tokensProvider;
        uint96 startTime;
        uint96 endTime;
        mapping(uint256 => uint256) claimed;
    }

    mapping(bytes32 => Config) public config;

    function newDistribuition(
        bytes32 merkleRoot,
        address token,
        address tokensProvider,
        uint96 startTime,
        uint96 endTime
    )
        external
        override
    {
        require(address(config[merkleRoot].token) == address(0), "merkleRoot already register");
        require(merkleRoot != bytes32(0), "empty root");
        require(token != address(0), "empty token");
        require(tokensProvider != address(0), "empty provider");
        require(startTime < endTime, "wrong dates");

        Config storage _config = config[merkleRoot];
        _config.token = IERC20(token);
        _config.tokensProvider = tokensProvider;
        _config.startTime = startTime;
        _config.endTime = endTime;
    }

    function isClaimed(bytes32 merkleRoot, uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = config[merkleRoot].claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        config[merkleRoot].claimed[claimedWordIndex] = config[merkleRoot].claimed[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProofs) external override {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        bytes32 merkleRoot = MerkleProof.getMerkleRoot(merkleProofs, leaf);

        require(
            config[merkleRoot].startTime < block.timestamp
            && config[merkleRoot].endTime >= block.timestamp
            ,"out of time / wrong root"
        );

        require(!isClaimed(merkleRoot, index), "already claimed");
        _setClaimed(merkleRoot, index);

        require(
            config[merkleRoot].token.transferFrom(
                config[merkleRoot].tokensProvider,
                account,
                amount
            )
        , "transfer failed");
        emit Claimed(account, address(config[merkleRoot].token), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20 {

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMerkleDrop {

    function newDistribuition(
        bytes32 merkleRoot,
        address token,
        address tokensProvider,
        uint96 startDate,
        uint96 endDate
    )
        external;

    function isClaimed(bytes32 merkleRoot, uint256 index) external view returns (bool);

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) external;

    event Claimed(address account, address token, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library MerkleProof {

    function getMerkleRoot(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32 computedHash) {
        computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
    }
}

