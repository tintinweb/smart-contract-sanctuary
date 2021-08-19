import "./ERC721.sol";
import "./SafeMath.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title NFT contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract NFT is ERC721 {
    using SafeMath for uint256;

    uint256 public count = 0;
    uint256 public nftPrice = 0.00000001 * (10 ** 18);
    uint public constant maxNftPurchase = 100;
    uint256 public MAX_NFTS = 100;
    bool public saleIsActive = true;

    event SafeMinted(address who, uint64 timestamp, uint256[] tokenIds);

    constructor() ERC721("Cartoon dragons", "DRAG") {
        _setBaseURI("https://nft-drag.s3.amazonaws.com/");
        initialMint();
    }

    function initialMint() private {
        _safeMint(msg.sender, 0);
        count += 1;
    }

    function withdraw(address payable beneficiant) public onlyOwner {
        uint balance = address(this).balance;
        beneficiant.transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function discoverNft(uint64 timeStamp, uint64 numberOfToken) public payable {
        uint256 ownedTokensCount = balanceOf(msg.sender) + 1;
        require(saleIsActive, "Sale must be active to mint Nft");
        require(ownedTokensCount <= maxNftPurchase, "Can only mint 20 tokens per address");
        require(totalSupply().add(1) <= MAX_NFTS, "Purchase would exceed max supply of Nfts");
        require(nftPrice.mul(1) <= msg.value, "Ether value sent is not correct");

        uint256[] memory output = new uint256[](numberOfToken);

        for(uint32 i = 0; i < numberOfToken; i++){
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            output[i] = mintIndex;
            count += 1;
        }

        emit SafeMinted(msg.sender, timeStamp, output);
    }

    function getCount() public view returns(uint256) {
        return count;
    }

    // Emergency: can be changed to account for large fluctuations in ETH price
    function emergencyChangePrice(uint256 newPrice) public onlyOwner {
        nftPrice = newPrice;
    }

    function totalSupply() public view returns (uint256) {
        return getCount();
    }

    function toString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}