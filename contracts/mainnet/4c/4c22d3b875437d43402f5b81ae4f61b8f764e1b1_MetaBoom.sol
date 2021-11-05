// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ComposableTopDown.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract MetaBoom is ComposableTopDown, Ownable {
    using Address for address;
    using Strings for uint256;

    uint256 public constant maxSupply = 5000;
    uint256 public constant price = 0.05 ether;
    uint256 public constant airDropMaxSupply = 300;
    uint256 public totalSupply = 0;
    uint256 public totalAirDrop = 0;
    string public baseTokenURI;
    string public subTokenURI;
    bool public paused = false;

    uint256 public preSaleTime = 1636682400;
    uint256 public publicSaleTime = 1637028000;

    mapping(address => bool) public airDropList;
    mapping(address => bool) public whiteList;
    mapping(address => uint8) public prePaidNumAry;
    mapping(address => uint8) public holdedNumAry;
    mapping(address => uint8) public claimed;
    mapping(uint256 => string) private _tokenURIs;

    event MetaBoomPop(uint256 indexed tokenId, address indexed tokenOwner);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _subUri
    ) ComposableTopDown(_name, _symbol) {
        baseTokenURI = _uri;
        subTokenURI = _subUri;
    }

    function preSale(uint8 _purchaseNum) external payable onlyWhiteList {
        require(!paused, "MetaBoom: currently paused");
        require(
            block.timestamp >= preSaleTime,
            "MetaBoom: preSale is not open"
        );
        require(
            (totalSupply + _purchaseNum) <= (maxSupply - airDropMaxSupply),
            "MetaBoom: reached max supply"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= 5,
            "MetaBoom: can not hold more than 5"
        );
        require(
            msg.value >= (price * _purchaseNum),
            "MetaBoom: price is incorrect"
        );

        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
        prePaidNumAry[_msgSender()] =
            prePaidNumAry[_msgSender()] +
            _purchaseNum;
        totalSupply = totalSupply + _purchaseNum;
    }

    function publicSale(uint8 _purchaseNum) external payable {
        require(!paused, "MetaBoom: currently paused");
        require(
            block.timestamp >= publicSaleTime,
            "MetaBoom: publicSale is not open"
        );
        require(
            (totalSupply + _purchaseNum) <= (maxSupply - airDropMaxSupply),
            "MetaBoom: reached max supply"
        );
        require(
            (holdedNumAry[_msgSender()] + _purchaseNum) <= 5,
            "MetaBoom: can not hold more than 5"
        );
        require(
            msg.value >= (price * _purchaseNum),
            "MetaBoom: price is incorrect"
        );

        holdedNumAry[_msgSender()] = holdedNumAry[_msgSender()] + _purchaseNum;
        prePaidNumAry[_msgSender()] =
            prePaidNumAry[_msgSender()] +
            _purchaseNum;
        totalSupply = totalSupply + _purchaseNum;
    }

    function ownerMInt(address _addr)
        external
        onlyOwner
        returns (uint256 tokenId_)
    {
        require(
            totalSupply < (maxSupply - airDropMaxSupply),
            "MetaBoom: reached max supply"
        );
        require(holdedNumAry[_addr] < 5, "MetaBoom: can not hold more than 5");

        tokenId_ = _safeMint(_addr);
        holdedNumAry[_addr]++;
        claimed[_addr]++;
        totalSupply++;
        emit MetaBoomPop(tokenId_, _addr);
        return tokenId_;
    }

    function claimAirdrop() external onlyAirDrop {
        require(
            block.timestamp >= preSaleTime,
            "MetaBoom: Not able to claim yet."
        );
        uint256 tokenId_ = _safeMint(_msgSender());
        airDropList[_msgSender()] = false;
        emit MetaBoomPop(tokenId_, _msgSender());
        holdedNumAry[_msgSender()]++;
        claimed[_msgSender()]++;
    }

    function claimAll() external {
        require(
            block.timestamp >= preSaleTime,
            "MetaBoom: Not able to claim yet"
        );

        require(
            prePaidNumAry[_msgSender()] > 0,
            "MetaBoom: already claimed all"
        );

        for (uint8 i = 0; i < prePaidNumAry[_msgSender()]; i++) {
            uint256 tokenId_ = _safeMint(_msgSender());
            emit MetaBoomPop(tokenId_, _msgSender());
        }

        claimed[_msgSender()] += prePaidNumAry[_msgSender()];
        prePaidNumAry[_msgSender()] = 0;
    }

    modifier onlyWhiteList() {
        require(whiteList[_msgSender()], "MetaBoom: caller not in WhiteList");
        _;
    }

    modifier onlyAirDrop() {
        require(
            airDropList[_msgSender()],
            "MetaBoom: caller not in AirdropList"
        );
        _;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseTokenURI = _baseURI;
    }

    function setSubURI(string memory _subURI) external onlyOwner {
        subTokenURI = _subURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _tokenURIs[_tokenId] = _tokenURI;
    }

    function setPreSaleTime(uint256 _time) external onlyOwner {
        preSaleTime = _time;
    }

    function setPublicSaleTime(uint256 _time) external onlyOwner {
        publicSaleTime = _time;
    }

    function pauseSale() external onlyOwner {
        paused = !paused;
    }

    function addBatchWhiteList(address[] memory _accounts) external onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            whiteList[_accounts[i]] = true;
        }
    }

    function addBatchAirDropList(address[] memory _accounts)
        external
        onlyOwner
    {
        require(
            totalAirDrop + _accounts.length <= airDropMaxSupply,
            "reached max airDropSupply"
        );

        for (uint256 i = 0; i < _accounts.length; i++) {
            require(holdedNumAry[_accounts[i]] < 5, "can not hold more than 5");
            airDropList[_accounts[i]] = true;
        }

        totalAirDrop = totalAirDrop + _accounts.length;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function childContractOfToken(uint256 _tokenId)
        external
        view
        returns (address[] memory)
    {
        uint256 childCount = totalChildContracts(_tokenId);
        if (childCount == 0) {
            return new address[](0);
        } else {
            address[] memory result = new address[](childCount);
            uint256 index;
            for (index = 0; index < childCount; index++) {
                result[index] = childContractByIndex(_tokenId, index);
            }
            return result;
        }
    }

    function childTokensOfChildContract(uint256 _tokenId, address _childAddr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = totalChildTokens(_tokenId, _childAddr);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = childTokenByIndex(_tokenId, _childAddr, index);
            }
            return result;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(_tokenURIs[_tokenId]).length > 0
                ? string(abi.encodePacked(subTokenURI, _tokenURIs[_tokenId]))
                : string(
                    abi.encodePacked(baseTokenURI, Strings.toString(_tokenId))
                );
    }
}