// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAPricer {
  function fotaPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGameNFT is IERC721Upgradeable {
  function mintHero(address _owner, uint16 _classId, uint _price, uint _index) external returns (uint);
  function getHero(uint _tokenId) external view returns (string memory, string memory, string memory, uint16, uint, uint8, uint32);
  function getHeroPrices(uint _tokenId) external view returns (uint, uint);
  function getHeroStrength(uint _tokenId) external view returns (uint, uint, uint, uint, uint);
  function mintItem(address _owner, uint8 _gene, uint16 _class, uint _price, uint _index) external returns (uint);
  function getItem(uint _tokenId) external view returns (uint8, uint16, uint, uint, uint);
  function getClassId(uint _tokenId) external view returns (uint16);
  function burn(uint _tokenId) external;
  function getCreator(uint _tokenId) external view returns (address);
  function countId() external view returns (uint16);
  function updateOwnPrice(uint _tokenId, uint _ownPrice) external;
  function updateFailedUpgradingAmount(uint _tokenId, uint _amount) external;
  function skillUp(uint _tokenId, uint8 _index) external;
  function experienceCheckpoint(uint8 _level) external view returns (uint32);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./IGameNFT.sol";

interface IMarketPlace {
  enum OrderType {
    trading,
    renting
  }
  enum OrderKind {
    hero,
    item,
    land
  }
  enum PaymentType {
    fota,
    usd,
    all
  }
  enum PaymentCurrency {
    fota,
    busd,
    usdt
  }
  function fotaToken() external view returns (address);
  function busdToken() external view returns (address);
  function usdtToken() external view returns (address);
  function citizen() external view returns (address);
  function takeOrder(OrderKind _kind, uint _tokenId, PaymentCurrency _paymentCurrency) external;
  function paymentType() external view returns (PaymentType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library MerkleProof {
  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }
    return computedHash == root;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library StringUtil {
  struct slice {
    uint _length;
    uint _pointer;
  }

  function validateUserName(string calldata _username)
  internal
  pure
  returns (bool)
  {
    uint8 len = uint8(bytes(_username).length);
    if ((len < 4) || (len > 21)) return false;

    // only contain A-Z 0-9
    for (uint8 i = 0; i < len; i++) {
      if (
        (uint8(bytes(_username)[i]) < 48) ||
        (uint8(bytes(_username)[i]) > 57 && uint8(bytes(_username)[i]) < 65) ||
        (uint8(bytes(_username)[i]) > 90)
      ) return false;
    }
    // First char != '0'
    return uint8(bytes(_username)[0]) != 48;
  }

  function toBytes24(string memory source)
  internal
  pure
  returns (bytes24 result)
  {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 24))
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../libs/zeppelin/token/BEP20/IBEP20.sol";
import "../interfaces/IGameNFT.sol";
import "../interfaces/IFOTAPricer.sol";
import "../interfaces/IMarketPlace.sol";
import "../libs/fota/Auth.sol";
import "../libs/fota/MerkelProof.sol";
import "../libs/fota/StringUtil.sol";

contract IGO is Auth, PausableUpgradeable {
  using StringUtil for string;
  struct Organization {
    uint id;
    string name;
    bytes32 rootHash;
    uint16[] nftClassIds;
    mapping(uint16 => uint) prices;
    uint8 quantityPerNFT;
    uint8 maxBuyPerUserPerClassId;
  }
  uint public totalOrganizations;
  mapping (uint => Organization) public organizations;
  mapping (bytes24 => bool) private organizationNames;
  mapping(uint => mapping(uint => uint)) private claimedBitMap;

  IBEP20 public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  IFOTAPricer public fotaPricer;
  IMarketPlace.PaymentType public paymentType;
  IGameNFT public itemToken;
  IGameNFT public heroToken;
  uint constant decimal3 = 1000;
  address private fundAdmin;

  event OrganizationAdded(
    uint id,
    string name,
    uint16[] heroes,
    uint[] prices,
    uint8 quantityPerNFT,
    uint8 maxBuyPerUserPerClassId
  );
  event PricesUpdated(uint id, uint[] prices);
  event PaymentTypeChanged(IMarketPlace.PaymentType _newMethod);
  event Claimed(
    address indexed user,
    uint id,
    IMarketPlace.PaymentCurrency paymentCurrency,
    uint16[] nftClassIds,
    uint[] nftIds,
    uint amount
  );

  function initialize(
    address _mainAdmin,
    address _fotaPricer,
    address _itemNFT,
    address _heroNFT
  ) public initializer {
    Auth.initialize(_mainAdmin);
    fundAdmin = _mainAdmin;
    fotaPricer = IFOTAPricer(_fotaPricer);
    itemToken = IGameNFT(_itemNFT);
    heroToken = IGameNFT(_heroNFT);
    fotaToken = IBEP20(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    paymentType = IMarketPlace.PaymentType.usd;
  }

  // ADMIN FUNCTIONS

  function updatePaymentType(IMarketPlace.PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeChanged(_type);
  }

  function addOrganization(
    string calldata _name,
    bytes32 _rootHash,
    uint16[] calldata _nftClassIds,
    uint[] calldata _prices,
    uint8 _quantityPerNFT,
    uint8 _maxBuyPerUserPerClassId
  ) external onlyMainAdmin {
    require(!organizationNames[_name.toBytes24()], "IGO: Organization Name exists");
    require(_nftClassIds.length * uint(_maxBuyPerUserPerClassId) > 0 && uint(_maxBuyPerUserPerClassId) <= _nftClassIds.length, "IGO: max buy per user invalid");
    require(_nftClassIds.length == _prices.length, "IGO: price invalid");
    organizationNames[_name.toBytes24()] = true;
    totalOrganizations += 1;

    organizations[totalOrganizations].id = totalOrganizations;
    organizations[totalOrganizations].name = _name;
    organizations[totalOrganizations].rootHash = _rootHash;
    organizations[totalOrganizations].nftClassIds = _nftClassIds;
    organizations[totalOrganizations].quantityPerNFT = _quantityPerNFT;
    organizations[totalOrganizations].maxBuyPerUserPerClassId = _maxBuyPerUserPerClassId;
    for(uint i = 0; i < _nftClassIds.length; i++) {
      organizations[totalOrganizations].prices[_nftClassIds[i]] = _prices[i];
    }
    emit OrganizationAdded(totalOrganizations, _name, _nftClassIds, _prices, _quantityPerNFT, _maxBuyPerUserPerClassId);
  }

  function updatePrices(uint _id, uint[] calldata _prices) external onlyMainAdmin {
    require(_id <= totalOrganizations, "IGO: id invalid");
    require(organizations[_id].nftClassIds.length == _prices.length, "IGO: price invalid");
    for(uint i = 0; i < organizations[_id].nftClassIds.length; i++) {
      organizations[_id].prices[organizations[_id].nftClassIds[i]] = _prices[i];
    }
    emit PricesUpdated(_id, _prices);
  }

  function updateRootHash(uint _id, bytes32 _rootHash) external onlyMainAdmin {
    require(_id <= totalOrganizations, "IGO: id invalid");
    organizations[_id].rootHash = _rootHash;
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0), "Whitelist: address invalid");
    fundAdmin = _address;
  }

  // PUBLIC FUNCTIONS

  function isClaimed(uint _id, uint _index) public view returns (bool) {
    uint claimedWordIndex = _index / 256;
    uint claimedBitIndex = _index % 256;
    uint claimedWord = claimedBitMap[_id][claimedWordIndex];
    uint mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function claim(uint _id, uint _index, bytes32[] calldata _path, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    require(!isClaimed(_id, _index), 'IGO: Use have already claimed.');
    _setClaimed(_id, _index);

    bytes32 hash = keccak256(abi.encodePacked(msg.sender, _index));
    require(MerkleProof.verify(_path, organizations[_id].rootHash, hash), 'IGO: 400');
    uint16[] memory ids = organizations[_id].nftClassIds;
    bool haveRandom = organizations[_id].maxBuyPerUserPerClassId < organizations[_id].nftClassIds.length;
    if (haveRandom) {
      ids = _shuffle(ids);
      for(uint i = organizations[_id].maxBuyPerUserPerClassId; i < organizations[_id].nftClassIds.length; i++) {
        delete ids[i];
      }
    }
    uint amount = _takeFund(_id, ids, _paymentCurrency);
    (uint16[] memory nftClassIds, uint[] memory nftIds) = _mintNFT(_id, ids);
    emit Claimed(msg.sender, _id, _paymentCurrency, nftClassIds, nftIds, amount);
  }

  function getClassIdsAndPrices(uint _id) external view returns (uint16[] memory, uint[] memory) {
    require(_id <= totalOrganizations, "IGO: id invalid");
    uint[] memory prices = new uint[](organizations[_id].nftClassIds.length);
    for (uint i = 0; i < organizations[_id].nftClassIds.length; i++) {
      prices[i] = organizations[_id].prices[organizations[_id].nftClassIds[i]];
    }
    return (
      organizations[_id].nftClassIds,
      prices
    );
  }

  // PRIVATE FUNCTIONS

  function _setClaimed(uint _id, uint _index) private {
    uint claimedWordIndex = _index / 256;
    uint claimedBitIndex = _index % 256;
    claimedBitMap[_id][claimedWordIndex] = claimedBitMap[_id][claimedWordIndex] | (1 << claimedBitIndex);
  }

  function _shuffle(uint16[] memory _arrayIds) public view returns (uint16[] memory) {
    for (uint16 i = 0; i < _arrayIds.length; i++) {
      uint16 n = i + uint16(
        uint(
          keccak256(
            abi.encodePacked(
              block.timestamp,
              msg.sender
            )
          )
        ) % (_arrayIds.length - i)
      );
      uint16 temp = _arrayIds[n];
      _arrayIds[n] = _arrayIds[i];
      _arrayIds[i] = temp;
    }
    return _arrayIds;
  }

  function _takeFund(uint _id, uint16[] memory _ids, IMarketPlace.PaymentCurrency _paymentCurrency) private returns (uint) {
    uint amount;
    for(uint i = 0; i < _ids.length; i++) {
      amount += organizations[_id].prices[_ids[i]] * organizations[_id].quantityPerNFT;
    }
    if (paymentType == IMarketPlace.PaymentType.fota) {
      amount = amount * decimal3 / fotaPricer.fotaPrice();
      _takeFundFOTA(amount);
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      _takeFundUSD(amount, _paymentCurrency);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      amount = amount * decimal3 / fotaPricer.fotaPrice();
      _takeFundFOTA(amount);
    } else {
      _takeFundUSD(amount, _paymentCurrency);
    }
    return amount;
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "IGO: please approve fota first");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "IGO: insufficient balance");
    require(fotaToken.transferFrom(msg.sender, address(this), _amount), "IGO: transfer fota failed");
    fotaToken.transfer(fundAdmin, fotaToken.balanceOf(address(this)));
  }

  function _takeFundUSD(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    IBEP20 usdToken = _paymentCurrency == IMarketPlace.PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "IGO: please approve usd token first");
    require(usdToken.balanceOf(msg.sender) >= _amount, "IGO: insufficient balance");
    require(usdToken.transferFrom(msg.sender, address(this), _amount), "IGO: transfer usd token failed");
    usdToken.transfer(fundAdmin, usdToken.balanceOf(address(this)));
  }

  function _mintNFT(uint _id, uint16[] memory _ids) private returns (uint16[] memory, uint[] memory){
    uint16[] memory classIds = new uint16[](_ids.length * organizations[_id].quantityPerNFT);
    uint[] memory tokenIds = new uint[](_ids.length * organizations[_id].quantityPerNFT);
    for(uint i = 0; i < _ids.length; i++) {
      uint price = organizations[_id].prices[_ids[i]];
      for (uint j = 0; j < organizations[_id].quantityPerNFT; j++) {
        uint index = i * organizations[_id].quantityPerNFT + j;
        if (_ids[i] > 100) {
          tokenIds[index] = itemToken.mintItem(msg.sender, uint8(_ids[i] / 100), _ids[i], price, index);
          classIds[index] = _ids[i];
        } else if (_ids[i] > 0) {
          tokenIds[index] = heroToken.mintHero(msg.sender, _ids[i], price, index);
          classIds[index] = _ids[i];
        }
      }
    }
    return (classIds, tokenIds);
  }

  // TODO for testing purpose
  function setFOTAToken(address _fotaToken) external onlyMainAdmin {
    fotaToken = IBEP20(_fotaToken);
  }

  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}