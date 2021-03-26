pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import { WeddingInvitationToken, WeddingWitnessToken } from "./Tokens.sol";


contract GuestBook {
    event GuestbookSignatureAdded(uint timestamp, address wallet, string name, string message);
    event GuestInvited(uint timestamp, address wallet, address from);

    address payable public spouse1Address;
    address payable public spouse2Address;
    address public owner;

    address[] invitationList;
    mapping (address => bool) private isInvited;

    WeddingInvitationToken invitationToken = new WeddingInvitationToken();
    WeddingWitnessToken witnessToken = new WeddingWitnessToken();

    struct GuestBookEntry {
        address sender;
        string name;
        string message;
    }
    GuestBookEntry[] guestBook;

    /**
     * @dev Constructor: Set the wallet addresses of both spouses.
     * @param _spouse1Address Wallet address of spouse1.
     * @param _spouse2Address Wallet address of spouse2.
     */
    constructor(address payable _spouse1Address, address payable _spouse2Address) public {
        require(_spouse1Address != address(0), "Spouse1 address must not be zero!");
        require(_spouse2Address != address(0), "Spouse2 address must not be zero!");
        require(_spouse1Address != _spouse2Address, "Spouse1 address must not equal Spouse2 address!");

        spouse1Address = _spouse1Address;
        isInvited[spouse1Address] = true;
        invitationList.push(spouse1Address);

        spouse2Address = _spouse2Address;
        isInvited[spouse2Address] = true;
        invitationList.push(spouse2Address);
    }

    /**
     * @dev Modifier that only allows contract owner execution.
      */
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not contract owner!");
        _;
    }

    /**
     * @dev Modifier that only allows spouse execution.
      */
    modifier onlySpouse() {
        require(msg.sender == spouse1Address || msg.sender == spouse2Address, "Sender is not a spouse!");
        _;
    }

    /**
     * @dev Modifier that only allows invited member execution.
      */
    modifier onlyInvited() {
        require(isInvited[msg.sender], "Sender is not invited!");
        _;
    }

    /**
     * @dev Set contract owner
     */
    function setContractOwner(address _owner) public {
        require(owner == address(0), "Owner already set");
        owner = _owner;
    }

    /**
     * @dev Invite someone to your wedding
     */
    function sendInvitation(address payable _to) public onlySpouse {
        require(!isInvited[_to], "Person has already been invited!");
        if (invitationToken.balanceOf(address(this)) > 0) {
            invitationToken.transfer(_to, 1);
            isInvited[_to] = true;
            invitationList.push(_to);
            emit GuestInvited(now, _to, msg.sender);
        }
    }

    /**
     * @dev Sign the guest book
     */
    function signGuestBook(string memory name, string memory message) public onlyInvited {
        GuestBookEntry memory entry = GuestBookEntry({
            sender: msg.sender,
            name: name,
            message: message
        });
        guestBook.push(entry);
        emit GuestbookSignatureAdded(now, msg.sender, name, message);
    }

    /**
     * @dev Get guest book entries
     */
    function getGuestBookEntries() public view returns (GuestBookEntry[] memory) {
        return guestBook;
    }

    /**
     * @dev Send witness tokens
     */
    function sendWitnessTokens() public onlyOwner {
        for (uint i = 0; i < invitationList.length; i++) {
            if (witnessToken.balanceOf(address(this)) > 0) {
                witnessToken.transfer(invitationList[i], 1);
            }
        }
    }

    /**
     * @dev Get address to WitnessToken
     */
    function getWitnessTokenAddress() public view returns (address) {
        return address(witnessToken);
    }

    /**
     * @dev Get address to InvitationToken
     */
    function getInvitationTokenAddress() public view returns (address) {
        return address(invitationToken);
    }

}

pragma solidity ^0.5.0;

import { GuestBook } from "./GuestBook.sol";


/**
 * @title SmartWeddingContract
 * @dev The contract has both addresses of spouse1 and spouse2. It is capable of handling assets, funds and
 * divorce. A multisig variant is used to consider the decision of both parties.
 */
contract SmartWeddingContract {
  event WrittenContractProposed(uint timestamp, string ipfsHash, address wallet);
  event Signed(uint timestamp, address wallet);
  event ContractSigned(uint timestamp);
  event AssetProposed(uint timestamp, string asset, address wallet);
  event AssetAddApproved(uint timestamp, string asset, address wallet);
  event AssetAdded(uint timestamp, string asset);
  event AssetRemoveApproved(uint timestamp, string asset, address wallet);
  event AssetRemoved(uint timestamp, string asset);
  event DivorceApproved(uint timestamp, address wallet);
  event Divorced(uint timestamp);
  event FundsSent(uint timestamp, address wallet, uint amount);
  event FundsReceived(uint timestamp, address wallet, uint amount);

  bool public signed = false;
  bool public divorced = false;

  mapping (address => bool) private hasSigned;
  mapping (address => bool) private hasDivorced;

  address payable public spouse1Address;
  address payable public spouse2Address;
  string public writtenContractIpfsHash;
  address public guestBookAddress;

  struct Asset {
    string data;
    uint spouse1Allocation;
    uint spouse2Allocation;
    bool added;
    bool removed;
    mapping (address => bool) hasApprovedAdd;
    mapping (address => bool) hasApprovedRemove;
  }

  Asset[] public assets;

  /**
   * @dev Modifier that only allows spouse execution.
    */
  modifier onlySpouse() {
    require(msg.sender == spouse1Address || msg.sender == spouse2Address, "Sender is not a spouse!");
    _;
  }

  /**
   * @dev Modifier that checks if the contract has been signed by both spouses.
    */
  modifier isSigned() {
    require(signed == true, "Contract has not been signed by both spouses yet!");
    _;
  }

  /**
   * @dev Modifier that only allows execution if the spouses have not been divorced.
    */
  modifier isNotDivorced() {
    require(divorced == false, "Can not be called after spouses agreed to divorce!");
    _;
  }

  /**
   * @dev Private helper function to check if a string is not equal to another.
   */
  function isNotSameString(string memory string1, string memory string2) private pure returns (bool) {
    return keccak256(abi.encodePacked(string1)) != keccak256(abi.encodePacked(string2));
  }

  /**
   * @dev Constructor: Set the wallet addresses of both spouses.
   * @param _spouse1Address Wallet address of spouse1.
   * @param _spouse2Address Wallet address of spouse2.
   */
  constructor(address payable _guestBookAddress, address payable _spouse1Address, address payable _spouse2Address) public {
    require(_guestBookAddress != address(0), "GuestBook address must not be zero!");
    require(_spouse1Address != address(0), "Spouse1 address must not be zero!");
    require(_spouse2Address != address(0), "Spouse2 address must not be zero!");
    require(_spouse1Address != _spouse2Address, "Spouse1 address must not equal Spouse2 address!");

    spouse1Address = _spouse1Address;
    spouse2Address = _spouse2Address;
    guestBookAddress = _guestBookAddress;

  }

  /**
   * @dev Default function to enable the contract to receive funds.
   */
  function() external payable isSigned isNotDivorced {
    emit FundsReceived(now, msg.sender, msg.value);
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev Propose a written contract (update).
   * @param _writtenContractIpfsHash IPFS hash of the written contract PDF.
   */
  function proposeWrittenContract(string calldata _writtenContractIpfsHash) external onlySpouse isNotDivorced {
    require(signed == false, "Written contract ipfs hash can not be changed. Both spouses have already signed it!");

    // Update written contract ipfs hash
    writtenContractIpfsHash = _writtenContractIpfsHash;

    emit WrittenContractProposed(now, _writtenContractIpfsHash, msg.sender);

    // Revoke previous signatures
    if (hasSigned[spouse1Address] == true) {
      hasSigned[spouse1Address] = false;
    }
    if (hasSigned[spouse2Address] == true) {
      hasSigned[spouse2Address] = false;
    }
  }

  /**
   * @dev Sign the contract.
   */
  function signContract() external onlySpouse {
    require(isNotSameString(writtenContractIpfsHash, ""), "Written contract ipfs hash has been proposed yet!");
    require(hasSigned[msg.sender] == false, "Spouse has already signed the contract!");

    // Sender signed
    hasSigned[msg.sender] = true;

    emit Signed(now, msg.sender);

    // Check if both spouses have signed
    if (hasSigned[spouse1Address] && hasSigned[spouse2Address]) {
      signed = true;
      GuestBook(guestBookAddress).sendWitnessTokens();
      emit ContractSigned(now);
    }
  }

  /**
   * @dev Return whether sending spouse has signed.
   */
  function senderSigned() external view onlySpouse returns (bool) {
    return hasSigned[msg.sender];
  }

  /**
   * @dev Return whether sending spouse has approved divorce.
   */
  function senderDivorced() external view onlySpouse returns (bool) {
    return hasDivorced[msg.sender];
  }

  /**
   * @dev Send ETH to a target address.
   * @param _to Destination wallet address.
   * @param _amount Amount of ETH to send.
   */
  function pay(address payable _to, uint _amount) external onlySpouse isSigned isNotDivorced {
    require(_to != address(0), "Sending funds to address zero is prohibited!");
    require(_amount <= address(this).balance, "Not enough balance available!");

    // Send funds to the destination address
    _to.transfer(_amount);

    emit FundsSent(now, _to, _amount);
  }

  /**
   * @dev Propose an asset to add. The other spouse needs to approve this action.
   * @param _data The asset represented as a string.
   * @param _spouse1Allocation Allocation of spouse1.
   * @param _spouse2Allocation Allocation of spouse2.
   */
  function proposeAsset(string calldata _data, uint _spouse1Allocation, uint _spouse2Allocation) external onlySpouse isSigned isNotDivorced {
    require(isNotSameString(_data, ""), "No asset data provided!");
    require(_spouse1Allocation >= 0, "spouse1 allocation invalid!");
    require(_spouse2Allocation >= 0, "spouse2 allocation invalid!");
    require((_spouse1Allocation + _spouse2Allocation) == 100, "Total allocation must be equal to 100%!");

    // Add new asset
    Asset memory newAsset = Asset({
      data: _data,
      spouse1Allocation: _spouse1Allocation,
      spouse2Allocation: _spouse2Allocation,
      added: false,
      removed: false
    });
    uint newAssetId = assets.push(newAsset);

    emit AssetProposed(now, _data, msg.sender);

    // Map to a storage object (otherwise mappings could not be accessed)
    Asset storage asset = assets[newAssetId - 1];

    // Instantly approve it by the sender
    asset.hasApprovedAdd[msg.sender] = true;

    emit AssetAddApproved(now, _data, msg.sender);
  }

  /**
   * @dev Approve the addition of a prior proposed asset. The other spouse needs to approve this action.
   * @param _assetId The id of the asset that should be approved.
   */
  function approveAsset(uint _assetId) external onlySpouse isSigned isNotDivorced {
    require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");

    Asset storage asset = assets[_assetId - 1];

    require(asset.added == false, "Asset has already been added!");
    require(asset.removed == false, "Asset has already been removed!");
    require(asset.hasApprovedAdd[msg.sender] == false, "Asset has already approved by sender!");

    // Sender approved
    asset.hasApprovedAdd[msg.sender] = true;

    emit AssetAddApproved(now, asset.data, msg.sender);

    // Check if both spouses have approved
    if (asset.hasApprovedAdd[spouse1Address] && asset.hasApprovedAdd[spouse2Address]) {
      asset.added = true;
      emit AssetAdded(now, asset.data);
    }
  }

  /**
   * @dev Approve the removal of a prior proposed/already added asset. The other spouse needs to approve this action.
   * @param _assetId The id of the asset that should be removed.
   */
  function removeAsset(uint _assetId) external onlySpouse isSigned isNotDivorced {
    require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");

    Asset storage asset = assets[_assetId - 1];

    require(asset.added, "Asset has not been added yet!");
    require(asset.removed == false, "Asset has already been removed!");
    require(asset.hasApprovedRemove[msg.sender] == false, "Removing the asset has already been approved by the sender!");

    // Approve removal by the sender
    asset.hasApprovedRemove[msg.sender] = true;

    emit AssetRemoveApproved(now, asset.data, msg.sender);

    // Check if both spouses have approved the removal of the asset
    if (asset.hasApprovedRemove[spouse1Address] && asset.hasApprovedRemove[spouse2Address]) {
      asset.removed = true;
      emit AssetRemoved(now, asset.data);
    }
  }

  /**
   * @dev Request to divorce. The other spouse needs to approve this action.
   */
  function divorce() external onlySpouse isSigned isNotDivorced {
    require(hasDivorced[msg.sender] == false, "Sender has already approved to divorce!");

    // Sender approved
    hasDivorced[msg.sender] = true;

    emit DivorceApproved(now, msg.sender);

    // Check if both spouses have approved to divorce
    if (hasDivorced[spouse1Address] && hasDivorced[spouse2Address]) {
      divorced = true;
      emit Divorced(now);

      // Get the contracts balance
      uint balance = address(this).balance;

      // Split the remaining balance half-half
      if (balance != 0) {
        // Ignore any remainder due to low value
        uint balancePerSpouse = balance / 2;

        // Send transfer to spouse1
        spouse1Address.transfer(balancePerSpouse);
        emit FundsSent(now, spouse1Address, balancePerSpouse);

        // Send transfer to spouse2
        spouse2Address.transfer(balancePerSpouse);
        emit FundsSent(now, spouse2Address, balancePerSpouse);
      }
    }
  }

  /**
   * @dev Return whether asset has been approved by sender.
   */
  function assetIsApproved(uint _assetId) external onlySpouse view returns (bool) {
    require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");
    Asset storage asset = assets[_assetId - 1];
    return asset.hasApprovedAdd[msg.sender];
  }

  /**
   * @dev Return whether asset has been removed by sender.
   */
  function assetIsRemoved(uint _assetId) external onlySpouse view returns (bool) {
    require(_assetId > 0 && _assetId <= assets.length, "Invalid asset id!");
    Asset storage asset = assets[_assetId - 1];
    return asset.hasApprovedRemove[msg.sender];
  }

  /**
   * @dev Return a list of all asset ids.
   */
  function getAssetIds() external view returns (uint[] memory) {
    uint assetCount = assets.length;
    uint[] memory assetIds = new uint[](assetCount);

    // Get all asset ids
    for (uint i = 1; i <= assetCount; i++) { assetIds[i - 1] = i; }

    return assetIds;
  }
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract WeddingInvitationToken is ERC20, ERC20Detailed {
    constructor() ERC20Detailed("WeddingInvitation", "INVITE", 0) public {
        _mint(msg.sender, 100);
    }
}

contract WeddingWitnessToken is ERC20, ERC20Detailed {
    constructor() ERC20Detailed("WeddingWitness", "WED", 0) public {
        _mint(msg.sender, 100);
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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