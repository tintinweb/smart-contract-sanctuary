// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface ClaimContract {
    function balanceOf(address owner) external view returns (uint256 balance);
}


contract Apes is ERC721, Ownable {

    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;    
    using EnumerableSet for EnumerableSet.AddressSet;

    // Hash of all 8888 apes
    string public constant PROVENANCE_HASH = "1a6595d8f3c2c97b66a34e35dbe9bc0e83edfdca1d93193145d8904775671cc3";

    // Sale starts at 
    uint256 public constant SALE_START_TIMESTAMP = 1619190000;

    // Sale ends 7 days later
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 7);

    // 8888 Apes
    uint256 public constant MAX_NFT_SUPPLY = 8888;

    // 25% Airdrop!
    uint256 public constant MAX_CLAIMABLE_SUPPLY = 2222;

    // Flat price 0.1 ETH
    uint256 public constant FLAT_PRICE = 100000000000000000;

    // Whitelisted NFT project
    EnumerableSet.AddressSet private _claimableContracts;

    // If token is minted by owning a NFT    
    EnumerableSet.UintSet private _claimedTokenIds;

    // You can only claim one Ape per owner
    mapping (address => bool) private _claimedTokenOwners;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name, string memory symbol, string memory baseUri) ERC721(name, symbol) {        
        _setBaseURI(baseUri);
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function getNFTPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        return FLAT_PRICE;
    }

    function totalClaimedSupply() public view returns (uint256) {              
        return _claimedTokenIds.length();
    }

    function addClaimableContracts(address[] memory contractAddresses) public onlyOwner {
        for (uint i = 0; i < contractAddresses.length; i++) {
            _claimableContracts.add(contractAddresses[i]);
        }
    }

    function removeClaimableContract(address contractAddress) public onlyOwner {
        _claimableContracts.remove(contractAddress);
    }

    function claimableContractsLength() public view returns (uint256) {
        return _claimableContracts.length();
    }

    function claimableContractAt(uint256 index) public view returns (address) {
        return _claimableContracts.at(index);
    }

    function claimNFT(address contractAddress) public {
        require(block.timestamp < REVEAL_TIMESTAMP, "Reveal date has passed");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(totalClaimedSupply() < MAX_CLAIMABLE_SUPPLY, "All claimable tokens have been claimed");  
        require(!isClaimedOwner(msg.sender), "Owner has already claimed a token");        
        require(isNFTOwner(contractAddress, msg.sender), "Caller does not own token for passed contract");

        uint mintIndex = totalSupply();
        _claimedTokenIds.add(mintIndex);
        _claimedTokenOwners[msg.sender] = true;
        _safeMint(msg.sender, mintIndex);
    }

    function isNFTOwner(address contractAddress, address owner) public view returns (bool) {
        require(_claimableContracts.contains(contractAddress), "Contract is not eligible yet");
        return ClaimContract(contractAddress).balanceOf(owner) > 0;
    }

    function isClaimedOwner(address owner) public view returns (bool) {
        return _claimedTokenOwners[owner];
    }

    function isClaimedNFT(uint256 index) public view returns (bool) {
        return _claimedTokenIds.contains(index);
    }

    function mintNFT(uint256 numberOfNfts) public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "Number of NFT must be > 0");
        require(numberOfNfts <= 50, "Number of NFT must not be > 50");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds total number of NFT");
        require(getNFTPrice().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }


    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}