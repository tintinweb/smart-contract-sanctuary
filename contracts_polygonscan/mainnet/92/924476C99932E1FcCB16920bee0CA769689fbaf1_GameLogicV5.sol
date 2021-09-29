// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./meta/EIP712MetaTransaction.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./interfaces/IAssets.sol";
import "./Constants.sol";

import "hardhat/console.sol";

contract Assets is IAssets, ERC1155, Ownable, EIP712MetaTransaction {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.UintSet;

  uint8 constant internal _vers = 1;

  IAssets immutable public deprecatedAssets; 

  bytes32[] private _assetNames;
  uint256[] private _minIDs;

  // registry containing fungible / non-fungible tokens
  // fungible tokens have minID == totalSupply
  // nfts have a range of IDs, specified via totalSupply 
  struct AssetType {
    bool    isNFT;
    uint256 minID;
    uint256 totalSupply;
    uint256 currentSupply;
    mapping (address => bool) operators;
  }
  
  mapping(bytes32 => AssetType) private _assets;

  mapping (address => EnumerableSet.UintSet) private _accountTokens;

  constructor(address oldAssets) public ERC1155("/1155/{id}.json") EIP712MetaTransaction("Assets", "1")  {
    deprecatedAssets = IAssets(oldAssets);
  }

  function register(
    bytes32 name,
    bool    isNFT,
    uint256 totalSupply,
    address[] memory operators
  ) public onlyOwner {
    require(totalSupply > 0, "total supply must be greater than 0");

    uint256 minID;
    if (_assetNames.length == 0) {
      minID = 0;
    } else {
      require(_assets[name].totalSupply == 0, "asset name already taken");
      // get maxID of last asset, and add 1
      minID = _maxID(_assets[_assetNames[_assetNames.length - 1]]) + 1;
    }

    AssetType storage asset = _assets[name];
    asset.isNFT = isNFT;
    asset.minID = minID;
    asset.totalSupply = totalSupply;
    asset.currentSupply = 0;

    for (uint i = 0; i < operators.length; i++) {
      asset.operators[operators[i]] = true;
    }
    if (operators.length == 0) {
      asset.operators[msgSender()] = true;
    }

    require(_maxID(asset) < type(uint256).max, "out of ids");

    _assetNames.push(name);
    _minIDs.push(minID);
  }

  function registerAssetContract(
    address contractAddress
  ) public onlyOwner {
    IRegisterableAsset asset = IRegisterableAsset(contractAddress);
    register(
      asset.assetName(),
      asset.assetIsNFT(),
      asset.assetTotalSupply(),
      asset.assetOperators()
    );
  }

  function addOperator(address operator_, bytes32 name) external returns (bool) {
    AssetType storage asset = _assets[name];
    require(asset.operators[msgSender()], "Assets: Not authorized to add");
    asset.operators[operator_] = true;
    return true;
  }

  function removeOperator(address operator_, bytes32 name) external returns (bool) {
    AssetType storage asset = _assets[name];
    require(asset.operators[msgSender()], "Assets: Not authorized to add");
    delete asset.operators[operator_];
    return true;
  }

  function mint(
    address account,
    bytes32 name,
    uint256 amount,
    bytes memory data
  ) override external returns(uint256[] memory) {
    AssetType storage asset = _assets[name];
    require(asset.operators[msgSender()], "Assets: Not authorized to mint");
    require((asset.currentSupply + amount) <= asset.totalSupply, "Assets: Token supply exhausted");

    uint256[] memory mintedIDs;

    if (asset.isNFT) {
      mintedIDs = new uint256[](amount);
      for (uint i; i < amount; i++) {
        _mint(account, asset.minID + asset.currentSupply + i, 1, data);
        mintedIDs[i] = asset.minID + asset.currentSupply + i;
      }
    } else {
      mintedIDs = new uint256[](1);
      mintedIDs[0] = asset.minID;
      _mint(account, asset.minID, amount, data);
    }

    asset.currentSupply = asset.currentSupply + amount;
    return mintedIDs;
  }

  /**
  This function is for assets like equipment where it's kind of an NFT and kind of a fungible
  ie: it's an NFT (there's only 1 contract), but there can be more than one of a type
  something like "5 swords" but we don't want to deploy a new contract per Equipment 
  */
  function forge(
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) override external returns (bool) {
    bytes32 name = nameForID(id);
    AssetType storage asset = _assets[name];
    require(asset.operators[msgSender()], "Assets: Not authorized to forge");
    _mint(account, id, amount, data);
    return true;
  }
  
  function burn(
    address account,
    bytes32 name,
    uint256 amount
  ) override external {
    AssetType storage asset = _assets[name];
    require(asset.isNFT == false, "cannot burn NFTs");
    require(
      isApprovedOrOwner(account, msgSender(), asset.minID),
      "Assets: caller is not owner nor approved"
    );
    _burn(account, asset.minID, amount);
    asset.currentSupply = asset.currentSupply - amount;
  }

  function isOwner(
    address account,
    uint256 id
  ) override public view returns (bool) {
    return balanceOf(account, id) > 0;
  }

  function isApprovedOrOwner(
    address account,
    address operator,
    uint256 id
  ) override public view returns (bool) {
    return isApprovedForAll(account, operator) || ( account == operator && isOwner(account, id) );
  }

  // given an ID inside a minted range, return the type name
  function nameForID(
    uint256 id
  ) override public view returns (bytes32) {
    uint256 lastIndex = _minIDs.length - 1;
    for (uint256 i = 0; i <= lastIndex; i++) {
      if (i == lastIndex) {
        AssetType storage lastAsset = _assets[_assetNames[i]];
        if (id <= _maxID(lastAsset)) {
          return _assetNames[i];
        }
      } else if(_minIDs[i] <= id && id < _minIDs[i + 1]) {
        return _assetNames[i];
      }
    }
  }

  function idRange(
    bytes32 name
  ) override public view returns (uint256, uint256) {
    AssetType storage asset = _assets[name];
    if (asset.isNFT) {
      return (asset.minID, asset.minID + asset.totalSupply - 1);
    }
    return (asset.minID, asset.minID);
  }

  // has the token of name been minted
  function exists(
    bytes32 name,
    uint256 id
  ) override public view returns (bool) {
    AssetType storage asset = _assets[name];
    if (!asset.isNFT) {
      return asset.minID == id && asset.currentSupply > 0;
    }
    return asset.minID <= id && id < (asset.minID + asset.currentSupply);
  }

  function totalSupply(
    bytes32 name
  ) override external view returns (uint256) {
    return _assets[name].totalSupply;
  }

  function currentSupply(
    bytes32 name
  ) override external view returns (uint256) {
    return _assets[name].currentSupply;
  }

  function accountTokens(
    address account
  ) override public view returns (uint256[] memory) {
    uint256 tokenCount = _accountTokens[account].length(); 
    uint256[] memory ids = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ids[i] = _accountTokens[account].at(i);
    }
    return ids;
  }

  function _msgSender() internal view override(Context,EIP712MetaTransaction) returns (address payable) {
    return EIP712MetaTransaction.msgSender();
  }

  function _maxID(
    AssetType storage asset
  ) internal view returns(uint256) {
    if (asset.isNFT == false) {
      return asset.minID;
    }
    return asset.minID + asset.totalSupply - 1;
  }

  function _beforeTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  ) internal override {
    for (uint256 i = 0; i < ids.length; i++) {
      if (from != address(0) && (balanceOf(from, ids[i]) - amounts[i]) <= 0) {
        _accountTokens[from].remove(ids[i]);
      }
      if (to != address(0)) {
        _accountTokens[to].add(ids[i]);
      }
    }
  }

  function onERC1155Received(
    address,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata
  ) external returns(bytes4) {
    require(msg.sender == address(deprecatedAssets), "Assets#onERC1155Received: invalid old asset address");
    (uint prestigeStart, uint prestigeEnd) = deprecatedAssets.idRange(Constants.PRESTIGE_ASSET_NAME);
    require(id >= prestigeStart && id <= prestigeEnd, "Assets#Only supports prestige migration");
    
    AssetType storage prestige = _assets[Constants.PRESTIGE_ASSET_NAME];

    _mint(from, prestige.minID, value, '');
    
    return IERC1155Receiver.onERC1155Received.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../GSN/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// imported from https://github.com/bcnmy/metatx-standard/blob/8a6564b8fac5d2aceebb1972bcffdd5e88ceec63/src/contracts/EIP712MetaTransaction.sol
// modified to support solidity 0.7
pragma solidity 0.7.4;

import "./EIP712Base.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) public EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msgSender();
    }

    function msgSender() internal view returns(address payable sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IRegisterableAsset {
  function assetName() external view returns (bytes32);
  function assetTotalSupply() external pure returns (uint256);
  function assetIsNFT() external pure returns (bool);
  function assetOperators() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAssets is IERC1155 {
  function mint(
    address account,
    bytes32 name,
    uint256 amount,
    bytes memory data
  ) external returns(uint256[] memory);
  
  function forge(
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) external returns (bool);

  function burn(
    address account,
    bytes32 name,
    uint256 amount
  ) external;

  function isOwner(
    address account,
    uint256 id
  ) external view returns(bool);

  function isApprovedOrOwner(
    address account,
    address operator,
    uint256 id
  ) external view returns(bool);

  function nameForID(
    uint256 id
  ) external view returns(bytes32);

  function idRange(
    bytes32 name
  ) external view returns (uint256, uint256);

  function exists(
    bytes32 name,
    uint256 id
  ) external view returns (bool);

  function totalSupply(
    bytes32 name
  ) external view returns (uint256);

  function currentSupply(
    bytes32 name
  ) external view returns (uint256);

  function accountTokens(
    address account
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

library Constants {
  bytes32 constant PRESTIGE_ASSET_NAME = "prestige";

  function prestigeAssetName() internal pure returns(bytes32){
    return PRESTIGE_ASSET_NAME;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

pragma solidity 0.7.4;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    bytes32 internal domainSeperator;

    constructor(string memory name, string memory version) public {
        domainSeperator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            getChainID(),
            address(this)
        ));
    }

    function getChainID() internal pure returns (uint256 id) {
        return 1;
        // if you want to use the chainId specified by deployment uncomment out below:
        // assembly {
        //     id := chainid()
        // }
    }

    function getDomainSeperator() private view returns(bytes32) {
        return domainSeperator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Assets.sol";
import "./TrophyV5.sol";
import "./Gladiator.sol";
import "./Constants.sol";
import "./interfaces/IDiceRollsV5.sol";
import "./interfaces/IDiceRolls.sol";
import "./interfaces/IGameLogicV4.sol";
import "./interfaces/ITournamentV5.sol";

import "hardhat/console.sol";

contract TournamentV5 is
    ITournamentV5,
    AccessControl
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter public nextTournamentId;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    bytes32 constant ASSET_NAME = "TournamentV5";

    mapping(uint256 => TournamentDataV5) public _tournaments;

    Gladiator private immutable _gladiator;
    TrophyV5 public immutable trophies;

    bytes32 private immutable _gladiatorAssetName;

    constructor(address _assetsAddress, address _gladiatorAddress, address _trophyAddress) {
        require(
            _assetsAddress != address(0),
            "Tournament#constructor: INVALID_INPUT _assetsAddress is 0"
        );
        _gladiator = Gladiator(_gladiatorAddress);
        trophies = TrophyV5(_trophyAddress);
        _gladiatorAssetName = Gladiator(_gladiatorAddress).assetName();
        _setupRole(CREATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function newTournament(
        string memory name,
        address gameLogic_,
        address roller_,
        uint8 totalRounds,
        uint256 notBefore,
        int256 maxFactionBonus,
        string[] memory factions
    ) public returns (uint256) {
        require(hasRole(CREATOR_ROLE, msg.sender), "Caller is not a creator");

        require(
            factions.length <= 65536,
            "Tournament#newTournament: Can only have 65536 factions"
        );

        address creator = _msgSender();
        nextTournamentId.increment();
        uint256 tournamentId = nextTournamentId.current();

        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        tournament.name = name;
        tournament.creator = creator;
        tournament.totalRounds = totalRounds;
        tournament.factions = factions;
        tournament.gameLogic = gameLogic_;
        tournament.notBefore = notBefore;
        tournament.roller = roller_;
        tournament.maxFactionBonus = maxFactionBonus;
        emit NewTournament(creator, notBefore, tournamentId);
        return tournamentId;
    }

    function registerGladiator(TournamentDataV5 storage tournament, uint tournamentId, uint id, uint16 faction) internal {
        require(
            faction < tournament.factions.length,
            "Tournament#onERC1155BatchReceived: faction does not exist"
        );
        require(_gladiator.exists(id), "Tournament#Not a gladiator");

        tournament.registrations.push(
            Registration({gladiator: id, faction: faction})
        );
        emit RegistrationEvent(
            tournamentId,
            id,
            faction,
            tournament.registrations.length - 1
        );
    }

    function registerGladiators(uint tournamentId, uint[] calldata ids, uint16[] calldata factions) public {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        require(tournament.creator == _msgSender(), "Tournament#regGlad: can only register to tournaments you have created");

        require(
            tournament.totalRounds > 0,
            "Tournament#onERC1155BatchReceived: tournament does not exist"
        );
        require(
            !started(tournamentId),
            "Tournament#onERC1155BatchReceived: tournament already started"
        );
        require(
            tournament.registrations.length + ids.length <= this.maxGladiators(tournamentId),
            "Tournament#onERC1155BatchReceived: registration closed"
        );

        for (uint i; i < ids.length; i++) {
            registerGladiator(tournament, tournamentId, ids[i], factions[i]);
        }
    }

    function name(uint256 tournamentId) external view returns (string memory) {
        return _tournaments[tournamentId].name;
    }

    function maxFactionBonus(uint256 tournamentId) external view override returns (int256) {
        return _tournaments[tournamentId].maxFactionBonus;
    }

    function firstRoll(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].firstRoll;
    }

    function notBefore(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].notBefore;
    }

    function lastRoll(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].lastRoll;
    }

    function rollerV5(uint256 tournamentId)
        external
        view
        override
        returns (address)
    {
        return _tournaments[tournamentId].roller;
    }

    function roller(uint256 tournamentId)
        external
        view
        override
        returns (IDiceRolls)
    {
        revert('roller is not supported in v5');
    }

    function started(uint256 tournamentId) public override view returns (bool) {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        // console.log('first role', tournament.firstRoll, 'latest', latest);
        uint256 _firstRoll = tournament.firstRoll;
        return _firstRoll > 0 && _firstRoll <= IDiceRollsV5(tournament.roller).latest();
    }

    function totalRounds(uint256 tournamentId) external view returns (uint256) {
        return _tournaments[tournamentId].totalRounds;
    }

    function maxGladiators(uint256 tournamentId)
        external
        view
        returns (uint256)
    {
        return 2**uint256(_tournaments[tournamentId].totalRounds);
    }

    function registrationCount(uint256 tournamentId)
        external
        view
        returns (uint256)
    {
        return _tournaments[tournamentId].registrations.length;
    }

    function registration(uint256 tournamentId, uint256 registrationId)
        external
        view
        returns (Registration memory)
    {
        return _tournaments[tournamentId].registrations[registrationId];
    }

    function registrations(uint256 tournamentId)
        external
        view
        override
        returns (Registration[] memory)
    {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        return tournament.registrations;
    }

    function factions(uint256 tournamentId)
        external
        view
        override
        returns (string[] memory)
    {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        return tournament.factions;
    }

    function start(uint256 tournamentId) external {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        require(
            block.timestamp > tournament.notBefore,
            "Tournament cannot start yet"
        );
        require(
            !started(tournamentId),
            "Tournament#start: already started"
        );
        tournament.firstRoll = IDiceRollsV5(tournament.roller).latest().add(1);
    }

    function checkpoint(uint256 tournamentId) external {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];

        (uint256 winner, uint256 tournamentLastRoll) =
            IGameLogicV4(tournament.gameLogic).tournamentWinner(tournamentId);

        tournament.lastRoll = tournamentLastRoll;

        createTrophy(tournamentId, tournament, winner);
    }

    function createTrophy(
        uint256 tournamentId,
        TournamentDataV5 storage tournament,
        uint256 winnerId
    ) internal {
        Registration memory winner = tournament.registrations[winnerId];

        uint256 trophyId =
            trophies.mint(
                address(_gladiator),
                tournament.name,
                tournamentId,
                winner.gladiator
            );

        tournament.champion.faction = winner.faction;
        tournament.champion.gladiator = winner.gladiator;
        tournament.champion.trophy = trophyId;

        emit TournamentComplete(tournamentId, winner.gladiator);
    }

    function getChampion(uint256 tournamentId)
        public
        view
        returns (Champion memory)
    {
        TournamentDataV5 storage tournament = _tournaments[tournamentId];
        require(tournament.lastRoll > 0, "Tournament is still in progress");
        return tournament.champion;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./EnumerableMap.sol";
import "hardhat/console.sol";

contract TrophyV5 is AccessControl, IRegisterableAsset {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.Map;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 immutable ASSET_NAME = "TrophyV5";
    uint256 constant TOTAL_SUPPLY = 2**20;

    IAssets public immutable assets;

    struct Metadata {
        string name;
        EnumerableMap.Map properties;
    }

    mapping(uint256 => Metadata) private _metadata;

    constructor(address assetsAddress) public {
        assets = IAssets(assetsAddress);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function assetName() public view override returns (bytes32) {
        return ASSET_NAME;
    }

    function assetTotalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function assetIsNFT() public pure override returns (bool) {
        return true;
    }

    function assetOperators() public view override returns (address[] memory) {
        address[] memory operators = new address[](1);
        operators[0] = address(this);
        return operators;
    }

    function idRange() public view returns (uint256, uint256) {
        return assets.idRange(ASSET_NAME);
    }

    function mint(
        address account,
        string memory name,
        uint256 tournamentID,
        uint256 gladiatorID
    ) external returns (uint256) {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");

        uint256[] memory ids = assets.mint(
            account,
            ASSET_NAME,
            1,
            abi.encodePacked(gladiatorID)
        );
        uint256 id = ids[0];

        Metadata storage metadata = _metadata[id];
        metadata.name = name;

        EnumerableMap.Map storage _properties = metadata.properties;

        _properties.set("tournamentID", bytes32(tournamentID));
        _properties.set("gladiatorID", bytes32(gladiatorID));
        _properties.set("createdAt", bytes32(block.timestamp));

        return id;
    }

    function exists(uint256 id) external view returns (bool) {
        return assets.exists(ASSET_NAME, id);
    }

    function name(uint256 id) external view returns (string memory) {
        return _metadata[id].name;
    }

    function properties(uint256 id)
        external
        view
        returns (EnumerableMap.MapEntry[] memory)
    {
        EnumerableMap.Map storage _properties = _metadata[id].properties;
        uint256 propsLength = _properties.length();

            EnumerableMap.MapEntry[] memory propertyPairs
         = new EnumerableMap.MapEntry[](propsLength);
        for (uint256 i = 0; i < propsLength; i++) {
            (bytes32 k, bytes32 v) = _properties.at(i);
            propertyPairs[i].key = k;
            propertyPairs[i].value = v;
        }
        return propertyPairs;
    }

    function getProperty(uint256 id, bytes32 key)
        external
        view
        returns (bytes32)
    {
        EnumerableMap.Map storage _properties = _metadata[id].properties;
        return _properties.get(key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./meta/EIP712MetaTransaction.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./EnumerableMap.sol";
import "./EnumerableStringMap.sol";
import "./Constants.sol";

import "hardhat/console.sol";

contract Gladiator is IRegisterableAsset, ERC1155Receiver, EIP712MetaTransaction {
  using SafeMath for uint256;
  using EnumerableMap for EnumerableMap.Map;
  using EnumerableStringMap for EnumerableStringMap.Map;
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 constant ASSET_NAME = "gladiator";
  uint256 constant TOTAL_SUPPLY = 2**24;

  uint256 constant ASSET_DECIMALS = 10**18;

  IAssets immutable public assets;

  struct Metadata {
    string name;
    string image;
    EnumerableMap.Map properties;
    EnumerableStringMap.Map extendedProperties;
  }

  mapping(uint256 => Metadata) private _metadata;

  mapping(uint256 => EnumerableSet.UintSet) private _inventory;

  mapping(uint256 => mapping(uint256 => uint256)) private _balances;

  constructor(address assetsAddress) public EIP712MetaTransaction("Gladiator", "1") {
    assets = IAssets(assetsAddress);
  }

  function assetName() override public pure returns (bytes32) {
    return ASSET_NAME;
  }

  function assetTotalSupply() override public pure returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function assetIsNFT() override public pure returns (bool) {
    return true;
  }

  function assetOperators() override public view returns (address[] memory) {
    address[] memory operators = new address[](1);
    operators[0] = address(this);
    return operators;
  }

  function idRange() public view returns (uint256, uint256) {
    return assets.idRange(ASSET_NAME);
  }

  function mint(
    address account,
    string calldata name,
    string calldata image,
    EnumerableMap.MapEntry[] calldata properties,
    EnumerableStringMap.MapEntry[] calldata extendedProperties
  ) external returns (uint256) {
    // uint256 propsLength = propertyPairs.length;
    // require((propsLength % 2) == 0, "propertyPairs must have even number of members (k/v)");

    uint256[] memory ids = assets.mint(account, ASSET_NAME, 1, "");
    uint256 id = ids[0];

    Metadata storage metadata = _metadata[id];
    metadata.name = name;
    metadata.image = image;

    EnumerableMap.Map storage _properties = metadata.properties;
    EnumerableStringMap.Map storage _extendedProperties = metadata.extendedProperties;

    for (uint i; i < properties.length; i++) {
      _properties.set(properties[i].key, properties[i].value);
    }

    for (uint i; i < extendedProperties.length; i++) {
      _extendedProperties.set(extendedProperties[i].key, extendedProperties[i].value);
    }

    _properties.set("generation", bytes32(_generationOfID(id)));
    _properties.set("createdAt", bytes32(block.timestamp));

    return id;
  }

  // Returns integer representing generation of id
  // generation correlates to number of digits, floored at 2
  // 0-99 gen 0
  // 100-999 gen 1
  // 1000-9999 gen 2
  // etc
  function _generationOfID(uint256 id) internal view returns (uint256) {
    (uint256 gladiatorMinID, uint256 _) = assets.idRange(ASSET_NAME);
    uint256 mintNumber = id - gladiatorMinID;

    uint8 digits = 0;
    while (mintNumber != 0) {
      mintNumber /= 10;
      digits++;
    }

    return Math.max(digits, 2) - 2;
  }

  function exists(
    uint256 id
  ) public view returns (bool) {
    return assets.exists(ASSET_NAME, id);
  }

  function name(
    uint256 id
  ) external view returns (string memory) {
    return _metadata[id].name;
  }

  function image(
    uint256 id
  ) external view returns (string memory) {
    return _metadata[id].image;
  }

  function prestige(
    uint256 id
  ) external view returns (uint256) {
    (uint256 prestigeTokenID, uint256 _) = assets.idRange(Constants.prestigeAssetName());
    return _balances[id][prestigeTokenID];
  }

  function properties(
    uint256 id
  ) external view returns (EnumerableMap.MapEntry[] memory) {
    EnumerableMap.Map storage _properties = _metadata[id].properties;
    uint256 propsLength = _properties.length(); 
    EnumerableMap.MapEntry[] memory propertyPairs = new EnumerableMap.MapEntry[](propsLength);
    for (uint256 i = 0; i < propsLength; i++) {
      (bytes32 k, bytes32 v) = _properties.at(i);
      propertyPairs[i] = EnumerableMap.MapEntry({
        key: k,
        value: v
      });
    }
    return propertyPairs;
  }

  function getProperty(
    uint256 id,
    bytes32 key
  ) external view returns (bytes32) {
    return _metadata[id].properties.get(key);
  }
  
  function extendedProperties(
    uint256 id
  ) external view returns (EnumerableStringMap.MapEntry[] memory) {
    EnumerableStringMap.Map storage _extendedProperties = _metadata[id].extendedProperties;
    uint256 propsLength = _extendedProperties.length(); 
    EnumerableStringMap.MapEntry[] memory propertyPairs = new EnumerableStringMap.MapEntry[](propsLength);
    for (uint256 i = 0; i < propsLength; i++) {
      (bytes32 k, string memory v) = _extendedProperties.at(i);
      propertyPairs[i] = EnumerableStringMap.MapEntry({
        key: k,
        value: v
      });
    }
    return propertyPairs;
  }

  function getExtendedProperty(
    uint256 id,
    bytes32 key
  ) external view returns (string memory) {
    return _metadata[id].extendedProperties.get(key);
  }

  function inventory(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ids = new uint256[](set.length());
    for (uint256 i = 0; i < ids.length; i++) {
      ids[i] = set.at(i);
    }
    return ids;
  }

  function balances(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ret = new uint256[](set.length());
    for (uint256 i = 0; i < ret.length; i++) {
      ret[i] = _balances[id][set.at(i)];
    }
    return ret;
  }

  function balanceOf(
    uint256 id,
    uint256 tokenID
  ) external view returns (uint256) {
    return _balances[id][tokenID];
  }

  function safeTransferFrom(
        uint gladiator,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
  ) public {
    address sender = msgSender();
    require(assets.isApprovedOrOwner(sender, sender, gladiator), "You must own the the gladiator to transfer balances");
    uint bal = _balances[gladiator][id];
    _balances[gladiator][id] = bal.sub(amount); // this will error if the sub doesn't go through.
    assets.safeTransferFrom(address(this), to, id, amount, data);
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory values = new uint256[](1);
    ids[0] = id;
    values[0] = value;
    onERC1155BatchReceived(operator, from, ids, values, data);
    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes calldata data // abi.encoded (uint256 gladiatorID)
  ) public override returns(bytes4) {
    require(msgSender() == address(assets), "Gladiator can only receive items from Assets contract");

    (uint256 gladiatorID) = abi.decode(data, (uint256));
    require(exists(gladiatorID), "gladiator does not exist");

    EnumerableSet.UintSet storage gladiatorInventory = _inventory[gladiatorID];
    for (uint i = 0; i < ids.length; i++) {
      gladiatorInventory.add(ids[i]);
      _balances[gladiatorID][ids[i]] += values[i];
    }

    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IDiceRollsV5 {
    event DiceRoll(uint256 indexed id, uint256 random);

    struct RollParams {
        uint256 id;
        uint256 random;
        PerformancePair[] performances;
        uint256 blockNumber;
    }

    struct PerformancePair {
        bytes32 name;
        int256 value;
    }

    function latest() external virtual view returns (uint);

    function roll(uint256 random, PerformancePair[] calldata performance)
        external
        virtual;

    function getLatestRoll() external view virtual returns (RollParams memory);

    function getRoll(uint256 index)
        external
        view
        virtual
        returns (RollParams memory);

    function getRange(uint256 start, uint length)
        external
        view
        virtual
        returns (RollParams[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IDiceRolls {
    event DiceRoll(uint256 indexed id, uint256 random);

    struct RollParams {
        uint256 id;
        uint256 random;
        PerformancePair[] performances;
        uint256 blockNumber;
    }

    struct PerformancePair {
        bytes32 name;
        uint256 value;
    }

    function latest() external virtual view returns (uint);

    function roll(uint256 random, PerformancePair[] calldata performance)
        external
        virtual;

    function getLatestRoll() external view virtual returns (RollParams memory);

    function getRoll(uint256 index)
        external
        view
        virtual
        returns (RollParams memory);

    function getRange(uint256 start, uint length)
        external
        view
        virtual
        returns (RollParams[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ITournamentV4.sol";
import "./IDiceRolls.sol";

interface IGameLogicV4 {

    struct RollReturn {
        uint attacker;
        uint defender;
        int attackRoll;
        int defenseRoll;
        int attackHpAddition;
        int defenseHpAddition;
    }

    function roll(
        ITournamentV4.Game memory game,
        IDiceRolls.RollParams[] memory rolls
    ) external view virtual returns (ITournamentV4.Game memory);

    // This interface allows running a tournament without *creating* a tournament (just seeing results)
    // We *theorize* this is useful as a welcome experience.
    function tournament(
        ITournamentV4.GameGladiator[] memory gladiators,
        IDiceRolls.RollParams[] calldata rolls
    ) external view virtual returns (ITournamentV4.Round[] memory rounds);

    function bracket(
        uint tournamentId,
        int lastRoll
    ) external view virtual returns (ITournamentV4.Round[] memory rounds);

    function tournamentWinner(
        uint tournamentId
    ) external view virtual returns (uint256 registrationId, uint lastRoll);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ITournamentV4.sol"; 

interface ITournamentV5 is ITournamentV4 {
    struct TournamentDataV5 {
        string name;
        address creator;
        uint256 notBefore;
        int256 maxFactionBonus;
        uint256 firstRoll;
        uint256 lastRoll;
        address gameLogic;
        address roller;
        uint8 totalRounds;
        string[] factions;
        Champion champion;
        Registration[] registrations;
    }
    
    function factions(uint256 tournamentId) external view returns (string[] memory);
    function maxFactionBonus(uint256 tournamentId) external view returns (int256);
    function rollerV5(uint256 tournamentId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// Copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.3/contracts/utils/EnumerableMap.sol
// exposes all private methods, resulting in pure byte32 => byte32 functions

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap internal myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses internal functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 key;
        bytes32 value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ key: key, value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1].value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Map storage map, bytes32 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry.key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Map storage map) internal view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry.key, entry.value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Map storage map, bytes32 key) internal view returns (bytes32) {
        return get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(Map storage map, bytes32 key, string memory errorMessage) internal view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1].value; // All indexes are 1-based
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// this is similar to ./EnumberableMap but uses *strings* for values

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap internal myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableStringMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses internal functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 key;
        string value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Map storage map, bytes32 key, string memory value) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ key: key, value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1].value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Map storage map, bytes32 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry.key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Map storage map, bytes32 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Map storage map) internal view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Map storage map, uint256 index) internal view returns (bytes32, string memory) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry.key, entry.value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Map storage map, bytes32 key) internal view returns (string memory) {
        return get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(Map storage map, bytes32 key, string memory errorMessage) internal view returns (string memory) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1].value; // All indexes are 1-based
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IGameLogicV4.sol";
import "./IGameEquipment.sol";
import "./IDiceRolls.sol";

interface ITournamentV4 {
    event RegistrationEvent(
        uint256 indexed tournamentId,
        uint256 indexed gladiatorId,
        uint16 faction,
        uint256 registrationId
    );

    event NewTournament(address indexed creator, uint256 indexed notBefore, uint256 tournamentId);

    event TournamentComplete(uint256 indexed tournamentId, uint256 winner);

    struct Registration {
        uint16 faction;
        uint256 gladiator;
    }

    struct Champion {
        uint16 faction;
        uint256 gladiator;
        uint256 trophy;
    }

    struct TournamentData {
        string name;
        address creator;
        uint256 notBefore;
        uint256 firstRoll;
        uint256 lastRoll;
        IGameLogicV4 gameLogic;
        IDiceRolls roller;
        uint8 totalRounds;
        string[] factions;
        Champion champion;
        Registration[] registrations;
    }

    struct GameGladiator {
        string name;
        uint256 id;
        uint256 registrationId;
        int256 hitPoints;
        uint256 attack;
        uint256 defense;
        uint256 faction;
        IGameEquipment.EquipmentMetadata[] equipment;
        uint256[] equipmentUses;
    }

    struct Round {
        Game[] games;
        uint256 firstRoll;
        uint256 lastRoll;
    }

    struct Game {
        uint256 id;
        uint256 tournamentId;
        bool decided;
        uint8 winner;
        uint256 firstRoll;
        uint256 lastRoll;
        GameGladiator[] players;
    }

    function firstRoll(uint256 tournamentId) external view returns (uint256);

    function notBefore(uint256 tournamentId) external view returns (uint256);

    function started(uint256 tournamentId) external view returns (bool);

    function lastRoll(uint256 tournamentId) external view returns (uint256);

    function roller(uint256 tournamentId) external view returns (IDiceRolls);

    function registrations(uint256 tournamentId) external view returns (Registration[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IGameEquipment {
    struct EquipmentMetadata {
        uint256 id;
        string name;
        int256 hitPoints;
        int256 attack;
        int256 defense;
        uint256 percentChanceOfUse;
        uint256 numberOfUsesPerGame;
        bytes32 createdAt;
    }

    function getMetadata(uint id) external virtual returns (EquipmentMetadata memory);

    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IAssetsERC20Wrapper.sol";

import "hardhat/console.sol";

// turns out the regular wrapper factory doesn't support name, but this does.

contract WrappedPTG is IAssetsERC20Wrapper, ERC20, ERC1155Receiver {
    using SafeMath for uint256;

    IAssets immutable _tokenHolder;
    uint256 private _tokenID; // the specific token id this erc20 is wrapping

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(address holder, uint256 prestigeID)
        ERC20("Wrapped Prestige", "wPTG")
    {
        _tokenHolder = IAssets(holder);
        _tokenID = prestigeID; // initialize the contract for the copy
    }

    function unwrap(
        address account,
        address to,
        uint256 amount
    ) external override {
        if (account != _msgSender()) {
            uint256 currentAllowance = allowance(account, _msgSender());
            require(
                currentAllowance >= amount,
                "AssetsERC20Wrapper: unwrap amount exceeds allowance"
            );
            _approve(account, _msgSender(), currentAllowance.sub(amount));
        }
        _burn(account, amount);
        _tokenHolder.safeTransferFrom(address(this), to, _tokenID, amount, "");
    }

    function onERC1155Received(
        address, // operator
        address from,
        uint256 id,
        uint256 value,
        bytes calldata // data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(_tokenHolder),
            "AssetsERC20Wrapper#onERC1155: invalid asset address"
        );
        require(id == _tokenID, "AssetsERC20Wrapper: invalid token id");

        _mint(from, value);

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("batch send is not supported");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./IAssets.sol";

import "hardhat/console.sol";

interface IAssetsERC20Wrapper is IERC20 {

    function unwrap(address account, address to, uint256 amount) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./libraries/UniswapV2Library.sol";

import "./interfaces/IAssets.sol";
import "./interfaces/IAssetsERC20Wrapper.sol";
import "./interfaces/IGameEquipment.sol";
import "hardhat/console.sol";

interface IWrapperFactory {
    function getWrapper(uint256 tokenID) external view returns (address); // mapping of tokenID to address

    function createWrapper(
        uint256 tokenID,
        string calldata name,
        string calldata symbol
    ) external returns (address);
}

contract Marketplace is Ownable, ERC1155Receiver {
    using SafeMath for uint256;

    event Bootstrap(uint256 indexed itemID, uint256 prestigeAmount, uint256 tokenAmount);
    event Mint(uint256 indexed itemID, uint256 quantity);
    event Buy(address indexed from, uint256 indexed itemID, uint256 prestigeAmount, uint256 tokenAmount);
    event Sell(address indexed from, uint256 indexed itemID, uint256 prestigeAmount, uint256 tokenAmount);

    uint256 constant maxUint = 2**254;
    bytes4 constant bootstrapSelector = bytes4(keccak256("boot"));

    uint256 private immutable _ptgID;
    IAssets private immutable _assets;
    IGameEquipment private immutable _equipment;
    IWrapperFactory private immutable _wrapperFactory;
    IAssetsERC20Wrapper public immutable wrappedPTG;
    IUniswapV2Factory public immutable uniswapFactory;
    IUniswapV2Router02 public immutable uniswapRouter;

    constructor(
        address assetsContract,
        address equipmentContract,
        address wrapperFactoryContract,
        address uniswapFactoryContract,
        address uniswapRouterContract,
        uint256 ptgID
    ) {
        IWrapperFactory factory = IWrapperFactory(wrapperFactoryContract);
        _wrapperFactory = factory;
        _assets = IAssets(assetsContract);

        // you cannot call getWrapper here because you can't read from _wrapperFactory;
        address wrapperContract = factory.getWrapper(ptgID);
        require(wrapperContract != address(0), "invalid token wrapper");
        wrappedPTG = IAssetsERC20Wrapper(wrapperContract);

        uniswapFactory = IUniswapV2Factory(uniswapFactoryContract);
        uniswapRouter = IUniswapV2Router02(uniswapRouterContract);

        IAssetsERC20Wrapper(wrapperContract).approve(
            uniswapRouterContract,
            maxUint
        );
        _equipment = IGameEquipment(equipmentContract);
        _ptgID = ptgID;
    }

    function prices(uint itemID, uint quantity) external view returns (uint buy, uint sell) {
        address itemWrapper = _wrapperFactory.getWrapper(itemID);
        (uint ptgReserve, uint itemReserve) = UniswapV2Library.getReserves(address(uniswapFactory), address(wrappedPTG), itemWrapper);
        buy = 0;
        // do not error if trying to buy more than allowed, you can never buy *all* the items (because price would be infinite)
        if (itemReserve > quantity) {
            buy = UniswapV2Library.getAmountIn(quantity, ptgReserve, itemReserve);
        }
        sell = UniswapV2Library.getAmountOut(quantity, itemReserve, ptgReserve);
        return (buy,sell);
    }

    function wrapper(uint itemID) external view returns (address) {
        return _wrapperFactory.getWrapper(itemID);
    }

    function reserves(uint itemID) external view returns (uint ptg, uint item) {
        address itemWrapper = _wrapperFactory.getWrapper(itemID);
        return UniswapV2Library.getReserves(address(uniswapFactory), address(wrappedPTG), itemWrapper);
    }

    function bootstrap(
        uint256 tokenID,
        uint256 prestigeAmount,
        uint256 tokenAmount,
        string memory name,
        string memory symbol
    ) internal {
        // create the item proxy, and the liquidity pool
        // TODO: add to a list of items
        IAssetsERC20Wrapper tokenWrapper =
            IAssetsERC20Wrapper(
                _wrapperFactory.createWrapper(tokenID, name, symbol)
            );
        tokenWrapper.approve(address(uniswapRouter), maxUint);
        _assets.safeTransferFrom(
            address(this),
            address(tokenWrapper),
            tokenID,
            tokenAmount,
            ""
        );
        _assets.safeTransferFrom(
            address(this),
            address(wrappedPTG),
            _ptgID,
            prestigeAmount,
            ""
        );

        uniswapRouter.addLiquidity(
            address(wrappedPTG),
            address(tokenWrapper),
            prestigeAmount,
            tokenAmount,
            prestigeAmount,
            tokenAmount,
            address(this),
            maxUint
        );
        emit Bootstrap(tokenID, prestigeAmount, tokenAmount);
    }

    function getWrapper(uint256 tokenID)
        internal
        view
        returns (IAssetsERC20Wrapper)
    {
        address wrapperContract = _wrapperFactory.getWrapper(tokenID);
        require(wrapperContract != address(0), "invalid token wrapper");
        return IAssetsERC20Wrapper(wrapperContract);
    }

    function onMint(uint256 tokenID, uint256 amount) internal {
        // console.log('on mint');
        IAssetsERC20Wrapper tokenWrapper = getWrapper(tokenID);
        // console.log('wrapper: ', address(tokenWrapper));
        IUniswapV2Pair pair =
            IUniswapV2Pair(
                uniswapFactory.getPair(
                    address(tokenWrapper),
                    address(wrappedPTG)
                )
            );

        // console.log('pair: ', address(pair));
        // first we wrap them
        _assets.safeTransferFrom(
            address(this),
            address(tokenWrapper),
            tokenID,
            amount,
            ""
        );
                // console.log('wrapped');
        // then we transfer them to the liquidity contract
        tokenWrapper.transfer(address(pair), amount);
        // console.log('transferred to pair');
        // then we sync so no skim!
        pair.sync();
        // console.log('synced');
        emit Mint(tokenID, amount);
    }

    // onReceivedItem sells the item into the bonding curve
    function onReceivedItem(
        address from,
        uint256 tokenID,
        uint256 quantity,
        uint256 minAmountOut,
        uint256 deadline
    ) internal returns (uint256 amountReceived) {
        IAssetsERC20Wrapper tokenWrapper = getWrapper(tokenID);

        // first we wrap the item
        _assets.safeTransferFrom(
            address(this),
            address(tokenWrapper),
            tokenID,
            quantity,
            ""
        );
        // then we use the router
        address[] memory path = new address[](2);
        path[0] = address(tokenWrapper);
        path[1] = address(wrappedPTG);

        uint256[] memory amounts =
            uniswapRouter.swapExactTokensForTokens(
                quantity,
                minAmountOut,
                path,
                address(this),
                deadline
            );
        // now unwrap the PTG
        wrappedPTG.unwrap(address(this), from, amounts[1]);
        emit Sell(from, tokenID, amounts[0], quantity);
        return amounts[0];
    }

    // onReceivedItem buys an item with a max amount of PTG
    function onReceivedPTG(
        address from,
        uint256 amount,
        uint256 itemToBuy,
        uint256 quantity,
        uint256 maxAmount,
        uint256 deadline
    ) internal returns (uint256 amountReceived) {
        // console.log('on received ptg');
        IAssetsERC20Wrapper toBuyWrapper = getWrapper(itemToBuy);

        // first we wrap the ptg
        _assets.safeTransferFrom(
            address(this),
            address(wrappedPTG),
            _ptgID,
            amount,
            ""
        );
        // console.log('wrapped');

        // then we use the router
        address[] memory path = new address[](2);
        path[0] = address(wrappedPTG);
        path[1] = address(toBuyWrapper);

        // console.log('deadline, now', deadline, block.timestamp);

        uint256[] memory amounts =
            uniswapRouter.swapTokensForExactTokens(
                quantity,
                maxAmount,
                path,
                address(this),
                deadline
            );
        // console.log('swapped');
        // now unwrap the item
        toBuyWrapper.unwrap(address(this), from, quantity);
        // console.log('unwrapped');

        if (amounts[0] < amount) {
            wrappedPTG.unwrap(address(this), from, amount.sub(amounts[0]));
        }
        // console.log('emit');
        emit Buy(from, itemToBuy, amounts[0], quantity);
        return amounts[0];
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;
        onERC1155BatchReceived(operator, from, ids, values, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) public override returns (bytes4) {
        require(
            msg.sender == address(_assets),
            "Marketplace can only receive items from Assets contract"
        );
        // special case where we want to bootstrap and create a new pair
        if (bytes4(keccak256(abi.encodePacked(data))) == bootstrapSelector) {
            require(ids[0] == _ptgID, "first asset must be PTG");
            require(
                ids.length == 2,
                "pass in only PTG and a single other token"
            );
            IGameEquipment.EquipmentMetadata memory meta =
                _equipment.getMetadata(ids[1]);

            bootstrap(
                ids[1],
                values[0],
                values[1],
                meta.name,
                string(abi.encodePacked("CCWRAP-", uint2str(ids[1])))
            );
            return IERC1155Receiver.onERC1155BatchReceived.selector;
        }

        for (uint256 i; i < ids.length; i++) {
            if (from == address(0)) {
                // this is a mint
                onMint(ids[i], values[i]);
                continue;
            }
            if (ids[i] == _ptgID) {
                // this is a *purchase* of an item
                require(ids.length == 1, "cannot batch send more if purchasing");
                (uint256 tokenID, uint256 quantity, uint256 maxPrice, uint256 deadline) = abi.decode(data, (uint256, uint256, uint256, uint256));
                onReceivedPTG(from, values[i], tokenID, quantity, maxPrice, deadline);
                break;
            }
            (uint256 minAmountOut, uint256 deadline) = abi.decode(data, (uint256, uint256));
            onReceivedItem(from, ids[i], values[i], minAmountOut, deadline);
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

// direct port of the uniswap library but with an upgraded SafeMath

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
import "./interfaces/IGameLogicV4.sol";
import "./interfaces/IDiceRollsV5.sol";
import "./interfaces/ITournamentV5.sol";
import "./Gladiator.sol";
import "./EquipperV5.sol";
import "./interfaces/IGameEquipment.sol";

contract GameLogicV5 {
    using SafeMath for uint256;

    string constant TWENTY_FOUR_HR_POSTFIX = "-24h";

    struct Narrative {
        bool attackerIsWinner;
        uint256 attacker;
        uint256 defender;
        int256 attackRoll;
        int256 defenseRoll;
        int256 attackFactionBonus;
        int256 defenseFactionBonus;
        uint256[] attackEquipment;
        uint256[] defenseEquipment;
        int256 attackerHP;
        int256 defenderHP;
    }

    struct Bonus {
        uint256 id;
        int256 hitPoints;
        int256 attack;
        int256 defense;
    }

    struct OriginalStats {
        uint256 id;
        int256 hitPoints;
        uint256 attack;
        uint256 defense;
    }

    struct RollReturn {
        uint256 attacker;
        uint256 defender;
        int256 attackRoll;
        int256 defenseRoll;
        int256 attackHpAddition;
        int256 defenseHpAddition;
    }

    bytes32 constant HIT_POINTS = "hitpoints";
    bytes32 constant ATTACK = "attack";
    bytes32 constant DEFENSE = "defense";
    bytes32 constant NAME = "name";

    uint256 constant MAX_PERCENTAGE = 10**6;

    Gladiator private immutable _gladiators;
    ITournamentV5 private immutable _tournament;
    EquipperV5 public immutable equipper;

    constructor(
        address gladiatorContract,
        address tournamentContract,
        address assetsContract,
        address equipperContract
    ) {
        _gladiators = Gladiator(gladiatorContract);
        _tournament = ITournamentV5(tournamentContract);
        equipper = EquipperV5(equipperContract);
    }

    function copyUses(uint256[] memory uses)
        internal
        pure
        returns (uint256[] memory newUses)
    {
        newUses = new uint256[](uses.length);
        for (uint256 i; i < uses.length; i++) {
            newUses[i] = uses[i];
        }
        return newUses;
    }

    function equipmentBonuses(
        ITournamentV4.GameGladiator memory gladiator,
        uint256 random,
        bool isAttacker
    ) internal view returns (Bonus memory bonus) {
        // turn to view from pure if turning on console.log
        for (uint256 i; i < gladiator.equipment.length; i++) {
            // console.logBool(isAttacker);
            // console.log('scanning equipment: ', i);
            IGameEquipment.EquipmentMetadata memory equipment = gladiator
                .equipment[i];
            // if it's already been used, then just continue
            if (
                equipment.numberOfUsesPerGame > 0 &&
                gladiator.equipmentUses[i] >= equipment.numberOfUsesPerGame
            ) {
                continue;
            }
            // if this is the attacker, but this equipment does nothing for them
            // then just continue
            if (
                isAttacker && equipment.hitPoints == 0 && equipment.attack == 0
            ) {
                continue;
            }
            // if this is not the attacker, but the equipent only affects attack then
            // don't use it.
            if (
                !isAttacker &&
                equipment.hitPoints == 0 &&
                equipment.defense == 0
            ) {
                continue;
            }
            // otherwise roll the dice to see if it'll be used
            bool useEquipment = true;

            // 0 means 100% of the time anything more is a percentage that we roll for;
            if (equipment.percentChanceOfUse > 0) {
                uint256 equipRoll = uint256(
                    keccak256(abi.encodePacked(random, equipment.id, i))
                );
                useEquipment =
                    equipRoll.mod(MAX_PERCENTAGE) <=
                    equipment.percentChanceOfUse;
            }

            if (useEquipment) {
                // we'll go ahead and use this one
                // console.log('increasing usage', equipment.name, ' from ', gladiator.equipmentUses[i]);
                gladiator.equipmentUses[i]++;

                bonus.hitPoints += equipment.hitPoints;
                bonus.attack += equipment.attack;
                bonus.defense += equipment.defense;
            }
        }
        return bonus;
    }

    function concatBonuses(Bonus[] memory bonuses)
        internal
        pure
        returns (Bonus memory bonus)
    {
        for (uint256 i; i < bonuses.length; i++) {
            bonus.hitPoints += bonuses[i].hitPoints;
            bonus.attack += bonuses[i].attack;
            bonus.defense += bonuses[i].defense;
        }
        return bonus;
    }

    function getBonuses(
        ITournamentV4.Game memory game,
        uint256 random,
        Bonus[] memory factionBonuses,
        ITournamentV4.GameGladiator memory gladiator,
        bool isAttacker
    ) internal view returns (Bonus memory bonus) {
        Bonus[] memory bonuses = new Bonus[](2);
        bonuses[0] = factionBonuses[gladiator.faction];
        bonuses[1] = equipmentBonuses(gladiator, random, isAttacker);
        return concatBonuses(bonuses);
    }

    function getRoll(
        ITournamentV4.Game memory game,
        IDiceRollsV5.RollParams memory roll,
        Bonus[] memory factionBonuses,
        uint256 lastWinner
    ) public view returns (RollReturn memory) {
        // console.log('bonus length', bonuses.lenth, 'random: ', roll.random );
        uint256 random = roll.random;
        // console.log("random: (gameid, random) ", game.id, random);

        // first we roll a d3
        // 0 means player 1 is attacker
        // 1 means player 2 is attacker
        // 2 means last player to win is attacker
        uint256 d3 = random.mod(3);
        uint256 attacker = d3;
        if (attacker == 2) {
            attacker = lastWinner;
        }
        // console.log('attacker', attacker);
        uint256 defender = (attacker + 1).mod(game.players.length);

        ITournamentV4.GameGladiator memory attackGladiator = game.players[
            attacker
        ];
        ITournamentV4.GameGladiator memory defendGladiator = game.players[
            defender
        ];

        // console.log("attack/defense gladiator: ", attackGladiator.id, defendGladiator.id);

        uint256 attackRandom = uint256(
            keccak256(abi.encodePacked(attackGladiator.id, random))
        );
        uint256 defenseRandom = uint256(
            keccak256(abi.encodePacked(defendGladiator.id, random))
        );

        // console.log('attack/defense random', random, attackRandom, defenseRandom);

        Bonus memory attackBonus = getBonuses(
            game,
            attackRandom,
            factionBonuses,
            attackGladiator,
            true
        );
        Bonus memory defenseBonus = getBonuses(
            game,
            defenseRandom,
            factionBonuses,
            defendGladiator,
            false
        );

        // console.log('attackGladiator: ', attackGladiator.faction, 'bonus', bonuses[0]);
        // console.log("bonus: (attack,defend): ", bonuses[game.factions[attacker]], bonuses[game.factions[defender]]);
        int256 attackRoll = int256(attackRandom.mod(attackGladiator.attack));
        int256 defenseRoll = int256(defenseRandom.mod(defendGladiator.defense));

        attackRoll += attackBonus.attack;
        defenseRoll += defenseBonus.defense;

        return
            RollReturn({
                attacker: attacker,
                defender: defender,
                attackRoll: attackRoll,
                defenseRoll: defenseRoll,
                attackHpAddition: attackBonus.hitPoints,
                defenseHpAddition: defenseBonus.hitPoints
            });
    }

    function factionBonusesFromId(uint256 tournamentId)
        internal
        view
        returns (Bonus[] memory factionBonuses)
    {
        IDiceRollsV5 roller = IDiceRollsV5(_tournament.rollerV5(tournamentId));
        uint256 firstRoll = _tournament.firstRoll(tournamentId);
        ITournamentV4.GameGladiator[] memory gladiators = gameGladiators(
            tournamentId
        );
        return
            calculateFactionBonuses(
                tournamentId,
                roller.getRoll(firstRoll),
                gladiators
            );
    }

    // TODO: this is a hacky repeat of roll below, but for now it suffices
    function blowByBlow(
        uint256 tournamentId,
        ITournamentV4.Game memory game,
        IDiceRollsV5.RollParams[] memory rolls
    ) public view returns (Narrative[] memory narratives) {
        narratives = new Narrative[](rolls.length);
        // console.log("blow by blow: ", game.id, rolls.length);
        uint256 lastWinner = 0;
        IDiceRollsV5.RollParams memory previousRoll;

        Bonus[] memory factionBonuses = factionBonusesFromId(tournamentId);

        for (uint256 i = 0; i < rolls.length; i++) {
            Narrative memory narrative = narratives[i];
            IDiceRollsV5.RollParams memory roll = rolls[i];

            RollReturn memory rollResult = getRoll(
                game,
                roll,
                factionBonuses,
                lastWinner
            );

            int256 attackRoll = rollResult.attackRoll;
            int256 defenseRoll = rollResult.defenseRoll;
            uint256 attacker = rollResult.attacker;
            uint256 defender = rollResult.defender;

            narrative.attacker = game.players[attacker].id;
            narrative.defender = game.players[defender].id;
            narrative.attackRoll = attackRoll;
            narrative.defenseRoll = defenseRoll;

            narrative.attackFactionBonus = factionBonuses[
                game.players[attacker].faction
            ].attack;

            narrative.defenseFactionBonus = factionBonuses[
                game.players[defender].faction
            ].defense;

            narrative.attackEquipment = copyUses(
                game.players[attacker].equipmentUses
            );
            narrative.defenseEquipment = copyUses(
                game.players[defender].equipmentUses
            );

            game.players[attacker].hitPoints += rollResult.attackHpAddition;
            game.players[defender].hitPoints += rollResult.defenseHpAddition;

            narrative.attackerHP = game.players[attacker].hitPoints;
            if (attackRoll > defenseRoll) {
                // attack was successful!
                // console.log("successful attack: ");
                // console.logInt(attackRoll - defenseRoll);
                // console.logInt(game.players[defender].hitPoints);
                game.players[defender].hitPoints -= (attackRoll - defenseRoll);
                narrative.defenderHP = game.players[defender].hitPoints;
                // console.log('setting hp to');
                // console.logInt(narrative.defenderHP);
                if (game.players[defender].hitPoints <= 0) {
                    // console.log("death blow after # of rolls: ", i);
                    game.decided = true;
                    game.winner = uint8(attacker);
                    game.lastRoll = roll.id;

                    narrative.attackerIsWinner = true;
                    break;
                }
                lastWinner = attacker;
            } else {
                narrative.defenderHP = game.players[defender].hitPoints;
                lastWinner = defender;
                // console.log("defense win");
            }
        }
        return narratives;
    }

    function roll(
        ITournamentV4.Game memory game,
        IDiceRollsV5.RollParams[] memory rolls,
        Bonus[] memory factionBonuses
    ) public view returns (ITournamentV4.Game memory) {
        // console.log("roll: ", game.id, rolls.length);
        uint256 lastWinner = 0;
        IDiceRollsV5.RollParams memory previousRoll;

        (uint256 start, bool found) = indexOf(rolls, game.firstRoll);
        // require(found, "no first roll found in rolls");
        if (!found) {
            return game;
        }

        for (uint256 i = start; i < rolls.length; i++) {
            IDiceRollsV5.RollParams memory roll = rolls[i];

            RollReturn memory rollResult = getRoll(
                game,
                roll,
                factionBonuses,
                lastWinner
            );

            int256 attackRoll = rollResult.attackRoll;
            int256 defenseRoll = rollResult.defenseRoll;

            game.players[rollResult.attacker].hitPoints += rollResult
                .attackHpAddition;
            game.players[rollResult.defender].hitPoints += rollResult
                .defenseHpAddition;

            if (attackRoll > defenseRoll) {
                // attack was successful!
                // console.log("successful attack: ", attackRoll.sub(defenseRoll));
                game.players[rollResult.defender].hitPoints -= (attackRoll -
                    defenseRoll);
                if (game.players[rollResult.defender].hitPoints <= 0) {
                    // console.log("death blow after # of rolls: ", i);
                    game.decided = true;
                    game.winner = uint8(rollResult.attacker);
                    game.lastRoll = roll.id;
                    break;
                }
                lastWinner = rollResult.attacker;
            } else {
                lastWinner = rollResult.defender;
                // console.log("defense win");
            }
        }
        return game;
    }

    // TODO: binary search
    function indexOf(IDiceRollsV5.RollParams[] memory rolls, uint256 id)
        internal
        view
        returns (uint256 idx, bool found)
    {
        for (idx = 0; idx < rolls.length; idx++) {
            if (rolls[idx].id == id) {
                return (idx, true);
            }
        }
        return (0, false);
    }

    function _getRound(
        ITournamentV4.GameGladiator[] memory roundPlayers,
        IDiceRollsV5.RollParams[] memory rolls,
        uint256 firstRollIndex,
        Bonus[] memory factionBonuses
    ) internal view returns (ITournamentV4.Round memory round) {
        round.games = new ITournamentV4.Game[](roundPlayers.length.div(2));
        // console.log("fetching: ", firstRollIndex);
        if (firstRollIndex >= rolls.length) {
            uint256 gameId = 0;
            for (uint256 i; i < roundPlayers.length; i += 2) {
                ITournamentV4.Game memory game;

                ITournamentV4.GameGladiator[]
                    memory players = new ITournamentV4.GameGladiator[](2);
                players[0] = roundPlayers[i];
                players[1] = roundPlayers[i + 1];

                game.players = players;
                game.id = gameId;
                round.games[gameId] = game;
                gameId++;
            }
            return round;
        }
        uint256 firstRoll = rolls[firstRollIndex].id;
        round.firstRoll = firstRoll;

        bool lastGameIsFinished = true;

        uint256 gameId = 0;
        for (uint256 i; i < roundPlayers.length; i += 2) {
            ITournamentV4.Game memory game;

            ITournamentV4.GameGladiator[]
                memory players = new ITournamentV4.GameGladiator[](2);
            players[0] = roundPlayers[i];
            players[1] = roundPlayers[i + 1];
            // console.log("player 0: ", players[0].id);
            // console.log("player 1: ", players[1].id);

            game.players = players;
            game.id = gameId;
            if (lastGameIsFinished) {
                game.firstRoll = firstRoll;
                // console.log("calculatin game", i, game.id, firstRoll);
                // console.log(game.players.length);
                // only calculate if the last game was finished
                game = roll(game, rolls, factionBonuses);
            }
            if (game.decided) {
                // console.log("setting firstRoll: ", game.lastRoll);
                firstRoll = game.lastRoll + 1;
                lastGameIsFinished = true;
            } else {
                lastGameIsFinished = false;
            }
            round.games[gameId] = game;
            gameId++;
        }
        if (lastGameIsFinished) {
            round.lastRoll = firstRoll - 1; // firstRoll has been updating
        }
        return round;
    }

    // TODO: binary search
    function indexOfGladiator(OriginalStats[] memory originalStats, uint256 id)
        internal
        pure
        returns (uint256 idx)
    {
        for (idx = 0; idx < originalStats.length; idx++) {
            if (originalStats[idx].id == id) {
                return idx;
            }
        }
        require(false, "should not get here");
        return 0;
    }

    function restoreGladiator(
        ITournamentV4.GameGladiator memory gladiator,
        OriginalStats[] memory originalStats
    ) internal pure returns (ITournamentV4.GameGladiator memory) {
        uint256 idx = indexOfGladiator(originalStats, gladiator.id);
        OriginalStats memory stats = originalStats[idx];
        gladiator.hitPoints = stats.hitPoints;
        gladiator.attack = stats.attack;
        gladiator.defense = stats.defense;
        gladiator.equipmentUses = new uint256[](gladiator.equipmentUses.length);
        return gladiator;
    }

    function getWinners(
        ITournamentV4.Round memory round,
        OriginalStats[] memory originalStats
    ) internal pure returns (ITournamentV4.GameGladiator[] memory players) {
        players = new ITournamentV4.GameGladiator[](round.games.length);
        for (uint256 i; i < round.games.length; i++) {
            ITournamentV4.Game memory game = round.games[i];
            require(game.decided, "Winners not decided");
            players[i] = restoreGladiator(
                game.players[game.winner],
                originalStats
            );
        }
        return players;
    }

    function tournamentWinner(uint256 tournamentId)
        public
        view
        returns (uint256 registrationId, uint256 lastRoll)
    {
        ITournamentV4.Round[] memory rounds = bracket(tournamentId, -1);
        ITournamentV4.Round memory round = rounds[rounds.length - 1];
        ITournamentV4.Game memory game = round.games[0];
        require(game.decided, "Tournament Not Decided");
        return (game.players[game.winner].registrationId, game.lastRoll);
    }

    function getPerformancePair(IDiceRollsV5.RollParams memory roll, bytes32 name)
        internal
        pure
        returns (IDiceRollsV5.PerformancePair memory)
    {
        uint256 len = roll.performances.length;
        for (uint256 i; i < len; i++) {
            if (roll.performances[i].name == name) {
                return roll.performances[i];
            }
        }
        revert("unknown performance pair");
    }

    function calculateFactionBonuses(
        uint256 tournamentId,
        IDiceRollsV5.RollParams memory roll,
        ITournamentV4.GameGladiator[] memory gladiators
    ) internal view returns (Bonus[] memory bonuses) {
        string[] memory factionNames = _tournament.factions(tournamentId);
        bonuses = new Bonus[](factionNames.length);
        for (uint256 i; i < factionNames.length; i++) {
            IDiceRollsV5.PerformancePair memory perf = getPerformancePair(
                roll,
                concatToBytes32(factionNames[i], TWENTY_FOUR_HR_POSTFIX)
            );
            int256 bonus = _tournament.maxFactionBonus(tournamentId) * perf.value / 100000;
            // console.log('bonus: ');
            // console.logInt(bonus);
            bonuses[i] = Bonus({id: 0, hitPoints: 0, attack: bonus, defense: 0});
        }
        return bonuses;
    }

    function tournament(
        ITournamentV4.GameGladiator[] memory gladiators,
        IDiceRollsV5.RollParams[] memory rolls,
        Bonus[] memory factionBonuses
    ) public view returns (ITournamentV4.Round[] memory rounds) {
        ITournamentV4.Round memory currentRound;
        rounds = new ITournamentV4.Round[](log2(gladiators.length));

        OriginalStats[] memory originalStats = new OriginalStats[](
            gladiators.length
        );
        for (uint256 i = 0; i < gladiators.length; i++) {
            originalStats[i] = OriginalStats({
                id: gladiators[i].id,
                hitPoints: gladiators[i].hitPoints,
                attack: gladiators[i].attack,
                defense: gladiators[i].defense
            });
        }

        for (uint256 i = 0; i < rounds.length; i++) {
            if (i == 0) {
                // console.log("round 0");
                currentRound = _getRound(gladiators, rolls, 0, factionBonuses);
            } else {
                // console.log("round ", i);
                (uint256 start, bool found) = indexOf(
                    rolls,
                    currentRound.lastRoll
                );
                require(found, "no roll found");
                currentRound = _getRound(
                    getWinners(currentRound, originalStats),
                    rolls,
                    start + 1,
                    factionBonuses
                );
            }
            rounds[i] = currentRound;
            if (!currentRound.games[currentRound.games.length - 1].decided) {
                break;
            }
        }

        return rounds;
    }

    function bracket(uint256 tournamentId, int256 specifiedLastRoll)
        public
        view
        returns (ITournamentV4.Round[] memory rounds)
    {
        ITournamentV4.GameGladiator[] memory gladiators = gameGladiators(
            tournamentId
        );
        // if tournament hasn't started yet
        if (!_tournament.started(tournamentId)) {
            IDiceRollsV5.RollParams[] memory rolls;
            return tournament(gladiators, rolls, new Bonus[](0));
        }

        IDiceRollsV5 roller = IDiceRollsV5(_tournament.rollerV5(tournamentId));
        uint256 firstRoll = _tournament.firstRoll(tournamentId);

        uint256 lastRoll;

        // user sends in -1 to mean "the whole tournament
        if (specifiedLastRoll < 0) {
            lastRoll = _tournament.lastRoll(tournamentId);
            if (lastRoll == 0) {
                lastRoll = roller.latest();
            }
        } else {
            lastRoll = uint256(specifiedLastRoll);
        }
        IDiceRollsV5.RollParams[] memory rolls = roller.getRange(
            firstRoll,
            lastRoll
        );
        if (rolls.length == 0) {
            return tournament(gladiators, rolls, new Bonus[](0));
        }

        Bonus[] memory factionBonuses = calculateFactionBonuses(
            tournamentId,
            rolls[0],
            gladiators
        );

        return tournament(gladiators, rolls, factionBonuses);
    }

    // Gladiator stuff

    function getGladiator(
        uint256 registrationId,
        uint256 tournamentId,
        ITournamentV4.Registration memory reg
    ) internal view returns (ITournamentV4.GameGladiator memory gladiator) {
        uint256 id = reg.gladiator;
        gladiator.id = id;
        gladiator.faction = reg.faction;
        gladiator.registrationId = registrationId;
        gladiator.name = _gladiators.name(id);
        gladiator.hitPoints = int256(_gladiators.getProperty(id, HIT_POINTS));
        gladiator.attack = uint256(_gladiators.getProperty(id, ATTACK));
        gladiator.defense = uint256(_gladiators.getProperty(id, DEFENSE));
        gladiator.equipment = equipper.gladiatorEquipment(tournamentId, id);
        gladiator.equipmentUses = new uint256[](gladiator.equipment.length);
        return gladiator;
    }

    function gameGladiators(uint256 tournamentId)
        public
        view
        returns (ITournamentV4.GameGladiator[] memory gladiators)
    {
        ITournamentV4.Registration[] memory registrations = _tournament
            .registrations(tournamentId);
        return _gameGladiators(tournamentId, registrations);
    }

    function _gameGladiators(
        uint256 tournamentId,
        ITournamentV4.Registration[] memory registrations
    ) internal view returns (ITournamentV4.GameGladiator[] memory gladiators) {
        gladiators = new ITournamentV4.GameGladiator[](registrations.length);
        for (uint256 i; i < registrations.length; i++) {
            gladiators[i] = getGladiator(i, tournamentId, registrations[i]);
        }
        return gladiators;
    }

    function concatToBytes32(string memory a, string memory b)
        internal
        view
        returns (bytes32)
    {
        return bytesToBytes32(abi.encodePacked(a, b));
    }

    function bytesToBytes32(bytes memory source)
        private
        pure
        returns (bytes32 result)
    {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
        return result;
    }

    // see: https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity
    function log2(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITournamentV4.sol";
import "./interfaces/IDiceRolls.sol";
import "./Assets.sol";
import "./interfaces/IGameEquipment.sol";

import "hardhat/console.sol";

contract EquipperV5 is ERC1155Receiver, AccessControl {
    using SafeMath for uint256;

    bytes32 constant EQUIPMENT_NAME = "equipment";

    bytes32 public constant SETTINGS_UPDATER_ROLE =
        keccak256("SETTINGS_UPDATER_ROLE");

    IGameEquipment public immutable equipment;
    ITournamentV4 private immutable _tournament;
    Assets private immutable _assets; // ERC-1155 Assets contract

    uint256 public lockTime = 15 * 60; // 15 minutes
    uint256 public maxPerGladiator = 1;
    uint256 public maxPerTournament = 4;
    uint256 public globaMaxPerTournamentGladiator = 3;

    struct Equipping {
        uint256 gladiatorId;
        uint256 equipmentId;
    }

    mapping(uint256 => mapping(uint256 => IGameEquipment.EquipmentMetadata[]))
        public equippings; // tournamentId => gladiatorId => array of equipment

    mapping(address => mapping(uint256 => Equipping[])) public playerEquippings; // player -> tournament -> array of equippings
    mapping(address => mapping(uint256 => uint256))
        public playerTournamentCount; // player -> tournament -> count of tournament equippings
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public playerTournamentGladiatorCount; // player -> tournament -> gladiatorId -> count of gladiator equippings

    constructor(
        address equipmentContract,
        address tournamentContractAddress,
        address assetsContract
    ) {
        equipment = IGameEquipment(equipmentContract);
        _tournament = ITournamentV4(tournamentContractAddress);
        _assets = Assets(assetsContract);
        _setupRole(SETTINGS_UPDATER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function updateSettings(
        uint256 _lockTime,
        uint256 _maxPerGladiator,
        uint256 _maxPerTournament,
        uint256 _globaMaxPerTournamentGladiator
    ) public {
        require(
            hasRole(SETTINGS_UPDATER_ROLE, msg.sender),
            "Must be a settings updater"
        );
        lockTime = _lockTime;
        maxPerGladiator = _maxPerGladiator;
        maxPerTournament = _maxPerTournament;
        globaMaxPerTournamentGladiator = _globaMaxPerTournamentGladiator;
    }

    function gladiatorEquipment(uint256 tournamentId, uint256 gladiatorId)
        public
        view
        returns (IGameEquipment.EquipmentMetadata[] memory)
    {
        return equippings[tournamentId][gladiatorId];
    }

    function handleEquipment(
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // abi encoded uint256,uint256 tournamentId, gladiatorId
    ) internal returns (bool) {
        // TODO: allow fungible equipment
        require(
            value == 1,
            "Equipper#onERC1155BatchReceived: may only add one equipment at a time"
        );

        (uint256 tournamentId, uint256 gladiatorId) = abi.decode(
            data,
            (uint256, uint256)
        );

        uint256 tournamentStart = _tournament.notBefore(tournamentId);
        require(
            (tournamentStart > block.timestamp) && (tournamentStart.sub(block.timestamp)) > lockTime,
            "Equipper#Equippings locked"
        );
        require(
            equippings[tournamentId][gladiatorId].length <
                globaMaxPerTournamentGladiator,
            "Equipper#Max equippings per gladiator per tournament"
        );
        require(
            playerTournamentCount[from][tournamentId] < maxPerTournament,
            "Equipper#Max per tournament reached"
        );
        require(
            playerTournamentGladiatorCount[from][tournamentId][gladiatorId] <
                maxPerGladiator,
            "Equipper#Max per gladiator reached"
        );

        equippings[tournamentId][gladiatorId].push(equipment.getMetadata(id));
        playerEquippings[from][tournamentId].push(
            Equipping({gladiatorId: gladiatorId, equipmentId: id})
        );
        playerTournamentCount[from][tournamentId] += 1;
        playerTournamentGladiatorCount[from][tournamentId][gladiatorId] += 1;
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;
        onERC1155BatchReceived(operator, from, ids, values, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data // abi.encoded (uint256 tournamentId, uint16 faction)
    ) public override returns (bytes4) {
        require(
            msg.sender == address(_assets),
            "Tournament#onERC1155BatchReceived: invalid asset address"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            if (_assets.exists(EQUIPMENT_NAME, ids[i])) {
                require(
                    handleEquipment(from, ids[i], values[i], data),
                    "error handling equipment"
                );
                continue; // stop processing hr
            }
            revert("Unknown token type");
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
import "./interfaces/IGameLogicV4.sol";
import "./interfaces/IDiceRolls.sol";
import "./interfaces/ITournamentV4.sol";
import "./Gladiator.sol";
import "./Equipper.sol";
import "./interfaces/IGameEquipment.sol";

contract GameLogicV4 is IGameLogicV4 {
    using SafeMath for uint256;

    bytes32 constant HIT_POINTS = "hitpoints";
    bytes32 constant ATTACK = "attack";
    bytes32 constant DEFENSE = "defense";
    bytes32 constant NAME = "name";

    uint256 constant MAX_PERCENTAGE = 10**6;

    Gladiator immutable private _gladiators;
    ITournamentV4 immutable private _tournament;
    Equipper immutable public equipper;

    constructor(
        address gladiatorContract, 
        address tournamentContract, 
        address assetsContract,
        address equipmentContract
    ) {
        _gladiators = Gladiator(gladiatorContract);
        _tournament = ITournamentV4(tournamentContract);
        equipper = new Equipper(equipmentContract, tournamentContract, assetsContract);
    } 

    struct Narrative {
        bool attackerIsWinner;
        uint256 attacker;
        uint256 defender;
        int256 attackRoll;
        int256 defenseRoll;
        int256 attackFactionBonus;
        int256 defenseFactionBonus;
        uint256[] attackEquipment;
        uint256[] defenseEquipment;
        int256 attackerHP;
        int256 defenderHP;
    }

    struct Bonus {
        uint256 id;
        int256 hitPoints;
        int256 attack;
        int256 defense;
    }

    struct OriginalStats {
        uint id;
        int256 hitPoints;
        uint attack;
        uint defense;
    }

    // expected is the uint[] from RollParams#performance
    function getFactionBonuses(
        IDiceRolls.PerformancePair[] memory previous,
        IDiceRolls.PerformancePair[] memory current
    ) internal pure returns (uint256[] memory bonuses) {
        bonuses = new uint256[](current.length);
        for (uint256 i; i < current.length; i++) {
            int256 prev = int256(previous[i].value);
            if (prev == 0) {
                prev = int256(current[i].value);
            }
            // if previous is still 0 then we don't
            // want to divide by zero, so continue
            if (prev == 0) {
                continue;
            }
            int256 bonus = (prev - (int256(current[i].value) * 100)) / prev;
            if (bonus < 0) {
                bonus = 0;
            }
            bonuses[i] = uint256(bonus);
        }
        return bonuses;
    }

    function factionBonus(
        ITournamentV4.Game memory game,
        uint256[] memory bonuses,
        ITournamentV4.GameGladiator memory gladiator
    ) internal view returns (Bonus memory bonus) {
        // console.log("faction: ", gladiator.faction);
        // console.log("bonus length: ", bonuses.length);
        int256 facBonus_ = int256(bonuses[gladiator.faction]);
        bonus.attack = facBonus_;
        bonus.defense = facBonus_;
    }

    function copyUses(uint256[] memory uses)
        internal
        pure
        returns (uint256[] memory newUses)
    {
        newUses = new uint256[](uses.length);
        for (uint256 i; i < uses.length; i++) {
            newUses[i] = uses[i];
        }
        return newUses;
    }

    function equipmentBonuses(
        ITournamentV4.GameGladiator memory gladiator,
        uint256 random,
        bool isAttacker
    ) internal view returns (Bonus memory bonus) {
        // turn to view from pure if turning on console.log
        for (uint256 i; i < gladiator.equipment.length; i++) {
            // console.logBool(isAttacker);
            // console.log('scanning equipment: ', i);
            IGameEquipment.EquipmentMetadata memory equipment =
                gladiator.equipment[i];
            // if it's already been used, then just continue
            if (
                equipment.numberOfUsesPerGame > 0 &&
                gladiator.equipmentUses[i] >= equipment.numberOfUsesPerGame
            ) {
                continue;
            }
            // if this is the attacker, but this equipment does nothing for them
            // then just continue
            if (
                isAttacker && equipment.hitPoints == 0 && equipment.attack == 0
            ) {
                continue;
            }
            // if this is not the attacker, but the equipent only affects attack then
            // don't use it.
            if (
                !isAttacker &&
                equipment.hitPoints == 0 &&
                equipment.defense == 0
            ) {
                continue;
            }
            // otherwise roll the dice to see if it'll be used
            bool useEquipment = true;
            
            // 0 means 100% of the time anything more is a percentage that we roll for;
            if (equipment.percentChanceOfUse > 0) {
                uint256 equipRoll =
                    uint256(keccak256(abi.encodePacked(random, equipment.id)));
                useEquipment = equipRoll.mod(MAX_PERCENTAGE) <=
                    equipment.percentChanceOfUse;
            }

            if (useEquipment) {
                // we'll go ahead and use this one
                // console.log('increasing usage', equipment.name, ' from ', gladiator.equipmentUses[i]);
                gladiator.equipmentUses[i]++;

                bonus.hitPoints += equipment.hitPoints;
                bonus.attack += equipment.attack;
                bonus.defense += equipment.defense;
            }
        }
        return bonus;
    }

    function concatBonuses(Bonus[] memory bonuses)
        internal
        pure
        returns (Bonus memory bonus)
    {
        for (uint256 i; i < bonuses.length; i++) {
            bonus.hitPoints += bonuses[i].hitPoints;
            bonus.attack += bonuses[i].attack;
            bonus.defense += bonuses[i].defense;
        }
        return bonus;
    }

    function getBonuses(
        ITournamentV4.Game memory game,
        uint256 random,
        uint256[] memory factionBonuses,
        ITournamentV4.GameGladiator memory gladiator,
        bool isAttacker
    ) internal view returns (Bonus memory bonus) {
        Bonus[] memory bonuses = new Bonus[](2);
        bonuses[0] = factionBonus(game, factionBonuses, gladiator);
        bonuses[1] = equipmentBonuses(gladiator, random, isAttacker);
        return concatBonuses(bonuses);
    }

    function getRoll(
        ITournamentV4.Game memory game,
        IDiceRolls.RollParams memory roll,
        uint256[] memory factionBonuses,
        uint256 lastWinner
    ) public view returns (RollReturn memory) {
        // console.log('bonus length', bonuses.lenth, 'random: ', roll.random );
        uint256 random = roll.random;
        // console.log("random: (gameid, random) ", game.id, random);

        // first we roll a d3
        // 0 means player 1 is attacker
        // 1 means player 2 is attacker
        // 2 means last player to win is attacker
        uint256 d3 = random.mod(3);
        uint256 attacker = d3;
        if (attacker == 2) {
            attacker = lastWinner;
        }
        // console.log('attacker', attacker);
        uint256 defender = (attacker + 1).mod(game.players.length);

        ITournamentV4.GameGladiator memory attackGladiator =
            game.players[attacker];
        ITournamentV4.GameGladiator memory defendGladiator =
            game.players[defender];

        // console.log("attack/defense gladiator: ", attackGladiator.id, defendGladiator.id);

        uint256 attackRandom =
            uint256(keccak256(abi.encodePacked(attackGladiator.id, random)));
        uint256 defenseRandom =
            uint256(keccak256(abi.encodePacked(defendGladiator.id, random)));

        // console.log('attack/defense random', random, attackRandom, defenseRandom);

        Bonus memory attackBonus =
            getBonuses(
                game,
                attackRandom,
                factionBonuses,
                attackGladiator,
                true
            );
        Bonus memory defenseBonus =
            getBonuses(
                game,
                defenseRandom,
                factionBonuses,
                defendGladiator,
                false
            );

        // console.log('attackGladiator: ', attackGladiator.faction, 'bonus', bonuses[0]);
        // console.log("bonus: (attack,defend): ", bonuses[game.factions[attacker]], bonuses[game.factions[defender]]);
        int256 attackRoll = int256(attackRandom.mod(attackGladiator.attack));
        int256 defenseRoll = int256(defenseRandom.mod(defendGladiator.defense));

        attackRoll += attackBonus.attack;
        defenseRoll += defenseBonus.defense;

        return
            RollReturn({
                attacker: attacker,
                defender: defender,
                attackRoll: attackRoll,
                defenseRoll: defenseRoll,
                attackHpAddition: attackBonus.hitPoints,
                defenseHpAddition: defenseBonus.hitPoints
            });
    }

    // TODO: this is a hacky repeat of roll below, but for now it suffices
    function blowByBlow(
        ITournamentV4.Game memory game,
        IDiceRolls.RollParams[] memory rolls
    ) public view returns (Narrative[] memory narratives) {
        narratives = new Narrative[](rolls.length);
        // console.log("blow by blow: ", game.id, rolls.length);
        uint256 lastWinner = 0;
        IDiceRolls.RollParams memory previousRoll;

        // set it up as 0
        uint256[] memory factionBonuses =
            new uint256[](rolls[0].performances.length);

        for (uint256 i = 0; i < rolls.length; i++) {
            Narrative memory narrative = narratives[i];

            IDiceRolls.RollParams memory roll = rolls[i];
            if (i > 0) {
                factionBonuses = getFactionBonuses(
                    rolls[i - 1].performances,
                    roll.performances
                );
            }

            RollReturn memory rollResult =
                getRoll(game, roll, factionBonuses, lastWinner);

            int256 attackRoll = rollResult.attackRoll;
            int256 defenseRoll = rollResult.defenseRoll;
            uint256 attacker = rollResult.attacker;
            uint256 defender = rollResult.defender;

            narrative.attacker = game.players[attacker].id;
            narrative.defender = game.players[defender].id;
            narrative.attackRoll = attackRoll;
            narrative.defenseRoll = defenseRoll;

            narrative.attackFactionBonus = int256(
                factionBonuses[game.players[attacker].faction]
            );
            narrative.defenseFactionBonus = int256(
                factionBonuses[game.players[defender].faction]
            );

            narrative.attackEquipment = copyUses(
                game.players[attacker].equipmentUses
            );
            narrative.defenseEquipment = copyUses(
                game.players[defender].equipmentUses
            );

            game.players[attacker].hitPoints += rollResult.attackHpAddition;
            game.players[defender].hitPoints += rollResult.defenseHpAddition;

            narrative.attackerHP = game.players[attacker].hitPoints;
            if (attackRoll > defenseRoll) {
                // attack was successful!
                // console.log("successful attack: ");
                // console.logInt(attackRoll - defenseRoll);
                // console.logInt(game.players[defender].hitPoints);
                game.players[defender].hitPoints -= (attackRoll - defenseRoll);
                narrative.defenderHP = game.players[defender].hitPoints;
                // console.log('setting hp to');
                // console.logInt(narrative.defenderHP);
                if (game.players[defender].hitPoints <= 0) {
                    // console.log("death blow after # of rolls: ", i);
                    game.decided = true;
                    game.winner = uint8(attacker);
                    game.lastRoll = roll.id;

                    narrative.attackerIsWinner = true;
                    break;
                }
                lastWinner = attacker;
            } else {
                narrative.defenderHP = game.players[defender].hitPoints;
                lastWinner = defender;
                // console.log("defense win");
            }
        }
        return narratives;
    }

    function roll(
        ITournamentV4.Game memory game,
        IDiceRolls.RollParams[] memory rolls // use view if you enable console.log
    ) public view override returns (ITournamentV4.Game memory) {
        // console.log("roll: ", game.id, rolls.length);
        uint256 lastWinner = 0;
        IDiceRolls.RollParams memory previousRoll;

        // set it up as 0
        uint256[] memory factionBonuses =
            new uint256[](rolls[0].performances.length);

        (uint256 start, bool found) = indexOf(rolls, game.firstRoll);
        // require(found, "no first roll found in rolls");
        if (!found) {
            return game;
        }

        for (uint256 i = start; i < rolls.length; i++) {
            IDiceRolls.RollParams memory roll = rolls[i];
            if (i > 0) {
                factionBonuses = getFactionBonuses(
                    rolls[i - 1].performances,
                    roll.performances
                );
            }

            RollReturn memory rollResult =
                getRoll(game, roll, factionBonuses, lastWinner);

            int256 attackRoll = rollResult.attackRoll;
            int256 defenseRoll = rollResult.defenseRoll;

            game.players[rollResult.attacker].hitPoints += rollResult
                .attackHpAddition;
            game.players[rollResult.defender].hitPoints += rollResult
                .defenseHpAddition;

            if (attackRoll > defenseRoll) {
                // attack was successful!
                // console.log("successful attack: ", attackRoll.sub(defenseRoll));
                game.players[rollResult.defender].hitPoints -= (attackRoll -
                    defenseRoll);
                if (game.players[rollResult.defender].hitPoints <= 0) {
                    // console.log("death blow after # of rolls: ", i);
                    game.decided = true;
                    game.winner = uint8(rollResult.attacker);
                    game.lastRoll = roll.id;
                    break;
                }
                lastWinner = rollResult.attacker;
            } else {
                lastWinner = rollResult.defender;
                // console.log("defense win");
            }
        }
        return game;
    }

    // TODO: binary search
    function indexOf(IDiceRolls.RollParams[] memory rolls, uint256 id)
        internal
        view
        returns (uint256 idx, bool found)
    {
        for (idx = 0; idx < rolls.length; idx++) {
            if (rolls[idx].id == id) {
                return (idx, true);
            }
        }
        return (0, false);
    }

    function _getRound(
        ITournamentV4.GameGladiator[] memory roundPlayers,
        IDiceRolls.RollParams[] memory rolls,
        uint256 firstRollIndex
    ) internal view returns (ITournamentV4.Round memory round) {
        round.games = new ITournamentV4.Game[](roundPlayers.length.div(2));
        // console.log("fetching: ", firstRollIndex);
        if (firstRollIndex >= rolls.length) {
            uint256 gameId = 0;
            for (uint256 i; i < roundPlayers.length; i += 2) {
                ITournamentV4.Game memory game;

                ITournamentV4.GameGladiator[] memory players =
                    new ITournamentV4.GameGladiator[](2);
                players[0] = roundPlayers[i];
                players[1] = roundPlayers[i + 1];

                game.players = players;
                game.id = gameId;
                round.games[gameId] = game;
                gameId++;
            }
            return round;
        }
        uint256 firstRoll = rolls[firstRollIndex].id;
        round.firstRoll = firstRoll;

        bool lastGameIsFinished = true;

        uint256 gameId = 0;
        for (uint256 i; i < roundPlayers.length; i += 2) {
            ITournamentV4.Game memory game;

            ITournamentV4.GameGladiator[] memory players =
                new ITournamentV4.GameGladiator[](2);
            players[0] = roundPlayers[i];
            players[1] = roundPlayers[i + 1];
            // console.log("player 0: ", players[0].id);
            // console.log("player 1: ", players[1].id);

            game.players = players;
            game.id = gameId;
            if (lastGameIsFinished) {
                game.firstRoll = firstRoll;
                // console.log("calculatin game", i, game.id, firstRoll);
                // console.log(game.players.length);
                // only calculate if the last game was finished
                game = roll(game, rolls);
            }
            if (game.decided) {
                // console.log("setting firstRoll: ", game.lastRoll);
                firstRoll = game.lastRoll + 1;
                lastGameIsFinished = true;
            } else {
                lastGameIsFinished = false;
            }
            round.games[gameId] = game;
            gameId++;
        }
        if (lastGameIsFinished) {
            round.lastRoll = firstRoll - 1; // firstRoll has been updating
        }
        return round;
    }

     // TODO: binary search
    function indexOfGladiator(OriginalStats[] memory originalStats, uint256 id)
        internal
        pure
        returns (uint256 idx)
    {
        for (idx = 0; idx < originalStats.length; idx++) {
            if (originalStats[idx].id == id) {
                return idx;
            }
        }
        require(false, "should not get here");
        return 0;
    }

    function restoreGladiator(
        ITournamentV4.GameGladiator memory gladiator,
        OriginalStats[] memory originalStats
    ) internal pure returns (ITournamentV4.GameGladiator memory) {
        uint idx = indexOfGladiator(originalStats, gladiator.id);
        OriginalStats memory stats = originalStats[idx];
        gladiator.hitPoints = stats.hitPoints;
        gladiator.attack = stats.attack;
        gladiator.defense = stats.defense;
        gladiator.equipmentUses = new uint[](gladiator.equipmentUses.length);
        return gladiator;
    }

    function getWinners(
        ITournamentV4.Round memory round,
        OriginalStats[] memory originalStats
    )
        internal
        pure
        returns (ITournamentV4.GameGladiator[] memory players)
    {
        players = new ITournamentV4.GameGladiator[](round.games.length);
        for (uint256 i; i < round.games.length; i++) {
            ITournamentV4.Game memory game = round.games[i];
            require(game.decided, "Winners not decided");
            players[i] = restoreGladiator(game.players[game.winner], originalStats);
        }
        return players;
    }

    function tournamentWinner(
        uint tournamentId
    ) public view override returns (uint256 registrationId, uint256 lastRoll) {
        ITournamentV4.Round[] memory rounds = bracket(tournamentId, -1);
        ITournamentV4.Round memory round = rounds[rounds.length - 1];
        ITournamentV4.Game memory game = round.games[0];
        require(game.decided, "Tournament Not Decided");
        return (game.players[game.winner].registrationId, game.lastRoll);
    }

    function tournament(
        ITournamentV4.GameGladiator[] memory gladiators,
        IDiceRolls.RollParams[] memory rolls
    ) public view override returns (ITournamentV4.Round[] memory rounds) {
        ITournamentV4.Round memory currentRound;
        rounds = new ITournamentV4.Round[](log2(gladiators.length)); // TODO: check this math
        
        OriginalStats[] memory originalStats = new OriginalStats[](gladiators.length);
        for (uint i = 0; i < gladiators.length; i++) {
            originalStats[i] = OriginalStats({
                id: gladiators[i].id,
                hitPoints: gladiators[i].hitPoints,
                attack: gladiators[i].attack,
                defense: gladiators[i].defense
            });
        }

        for (uint256 i = 0; i < rounds.length; i++) {
            if (i == 0) {
                // console.log("round 0");
                currentRound = _getRound(gladiators, rolls, 0);
            } else {
                // console.log("round ", i);
                (uint256 start, bool found) =
                    indexOf(rolls, currentRound.lastRoll);
                require(found, "no roll found");
                currentRound = _getRound(
                    getWinners(currentRound, originalStats),
                    rolls,
                    start + 1
                );
            }
            rounds[i] = currentRound;
            if (!currentRound.games[currentRound.games.length - 1].decided) {
                break;
            }
        }

        return rounds;
    }

    function bracket(uint tournamentId, int specifiedLastRoll) public view override returns (ITournamentV4.Round[] memory rounds) {
        ITournamentV4.GameGladiator[] memory gladiators = gameGladiators(tournamentId);
        // if tournament hasn't started yet
        if (!_tournament.started(tournamentId)) {
            IDiceRolls.RollParams[] memory rolls;
            return tournament(gladiators, rolls);
        }

        IDiceRolls roller = _tournament.roller(tournamentId);
        uint firstRoll = _tournament.firstRoll(tournamentId);
        
        uint lastRoll;

        // user sends in -1 to mean "the whole tournament
        if (specifiedLastRoll < 0) {
            lastRoll = _tournament.lastRoll(tournamentId);
            if (lastRoll == 0) {
                lastRoll = roller.latest();
            }
        } else {
            lastRoll = uint(specifiedLastRoll);
        }
        
        return tournament(gladiators, roller.getRange(firstRoll, lastRoll));
    }


    // Gladiator stuff

    function getGladiator(
        uint256 registrationId,
        uint256 tournamentId,
        ITournamentV4.Registration memory reg
    ) internal view returns (ITournamentV4.GameGladiator memory gladiator) {
        uint256 id = reg.gladiator;
        gladiator.id = id;
        gladiator.faction = reg.faction;
        gladiator.registrationId = registrationId;
        gladiator.name = _gladiators.name(id);
        gladiator.hitPoints = int256(_gladiators.getProperty(id, HIT_POINTS));
        gladiator.attack = uint256(_gladiators.getProperty(id, ATTACK));
        gladiator.defense = uint256(_gladiators.getProperty(id, DEFENSE));
        gladiator.equipment = equipper.gladiatorEquipment(tournamentId, id);
        gladiator.equipmentUses = new uint256[](gladiator.equipment.length);
        return gladiator;
    }

    function gameGladiators(uint256 tournamentId)
        public
        view
        returns (ITournamentV4.GameGladiator[] memory gladiators)
    {
        ITournamentV4.Registration[] memory registrations = _tournament.registrations(tournamentId);
        return _gameGladiators(tournamentId, registrations);
    }

    function _gameGladiators(
        uint256 tournamentId,
        ITournamentV4.Registration[] memory registrations
    ) internal view returns (ITournamentV4.GameGladiator[] memory gladiators) {
        gladiators = new ITournamentV4.GameGladiator[](registrations.length);
        for (uint256 i; i < registrations.length; i++) {
            gladiators[i] = getGladiator(i, tournamentId, registrations[i]);
        }
        return gladiators;
    }
    
 // see: https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity
    function log2(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(
                m,
                0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
            )
            mstore(
                add(m, 0x20),
                0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
            )
            mstore(
                add(m, 0x40),
                0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
            )
            mstore(
                add(m, 0x60),
                0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
            )
            mstore(
                add(m, 0x80),
                0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
            )
            mstore(
                add(m, 0xa0),
                0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
            )
            mstore(
                add(m, 0xc0),
                0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
            )
            mstore(
                add(m, 0xe0),
                0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
            )
            mstore(0x40, add(m, 0x100))
            let
                magic
            := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let
                shift
            := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(
                y,
                mul(
                    256,
                    gt(
                        arg,
                        0x8000000000000000000000000000000000000000000000000000000000000000
                    )
                )
            )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./interfaces/ITournamentV4.sol";
import "./interfaces/IDiceRolls.sol";
import "./Assets.sol";
import "./interfaces/IGameEquipment.sol";

import "hardhat/console.sol";

contract Equipper is ERC1155Receiver {
    using SafeMath for uint256;

    IGameEquipment public immutable equipment;
    ITournamentV4 private immutable _tournament;
    Assets private immutable _assets; // ERC-1155 Assets contract

    constructor(
        address equipmentContract,
        address tournamentContractAddress,
        address assetsContract
    ) {
        equipment = IGameEquipment(equipmentContract);
        _tournament = ITournamentV4(tournamentContractAddress);
        _assets = Assets(assetsContract);
    }

    mapping(uint256 => mapping(uint256 => IGameEquipment.EquipmentMetadata[]))
        public equippings; // tournamentId => gladiatorId => array of equipment

    function gladiatorEquipment(uint256 tournamentId, uint256 gladiatorId)
        public
        view
        returns (IGameEquipment.EquipmentMetadata[] memory)
    {
        return equippings[tournamentId][gladiatorId];
    }

    function handleEquipment(
        address,
        uint256 id,
        uint256 value,
        bytes calldata data // abi encoded uint256,uint256 tournamentId, gladiatorId
    ) internal returns (bool) {
        // TODO: allow fungible equipment
        require(
            value == 1,
            "Equipper#onERC1155BatchReceived: may only add one equipment at a time"
        );

        (uint256 tournamentId, uint256 gladiatorId) =
            abi.decode(data, (uint256, uint256));

        require(
            !_tournament.started(tournamentId),
            "Equipper#No equippings after tournament start"
        );
        require(
            equippings[tournamentId][gladiatorId].length < 3,
            "Equipper#Only 3 Equippings per gladiator per tournament"
        );

        equippings[tournamentId][gladiatorId].push(equipment.getMetadata(id));
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;
        onERC1155BatchReceived(operator, from, ids, values, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data // abi.encoded (uint256 tournamentId, uint16 faction)
    ) public override returns (bytes4) {
        require(
            msg.sender == address(_assets),
            "Tournament#onERC1155BatchReceived: invalid asset address"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            if (_assets.exists("equipment", ids[i])) {
                require(
                    handleEquipment(from, ids[i], values[i], data),
                    "error handling equipment"
                );
                continue; // stop processing hr
            }
            revert("Unknown token type");
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./Assets.sol";
import "./Trophy.sol";
import "./Gladiator.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./Constants.sol";
import "./interfaces/IGameLogicV4.sol";
import "./interfaces/IDiceRolls.sol";
import "./interfaces/ITournamentV4.sol";

import "hardhat/console.sol";

contract TournamentV4 is
    ITournamentV4,
    Ownable,
    IRegisterableAsset
{
    using SafeMath for uint256;

    bytes32 constant ASSET_NAME = "TournamentV4";
    uint256 constant TOTAL_SUPPLY = 2**38;
    uint256 constant ASSET_DECIMALS = 10**18;

    bytes32 constant HIT_POINTS = "hitpoints";
    bytes32 constant ATTACK = "attack";
    bytes32 constant DEFENSE = "defense";
    bytes32 constant NAME = "name";

    mapping(uint256 => TournamentData) private _tournaments;

    Assets private immutable _assets; // ERC-1155 Assets contract
    Gladiator private immutable _gladiator; // gladiator transfers
    Trophy public immutable trophies; // trophies minting

    bytes32 private immutable _gladiatorAssetName; 

    modifier onlyApproved(uint256 tournamentId) {
        require(
            _assets.isApprovedOrOwner(_msgSender(), _msgSender(), tournamentId),
            "Tournament: not an owner of the tournament"
        );
        _;
    }

    constructor(address _assetsAddress, address _gladiatorAddress) {
        require(
            _assetsAddress != address(0),
            "Tournament#constructor: INVALID_INPUT _assetsAddress is 0"
        );
        _assets = Assets(_assetsAddress);
        _gladiator = Gladiator(_gladiatorAddress);
        trophies = new Trophy(_assetsAddress, bytes32("TrophyV4"));
        _gladiatorAssetName = Gladiator(_gladiatorAddress).assetName();
    }

    function assetName() public pure override returns (bytes32) {
        return ASSET_NAME;
    }

    function assetTotalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function assetIsNFT() public pure override returns (bool) {
        return true;
    }

    function assetOperators() public view override returns (address[] memory) {
        address[] memory operators = new address[](1);
        operators[0] = address(this);
        return operators;
    }

    function idRange() public view returns (uint256, uint256) {
        return _assets.idRange(ASSET_NAME);
    }

    function newTournament(
        string memory name,
        address gameLogic_,
        address roller_,
        uint8 totalRounds,
        uint256 notBefore,
        string[] memory factions
    ) public onlyOwner returns (uint256) {
        require(
            factions.length <= 65536,
            "Tournament#newTournament: Can only have 65536 factions"
        );

        address creator = _msgSender();

        uint256[] memory ids = _assets.mint(creator, ASSET_NAME, 1, "");
        uint256 tournamentId = ids[0];

        TournamentData storage tournament = _tournaments[tournamentId];
        tournament.name = name;
        tournament.creator = creator;
        tournament.totalRounds = totalRounds;
        tournament.factions = factions;
        tournament.gameLogic = IGameLogicV4(gameLogic_);
        tournament.notBefore = notBefore;
        tournament.roller = IDiceRolls(roller_);
        emit NewTournament(creator, notBefore, tournamentId);
        return tournamentId;
    }

    function registerGladiator(TournamentData storage tournament, uint tournamentId, uint id, uint16 faction) internal {
        require(
            faction < tournament.factions.length,
            "Tournament#onERC1155BatchReceived: faction does not exist"
        );
        require(_assets.exists(_gladiatorAssetName, id), "Tournament#Not a gladiator");

        tournament.registrations.push(
            Registration({gladiator: id, faction: faction})
        );
        emit RegistrationEvent(
            tournamentId,
            id,
            faction,
            tournament.registrations.length - 1
        );
    }

    function registerGladiators(uint tournamentId, uint[] calldata ids, uint16[] calldata factions) onlyOwner public {
        TournamentData storage tournament = _tournaments[tournamentId];

        require(
            tournament.totalRounds > 0,
            "Tournament#onERC1155BatchReceived: tournament does not exist"
        );
        require(
            !started(tournamentId),
            "Tournament#onERC1155BatchReceived: tournament already started"
        );
        require(
            tournament.registrations.length + ids.length <= this.maxGladiators(tournamentId),
            "Tournament#onERC1155BatchReceived: registration closed"
        );

        for (uint i; i < ids.length; i++) {
            registerGladiator(tournament, tournamentId, ids[i], factions[i]);
        }
    }

    function name(uint256 tournamentId) external view returns (string memory) {
        return _tournaments[tournamentId].name;
    }

    function firstRoll(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].firstRoll;
    }

    function notBefore(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].notBefore;
    }

    function lastRoll(uint256 tournamentId)
        external
        view
        override
        returns (uint256)
    {
        return _tournaments[tournamentId].lastRoll;
    }

    function roller(uint256 tournamentId)
        external
        view
        override
        returns (IDiceRolls)
    {
        return _tournaments[tournamentId].roller;
    }

    function started(uint256 tournamentId) public override view returns (bool) {
        TournamentData storage tournament = _tournaments[tournamentId];
        // console.log('first role', tournament.firstRoll, 'latest', latest);
        uint256 _firstRoll = tournament.firstRoll;
        return _firstRoll > 0 && _firstRoll <= tournament.roller.latest();
    }

    function totalRounds(uint256 tournamentId) external view returns (uint256) {
        return _tournaments[tournamentId].totalRounds;
    }

    function maxGladiators(uint256 tournamentId)
        external
        view
        returns (uint256)
    {
        return 2**uint256(_tournaments[tournamentId].totalRounds);
    }

    function registrationCount(uint256 tournamentId)
        external
        view
        returns (uint256)
    {
        return _tournaments[tournamentId].registrations.length;
    }

    function registration(uint256 tournamentId, uint256 registrationId)
        external
        view
        returns (Registration memory)
    {
        return _tournaments[tournamentId].registrations[registrationId];
    }

    function registrations(uint256 tournamentId)
        external
        view
        override
        returns (Registration[] memory)
    {
        TournamentData storage tournament = _tournaments[tournamentId];
        return tournament.registrations;
    }

    function factions(uint256 tournamentId)
        external
        view
        returns (string[] memory)
    {
        TournamentData storage tournament = _tournaments[tournamentId];
        return tournament.factions;
    }

    function start(uint256 tournamentId) external {
        TournamentData storage tournament = _tournaments[tournamentId];
        require(
            block.timestamp > tournament.notBefore,
            "Tournament cannot start yet"
        );
        tournament.firstRoll = tournament.roller.latest().add(1);
    }

    function checkpoint(uint256 tournamentId) external {
        TournamentData storage tournament = _tournaments[tournamentId];

        (uint256 winner, uint256 tournamentLastRoll) =
            tournament.gameLogic.tournamentWinner(tournamentId);

        tournament.lastRoll = tournamentLastRoll;

        createTrophy(tournamentId, tournament, winner);
    }

    function createTrophy(
        uint256 tournamentId,
        TournamentData storage tournament,
        uint256 winnerId
    ) internal {
        Registration memory winner = tournament.registrations[winnerId];

        uint256 trophyId =
            trophies.mint(
                address(_gladiator),
                tournament.name,
                tournamentId,
                winner.gladiator
            );

        _assets.mint(
            address(_gladiator),
            Constants.prestigeAssetName(),
            10 * ASSET_DECIMALS,
            abi.encodePacked(winner.gladiator)
        );

        tournament.champion.faction = winner.faction;
        tournament.champion.gladiator = winner.gladiator;
        tournament.champion.trophy = trophyId;

        emit TournamentComplete(tournamentId, winner.gladiator);
    }

    function getChampion(uint256 tournamentId)
        public
        view
        returns (Champion memory)
    {
        TournamentData storage tournament = _tournaments[tournamentId];
        require(tournament.lastRoll > 0, "Tournament is still in progress");
        return tournament.champion;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./EnumerableMap.sol";
import "./meta/EIP712MetaTransaction.sol";

import "hardhat/console.sol";

contract Trophy is Ownable, IRegisterableAsset, EIP712MetaTransaction {
  using SafeMath for uint256;
  using EnumerableMap for EnumerableMap.Map;

  bytes32 immutable ASSET_NAME;
  uint256 constant TOTAL_SUPPLY = 2**38;

  IAssets immutable public assets;

  struct Metadata {
    string name;
    EnumerableMap.Map properties;
  }

  mapping(uint256 => Metadata) private _metadata;

  constructor(
    address assetsAddress,
    bytes32 name
   ) public EIP712MetaTransaction("Trophy", "1") {
    assets = IAssets(assetsAddress);
    ASSET_NAME = name;
  }

  function assetName() override public view returns (bytes32) {
    return ASSET_NAME;
  }

  function assetTotalSupply() override public pure returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function assetIsNFT() override public pure returns (bool) {
    return true;
  }

  function assetOperators() override public view returns (address[] memory) {
    address[] memory operators = new address[](1);
    operators[0] = address(this);
    return operators;
  }

  function idRange() public view returns (uint256, uint256) {
    return assets.idRange(ASSET_NAME);
  }

  function mint(
    address account,
    string  memory name,
    uint256 tournamentID,
    uint256 gladiatorID
  ) external onlyOwner returns (uint256) {
    uint256[] memory ids = assets.mint(account, ASSET_NAME, 1, abi.encodePacked(gladiatorID));
    uint256 id = ids[0];

    Metadata storage metadata = _metadata[id];
    metadata.name = name;
 
    EnumerableMap.Map storage _properties = metadata.properties;

    _properties.set("tournamentID", bytes32(tournamentID));
    _properties.set("gladiatorID", bytes32(gladiatorID));
    _properties.set("createdAt", bytes32(block.timestamp));

    return id;
  }

  function exists(
    uint256 id
  ) external view returns (bool) {
    return assets.exists(ASSET_NAME, id);
  }

  function name(
    uint256 id
  ) external view returns (string memory) {
    return _metadata[id].name;
  }

  function properties(
    uint256 id
  ) external view returns (EnumerableMap.MapEntry[] memory) {
    EnumerableMap.Map storage _properties = _metadata[id].properties;
    uint256 propsLength = _properties.length(); 
    EnumerableMap.MapEntry[] memory propertyPairs = new EnumerableMap.MapEntry[](propsLength);
    for (uint256 i = 0; i < propsLength; i++) {
      (bytes32 k, bytes32 v) = _properties.at(i);
      propertyPairs[i].key = k;
      propertyPairs[i].value = v;
    }
    return propertyPairs;
  }

  function getProperty(
    uint256 id,
    bytes32 key
  ) external view returns (bytes32) {
    EnumerableMap.Map storage _properties = _metadata[id].properties;
    return _properties.get(key);
  }

  function _msgSender() internal view override(Context,EIP712MetaTransaction) returns (address payable) {
    return EIP712MetaTransaction.msgSender();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./Assets.sol";
import "./TournamentV4.sol";
import "./Constants.sol";

import "hardhat/console.sol";

// only calling this with the 5 because otherwise there's a build error conflicting with BettingPoolV4
interface IFaction5 {
    function byName(string calldata name) external returns (uint);
}

contract BettingPoolV6 is ERC1155Receiver, Ownable {
  using SafeMath for uint256;

  event BetPlaced(address indexed better, uint indexed tournamentId, uint indexed gladiatorId);

  uint256 constant private oneHundredPercent = 10**10;

  Assets immutable private _assets; // ERC-1155 Assets contract
  TournamentV4 immutable private _tournaments; // ERC-1155 Assets contract
  IFaction5 immutable private _faction;
  address immutable private _gladiatorContract;

  uint immutable private _prestigeId;

  uint8 public multiplier;
  uint8 public gladiatorPercent;

  mapping(uint256 => mapping(address => mapping(uint => uint))) public betsByUser;  //tournamentID => user => gladiator => amount
  mapping(uint256 => mapping(address => uint8)) public betCountByUser; // tournamentID => user => count; // only allow 2 bets per user
  mapping(uint256 => mapping(uint => uint)) public betsByGladiator; // tournamentID => gladiatorId => totalAmount
  mapping(uint256 => uint) public betsByTournament; // tournamentID => totalAmount

  mapping(uint256 => uint256) public incentivesByTournament; // tournamentID => amount of incentive

  mapping(uint256 => bool) private _claimedByGladiator; // tournamentID => true/false if already claimed by gladiator

  constructor(
    address _assetsAddress,
    address _tournamentAddress,
    address _gladiatorAddress,
    address _factionAddress
  ) {
    require(
      _assetsAddress != address(0),
      "BettingPool#constructor: INVALID_INPUT _assetsAddress is 0"
    );
    Assets assetContract = Assets(_assetsAddress);
    _assets = assetContract;
    _tournaments = TournamentV4(_tournamentAddress);
    (uint start,) = assetContract.idRange(Constants.prestigeAssetName());
    _prestigeId = start;
    gladiatorPercent = 20;
    _gladiatorContract = _gladiatorAddress;
    _faction = IFaction5(_factionAddress);
  }

  function setIncentive(uint256 tournamentId, uint256 amount) external onlyOwner {
    incentivesByTournament[tournamentId] = amount;
  }

  function setGladiatorPercent(uint8 percent) external onlyOwner {
    gladiatorPercent = percent;
  }

  function expectedWinnings(uint tournamentId, address user, uint champion) public view returns (uint) {
    uint bet = betsByUser[tournamentId][user][champion];
    if (bet == 0) {
      return 0;
    }

    // calculate their percentage of all the *winners* of the tournament (those that picked the right gladiator)
    // percent calculated as 10 digits (10^10 is 100%);
    uint percentOfPool = (bet * oneHundredPercent).div(betsByGladiator[tournamentId][champion]);
    
    return betsByTournament[tournamentId].sub(gladiatorWinnings(tournamentId)).add(incentivesByTournament[tournamentId]).mul(percentOfPool).div(oneHundredPercent);
  }

  function withdraw(uint tournamentId) external returns (bool) {
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);
    uint champion = winner.gladiator;

    address user = msg.sender;

    uint winnings = expectedWinnings(tournamentId, user, champion);
    require(winnings > 0, "BettingPool#You didn't win");
    
    delete betsByUser[tournamentId][user][champion];
    delete betCountByUser[tournamentId][user];
    _assets.safeTransferFrom(address(this), user, _prestigeId, winnings, '');
    return true;
  }

  function gladiatorWinnings(uint tournamentId) internal view returns (uint) {
    return betsByTournament[tournamentId].mul(gladiatorPercent).div(100);
  }

  function claimForGladiator(uint tournamentId) external returns (bool) {
    require(!_claimedByGladiator[tournamentId], "Gladiators winnings already claimed");
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);

    string memory factionName = _tournaments.factions(tournamentId)[winner.faction];
    uint factionID = _faction.byName(factionName);
    
    uint winnings = gladiatorWinnings(tournamentId);

    if (factionID > 0) {
      uint factionWinnings = winnings.mul(25).div(100);
      _assets.safeTransferFrom(address(this), address(_faction), _prestigeId, winnings, abi.encode(factionID));
      winnings = winnings.sub(factionWinnings);
    }

    // console.log('winnings', winnings);
    _claimedByGladiator[tournamentId] = true;
    _assets.safeTransferFrom(address(this), _gladiatorContract, _prestigeId, winnings, abi.encode(winner.gladiator));
    return true;
  }

  function migrate(address payable newAddress) external onlyOwner {
    // move all ptg to the new address and destroy this contract
    uint balance = _assets.balanceOf(address(this), _prestigeId);
    _assets.safeTransferFrom(address(this), newAddress, _prestigeId, balance, '');
    selfdestruct(newAddress);
  }

  // This adds two features from BettingPoolV5
  // 1. it lets you bet *for* someone else (will be useful for other smart contracts)
  // 2. It handles the 'bet checker' by having the expected total bet as part of the data... making the transactions idempotent.
  function onERC1155Received(
    address, // operator
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    require(msg.sender == address(_assets), "BettingPool#onERC1155Received: invalid asset address");
    require(id == _prestigeId, "BettingPool#Invalid token send");
    if (from == address(0)) {
      // this is a MINT so just accept it
      return IERC1155Receiver.onERC1155Received.selector;
    }

    (address onBehalfOf, uint256 tournamentId, uint256 gladiatorId, uint256 expectedTotal) = abi.decode(data, (address, uint256, uint256, uint256));
    // console.log("bet!", tournamentId, gladiatorId, from);
    require(!_tournaments.started(tournamentId), "BettingPool#Tournament already started");

    // if this is a *new* bet on the tournament then increase the count
    // but allow unlimited increases in your betting;
    if (betsByUser[tournamentId][onBehalfOf][gladiatorId] == 0) {
      require(betCountByUser[tournamentId][from] < 2, "BettingPool#Too many bets");
      betCountByUser[tournamentId][onBehalfOf] += 1; 
    }
    betsByUser[tournamentId][onBehalfOf][gladiatorId] += value;
    require(betsByUser[tournamentId][onBehalfOf][gladiatorId] == expectedTotal, "Unexpected bet amount");

    betsByGladiator[tournamentId][gladiatorId] += value;
    betsByTournament[tournamentId] += value;
    
    emit BetPlaced(onBehalfOf, tournamentId, gladiatorId);

    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes calldata
  ) pure public override returns(bytes4) {
    revert("BettingPool#No batch allowed");
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAssets.sol";
import "./Constants.sol";

import "hardhat/console.sol";

contract FactionV5 is ERC721, ERC1155Receiver, AccessControl {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.UintSet;
  using Counters for Counters.Counter;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  IAssets immutable public assets;
  
  Counters.Counter private _tokenIds;

  mapping(string => uint256) public byName;
  mapping(uint256 => string) public names;

  mapping(uint256 => EnumerableSet.UintSet) private _inventory;

  mapping(uint256 => mapping(uint256 => uint256)) private _balances;

  constructor(address assetsAddress) ERC721("Crypto Colosseum Faction", "CCFACT") {
    assets = IAssets(assetsAddress);
    _setBaseURI("https://arena.cryptocolosseum.com/721/");
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(
    address account,
    string calldata name
  ) external returns (uint256) {
    require(hasRole(MINTER_ROLE, msg.sender), 'missing role');
    require(byName[name] == 0, "Name already taken");

    _tokenIds.increment();
    uint256 id = _tokenIds.current();
    _safeMint(account, id);

    byName[name] = id;
    names[id] = name;

    return id;
  }

  function exists(
    uint256 id
  ) public view returns (bool) {
    return _exists(id);
  }

  function prestige(
    uint256 id
  ) external view returns (uint256) {
    (uint256 prestigeTokenID,) = assets.idRange(Constants.prestigeAssetName());
    return _balances[id][prestigeTokenID];
  }

  function inventory(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ids = new uint256[](set.length());
    for (uint256 i = 0; i < ids.length; i++) {
      ids[i] = set.at(i);
    }
    return ids;
  }

  function balances(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ret = new uint256[](set.length());
    for (uint256 i = 0; i < ret.length; i++) {
      ret[i] = _balances[id][set.at(i)];
    }
    return ret;
  }

  function balanceOf(
    uint256 id,
    uint256 tokenID
  ) external view returns (uint256) {
    return _balances[id][tokenID];
  }

  function transferInventory(
    uint factionId,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public {
    address sender = msg.sender;
    require(_isApprovedOrOwner(sender, factionId), "You must own the the faction to transfer balances");
    uint bal = _balances[factionId][id];
    _balances[factionId][id] = bal.sub(amount); // this will error if the sub doesn't go through.
    assets.safeTransferFrom(address(this), to, id, amount, data);
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory values = new uint256[](1);
    ids[0] = id;
    values[0] = value;
    onERC1155BatchReceived(operator, from, ids, values, data);
    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes calldata data // abi.encoded (uint256 factionId)
  ) public override returns(bytes4) {
    require(msg.sender == address(assets), "Faction can only receive items from Assets contract");

    (uint256 factionId) = abi.decode(data, (uint256));
    require(exists(factionId), "faction does not exist");

    EnumerableSet.UintSet storage factionInventory = _inventory[factionId];
    for (uint i = 0; i < ids.length; i++) {
      factionInventory.add(ids[i]);
      _balances[factionId][ids[i]] += values[i];
    }

    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssets.sol";
import "./meta/EIP712MetaTransaction.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";

import "hardhat/console.sol";

/**
This is a contract that sells Assets (equipment). Right now it just mints them without any care about the total supply.
Next feature after would be maintaining rarity.

You register an asset for sale, it will then mint and transfer an asset to the sender
 */
contract VendingMachine is Ownable, EIP712MetaTransaction, ERC1155Receiver {
    using SafeMath for uint256;

    uint256 private immutable _prestigeID; // id of the prestige token
    IAssets public immutable assets;

    event ItemForSale(uint256 indexed id, uint256 indexed price);
    event ItemRemoved(uint256 indexed id);

    mapping(uint256 => uint256) public itemsForSale; // mapping of assetId to price

    constructor(address assetsAddress, uint256 prestigeID)
        public
        EIP712MetaTransaction("VendingMachine", "1")
    {
        _prestigeID = prestigeID;
        assets = IAssets(assetsAddress);
    }

    function sellItem(uint id, uint price) external onlyOwner {
      itemsForSale[id] = price;
      emit ItemForSale(id, price);
    }

    function stopSellingItem(uint id) external onlyOwner {
      delete itemsForSale[id];
      emit ItemRemoved(id);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // abi.encoded (uint256 itemID)
    ) external override returns (bytes4) {
        require(
            msg.sender == address(assets),
            "VendingMachine#onERC1155BatchReceived: invalid asset address"
        );
        require(id == _prestigeID, "VendingMachine#OnlySupportsPrestige");
        uint256 itemId = abi.decode(data, (uint256));
        uint256 price = itemsForSale[itemId];
        require(price > 0, "VendingMachine#ItemNotForSale");
        require(value == price, "VendingMachine#NotEnoughPrestige");

        // if it is enough then mint it and send it
        require(assets.forge(from, itemId, 1, ""), "VendingMachine#ForgeFailed");

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) public override returns (bytes4) {
        revert("Batch not supported");
    }

    function _msgSender()
        internal
        view
        override(Context, EIP712MetaTransaction)
        returns (address payable)
    {
        return EIP712MetaTransaction.msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./EnumerableMap.sol";
import "./EnumerableStringMap.sol";
import "./Constants.sol";

import "hardhat/console.sol";

contract Faction is IRegisterableAsset, ERC1155Receiver {
  using SafeMath for uint256;
  using EnumerableMap for EnumerableMap.Map;
  using EnumerableStringMap for EnumerableStringMap.Map;
  using EnumerableSet for EnumerableSet.UintSet;

  bytes32 constant ASSET_NAME = "faction";
  uint256 constant TOTAL_SUPPLY = 2**24;

  uint256 constant ASSET_DECIMALS = 10**18;

  IAssets immutable public assets;

  // A little oddly but these are stored as the id +1 which is why this is private
  // this allows us to check for existence by looking at 0 which otherwise we could not (since 0 is a valid token id)
  mapping(string => uint256) private _byName; // name => id of token + 1

  struct Metadata {
    string name;
    EnumerableMap.Map properties;
    EnumerableStringMap.Map extendedProperties;
  }

  mapping(uint256 => Metadata) private _metadata;

  mapping(uint256 => EnumerableSet.UintSet) private _inventory;

  mapping(uint256 => mapping(uint256 => uint256)) private _balances;

  constructor(address assetsAddress) {
    assets = IAssets(assetsAddress);
  }

  function byName(string calldata name) public view returns (uint id) {
    id = _byName[name];
    if (id == 0) {
      return id;
    }
    return id - 1;
  }

  function assetName() override public pure returns (bytes32) {
    return ASSET_NAME;
  }

  function assetTotalSupply() override public pure returns (uint256) {
    return TOTAL_SUPPLY;
  }

  function assetIsNFT() override public pure returns (bool) {
    return true;
  }

  function assetOperators() override public view returns (address[] memory) {
    address[] memory operators = new address[](1);
    operators[0] = address(this);
    return operators;
  }

  function idRange() public view returns (uint256, uint256) {
    return assets.idRange(ASSET_NAME);
  }

  function mint(
    address account,
    string calldata name,
    EnumerableMap.MapEntry[] calldata properties,
    EnumerableStringMap.MapEntry[] calldata extendedProperties
  ) external returns (uint256) {
    require(_byName[name] == 0, "Name already taken");

    uint256[] memory ids = assets.mint(account, ASSET_NAME, 1, "");
    uint256 id = ids[0];

    Metadata storage metadata = _metadata[id];
    metadata.name = name;

    EnumerableMap.Map storage _properties = metadata.properties;
    EnumerableStringMap.Map storage _extendedProperties = metadata.extendedProperties;

    for (uint i; i < properties.length; i++) {
      _properties.set(properties[i].key, properties[i].value);
    }

    for (uint i; i < extendedProperties.length; i++) {
      _extendedProperties.set(extendedProperties[i].key, extendedProperties[i].value);
    }

    _properties.set("createdAt", bytes32(block.timestamp));

    _byName[name] = id + 1;

    return id;
  }

  function exists(
    uint256 id
  ) public view returns (bool) {
    return assets.exists(ASSET_NAME, id);
  }

  function name(
    uint256 id
  ) external view returns (string memory) {
    return _metadata[id].name;
  }

  function prestige(
    uint256 id
  ) external view returns (uint256) {
    (uint256 prestigeTokenID,) = assets.idRange(Constants.prestigeAssetName());
    return _balances[id][prestigeTokenID];
  }

  function properties(
    uint256 id
  ) external view returns (EnumerableMap.MapEntry[] memory) {
    EnumerableMap.Map storage _properties = _metadata[id].properties;
    uint256 propsLength = _properties.length(); 
    EnumerableMap.MapEntry[] memory propertyPairs = new EnumerableMap.MapEntry[](propsLength);
    for (uint256 i = 0; i < propsLength; i++) {
      (bytes32 k, bytes32 v) = _properties.at(i);
      propertyPairs[i] = EnumerableMap.MapEntry({
        key: k,
        value: v
      });
    }
    return propertyPairs;
  }

  function getProperty(
    uint256 id,
    bytes32 key
  ) external view returns (bytes32) {
    return _metadata[id].properties.get(key);
  }
  
  function extendedProperties(
    uint256 id
  ) external view returns (EnumerableStringMap.MapEntry[] memory) {
    EnumerableStringMap.Map storage _extendedProperties = _metadata[id].extendedProperties;
    uint256 propsLength = _extendedProperties.length(); 
    EnumerableStringMap.MapEntry[] memory propertyPairs = new EnumerableStringMap.MapEntry[](propsLength);
    for (uint256 i = 0; i < propsLength; i++) {
      (bytes32 k, string memory v) = _extendedProperties.at(i);
      propertyPairs[i] = EnumerableStringMap.MapEntry({
        key: k,
        value: v
      });
    }
    return propertyPairs;
  }

  function getExtendedProperty(
    uint256 id,
    bytes32 key
  ) external view returns (string memory) {
    return _metadata[id].extendedProperties.get(key);
  }

  function inventory(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ids = new uint256[](set.length());
    for (uint256 i = 0; i < ids.length; i++) {
      ids[i] = set.at(i);
    }
    return ids;
  }

  function balances(
    uint256 id
  ) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage set = _inventory[id];
    uint256[] memory ret = new uint256[](set.length());
    for (uint256 i = 0; i < ret.length; i++) {
      ret[i] = _balances[id][set.at(i)];
    }
    return ret;
  }

  function balanceOf(
    uint256 id,
    uint256 tokenID
  ) external view returns (uint256) {
    return _balances[id][tokenID];
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    uint256[] memory ids = new uint256[](1);
    uint256[] memory values = new uint256[](1);
    ids[0] = id;
    values[0] = value;
    onERC1155BatchReceived(operator, from, ids, values, data);
    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes calldata data // abi.encoded (uint256 gladiatorID)
  ) public override returns(bytes4) {
    require(msg.sender == address(assets), "Gladiator can only receive items from Assets contract");

    (uint256 gladiatorID) = abi.decode(data, (uint256));
    require(exists(gladiatorID), "gladiator does not exist");

    EnumerableSet.UintSet storage gladiatorInventory = _inventory[gladiatorID];
    for (uint i = 0; i < ids.length; i++) {
      gladiatorInventory.add(ids[i]);
      _balances[gladiatorID][ids[i]] += values[i];
    }

    return IERC1155Receiver.onERC1155BatchReceived.selector;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IRegisterableAsset.sol";
import "./EnumerableMap.sol";
import "./meta/EIP712MetaTransaction.sol";
import "./interfaces/IGameEquipment.sol";

import "hardhat/console.sol";

contract Equipment is Ownable, IRegisterableAsset, IGameEquipment, EIP712MetaTransaction {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.Map;

    bytes32 constant ASSET_NAME = "equipment";
    uint256 constant TOTAL_SUPPLY = 2**40;

    IAssets public immutable assets;

    mapping(uint256 => EquipmentMetadata) public metadata;

    constructor(address assetsAddress)
        public
        EIP712MetaTransaction("Equipment", "1")
    {
        assets = IAssets(assetsAddress);
    }

    function assetName() public view override returns (bytes32) {
        return ASSET_NAME;
    }

    function assetTotalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function assetIsNFT() public pure override returns (bool) {
        return true;
    }

    function assetOperators() public view override returns (address[] memory) {
        address[] memory operators = new address[](2);
        operators[0] = address(this);
        operators[1] = owner();
        return operators;
    }

    function idRange() public view returns (uint256, uint256) {
        return assets.idRange(ASSET_NAME);
    }

    function getMetadata(uint id) public override view returns (EquipmentMetadata memory equipment) {
        equipment = metadata[id];
        equipment.id = id;
        return equipment;
    }

    function mint(
        address account,
        string memory name,
        int256 hitPoints,
        int256 attack,
        int256 defense,
        uint256 percentChanceOfUse,
        uint256 numberOfUsesPerGame
    ) external onlyOwner returns (uint256) {
        uint256[] memory ids = assets.mint(account, ASSET_NAME, 1, "");
        uint256 id = ids[0];

        EquipmentMetadata storage metadata = metadata[id];
        metadata.name = name;
        metadata.hitPoints = hitPoints;
        metadata.attack = attack;
        metadata.defense = defense;
        metadata.percentChanceOfUse = percentChanceOfUse;
        metadata.numberOfUsesPerGame = numberOfUsesPerGame;
        metadata.createdAt = bytes32(block.timestamp);

        return id;
    }

    function exists(uint256 id) external view returns (bool) {
        return assets.exists(ASSET_NAME, id);
    }

    function _msgSender()
        internal
        view
        override(Context, EIP712MetaTransaction)
        returns (address payable)
    {
        return EIP712MetaTransaction.msgSender();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./meta/EIP712MetaTransaction.sol";
import "./Assets.sol";
import "./TournamentV4.sol";
import "./Constants.sol";

import "hardhat/console.sol";

// only calling this with the 5 because otherwise there's a build error conflicting with BettingPoolV4
interface IFaction5 {
    function byName(string calldata name) external returns (uint);
}

contract BettingPoolV5 is ERC1155Receiver, Ownable, EIP712MetaTransaction {
  using SafeMath for uint256;

  event BetPlaced(address indexed better, uint indexed tournamentId, uint indexed gladiatorId);

  uint256 constant private oneHundredPercent = 10**10;

  Assets immutable private _assets; // ERC-1155 Assets contract
  TournamentV4 immutable private _tournaments; // ERC-1155 Assets contract
  IFaction5 immutable private _faction;
  address immutable private _gladiatorContract;

  uint immutable private _prestigeId;

  uint8 public multiplier;
  uint8 public gladiatorPercent;

  mapping(uint256 => mapping(address => mapping(uint => uint))) public betsByUser;  //tournamentID => user => gladiator => amount
  mapping(uint256 => mapping(address => uint8)) public betCountByUser; // tournamentID => user => count; // only allow 2 bets per user
  mapping(uint256 => mapping(uint => uint)) public betsByGladiator; // tournamentID => gladiatorId => totalAmount
  mapping(uint256 => uint) public betsByTournament; // tournamentID => totalAmount

  mapping(uint256 => uint256) public incentivesByTournament; // tournamentID => amount of incentive

  mapping(uint256 => bool) private _claimedByGladiator; // tournamentID => true/false if already claimed by gladiator

  constructor(
    address _assetsAddress,
    address _tournamentAddress,
    address _gladiatorAddress,
    address _factionAddress
  ) EIP712MetaTransaction("BettingPool", "2") {
    require(
      _assetsAddress != address(0),
      "BettingPool#constructor: INVALID_INPUT _assetsAddress is 0"
    );
    Assets assetContract = Assets(_assetsAddress);
    _assets = assetContract;
    _tournaments = TournamentV4(_tournamentAddress);
    (uint start,) = assetContract.idRange(Constants.prestigeAssetName());
    _prestigeId = start;
    gladiatorPercent = 20;
    _gladiatorContract = _gladiatorAddress;
    _faction = IFaction5(_factionAddress);
  }

  function setIncentive(uint256 tournamentId, uint256 amount) external onlyOwner {
    incentivesByTournament[tournamentId] = amount;
  }

  function setGladiatorPercent(uint8 percent) external onlyOwner {
    gladiatorPercent = percent;
  }

  function expectedWinnings(uint tournamentId, address user, uint champion) public view returns (uint) {
    uint bet = betsByUser[tournamentId][user][champion];
    if (bet == 0) {
      return 0;
    }

    // calculate their percentage of all the *winners* of the tournament (those that picked the right gladiator)
    // percent calculated as 10 digits (10^10 is 100%);
    uint percentOfPool = (bet * oneHundredPercent).div(betsByGladiator[tournamentId][champion]);
    
    return betsByTournament[tournamentId].sub(gladiatorWinnings(tournamentId)).add(incentivesByTournament[tournamentId]).mul(percentOfPool).div(oneHundredPercent);
  }

  function withdraw(uint tournamentId) external returns (bool) {
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);
    uint champion = winner.gladiator;

    address user = msgSender();

    uint winnings = expectedWinnings(tournamentId, user, champion);
    require(winnings > 0, "BettingPool#You didn't win");
    
    delete betsByUser[tournamentId][user][champion];
    delete betCountByUser[tournamentId][user];
    _assets.safeTransferFrom(address(this), user, _prestigeId, winnings, '');
    return true;
  }

  function gladiatorWinnings(uint tournamentId) internal view returns (uint) {
    return betsByTournament[tournamentId].mul(gladiatorPercent).div(100);
  }

  function claimForGladiator(uint tournamentId) external returns (bool) {
    require(!_claimedByGladiator[tournamentId], "Gladiators winnings already claimed");
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);

    string memory factionName = _tournaments.factions(tournamentId)[winner.faction];
    uint factionID = _faction.byName(factionName);
    
    uint winnings = gladiatorWinnings(tournamentId);

    if (factionID > 0) {
      uint factionWinnings = winnings.mul(25).div(100);
      _assets.safeTransferFrom(address(this), address(_faction), _prestigeId, winnings, abi.encode(factionID));
      winnings = winnings.sub(factionWinnings);
    }

    // console.log('winnings', winnings);
    _claimedByGladiator[tournamentId] = true;
    _assets.safeTransferFrom(address(this), _gladiatorContract, _prestigeId, winnings, abi.encode(winner.gladiator));
    return true;
  }

  function migrate(address payable newAddress) external onlyOwner {
    // move all ptg to the new address and destroy this contract
    uint balance = _assets.balanceOf(address(this), _prestigeId);
    _assets.safeTransferFrom(address(this), newAddress, _prestigeId, balance, '');
    selfdestruct(newAddress);
  }

  function onERC1155Received(
    address, // operator
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    require(msg.sender == address(_assets), "BettingPool#onERC1155Received: invalid asset address");
    require(id == _prestigeId, "BettingPool#Invalid token send");
    if (from == address(0)) {
      // this is a MINT so just accept it
      return IERC1155Receiver.onERC1155Received.selector;
    }
    (uint256 tournamentId, uint256 gladiatorId) = abi.decode(data, (uint256, uint256));
    // console.log("bet!", tournamentId, gladiatorId, from);
    require(!_tournaments.started(tournamentId), "BettingPool#Tournament already started");

    // if this is a *new* bet on the tournament then increase the count
    // but allow unlimited increases in your betting;
    if (betsByUser[tournamentId][from][gladiatorId] == 0) {
      require(betCountByUser[tournamentId][from] < 2, "BettingPool#Too many bets");
      betCountByUser[tournamentId][from] += 1; 
    }
    betsByUser[tournamentId][from][gladiatorId] += value;
    betsByGladiator[tournamentId][gladiatorId] += value;
    betsByTournament[tournamentId] += value;
    
    emit BetPlaced(from, tournamentId, gladiatorId);

    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes calldata
  ) pure public override returns(bytes4) {
      revert("BettingPool#No batch allowed");
  }

  function _msgSender() internal view override(Context,EIP712MetaTransaction) returns (address payable) {
    return EIP712MetaTransaction.msgSender();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// this is https://github.com/keep3r-network/keep3r.network/blob/master/contracts/jobs/UniswapV2Oracle.sol
// but with the keep3r parts removed and solidity version updated.
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
// import "hardhat/console.sol";

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract UniswapV2Oracle is AccessControl {
    using FixedPoint for *;
    using SafeMath for uint;
    using Arrays for uint256[];

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    mapping(address => uint256[]) private pairSnapshots; // pair address => snapshotIds

    mapping(address => mapping(uint256 => Observation)) private historicObservations; // pairAddress => snapshotId => price

    bytes32 public constant PAIR_ADDER_ROLE = keccak256("PAIR_ADDER_ROLE");

    address public immutable factory; // quickswap factory
    // the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint public immutable windowSize = 14400;

    uint public immutable periodSize = 900;

    address[] internal _pairs;
    mapping(address => bool) internal _known;
    mapping(address => uint) public lastUpdated;

    function pairs() external view returns (address[] memory) {
        return _pairs;
    }

    constructor(address factoryAddress) {
        factory = factoryAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAIR_ADDER_ROLE, _msgSender());
    }

    function observationAt(
        address pairAddress,
        uint256 time
    ) public view returns (Observation memory) {
        uint256[] storage snapshots = pairSnapshots[pairAddress];
        uint256 closest = snapshots.findUpperBound(time);

        if (closest == 0) {
            return historicObservations[pairAddress][snapshots[0]];
        }
        if (closest == snapshots.length) {
            return historicObservations[pairAddress][snapshots[closest - 1]];
        }
        uint256 snapID = snapshots[closest];
        if (snapID > time) {
            return historicObservations[pairAddress][snapshots[closest - 1]];
        }
        return historicObservations[pairAddress][snapID];
    }

    // returns the observation from the oldest epoch (at the beginning of the window) relative to the timestamp
    function getFirstObservationInWindow(uint256 timestamp, address pair) private view returns (Observation memory) {
       return observationAt(pair, (timestamp - windowSize) + periodSize);
    }

    function updatePair(address pair) external returns (bool) {
        return _update(pair);
    }

    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function update(address tokenA, address tokenB) external returns (bool) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        return _update(pair);
    }

    function add(address tokenA, address tokenB) external {
        require(hasRole(PAIR_ADDER_ROLE, _msgSender()), "UniswapV2Oracle::add: !gov");
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        require(!_known[pair], "known");
        _known[pair] = true;
        _pairs.push(pair);
    }

    function updateAll() external returns (bool updated) {
        for (uint i = 0; i < _pairs.length; i++) {
            updated = _update(_pairs[i]);
        }
    }

    function updateFor(uint i, uint length) external returns (bool updated) {
        for (; i < length; i++) {
            if (_update(_pairs[i])) {
                updated = true;
            }
        }
    }

    function updateableList() external view returns (address[] memory list) {
        uint _index = 0;
        for (uint i = 0; i < _pairs.length; i++) {
            if (updateable(_pairs[i])) {
               list[_index++] = _pairs[i];
            }
        }
    }

    function updateable(address pair) public view returns (bool) {
        return (block.timestamp - lastUpdated[pair]) > periodSize;
    }

    function updateable() external view returns (bool) {
        for (uint i = 0; i < _pairs.length; i++) {
            if (updateable(_pairs[i])) {
                return true;
            }
        }
        return false;
    }

    function updateableFor(uint i, uint length) external view returns (bool) {
        for (; i < length; i++) {
            if (updateable(_pairs[i])) {
                return true;
            }
        }
        return false;
    }

    function _update(address pair) internal returns (bool) {
        // we only want to commit updates once per periodSize
        uint timeElapsed;
        uint[] storage snapshots = pairSnapshots[pair];
        if (snapshots.length > 0) {
            uint256 lastUpdate = snapshots[snapshots.length - 1];
            timeElapsed = block.timestamp - lastUpdate;
        }
       
        if (timeElapsed == 0 || timeElapsed > periodSize) {
            (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            lastUpdated[pair] = block.timestamp;

            pairSnapshots[pair].push(block.timestamp);
            historicObservations[pair][block.timestamp] = Observation({
                timestamp: block.timestamp,
                price0Cumulative: price0Cumulative,
                price1Cumulative: price1Cumulative
            });

            return true;
        }

        revert('not enough time elapsed');
        return false;
    }

    // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
    // price in terms of how much amount out is received for the amount in
    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        Observation memory firstObservation = getFirstObservationInWindow(block.timestamp, pair);

        uint timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, 'SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION');
        // should never happen.
        require(timeElapsed >= windowSize - periodSize * 2, 'SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED');

        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }

    function consultAt(uint256 timestamp, address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        Observation memory earlierObservation = getFirstObservationInWindow(timestamp, pair);
        Observation memory timestampObservation = observationAt(pair, timestamp);

        uint timeElapsed = timestampObservation.timestamp - earlierObservation.timestamp;

        require(timeElapsed <= windowSize, 'SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION');
        // should never happen.
        require(timeElapsed >= windowSize - periodSize * 2, 'SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED');

        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(earlierObservation.price0Cumulative, timestampObservation.price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(earlierObservation.price1Cumulative, timestampObservation.price1Cumulative, timeElapsed, amountIn);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// import "hardhat/console.sol";

contract FreeBetCoin is ERC721, AccessControl, IERC1155Receiver {
    using Counters for Counters.Counter;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 private constant PTG_ID = 0;

    IERC1155 immutable assets;
    address immutable bettingPoolAddress;

    string private contractMetadataUri;

    struct FreeBetCoinMetadata {
      uint256 value;
      uint256 blockCreatedAt;
      uint256 expiresAtBlock;
      address creator;
    }

    event FreeBetCreated(
        address indexed creator,
        address indexed user,
        uint256 indexed tokenId,
        uint256 blockNumber,
        uint256 amount
    );

    event FreeBetUsed(
        address indexed creator,
        address indexed user,
        uint256 indexed tournamentId,
        uint256 gladiatorId,
        uint256 tokenId,
        uint256 value
    );

    event FreeBetBurnt(
      uint256 indexed tokenId,
      address indexed to,
      uint256 value
    );

    Counters.Counter private _tokenIds;
    mapping(uint256 => FreeBetCoinMetadata) public metadata;

    constructor(
        address _assets,
        address _bettingPool,
        string memory _baseURI,
        string memory _contractURI
    ) ERC721("Crypto Colosseum Free Bet", "ccFreeBet") {
        assets = IERC1155(_assets);
        bettingPoolAddress = _bettingPool;
        _setBaseURI(_baseURI);
        contractMetadataUri = _contractURI;
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    function use(uint256 tokenId, address onBehalfOf, uint256 tournamentId, uint256 gladiatorId, uint256 expectedTotal) public {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "FreeBetCoin: caller is not owner nor approved");
      
      bytes memory data = abi.encode(onBehalfOf, tournamentId, gladiatorId, expectedTotal);
      FreeBetCoinMetadata storage meta = metadata[tokenId];
      uint256 expiry = meta.expiresAtBlock;
      uint256 value = meta.value;
      require(expiry == 0 || expiry >= block.number, "token expired");
      _fullBurn(tokenId);
      assets.safeTransferFrom(address(this), bettingPoolAddress, PTG_ID, value, data);
      emit FreeBetUsed(meta.creator, onBehalfOf, tournamentId, gladiatorId, tokenId, value);
    }

    function _fullBurn(uint256 tokenId) private {
        delete metadata[tokenId];
        _burn(tokenId);
    }

    /**
    @dev
    burn is an admin function to delete bad free bets or erase them from unused accounts.
     */
    function burn(uint256 tokenId, address to) public {
        FreeBetCoinMetadata storage meta = metadata[tokenId];
        require(
            hasRole(BURNER_ROLE, _msgSender()) || meta.creator == _msgSender(),
            "Only governance can burn tokens"
        );
        uint256 value = metadata[tokenId].value;
        _fullBurn(tokenId);
        assets.safeTransferFrom(address(this), to, PTG_ID, value, "");
        emit FreeBetBurnt(tokenId, to, value);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 assetId,
        uint256 value,
        bytes calldata data // data holds the address we are minting the coin *to*
    ) external override returns (bytes4) {
        require(
            _msgSender() == address(assets),
            "FreeBetCoin#Only assets contract supported"
        );
        require(assetId == PTG_ID, "only PTG is supported");
        (address to, uint256 expiresAtBlock) = abi.decode(data, (address, uint256));
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _mint(to, id);
        metadata[id] = FreeBetCoinMetadata({
          value: value,
          blockCreatedAt: block.number,
          expiresAtBlock: expiresAtBlock,
          creator: from
        });
        emit FreeBetCreated(from, to, id, block.number, value);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public override returns (bytes4) {
        revert("we only use PTG here");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// import "hardhat/console.sol";

contract MarketplaceWrapper is 
    ERC721,
    IERC1155Receiver
{
    using Counters for Counters.Counter;
    
    event Wrapped(address indexed from, uint256 indexed addressId, uint256 indexed wrappedId);

    IERC1155 immutable assets;
    string private contractMetadataUri;

    Counters.Counter private _tokenIds;
    mapping(uint256 => uint256) public wrapperToAsset;

    constructor(address _assets, string memory baseURI, string memory _contractURI) ERC721("CryptoColosseumToken", "CCTKN") {
        assets = IERC1155(_assets);
        _setBaseURI(baseURI);
        contractMetadataUri = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        uint256 assetId = wrapperToAsset[tokenId];
        delete wrapperToAsset[tokenId];
        _burn(tokenId);
        assets.safeTransferFrom(address(this), _msgSender(), assetId, 1, '');
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // the id of the token
    ) external override returns (bytes4) {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory values = new uint256[](1);
        ids[0] = id;
        values[0] = value;
        onERC1155BatchReceived(operator, from, ids, values, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata
    ) public override returns (bytes4) {
        require(_msgSender() == address(assets), "MarketplaceWrapper#Only assets contract tokens supported");
        
        for (uint256 i = 0; i < ids.length; i++) {
            // We cannot just use balanceOf to create the new tokenId because tokens
            // can be burned (destroyed), so we need a separate counter.
            uint256 assetsId = ids[i];
            require(values[i] < 1000, "Do not send fungible tokens here");
            for (uint256 j = 0; j < values[i]; j++) {
                uint256 wrapperId = _tokenIds.current();
                _mint(from, wrapperId);
                _tokenIds.increment();
                wrapperToAsset[wrapperId] = assetsId;
                emit Wrapped(from, assetsId, wrapperId);
            }
        }
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bundler is
    IERC1155,
    IERC1155MetadataURI,
    ERC165,
    AccessControl,
    IERC1155Receiver
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct TokenMetadata {
        string uri;
        EnumerableSet.AddressSet addresses;
        mapping(address => EnumerableSet.UintSet) ids;
        mapping(address => mapping(uint256 => uint256)) balances;
    }

    mapping(uint256 => TokenMetadata) private _tokenMetadata;

    function uri(uint256 tokenID)
        external
        view
        override
        returns (string memory)
    {
        return _tokenMetadata[tokenID].uri;
    }

    mapping(address => EnumerableSet.UintSet) private _addressTokens; // the tokens an address holds

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    constructor() public {
        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

     function contractURI() public view returns (string memory) {
        return "https://arena.cryptocolosseum.com/metadata/bundler.json";
    }

    function mint(address account, string calldata uri)
        public
        returns (uint256 id)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");

        _tokenIds.increment();
        id = _tokenIds.current();
        _mint(account, id, 1, "");
        TokenMetadata storage metadata = _tokenMetadata[id];
        metadata.uri = uri;
        return id;
    }

    function bundledAddresses(uint tokenID) public view returns (address[] memory addresses) {
        EnumerableSet.AddressSet storage tokenAddresses = _tokenMetadata[tokenID].addresses;
        uint256 len = tokenAddresses.length();
        addresses = new address[](len);
        for (uint i; i < len; i++) {
            addresses[i] = tokenAddresses.at(i);
        }
        return addresses;
    }

    function bundledIds(uint tokenID, address addr) public view returns (uint[] memory ids) {
        EnumerableSet.UintSet storage heldIDs = _tokenMetadata[tokenID].ids[addr];
        uint256 len = heldIDs.length();
        ids = new uint[](len);
        for (uint i; i < len; i++) {
            ids[i] = heldIDs.at(i);
        }
        return ids;
    }

    function unbundleAndBurn(uint256 tokenID, address to) public {
        // todo: gas efficiency
        EnumerableSet.AddressSet storage tokenAddresses = _tokenMetadata[tokenID].addresses;
        uint256 addrLen = tokenAddresses.length();
        for (uint i; i < addrLen; i++) {
            address addr = tokenAddresses.at(i);
            uint256[] memory ids = bundledIds(tokenID, addr);
            for (uint j; j < ids.length; j++) {
                withdraw(tokenID, addr, ids[j], to);
            }
        }
        burn(tokenID);
    }

    function burn(uint256 tokenID) public {
        require(balanceOf(_msgSender(), tokenID) > 0, "No token");
        _burn(_msgSender(), tokenID, 1);
    }

    function withdraw(
        uint256 tokenID,
        address addr,
        uint256 id,
        address to
    ) public {
        require(balanceOf(_msgSender(), tokenID) > 0, "No token");
        TokenMetadata storage metadata = _tokenMetadata[tokenID];
        uint256 amount = metadata.balances[addr][id];
        delete metadata.balances[addr][id];
        metadata.addresses.remove(addr);
        metadata.ids[addr].remove(id);
        IERC1155(addr).safeTransferFrom(address(this), to, id, amount, '');
    }

    function tokenBalance(
        uint256 tokenID,
        address addr,
        uint256 id
    ) public view returns (uint256) {
        TokenMetadata storage metadata = _tokenMetadata[tokenID];
        return metadata.balances[addr][id];
    }

    function addressTokens(address addr) public view returns (uint256[] memory ids) {
        EnumerableSet.UintSet storage tokens = _addressTokens[addr];
        uint256 len = tokens.length();
        ids = new uint256[](len);
        for (uint i; i < len; i++) {
            ids[i] = tokens.at(i);
        }
        return ids;
    }

    function onERC1155Received(
        address, // operator
        address,
        uint256 id,
        uint256 value,
        bytes calldata data // the id of the token
    ) external override returns (bytes4) {
        TokenMetadata storage metadata =
            _tokenMetadata[abi.decode(data, (uint256))];
        address sender = msg.sender;
        metadata.addresses.add(sender);
        metadata.ids[sender].add(id);
        metadata.balances[sender][id] = metadata.balances[sender][id].add(
            value
        );
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("batch send is not supported");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        for (uint i; i < ids.length; i++) {
            if (from != address(0)) {
                _addressTokens[from].remove(ids[i]);
            }
            if (to != address(0)) {
                _addressTokens[to].add(ids[i]);
            }
        }
    }

    // below is boiler plate from open zeppelin ERC1155

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(
                accounts[i] != address(0),
                "ERC1155: batch balance query for the zero address"
            );
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // function _beforeTokenTransfer(
    //     address operator,
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TournamentLogger is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    EnumerableSet.UintSet private tournaments;

    function add(uint tournamentId) public onlyOwner {
        tournaments.add(tournamentId);
    }

    function all() public view returns (uint[] memory ids) {
        uint len = tournaments.length();
        ids = new uint[](len);
        for (uint i; i < len; i++) {
            ids[i] = tournaments.at(i);
        }
        return ids;
    }

    function length() public view returns (uint) {
        return tournaments.length();
    }

    function slice(uint start, uint length) public view returns (uint[] memory ids) {
        ids = new uint[](length);
        uint idsIndx = 0;
        for (uint i = start; i < start + length; i++) {
            ids[idsIndx] = tournaments.at(i);
            idsIndx++;
        }
        return ids;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FreeBet is Ownable {
    mapping(address => uint32) public maxFreeBets;
    mapping(address => uint32) public usedFreeBets;

    function inc(address userAddress) public onlyOwner returns (uint32) {
        return usedFreeBets[userAddress]++;
    }

    function setMaxFreeBets(address userAddress, uint32 max) public onlyOwner {
        maxFreeBets[userAddress] = max;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./Constants.sol";
import "./interfaces/IDiceRollsV5.sol";

import "hardhat/console.sol";

contract DiceRollerV5 is
    IDiceRollsV5,
    Ownable
{
    using SafeMath for uint256;

    uint256 public override latest;

    mapping(uint256 => RollParams) public rolls;

    function roll(uint256 random, PerformancePair[] calldata performance)
        public
        override
        onlyOwner
    {
        // console.log("---- dice roll");
        RollParams storage roll = rolls[latest + 1];
        roll.random = uint256(
            keccak256(abi.encodePacked(random, blockhash(block.number - 1)))
        );
        // console.log('pushing performances');
        for (uint256 i; i < performance.length; i++) {
            roll.performances.push(performance[i]);
        }
        roll.id = latest + 1;
        roll.blockNumber = block.number;
        latest++;
        emit DiceRoll(latest, roll.random);
    }

    function getLatestRoll() public view override returns (RollParams memory) {
        return getRoll(latest);
    }

    function getRoll(uint256 index)
        public
        view
        override
        returns (RollParams memory)
    {
        return rolls[index];
    }

    function getRange(uint256 start, uint256 last)
        public
        view
        override
        returns (RollParams[] memory)
    {
        // console.log("getRange:", start, last, latest);
        RollParams[] memory rolls_ = new RollParams[](last - start + 1);
        uint256 returnedRollsIndex;
        for (uint256 i = start; i <= last; i++) {
            // console.log('getRange add', i, 'random', rolls[i].random);
            rolls_[returnedRollsIndex] = rolls[i];
            returnedRollsIndex++;
        }
        return rolls_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./Constants.sol";
import "./interfaces/IDiceRolls.sol";

import "hardhat/console.sol";

contract DiceRoller is
    IDiceRolls,
    Ownable
{
    using SafeMath for uint256;

    uint256 public override latest;

    mapping(uint256 => RollParams) public rolls;

    function roll(uint256 random, PerformancePair[] calldata performance)
        public
        override
        onlyOwner
    {
        // console.log("---- dice roll");
        RollParams storage roll = rolls[latest + 1];
        roll.random = uint256(
            keccak256(abi.encodePacked(random, blockhash(block.number - 1)))
        );
        // console.log('pushing performances');
        for (uint256 i; i < performance.length; i++) {
            roll.performances.push(performance[i]);
        }
        roll.id = latest + 1;
        roll.blockNumber = block.number;
        latest++;
        emit DiceRoll(latest, roll.random);
    }

    function getLatestRoll() public view override returns (RollParams memory) {
        return getRoll(latest);
    }

    function getRoll(uint256 index)
        public
        view
        override
        returns (RollParams memory)
    {
        return rolls[index];
    }

    function getRange(uint256 start, uint256 last)
        public
        view
        override
        returns (RollParams[] memory)
    {
        // console.log("getRange:", start, last, latest);
        RollParams[] memory rolls_ = new RollParams[](last - start + 1);
        uint256 returnedRollsIndex;
        for (uint256 i = start; i <= last; i++) {
            // console.log('getRange add', i, 'random', rolls[i].random);
            rolls_[returnedRollsIndex] = rolls[i];
            returnedRollsIndex++;
        }
        return rolls_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IAssets.sol";

import "hardhat/console.sol";

/**
 *
 * @dev This receives erc1155s and is operated by a banker that can then distribute them.
 */
contract BotBank is IERC1155, IERC1155Receiver, ERC165, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    IAssets immutable assets;

    constructor(address _assetsAddress) {
        assets = IAssets(_assetsAddress);
    }

    function withdraw(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(from, id, value);
        assets.safeTransferFrom(address(this), to, id, value, "");
    }

    function handleTokenReceived(
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) private returns (bool) {
        _mint(from, id, value, data);
        // allow the banker (owner of this contract) to operate the funds here
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        onERC1155BatchReceived(
            operator,
            from,
            _asSingletonArray(id),
            _asSingletonArray(value),
            data
        );
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data // abi.encoded (uint256 tournamentId, uint16 faction)
    ) public override returns (bytes4) {
        require(
            msg.sender == address(assets),
            "Tournament#onERC1155BatchReceived: invalid asset address"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                handleTokenReceived(from, ids[i], values[i], data),
                "error handling token"
            );
        }

        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return (operator == owner()) || _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./interfaces/IAssets.sol";
import "./interfaces/IAssetsERC20Wrapper.sol";

import "hardhat/console.sol";

contract AssetsERC20Wrapper is IAssetsERC20Wrapper, ERC20, ERC1155Receiver {
    using SafeMath for uint256;
    
    IAssets immutable _tokenHolder;
    uint256 private _tokenID; // the specific token id this erc20 is wrapping

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor(address holder) ERC20('', '') {
        _tokenHolder = IAssets(holder);
        _tokenID = 1; // initialize the contract for the copy
    }

    function init(uint256 tokenID, string calldata name_, string calldata symbol_) public {
        _tokenID = tokenID;
        _name = name_;
        _symbol = symbol_;
    }

    function unwrap(address account, address to, uint256 amount) override external {
        if (account != _msgSender()) {
            uint256 currentAllowance = allowance(account, _msgSender());
            require(currentAllowance >= amount, "AssetsERC20Wrapper: unwrap amount exceeds allowance");
            _approve(account, _msgSender(), currentAllowance.sub(amount));
        }
        _burn(account, amount);
        _tokenHolder.safeTransferFrom(address(this), to, _tokenID, amount, '');
    }

    function onERC1155Received(
        address, // operator
        address from,
        uint256 id,
        uint256 value,
        bytes calldata // data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(_tokenHolder),
            "AssetsERC20Wrapper#onERC1155: invalid asset address"
        );
        require(id == _tokenID, "AssetsERC20Wrapper: invalid token id");

        _mint(from, value);

        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("batch send is not supported");
    }
    
}

pragma solidity ^0.7.4;

import "./AssetsERC20Wrapper.sol";
import "./CloneFactory.sol";

contract WrapperFactory is CloneFactory {

  address public libraryAddress;
  address public holderAddress;

  mapping(uint256 => address) public getWrapper; // mapping of tokenID to address

  event WrapperCreated(address proxyAddress);

  constructor(address _libraryAddress, address _holderAddress) {
    libraryAddress = _libraryAddress;
    holderAddress = _holderAddress;
  }

  function createWrapper(uint256 tokenID, string calldata name, string calldata symbol) public returns(address) {
    require(getWrapper[tokenID] == address(0), "wrapper already created");
    address clone = createClone(libraryAddress);
    AssetsERC20Wrapper(clone).init(tokenID, name, symbol);
    getWrapper[tokenID] = address(clone);
    emit WrapperCreated(clone);
    return clone;
  }
}

pragma solidity >= 0.6.0;

// see https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol


/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "./meta/EIP712MetaTransaction.sol";
import "./Assets.sol";
import "./TournamentV4.sol";
import "./Constants.sol";

import "hardhat/console.sol";

interface IFaction {
    function byName(string calldata name) external returns (uint);
}

contract BettingPoolV4 is ERC1155Receiver, Ownable, EIP712MetaTransaction {
  using SafeMath for uint256;

  event BetPlaced(address indexed better, uint indexed tournamentId, uint indexed gladiatorId);

  Assets immutable private _assets; // ERC-1155 Assets contract
  TournamentV4 immutable private _tournaments; // ERC-1155 Assets contract
  IFaction immutable private _faction;
  address immutable private _gladiatorContract;

  uint immutable private _prestigeId;

  uint8 public multiplier;
  uint8 public gladiatorPercent;

  mapping(uint256 => mapping(address => mapping(uint => uint))) public betsByUser;  //tournamentID => user => gladiator => amount
  mapping(uint256 => mapping(uint => uint)) public betsByGladiator; // tournamentID => gladiatorId => totalAmount
  mapping(uint256 => uint) public betsByTournament; // tournamentID => totalAmount

  mapping(uint256 => bool) private _claimedByGladiator; // tournamentID => true/false if already claimed by gladiator

  constructor(
    address _assetsAddress,
    address _tournamentAddress,
    address _gladiatorAddress,
    address _factionAddress
  ) public EIP712MetaTransaction("BettingPool", "1") {
    require(
      _assetsAddress != address(0),
      "BettingPool#constructor: INVALID_INPUT _assetsAddress is 0"
    );
    Assets assetContract = Assets(_assetsAddress);
    _assets = assetContract;
    _tournaments = TournamentV4(_tournamentAddress);
    (uint start,) = assetContract.idRange(Constants.prestigeAssetName());
    _prestigeId = start;
    gladiatorPercent = 20;
    _gladiatorContract = _gladiatorAddress;
    _faction = IFaction(_factionAddress);
  }

  function setMultiplier(uint8 multiplier_) external onlyOwner {
    multiplier = multiplier_;
  }

  function setGladiatorPercent(uint8 percent) external onlyOwner {
    gladiatorPercent = percent;
  }

  function expectedWinnings(uint tournamentId, address user, uint champion) public view returns (uint) {
    uint bet = betsByUser[tournamentId][user][champion];
    if (bet == 0) {
      return 0;
    }
    uint winningPool = betsByGladiator[tournamentId][champion];

    // percent calculated as 10 digits (10^10 is 100%);
    uint percentOfPool = (bet * 10**10).div(winningPool);
    
    uint winnings = betsByTournament[tournamentId].sub(gladiatorWinnings(tournamentId)).mul(percentOfPool).div(10**10);

    if (multiplier > 0) {
      // mint the multiplier for this winner
      winnings *= uint(multiplier);
    }
    return winnings;
  }

  function withdraw(uint tournamentId) external returns (bool) {
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);
    uint champion = winner.gladiator;

    address user = msgSender();

    uint winnings = expectedWinnings(tournamentId, user, champion);
    require(winnings > 0, "BettingPool#You didn't win");
    
    delete betsByUser[tournamentId][user][champion];
    _assets.mint(address(this), Constants.prestigeAssetName(), winnings, '');
    _assets.safeTransferFrom(address(this), user, _prestigeId, winnings, '');
    return true;
  }

  function gladiatorWinnings(uint tournamentId) internal view returns (uint) {
    return betsByTournament[tournamentId].mul(gladiatorPercent).div(100);
  }

  function claimForGladiator(uint tournamentId) external returns (bool) {
    require(!_claimedByGladiator[tournamentId], "Gladiators winnings already claimed");
    TournamentV4.Champion memory winner = _tournaments.getChampion(tournamentId);

    string memory factionName = _tournaments.factions(tournamentId)[winner.faction];
    uint factionID = _faction.byName(factionName);
    
    uint winnings = gladiatorWinnings(tournamentId);

    if (factionID > 0) {
      uint factionWinnings = winnings.mul(25).div(100);
      _assets.safeTransferFrom(address(this), address(_faction), _prestigeId, winnings, abi.encode(factionID));
      winnings = winnings.sub(factionWinnings);
    }

    // console.log('winnings', winnings);
    _claimedByGladiator[tournamentId] = true;
    _assets.safeTransferFrom(address(this), _gladiatorContract, _prestigeId, winnings, abi.encode(winner.gladiator));
    return true;
  }

  function onERC1155Received(
    address, // operator
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns(bytes4) {
    require(msg.sender == address(_assets), "BettingPool#onERC1155Received: invalid asset address");
    require(id == _prestigeId, "BettingPool#Invalid token send");
    if (from == address(0)) {
      // this is a MINT so just accept it
      return IERC1155Receiver.onERC1155Received.selector;
    }
    (uint256 tournamentId, uint256 gladiatorId) = abi.decode(data, (uint256, uint256));
    // console.log("bet!", tournamentId, gladiatorId, from);
    require(!_tournaments.started(tournamentId), "BettingPool#Tournament already started");
    betsByUser[tournamentId][from][gladiatorId] += value;
    betsByGladiator[tournamentId][gladiatorId] += value;
    betsByTournament[tournamentId] += value;
    
    emit BetPlaced(from, tournamentId, gladiatorId);

    return IERC1155Receiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes calldata
  ) pure public override returns(bytes4) {
      revert("BettingPool#No batch allowed");
  }

  function _msgSender() internal view override(Context,EIP712MetaTransaction) returns (address payable) {
    return EIP712MetaTransaction.msgSender();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Assets.sol";
import "./interfaces/IAuction.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionV2 is IAuction, ERC1155Receiver, Ownable {
    using Counters for Counters.Counter;

    Assets private immutable _assets; // ERC-1155 Assets contract
    uint256 private immutable _ptgID;
    bytes32 constant EQUIPMENT_NAME = "equipment";

    uint256 public endTimeExtensionOffset = 60 * 60; // 1hr default
    uint256 public endTimeExtensionAmount = 10 * 60; // 10 minut default

    mapping(uint256 => AuctionData) public auctions;

    Counters.Counter public tokenIds;

    constructor(address assetsContract, uint256 ptgId) {
        _assets = Assets(assetsContract);
        _ptgID = ptgId;
    }

    function setEndTime(uint offset, uint amount) onlyOwner public {
        endTimeExtensionOffset = offset;
        endTimeExtensionAmount = amount;
    }

    function newAuction(
        address _owner,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _itemId,
        uint256 _minBidAmount,
        uint256 _minIncrement
    ) private returns (uint256 id) {
        require(_owner != address(0), "Owner must be specifed");

        tokenIds.increment();
        uint256 auctionId = tokenIds.current();

        AuctionData storage auction = auctions[auctionId];

        auction.id = auctionId;
        auction.owner = _owner;
        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.itemId = _itemId;
        auction.minBidAmount = _minBidAmount;
        auction.minIncrement = _minIncrement;

        emit NewAuction(_owner, _startTime, _endTime, auctionId, _minBidAmount);

        return auctionId;
    }

    function placeBid(
        address from,
        uint256 value,
        bytes calldata data // abi encoded (uint256 auctionId)
    ) private {
        // reject payments of 0 PTG
        require(value != 0, "Cannot bid 0");

        uint256 auctionId = abi.decode(data, (uint256));

        AuctionData storage auction = auctions[auctionId];

        require(from != auction.owner, "Owner cannot place bid");
        require(!auction.canceled, "cancelled");
        require(block.timestamp < auction.endTime, "already ended");
        require(block.timestamp > auction.startTime, "not started");

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint256 newBid = auction.fundsByBidder[from] + value;
        uint256 highestAuctionBid =
            auction.fundsByBidder[auction.highestBidder];

        require(
            newBid >= auction.minBidAmount,
            "Cannot bid below minimum amount"
        );

        require(
            newBid >= highestAuctionBid + auction.minIncrement,
            "New bid is less than minimum highest bid"
        );

        auction.fundsByBidder[from] = newBid;
        auction.bidders.push(Bid({bidder: from, amount: newBid, time: block.timestamp}));

        if (from != auction.highestBidder) {
            auction.highestBidder = from;
        }

        if (auction.endTime - block.timestamp < endTimeExtensionOffset) {
            auction.endTime += endTimeExtensionAmount;
        }

        emit NewBid(
            from,
            auction.id,
            newBid,
            auction.highestBidder,
            highestAuctionBid
        );
    }

    function initiateTransfer(
        address to,
        uint256 tokenID,
        uint256 amount
    ) private returns (bool success) {
        _assets.safeTransferFrom(address(this), to, tokenID, amount, "");
        return true;
    }

    function claimItem(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(!auction.highestBidderHasWithdrawn, "already withdrawn");
        require(
            auction.canceled || (block.timestamp > auction.endTime),
            "must be over or canceled"
        );
        // if the auction is over with no bidders or it is canceled then reclaim the 
        // item for the owner.
        if (
            auction.canceled ||
            (block.timestamp > auction.endTime &&
            auction.highestBidder == address(0))
        ) {
            auction.highestBidderHasWithdrawn = true;
            initiateTransfer(auction.owner, auction.itemId, 1);
            return true;
        }

        // otherwise send the item to the highest bidder
        auction.highestBidderHasWithdrawn = true;
        initiateTransfer(auction.highestBidder, auction.itemId, 1);
        return true;
    }

    function claimPayment(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(
            block.timestamp > auction.endTime,
            "Can't withdraw before auction ends"
        );
        require(!auction.ownerHasWithdrawn, "already withdrawn");
        auction.ownerHasWithdrawn = true;

        initiateTransfer(auction.owner, _ptgID, auction.fundsByBidder[auction.highestBidder]);
        return true;
    }

    function withdraw(address bidder, uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(
            bidder != auction.highestBidder,
            "highest bidder may not withdraw"
        );

        require(bidder == msg.sender || block.timestamp > auction.endTime, "only the bidder can withdraw before the auction is over");

        uint256 funds = auction.fundsByBidder[bidder];
        require(funds > 0, "no bids");
        delete auction.fundsByBidder[bidder];
        initiateTransfer(bidder, _ptgID, funds);

        return true;
    }

    function getAuctionBidders(uint256 auctionId)
        public
        view
        returns (Bid[] memory bidders)
    {
        // return auctions[auctionId];
        return auctions[auctionId].bidders;
    }

    function getBidAmount(uint256 auctionId, address bidderAddress)
        public
        view
        returns (uint256 amount)
    {
        return auctions[auctionId].fundsByBidder[bidderAddress];
    }

    function highestBidAmount(uint256 auctionId)
        public
        view
        returns (uint256 amount)
    {
        AuctionData storage auction = auctions[auctionId];
        return auction.fundsByBidder[auction.highestBidder];
    }

    function cancelAuction(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];

        require(msg.sender == auction.owner, "Not owner");
        require(block.timestamp < auction.startTime, "already started");
        require(!auction.canceled, "already canceled");

        auction.canceled = true;
        emit AuctionCancelled();
        return true;
    }

    function handleItemReceived(
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // abi encoded (uint256 startTime, uint256 endTime)
    ) internal returns (bool) {
        require(
            value == 1,
            "Auction#onERC1155Received: may only add one auction at a time"
        );

        (
            uint256 startTime,
            uint256 endTime,
            uint256 minBidAmount,
            uint256 minIncrement
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));

        newAuction(from, startTime, endTime, id, minBidAmount, minIncrement);
        return true;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(_assets),
            "Auction#onERC1155Received: invalid asset address"
        );
        if (id == _ptgID) {
            placeBid(from, value, data);
        } else {
            require(handleItemReceived(from, id, value, data), "failed");
        }
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) public override returns (bytes4) {
        revert("batch auction creation not supported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IDiceRolls.sol";

interface IAuction {
    event NewBid(
        address indexed bidder,
        uint256 indexed auctionId,
        uint256 bid,
        address highestBidder,
        uint256 highestBid
    );
    event AuctionCancelled();

    event NewAuction(
        address indexed owner,
        uint256 indexed startTime,
        uint256 indexed endTime,
        uint256 auctionId,
        uint256 minBidAmount
    );

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 time;
    }

    struct AuctionData {
        // static
        uint256 id;
        address owner;
        uint256 itemId;
        uint256 startTime;
        uint256 endTime;
        uint256 minBidAmount;
        uint256 minIncrement;
        // state
        bool canceled;
        address highestBidder;
        Bid[] bidders;
        mapping(address => uint256) fundsByBidder;
        bool ownerHasWithdrawn;
        bool highestBidderHasWithdrawn;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Assets.sol";
import "./interfaces/IAuction.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Auction is IAuction, ERC1155Receiver {
    using Counters for Counters.Counter;

    Assets private immutable _assets; // ERC-1155 Assets contract
    uint256 private immutable _ptgID;
    bytes32 constant EQUIPMENT_NAME = "equipment";

    mapping(uint256 => AuctionData) public auctions;

    Counters.Counter public tokenIds;

    constructor(address assetsContract, uint256 ptgId) {
        _assets = Assets(assetsContract);
        _ptgID = ptgId;
    }

    function newAuction(
        address _owner,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _itemId,
        uint256 _minBidAmount,
        uint256 _minIncrement
    ) private returns (uint256 id) {
        require(_owner != address(0), "Owner must be specifed");

        tokenIds.increment();
        uint256 auctionId = tokenIds.current();

        AuctionData storage auction = auctions[auctionId];

        auction.id = auctionId;
        auction.owner = _owner;
        auction.startTime = _startTime;
        auction.endTime = _endTime;
        auction.itemId = _itemId;
        auction.minBidAmount = _minBidAmount;
        auction.minIncrement = _minIncrement;

        emit NewAuction(_owner, _startTime, _endTime, auctionId, _minBidAmount);

        return auctionId;
    }

    function placeBid(
        address from,
        uint256 value,
        bytes calldata data // abi encoded (uint256 auctionId)
    ) private {
        // reject payments of 0 PTG
        require(value != 0, "Cannot bid 0");

        uint256 auctionId = abi.decode(data, (uint256));

        AuctionData storage auction = auctions[auctionId];

        require(from != auction.owner, "Owner cannot place bid");
        require(!auction.canceled, "cancelled");
        require(block.timestamp < auction.endTime, "already ended");
        require(block.timestamp > auction.startTime, "not started");

        // calculate the user's total bid based on the current amount they've sent to the contract
        // plus whatever has been sent with this transaction
        uint256 newBid = auction.fundsByBidder[from] + value;
        uint256 highestAuctionBid =
            auction.fundsByBidder[auction.highestBidder];

        require(
            newBid >= auction.minBidAmount,
            "Cannot bid below minimum amount"
        );

        require(
            newBid >= highestAuctionBid + auction.minIncrement,
            "New bid is less than minimum highest bid"
        );

        auction.fundsByBidder[from] = newBid;
        auction.bidders.push(Bid({bidder: from, amount: newBid, time: block.timestamp}));

        if (from != auction.highestBidder) {
            auction.highestBidder = from;
        }

        emit NewBid(
            from,
            auction.id,
            newBid,
            auction.highestBidder,
            highestAuctionBid
        );
    }

    function initiateTransfer(
        address to,
        uint256 tokenID,
        uint256 amount
    ) private returns (bool success) {
        _assets.safeTransferFrom(address(this), to, tokenID, amount, "");
        return true;
    }

    function claimItem(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(!auction.highestBidderHasWithdrawn, "already withdrawn");
        require(
            auction.canceled || (block.timestamp > auction.endTime),
            "must be over or canceled"
        );
        // if the auction is over with no bidders or it is canceled then reclaim the 
        // item for the owner.
        if (
            auction.canceled ||
            (block.timestamp > auction.endTime &&
            auction.highestBidder == address(0))
        ) {
            auction.highestBidderHasWithdrawn = true;
            initiateTransfer(auction.owner, auction.itemId, 1);
            return true;
        }

        // otherwise send the item to the highest bidder
        auction.highestBidderHasWithdrawn = true;
        initiateTransfer(auction.highestBidder, auction.itemId, 1);
        return true;
    }

    function claimPayment(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(
            block.timestamp > auction.endTime,
            "Can't withdraw before auction ends"
        );
        require(!auction.ownerHasWithdrawn, "already withdrawn");
        auction.ownerHasWithdrawn = true;

        initiateTransfer(auction.owner, _ptgID, auction.fundsByBidder[auction.highestBidder]);
        return true;
    }

    function withdraw(address bidder, uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];
        require(
            bidder != auction.highestBidder,
            "highest bidder may not withdraw"
        );

        require(bidder == msg.sender || block.timestamp > auction.endTime, "only the bidder can withdraw before the auction is over");

        uint256 funds = auction.fundsByBidder[bidder];
        require(funds > 0, "no bids");
        delete auction.fundsByBidder[bidder];
        initiateTransfer(bidder, _ptgID, funds);

        return true;
    }

    function getAuctionBidders(uint256 auctionId)
        public
        view
        returns (Bid[] memory bidders)
    {
        // return auctions[auctionId];
        return auctions[auctionId].bidders;
    }

    function getBidAmount(uint256 auctionId, address bidderAddress)
        public
        view
        returns (uint256 amount)
    {
        return auctions[auctionId].fundsByBidder[bidderAddress];
    }

    function highestBidAmount(uint256 auctionId)
        public
        view
        returns (uint256 amount)
    {
        AuctionData storage auction = auctions[auctionId];
        return auction.fundsByBidder[auction.highestBidder];
    }

    function cancelAuction(uint256 auctionId) public returns (bool success) {
        AuctionData storage auction = auctions[auctionId];

        require(msg.sender == auction.owner, "Not owner");
        require(block.timestamp < auction.startTime, "already started");
        require(!auction.canceled, "already canceled");

        auction.canceled = true;
        emit AuctionCancelled();
        return true;
    }

    function handleItemReceived(
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data // abi encoded (uint256 startTime, uint256 endTime)
    ) internal returns (bool) {
        require(
            value == 1,
            "Auction#onERC1155Received: may only add one auction at a time"
        );

        (
            uint256 startTime,
            uint256 endTime,
            uint256 minBidAmount,
            uint256 minIncrement
        ) = abi.decode(data, (uint256, uint256, uint256, uint256));

        newAuction(from, startTime, endTime, id, minBidAmount, minIncrement);
        return true;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(_assets),
            "Auction#onERC1155Received: invalid asset address"
        );
        if (id == _ptgID) {
            placeBid(from, value, data);
        } else {
            require(handleItemReceived(from, id, value, data), "failed");
        }
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, //operator
        address,
        uint256[] memory,
        uint256[] memory,
        bytes calldata
    ) public override returns (bytes4) {
        revert("batch auction creation not supported");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract BettingLogger is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private allBettors;
    mapping(uint => EnumerableSet.AddressSet) private bettors; // tournamentID => bettors

    function add(uint tournamentId) public {
        bettors[tournamentId].add(msg.sender);
        allBettors.add(msg.sender);
    }

    function allFor(uint tournamentId) public view returns (address[] memory ids) {
        EnumerableSet.AddressSet storage addrs = bettors[tournamentId];
        uint len = addrs.length();
        ids = new address[](len);
        for (uint i; i < len; i++) {
            ids[i] = addrs.at(i);
        }
        return ids;
    }

    function lengthFor(uint tournamentId) public view returns (uint) {
        return bettors[tournamentId].length();
    }

    function sliceFor(uint tournamentId, uint start, uint length) public view returns (address[] memory ids) {
        EnumerableSet.AddressSet storage addrs = bettors[tournamentId];
        ids = new address[](length);
        for (uint i; i < length; i++) {
            ids[i] = addrs.at(i + start);
        }
        return ids;
    }

    // functions for all users

    function all() public view returns (address[] memory ids) {
        uint len = allBettors.length();
        ids = new address[](len);
        for (uint i; i < len; i++) {
            ids[i] = allBettors.at(i);
        }
        return ids;
    }

    function length() public view returns (uint) {
        return allBettors.length();
    }

    function slice(uint start, uint length) public view returns (address[] memory ids) {
        ids = new address[](length);
        for (uint i; i < length; i++) {
            ids[i] = allBettors.at(start + i);
        }
        return ids;
    }

    // restricted functions

    function removeFor(uint tournamentId, address addr) public onlyOwner {
        bettors[tournamentId].remove(addr);
    }

    function removeFromAll(address addr) public onlyOwner {
        allBettors.remove(addr);
    }

    function adminAdd(uint tournamentId, address addr) public onlyOwner {
        bettors[tournamentId].add(addr);
        allBettors.add(addr);
    }
    
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}