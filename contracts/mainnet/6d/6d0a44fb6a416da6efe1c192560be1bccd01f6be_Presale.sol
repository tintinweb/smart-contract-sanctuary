pragma solidity ^0.4.19;

/**
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * license: MIT
 */
contract OwnableSimple {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function OwnableSimple() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// based on axiomzen, MIT license
contract RandomApi {
    uint64 _seed = 0;

    function random(uint64 maxExclusive) public returns (uint64 randomNumber) {
        // the blockhash of the current block (and future block) is 0 because it doesn&#39;t exist
        _seed = uint64(keccak256(keccak256(block.blockhash(block.number - 1), _seed), block.timestamp));
        return _seed % maxExclusive;
    }

    function random256() public returns (uint256 randomNumber) {
        uint256 rand = uint256(keccak256(keccak256(block.blockhash(block.number - 1), _seed), block.timestamp));
        _seed = uint64(rand);
        return rand;
    }
}

// @title ERC-165: Standard interface detection
// https://github.com/ethereum/EIPs/issues/165
contract ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// @title ERC-721: Non-Fungible Tokens
// @author Dieter Shirley (https://github.com/dete)
// @dev https://github.com/ethereum/eips/issues/721
contract ERC721 is ERC165 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 count);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
    // described in old version of the standard
    // use the more flexible transferFrom
    function takeOwnership(uint256 _tokenId) external;

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // Optional
    // function name() public view returns (string);
    // function symbol() public view returns (string);
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl);
    
    // Optional, described in old version of the standard
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl);
}

// Based on strings library by Nick Johnson <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c4a5b6a5a7acaaada084aaabb0a0abb0eaaaa1b0">[email&#160;protected]</a>>
// Apache license
// https://github.com/Arachnid/solidity-stringutils
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
    
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
    
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
    
    function toString(slice self) internal pure returns (string) {
        var ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
    
    function len(slice self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        var ptr = self._ptr - 31;
        var end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
    
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }
    
    function toSliceB32(bytes32 self) internal pure returns (slice ret) {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }
    
    function concat(slice self, slice other) internal pure returns (string) {
        var ret = new string(self._len + other._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
}

/**
 * https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/lifecycle/Pausable.sol
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableSimple is OwnableSimple {
    event Pause();
    event Unpause();

    bool public paused = true;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

// heavily modified from https://github.com/dob/auctionhouse/blob/master/contracts/AuctionHouse.sol
// license: MIT
// original author: Doug Petkanics (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="85f5e0f1eee4ebece6f6c5e2e8e4ece9abe6eae8">[email&#160;protected]</a>) https://github.com/dob
contract PresaleMarket is PausableSimple {
    struct Auction {
        address seller;
        uint256 price;           // In wei, can be 0
    }

    ERC721 public artworkContract;
    mapping (uint256 => Auction) artworkIdToAuction;

    //      0 means everything goes to the seller
    //   1000 means 1%
    //   2500 means 2.5%
    //   4000 means 4%
    //  50000 means 50%
    // 100000 means everything goes to us
    uint256 public distributionCut = 2500;
    bool public constant isPresaleMarket = true;

    event AuctionCreated(uint256 _artworkId, uint256 _price);
    event AuctionConcluded(uint256 _artworkId, uint256 _price, address _buyer);
    event AuctionCancelled(uint256 _artworkId);

    // mapping(address => uint256[]) public auctionsRunByUser;
    // No need to have a dedicated variable
    // Can be found by
    //  iterate all artwork ids owned by this auction contract
    //    get the auction object from artworkIdToAuction
    //      get the seller property
    //        return artwork id
    // however it would be a lot better if our second layer keeps track of it
    function auctionsRunByUser(address _address) external view returns(uint256[]) {
        uint256 allArtworkCount = artworkContract.balanceOf(this);

        uint256 artworkCount = 0;
        uint256[] memory allArtworkIds = new uint256[](allArtworkCount);
        for(uint256 i = 0; i < allArtworkCount; i++) {
            uint256 artworkId = artworkContract.tokenOfOwnerByIndex(this, i);
            Auction storage auction = artworkIdToAuction[artworkId];
            if(auction.seller == _address) {
                allArtworkIds[artworkCount++] = artworkId;
            }
        }

        uint256[] memory result = new uint256[](artworkCount);
        for(i = 0; i < artworkCount; i++) {
            result[i] = allArtworkIds[i];
        }

        return result;
    }

    // constructor. rename this if you rename the contract
    function PresaleMarket(address _artworkContract) public {
        artworkContract = ERC721(_artworkContract);
    }

    function bid(uint256 _artworkId) external payable whenNotPaused {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        require(auction.seller != msg.sender);
        uint256 price = auction.price;
        require(msg.value == price);

        address seller = auction.seller;
        delete artworkIdToAuction[_artworkId];

        if(price > 0) {
            uint256 myCut =  price * distributionCut / 100000;
            uint256 sellerCut = price - myCut;
            seller.transfer(sellerCut);
        }

        AuctionConcluded(_artworkId, price, msg.sender);
        artworkContract.transfer(msg.sender, _artworkId);
    }

    function getAuction(uint256 _artworkId) external view returns(address seller, uint256 price) {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        return (auction.seller, auction.price);
    }

    function createAuction(uint256 _artworkId, uint256 _price, address _originalOwner) external whenNotPaused {
        require(msg.sender == address(artworkContract));

        // Will check to see if the seller owns the asset at the contract
        _takeOwnership(_originalOwner, _artworkId);

        Auction memory auction;

        auction.seller = _originalOwner;
        auction.price = _price;

        _createAuction(_artworkId, auction);
    }

    function _createAuction(uint256 _artworkId, Auction _auction) internal {
        artworkIdToAuction[_artworkId] = _auction;
        AuctionCreated(_artworkId, _auction.price);
    }

    function cancelAuction(uint256 _artworkId) external {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_artworkId, seller);
    }

    function _cancelAuction(uint256 _artworkId, address _owner) internal {
        delete artworkIdToAuction[_artworkId];
        artworkContract.transfer(_owner, _artworkId);
        AuctionCancelled(_artworkId);
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    // only if there is a bug discovered and we need to migrate to a new market contract
    function cancelAuctionEmergency(uint256 _artworkId) external whenPaused onlyOwner {
        require(_isAuctionExist(_artworkId));
        Auction storage auction = artworkIdToAuction[_artworkId];
        _cancelAuction(_artworkId, auction.seller);
    }

    // simple methods

    function _isAuctionExist(uint256 _artworkId) internal view returns(bool) {
        return artworkIdToAuction[_artworkId].seller != address(0);
    }

    function _owns(address _address, uint256 _artworkId) internal view returns(bool) {
        return artworkContract.ownerOf(_artworkId) == _address;
    }

    function _takeOwnership(address _originalOwner, uint256 _artworkId) internal {
        artworkContract.transferFrom(_originalOwner, this, _artworkId);
    }
}

contract Presale is OwnableSimple, RandomApi, ERC721 {
    using strings for *;

    // There are 4 batches available for presale.
    // A batch is a set of artworks and
    // we plan to release batches monthly.
    uint256 public batchCount;
    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public supplies;
    mapping(uint256 => uint256) public sold;

    // Before each batch is released on the main contract,
    // we will disable transfers (including trading)
    // on this contract.
    // This is to prevent someone selling an artwork
    // on the presale contract when we are migrating
    // the artworks to the main contract.
    mapping(uint256 => bool) public isTransferDisabled;

    uint256[] public dnas;
    mapping(address => uint256) public ownerToTokenCount;
    mapping (uint256 => address) public artworkIdToOwner;
    mapping (uint256 => address) public artworkIdToTransferApproved;

    PresaleMarket public presaleMarket;

    bytes4 constant ERC165Signature_ERC165 = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));

    // Latest version of ERC721 perhaps
    bytes4 constant ERC165Signature_ERC721A =
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;tokensOfOwner(address)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256,string)&#39;));

    // as described in https://github.com/ethereum/eips/issues/721
    // as of January 23, 2018
    bytes4 constant ERC165Signature_ERC721B =
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;takeOwnership(uint256)&#39;)) ^
    bytes4(keccak256(&#39;transfer(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokenMetadata(uint256)&#39;));

    function Presale() public {
        // Artworks are released in batches, which we plan to release
        // every month if possible. New batches might contain new characters,
        // or old characters in new poses. Later batches will definitely be
        // more rare.

        // By buying at presale, you have a chance to buy the
        // artwork at potentially 50% of the public release initial sales price.
        // Note that because the public release uses a sliding price system,
        // once an artwork is in the marketplace, the price will get lower until
        // someone buys it.

        // Example: You bought a batch 1 artwork at presale for 0.05 eth.
        // When the game launches, the first batch 1 artworks are generated
        // on the marketplace with the initial price of 0.1 eth. You sell yours
        // on the marketplace for 0.08 eth which is lower than the public release
        // initial sales price. If someone buys your artwork, you will get profit.

        // Note that we do not guarantee any profit whatsoever. The price of an
        // item we sell will get cheaper until someone buys it. So other people might wait
        // for the public release artworks to get cheaper and buy it instead of
        // buying yours.

        // Distribution of presale artworks:
        // When the game is released, all batch 1 presale artworks
        // will be immediately available for trading.

        // When other batches are released, first we will generate 10 artworks
        // on the marketplace. After that we will distribute the presale
        // artworks with the rate of around 10 every minute.
        // Note that because of mining uncertainties we cannot guarantee any
        // specific timings.

        // public release initial sales price >= 0.1 ether
        _addPresale(0.05 ether, 450);

        // public release initial sales price >= 0.24 ether
        _addPresale(0.12 ether, 325);

        // public release initial sales price >= 0.7 ether
        _addPresale(0.35 ether, 150);

        // public release initial sales price >= 2.0 ether
        _addPresale(1.0 ether, 75);
    }

    function buy(uint256 _batch) public payable {
        require(_batch < batchCount);
        require(msg.value == prices[_batch]); // we don&#39;t want to deal with refunds
        require(sold[_batch] < supplies[_batch]);

        sold[_batch]++;
        uint256 dna = _generateRandomDna(_batch);

        uint256 artworkId = dnas.push(dna) - 1;
        ownerToTokenCount[msg.sender]++;
        artworkIdToOwner[artworkId] = msg.sender;

        Transfer(0, msg.sender, artworkId);
    }

    function getArtworkInfo(uint256 _id) external view returns (
        uint256 dna, address owner) {
        require(_id < totalSupply());

        dna = dnas[_id];
        owner = artworkIdToOwner[_id];
    }

    function withdraw() public onlyOwner {
        msg.sender.transfer(this.balance);
    }

    function getBatchInfo(uint256 _batch) external view returns(uint256 price, uint256 supply, uint256 soldAmount) {
        require(_batch < batchCount);

        return (prices[_batch], supplies[_batch], sold[_batch]);
    }

    function setTransferDisabled(uint256 _batch, bool _isDisabled) external onlyOwner {
        require(_batch < batchCount);

        isTransferDisabled[_batch] = _isDisabled;
    }

    function setPresaleMarketAddress(address _address) public onlyOwner {
        PresaleMarket presaleMarketTest = PresaleMarket(_address);
        require(presaleMarketTest.isPresaleMarket());
        presaleMarket = presaleMarketTest;
    }

    function sell(uint256 _artworkId, uint256 _price) external {
        require(_isOwnerOf(msg.sender, _artworkId));
        require(_canTransferBatch(_artworkId));
        _approveTransfer(_artworkId, presaleMarket);
        presaleMarket.createAuction(_artworkId, _price, msg.sender);
    }

    // Helper methods

    function _addPresale(uint256 _price, uint256 _supply) private {
        prices[batchCount] = _price;
        supplies[batchCount] = _supply;

        batchCount++;
    }

    function _generateRandomDna(uint256 _batch) private returns(uint256 dna) {
        uint256 rand = random256() % (10 ** 76);

        // set batch digits
        rand = rand / 100000000 * 100000000 + _batch;

        return rand;
    }

    function _isOwnerOf(address _address, uint256 _tokenId) private view returns (bool) {
        return artworkIdToOwner[_tokenId] == _address;
    }

    function _approveTransfer(uint256 _tokenId, address _address) internal {
        artworkIdToTransferApproved[_tokenId] = _address;
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        artworkIdToOwner[_tokenId] = _to;
        ownerToTokenCount[_to]++;

        ownerToTokenCount[_from]--;
        delete artworkIdToTransferApproved[_tokenId];

        Transfer(_from, _to, _tokenId);
    }

    function _approvedForTransfer(address _address, uint256 _tokenId) internal view returns (bool) {
        return artworkIdToTransferApproved[_tokenId] == _address;
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_isOwnerOf(_from, _tokenId));
        require(_approvedForTransfer(msg.sender, _tokenId));

        // prevent accidental transfer
        require(_to != address(0));
        require(_to != address(this));

        // perform the transfer and emit Transfer event
        _transfer(_from, _to, _tokenId);
    }

    function _canTransferBatch(uint256 _tokenId) internal view returns(bool) {
        uint256 batch = dnas[_tokenId] % 10;
        return !isTransferDisabled[batch];
    }

    function _tokenMetadata(uint256 _tokenId, string _preferredTransport) internal view returns (string infoUrl) {
        _preferredTransport; // we don&#39;t use this parameter

        require(_tokenId < totalSupply());

        strings.slice memory tokenIdSlice = _uintToBytes(_tokenId).toSliceB32();
        return "/http/etherwaifu.com/presale/artwork/".toSlice().concat(tokenIdSlice);
    }

    // Author: pipermerriam
    // MIT license
    // https://github.com/pipermerriam/ethereum-string-utils
    function _uintToBytes(uint256 v) internal pure returns(bytes32 ret) {
        if (v == 0) {
            ret = &#39;0&#39;;
        }
        else {
            while (v > 0) {
                ret = bytes32(uint256(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    // Required methods of ERC721

    function totalSupply() public view returns (uint256) {
        return dnas.length;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return ownerToTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address theOwner = artworkIdToOwner[_tokenId];
        require(theOwner != address(0));
        return theOwner;
    }

    function approve(address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));

        require(_isOwnerOf(msg.sender, _tokenId));

        // MUST throw if _tokenID does not represent an NFT
        // but if it is not NFT, owner is address(0)
        // which means it is impossible because msg.sender is a nonzero address

        require(msg.sender != _to);

        address prevApprovedAddress = artworkIdToTransferApproved[_tokenId];
        _approveTransfer(_tokenId, _to);

        // Don&#39;t send Approval event if it is just
        // reaffirming that there is no one approved
        if(!(prevApprovedAddress == address(0) && _to == address(0))) {
            Approval(msg.sender, _to, _tokenId);
        }
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        require(_isOwnerOf(msg.sender, _tokenId));

        // prevent accidental transfers
        require(_to != address(0));
        require(_to != address(this));
        require(_to != address(presaleMarket));

        // perform the transfer and emit Transfer event
        _transfer(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        _transferFrom(_from, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) external {
        require(_canTransferBatch(_tokenId));
        address owner = artworkIdToOwner[_tokenId];
        _transferFrom(owner, msg.sender, _tokenId);
    }

    // Optional methods of ERC721

    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds) {
        uint256 count = balanceOf(_owner);

        uint256[] memory res = new uint256[](count);
        uint256 allArtworkCount = totalSupply();
        uint256 i = 0;

        for(uint256 artworkId = 1; artworkId <= allArtworkCount && i < count; artworkId++) {
            if(artworkIdToOwner[artworkId] == _owner) {
                res[i++] = artworkId;
            }
        }

        return res;
    }

    function tokenMetadata(uint256 _tokenId, string _preferredTransport) external view returns (string infoUrl) {
        return _tokenMetadata(_tokenId, _preferredTransport);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId) {
        require(_index < balanceOf(_owner));

        // not strictly needed because if the state is consistent then
        // a match will be found
        uint256 allArtworkCount = totalSupply();

        uint256 i = 0;
        for(uint256 artworkId = 0; artworkId < allArtworkCount; artworkId++) {
            if(artworkIdToOwner[artworkId] == _owner) {
                if(i == _index) {
                    return artworkId;
                } else {
                    i++;
                }
            }
        }
        assert(false); // should never reach here
    }

    function tokenMetadata(uint256 _tokenId) external view returns (string infoUrl) {
        return _tokenMetadata(_tokenId, "http");
    }

    // ERC-165 Standard interface detection (required)

    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return _interfaceID == ERC165Signature_ERC165 ||
        _interfaceID == ERC165Signature_ERC721A ||
        _interfaceID == ERC165Signature_ERC721B;
    }
}