// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";

contract WhelpsBreed7 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;
    
    address public _approvedContract = address(0);
    address public _stakingContract = address(0);
    bool public stakingContractLocked = false;
    
    /**
     * @dev Returns the address of the current owner.
     */
    function approvedContract() public view virtual returns (address) {
        return _approvedContract;
    }
    
    function setApprovedContract(address _contract) external onlyOwner {
      _approvedContract = _contract;
    }
    
    modifier onlyOwnerOrApprovedContract() {
        require(owner() == _msgSender() || approvedContract() == _msgSender(), "Caller is not the owner or the approved contract");
        _;
    }

    function setStakingContract(address _contract) external onlyOwner {
        require(!stakingContractLocked, "Locked");
        _stakingContract = _contract;
    }
    
    function lockStakingContract() external onlyOwner {
        stakingContractLocked = true;
    }
    
    // name handlers
    
    bool public namesActivated;
    bool public namesActivatedLock;
    mapping (uint256 => string) public tokenIdToName;
    uint256 public constant MAX_NAME_LEN = 100;
    
    function toggleActivateNameFeature() public onlyOwner {
      require(namesActivatedLock == false, "Locked");
      namesActivated = !namesActivated;
    }
    
    function lockNameFeatureForever() public onlyOwner {
      namesActivatedLock = true;
    }
    
    function checkNameValid(string calldata name) public pure returns(bool) {
      bytes memory nameBytes = bytes(name);
      require(nameBytes.length <= MAX_NAME_LEN);
      for (uint256 i = 0; i < nameBytes.length; i++) {
        require((nameBytes[i]>="a"&&nameBytes[i]<="z")||(nameBytes[i]>="A"&&nameBytes[i]<="Z")||(nameBytes[i]>="0"&&nameBytes[i]<="9")||nameBytes[i]=="-"||nameBytes[i]=="."||nameBytes[i]=="_"||nameBytes[i]=="~", "invalid char");
      }
      return true;
    }
    
    function setNameForTokenId(uint256 tokenId, string calldata name) public {
      require(_exists(tokenId), "Unknown token");
      require(msg.sender == ownerOf(tokenId), "Unauthorized");
      require(namesActivated, "Setting names is disabled");
      
      require(checkNameValid(name));
      
      tokenIdToName[tokenId] = name;
    }
    
    // metadata & ipfs
    
    string public baseURI = "https://whelpsio.herokuapp.com/api7/";
    string public ipfsBaseURI = "https://whelps.mypinata.cloud/ipfs/";
    mapping (uint256 => string) public tokenIdToIpfsHash;
    
    // 1 - force use computed name for all
    // 2 - use ipfs hash if available, fallback to computed name
    // 3 - force use ipfs hash for all
    uint256 public metadataSwitch = 1;
    bool public ipfsLocked = false;
    mapping (uint256 => bool) public ipfsLockPerToken;
    bool public switchLocked = false;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}

    // Metadata handlers
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function _ipfsBaseURI() internal view returns (string memory) {
        return ipfsBaseURI;
    }
    
    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
    
    function setIpfsBaseUri(string memory _uri) external onlyOwner {
        require(ipfsLocked == false);
        ipfsBaseURI = _uri;
    }
    
    function lockIpfsMetadata() external onlyOwner {
        require(ipfsLocked == false);
        ipfsLocked = true;
    }
    
    function setMetadataSwitch(uint256 _switch) external onlyOwner {
        if (switchLocked == true) {
          require (_switch > metadataSwitch);
        }
        
        require(_switch >= 1 && _switch <= 3);
        
        metadataSwitch = _switch;
    }
    
    function lockMetadataSwitch() external onlyOwner {
        require(switchLocked == false);
        switchLocked = true;
    }
    
    function setIpfsHash(uint256 traitSummary, string memory hash) external onlyOwnerOrApprovedContract {
        if (ipfsLocked == true) {
          require(bytes(tokenIdToIpfsHash[traitSummary]).length == 0);
        }
        require(ipfsLockPerToken[traitSummary] == false);
        
        tokenIdToIpfsHash[traitSummary] = hash;
    }
    
    function lockIpfsPerToken(uint256 traitSummary) external onlyOwnerOrApprovedContract {
        require(ipfsLockPerToken[traitSummary] == false);
        ipfsLockPerToken[traitSummary] = true;
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        
        string memory base = _baseURI();
        string memory ipfsBase = _ipfsBaseURI();
        
        string memory ipfsHash = tokenIdToIpfsHash[tokenId];
        
        if (metadataSwitch == 1) {
            // force computed name
            return string(abi.encodePacked(base, tokenId.toString(), "/", tokenIdToName[tokenId]));
        } else if (metadataSwitch == 2) {
            // ipfs hash if available, fallback to computed name
            if (bytes(ipfsHash).length == 0) {
                return string(abi.encodePacked(base, tokenId.toString(), "/", tokenIdToName[tokenId]));
            } else {
                return string(abi.encodePacked(ipfsBase, ipfsHash));
            }
        } else if (metadataSwitch == 3) {
            // force ipfs hash
            return string(abi.encodePacked(ipfsBase, ipfsHash));
        }
        
        return "";
    }
    
    // Minting
            
    function mint(address minter, uint256 mintIndex) public returns (uint256) {
      require(msg.sender == _stakingContract, "Unauthorized");
      require(!_exists(mintIndex), "Token already minted");

      _mint(minter, mintIndex);
      
      return mintIndex;
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}