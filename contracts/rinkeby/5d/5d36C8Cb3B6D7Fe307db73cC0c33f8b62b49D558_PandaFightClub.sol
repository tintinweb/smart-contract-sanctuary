// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./String.sol";

contract PandaFightClub is Ownable, ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    
    //Sale and Supply
    uint256 public mintPrice = 0.0888 ether;
    uint256 public mintLimit = 18;
    uint256 public totalSupply = 0;
    uint256 public supplyLimit;
    uint256 public wallet1Share = 50;
    uint256 public wallet2Share = 29;
    uint256 public wallet3Share = 15;
    uint256 public wallet4Share = 5;
    uint256 public wallet5Share = 1;
    uint256 public namingPrice = 0 ether;
    uint8 public charLimit = 32;

    address public wallet1;
    address public wallet2;
    address public wallet3;
    address public wallet4;
    address public wallet5;

    string public baseURI = "";
    bool public namingAllowed = false;
    bool public saleActive = false;

    event wallet1AddressChanged(address _wallet1);
    event wallet2AddressChanged(address _wallet2);
    event wallet3AddressChanged(address _wallet3);
    event wallet4AddressChanged(address _wallet2);
    event wallet5AddressChanged(address _wallet3);
    event SaleStateChanged(bool _state);
    event SupplyLimitChanged(uint256 _supplyLimit);
    event MintLimitChanged(uint256 _mintLimit);
    event MintPriceChanged(uint256 _mintPrice);
    event ReservePandas(uint256 _numberOfTokens);
    event SharesChanged(uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4, uint256 _value5);
    event NameChanged(uint256 _tokenId, string _name);
    event NamingPriceChanged(uint256 _price);
    event BaseURIChanged(string _baseURI);
    event PandaMinted(address indexed _user, uint256 indexed _tokenId, string _tokenURI);
    event NamingStateChanged(bool _namingAllowed);

    constructor(
        uint256 tokenSupplyLimit,
        string memory _baseURI
    ) ERC721("Panda Fight Club", "PFC") {
        
        supplyLimit = tokenSupplyLimit;
        wallet1 = owner();
        wallet2 = owner();
        wallet3 = owner();
        wallet4 = owner();
        wallet5 = owner();
        
        baseURI = _baseURI;

        emit NamingPriceChanged(namingPrice);
        emit SupplyLimitChanged(supplyLimit);
        emit MintLimitChanged(mintLimit);
        emit MintPriceChanged(mintPrice);
        emit SharesChanged(wallet1Share, wallet2Share, wallet3Share, wallet4Share, wallet5Share);
        emit BaseURIChanged(_baseURI);
        emit NamingStateChanged(true);
        
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? 
        string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function buyToken(uint _numberOfTokens) external payable {
        require(saleActive, "Sale is not active.");
        require(_numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_numberOfTokens), "Insufficient payment.");
        
        _mintPandas(_numberOfTokens);
    }
    
    function _mintPandas(uint _numberOfTokens) internal {
        require(totalSupply.add(_numberOfTokens) <= supplyLimit, "Not enough tokens left.");

        uint256 newId = totalSupply;
        for(uint i = 0; i < _numberOfTokens; i++) {
            newId += 1;
            totalSupply = totalSupply.add(1);

            _safeMint(msg.sender, newId);
            emit PandaMinted(msg.sender, newId, tokenURI(newId));
        }
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        emit SaleStateChanged(saleActive);
    }
    
    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        require(_supplyLimit >= totalSupply, "Error 504");
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }
    
    function changeMintLimit(uint256 _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
        emit MintLimitChanged(_mintLimit);
    }
    
    function changeMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }
    
    function toggleNaming(bool _namingAllowed) external onlyOwner {
        namingAllowed = _namingAllowed;
        emit NamingStateChanged(_namingAllowed);
    }
    
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURIChanged(_baseURI);
    }
    
    function setCharacterLimit(uint8 _charLimit) external onlyOwner {
        charLimit = _charLimit;
    }
    
    function reservePandas(uint256 _numberOfTokens) external onlyOwner {
        _mintPandas(_numberOfTokens);
        emit ReservePandas(_numberOfTokens);
    }
    
    function setWallet_1(address _address) external onlyOwner {
        wallet1 = _address;
        emit wallet1AddressChanged(_address);
    }
    
    function setWallet_2(address _address) external onlyOwner {
        wallet2 = _address;
        emit wallet2AddressChanged(_address);
    }

    function setWallet_3(address _address) external onlyOwner {
        wallet3 = _address;
        emit wallet3AddressChanged(_address);
    }
    
    function setWallet_4(address _address) external onlyOwner {
        wallet4 = _address;
        emit wallet4AddressChanged(_address);
    }

    function setWallet_5(address _address) external onlyOwner {
        wallet5 = _address;
        emit wallet5AddressChanged(_address);
    }
    
    function changeWalletShares(uint256 _value1, uint256 _value2, uint256 _value3, uint256 _value4, uint256 _value5) external onlyOwner {
        require(_value1 + _value2 + _value3 + _value4 + _value5 == 100, "Shares are not adding up to 100.");
        wallet1Share = _value1;
        wallet2Share = _value2;
        wallet3Share = _value3;
        wallet4Share = _value4;
        wallet5Share = _value5;
        emit SharesChanged(_value1, _value2, _value3, _value4, _value5);
    }
    
    function emergencyWithdraw() external onlyOwner {
        require(address(this).balance > 0, "No funds in smart Contract.");
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw Failed.");
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance to withdraw.");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1.call{value: _amount.mul(wallet1Share).div(100)}("");
        (bool wallet2Success, ) = wallet2.call{value: _amount.mul(wallet2Share).div(100)}("");
        (bool wallet3Success, ) = wallet3.call{value: _amount.mul(wallet3Share).div(100)}("");
        (bool wallet4Success, ) = wallet4.call{value: _amount.mul(wallet4Share).div(100)}("");
        (bool wallet5Success, ) = wallet5.call{value: _amount.mul(wallet5Share).div(100)}("");

        require(wallet1Success && wallet2Success && wallet3Success && wallet4Success && wallet5Success, "Withdrawal failed.");
    }
    
    //Interact with NFT. Does not includ the dojo (other contract)
    function nameNFT(uint256 _tokenId, string memory _name) external payable {
        require(msg.value == namingPrice, "Incorrect price paid.");
        require(namingAllowed, "Naming is disabled.");
        require(ownerOf(_tokenId) == msg.sender, "Only owner of NFT can change name.");
        require(bytes(_name).length <= charLimit, "Name exceeds characters limit.");
        emit NameChanged(_tokenId, _name);
    }
    
}