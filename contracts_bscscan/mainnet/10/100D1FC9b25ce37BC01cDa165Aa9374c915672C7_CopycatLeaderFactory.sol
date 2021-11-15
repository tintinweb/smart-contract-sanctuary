// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CopycatLeader.sol";
import "./lib/CopycatEmergencyMaster.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CopycatLeaderFactory is CopycatEmergencyMaster, ReentrancyGuard {
  event NewCopycatLeaderContract(address indexed copycatLeader, address indexed leader, uint256 indexed leaderId);
  event FeeCollected(address indexed leaderContract, address indexed from, uint256 amount);
  event NewDeposit(uint256 indexed tier, address indexed leaderContract, address indexed depositer, uint256 amount);
  event NewWithdraw(uint256 indexed tier, address indexed leaderContract, address indexed withdrawer, uint256 amount);

  struct LeaderStat {
    uint256 leaderId;
    uint256 totalDeposit;
    uint256 totalWithdraw;
    // bool isUnsafe;
  }

  IERC20 immutable public copycatToken;

  mapping(address => LeaderStat) public leaderStat;
  mapping(uint256 => address) public leaderIdMap;
  mapping(address => bool) public registeredAdapterFactory;
  mapping(address => uint256) public excludeFromFee;
  mapping(address => bool) public contractWhitelist;

  uint256 public nextLeaderId = 1;

  uint256[5] public FEE_LIST = [1000 ether, 20000 ether, 100000 ether, 1 ether, 0.3 ether];

  address public feeAddress;

  constructor(
    IERC20 _copycatToken
  ) {
    copycatToken = _copycatToken;
    feeAddress = msg.sender;
  }

  function COPYCAT_FEE_BASE() public view returns(uint256) {
    return FEE_LIST[3];
  }

  event SetFee(address indexed setter, uint256 index, uint256 oldFee, uint256 newFee);
  function setFee(uint256 newFee, uint256 index) public onlyOwner {
    emit SetFee(msg.sender, index, FEE_LIST[index], newFee);
    FEE_LIST[index] = newFee;
  }

  /*event SetDeployFeeEnablePercentage(address indexed setter, uint256 oldFee, uint256 newFee);
  function setDeployFeeEnablePercentage(uint256 newFee) public onlyOwner {
    // emit SetDeployFeeEnablePercentage(msg.sender, DEPLOY_FEE_ENABLE_PERCENTAGE, newFee);
    DEPLOY_FEE_ENABLE_PERCENTAGE = newFee;
  }*/

  event SetFeeAddress(address indexed setter, address oldAddress, address newAddress);
  function setFeeAddress(address newAddress) public onlyOwner {
    emit SetFeeAddress(msg.sender, feeAddress, newAddress);
    feeAddress = newAddress;
  }

  event SetRegisteredAdapterFactory(address indexed setter, address indexed factoryAddress, bool enabled);
  function setRegisteredAdapterFactory(address factoryAddress, bool enabled) public onlyOwner {
    registeredAdapterFactory[factoryAddress] = enabled;
    emit SetRegisteredAdapterFactory(msg.sender, factoryAddress, enabled);
  }

  event SetContractWhitelist(address indexed setter, address indexed contractAddr, bool enabled);
  function setContractWhitelist(address contractAddr, bool enabled) public {
    require(msg.sender == owner() || registeredAdapterFactory[msg.sender], "F");
    contractWhitelist[contractAddr] = enabled;
    emit SetContractWhitelist(msg.sender, contractAddr, enabled);
  }

  event SetExcludeFromFee(address indexed setter, address indexed walletAddress, uint256 level);
  function setExcludeFromFee(address walletAddress, uint256 level) public onlyOwner {
    excludeFromFee[walletAddress] = level;
    emit SetExcludeFromFee(msg.sender, walletAddress, level);
  }

  function calculateTier(uint256 amount) public pure returns(uint256) {
    if (amount < 1e18) {
      return 0;
    } else if (amount < 1e17) {
      return 1;
    } else if (amount < 1e16) {
      return 2;
    } else if (amount < 1e15) {
      return 3;
    } else {
      return 4;
    }
  }

  function emitDeposit(address depositer, uint256 level, uint256 amount) public {
    require(leaderStat[msg.sender].leaderId > 0, "NR");
    leaderStat[msg.sender].totalDeposit += amount;
    emit NewDeposit(10 * level + calculateTier(amount), msg.sender, depositer, amount);
  }

  function emitWithdraw(address withdrawer, uint256 level, uint256 amount) public {
    require(leaderStat[msg.sender].leaderId > 0, "NR");
    leaderStat[msg.sender].totalWithdraw += amount;
    emit NewWithdraw(10 * level + calculateTier(amount), msg.sender, withdrawer, amount);
  }

  function collectDeployFee(address from, uint256 amount) internal {
    copycatToken.transferFrom(from, feeAddress, amount);
    emit FeeCollected(address(this), from, amount);
  }

  function collectLeaderFee(address from, uint256 amount) external {
    require(leaderStat[msg.sender].leaderId > 0, "NR");
    uint256 half = amount * 6 / 10;
    copycatToken.transferFrom(from, CopycatLeader(payable(msg.sender)).owner(), half);
    copycatToken.transferFrom(from, feeAddress, amount - half);
    emit FeeCollected(address(this), from, amount);
  }

  // function isUnsafeLeader(address leader) public view returns(bool) {
  //   return leaderStat[leader].isUnsafe;
  // }

  function deployLeader(
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
    // address payable _migrateFrom
  ) external nonReentrant payable returns(address payable copycatLeaderAddress) {
    require(_level < 3, "L");
    require(msg.value == FEE_LIST[4] + 0.0001 ether, "IL");

    if (_level >= excludeFromFee[msg.sender]) {
      collectDeployFee(msg.sender, FEE_LIST[_level]);
    }

    bytes memory bytecode = type(CopycatLeader).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, nextLeaderId));

    assembly {
      copycatLeaderAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    // if (_migrateFrom != address(0)) {
    //   CopycatLeader(_migrateFrom).migrateTo(CopycatLeader(copycatLeaderAddress));
    // }

    CopycatLeader(copycatLeaderAddress).initialize(
      msg.sender,
      _depositCopycatFee,
      _depositPercentageFee,
      _level,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar
    );

    // Register leader to factory
    leaderStat[copycatLeaderAddress].leaderId = nextLeaderId;
    // leaderStat[copycatLeaderAddress].isUnsafe = _unsafe;
    leaderIdMap[nextLeaderId] = copycatLeaderAddress;

    // Burn and force initial leader share
    CopycatLeader(copycatLeaderAddress).deposit{value: msg.value}(0);
    CopycatLeader(copycatLeaderAddress).transfer(msg.sender, FEE_LIST[4]);

    emit NewCopycatLeaderContract(copycatLeaderAddress, msg.sender, nextLeaderId);

    excludeFromFee[msg.sender] = 0;
    nextLeaderId++;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
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

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./interfaces/ICopycatNameNft.sol";
import "./interfaces/ICopycatAdapter.sol";
import "./interfaces/ICopycatLeader.sol";
// import "./interfaces/IUniswapV2Router.sol";
// import "hardhat/console.sol";
import "./CopycatLeaderFactory.sol";
import "./lib/CopycatAdapterFactoryBase.sol";
import "./lib/CopycatEmergency.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// CopycatLeader is the main contract for controlling Master fund
contract CopycatLeader is ERC20('', ''), Ownable, ICopycatLeader, CopycatEmergency, ReentrancyGuard {
  CopycatLeaderFactory public override factory;
  bool public initialized = false;
  uint256 public createdAt;

  string public tokenName = "";
  string public tokenSymbol = "";
  string public description = "";
  string public avatar = "";
  string public ipfsHash;
  uint256 public override level = 0;

  bool public override disabled;
  // ICopycatLeader public override migratedTo;
  // address public override migratedFrom;

  ICopycatAdapter[] public override adapters;

  // uint256 public depositFeeRate = 0;
  // uint256 public withdrawFeeRate = 0;

  // netCopycatFee = copycatFee * copycatToken.copycatFeeMultiplier
  uint256 public override depositCopycatFee = 0; // Base fee
  uint256 public override depositPercentageFee = 0; // Base fee

  constructor() {
    factory = CopycatLeaderFactory(msg.sender);
    createdAt = block.timestamp;
  }

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
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  modifier onlyEOA(){
    bool isEOA = tx.origin == msg.sender && !isContract(msg.sender);
    require(isEOA || factory.contractWhitelist(msg.sender), "EOA");
    _;
  }

  event ReceiveBnb(address indexed payer, uint256 value);

  fallback() external payable {
    emit ReceiveBnb(msg.sender, msg.value);
  }

  receive() external payable {
    emit ReceiveBnb(msg.sender, msg.value);
  }

  function _updateLeaderInfo(
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) internal {
    require(_depositCopycatFee <= 10000 ether, "HCF");
    require(_depositPercentageFee <= 0.2 ether, "HF");

    depositCopycatFee = _depositCopycatFee;
    depositPercentageFee = _depositPercentageFee;
    level = _level;

    tokenName = _tokenName;
    tokenSymbol = _tokenSymbol;
    description = _description;
    avatar = _avatar;
  }

  event Initialize(
    address indexed initializer, 
    address indexed _leaderAddr,
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level
  );
  function initialize(
    address _leaderAddr, 
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) override public onlyOwner {
    require(!initialized, "AI");

    _updateLeaderInfo(
      _depositCopycatFee,
      _depositPercentageFee,
      _level,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar
    );

    transferOwnership(_leaderAddr);

    initialized = true;

    emit Initialize(msg.sender, _leaderAddr, _depositCopycatFee, _depositPercentageFee, _level);
  }

  event UpdateLeaderInfo(
    address indexed updater,
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level
  );
  function updateLeaderInfo(
    uint256 _depositCopycatFee,
    uint256 _depositPercentageFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) external onlyOwner {
    require(_level < 3, "L");

    if (_level == level) {
      factory.collectLeaderFee(msg.sender, factory.FEE_LIST(0));
    } else {
      factory.collectLeaderFee(msg.sender, factory.FEE_LIST(_level));
    }

    _updateLeaderInfo(
      _depositCopycatFee,
      _depositPercentageFee,
      _level,
      _tokenName,
      _tokenSymbol,
      _description,
      _avatar
    );

    emit UpdateLeaderInfo(msg.sender, _depositCopycatFee, _depositPercentageFee, _level);
  }

  event AdminSetLevel(address indexed setter, uint256 levelBefore, uint256 level);
  function adminSetLevel(uint256 _level) public {
    require(msg.sender == factory.owner(), "NO");
    emit AdminSetLevel(msg.sender, level, _level);
    level = _level;
  }

  // event SetWithdrawFeeRate(address indexed setter, uint256 oldRate, uint256 newRate);
  // function setWithdrawFeeRate(uint256 _withdrawFeeRate) override public onlyOwner {
  //   require(_withdrawFeeRate <= 2000, "Too greedy");
  //   emit SetWithdrawFeeRate(msg.sender, withdrawFeeRate, _withdrawFeeRate);
  //   withdrawFeeRate = _withdrawFeeRate;
  // }

  function getAdapters() override external view returns(ICopycatAdapter[] memory) {
    return adapters;
  }

  function getAdaptersLength() override external view returns(uint256) {
    return adapters.length;
  }

  function getAdaptersBnb() override public view returns(uint256[] memory) {
    uint256[] memory bnbValues = new uint[](adapters.length + 2);
    uint256 totalBnb = 0;

    // Bnb value of adapters
    for (uint256 i = 0; i < adapters.length; i++) {
      if (address(adapters[i]) != address(0)) {
        uint256 bnbValue = adapters[i].getBnbValue();
        totalBnb += bnbValue;
        bnbValues[i] = bnbValue;
      } else {
        bnbValues[i] = 0;
      }
    }

    // Bnb value of this contract
    bnbValues[adapters.length] = address(this).balance;
    totalBnb += address(this).balance;

    // Append total BNB
    bnbValues[adapters.length + 1] = totalBnb;

    return bnbValues;
  }

  function getShareRatioSaveGas(uint256 totalBnb) override public view returns(uint256) {
    if (totalSupply() == 0) return 1e18;
    return totalBnb * 1e18 / totalSupply();
  }

  function getShareRatio() override public view returns(uint256) {
    return getShareRatioSaveGas(getAdaptersBnb()[adapters.length + 1]);
  }

  // Add existing initialized adapter to this leader
  event AddAdapter(address indexed adder, address indexed adapter);
  function addAdapter(ICopycatAdapter adapter) override nonReentrant public {
    require(!disabled, "D");
    require(factory.registeredAdapterFactory(msg.sender), "F");
    require(adapter.getLeaderContract() == this, "WC");
    require(adapter.getLeaderAddress() == owner(), "WL");
    
    adapters.push(adapter);
    emit AddAdapter(msg.sender, address(adapter));
  }

  // Emergency only: Remove adapter
  event RemoveAdapter(address indexed remover, uint256 indexed adpterId, address indexed adapter);
  function removeAdapter(uint256 adapterId) override public nonReentrant onlyOwner {
    require(
      adapters[adapterId].getBnbValue() == 0 || 
      CopycatAdapterFactoryBase(adapters[adapterId].factory()).allowEmergencySignature(adapters[adapterId].contractSignature()) >= 2, 
      "F");
    adapters[adapterId] = ICopycatAdapter(address(0));
  }

  // New follower deposit BNB to CopycatLeader and earn CopycatLeader share
  event Deposit(address indexed depositer, address indexed to, uint256 amount, uint256 totalShare, uint256 shareRatio);
  function depositTo(address to, uint256 shareMin) override public payable onlyEOA nonReentrant returns (uint256 totalShare, uint256 shareRatio) {
    require(!disabled, "D");

    uint256 value = msg.value;

    // Collect CPC fee
    if (msg.sender != address(factory)) {
      factory.collectLeaderFee(msg.sender, depositCopycatFee * factory.COPYCAT_FEE_BASE() / 1e18);
    }

    uint256[] memory bnbValues = getAdaptersBnb();

    // Minus recently added BNB
    bnbValues[adapters.length] -= value;
    bnbValues[adapters.length + 1] -= value;

    uint256 totalBnb = bnbValues[adapters.length + 1];
    shareRatio = getShareRatioSaveGas(totalBnb);

    // console.log("Total BNB", bnbValues[0], totalBnb);

    // Distribute BNB to leader
    if (totalBnb > 0) {
      for (uint256 i = 0; i < adapters.length; i++) {
        uint256 bnbToDistribute = value * bnbValues[i] / totalBnb;
        if (bnbToDistribute > 10 && address(adapters[i]) != address(0)) {
          // -10 to avoid rounding error
          adapters[i].toAdapter{value: bnbToDistribute - 10}(0);
        }
      }
    }

    uint256 totalReceived = getAdaptersBnb()[adapters.length + 1] - totalBnb;

    if (msg.value < totalReceived) {
      totalReceived = msg.value;
    }

    totalShare = totalReceived * 1e18 / shareRatio;

    // uint256 depositFee = totalReceived * depositFeeRate / 10000;

    // if (depositFeeRate > 0) {
    //   uint256 devFee = depositFee / 5;
    //   totalReceived -= depositFee;
    //   _mint(factory.feeAddress(), devFee);
    //   _mint(owner(), depositFee - devFee);
    // }

    uint256 shareFee = totalShare * depositPercentageFee / 1e18;

    if (msg.sender == address(factory) || msg.sender == owner()) {
      shareFee = 0;
    }

    totalShare -= shareFee;

    require(totalShare >= shareMin, "IO");

    _mint(owner(), shareFee * 6 / 10);
    _mint(factory.feeAddress(), shareFee * 4 / 10);
    _mint(to, totalShare);
    emit Deposit(msg.sender, to, value, totalShare, shareRatio);

    // Emit event to factory to make it globally trackable
    factory.emitDeposit(to, level, value);
  }

  function deposit(uint256 shareMin) override public payable returns (uint256 totalShare, uint256 shareRatio) {
    (totalShare, shareRatio) = depositTo(msg.sender, shareMin);
  }

  /*event DepositUsingToken(
    address indexed depositer,
    address indexed token,
    address indexed router,
    uint256 tokenAmount,
    uint256 bnbOutputAmount,
    uint256 shareOutputAmount
  );
  function depositUsingToken(uint256 tokenAmount, address router, uint256 shareMin, address[] calldata path) override public returns (uint256) {
    uint256 bnbBefore = address(this).balance;
    
    IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 bnbOutputAmount = address(this).balance - bnbBefore;

    uint256 shareOutputAmount = _deposit(bnbOutputAmount, shareMin);

    emit DepositUsingToken(msg.sender, path[0], router, tokenAmount, bnbOutputAmount, shareOutputAmount);
  }*/
  
  event Withdraw(address indexed withdrawer, address indexed to, uint256 amount, uint256 outputAmount, uint256 shareRatio);
  // function withdrawFromMigration(address to, uint256 amount, uint256 bnbMin) internal returns (uint256 outputAmount) {
  //   // if (msg.sender != migratedFrom) {
  //   //   factory.collectLeaderFee(msg.sender, withdrawCopycatFee * factory.COPYCAT_FEE_BASE() / 1e18);
  //   // }

  //   _burn(msg.sender, amount);
  //   outputAmount = migratedTo.withdraw(amount, bnbMin);

  //   if (outputAmount <= address(this).balance) {
  //     require(outputAmount >= bnbMin, "IO");
  //     payable(to).transfer(outputAmount);
  //   } else {
  //     require(address(this).balance >= bnbMin, "IO");
  //     outputAmount = address(this).balance;
  //     payable(to).transfer(outputAmount);
  //   }
    
  //   emit Withdraw(msg.sender, amount, outputAmount, 0);

  //   // Don't emit global withdraw because already emitted at leaf leader
  // }

  function withdrawTo(address to, uint256 amount, uint256 bnbMin) override onlyEOA nonReentrant public returns (uint256 outputAmount, uint256 shareRatio) {
    // if (address(migratedTo) == address(0)) {
      // Collect CPC fee
      // if (msg.sender != migratedFrom) {
      //   factory.collectLeaderFee(msg.sender, withdrawCopycatFee * factory.COPYCAT_FEE_BASE() / 1e18);
      // }

      // uint256 withdrawFee = amount * withdrawFeeRate / 10000;
      uint256[] memory bnbValues = getAdaptersBnb();
      uint256 totalBnb = bnbValues[adapters.length + 1];
      shareRatio = getShareRatioSaveGas(totalBnb);

      // shareRatio in 1e18 unit, percentage in 1e18 unit
      // optimisticAmountInBnb = shareRatio * (amount - withdrawFee)
      // uint256 percentage = shareRatio * (amount - withdrawFee) / totalBnb;
      uint256 percentage = shareRatio * amount / totalBnb;

      if (percentage == 0) {
        return (0, shareRatio);
      }

      uint256 beforeBnb = address(this).balance;

      // Withdraw BNB from adapters
      for (uint256 i = 0; i < adapters.length; i++) {
        if (address(adapters[i]) != address(0) && bnbValues[i] > 10) {
          adapters[i].toLeader(bnbValues[i] * percentage / 1e18, 0);
        }
      }

      outputAmount = address(this).balance - beforeBnb * (1e18 - percentage) / 1e18;

      // console.log(outputAmount, address(this).balance);

      _burn(msg.sender, amount);
      // if (withdrawFeeRate > 0) {
      //   uint256 devFee = withdrawFee / 5;
      //   _mint(factory.feeAddress(), devFee);
      //   _mint(owner(), withdrawFee - devFee);
      // }
      
      if (outputAmount <= address(this).balance) {
        require(outputAmount >= bnbMin, "IO");
        payable(to).transfer(outputAmount);
      } else {
        require(address(this).balance >= bnbMin, "IO");
        outputAmount = address(this).balance;
        payable(to).transfer(outputAmount);
      }
      
      emit Withdraw(msg.sender, to, amount, outputAmount, shareRatio);

      // Emit event to factory to make it globally trackable
      factory.emitWithdraw(to, level, outputAmount);
    // } else {
    //   return withdrawFromMigration(to, amount, bnbMin);
    // }
  }

  function withdraw(uint256 amount, uint256 bnbMin) override public returns (uint256 outputAmount, uint256 shareRatio) {
    (outputAmount, shareRatio) = withdrawTo(msg.sender, amount, bnbMin);
  }

  /*event WithdrawToToken(
    address indexed withdrawer,
    address indexed token,
    address indexed router,
    uint256 shareAmount,
    uint256 bnbOutputAmount,
    uint256 tokenOutputAmount
  );
  function withdrawToToken(uint256 shareAmount, address router, uint256 tokenMin, address[] calldata path) override public returns (uint256 tokenOutputAmount) {
    uint256 bnbOutputAmount = withdrawTo(address(this), shareAmount, 0);
    
    address token = path[path.length - 1];
    uint256 tokenBefore = IERC20(token).balanceOf(address(this));
    
    IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbOutputAmount}(
      tokenMin,
      path,
      address(this),
      block.timestamp
    );

    tokenOutputAmount = IERC20(token).balanceOf(address(this)) - tokenBefore;
    IERC20(token).transfer(msg.sender, tokenOutputAmount);

    emit WithdrawToToken(msg.sender, token, router, shareAmount, bnbOutputAmount, tokenOutputAmount);
  }*/
  
  event ToAdapter(uint256 indexed adapterId, uint256 amountBnb, uint256 tokenMin);
  function toAdapter(uint256 adapterId, uint256 amountBnb, uint256 tokenMin) public override onlyEOA nonReentrant onlyOwner returns(uint256) {
    require(!disabled, "D");
    emit ToAdapter(adapterId, amountBnb, tokenMin);
    return adapters[adapterId].toAdapter{value: amountBnb}(tokenMin);
  }
  
  event ToLeader(uint256 indexed adapterId, uint256 amountBnb, uint256 bnbMin);
  function toLeader(uint256 adapterId, uint256 amountBnb, uint256 bnbMin) public override onlyEOA nonReentrant onlyOwner returns(uint256) {
    require(!disabled, "D");
    emit ToLeader(adapterId, amountBnb, bnbMin);
    return adapters[adapterId].toLeader(amountBnb, bnbMin);
  }

  /**
    * @dev Returns the name of the token.
    */
  function name() public view virtual override returns (string memory) {
    return tokenName;
  }

  /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
  function symbol() public view virtual override returns (string memory) {
    return tokenSymbol;
  }

  function allowEmergencyCall(ICopycatEmergencyAllower allower, bytes32 txHash) public override view returns(bool) {
    return msg.sender == owner() && factory.isAllowEmergency(allower) && allower.isAllowed(txHash);
  }

  // Migration system
  // event Upgrade(address indexed caller, uint256 shareAmount);
  // function upgrade(uint256 amount) public override {
  //   require(address(migratedTo) != address(0), "No");
  //   _burn(msg.sender, amount);
  //   migratedTo.transfer(msg.sender, amount);
  //   emit Upgrade(msg.sender, amount);
  // }

  // event MigrationMintShare(address indexed migratedFrom, uint256 amount);
  // function migrationMintShare(uint256 amount) public override {
  //   require(!initialized, "I");

  //   migratedFrom = msg.sender;
  //   _mint(msg.sender, amount);

  //   emit MigrationMintShare(msg.sender, amount);
  // }

  // Used to do profit sharing. Adapter must be approved by Copycat team. If adapter's code is not malcious, it is safe to allow this ability
  event AdapterMintShare(address indexed adapter, address indexed to, uint256 amount);
  function adapterMintShare(address to, uint256 amount, uint256 adapterId) external nonReentrant override {
    require(address(adapters[adapterId]) == msg.sender, "I");
    _mint(to, amount);
    emit AdapterMintShare(msg.sender, to, amount);
  }

  event Disable(address indexed disabler);
  function disable() public override onlyOwner {
    disabled = true;

    uint256[] memory bnbValues = getAdaptersBnb();

    for (uint256 i = 0; i < adapters.length; i++) {
      if (address(adapters[i]) != address(0)) {
        if (bnbValues[i] > 0) {
          adapters[i].toLeader(bnbValues[i], 0);
        }
        adapters[i] = ICopycatAdapter(address(0));
      }
    }

    emit Disable(msg.sender);
  }

  // event MigrateTo(address indexed migrator, address indexed to);
  // function migrateTo(ICopycatLeader to) public override {
  //   require(address(migratedTo) == address(0), "M");

  //   disabled = true;

  //   require(msg.sender == address(factory), "NF");

  //   migratedTo = to;

  //   // Move bnb from this contract to new leader
  //   payable(address(to)).transfer(address(this).balance);

  //   // Mint share on new leader
  //   to.migrationMintShare(totalSupply());

  //   // Move adapters to new leader
  //   for (uint256 i = 0; i < adapters.length; i++) {
  //     adapters[i].migrateTo(to);
  //     to.addAdapter(adapters[i]);
  //     adapters[i] = ICopycatAdapter(address(0));
  //   }

  //   emit MigrateTo(msg.sender, address(to));
  // }

  // Use fixed name on initialization instead

  // event EjectNameNft(address indexed setter, uint256 oldNftTokenId);
  // function ejectNameNft() public onlyOwner {
  //   require(nameNftTokenId != 0, "Ejected");
  //   nameNft.safeTransferFrom(address(this), msg.sender, nameNftTokenId);
  //   emit EjectNameNft(msg.sender, nameNftTokenId);
  //   nameNftTokenId = 0;
  // }

  // event InjectNameNft(address indexed setter, uint256 tokenId);
  // function injectNameNft(uint256 tokenId) public onlyOwner {
  //   if (nameNftTokenId != 0) {
  //     ejectNameNft();
  //   }

  //   nameNft.safeTransferFrom(msg.sender, address(this), tokenId);
  //   nameNftTokenId = tokenId;
  //   emit InjectNameNft(msg.sender, tokenId);
  // }
}

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICopycatEmergencyMaster.sol";
import "../interfaces/ICopycatEmergencyAllower.sol";

contract CopycatEmergencyMaster is Ownable, ICopycatEmergencyMaster {
  mapping(ICopycatEmergencyAllower => bool) public override isAllowEmergency;

  event AllowEmergency(address indexed caller, ICopycatEmergencyAllower indexed allower, bool indexed allowed);
  function allowEmergency(ICopycatEmergencyAllower allower, bool allowed) external override onlyOwner {
    isAllowEmergency[allower] = allowed;
    emit AllowEmergency(msg.sender, allower, allowed);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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

pragma solidity >=0.6.6;

import "./ICopycatLeader.sol";

/**
  Adapter for CopycatLeader

  Example mode: swap / farm
*/
interface ICopycatAdapter {
  // Factory
  function factory() external returns(address);

  // Signature system for emergency use
  function adapterType() external view returns(string memory);
  function contractSignature() external view returns(bytes32);

  // Initialize the adapter and bond it to leader
  function initializeLeader(ICopycatLeader _leaderContract) external;
  function getLeaderContract() external view returns(ICopycatLeader);
  function getLeaderAddress() external view returns(address);

  // Transfer BNB from leader to adapter and then convert BNB = msg.value to xxx
  function toAdapter(uint256 tokenMin) external payable returns(uint256);

  // Adapter sell xxx to BNB and transfer to leader (sell only ... percent (100% = 1e18)), returns BNB value
  function toLeader(uint256 bnbAmount, uint256 bnbMin) external returns(uint256);

  // Sum of BNB value in all mode
  function getBnbValue() external view returns(uint256);

  function approveSubAdapter(uint256 adapterId, uint256 amount) external;
}

pragma solidity >=0.6.6;

import "./ICopycatAdapter.sol";
import "../CopycatLeaderFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Copycat Leader with NFT renaming support
interface ICopycatLeader is IERC20 {
  function adapters(uint256 i) external view returns(ICopycatAdapter);

  function initialize(
    address _leaderAddr, 
    uint256 _depositCopycatFee,
    uint256 _withdrawCopycatFee,
    uint256 _level,
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _description,
    string memory _avatar
  ) external;

  // Setting fee is not allowed
  // function setDepositFeeRate(uint256 _depositFeeRate) external;
  // function setWithdrawFeeRate(uint256 _withdrawFeeRate) external;

  function getAdapters() external view returns(ICopycatAdapter[] memory);
  function getAdaptersLength() external view returns(uint256);

  // function getBnbInContract() external view returns(uint256);
  function getAdaptersBnb() external view returns(uint256[] memory);
  function getShareRatioSaveGas(uint256 totalBnb) external view returns(uint256);
  function getShareRatio() external view returns(uint256);
  function addAdapter(ICopycatAdapter adapter) external;

  function depositTo(address to, uint256 shareMin) external payable returns (uint256 totalShare, uint256 shareRatio);
  function deposit(uint256 shareMin) external payable returns (uint256 totalShare, uint256 shareRatio);
  //function depositUsingToken(uint256 tokenAmount, address router, uint256 shareMin, address[] calldata path) external returns (uint256);
  function withdraw(uint256 amount, uint256 bnbMin) external returns (uint256 outputAmount, uint256 shareRatio);
  function withdrawTo(address to, uint256 amount, uint256 bnbMin) external returns (uint256 outputAmount, uint256 shareRatio);
  //function withdrawToToken(uint256 shareAmount, address router, uint256 tokenMin, address[] calldata path) external returns (uint256 tokenOutputAmount);

  function toAdapter(uint256 adapterId, uint256 amountBnb, uint256 tokenMin) external returns(uint256);
  function toLeader(uint256 adapterId, uint256 percentage, uint256 bnbMin) external returns(uint256);

  function adapterMintShare(address to, uint256 amount, uint256 adapterId) external;

  function removeAdapter(uint256 adapterId) external;

  function disable() external;
  // function upgrade(uint256 amount) external;
  // function migrateTo(ICopycatLeader to) external;
  // function migrationMintShare(uint256 amount) external;

  function factory() external view returns(CopycatLeaderFactory);
  function depositCopycatFee() external view returns(uint256);
  function depositPercentageFee() external view returns(uint256);
  // function withdrawCopycatFee() external view returns(uint256);

  function level() external view returns(uint256);
  function disabled() external view returns(bool);
  // function migratedTo() external view returns(ICopycatLeader);
  // function migratedFrom() external view returns(address);
}

pragma solidity 0.8.7;

import "../interfaces/ICopycatLeader.sol";
import "../interfaces/ICopycatAdapter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CopycatEmergencyMaster.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract CopycatAdapterFactoryBase is CopycatEmergencyMaster, ReentrancyGuard {
  event NewAdapter(address indexed adapterContract, address indexed leaderContract, address indexed leader);
  uint256 public nextAdapterId = 0;
  address[] public adapters;

  mapping(bytes32 => uint256) public allowEmergencySignature;

  event SetAllowEmergencySignature(address indexed setter, bytes32 signature, uint256 level);
  function setAllowEmergencySignature(bytes32 signature, uint256 level) public onlyOwner {
    allowEmergencySignature[signature] = level;
    emit SetAllowEmergencySignature(msg.sender, signature, level);
  }

  modifier onlyLeader(address leaderContract) {
    require(Ownable(leaderContract).owner() == msg.sender, "NL");
    _;
  }

  function finalize(address leaderContract, address adapter) internal {
    ICopycatLeader(leaderContract).factory().setContractWhitelist(leaderContract, true);

    adapters.push(adapter);
    ICopycatLeader(leaderContract).addAdapter(ICopycatAdapter(adapter));
    emit NewAdapter(adapter, leaderContract, Ownable(leaderContract).owner());
    nextAdapterId++;
  }
}

pragma solidity 0.8.7;

import "../interfaces/ICopycatEmergencyAllower.sol";

// Emergency protocol adapted from Timelock system
abstract contract CopycatEmergency {
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;

    function allowEmergencyCall(ICopycatEmergencyAllower allower, bytes32 txHash) public virtual view returns(bool);

    function executeTransaction(ICopycatEmergencyAllower allower, address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        // require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));

        // We read from global control instead
        require(allowEmergencyCall(allower, txHash), "A");
        // require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(block.timestamp >= eta, "B");
        require(block.timestamp <= eta + GRACE_PERIOD, "C");

        // queuedTransactions[txHash] = false;

        allower.beforeExecute(txHash);

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "D");

        allower.afterExecute(txHash);

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity >=0.6.6;

import "../interfaces/ICopycatEmergencyAllower.sol";

interface ICopycatEmergencyMaster {
  function isAllowEmergency(ICopycatEmergencyAllower allower) external view returns(bool);
  function allowEmergency(ICopycatEmergencyAllower allower, bool allowed) external;
}

pragma solidity >=0.6.6;

interface ICopycatEmergencyAllower {
  function isAllowed(bytes32 txHash) external view returns(bool);
  function beforeExecute(bytes32 txHash) external;
  function afterExecute(bytes32 txHash) external;
}

