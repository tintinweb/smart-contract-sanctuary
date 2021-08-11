//SPDX-License-Identifier: UNLICENSED
// Is ERC721, Ownable, Metadata
pragma solidity ^0.8.0;
contract FinalFantasy7 {
	string private _name = 'Final Fantasy 7';
	string private _symbol = 'FF7';
	address private _owner = msg.sender;
	uint256 _total;
	uint256 fee = 0.02 ether;

	struct Player{uint256 Level; uint256 Strength; uint256 Magic;  
		uint256 Vitality; uint256 Spirit; uint256 Luck; uint256 Speed; string nameOf;}

		Player[] public players;

	mapping(uint256 => string) private _tokenURIs;
	mapping(uint256 => address) private _owners;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event CreatePlayer(address indexed owner, uint256 Level, uint256 Strength, uint256 Magic,  
		uint256 Vitality, uint256 Spirit, uint256 Luck, uint256 Speed);

	constructor() {
		_setOwner(msg.sender);
	}

	function onERC721Received(address, address, uint256, bytes calldata) public pure returns(bytes4) {
		return bytes4(keccak256('onERC721Received(address,address,uint256,bytes'));
	}
	function name() public view returns(string memory) {
		return _name;
	}
	function symbol() public view returns(string memory) {
		return _symbol;									
	}																			
	function tokenURI(uint256 tokenId) public view returns(string memory) {
		return _tokenURIs[tokenId];
	}
	function balanceOf(address owner) public view returns(uint256) {
		return _balances[owner];
	}
	function isOwner() public view returns(address) {
		return _owner;
	}	
	modifier onlyOwner() {
		require(isOwner() == msg.sender, 'Problem is not the owner');
		_;
	}			
	function renounceOwnership() public onlyOwner {
		_setOwner(address(0));
	}						
	function transferOwnership(address newOwner) public view onlyOwner {
		require(newOwner != address(0), 'Problem is zero address');
	}	
	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}				
	function ownerOf(uint256 tokenId) public view returns(address) {
		return _owners[tokenId];
	}
	function safeTransferFrom(address from, address to, uint256 tokenId) public {
		transferFrom(from, to, tokenId);
	}
	function transferFrom(address from, address to, uint256 tokenId) public {
		require(ownerOf(tokenId) == from, 'Problem is you are not owner');
		approve(address(0), tokenId);
		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(from, to, tokenId);
	}
	function approve(address to, uint256 tokenId) public {
		address owner = ownerOf(tokenId);
		require(to != owner, 'Problem is your the owner');
		require(msg.sender == owner || isApprovedForAll(ownerOf(tokenId), msg.sender), 'Problem is your not approved or owner');
		_tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
	}
	function setApprovalForAll(address operator, bool approved) public {
		require(operator != msg.sender);
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator,approved);
	}
	function getApproved(uint256 tokenId) public view returns(address) {
		return _tokenApprovals[tokenId];
	}
	function isApprovedForAll(address owner, address operator) public view returns(bool) {
		return _operatorApprovals[owner][operator];
	}
	function exists(uint256 tokenId) internal view returns(bool) {
		return _owners[tokenId] != address(0);
	}
	function mint(address to, uint256 tokenId) internal {
		require(to != address(0), 'Problem minting to zero address');
		require(!exists(tokenId), 'Problem already minted');
		_balances[to] += 1;
		_owners[tokenId] = to;
		emit Transfer(address(0), to, tokenId);
	}
	function burn(uint256 tokenId) internal {
		address owner = ownerOf(tokenId);
		approve(address(0), tokenId);
		_balances[owner] -= 1;
		delete _owners[tokenId];
		emit Transfer(owner, address(0), tokenId);
	}

	// NONE NFT STANDARD FUNCTIONS

	function rNumber(uint256 mod) internal view returns(uint256) {
		uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
		return randomNum % mod;
	}
	function updateFee(uint256 _fee) external onlyOwner() {
		fee = _fee;
	}
	function withdraw() public payable onlyOwner() {
		address payable owner_ = payable(isOwner());
		owner_.transfer(address(this).balance);
	}
	function buildPlayer(string memory nameOf) internal {
		uint256 rLevel = rNumber(50);
		uint256 rStrength = rNumber(999);
		uint256 rMagic = rNumber(999);
		uint256 rVitality = rNumber(999);
		uint256 rSpirit = rNumber(999);
		uint256 rLuck = rNumber(999);
		uint256 rSpeed = rNumber(999);
		Player memory addPlayer = Player(rLevel, rStrength, rMagic, rVitality, rSpirit, rLuck, rSpeed, nameOf);
		players.push(addPlayer);
		mint(msg.sender, _total);
		emit CreatePlayer(msg.sender, rLevel, rStrength, rMagic, rVitality, rSpirit, rLuck, rSpeed);
		_total++;
	}
	function cost(string memory nameOf) public payable {
		require(msg.value >= fee);
		buildPlayer(nameOf);
	}
	function obtainPlayer() public view returns (Player[] memory) {
		return players;
	}
	function obtainOwnerPlayers(address owner_) public view returns(Player[] memory) {
		Player[] memory result = new Player[](balanceOf(owner_));
		uint256 total = 0;
		for(uint256 i = 0; i < players.length; i++) {
			if(ownerOf(i) == owner_) {
				result[total] = players[i];
				total++;
			}
		}
		return result;
	}
	function levelIncrease(uint256 playerId) public {
		require(ownerOf(playerId) == msg.sender);
		Player storage player = players[playerId];
		player.Level++;
	}
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}