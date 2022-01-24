// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utilities/UtilityVault.sol";
import "../interfaces/IVault.sol";

contract UTBGiftBox is UtilityVault {
  uint16 public constant STATE_NORMAL = 0;
  uint16 public constant STATE_READY = 1;
  uint16 public constant STATE_SURPRISE = 2;

  function wrap(uint256 tokenId) public onlyTokenOwner(tokenId) onlyState(tokenId, STATE_NORMAL) {
    require(!IVault(vault).isEmpty(tokenId));
    setTokenState(tokenId, STATE_READY);
  }

  function open(uint256 tokenId) external onlyTokenOwner(tokenId) onlyState(tokenId, STATE_READY) {
    setTokenState(tokenId, STATE_SURPRISE);
  }

  function claimDeposits(uint256 tokenId)
    external
    virtual
    override
    onlyTokenOwner(tokenId)
    onlyState(tokenId, STATE_SURPRISE)
  {
    IVault(vault).claimDeposits(tokenId, msg.sender);
    setTokenState(tokenId, STATE_NORMAL);
  }

  function isPublic(uint256 tokenId) public view virtual override returns (bool) {
    return tokenStates[tokenId] != STATE_READY;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UtilityBase.sol";

abstract contract UtilityVault is UtilityBase {
  event StateUpdated(uint256 tokenId, uint16 state);

  mapping(uint256 => uint16) public tokenStates;
  address public vault;

  modifier onlyState(uint256 tokenId, uint16 state) {
    require(tokenStates[tokenId] == state);
    _;
  }

  function setTokenState(uint256 tokenId, uint16 state) internal {
    require(state < states);
    tokenStates[tokenId] = state;
    emit StateUpdated(tokenId, state);
  }

  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  function claimDeposits(uint256 tokenId) external virtual;

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return assetStore().getAsset(tokenAssets[tokenId]).asset[tokenStates[tokenId]];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
  function isEmpty(uint256 tokenId) external view returns (bool);

  function claimDeposits(uint256 tokenId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IFactory.sol";
import "../interfaces/IAssetStore.sol";
import "../interfaces/IERC721.sol";

abstract contract UtilityBase {
  uint16 public constant REGISTER_PERCENT = 500;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event PromoUpdated(string);

  address implementation_;
  address public owner;

  bool public initialized;

  uint256 index;
  uint16 public states;

  IFactory public factory;
  IERC721 public token;
  string public promo;

  uint256[] public assets;
  mapping(uint256 => uint256) public tokenAssets;

  function initialize(
    address _factory,
    address _token,
    uint16 _states,
    string calldata _promo
  ) external {
    require(msg.sender == owner);
    require(!initialized);
    initialized = true;
    factory = IFactory(_factory);
    token = IERC721(_token);
    states = _states;
    promo = _promo;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    require(msg.sender == token.ownerOf(tokenId));
    _;
  }

  function ownerOf(uint256 tokenId) external view returns (address) {
    return token.ownerOf(tokenId);
  }

  function assetStore() internal view returns (IAssetStore) {
    return IAssetStore(factory.store());
  }

  function setIndex(uint256 _index) external {
    require(msg.sender == address(factory));
    index = _index;
  }

  function transferOwnership(address newOwner) external {
    withdraw();
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function updatePromo(string calldata _promo) external onlyOwner {
    promo = _promo;
    emit PromoUpdated(_promo);
  }

  function registerAsset(
    string calldata assetName,
    string calldata assetPromo,
    string[] calldata assetAsset,
    uint256 price,
    uint256 stock
  ) external payable virtual returns (uint256 assetId) {
    require(assetAsset.length == states);
    if (price > 0 && msg.sender != owner) {
      require(msg.value > ((price * stock * REGISTER_PERCENT) / 10000));
    }
    assetId = assetStore().registerAsset(index, assetName, assetPromo, assetAsset, price, stock);
    assets.push(assetId);
  }

  function updateAssetPrice(uint256 assetIndex, uint256 price) external onlyOwner {
    assetStore().updateAssetPrice(assets[assetIndex], price);
  }

  function assetPrice(uint256 assetIndex) public view returns (uint256 price) {
    price = assetStore().getAsset(assets[assetIndex]).price;
  }

  function useAsset(uint256 assetId, uint256 amount) internal returns (uint256 cost) {
    cost = assetStore().useAsset(assetId, amount);
  }

  function totalAssets() external view returns (uint256 total) {
    total = assets.length;
  }

  function mint(uint256 assetIndex, uint256 amount) external payable virtual returns (uint256 end) {
    require(assetIndex < assets.length);
    uint256 assetId = assets[assetIndex];
    require(msg.value >= useAsset(assetId, amount));
    end = token.mint(msg.sender, amount);
    for (uint256 i = 0; i < amount; i++) {
      tokenAssets[end - i] = assetId;
    }
  }

  function tokenURI(uint256) public view virtual returns (string memory);

  function isPublic(uint256) public view virtual returns (bool) {
    return true;
  }

  function withdraw() public onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
  function owner() external view returns (address);

  function treasury() external view returns (address);

  function store() external view returns (address);

  function utilities(uint256) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Asset {
  string name;
  string promo;
  string[] asset;
  address author;
  uint256 price;
  uint256 stock;
}

interface IAssetStore {
  function registerAsset(
    uint256 index,
    string calldata name,
    string calldata promo,
    string[] calldata asset,
    uint256 price,
    uint256 stock
  ) external returns (uint256 assetId);

  function updateAssetPrice(uint256 assetId, uint256 price) external;

  function getAsset(uint256 assetId) external view returns (Asset memory);

  function useAsset(uint256 assetId, uint256 amount) external returns (uint256 cost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function ownerOf(uint256 tokenId) external view returns (address);

  function balanceOf(address user) external view returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function mint(address to, uint256 amount) external returns (uint256);
}