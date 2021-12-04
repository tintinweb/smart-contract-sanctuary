// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract SharkCatPlanet is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public reservedGiveaway = 99; // Reserved last 99 SharkCats for giveaway (ID 9901 - 9999)
    uint256 public limitMintPerTx = 20;
    uint256 private maxCashbackPerToken;
    string public baseURI;
    string public baseExtension = ".json";
    bool public paused = true;
    bool private cashback = true;

    enum SaleRound {
        OG,
        WL,
        Public,
        Closed
    }

    SaleRound public saleRound = SaleRound.Closed;

    mapping(SaleRound => uint256) public salePrice;
    mapping(SaleRound => bytes32) private rootPreSaleWhiteList;
    mapping(SaleRound => mapping(address => uint256)) public preSaleMintAddressesMintedCount;

    constructor(string memory _initBaseURI, uint256 _initMaxCashbackPerToken) ERC721("SharkCat Planet", "SCP") {
        setBaseURI(_initBaseURI);
        setMaxCashbackPerToken(_initMaxCashbackPerToken);
        setSalePrice(SaleRound.OG, 0.065 ether);
        setSalePrice(SaleRound.WL, 0.075 ether);
        setSalePrice(SaleRound.Public, 0.085 ether);
    }

    modifier saleOpen(uint256 _mintAmount) {
        require(!paused, "Sales paused");
        require(saleRound != SaleRound.Closed, "Sales closed");
        require(
            totalSupply() + _mintAmount <= MAX_SUPPLY - reservedGiveaway,
            "Exceeds maximum SharkCats limit"
        );
        require(
            _mintAmount <= limitMintPerTx || limitMintPerTx == 0,
            "Mint SharkCats per tx exceeded"
        );
        _;
    }

    function isWhitelisted(SaleRound _round, bytes32[] memory _proof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(address(this), msg.sender));
        return MerkleProof.verify(_proof, rootPreSaleWhiteList[_round], leaf);
    }

    function preSaleMint(uint256 _mintAmount, bytes32[] memory _proof) public payable saleOpen(_mintAmount) {
        uint256 startGas = gasleft();
        uint256 supply = totalSupply();
        require(saleRound == SaleRound.OG || saleRound == SaleRound.WL, "Pre sales not open");
        if (saleRound == SaleRound.OG) {
            require(isWhitelisted(SaleRound.OG, _proof), "Not whitelisted");
            require(
                preSaleMintAddressesMintedCount[saleRound][msg.sender] + _mintAmount <= 4,
                "Mint SharkCat per address exceeded, come back again next round"
            );
        } else if (saleRound == SaleRound.WL) {
            require(
                isWhitelisted(SaleRound.WL, _proof) || isWhitelisted(SaleRound.OG, _proof),
                "Not whitelisted"
            );
            require(
                preSaleMintAddressesMintedCount[saleRound][msg.sender] + _mintAmount <= 2,
                "Mint SharkCat per address exceeded, come back again next round"
            );
        }
        require(msg.value >= salePrice[saleRound] * _mintAmount, "Value below price");

        preSaleMintAddressesMintedCount[saleRound][msg.sender] += _mintAmount;
        uint256 cashbackAmount = 0;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + i - (99 - reservedGiveaway);
            _safeMint(msg.sender, tokenId);

            if (cashback && tokenId <= 3000) {
                cashbackAmount = (startGas - gasleft()) * tx.gasprice;
                if (cashbackAmount > maxCashbackPerToken * i) {
                    cashbackAmount = maxCashbackPerToken * i;
                }
            }
        }

        if (cashbackAmount > 0) {
            _withdraw(msg.sender, cashbackAmount);
        }
    }

    function mint(uint256 _mintAmount) public payable saleOpen(_mintAmount) {
        uint256 startGas = gasleft();
        uint256 supply = totalSupply();
        require(saleRound == SaleRound.Public, "Sales not open");
        require(msg.value >= salePrice[SaleRound.Public] * _mintAmount, "Value below price");

        uint256 cashbackAmount = 0;
        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + i - (99 - reservedGiveaway);
            _safeMint(msg.sender, tokenId);

            if (cashback && tokenId <= 3000) {
                cashbackAmount = (startGas - gasleft()) * tx.gasprice;
                if (cashbackAmount > maxCashbackPerToken * i) {
                    cashbackAmount = maxCashbackPerToken * i;
                }
            }
        }

        if (cashbackAmount > 0) {
            _withdraw(msg.sender, cashbackAmount);
        }
    }

    function mintUnsoldToken(address _to, uint256 _mintAmount) public onlyOwner {
        uint256 supply = totalSupply();
        require(!paused, "Paused");
        require(saleRound == SaleRound.Closed, "Sales not closed");
        require(supply + _mintAmount <= MAX_SUPPLY - reservedGiveaway, "Exceeds maximum SharkCats limit");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + i - (99 - reservedGiveaway);
            _safeMint(_to, tokenId);
        }
    }

    function giveAway(address _to, uint256[] memory _tokensId) public onlyOwner {
        uint256 supply = totalSupply();
        require(_tokensId.length > 0);
        require(_tokensId.length <= reservedGiveaway, "Exceeds reserved giveaway limit");
        require(supply + _tokensId.length <= MAX_SUPPLY, "Exceeds maximum SharkCats limit");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            require(_tokensId[i] >= 9901 && _tokensId[i] <= MAX_SUPPLY, "Token ID out of range");
            require(!_exists(_tokensId[i]), "Token already exists");
        }

        reservedGiveaway -= _tokensId.length;
        for (uint256 i = 0; i < _tokensId.length; i++) {
            _safeMint(_to, _tokensId[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent SharkCat"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setSalePrice(SaleRound _round, uint256 _newPrice) public onlyOwner {
        salePrice[_round] = _newPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setRootPreSaleWhitelist(SaleRound _round, bytes32 _root) public onlyOwner {
        rootPreSaleWhiteList[_round] = _root;
    }

    function setLimitMintPerTx(uint256 _newLimitAmount) public onlyOwner {
        limitMintPerTx = _newLimitAmount;
    }

    function setSaleRound(SaleRound _round) public onlyOwner {
        saleRound = _round;
    }

    function pause(bool _pause) public onlyOwner {
        paused = _pause;
    }

    function setCashback(bool _cashback) public onlyOwner {
        cashback = _cashback;
    }

    function setMaxCashbackPerToken(uint256 _amount) public onlyOwner {
        maxCashbackPerToken = _amount;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether");
        _withdraw(owner(), balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = payable(_address).call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}