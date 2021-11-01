pragma solidity 0.6.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : - x;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public CLAIM_PACKED_HASH;
    mapping(address => uint) public nonces;


    constructor() internal {
        NAME = "KawaiiQuizAirdrop";
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(NAME)),
                keccak256(bytes('1')),
                chainId,
                this
            )
        );

        CLAIM_PACKED_HASH = keccak256("Data(address nftRegister,uint256 nonce)");
    }

    function verify(bytes32 data, address sender, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                data
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == sender, "Invalid nonce");
    }
}

interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external returns (uint256);
}

interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

contract KawaiiQuizAirdrop is Ownable, SignData {
    using SafeMath for uint256;
    IKawaiiRandomness public kawaiiRandomness;
    mapping(address => uint256) public  canClaim;
    uint256[] public animals;
    uint256[] public trees;
    uint256[] public materials;
    uint256[] public fields;
    uint256[] public dyes;

    uint256[] public weights; // trees,animal,material,fields,dyes

    event ClaimAirdrop(address indexed sender, uint256 id);

    constructor(IKawaiiRandomness _kawaiiRandomness) public {
        kawaiiRandomness = _kawaiiRandomness;
    }

    function setAnimals(uint256[] memory _animals) external onlyOwner {
        animals = _animals;
    }

    function setTrees(uint256[] memory _trees) external onlyOwner {
        trees = _trees;
    }

    function setMaterials(uint256[] memory _materials) external onlyOwner {
        materials = _materials;
    }

    function setFields(uint256[] memory _fields) external onlyOwner {
        fields = _fields;
    }

    function setDyes(uint256[] memory _dyes) external onlyOwner {
        dyes = _dyes;
    }

    function setWeight(uint256[] memory _weights) external onlyOwner {
        weights = _weights;
    }


    function setQuizAirdropNFT(address[] calldata receivers, uint256[] calldata isClaims) external onlyOwner {
        uint256 length = receivers.length;
        for (uint i = 0; i < length; i++) {
            canClaim[receivers[i]] = isClaims[i];
        }
    }

    function claimAirdrop(IERC1155 nftRegister, address sender, uint8 v, bytes32 r, bytes32 s) external {
        verify(keccak256(abi.encode(CLAIM_PACKED_HASH, nftRegister, nonces[sender]++)), sender, v, r, s);
        require(canClaim[sender] > 0 , "Forbidden");
        uint256 totalWeight;

        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight = totalWeight.add(weights[i]);
        }

        for (uint256 i=0; i< canClaim[sender]; i++) {
            uint256 rand = kawaiiRandomness.getRandomNumber(totalWeight, gasleft());
            uint256 index = selectItem(rand);

            uint256 idMint;

            if (index == 0) {
                idMint = chooseTree(trees.length, gasleft());
            }
            if (index == 1) {
                idMint = chooseAnimal(animals.length, gasleft());
            }
            if (index == 2) {
                idMint = chooseMaterial(materials.length, gasleft());
            }
            if (index == 3) {
                idMint = chooseField(fields.length, gasleft());
            }
            if (index == 4) {
                idMint = chooseDye(dyes.length, gasleft());
            }

            nftRegister.mint(sender, idMint, 1);
            emit ClaimAirdrop(sender, idMint);
        }
        canClaim[sender] = 0;
    }

    function selectItem(uint256 rand) internal view returns (uint256) {
        uint256 index;
        for (uint256 i = 0; i < weights.length - 1; i++) {
            if (rand > weights[i]) {
                index = i + 1;
                rand = rand.sub(weights[i]);
            }
        }
        return index;
    }

    function chooseAnimal(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return animals[index];
    }

    function chooseTree(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return trees[index];
    }

    function chooseMaterial(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return materials[index];
    }

    function chooseField(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return fields[index];
    }

    function chooseDye(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return dyes[index];
    }
}