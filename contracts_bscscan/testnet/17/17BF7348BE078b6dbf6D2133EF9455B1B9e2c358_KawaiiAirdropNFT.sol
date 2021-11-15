pragma solidity ^0.6.0;
//SPDX-License-Identifier: UNLICENSED
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

contract SignData {
    bytes32 public DOMAIN_SEPARATOR;
    string public NAME;
    bytes32 public CLAIM_NFT1155_HASH;
    mapping(address => uint) public nonces;


    constructor() internal {
        NAME = "KawaiiAirdropNFT";
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

        CLAIM_NFT1155_HASH = keccak256("Data(address nftRegister,uint256 tokenId,uint256 nonce)");
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

contract KawaiiAirdropNFT is Ownable, SignData {
    mapping(address => mapping(address => mapping(uint256 => bool))) NFT1155Data;


    function claimNFT1155(address nftRegister, uint256 tokenId, address sender, uint8 v, bytes32 r, bytes32 s) public {
        verify(keccak256(abi.encode(CLAIM_NFT1155_HASH, nftRegister, tokenId, nonces[sender]++)), sender, v, r, s);
        require(NFT1155Data[sender][nftRegister][tokenId] == true, "Forbidden");
        IERC1155(nftRegister).mint(sender, tokenId, 1);
    }


    function addAirdropNFT1155(address[] calldata receivers, address[] calldata nftRegisters, uint256[] calldata tokenIds) external onlyOwner {
        require(receivers.length == nftRegisters.length, "receivers.length!=nftRegisters.length");
        require(receivers.length == tokenIds.length, "receivers.length!=tokenIds.length");
        for (uint i = 0; i < receivers.length; i++) {
            NFT1155Data[receivers[i]][nftRegisters[i]][tokenIds[i]] = true;
        }
    }

    function setAirdropNFT1155(address[] calldata receivers, address[] calldata nftRegisters, uint256[] calldata tokenIds, bool[] calldata results) external onlyOwner {
        require(receivers.length == nftRegisters.length, "receivers.length!=nftRegisters.length");
        require(receivers.length == tokenIds.length, "receivers.length!=tokenIds.length");
        require(receivers.length == results.length, "receivers.length!=results.length");
        for (uint i = 0; i < receivers.length; i++) {
            NFT1155Data[receivers[i]][nftRegisters[i]][tokenIds[i]] = results[i];
        }
    }

}

