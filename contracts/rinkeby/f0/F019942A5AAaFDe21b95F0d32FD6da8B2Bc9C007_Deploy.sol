/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: contracts/MerkleTreeWithHistory.sol

pragma solidity =0.5.17;

contract Hasher {
    function MiMCSponge(uint256 in_xL, uint256 in_xR)
        public
        pure
        returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
    Hasher hasher;
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /* function getValue() public view returns (uint256) {
        return uint256(keccak256("TornCash")) % FIELD_SIZE;
    } */

    uint256 public constant ZERO_VALUE =
        15030953804071517393383426331000188129010706242704091381562377151103645898705; // = keccak256("TornCash") % FIELD_SIZE

    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code
    bytes32[] public filledSubtrees;
    bytes32[] public zeros;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 100;
    bytes32[ROOT_HISTORY_SIZE] public roots;

    constructor(uint32 _treeLevels, address _hasher) public {
        require(_treeLevels > 0, "_treeLevels should be greater than zero");
        require(_treeLevels < 32, "_treeLevels should be less than 32");
        levels = _treeLevels;

        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);
        hasher = Hasher(_hasher);

        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }

    /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
    function hashLeftRight(bytes32 _left, bytes32 _right)
        public
        view
        returns (bytes32)
    {
        require(
            uint256(_left) < FIELD_SIZE,
            "_left should be inside the field"
        );
        require(
            uint256(_right) < FIELD_SIZE,
            "_right should be inside the field"
        );
        uint256 R = uint256(_left);
        uint256 C = 0;
        (R, C) = hasher.MiMCSponge(R, C);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = hasher.MiMCSponge(R, C);
        return bytes32(R);
    }

    function _insert(bytes32 _leaf)
        internal
        returns (uint32 index, bytes32 root)
    {
        uint32 currentIndex = nextIndex;

        require(
            currentIndex != uint32(2)**levels,
            "Merkle tree is full. No more leafs can be added"
        );

        nextIndex += 1;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];

                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);

            currentIndex /= 2;
        }

        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentLevelHash;

        return (nextIndex - 1, roots[currentRootIndex]);
    }

    /**
    @dev Whether the root is present in the root history
  */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }

        uint32 i = currentRootIndex;

        do {
            if (_root == roots[i]) {
                return true;
            }

            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }

            i--;
        } while (i != currentRootIndex);

        return false;
    }

    /**
    @dev Returns the last root
  */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
}

// File: contracts/Ownable.sol

pragma solidity =0.5.17;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/AnonymousTree.sol

pragma solidity =0.5.17;



contract IVerifier {
    function verifyProof(bytes memory _proof, uint256[6] memory _input)
        public
        returns (bool);
}

contract AnonymousTree is Ownable, MerkleTreeWithHistory {
    mapping(bytes32 => bool) public COMMITMENTS;
    mapping(bytes32 => bool) public NULLIFIER_HASHES;
    IVerifier public VERIFIER;

    event Bind(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event UnBind(
        address to,
        bytes32 nullifierHash,
        address indexed relayer,
        uint256 fee
    );

    constructor(
        address _verifier,
        uint32 _merkleTreeHeight,
        address _hasher
    ) public MerkleTreeWithHistory(_merkleTreeHeight, _hasher) {
        VERIFIER = IVerifier(_verifier);
    }

    function bind(bytes32 _commitment)
        public
        returns (
            // onlyOwner
            bytes32,
            uint256
        )
    {
        (uint32 insertedIndex, bytes32 root) = _insert(_commitment);

        COMMITMENTS[_commitment] = true;

        emit Bind(_commitment, insertedIndex, block.timestamp);

        return (root, insertedIndex);
    }

    function unBind(
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund /* onlyOwner */
    ) external {
        require(
            !NULLIFIER_HASHES[_nullifierHash],
            "The note has been already spent"
        );
        require(isKnownRoot(_root), "Cannot find your merkle root"); // Make sure to use a recent one
        require(
            VERIFIER.verifyProof(
                _proof,
                [
                    uint256(_root),
                    uint256(_nullifierHash),
                    uint256(_recipient),
                    uint256(_relayer),
                    _fee,
                    _refund
                ]
            ),
            "Invalid withdraw proof"
        );

        NULLIFIER_HASHES[_nullifierHash] = true;

        emit UnBind(_recipient, _nullifierHash, _relayer, _fee);
    }

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return NULLIFIER_HASHES[_nullifierHash];
    }

    function isSpentArray(bytes32[] calldata _nullifierHashes)
        external
        view
        returns (bool[] memory spent)
    {
        spent = new bool[](_nullifierHashes.length);
        for (uint256 i = 0; i < _nullifierHashes.length; i++) {
            if (isSpent(_nullifierHashes[i])) {
                spent[i] = true;
            }
        }
    }
}

// File: contracts/Deploy.sol

pragma solidity =0.5.17;



interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract Deploy is Ownable {
    address VERIFIER;
    uint32 MERKLE_TREE_HEIGHT;
    address HASHER;

    event Create(address, address);

    constructor(
        address _verifier,
        uint32 _merkleTreeHeight,
        address _hasher
    ) public {
        VERIFIER = _verifier;
        MERKLE_TREE_HEIGHT = _merkleTreeHeight;
        HASHER = _hasher;
    }

    function create() public onlyOwner returns (address) {
        address _newAnonymousTree =
            address(new AnonymousTree(VERIFIER, MERKLE_TREE_HEIGHT, HASHER));

        emit Create(owner(), _newAnonymousTree);
    }

    function updateAnonymousTreeOwnership(address _anonymousTree, address _v)
        public
        onlyOwner
    {
        IOwnable(_anonymousTree).transferOwnership(_v);
    }
}