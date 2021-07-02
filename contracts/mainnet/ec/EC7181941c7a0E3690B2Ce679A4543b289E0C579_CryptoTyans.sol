// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AllDepsMerged.sol";

contract CryptoTyans is WhitelistedERC721, Ownable {
    using Math for uint256;

    string public constant provenance =
        "5ddee3a9170ab6edcd5c2947c42c5dc01599d1cb11a831e642736482813ca772";
    bytes32 public immutable baseUriHash;
    uint256 public constant maxSupply = 19800;
    uint256 private constant presaleDuration = 14 * 86400;

    address payable private _payoutAddress;
    string private _baseUri;
    uint256 private _tokenNum = 0;
    uint256 private _presaleFinishedAt = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory presaleUri,
        bytes32 futureUriHash,
        address payoutAddress,
        address proxyAddress
    ) WhitelistedERC721(name, symbol, proxyAddress) {
        bytes32 presaleUriHash = keccak256(bytes(presaleUri));
        require(
            presaleUriHash != futureUriHash,
            "presaleUriHash must not match baseUriHash"
        );

        _baseUri = presaleUri;
        baseUriHash = futureUriHash;
        _payoutAddress = payable(payoutAddress);
    }

    modifier finishedPresale() {
        require(
            totalSupply() >= maxSupply ||
                (_presaleFinishedAt != 0 &&
                    block.timestamp > _presaleFinishedAt),
            "Presale is not finished yet"
        );
        _;
    }

    function getSalesStartedAt() external view returns (uint256) {
        require(_presaleFinishedAt != 0, "Sales not yet defined");
        return _presaleFinishedAt - presaleDuration;
    }

    function isSalesStartedAt(uint256 timestamp) public view returns (bool) {
        return
            _presaleFinishedAt != 0 &&
            timestamp > _presaleFinishedAt - presaleDuration;
    }

    function startSales(uint256 presaleStartAt) public onlyOwner {
        require(_presaleFinishedAt == 0, "Sales are started already");
        _presaleFinishedAt = presaleStartAt + presaleDuration;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenNum;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) _tokenNum += 1;
        else if (to == address(0)) _tokenNum -= 1;
    }

    function getPrice() public pure returns (uint256) {
        return 50000000000000000; // 0.05ETH;
    }

    function mint(uint256 num) external payable {
        if (msg.value == 0 && owner() == msg.sender) {
            _mintWrapper(num);
        } else {
            require(
                isSalesStartedAt(block.timestamp),
                "Sales are not started yet"
            );
            require(getPrice() * num == msg.value, "Value sent is incorrect");
            _mintWrapper(num);
        }
    }

    function _mintWrapper(uint256 num) internal {
        require(num > 0 && num <= 20, "Num is not in 1-20 range");
        require(totalSupply() + num <= maxSupply, "Can't mint above maxSupply");
        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function metadataRevealed() external view returns (bool) {
        bytes32 _curUriHash = keccak256(bytes(_baseUri));
        return _curUriHash == baseUriHash;
    }

    function revealMetadata(string memory baseUri)
        external
        onlyOwner
        finishedPresale
    {
        bytes32 uriHash = keccak256(bytes(baseUri));
        require(uriHash == baseUriHash, "Can't accept wrong URI");
        _baseUri = baseUri;
    }

    function changePayoutAddress(address newPayoutAddress) external onlyOwner {
        _payoutAddress = payable(newPayoutAddress);
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0);
        _payoutAddress.transfer(contractBalance);
    }
}