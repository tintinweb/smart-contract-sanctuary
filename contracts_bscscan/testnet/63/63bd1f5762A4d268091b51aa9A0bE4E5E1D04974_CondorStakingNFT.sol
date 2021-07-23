/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6 <0.8.0;

library EnumerableSet {

    struct Set {
        bytes32[] _values;

        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }
    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

interface IERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes memory data) external;
    function unstake(uint256 amount, bytes memory data) external;
    function totalStakedFor(address addr) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function token() external view returns (address);
    function supportsHistory() external pure returns (bool);

    // optional
    function lastStakedFor(address addr) external view returns (uint256);
    function totalStakedForAt(address addr, uint256 blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 blockNumber) external view returns (uint256);
}

interface IERC2917 {

    event InterestRatePerBlockChanged (uint256 oldValue, uint256 newValue);

    function interestsPerBlock() external view returns (uint256);
    function changeInterestRatePerBlock(uint value) external returns (bool);
    function getProductivity(address user) external view returns (uint256, uint256);
    function take() external view returns (uint256);
    function takeWithBlock() external view returns (uint256, uint256);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;
        
        _status = _NOT_ENTERED;
    }
}

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

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

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CondorWrappedERC20 is ERC20, AccessControl {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() ERC20("Condor Token", "CONDOR") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }
    
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }
    
    function burn(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _burn(to, amount);
    }
}

contract CondorStakingNFT is IERC900, IERC2917, ERC1155Holder, AccessControl, ReentrancyGuard, Pausable {
    
    using SafeMath for uint256;
    
    struct SporeStakerInfo {
        uint256 totalAmountStaked;
        uint256 rewardPending;
        uint256 rewardDebt;
    }
    
    struct Checkpoint {
        uint256 at;
        uint256 amount;
    }
    
    CondorWrappedERC20 public CONDOR;
    IERC20 public powSPORE;
    IERC1155 public NFT;
    Checkpoint[] public stakeHistory;
    
    uint256 private _totalStaked;
    uint256 private _blockReward;
    
    uint256 public lastRewardBlock;
    uint256 public accAmountPerShare;
    
    uint256 public _poolKEY;
    uint256 public _exchangeRelationRatio;
    
    mapping(address => SporeStakerInfo) public stakers;
    mapping (address => Checkpoint[]) public stakesFor;
    
    event RewardsClaimed(address staker, uint256 amount);
    event KeyTokenChanged(uint256 oldID, uint256 newID);
    
    modifier update() {
        if(block.number > lastRewardBlock && block.number.sub(lastRewardBlock) > 0){
            if(_totalStaked == 0){
                lastRewardBlock = block.number;
            }
            else {
                uint256 multiplier = block.number.sub(lastRewardBlock);
                uint256 reward = multiplier.mul(_blockReward);
                
                accAmountPerShare = accAmountPerShare.add(reward.mul(1e18).div(_totalStaked));
                lastRewardBlock = block.number;
            }
        }
        _;
    }
    
    constructor(CondorWrappedERC20 _CONDOR, IERC20 _powSPORE, IERC1155 _NFT, uint256 _key, uint256 _reward, uint256 _relationRatio) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        CONDOR = _CONDOR;
        powSPORE = _powSPORE;
        NFT = _NFT;
        
        _poolKEY = _key;
        _blockReward = _reward;
        _exchangeRelationRatio = _relationRatio;
    }
    
    function getPoolKeyToken() public view returns (uint256) {
        return _poolKEY;
    }
    
    function changePoolKeyToken(uint256 id) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        
        uint256 old = _poolKEY;
        _poolKEY = id;

        emit KeyTokenChanged(old, id);
        return true;
    }
    
    function _getUpdatedAccAmountPerShare() internal view virtual returns (uint256 _accAmountPerShare) {
        _accAmountPerShare = accAmountPerShare;
        
        if (block.number > lastRewardBlock && _totalStaked != 0) {
            uint256 multiplier = block.number.sub(lastRewardBlock);
            uint256 reward = multiplier.mul(_blockReward);
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e18).div(_totalStaked));
        }
        
        return _accAmountPerShare;
    }
    
    function getUserAvailableStaking(address addr) public view returns (uint256) {
        uint256 availableBalance = 0;
        
        if(powSPORE.balanceOf(addr) > 0){
            availableBalance = powSPORE.balanceOf(addr).div(_exchangeRelationRatio);
            
            if(stakers[addr].totalAmountStaked > 0) {
                availableBalance = availableBalance.sub(stakers[addr].totalAmountStaked);
            }
        }
        
        return availableBalance;
    }
    
    function stake(uint256 amount, bytes memory data) public override nonReentrant whenNotPaused update {
        require(amount > 0, "Cannot stake 0");
        require(getUserAvailableStaking(_msgSender()) >= amount, "You cannot stake that amount, more spore power needed.");
        
        updateCheckpointAtNow(stakesFor[_msgSender()], amount, false);
        updateCheckpointAtNow(stakeHistory, amount, false);
        
        SporeStakerInfo storage staker = stakers[_msgSender()];
        if (staker.totalAmountStaked > 0) {
            uint256 pending = staker.totalAmountStaked.mul(accAmountPerShare).div(1e18).sub(staker.rewardDebt);
            staker.rewardPending = staker.rewardPending.add(pending);
        }
        
        staker.totalAmountStaked = staker.totalAmountStaked.add(amount);
        staker.rewardDebt = staker.totalAmountStaked.mul(accAmountPerShare).div(1e18);
        _totalStaked = _totalStaked.add(amount);
        
        NFT.safeTransferFrom(_msgSender(), address(this), _poolKEY, amount, data);
        
        emit Staked(_msgSender(), amount, staker.totalAmountStaked, data);
    }
    
    
    function unstake(uint256 amount, bytes memory data) public override nonReentrant whenNotPaused update {
        require(_msgSender() != address(0), "transfer from the zero address");
        require(stakers[_msgSender()].totalAmountStaked >= amount, "amount exceeds your total staked balance");
        
        updateCheckpointAtNow(stakesFor[_msgSender()], amount, true);
        updateCheckpointAtNow(stakeHistory, amount, true);
        
        SporeStakerInfo storage staker = stakers[_msgSender()];
       
        uint256 pending = staker.totalAmountStaked.mul(accAmountPerShare).div(1e18).sub(staker.rewardDebt);
        staker.rewardPending = staker.rewardPending.add(pending);
        
        staker.totalAmountStaked = staker.totalAmountStaked.sub(amount);
        staker.rewardDebt = staker.totalAmountStaked.mul(accAmountPerShare).div(1e18);
        _totalStaked = _totalStaked.sub(amount);
        
        NFT.safeTransferFrom(address(this), _msgSender(), _poolKEY, amount, data);
        
        emit Unstaked(_msgSender(), amount, staker.totalAmountStaked, data);
    }

    function totalStakedFor(address addr) public view override returns (uint256) {
        return stakers[addr].totalAmountStaked;
    }

    function totalStaked() public view override returns (uint256) {
        return _totalStaked;
    }
    
    function supportsHistory() public pure override returns (bool) {
        return true;
    }
    
    function lastStakedFor(address addr) public view override returns (uint256) {
        Checkpoint[] storage stakes = stakesFor[addr];

        if (stakes.length == 0) {
            return 0;
        }

        return stakes[stakes.length-1].at;
    }

    function totalStakedForAt(address addr, uint256 blockNumber) public view override returns (uint256) {
        return stakedAt(stakesFor[addr], blockNumber);
    }

    function totalStakedAt(uint256 blockNumber) public view override returns (uint256) {
        return stakedAt(stakeHistory, blockNumber);
    }
    
    function token() public view override returns (address) {
        return address(powSPORE);
    }

    function updateCheckpointAtNow(Checkpoint[] storage history, uint256 amount, bool isUnstake) internal {

        uint256 length = history.length;
        if (length == 0) {
            history.push(Checkpoint({at: block.number, amount: amount}));
            return;
        }

        if (history[length-1].at < block.number) {
            history.push(Checkpoint({at: block.number, amount: history[length-1].amount}));
        }

        Checkpoint storage checkpoint = history[length];

        if (isUnstake) {
            checkpoint.amount = checkpoint.amount.sub(amount);
        } else {
            checkpoint.amount = checkpoint.amount.add(amount);
        }
    }

    function stakedAt(Checkpoint[] storage history, uint256 blockNumber) internal view returns (uint256) {
        uint256 length = history.length;

        if (length == 0 || blockNumber < history[0].at) {
            return 0;
        }

        if (blockNumber >= history[length-1].at) {
            return history[length-1].amount;
        }

        uint min = 0;
        uint max = length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (history[mid].at <= blockNumber) {
                min = mid;
            } else {
                max = mid-1;
            }
        }

        return history[min].amount;
    }
    
    function changeInterestRatePerBlock(uint value) external override returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        require(value != _blockReward, 'amounts are the same');
        
        uint256 old = _blockReward;
        _blockReward = value;

        emit InterestRatePerBlockChanged(old, value);
        return true;
    }
    
    function getProductivity(address user) external override view returns (uint256, uint256) {
        return (stakers[user].totalAmountStaked, _totalStaked);
    }

    function interestsPerBlock() external override view returns (uint256) {
        return accAmountPerShare;
    }
    
    function rewardPerBlock() public view returns (uint256) {
        return _blockReward;
    }
    
    function stakerShare(address user) public view returns (uint256) {
        return stakers[user].totalAmountStaked.mul(accAmountPerShare).div(1e18);
    }

    function take() external override view returns (uint256) {
        SporeStakerInfo storage staker = stakers[_msgSender()];
        uint256 _accAmountPerShare = _getUpdatedAccAmountPerShare();
        
        return staker.totalAmountStaked.mul(_accAmountPerShare).div(1e18).add(staker.rewardPending).sub(staker.rewardDebt);
    }

    function takeWithAddress(address user) external view returns (uint256) {
        SporeStakerInfo storage staker = stakers[user];
        uint256 _accAmountPerShare = _getUpdatedAccAmountPerShare();
        
        return staker.totalAmountStaked.mul(_accAmountPerShare).div(1e18).add(staker.rewardPending).sub(staker.rewardDebt);
    }

    function takeWithBlock() external override view returns (uint256, uint256) {
        SporeStakerInfo storage staker = stakers[_msgSender()];
        uint256 _accAmountPerShare = _getUpdatedAccAmountPerShare();

        return (staker.totalAmountStaked.mul(_accAmountPerShare).div(1e18).add(staker.rewardPending).sub(staker.rewardDebt), block.number);
    }
    
    function claim() public nonReentrant whenNotPaused update {
        
        SporeStakerInfo storage staker = stakers[_msgSender()];
        
        uint256 _amount = staker.totalAmountStaked.mul(accAmountPerShare).div(1e18);
        uint256 _pending = _amount.add(staker.rewardPending).sub(staker.rewardDebt);
        
        if(_pending > 0) {
            
            CONDOR.mint(_msgSender(), _pending);
            staker.rewardDebt = _amount;
            staker.rewardPending = 0;
            
            emit RewardsClaimed(_msgSender(), _pending);
        }
    }
    
    function pause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have admin role");
        _unpause();
    }
}