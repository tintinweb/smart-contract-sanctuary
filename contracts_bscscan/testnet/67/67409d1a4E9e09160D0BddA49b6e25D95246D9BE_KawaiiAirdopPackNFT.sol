pragma solidity 0.6.12;


interface IKawaiiRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external returns (uint256);
}

interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

contract Context {

    constructor () internal {}
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        NAME = "KawaiiAirdropPackedNFT";
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


contract KawaiiAirdopPackNFT is Ownable, SignData {
    IKawaiiRandomness public kawaiiRandomness;
    mapping(address => bool) public  canClaim;
    uint256[] public animals;
    uint256[] public trees;
    uint256 public fieldId;
    uint256 public numberAnimalInPack;
    uint256 public numberTreeInPack;
    uint256 public numberFieldInPack;
    mapping(uint256 => uint256[]) public animalToTree;

    constructor(IKawaiiRandomness _kawaiiRandomness, uint256 _numberAnimalInPack, uint256 _numberTreeInPack) public {
        kawaiiRandomness = _kawaiiRandomness;
        require(_numberAnimalInPack < _numberTreeInPack, "Animal must < tree");
        numberAnimalInPack = _numberAnimalInPack;
        numberTreeInPack = _numberTreeInPack;
    }

    function setField(uint256 _fieldId, uint256 _numberFieldInPack) public onlyOwner {
        fieldId = _fieldId;
        numberFieldInPack = _numberFieldInPack;
    }

    function setAnimalToTree(uint256 animalId, uint256[] memory treeIds) public onlyOwner {
        animalToTree[animalId] = treeIds;
    }

    function setNumberInPack(uint256 animal, uint256 tree) public onlyOwner {
        numberTreeInPack = tree;
        numberAnimalInPack = animal;
    }

    function setTree(uint256[] memory _trees) public onlyOwner {
        trees = _trees;
    }

    function setAnimals(uint256[] memory _animals) public onlyOwner {
        animals = _animals;
    }

    function setAirdropPackNFT(address[] calldata receivers) external onlyOwner {
        uint256 length = receivers.length;
        for (uint i = 0; i < length; i++) {
            canClaim[receivers[i]] = true;
        }
    }

    function claimPacked(IERC1155 nftRegister, address sender, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(CLAIM_PACKED_HASH, nftRegister, nonces[sender]++)), sender, v, r, s);
        require(canClaim[sender] == true, "Forbidden");
        uint256[] memory animalsInPack;
        uint256[] memory treesInPack;
        (animalsInPack, treesInPack) = createAirdropPack(numberAnimalInPack, numberTreeInPack);
        nftRegister.mint(sender, fieldId, numberFieldInPack);
        for (uint256 i = 0; i < numberAnimalInPack; i++) {
            nftRegister.mint(sender, animalsInPack[i], 1);
        }
        for (uint256 i = 0; i < numberTreeInPack; i++) {
            nftRegister.mint(sender, treesInPack[i], 1);
        }
        canClaim[sender] = false;
    }

    function createAirdropPack(uint256 numberAnimal, uint256 numberTree) internal returns (uint[] memory, uint[] memory) {
        require(numberTree >= numberAnimal, "Animal must < tree");
        uint256[] memory animalIds = new  uint256[](numberAnimal);
        uint256[] memory treeIds = new  uint256[](numberTree);
        for (uint256 i = 0; i < numberAnimal; i++) {
            animalIds[i] = chooseAnimal(animals.length, gasleft());
            treeIds[i] = chooseTree(animalIds[i], gasleft());
        }
        for (uint256 i = numberAnimal; i < numberTree; i++) {
            treeIds[i] = chooseTreeWithoutRules(trees.length, gasleft());
        }
        return (animalIds, treeIds);
    }


    function chooseAnimal(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return animals[index];

    }


    function chooseTreeWithoutRules(uint256 range, uint256 randomNumber) private returns (uint256) {
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return trees[index];

    }


    function chooseTree(uint256 animalId, uint256 randomNumber) private returns (uint256) {
        uint256 range = animalToTree[animalId].length;
        uint256 index = kawaiiRandomness.getRandomNumber(range, randomNumber);
        return animalToTree[animalId][index];

    }
}

