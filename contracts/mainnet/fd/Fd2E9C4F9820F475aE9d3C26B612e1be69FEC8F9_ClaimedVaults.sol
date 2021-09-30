/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

pragma solidity 0.6.11;

interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
    function tokenPayload(uint256 _tokenId) external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
}

interface IStorage {
    function getZero() external view returns(address);
    function getDead() external view returns(address);
    function addToLegacy(address nftAddress, uint tokenId, address _owner) external;
    function getLegacyClaims(address nftAddress, uint tokenId) external view returns (address);
    function addToClaims(address nftAddress, uint tokenId, address _owner) external;
    function getClaims(address nftAddress, uint tokenId) external view returns (address);
    function getBurnAddresses() external view returns (address[] memory);
    function addToBurnAddresses(address burnAddress) external;
    function removeFromLegacy(address nftAddress, uint tokenId) external;
}

contract ClaimedVaults {
    
    event Tick(uint tick);
    event Tock(address tock);
    event Complete();
    event Finally();
    
    address StorageAddress;
    bool initialized = false;
    address owner;
    
    constructor(address storageContract) public {
        StorageAddress = storageContract;
        owner = msg.sender;
    }
    
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    function init() public {
        require(!initialized, 'already initialized');
        initialized = true;
    }
    
    
    function getZeroFromStorage() public view returns (address) {
        return IStorage(StorageAddress).getZero();
    }
    
    function isBurnAddress(address needle) public view returns (bool) {
        address[] memory BurnAddresses = IStorage(StorageAddress).getBurnAddresses();
        for (uint i=0; i < BurnAddresses.length; i++) {
            if (BurnAddresses[i] == needle) {
                return true;
            }
        }
        return false;
    }
    
    function claim(address nftAddress, uint tokenId) public {
        IERC721 token = IERC721(nftAddress);
        token.transferFrom(msg.sender, IStorage(StorageAddress).getDead(), tokenId);
        IStorage(StorageAddress).addToClaims(nftAddress, tokenId, msg.sender);
    }
    
    function isClaimed(address nftAddress, uint tokenId) public view returns(bool) {
        IERC721 token = IERC721(nftAddress);
        bool legacyClaimed = IStorage(StorageAddress).getLegacyClaims(nftAddress, tokenId) != getZeroFromStorage();
        bool claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId) != getZeroFromStorage();
        bool addressClaimed = false;
        try token.ownerOf(tokenId) returns (address _owner) {
            if (isBurnAddress(_owner)) {
                addressClaimed = true;
            }
        } catch {}
        return legacyClaimed || addressClaimed || claimed;
    }
    
    function claimedBy(address nftAddress, uint tokenId) public view returns (address _owner, string memory _type) {
        address legacyClaimed = IStorage(StorageAddress).getLegacyClaims(nftAddress, tokenId);
        address claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId);
        if (legacyClaimed != getZeroFromStorage()) {
            return (legacyClaimed, "legacy");
        } else if (claimed != getZeroFromStorage()) {
            return (claimed, "record");
        } else {
            return (getZeroFromStorage(), "unknown");
        }
    }
    
    function addManyLegacy(address nftAddress, address[] memory owners, uint[] memory tokenIds) isOwner public {
        for (uint i=0; i < owners.length; i++) {
            IStorage(StorageAddress).addToLegacy(nftAddress, tokenIds[i], owners[i]);
        }
    }
    
    function removeFromLegacy(address nftAddress, uint tokenId) isOwner public {
        IStorage(StorageAddress).removeFromLegacy(nftAddress, tokenId);
    }
}