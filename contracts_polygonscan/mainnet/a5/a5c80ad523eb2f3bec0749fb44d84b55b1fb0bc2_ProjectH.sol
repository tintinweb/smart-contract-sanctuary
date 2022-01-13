// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "Strings.sol";
import "Payment.sol";
import "Guard.sol";
import "VRFConsumerBase.sol";

contract ProjectH is VRFConsumerBase, ERC721Enumerable, Ownable, Payment, Guard  {
    using Strings for uint256;

    bytes32 internal keyHash;
    uint256 internal fee = 0.0001 * 10 ** 18;

    uint256 public linkVRFOffset;
    string public baseURI;

    //settings
    uint256 public maxSupply = 8888;
    bool public whitelistStatus = false;
    bool public publicStatus = false;
    mapping(address => bool) public onWhitelist;
    mapping(address => uint256) public walletMints;

    //prices
    uint256 private whitelistPrice = 0.08 ether;
    uint256 private publicPrice = 0.1 ether;

    uint256 private price = 0.1 ether;

    //maxmint
    uint256 public whitelistMaxMint = 10;
    uint256 public publicMaxMint = 25;

    uint256 public maxMint = 25;

    //shares
    address[] private addressList = [
    0x32ae561e25aa976c765Ee48b22ba5486Cd31d7b9, //85%
    0xdF4d8b41fa2F47378B24c98a469517B73260d03b //15%
    ];
    uint[] private shareList = [85, 15];

    event VRFOffsetSet(uint vrfResult, bytes32 requestId);

    //token
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _keyHash
    )
    VRFConsumerBase(
        0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
    )
    ERC721(_name, _symbol)
    Payment(addressList, shareList){
        setURI(_initBaseURI);
        keyHash = _keyHash;
    }

    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 s = totalSupply();
        linkVRFOffset = randomness % s;
        emit VRFOffsetSet(linkVRFOffset, requestId);
    }

    function mint(uint256 _tokenAmount) public payable {
        uint256 s = totalSupply();
        uint256 _maxMint = maxMint;
        uint256 _price = publicPrice;
        if (!publicStatus) {
            _maxMint = whitelistMaxMint;
            _price = whitelistPrice;
            bool wl = onWhitelist[msg.sender];
            require(whitelistStatus, "Whitelist is not active" );
            if (!wl) {
                require(publicStatus, "You are not whitelisted!" );
            }
        }

        uint256 mintsByWallet = walletMints[msg.sender];
        _maxMint = _maxMint - mintsByWallet;

        require(_tokenAmount > 0, "Must mint at least one NFT." );
        require(_tokenAmount <= _maxMint, "Mint less");
        require( s + _tokenAmount <= maxSupply, "Mint less");
        require(msg.value >= _price * _tokenAmount, "MATIC input is wrong");

        for (uint256 i = 0; i < _tokenAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }

        mintsByWallet = mintsByWallet + _tokenAmount;
        walletMints[msg.sender] = mintsByWallet;

        delete s;
    }


    // admin minting
    function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
        require(gifts.length == recipient.length);
        uint g = 0;
        uint256 s = totalSupply();
        for(uint i = 0; i < gifts.length; ++i){
            g += gifts[i];
        }
        require( s + g <= maxSupply, "Too many" );
        delete g;
        for(uint i = 0; i < recipient.length; ++i){
            for(uint j = 0; j < gifts[i]; ++j){
                _safeMint( recipient[i], s++, "" );
            }
        }
        delete s;
    }

    // admin functionality
    function whitelistSet(address[] calldata _addresses) public onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
            onWhitelist[_addresses[i]] = true;
        }
    }

    //read metadata
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(tokenId <= maxSupply, "Token ID out of bounds!");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    //price switch
    function setPrice(uint256 _whitelistPrice, uint256 _publicPrice) public onlyOwner {
        price = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    //max switch
    function setMax(uint256 _whitelistMaxMint, uint256 _publicMaxMint) public onlyOwner {
        maxMint = _publicMaxMint;
        whitelistMaxMint = _whitelistMaxMint;
    }

    //write metadata
    function setURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    //onoff switch
    function setWhitelistMode(bool _wlstatus) public onlyOwner {
        whitelistStatus = _wlstatus;
    }

    function setPublicMode(bool _pstatus) public onlyOwner {
        publicStatus = _pstatus;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}