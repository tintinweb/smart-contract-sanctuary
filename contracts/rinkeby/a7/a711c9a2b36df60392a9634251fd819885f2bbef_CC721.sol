// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/math/Math.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./AllDeps.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract WhitelistedERC721 is ERC721 {
    address private proxyRegistryAddress;

    constructor(
        string memory name,
        string memory symbol,
        address proxyAddress
    ) ERC721(name, symbol) {
        proxyRegistryAddress = proxyAddress;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }
}

contract CC721 is WhitelistedERC721, Ownable {
    using Math for uint256;

    string public constant provenance = "TBD";
    bytes32 public immutable baseUriProvenance;
    uint256 private constant presaleDuration = 14 * 86400;

    uint256 public constant maxSupply = 10000;
    uint256 public constant maxReserved = 300;

    address payable private _payoutAddress;
    string private _baseUri;
    uint256 private _tokenNum = 0;
    uint256 private _reservedNum = 0;
    uint256 private _presaleNum = 0;
    uint256 private _presaleFinishedAt = 0;

    string private constant ERR_PRESALE_NOT_STARTED =
        "Presale is not started yet";
    string private constant ERR_PRESALE_IS_FINISHED =
        "Presale is finished already";

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
            "presaleUriHash must not match baseUriProvenance"
        );

        _baseUri = presaleUri;
        baseUriProvenance = futureUriHash;
        _payoutAddress = payable(payoutAddress);
    }

    modifier activePresale() {
        if (_presaleFinishedAt == 0) {
            revert(ERR_PRESALE_NOT_STARTED);
        } else if (presalePercent() == 100) {
            revert(ERR_PRESALE_IS_FINISHED);
        } else {
            require(
                block.timestamp > _presaleFinishedAt - presaleDuration,
                ERR_PRESALE_NOT_STARTED
            );
            require(
                block.timestamp < _presaleFinishedAt,
                ERR_PRESALE_IS_FINISHED
            );
        }
        _;
    }

    modifier finishedPresale() {
        require(
            isPresaleFinishedAt(block.timestamp),
            "Presale is not finished yet"
        );
        _;
    }

    function getReservedNum() public view returns (uint256) {
        return _reservedNum;
    }

    function getPresaleNum() public view returns (uint256) {
        return _presaleNum;
    }

    function getPresaleStartedAt() public view returns (uint256) {
        require(_presaleFinishedAt != 0, ERR_PRESALE_NOT_STARTED);
        return _presaleFinishedAt - presaleDuration;
    }

    function getPresaleFinishedAt() public view returns (uint256) {
        require(_presaleFinishedAt != 0, ERR_PRESALE_NOT_STARTED);
        return _presaleFinishedAt;
    }

    function isPresaleActiveAt(uint256 timestamp) public view returns (bool) {
        return
            _presaleFinishedAt != 0 &&
            timestamp > _presaleFinishedAt - presaleDuration &&
            timestamp < _presaleFinishedAt &&
            presalePercent() < 100;
    }

    function isPresaleFinishedAt(uint256 timestamp) public view returns (bool) {
        return
            _presaleFinishedAt != 0 &&
            (timestamp >= _presaleFinishedAt || presalePercent() == 100);
    }

    function presalePercent() public view returns (uint256) {
        uint256 maxPresale = maxSupply - maxReserved;
        return (100 * _presaleNum.min(maxPresale)) / maxPresale;
    }

    function startPresale(uint256 presaleStartAt) public onlyOwner {
        require(_presaleFinishedAt == 0, "Presale started already");
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
        return 80000000000000000; // 0.08ETH
    }

    function _validateInput(uint256 num) internal pure {
        require(num > 0 && num <= 20, "Max 20 token per transaction");
    }

    function _validateSupply(uint256 num) internal view {
        require(totalSupply() + num <= maxSupply, "Can't mint above maxSupply");
    }

    function mint(uint256 num) public payable {
        _validateInput(num);
        _validateSupply(num);
        if (owner() == msg.sender && msg.value == 0) {
            ownerMint(num);
        } else if (isPresaleActiveAt(block.timestamp)) {
            presaleMint(num);
        } else if (isPresaleFinishedAt(block.timestamp)) {
            normalMint(num);
        } else {
            revert("Sales are not started yet");
        }
    }

    function presaleMint(uint256 num) internal activePresale {
        _presaleNum += num;
        publicMint(num);
    }

    function normalMint(uint256 num) internal finishedPresale {
        publicMint(num);
    }

    function publicMint(uint256 num) internal {
        require(getPrice() * num == msg.value, "Value sent is incorrect");
        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function ownerMint(uint256 num) internal onlyOwner {
        require(
            _reservedNum + num <= maxReserved,
            "Can't mint above maxReserved"
        );
        _reservedNum += num;
        for (uint256 i = 0; i < num; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function baseUriFrozen() public view returns (bool) {
        bytes32 _curUriHash = keccak256(bytes(_baseUri));
        return _curUriHash == baseUriProvenance;
    }

    function frozeBaseUri(string memory baseUri)
        public
        onlyOwner
        finishedPresale
    {
        bytes32 uriHash = keccak256(bytes(baseUri));
        require(uriHash == baseUriProvenance, "Can't accept wrong URI");
        _baseUri = baseUri;
    }

    function changePayoutAddress(address newPayoutAddress) public onlyOwner {
        _payoutAddress = payable(newPayoutAddress);
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0);
        _payoutAddress.transfer(contractBalance);
    }
}