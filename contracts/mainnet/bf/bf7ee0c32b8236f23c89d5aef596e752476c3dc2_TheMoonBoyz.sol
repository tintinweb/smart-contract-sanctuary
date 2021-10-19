// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";

contract TheMoonBoyz is ERC721, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Address for address;
    
    Counters.Counter private _tokenIdCounter;
    
    uint256 public maxMoonBoyzSupply = 10000;
    
    bool public claimableSale = false;
    bool public regularSale = false;
    
    bool private revealed = false;
    
    address[] private _team = [
        0xB8467cB9d289B9c83D36D1bB63666d78C8E06DC7
        ];
    
    uint256[] private _teamShares = [
        100
        ];
    
    uint public mintPrice;
    
    mapping (uint256 => string) private _tokenURIs;
    string public baseURI;
    
    mapping(address => uint256) public totalClaimable;
    mapping(address => uint256) public totalClaimed;
    address[] public claimers;
    
    uint private iOwner = 1;
    uint public maxPerTransaction = 10;
    
    constructor(uint _mintPrice) ERC721("The Moon Boyz", "MOONBOYZ") PaymentSplitter(_team, _teamShares) {
        //SET MINT PRICE
        mintPrice = _mintPrice;
        _tokenIdCounter.increment();
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        string memory base = _baseURI();
        if(!revealed){
            return bytes(base).length > 0 ? string(abi.encodePacked(base)) : "";
        }
        return bytes(base).length > 0 ? string(abi.encodePacked(base, uint2str(tokenId))) : "";
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
  	function setTotalSupply(uint _totalSupply) public onlyOwner{
  	    maxMoonBoyzSupply = _totalSupply;
  	}
  	
    function claim(uint _claimCount) public payable {
        require(claimableSale == true, "Claiming Not Active");
        uint sent = msg.value;
        require(sent == mintPrice * _claimCount, "Did not send required eth");
        require(_claimCount > 0 && _claimCount <= totalClaimable[msg.sender], "You are not eligible to claim this many tokens");
        //ADD USER TO ARRAY
        claimers.push(msg.sender);
        //ADD USER CLAIMED
        totalClaimed[msg.sender] += _claimCount;
        //REDUCE USER CLAIMABLE
        totalClaimable[msg.sender] -= _claimCount;
    }
    
    function airdrop(uint _from, uint _to) public onlyOwner {
        for(uint i = _from; i < _to && i < claimers.length; i++){
            require(_tokenIdCounter.current() <= (maxMoonBoyzSupply +1), "At Max Supply");
            
            for(uint j = 0; j < totalClaimed[claimers[i]]; j++){
                uint256 _tokenID = _tokenIdCounter.current();
                
                //REQUIRE TOKEN DOESNT EXIST
                require(!super._exists(_tokenID), "Token ID Exists");
                
                //MINT TO CLAIMERS ADDRESS
                _safeMint(claimers[i], _tokenID);
                _tokenIdCounter.increment();
            }
            totalClaimed[claimers[i]] = 0;
        }
    }
    
    function regularSaleMint(uint _count) public payable {
        require(regularSale == true, "Normal Sale Not Active");
        require(_count <= maxPerTransaction, "Over maxPerTransaction");
        require(msg.value == mintPrice * _count, "Insuffcient Amount Sent");
        
        require(_tokenIdCounter.current() <= (maxMoonBoyzSupply +1), "At Max Supply");
        
        
        for(uint i = 0; i < _count; i++){
            uint256 _tokenID = _tokenIdCounter.current();
            require(!super._exists(_tokenID), "Token ID Exists");
            _safeMint(msg.sender, _tokenID);
            _tokenIdCounter.increment();
        }
    }
    function ownerMint(uint _count)public onlyOwner {
        require(_tokenIdCounter.current() + _count <= (maxMoonBoyzSupply +1), "TOO MANY MOON BOYZ");
        for(uint i = 0; i < _count; i++){
            uint256 _tokenID = _tokenIdCounter.current();
            require(!super._exists(_tokenID), "Token ID Exists");
            require(_tokenIdCounter.current() <= (maxMoonBoyzSupply +1), "At Max Supply");
            _safeMint(msg.sender, _tokenID);
            _tokenIdCounter.increment();
        }
    }
   
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }
    
    function flipClaimableSale() public onlyOwner {
        claimableSale = !claimableSale;
    }
    
    function flipRevealed() public onlyOwner {
        revealed = !revealed;
    }
    
    function flipRegularSale() public onlyOwner {
        regularSale = !regularSale;
    }
    
    
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }
    
    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }
    
    function getClaimers() public view returns(address[] memory){
        return claimers;
    }
    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}