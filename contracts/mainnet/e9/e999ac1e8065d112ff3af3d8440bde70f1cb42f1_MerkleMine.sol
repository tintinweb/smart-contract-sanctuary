pragma solidity 0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 * @title MerkleProof
 * @dev Merkle proof verification
 * @note Based on https://github.com/ameensol/merkle-tree-solidity/blob/master/src/MerkleProof.sol
 */
library MerkleProof {
  /*
   * @dev Verifies a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves
   * and each pair of pre-images is sorted.
   * @param _proof Merkle proof containing sibling hashes on the branch from the leaf to the root of the Merkle tree
   * @param _root Merkle root
   * @param _leaf Leaf of Merkle tree
   */
  function verifyProof(bytes _proof, bytes32 _root, bytes32 _leaf) public pure returns (bool) {
    // Check if proof length is a multiple of 32
    if (_proof.length % 32 != 0) return false;

    bytes32 proofElement;
    bytes32 computedHash = _leaf;

    for (uint256 i = 32; i <= _proof.length; i += 32) {
      assembly {
        // Load the current element of the proof
        proofElement := mload(add(_proof, i))
      }

      if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(proofElement, computedHash);
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == _root;
  }
}

/**
 * @title MerkleMine
 * @dev Token distribution based on providing Merkle proofs of inclusion in genesis state to generate allocation
 */
contract MerkleMine {
    using SafeMath for uint256;

    // ERC20 token being distributed
    ERC20 public token;
    // Merkle root representing genesis state which encodes token recipients
    bytes32 public genesisRoot;
    // Total amount of tokens that can be generated
    uint256 public totalGenesisTokens;
    // Total number of recipients included in genesis state
    uint256 public totalGenesisRecipients;
    // Amount of tokens per recipient allocation. Equal to `totalGenesisTokens` / `totalGenesisRecipients`
    uint256 public tokensPerAllocation;
    // Minimum ETH balance threshold for recipients included in genesis state
    uint256 public balanceThreshold;
    // Block number of genesis - used to determine which ETH accounts are included in the genesis state
    uint256 public genesisBlock;
    // Start block where a third party caller (not the recipient) can generate and split the allocation with the recipient
    // As the current block gets closer to `callerAllocationEndBlock`, the caller receives a larger precentage of the allocation
    uint256 public callerAllocationStartBlock;
    // From this block onwards, a third party caller (not the recipient) can generate and claim the recipient&#39;s full allocation
    uint256 public callerAllocationEndBlock;
    // Number of blocks in the caller allocation period as defined by `callerAllocationEndBlock` - `callerAllocationStartBlock`
    uint256 public callerAllocationPeriod;

    // Track if the generation process is started
    bool public started;

    // Track the already generated allocations for recipients
    mapping (address => bool) public generated;

    // Check that a recipient&#39;s allocation has not been generated
    modifier notGenerated(address _recipient) {
        require(!generated[_recipient]);
        _;
    }

    // Check that the generation period is started
    modifier isStarted() {
        require(started);
        _;
    }

    // Check that the generation period is not started
    modifier isNotStarted() {
        require(!started);
        _;
    }

    event Generate(address indexed _recipient, address indexed _caller, uint256 _recipientTokenAmount, uint256 _callerTokenAmount, uint256 _block);

    /**
     * @dev MerkleMine constructor
     * @param _token ERC20 token being distributed
     * @param _genesisRoot Merkle root representing genesis state which encodes token recipients
     * @param _totalGenesisTokens Total amount of tokens that can be generated
     * @param _totalGenesisRecipients Total number of recipients included in genesis state
     * @param _balanceThreshold Minimum ETH balance threshold for recipients included in genesis state
     * @param _genesisBlock Block number of genesis - used to determine which ETH accounts are included in the genesis state
     * @param _callerAllocationStartBlock Start block where a third party caller (not the recipient) can generate and split the allocation with the recipient
     * @param _callerAllocationEndBlock From this block onwards, a third party caller (not the recipient) can generate and claim the recipient&#39;s full allocation
     */
    function MerkleMine(
        address _token,
        bytes32 _genesisRoot,
        uint256 _totalGenesisTokens,
        uint256 _totalGenesisRecipients,
        uint256 _balanceThreshold,
        uint256 _genesisBlock,
        uint256 _callerAllocationStartBlock,
        uint256 _callerAllocationEndBlock
    )
        public
    {
        // Address of token contract must not be null
        require(_token != address(0));
        // Number of recipients must be non-zero
        require(_totalGenesisRecipients > 0);
        // Genesis block must be at or before the current block
        require(_genesisBlock <= block.number);
        // Start block for caller allocation must be after current block
        require(_callerAllocationStartBlock > block.number);
        // End block for caller allocation must be after caller allocation start block
        require(_callerAllocationEndBlock > _callerAllocationStartBlock);

        token = ERC20(_token);
        genesisRoot = _genesisRoot;
        totalGenesisTokens = _totalGenesisTokens;
        totalGenesisRecipients = _totalGenesisRecipients;
        tokensPerAllocation = _totalGenesisTokens.div(_totalGenesisRecipients);
        balanceThreshold = _balanceThreshold;
        genesisBlock = _genesisBlock;
        callerAllocationStartBlock = _callerAllocationStartBlock;
        callerAllocationEndBlock = _callerAllocationEndBlock;
        callerAllocationPeriod = _callerAllocationEndBlock.sub(_callerAllocationStartBlock);
    }

    /**
     * @dev Start the generation period - first checks that this contract&#39;s balance is equal to `totalGenesisTokens`
     * The generation period must not already be started
     */
    function start() external isNotStarted {
        // Check that this contract has a sufficient balance for the generation period
        require(token.balanceOf(this) >= totalGenesisTokens);

        started = true;
    }

    /**
     * @dev Generate a recipient&#39;s token allocation. Generation period must be started. Starting from `callerAllocationStartBlock`
     * a third party caller (not the recipient) can invoke this function to generate the recipient&#39;s token
     * allocation and claim a percentage of it. The percentage of the allocation claimed by the
     * third party caller is determined by how many blocks have elapsed since `callerAllocationStartBlock`.
     * After `callerAllocationEndBlock`, a third party caller can claim the full allocation
     * @param _recipient Recipient of token allocation
     * @param _merkleProof Proof of recipient&#39;s inclusion in genesis state Merkle root
     */
    function generate(address _recipient, bytes _merkleProof) external isStarted notGenerated(_recipient) {
        // Check the Merkle proof
        bytes32 leaf = keccak256(_recipient);
        // _merkleProof must prove inclusion of _recipient in the genesis state root
        require(MerkleProof.verifyProof(_merkleProof, genesisRoot, leaf));

        generated[_recipient] = true;

        address caller = msg.sender;

        if (caller == _recipient) {
            // If the caller is the recipient, transfer the full allocation to the caller/recipient
            require(token.transfer(_recipient, tokensPerAllocation));

            Generate(_recipient, _recipient, tokensPerAllocation, 0, block.number);
        } else {
            // If the caller is not the recipient, the token allocation generation
            // can only take place if we are in the caller allocation period
            require(block.number >= callerAllocationStartBlock);

            uint256 callerTokenAmount = callerTokenAmountAtBlock(block.number);
            uint256 recipientTokenAmount = tokensPerAllocation.sub(callerTokenAmount);

            if (callerTokenAmount > 0) {
                require(token.transfer(caller, callerTokenAmount));
            }

            if (recipientTokenAmount > 0) {
                require(token.transfer(_recipient, recipientTokenAmount));
            }

            Generate(_recipient, caller, recipientTokenAmount, callerTokenAmount, block.number);
        }
    }

    /**
     * @dev Return the amount of tokens claimable by a third party caller when generating a recipient&#39;s token allocation at a given block
     * @param _blockNumber Block at which to compute the amount of tokens claimable by a third party caller
     */
    function callerTokenAmountAtBlock(uint256 _blockNumber) public view returns (uint256) {
        if (_blockNumber < callerAllocationStartBlock) {
            // If the block is before the start of the caller allocation period, the third party caller can claim nothing
            return 0;
        } else if (_blockNumber >= callerAllocationEndBlock) {
            // If the block is at or after the end block of the caller allocation period, the third party caller can claim everything
            return tokensPerAllocation;
        } else {
            // During the caller allocation period, the third party caller can claim an increasing percentage
            // of the recipient&#39;s allocation based on a linear curve - as more blocks pass in the caller allocation
            // period, the amount claimable by the third party caller increases linearly
            uint256 blocksSinceCallerAllocationStartBlock = _blockNumber.sub(callerAllocationStartBlock);
            return tokensPerAllocation.mul(blocksSinceCallerAllocationStartBlock).div(callerAllocationPeriod);
        }
    }
}