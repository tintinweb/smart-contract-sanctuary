// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract Devour is ERC721Enumerable, Ownable, ReentrancyGuard {
  // Manage minting detail and permission
  bytes32 public merkleRoot;
  uint256 public constant maxShardSupply = 600;
  uint256 public mintPrice = 0.1 ether;
  uint256 public publicMintLimit = 10;
  uint256 public wlMintLimit = 5;
  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;
  mapping (address => uint256) public whitelistMinted;

  // Manage addresses and URI related information
  address public oreClaimAddress;
  address public assemblerAddress;
  string public contractURI;
  string public baseTokenURI;

  // Manage balance and types information
  mapping (address => uint256) public shardBalances;
  mapping (uint256 => uint256) public devourTypes;
  uint256 public totalShardMinted;
  uint256 public totalAssembled;

  // Manage ore related information
  uint256 public orePerShard = 75;
  uint256 public orePerAssembled = 500;
  uint256 public initialOreClaimTimestamp;
  mapping (address => uint256) public lastOreClaimWeekByAddress;
  mapping (address => uint256) private _lastClaimableOreByAddress;

  constructor (
    bytes32 _merkleRoot,
    address _oreClaim,
    string memory _initialContractURI,
    string memory _initialBaseTokenURI
  ) ERC721("Devour", "DEVOUR") {
    merkleRoot = _merkleRoot;
    oreClaimAddress = _oreClaim;
    contractURI = _initialContractURI;
    baseTokenURI = _initialBaseTokenURI;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setAssemblerAddress(address _assembler) external onlyOwner {
    assemblerAddress = _assembler;
  }

  function setMintPrice(uint256 _price) external onlyOwner {
    mintPrice = _price;
  }

  function setWhitelistMintLimit(uint256 _limit) external onlyOwner {
    wlMintLimit = _limit;
  }

  function setPublicMintLimit(uint256 _limit) external onlyOwner {
    publicMintLimit = _limit;
  }

  function setPublicMintEnabled(bool _enabled) external onlyOwner {
    publicMintEnabled = _enabled;
  }

  function setWhitelistMintEnabled(bool _enabled) external onlyOwner {
    whitelistMintEnabled = _enabled;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    contractURI = _contractURI;
  }

  function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");

    // Return the correct metadata for assembled tokens
    if (_tokenId > maxShardSupply) {
      return string(abi.encodePacked(baseTokenURI, Strings.toString(devourTypes[_tokenId] + 1000)));  
    }

    // Otherwise return the shard metadata
    return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
  }

  function reserveMint(uint256 _count) external onlyOwner {
    uint256 currentSupply = totalShardMinted;
    require(currentSupply + _count <= maxShardSupply, "Invalid mint count");

    for (uint256 i = 0; i < _count; i++) {
      _safeMint(msg.sender, currentSupply + i + 1);
    }

    shardBalances[msg.sender] += _count;
    totalShardMinted += _count;
  }

  function whitelistMint(bytes32[] calldata _merkleProof) external payable nonReentrant {
    bytes32 node = keccak256(abi.encodePacked(msg.sender));
    uint256 currentSupply = totalShardMinted;
    uint256 price = mintPrice;

    require(whitelistMintEnabled, "Whitelist mint is closed");
    require(currentSupply < maxShardSupply, "Sold out!");
    require(MerkleProof.verify(_merkleProof, merkleRoot, node), "Not whitelisted");
    require(whitelistMinted[msg.sender] < wlMintLimit, "Whitelist mint fully claimed");
    require(msg.value >= price, "Not enough funds");

    uint256 count = msg.value / price;
    uint256 remaining = maxShardSupply - currentSupply;
    uint256 remainingWL = wlMintLimit - whitelistMinted[msg.sender];
    remaining = (remaining > remainingWL ? remainingWL : remaining);
    count = (count > remaining ? remaining : count);
    whitelistMinted[msg.sender] += count;

    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, currentSupply + i + 1);
    }

    shardBalances[msg.sender] += count;
    totalShardMinted += count;

    uint256 refund = msg.value - (count * price);
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }

  function publicMint() external payable nonReentrant {
    uint256 currentSupply = totalShardMinted;
    uint256 price = mintPrice;

    require(publicMintEnabled, "Public mint is closed");
    require(currentSupply < maxShardSupply, "Sold out!");
    require(msg.value >= price, "Not enough funds");

    uint256 count = msg.value / price;
    uint256 remaining = maxShardSupply - currentSupply;
    count = (count > publicMintLimit ? publicMintLimit : count);
    count = (count > remaining ? remaining : count);

    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, currentSupply + i + 1);
    }

    shardBalances[msg.sender] += count;
    totalShardMinted += count;

    uint256 refund = msg.value - (count * price);
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }

  function assemble(uint256 devourType, uint256[] calldata _tokenIds) external nonReentrant {
    require(assemblerAddress != address(0), "Assembler not set");
    require(msg.sender == assemblerAddress, "Invalid access");
    require(_tokenIds.length == 5, "Invalid token ids");

    address owner = ownerOf(_tokenIds[0]);

    // Make sure to still reward the user with any unclaimed ore before burning
    _updatePendingOre(owner, address(0));

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i]);
    }

    shardBalances[owner] -= 5;
    totalAssembled++;

    // Calculate the next tokenId for the new assembled token and mint it
    uint256 nextAssembledId = maxShardSupply + totalAssembled;
    devourTypes[nextAssembledId] = devourType;
    _safeMint(owner, nextAssembledId);

    // Immediately add the weekly claimable ore for the assembled piece to prevent "lost reward"
    _lastClaimableOreByAddress[owner] += orePerAssembled;
  }

  // Helper method to return both shards and assembled pieces owned by the specified owner/account
  function tokenIdsByOwner(address _owner) external view returns (uint256[] memory, uint256[] memory) {
    uint256 totalOwned = balanceOf(_owner);
    uint256 shardOwned = shardBalances[_owner];
    uint256 assembledOwned = totalOwned - shardOwned;
    uint256[] memory shardIds = new uint256[](shardOwned);
    uint256[] memory assembledIds = new uint256[](assembledOwned);

    uint256 shardIdx = 0;
    uint256 assembledIdx = 0;
    for (uint256 i = 0; i < totalOwned; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
      if (tokenId <= maxShardSupply) {
        shardIds[shardIdx++] = tokenId;
      } else {
        assembledIds[assembledIdx++] = tokenId;
      }
    }

    return (shardIds, assembledIds);
  }

  function _getOreClaimWeek() internal view returns (uint256) {
    uint256 initial = initialOreClaimTimestamp;
    uint256 timestamp = block.timestamp;

    // If ore claiming has not been specified, or if it's in the future, return 0
    if (initial == 0 || timestamp < initial) {
      return 0;
    }

    // Week starts right within the the next 7 days of the initial claim timestamp
    return (timestamp - initial) / 1 weeks + 1;
  }

  function _getPendingClaimable(address _owner) internal view returns (uint256) {
    uint256 week = _getOreClaimWeek();
    uint256 lastClaimedWeek = lastOreClaimWeekByAddress[_owner];

    if (week > lastClaimedWeek) {
      // Calculate the total pending claimable ore based on the shard and assembled token counts
      uint256 elapsed = (week - lastClaimedWeek);
      uint256 shardBalance = shardBalances[_owner];
      uint256 assembledBalance = balanceOf(_owner) - shardBalance;

      return (shardBalance * elapsed * orePerShard) + (assembledBalance * elapsed * orePerAssembled);
    }

    return 0;
  }

  function _updatePendingOre(address _from, address _to) internal {
    uint256 week = _getOreClaimWeek();

    if (_from != address(0)) {
      uint256 pendingOre = _getPendingClaimable(_from);
      if (pendingOre > 0) {
        _lastClaimableOreByAddress[_from] += pendingOre;
        lastOreClaimWeekByAddress[_from] = week;
      }
    }
    if (_to != address(0)) {
      uint256 pendingOre = _getPendingClaimable(_to);
      if (pendingOre > 0) {
        _lastClaimableOreByAddress[_to] += pendingOre;
        lastOreClaimWeekByAddress[_to] = week;
      }
    }
  }

  function _updateShardBalance(address _from, address _to) internal {
    if (_from != address(0)) {
      shardBalances[_from]--;
    }
    if (_to != address(0)) {
      shardBalances[_to]++;
    }
  }

  function setInitialOreClaimTimestamp(uint256 _timestamp) external onlyOwner {
    initialOreClaimTimestamp = _timestamp;
  }

  function claimOre(address _owner) external nonReentrant returns (uint256) {
    require(msg.sender == oreClaimAddress, "Invalid access");
    uint256 totalOre = _lastClaimableOreByAddress[_owner] + _getPendingClaimable(_owner);

    // Update the tracker states only if needed
    if (totalOre > 0) {
      lastOreClaimWeekByAddress[_owner] = _getOreClaimWeek();
      _lastClaimableOreByAddress[_owner] = 0;
    }

    return totalOre;
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public override {
    _updatePendingOre(_from, _to);
    if (_tokenId <= maxShardSupply) {
      _updateShardBalance(_from, _to);
    }

    ERC721.transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
    _updatePendingOre(_from, _to);
    if (_tokenId <= maxShardSupply) {
      _updateShardBalance(_from, _to);
    }

    ERC721.safeTransferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
    _updatePendingOre(_from, _to);
    if (_tokenId <= maxShardSupply) {
      _updateShardBalance(_from, _to);
    }

    ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
  }
}