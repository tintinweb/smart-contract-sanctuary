// SPDX-License-Identifier: MIT

/*
██████╗░░█████╗░██████╗░░█████╗░████████╗░█████╗░ 
██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗ 
██████╔╝██║░░██║██████╔╝███████║░░░██║░░░██║░░██║ 
██╔═══╝░██║░░██║██╔═══╝░██╔══██║░░░██║░░░██║░░██║ 
██║░░░░░╚█████╔╝██║░░░░░██║░░██║░░░██║░░░╚█████╔╝ 
╚═╝░░░░░░╚════╝░╚═╝░░░░░╚═╝░░╚═╝░░░╚═╝░░░░╚════╝░ 

██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
██████╔╝██║░░░██║██╔██╗██║█████═╝░╚█████╗░
██╔═══╝░██║░░░██║██║╚████║██╔═██╗░░╚═══██╗
██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗██████╔╝
╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

███╗░░██╗███████╗████████╗
████╗░██║██╔════╝╚══██╔══╝
██╔██╗██║█████╗░░░░░██║░░░
██║╚████║██╔══╝░░░░░██║░░░
██║░╚███║██║░░░░░░░░██║░░░
╚═╝░░╚══╝╚═╝░░░░░░░░╚═╝░░░
 */

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract PotatoPunks is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private totalSupplied;

    string public revealUri = "";
    string public uriFileExtension = ".json";
    string public hiddenMetadataUri;

    uint256 public costPerNft = 0.01 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmountPerTx = 10;

    bool public paused = true;
    bool public revealed = false;

    constructor() ERC721("Potato Punks", "PPKS") {
        setHiddenMetadataUri(
            "ipfs://QmbZiZRaNZxdWKRNaviY5qKZ1xKdBN9qLuqLEZgRbcdS99"
        );
    }

    modifier mintComplianceCheck(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid amount"
        );
        require(
            totalSupplied.current() + _mintAmount <= maxSupply,
            "Max Supply exceeded"
        );
        _;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupplied.current();
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintComplianceCheck(_mintAmount)
    {
        require(!paused, "The contract is paused!");
        require(msg.value >= costPerNft * _mintAmount, "Insufficient funds!");

        _mintLoop(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintComplianceCheck(_mintAmount)
        onlyOwner
    {
        _mintLoop(_receiver, _mintAmount);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriFileExtension
                    )
                )
                : "";
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCostPerMoodyTorta(uint256 _costPerNft) public onlyOwner {
        costPerNft = _costPerNft;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setRevealUri(string memory _revealUri) public onlyOwner {
        revealUri = _revealUri;
    }

    function setUriFileExtension(string memory _uriFileExtension)
        public
        onlyOwner
    {
        uriFileExtension = _uriFileExtension;
    }

    function setPauseContract(bool _state) public onlyOwner {
        paused = _state;
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            totalSupplied.increment();
            _safeMint(_receiver, totalSupplied.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return revealUri;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}