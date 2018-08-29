pragma solidity ^0.4.24;

// &#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;
// &#128512;
// &#128512;https://emojisan.github.io
// &#128512;
// &#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;&#128512;

// part of NFT token interface
// https://etherscan.io/address/0xE3f2F807ba194ea0221B9109fb14Da600C9e1eb6
interface Emojisan {

    function ownerOf(uint tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint tokenId) external;
    function mint(uint tokenId) external;
    function setMinter(address newMinter) external;
}

contract EmojisanMarketplace {

    struct Auction {
        address owner;
        uint32 bidBlock;
        uint128 currentPrice;
    }

    struct User {
        uint32 bidBlock;
        uint128 balance;
    }

    // NFT token address
    // https://etherscan.io/address/0xE3f2F807ba194ea0221B9109fb14Da600C9e1eb6
    Emojisan public constant emojisan = Emojisan(0x1f18c0e37E4a53ad3f110B7E1554Da41F26c8281);

    uint[] public tokenByIndex;
    mapping (uint => Auction) public auction;
    mapping (address => User) public user;
    uint32 private auctionTime = 20000;

    address public whaleAddress;
    uint32 public whaleStartTime;
    uint128 public whaleBalance;
    uint32 private whaleWithdrawDelay = 80000;

    uint128 public ownerBalance;
    uint private constant ownerTokenId = 128512;

    function tokens() external view returns (uint[]) {
        return tokenByIndex;
    }

    function tokensCount() external view returns (uint) {
        return tokenByIndex.length;
    }

    function wantItForFree(uint tokenId) external {
        // user &#128100; can bid only on one 1️⃣ token at a time ⏱️
        require(block.number >= user[msg.sender].bidBlock + auctionTime);
        // check auction has not started &#128683;&#127916;
        require(auction[tokenId].owner == address(this));
        auction[tokenId] = Auction({
            owner: msg.sender,
            bidBlock: uint32(block.number),
            currentPrice: 0
        });
        user[msg.sender].bidBlock = uint32(block.number);
        emojisan.mint(tokenId);
    }

    function wantItMoreThanYou(uint tokenId) external payable {
        // user &#128100; can bid only on one 1️⃣ token at a time ⏱️
        require(block.number >= user[msg.sender].bidBlock + auctionTime);
        Auction memory a = auction[tokenId];
        // check auction has not finished &#128683;&#127937;
        require(block.number < a.bidBlock + auctionTime);
        uint128 previousPrice = a.currentPrice;
        // fancy &#129488; price &#128176; calculation &#128200;
        // 0 ➡️ 0.002 ➡️ 0.004 ➡️ 0.008 ➡️ 0.016 ➡️ 0.032 ➡️ 0.064 ➡️ 0.128
        // ➡️ 0.256 ➡️ 0.512 ➡️ 1 ➡️ 1.5 ➡️ 2 ➡️ 2.5 ➡️ 3 ➡️ 3.5 ➡️ 4 ➡️ ...
        uint128 price;
        if (previousPrice == 0) {
            price = 2 finney;
        } else if (previousPrice < 500 finney) {
            price = 2 * previousPrice;
        } else {
            price = (previousPrice + 500 finney) / 500 finney * 500 finney;
        }
        require(msg.value >= price);
        uint128 priceDiff = price - previousPrice;
        // previous &#128100; gets what they &#128582; paid ➕ 2️⃣5️⃣%
        user[a.owner].balance += previousPrice + priceDiff / 4;
        // whale &#128011; gets 5️⃣0️⃣%
        whaleBalance += priceDiff / 2;
        // owner &#128105; of token 128512 &#128512; gets 2️⃣5️⃣%
        ownerBalance += priceDiff / 4;
        auction[tokenId] = Auction({
            owner: msg.sender,
            bidBlock: uint32(block.number),
            currentPrice: price
        });
        user[a.owner].bidBlock = 0;
        user[msg.sender].bidBlock = uint32(block.number);
        if (msg.value > price) {
            // send back eth if someone sent too much &#128184;&#128184;&#128184;
            msg.sender.transfer(msg.value - price);
        }
    }

    function wantMyToken(uint tokenId) external {
        Auction memory a = auction[tokenId];
        // check auction has finished &#127937;
        require(block.number >= a.bidBlock + auctionTime);
        emojisan.transferFrom(this, a.owner, tokenId);
    }

    function wantMyEther() external {
        uint amount = user[msg.sender].balance;
        user[msg.sender].balance = 0;
        msg.sender.transfer(amount);
    }

    function wantToBeWhale() external {
        // need to have more tokens &#128176; than current &#128011;
        require(emojisan.balanceOf(msg.sender) > emojisan.balanceOf(whaleAddress));
        whaleAddress = msg.sender;
        // whale &#128051; needs to wait some time ⏱️ before snatching that sweet &#127852; eth &#129297;
        whaleStartTime = uint32(block.number);
    }

    function whaleWantMyEther() external {
        require(msg.sender == whaleAddress);
        // whale &#128051; needs to wait some time ⏱️ between snatching that sweet &#127853; eth &#129297;
        require(block.number >= whaleStartTime + whaleWithdrawDelay);
        whaleStartTime = uint32(block.number);
        uint amount = whaleBalance;
        whaleBalance = 0;
        whaleAddress.transfer(amount);
    }

    function ownerWantMyEther() external {
        uint amount = ownerBalance;
        ownerBalance = 0;
        emojisan.ownerOf(ownerTokenId).transfer(amount);
    }

    function wantNewTokens(uint[] tokenIds) external {
        // only owner &#128105; of token 128512 &#128512;
        require(msg.sender == emojisan.ownerOf(ownerTokenId));
        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            auction[tokenId].owner = this;
            tokenByIndex.push(tokenId);
        }
    }

    function wantNewMinter(address minter) external {
        // only owner &#128105; of token 128512 &#128512;
        require(msg.sender == emojisan.ownerOf(ownerTokenId));
        emojisan.setMinter(minter);
    }

    function debug() external {
        require(msg.sender == emojisan.ownerOf(ownerTokenId));
        auctionTime = 1;
        whaleWithdrawDelay = 1;
    }
}