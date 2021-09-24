// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Strings.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

interface IPremintKeys{
    function getPremintKeyType(uint256 _keyId) external pure returns(uint256);
    function exists(uint256 _tokenId) external view returns (bool);
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool);
}

interface IWalletOfOwner {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}

contract OGMK is ERC721Enumerable, IPremintKeys, IWalletOfOwner, Ownable, ReentrancyGuard {
    using Strings for uint256;
    
    bool public saleLive = true;

    uint256 public tokenIdSilver = 0;
    uint256 public tokenIdGold = 566;
    
    uint256 public constant maxTokensSilver = 566;
    uint256 public constant maxTokensGold = 100;
    
    uint256 public counterGold = 0;
    uint256 public counterSilver = 0;
    
    uint256 public counterGoldReserved = 0;
    uint256 private _tokenIdGoldReserved = 656;
    uint256 private _goldReserved = 10;
    uint256 private constant _reservedPerMint = 100;
    
    mapping(address => uint256) public ownersGold;
    mapping(address => uint256) public ownersSilver;
    
    string private _baseTokenURI;
    string private _contractURI;
    
    constructor() ERC721("OG Motorcycle Keys", "OGMK")  {
    }
    
    //attention! doesn't check the limits!
    function addToGoldList(address[] memory _targetAddreses) external onlyOwner{
        for(uint256 i; i < _targetAddreses.length; i++){
            address targetAddress = _targetAddreses[i];
            require(targetAddress != address(0),        "NULL_ADDRESS");
            require(ownersGold[targetAddress] == 0,     "DUPLICATE_ADDRESS");
            ownersGold[targetAddress] = 1;
        }
    }
    
    //attention! doesn't check the limits!
    function addToSilverList(address[] memory _targetAddreses) external onlyOwner{
        for(uint256 i; i < _targetAddreses.length; i++){
            address targetAddress = _targetAddreses[i];
            require(targetAddress != address(0),        "NULL_ADDRESS");
            require(ownersSilver[targetAddress] == 0,   "DUPLICATE_ADDRESS");
            ownersSilver[targetAddress] = 1;
        }
    }
    
    function removeFromGoldList(address[] memory _targetAddreses) external onlyOwner{
        for(uint256 i; i < _targetAddreses.length; i++){
            address targetAddress = _targetAddreses[i];
            require(targetAddress != address(0),        "NULL_ADDRESS");
            ownersGold[targetAddress] = 0;
        }
    }
    
    function removeFromSilverList(address[] memory _targetAddreses) external onlyOwner{
        for(uint256 i; i < _targetAddreses.length; i++){
            address targetAddress = _targetAddreses[i];
            require(targetAddress != address(0),        "NULL_ADDRESS");
            ownersSilver[targetAddress] = 0;
        }
    }
    
    function getGoldListAddressValue(address _targetAddreses) external view returns(uint256){
        return ownersGold[_targetAddreses];
    }
    
    function getSilverListAddressValue(address _targetAddreses) external view returns(uint256){
        return ownersSilver[_targetAddreses];
    }
    
    function mintPremintKey(uint256 _keyType) public nonReentrant{
        require(saleLive,                                          "SALE_PAUSED" );
        require(_keyType == 1 || _keyType == 2,                    "KEYTYPE_INVALID");
        require(totalSupply() < maxTokensSilver + maxTokensGold,   "OUT_OF_STOCK");  
        if (_keyType == 1){
            require(ownersSilver[msg.sender] == 1,                 "NO_RIGHTS_FOR_SILVER");
            ownersSilver[msg.sender] = 2;
            counterSilver++;
            require(counterSilver <= maxTokensSilver,              "EXCEED_SILVER");
            _mintSilverKey(msg.sender);
        }
        if (_keyType == 2){
            require(ownersGold[msg.sender] == 1,                   "NO_RIGHTS_FOR_GOLD");
            ownersGold[msg.sender] = 2;
            counterGold++;
            require(counterGold <= maxTokensGold - _goldReserved,  "EXCEED_GOLD");
            _mintGoldKey(msg.sender);
        }
    }
    
    function _mintSilverKey(address _destinationAddress) private{
        tokenIdSilver++;
        require(!_exists(tokenIdSilver), "TOKEN_EXISTS");
        _safeMint(_destinationAddress, tokenIdSilver);
    }
    
    function _mintGoldKey(address _destinationAddress) private{
        tokenIdGold++;
        require(!_exists(tokenIdGold), "TOKEN_EXISTS");
        _safeMint(_destinationAddress, tokenIdGold);
    }
    
    function getPremintKeyType(uint256 _keyId) public pure virtual override returns(uint256) {
        //silver 1-566 = 566    return 1
        //gold 567-666 = 100    return 2
        if (_keyId >= 1 && _keyId <= 566){
            return 1;
        }
        if (_keyId >= 567 && _keyId <= 666){
            return 2;
        }
        return 0;
    }
    
    function walletOfOwner(address _owner) external view virtual override returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for(uint256 i; i < tokenCount; i++){
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }
    
    function giveAway(address _targetAddreses, uint256 _amount) external onlyOwner{
        require(_amount <= _goldReserved,          "EXCEED_GOLD_RESERVED");
        _goldReserved -= _amount;
        counterGoldReserved += _amount;
    
        for(uint256 i; i < _amount; i++){
            _tokenIdGoldReserved += 1;
            require(!_exists(_tokenIdGoldReserved), "TOKEN_EXISTS");
            _safeMint(_targetAddreses, _tokenIdGoldReserved);
        }
    }
    
    function mintLeftTokens(uint256 _numSilver, uint256 _numGold) external onlyOwner{
        require(_numSilver + _numGold <= _reservedPerMint,      "EXCEED_KEY_PER_MINT");

        uint256 maxToMintSilver = counterSilver + _numSilver;
        uint256 maxToMintGold = counterGold + _numGold;
        
        require(maxToMintSilver <= maxTokensSilver,             "EXCEED_SILVER");
        require(maxToMintGold <= maxTokensGold-_goldReserved,   "EXCEED_GOLD");

        while (counterSilver < maxToMintSilver) {
            counterSilver++;
            _mintSilverKey(msg.sender);
        }
        
        while (counterGold < maxToMintGold) {
            counterGold++;
            _mintGoldKey(msg.sender);
        }
    }
    
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "NOT_OWNER_NOR_APPROVED");
        _burn(_tokenId);
    }
    
    function exists(uint256 _tokenId) external view virtual override returns (bool) {
        return _exists(_tokenId);
    }
    
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view virtual override returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }
    
    function setSaleLiveStatus(bool _value) public onlyOwner {
        saleLive = _value;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}