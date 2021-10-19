// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./libraries/MerkleProofLib.sol";
import "./interfaces/IWaterfall.sol";
import "./interfaces/IERC20.sol";

/**
 * @dev Waterfall implementation.
 *
 * author: Nuno Axe
 * github: https://github.com/ngmachado/waterfall
 *
 */
contract Waterfall is IWaterfall {
    struct Config {
        IERC20 token;
        uint96 startTime;
        address tokensProvider;
        uint96 endTime;
        mapping(uint256 => uint256) claimed;
    }

    // @dev Config for the merkleRoot.
    mapping(bytes32 => Config) public config;

    // @dev IWaterfall.newDistribuition implementation.
    function newDistribuition(
        bytes32 merkleRoot,
        address token,
        uint96 startTime,
        uint96 endTime
    ) external override {
        require(
            address(config[merkleRoot].token) == address(0),
            "merkleRoot already register"
        );
        require(merkleRoot != bytes32(0), "empty root");
        require(token != address(0), "empty token");
        require(startTime < endTime, "wrong dates");

        Config storage _config = config[merkleRoot];
        _config.token = IERC20(token);
        _config.tokensProvider = msg.sender;
        _config.startTime = startTime;
        _config.endTime = endTime;
        emit NewDistribuition(
            msg.sender,
            token,
            merkleRoot,
            startTime,
            endTime
        );
    }

    // @dev IWaterfall.isClaimed implementation.
    function isClaimed(bytes32 merkleRoot, uint256 index)
        public
        view
        override
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = config[merkleRoot].claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // @dev Set index as claimed on specific merkleRoot
    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        config[merkleRoot].claimed[claimedWordIndex] =
            config[merkleRoot].claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    // @dev IWaterfall.claim implementation.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) external override {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        bytes32 merkleRoot = MerkleProof.getMerkleRoot(merkleProofs, leaf);

        require(
            config[merkleRoot].startTime < block.timestamp &&
                config[merkleRoot].endTime >= block.timestamp,
            "out of time / wrong root"
        );

        require(!isClaimed(merkleRoot, index), "already claimed");
        _setClaimed(merkleRoot, index);

        require(
            config[merkleRoot].token.transferFrom(
                config[merkleRoot].tokensProvider,
                account,
                amount
            ),
            "transfer failed"
        );
        emit Claimed(account, address(config[merkleRoot].token), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Waterfall contract interface
 *
 * @author Nuno Axe
 *
 */
interface IWaterfall {

    /**
     * @dev Create a new token distribution.
     * @notice If distribuition is not bound to a time interval, startTime = 0 (zero) and endTime = ype(uint96).max
     * @param merkleRoot Top node of a merkle tree structure.
     * @param token ERC20 compatible token address that will be distribuited.
     * @param startTime Start accepting claims in the distribuition.
     * @param endTime Stop accepting claims in the distribuition.
     */
    function newDistribuition(
        bytes32 merkleRoot,
        address token,
        uint96 startTime,
        uint96 endTime
    )
        external;

    /**
     * @dev New Distribution Event.
     * @param sender Address that register a new distribution.
     * @param token ERC20 compatible token address that will be distribuited.
     * @param merkleRoot Top node of a merkle tree structure.
     * @param startTime timestamp to accept claims in the distribuition.
     * @param endTime timestamp to stop accepting claims in the distribuition.
     */
    event NewDistribuition(address indexed sender, address indexed token, bytes32 indexed merkleRoot, uint96 startTime, uint96 endTime);

    /**
     * @dev Check if claim was executed.
     * @param merkleRoot Top node of a merkle tree structure.
     * @param index Position of the leaf in the merkle tree
     */
    function isClaimed(bytes32 merkleRoot, uint256 index) external view returns (bool);

    /**
     * @dev Make a single distribuion.
     * @notice claim data combined with merkleProofs will compute the merkle tree root.
     * @param index Position of the leaf in the merkle tree
     * @param account Address entitled to make the claim.
     * @param amount Number of tokens to transfer.
     * @param merkleProofs of the tree.
     */
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) external;

    /**
     * @dev Claimed Event.
     * @param account Address that received tokens from claim function.
     * @param token ERC20 compatible token address that has be distribuited.
     * @param amount Number of tokens transfered.
     */
    event Claimed(address account, address token, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);
}