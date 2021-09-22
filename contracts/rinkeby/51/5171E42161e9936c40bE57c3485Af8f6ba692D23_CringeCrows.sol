// SPDX-License-Identifier: GPL-3.0
//made by @apnumen and @redjanedoe
// with help of HashLips tutorial
pragma solidity >=0.7.0 <0.9.0; import "./ERC721Enumerable.sol"; import "./Ownable.sol";
contract CringeCrows is ERC721Enumerable, Ownable {using Strings for uint256;
string public baseURI; string public baseExtension = ".json"; uint256 public cost = 0.04 ether; uint256 public maxSupply = 4567;
uint256 public maxMintAmount = 3; bool public paused = false; mapping(address => bool) public whitelisted;
constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {setBaseURI(_initBaseURI); mint(msg.sender, 30);}
function _baseURI() internal view virtual override returns (string memory) {return baseURI;}
function mint(address _to, uint256 _mintAmount) public payable {uint256 supply = totalSupply(); require(!paused); require(_mintAmount > 0); require(supply + _mintAmount <= maxSupply); if (msg.sender != owner()) { require(_mintAmount <= maxMintAmount);  if(whitelisted[msg.sender] != true) {require(msg.value >= cost * _mintAmount);}}for (uint256 i = 1; i <= _mintAmount; i++) {_safeMint(_to, supply + i);}}
function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
string memory currentBaseURI = _baseURI(); return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)): "";}
function setCost(uint256 _newCost) public onlyOwner() {cost = _newCost;}
function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {maxMintAmount = _newmaxMintAmount;}
function setBaseURI(string memory _newBaseURI) public onlyOwner {baseURI = _newBaseURI;}
function pause(bool _state) public onlyOwner {paused = _state;}
function whitelistUser(address _user) public onlyOwner {whitelisted[_user] = true;}
function removeWhitelistUser(address _user) public onlyOwner {whitelisted[_user] = false;}
function withdraw() public payable onlyOwner {require(payable(msg.sender).send(address(this).balance));}}