// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utilities/UtilityVault.sol";
import "../interfaces/IVaultV2.sol";

contract UTBMysteryBox is UtilityVault {
  uint16 public constant STATE_NORMAL = 0;
  uint16 public constant STATE_READY = 1;
  uint16 public constant STATE_SURPRISE = 2;

  uint16 public constant MAX_MINT = 10;

  struct Package {
    uint256 prize;
    uint256 stock;
  }

  struct Company {
    address owner;
    address treasury;
    string promo;
    string link;
    address token;
    uint256 totalPrize;
  }

  mapping(uint256 => Company) public companies;
  mapping(uint256 => Package[]) public packages;
  mapping(uint256 => uint256) distributes;
  mapping(uint256 => bool) public withdrawn;
  mapping(address => bool) public whitelists;

  uint256 private seed;

  function addWhitelist(address whitelist, bool state) external onlyOwner {
    whitelists[whitelist] = state;
    seed = uint256(keccak256(abi.encodePacked(block.timestamp, seed, whitelist)));
  }

  function registerAsset(
    string calldata,
    string calldata,
    string[] calldata,
    uint256,
    uint256
  ) external payable virtual override returns (uint256) {
    require(false);
    return 0;
  }

  function registerCompanyAsset(
    string memory name,
    string memory promo,
    string[] memory asset,
    uint256[] memory price,
    address treasury,
    string[] memory company,
    address token,
    uint256[] memory prizes
  ) external payable {
    require(prizes.length % 2 == 0);
    if (msg.sender != owner && !whitelists[msg.sender]) {
      require(msg.value >= (price[0] * price[1] * REGISTER_PERCENT) / 10000);
    }

    uint256 assetId = assetStore().registerAsset(index, name, promo, asset, price[0], price[1]);
    assets.push(assetId);

    uint256 totalPrize;
    for (uint256 i = 0; i < prizes.length; i += 2) {
      packages[assetId].push(Package(prizes[i], prizes[i + 1]));
      totalPrize += prizes[i] * prizes[i + 1];
    }

    IERC20(token).transferFrom(msg.sender, vault, totalPrize);
    companies[assetId] = Company(msg.sender, treasury, company[0], company[1], token, totalPrize);
  }

  function withdrawCompanyAsset(uint256 companyId) external {
    require(companies[companyId].owner == msg.sender);
    uint256 totalPrize = companies[companyId].totalPrize;
    uint256 distributed = distributes[companyId];
    require(totalPrize > distributed);
    IVaultV2(vault).withdrawERC20(msg.sender, companies[companyId].token, totalPrize - distributed);
    distributes[companyId] = totalPrize;
    withdrawn[companyId] = true;
  }

  function getRandomPrize(uint256 companyId, uint256 totalLeft) internal returns (uint256) {
    seed = uint256(keccak256(abi.encodePacked(seed, totalLeft)));
    uint256 rand = totalLeft - (seed % totalLeft);
    Package[] memory companyPackages = packages[companyId];
    uint256 count;
    for (uint256 i = 0; i < companyPackages.length; i++) {
      count += companyPackages[i].stock;
      if (rand <= count) {
        packages[companyId][i].stock -= 1;
        return companyPackages[i].prize;
      }
    }
    return 0;
  }

  function mint(uint256 assetIndex, uint256 amount) external payable virtual override returns (uint256 end) {
    require(assetIndex < assets.length);
    uint256 assetId = assets[assetIndex];
    require(!withdrawn[assetId]);

    Company memory company = companies[assetId];
    require(amount <= MAX_MINT);

    Asset memory asset = assetStore().getAsset(assetId);

    uint256 distributed = distributes[assetId];
    uint256 left = asset.stock;
    address dToken = company.token;

    require(msg.value >= useAsset(assetId, amount));

    end = token.mint(msg.sender, amount);

    for (uint256 i = 0; i < amount; i++) {
      uint256 tokenId = end - i;
      uint256 distribute = getRandomPrize(assetId, left - i);
      if (distribute > 0) {
        distributed += distribute;
        IVaultV2(vault).registerERC20(tokenId, dToken, distribute);
        setTokenState(tokenId, STATE_READY);
      }
      tokenAssets[tokenId] = assetId;
    }

    require(distributed <= company.totalPrize);
    distributes[assetId] = distributed;

    payable(company.treasury).transfer(msg.value);
  }

  function tokensByState(address user, uint16 state) external view returns (uint256[] memory) {
    uint256 tokenCount = token.balanceOf(user);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = token.tokenOfOwnerByIndex(user, index);
      if (tokenStates[tokenId] == state) {
        tokenIds[index] = tokenId;
      }
    }
    return tokenIds;
  }

  function opens(uint256[] memory tokenIds) external {
    for (uint256 index = 0; index < tokenIds.length; index++) {
      uint256 tokenId = tokenIds[index];
      require(tokenStates[tokenId] == STATE_READY);
      require(token.ownerOf(tokenId) == msg.sender);
      setTokenState(tokenId, STATE_SURPRISE);
    }
  }

  function openAll() external {
    address user = msg.sender;
    uint256 tokenCount = token.balanceOf(user);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = token.tokenOfOwnerByIndex(user, index);
      if (tokenStates[tokenId] == STATE_READY) {
        setTokenState(tokenId, STATE_SURPRISE);
      }
    }
  }

  function claimAll() external {
    address user = msg.sender;
    uint256 tokenCount = token.balanceOf(user);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = token.tokenOfOwnerByIndex(user, index);
      if (tokenStates[tokenId] == STATE_SURPRISE) {
        IVaultV2(vault).claimDeposits(tokenId, user);
        setTokenState(tokenId, STATE_NORMAL);
      }
    }
  }

  function wrap(uint256 tokenId) public onlyTokenOwner(tokenId) onlyState(tokenId, STATE_NORMAL) {
    require(!IVaultV2(vault).isEmpty(tokenId));
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
    IVaultV2(vault).claimDeposits(tokenId, msg.sender);
    setTokenState(tokenId, STATE_NORMAL);
  }

  function isPublic(uint256 tokenId) public view virtual override returns (bool) {
    return tokenStates[tokenId] != STATE_READY;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IVaultV2 {
  function isEmpty(uint256 tokenId) external view returns (bool);

  function claimDeposits(uint256 tokenId, address to) external;

  function registerERC20(
    uint256 tokenId,
    address token,
    uint256 amount
  ) external;

  function withdrawERC20(
    address to,
    address token,
    uint256 amount
  ) external;
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