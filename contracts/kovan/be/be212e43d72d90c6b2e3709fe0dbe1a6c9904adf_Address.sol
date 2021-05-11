/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**

Licenses
openzeppelin-solidity: (MIT) https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/LICENSE
darknode-sol: (GNU GPL V3) https://github.com/renproject/darknode-sol/blob/master/LICENSE

*/

pragma solidity ^0.5.12;


contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

library ERC20WithFees {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    
    function safeTransferFromWithFees(IERC20 token, address from, address to, uint256 value) internal returns (uint256) {
        uint256 balancesBefore = token.balanceOf(to);
        token.safeTransferFrom(from, to, value);
        uint256 balancesAfter = token.balanceOf(to);
        return Math.min(value, balancesAfter.sub(balancesBefore));
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

contract Pausable is Context, PauserRole {
    
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract ERC20Burnable is Context, ERC20 {
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

contract BitblocksGovernanceToken is Ownable, ERC20Detailed, ERC20Pausable, ERC20Burnable {

    string private constant _name = "Bitblocks Governance Token";
    string private constant _symbol = "XBB";
    uint8 private constant _decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**uint256(_decimals);

    
    constructor() ERC20Burnable() ERC20Pausable() ERC20Detailed(_name, _symbol, _decimals) public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferTokens(address beneficiary, uint256 amount) public onlyOwner returns (bool) {
        
        
        require(amount > 0);

        _transfer(msg.sender, beneficiary, amount);
        emit Transfer(msg.sender, beneficiary, amount);

        return true;
    }
}

contract Claimable is Ownable {

    address public pendingOwner;

    modifier onlyPendingOwner() {
        require(_msgSender() == pendingOwner, "Claimable: caller is not the pending owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() public onlyPendingOwner {
        _transferOwnership(pendingOwner);
        delete pendingOwner;
    }
}

library LinkedList {

    
    address public constant NULL = address(0);

    
    struct Node {
        bool inList;
        address previous;
        address next;
    }

    
    struct List {
        mapping (address => Node) list;
    }

    
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

    
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

        
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

    
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "LinkedList: not in list");
        if (node == NULL) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

        
        
        self.list[node].inList = false;
        delete self.list[node];
    }

    
    function prepend(List storage self, address node) internal {
        

        insertBefore(self, begin(self), node);
    }

    
    function append(List storage self, address node) internal {
        

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
        

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

    
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

    
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].previous;
    }

}

contract CanReclaimTokens is Ownable {

    mapping(address => bool) private recoverableTokensBlacklist;

    function blacklistRecoverableToken(address _token) public onlyOwner {
        recoverableTokensBlacklist[_token] = true;
    }

    
    
    function recoverTokens(address _token) external onlyOwner {
        require(!recoverableTokensBlacklist[_token], "CanReclaimTokens: token is not recoverable");

        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }
}

contract DarknodeRegistryStore is Claimable, CanReclaimTokens {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    
    
    struct Darknode {
        
        
        
        
        address payable owner;

        
        
        
        uint256 bond;

        
        uint256 registeredAt;

        
        uint256 deregisteredAt;

        
        
        
        
        bytes publicKey;
    }

    
    mapping(address => Darknode) private darknodeRegistry;
    LinkedList.List private darknodes;

    
    BitblocksGovernanceToken public xbg;

    
    
    
    
    constructor(
        string memory _VERSION,
        BitblocksGovernanceToken _xbg
    ) public {
        VERSION = _VERSION;
        xbg = _xbg;
        blacklistRecoverableToken(address(xbg));
    }

    
    
    
    
    
    
    
    
    
    function appendDarknode(
        address _darknodeID,
        address payable _darknodeOwner,
        uint256 _bond,
        bytes calldata _publicKey,
        uint256 _registeredAt,
        uint256 _deregisteredAt
    ) external onlyOwner {
        Darknode memory darknode = Darknode({
            owner: _darknodeOwner,
            bond: _bond,
            publicKey: _publicKey,
            registeredAt: _registeredAt,
            deregisteredAt: _deregisteredAt
        });
        darknodeRegistry[_darknodeID] = darknode;
        LinkedList.append(darknodes, _darknodeID);
    }

    
    function begin() external view onlyOwner returns(address) {
        return LinkedList.begin(darknodes);
    }

    
    
    function next(address darknodeID) external view onlyOwner returns(address) {
        return LinkedList.next(darknodes, darknodeID);
    }

    
    
    function removeDarknode(address darknodeID) external onlyOwner {
        uint256 bond = darknodeRegistry[darknodeID].bond;
        delete darknodeRegistry[darknodeID];
        LinkedList.remove(darknodes, darknodeID);
        require(xbg.transfer(owner(), bond), "DarknodeRegistryStore: bond transfer failed");
    }

    
    
    function updateDarknodeBond(address darknodeID, uint256 decreasedBond) external onlyOwner {
        uint256 previousBond = darknodeRegistry[darknodeID].bond;
        require(decreasedBond < previousBond, "DarknodeRegistryStore: bond not decreased");
        darknodeRegistry[darknodeID].bond = decreasedBond;
        require(xbg.transfer(owner(), previousBond.sub(decreasedBond)), "DarknodeRegistryStore: bond transfer failed");
    }

    
    function updateDarknodeDeregisteredAt(address darknodeID, uint256 deregisteredAt) external onlyOwner {
        darknodeRegistry[darknodeID].deregisteredAt = deregisteredAt;
    }

    
    function darknodeOwner(address darknodeID) external view onlyOwner returns (address payable) {
        return darknodeRegistry[darknodeID].owner;
    }

    
    function darknodeBond(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].bond;
    }

    
    function darknodeRegisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].registeredAt;
    }

    
    function darknodeDeregisteredAt(address darknodeID) external view onlyOwner returns (uint256) {
        return darknodeRegistry[darknodeID].deregisteredAt;
    }

    
    function darknodePublicKey(address darknodeID) external view onlyOwner returns (bytes memory) {
        return darknodeRegistry[darknodeID].publicKey;
    }
}

interface IDarknodePaymentStore {
}

interface IDarknodePayment {
    function changeCycle() external returns (uint256);
    function store() external returns (IDarknodePaymentStore);
}

interface IDarknodeSlasher {
}

contract DarknodeRegistry is Claimable, CanReclaimTokens {
    using SafeMath for uint256;

    string public VERSION; 

    
    
    
    struct Epoch {
        uint256 epochhash;
        uint256 blocktime;
    }

    uint256 public numDarknodes;
    uint256 public numDarknodesNextEpoch;
    uint256 public numDarknodesPreviousEpoch;

    
    uint256 public minimumBond;
    uint256 public minimumPodSize;
    uint256 public minimumEpochInterval;

    
    
    uint256 public nextMinimumBond;
    uint256 public nextMinimumPodSize;
    uint256 public nextMinimumEpochInterval;

    
    Epoch public currentEpoch;
    Epoch public previousEpoch;

    
    BitblocksGovernanceToken public xbg;

    
    DarknodeRegistryStore public store;

    
    IDarknodePayment public darknodePayment;

    
    IDarknodeSlasher public slasher;
    IDarknodeSlasher public nextSlasher;

    
    
    
    
    event LogDarknodeRegistered(address indexed _operator, address indexed _darknodeID, uint256 _bond);

    
    
    
    event LogDarknodeDeregistered(address indexed _operator, address indexed _darknodeID);

    
    
    
    event LogDarknodeOwnerRefunded(address indexed _operator, uint256 _amount);

    
    
    
    
    
    event LogDarknodeSlashed(address indexed _operator, address indexed _darknodeID, address indexed _challenger, uint256 _percentage);

    
    event LogNewEpoch(uint256 indexed epochhash);

    
    event LogMinimumBondUpdated(uint256 _previousMinimumBond, uint256 _nextMinimumBond);
    event LogMinimumPodSizeUpdated(uint256 _previousMinimumPodSize, uint256 _nextMinimumPodSize);
    event LogMinimumEpochIntervalUpdated(uint256 _previousMinimumEpochInterval, uint256 _nextMinimumEpochInterval);
    event LogSlasherUpdated(address _previousSlasher, address _nextSlasher);
    event LogDarknodePaymentUpdated(IDarknodePayment _previousDarknodePayment, IDarknodePayment _nextDarknodePayment);

    
    modifier onlyDarknodeOwner(address _darknodeID) {
        require(store.darknodeOwner(_darknodeID) == msg.sender, "DarknodeRegistry: must be darknode owner");
        _;
    }

    
    modifier onlyRefunded(address _darknodeID) {
        require(isRefunded(_darknodeID), "DarknodeRegistry: must be refunded or never registered");
        _;
    }

    
    modifier onlyRefundable(address _darknodeID) {
        require(isRefundable(_darknodeID), "DarknodeRegistry: must be deregistered for at least one epoch");
        _;
    }

    
    
    modifier onlyDeregisterable(address _darknodeID) {
        require(isDeregisterable(_darknodeID), "DarknodeRegistry: must be deregisterable");
        _;
    }

    
    modifier onlySlasher() {
        require(address(slasher) == msg.sender, "DarknodeRegistry: must be slasher");
        _;
    }

    
    
    
    
    
    
    
    
    
    constructor(
        string memory _VERSION,
        BitblocksGovernanceToken _xbgAddress,
        DarknodeRegistryStore _storeAddress,
        uint256 _minimumBond,
        uint256 _minimumPodSize,
        uint256 _minimumEpochIntervalSeconds
    ) public {
        VERSION = _VERSION;

        store = _storeAddress;
        xbg = _xbgAddress;

        minimumBond = _minimumBond;
        nextMinimumBond = minimumBond;

        minimumPodSize = _minimumPodSize;
        nextMinimumPodSize = minimumPodSize;

        minimumEpochInterval = _minimumEpochIntervalSeconds;
        nextMinimumEpochInterval = minimumEpochInterval;

        currentEpoch = Epoch({
            epochhash: uint256(blockhash(block.number - 1)),
            blocktime: block.timestamp
        });
        numDarknodes = 0;
        numDarknodesNextEpoch = 0;
        numDarknodesPreviousEpoch = 0;
    }

    
    
    
    
    
    
    
    
    
    
    function register(address _darknodeID, bytes calldata _publicKey) external onlyRefunded(_darknodeID) {
        
        uint256 bond = minimumBond;

        
        require(xbg.transferFrom(msg.sender, address(store), bond), "DarknodeRegistry: bond transfer failed");

        
        store.appendDarknode(
            _darknodeID,
            msg.sender,
            bond,
            _publicKey,
            currentEpoch.blocktime.add(minimumEpochInterval),
            0
        );

        numDarknodesNextEpoch = numDarknodesNextEpoch.add(1);

        
        emit LogDarknodeRegistered(msg.sender, _darknodeID, bond);
    }

    
    
    
    
    
    
    function deregister(address _darknodeID) external onlyDeregisterable(_darknodeID) onlyDarknodeOwner(_darknodeID) {
        deregisterDarknode(_darknodeID);
    }

    
    
    
    function epoch() external {
        if (previousEpoch.blocktime == 0) {
            
            require(msg.sender == owner(), "DarknodeRegistry: not authorized (first epochs)");
        }

        
        require(block.timestamp >= currentEpoch.blocktime.add(minimumEpochInterval), "DarknodeRegistry: epoch interval has not passed");
        uint256 epochhash = uint256(blockhash(block.number - 1));

        
        previousEpoch = currentEpoch;
        currentEpoch = Epoch({
            epochhash: epochhash,
            blocktime: block.timestamp
        });

        
        numDarknodesPreviousEpoch = numDarknodes;
        numDarknodes = numDarknodesNextEpoch;

        
        if (nextMinimumBond != minimumBond) {
            minimumBond = nextMinimumBond;
            emit LogMinimumBondUpdated(minimumBond, nextMinimumBond);
        }
        if (nextMinimumPodSize != minimumPodSize) {
            minimumPodSize = nextMinimumPodSize;
            emit LogMinimumPodSizeUpdated(minimumPodSize, nextMinimumPodSize);
        }
        if (nextMinimumEpochInterval != minimumEpochInterval) {
            minimumEpochInterval = nextMinimumEpochInterval;
            emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, nextMinimumEpochInterval);
        }
        if (nextSlasher != slasher) {
            slasher = nextSlasher;
            emit LogSlasherUpdated(address(slasher), address(nextSlasher));
        }
        if (address(darknodePayment) != address(0x0)) {
            darknodePayment.changeCycle();
        }

        
        emit LogNewEpoch(epochhash);
    }

    
    
    
    function transferStoreOwnership(DarknodeRegistry _newOwner) external onlyOwner {
        store.transferOwnership(address(_newOwner));
        _newOwner.claimStoreOwnership();
    }

    
    
    
    function claimStoreOwnership() external {
        store.claimOwnership();
    }

    
    
    
    
    function updateDarknodePayment(IDarknodePayment _darknodePayment) external onlyOwner {
        require(address(_darknodePayment) != address(0x0), "DarknodeRegistry: invalid Darknode Payment address");
        IDarknodePayment previousDarknodePayment = darknodePayment;
        darknodePayment = _darknodePayment;
        emit LogDarknodePaymentUpdated(previousDarknodePayment, darknodePayment);
    }

    
    
    
    function updateMinimumBond(uint256 _nextMinimumBond) external onlyOwner {
        
        nextMinimumBond = _nextMinimumBond;
    }

    
    
    function updateMinimumPodSize(uint256 _nextMinimumPodSize) external onlyOwner {
        
        nextMinimumPodSize = _nextMinimumPodSize;
    }

    
    
    function updateMinimumEpochInterval(uint256 _nextMinimumEpochInterval) external onlyOwner {
        
        nextMinimumEpochInterval = _nextMinimumEpochInterval;
    }

    
    
    
    function updateSlasher(IDarknodeSlasher _slasher) external onlyOwner {
        require(address(_slasher) != address(0), "DarknodeRegistry: invalid slasher address");
        nextSlasher = _slasher;
    }

    
    
    
    
    
    function slash(address _guilty, address _challenger, uint256 _percentage)
        external
        onlySlasher
    {
        require(_percentage <= 100, "DarknodeRegistry: invalid percent");

        
        if (isDeregisterable(_guilty)) {
            deregisterDarknode(_guilty);
        }

        uint256 totalBond = store.darknodeBond(_guilty);
        uint256 penalty = totalBond.div(100).mul(_percentage);
        uint256 reward = penalty.div(2);
        if (reward > 0) {
            
            store.updateDarknodeBond(_guilty, totalBond.sub(penalty));

            
            require(address(darknodePayment) != address(0x0), "DarknodeRegistry: invalid payment address");
            require(xbg.transfer(address(darknodePayment.store()), reward), "DarknodeRegistry: reward transfer failed");
            require(xbg.transfer(_challenger, reward), "DarknodeRegistry: reward transfer failed");
        }

        emit LogDarknodeSlashed(store.darknodeOwner(_guilty), _guilty, _challenger, _percentage);
    }

    
    
    
    
    
    
    function refund(address _darknodeID) external onlyRefundable(_darknodeID) {
        address darknodeOwner = store.darknodeOwner(_darknodeID);

        
        uint256 amount = store.darknodeBond(_darknodeID);

        
        store.removeDarknode(_darknodeID);

        
        require(xbg.transfer(darknodeOwner, amount), "DarknodeRegistry: bond transfer failed");

        
        emit LogDarknodeOwnerRefunded(darknodeOwner, amount);
    }

    
    
    function getDarknodeOwner(address _darknodeID) external view returns (address payable) {
        return store.darknodeOwner(_darknodeID);
    }

    
    
    function getDarknodeBond(address _darknodeID) external view returns (uint256) {
        return store.darknodeBond(_darknodeID);
    }

    
    
    function getDarknodePublicKey(address _darknodeID) external view returns (bytes memory) {
        return store.darknodePublicKey(_darknodeID);
    }

    
    
    
    
    
    
    
    
    
    
    function getDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }
        return getDarknodesFromEpochs(_start, count, false);
    }

    
    
    function getPreviousDarknodes(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodesPreviousEpoch;
        }
        return getDarknodesFromEpochs(_start, count, true);
    }

    
    
    
    function isPendingRegistration(address _darknodeID) external view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        return registeredAt != 0 && registeredAt > currentEpoch.blocktime;
    }

    
    
    function isPendingDeregistration(address _darknodeID) external view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt > currentEpoch.blocktime;
    }

    
    function isDeregistered(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return deregisteredAt != 0 && deregisteredAt <= currentEpoch.blocktime;
    }

    
    
    
    function isDeregisterable(address _darknodeID) public view returns (bool) {
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        
        
        return isRegistered(_darknodeID) && deregisteredAt == 0;
    }

    
    
    
    function isRefunded(address _darknodeID) public view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        return registeredAt == 0 && deregisteredAt == 0;
    }

    
    
    function isRefundable(address _darknodeID) public view returns (bool) {
        return isDeregistered(_darknodeID) && store.darknodeDeregisteredAt(_darknodeID) <= previousEpoch.blocktime;
    }

    
    function isRegistered(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, currentEpoch);
    }

    
    function isRegisteredInPreviousEpoch(address _darknodeID) public view returns (bool) {
        return isRegisteredInEpoch(_darknodeID, previousEpoch);
    }

    
    
    
    
    function isRegisteredInEpoch(address _darknodeID, Epoch memory _epoch) private view returns (bool) {
        uint256 registeredAt = store.darknodeRegisteredAt(_darknodeID);
        uint256 deregisteredAt = store.darknodeDeregisteredAt(_darknodeID);
        bool registered = registeredAt != 0 && registeredAt <= _epoch.blocktime;
        bool notDeregistered = deregisteredAt == 0 || deregisteredAt > _epoch.blocktime;
        
        
        return registered && notDeregistered;
    }

    
    
    
    
    
    function getDarknodesFromEpochs(address _start, uint256 _count, bool _usePreviousEpoch) private view returns (address[] memory) {
        uint256 count = _count;
        if (count == 0) {
            count = numDarknodes;
        }

        address[] memory nodes = new address[](count);

        
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = store.begin();
        }

        
        while (n < count) {
            if (next == address(0)) {
                break;
            }
            
            bool includeNext;
            if (_usePreviousEpoch) {
                includeNext = isRegisteredInPreviousEpoch(next);
            } else {
                includeNext = isRegistered(next);
            }
            if (!includeNext) {
                next = store.next(next);
                continue;
            }
            nodes[n] = next;
            next = store.next(next);
            n += 1;
        }
        return nodes;
    }

    
    function deregisterDarknode(address _darknodeID) private {
        
        store.updateDarknodeDeregisteredAt(_darknodeID, currentEpoch.blocktime.add(minimumEpochInterval));
        numDarknodesNextEpoch = numDarknodesNextEpoch.sub(1);

        
        emit LogDarknodeDeregistered(msg.sender, _darknodeID);
    }
}

contract DarknodePaymentStore is Claimable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using ERC20WithFees for ERC20;

    string public VERSION; 

    
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    
    mapping(address => mapping(address => uint256)) public darknodeBalances;

    
    mapping(address => uint256) public lockedBalances;

    
    
    
    constructor(
        string memory _VERSION
    ) public {
        VERSION = _VERSION;
    }

    
    function () external payable {
    }

    
    
    
    
    function totalBalance(address _token) public view returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        } else {
            return ERC20(_token).balanceOf(address(this));
        }
    }

    
    
    
    
    
    
    function availableBalance(address _token) public view returns (uint256) {
        return totalBalance(_token).sub(lockedBalances[_token]);
    }

    
    
    
    
    
    
    function incrementDarknodeBalance(address _darknode, address _token, uint256 _amount) external onlyOwner {
        require(_amount > 0, "DarknodePaymentStore: invalid amount");
        require(availableBalance(_token) >= _amount, "DarknodePaymentStore: insufficient contract balance");

        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token].add(_amount);
        lockedBalances[_token] = lockedBalances[_token].add(_amount);
    }

    
    
    
    
    
    
    function transfer(address _darknode, address _token, uint256 _amount, address payable _recipient) external onlyOwner {
        require(darknodeBalances[_darknode][_token] >= _amount, "DarknodePaymentStore: insufficient darknode balance");
        darknodeBalances[_darknode][_token] = darknodeBalances[_darknode][_token].sub(_amount);
        lockedBalances[_token] = lockedBalances[_token].sub(_amount);

        if (_token == ETHEREUM) {
            _recipient.transfer(_amount);
        } else {
            ERC20(_token).safeTransfer(_recipient, _amount);
        }
    }

}

contract DarknodePayment is Claimable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using ERC20WithFees for ERC20;

    string public VERSION; 

    
    address constant public ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    DarknodeRegistry public darknodeRegistry; 

    
    
    DarknodePaymentStore public store; 

    
    
    address public cycleChanger;

    uint256 public currentCycle;
    uint256 public previousCycle;

    
    
    
    address[] public pendingTokens;

    
    
    address[] public registeredTokens;

    
    
    mapping(address => uint256) public registeredTokenIndex;

    
    
    
    mapping(address => uint256) public unclaimedRewards;

    
    
    mapping(address => uint256) public previousCycleRewardShare;

    
    uint256 public cycleStartTime;

    
    uint256 public nextCyclePayoutPercent;

    
    uint256 public currentCyclePayoutPercent;

    
    
    
    mapping(address => mapping(uint256 => bool)) public rewardClaimed;

    
    
    
    event LogDarknodeClaim(address indexed _darknode, uint256 _cycle);

    
    
    
    
    event LogPaymentReceived(address indexed _payer, uint256 _amount, address indexed _token);

    
    
    
    
    event LogDarknodeWithdrew(address indexed _payee, uint256 _value, address indexed _token);

    
    
    
    event LogPayoutPercentChanged(uint256 _newPercent, uint256 _oldPercent);

    
    
    
    event LogCycleChangerChanged(address _newCycleChanger, address _oldCycleChanger);

    
    
    event LogTokenRegistered(address _token);

    
    
    event LogTokenDeregistered(address _token);

    
    
    
    event LogDarknodeRegistryUpdated(DarknodeRegistry _previousDarknodeRegistry, DarknodeRegistry _nextDarknodeRegistry);

    
    modifier onlyDarknode(address _darknode) {
        require(darknodeRegistry.isRegistered(_darknode), "DarknodePayment: darknode is not registered");
        _;
    }

    
    modifier validPercent(uint256 _percent) {
        require(_percent <= 100, "DarknodePayment: invalid percentage");
        _;
    }

    
    
    
    
    
    
    
    constructor(
        string memory _VERSION,
        DarknodeRegistry _darknodeRegistry,
        DarknodePaymentStore _darknodePaymentStore,
        uint256 _cyclePayoutPercent
    ) public validPercent(_cyclePayoutPercent) {
        VERSION = _VERSION;
        darknodeRegistry = _darknodeRegistry;
        store = _darknodePaymentStore;
        nextCyclePayoutPercent = _cyclePayoutPercent;
        
        cycleChanger = msg.sender;

        
        (currentCycle, cycleStartTime) = darknodeRegistry.currentEpoch();
        currentCyclePayoutPercent = nextCyclePayoutPercent;
    }

    
    
    
    
    function updateDarknodeRegistry(DarknodeRegistry _darknodeRegistry) external onlyOwner {
        require(address(_darknodeRegistry) != address(0x0), "DarknodePayment: invalid Darknode Registry address");
        DarknodeRegistry previousDarknodeRegistry = darknodeRegistry;
        darknodeRegistry = _darknodeRegistry;
        emit LogDarknodeRegistryUpdated(previousDarknodeRegistry, darknodeRegistry);
    }

    
    
    
    
    
    function withdraw(address _darknode, address _token) public {
        address payable darknodeOwner = darknodeRegistry.getDarknodeOwner(_darknode);
        require(darknodeOwner != address(0x0), "DarknodePayment: invalid darknode owner");

        uint256 amount = store.darknodeBalances(_darknode, _token);
        require(amount > 0, "DarknodePayment: nothing to withdraw");

        store.transfer(_darknode, _token, amount, darknodeOwner);
        emit LogDarknodeWithdrew(_darknode, amount, _token);
    }

    function withdrawMultiple(address _darknode, address[] calldata _tokens) external {
        for (uint i = 0; i < _tokens.length; i++) {
            withdraw(_darknode, _tokens[i]);
        }
    }

    
    function () external payable {
        address(store).transfer(msg.value);
        emit LogPaymentReceived(msg.sender, msg.value, ETHEREUM);
    }

    
    
    function currentCycleRewardPool(address _token) external view returns (uint256) {
        uint256 total = store.availableBalance(_token).sub(unclaimedRewards[_token]);
        return total.div(100).mul(currentCyclePayoutPercent);
    }

    function darknodeBalances(address _darknodeID, address _token) external view returns (uint256) {
        return store.darknodeBalances(_darknodeID, _token);
    }

    
    function changeCycle() external returns (uint256) {
        require(msg.sender == cycleChanger, "DarknodePayment: not cycle changer");

        
        uint arrayLength = registeredTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            _snapshotBalance(registeredTokens[i]);
        }

        
        previousCycle = currentCycle;
        (currentCycle, cycleStartTime) = darknodeRegistry.currentEpoch();
        currentCyclePayoutPercent = nextCyclePayoutPercent;

        
        _updateTokenList();
        return currentCycle;
    }

    
    
    
    
    function deposit(uint256 _value, address _token) external payable {
        uint256 receivedValue;
        if (_token == ETHEREUM) {
            require(_value == msg.value, "DarknodePayment: mismatched deposit value");
            receivedValue = msg.value;
            address(store).transfer(msg.value);
        } else {
            require(msg.value == 0, "DarknodePayment: unexpected ether transfer");
            
            receivedValue = ERC20(_token).safeTransferFromWithFees(msg.sender, address(store), _value);
        }
        emit LogPaymentReceived(msg.sender, receivedValue, _token);
    }

    
    
    
    
    function forward(address _token) external {
        if (_token == ETHEREUM) {
            
            
            
            
            address(store).transfer(address(this).balance);
        } else {
            ERC20(_token).safeTransfer(address(store), ERC20(_token).balanceOf(address(this)));
        }
    }

    
    
    function claim(address _darknode) external onlyDarknode(_darknode) {
        require(darknodeRegistry.isRegisteredInPreviousEpoch(_darknode), "DarknodePayment: cannot claim for this epoch");
        
        _claimDarknodeReward(_darknode);
        emit LogDarknodeClaim(_darknode, previousCycle);
    }

    
    
    
    
    function registerToken(address _token) external onlyOwner {
        require(registeredTokenIndex[_token] == 0, "DarknodePayment: token already registered");
        require(!tokenPendingRegistration(_token), "DarknodePayment: token already pending registration");
        pendingTokens.push(_token);
    }

    function tokenPendingRegistration(address _token) public view returns (bool) {
        uint arrayLength = pendingTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            if (pendingTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    
    
    
    
    function deregisterToken(address _token) external onlyOwner {
        require(registeredTokenIndex[_token] > 0, "DarknodePayment: token not registered");
        _deregisterToken(_token);
    }

    
    
    
    function updateCycleChanger(address _addr) external onlyOwner {
        require(_addr != address(0), "DarknodePayment: invalid contract address");
        emit LogCycleChangerChanged(_addr, cycleChanger);
        cycleChanger = _addr;
    }

    
    
    
    function updatePayoutPercentage(uint256 _percent) external onlyOwner validPercent(_percent) {
        uint256 oldPayoutPercent = nextCyclePayoutPercent;
        nextCyclePayoutPercent = _percent;
        emit LogPayoutPercentChanged(nextCyclePayoutPercent, oldPayoutPercent);
    }

    
    
    
    
    function transferStoreOwnership(DarknodePayment _newOwner) external onlyOwner {
        store.transferOwnership(address(_newOwner));
        _newOwner.claimStoreOwnership();
    }

    
    
    
    function claimStoreOwnership() external {
        store.claimOwnership();
    }

    
    
    
    
    
    function _claimDarknodeReward(address _darknode) private {
        require(!rewardClaimed[_darknode][previousCycle], "DarknodePayment: reward already claimed");
        rewardClaimed[_darknode][previousCycle] = true;
        uint arrayLength = registeredTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            address token = registeredTokens[i];

            
            if (previousCycleRewardShare[token] > 0) {
                unclaimedRewards[token] = unclaimedRewards[token].sub(previousCycleRewardShare[token]);
                store.incrementDarknodeBalance(_darknode, token, previousCycleRewardShare[token]);
            }
        }
    }

    
    
    
    
    function _snapshotBalance(address _token) private {
        uint256 shareCount = darknodeRegistry.numDarknodesPreviousEpoch();
        if (shareCount == 0) {
            unclaimedRewards[_token] = 0;
            previousCycleRewardShare[_token] = 0;
        } else {
            
            uint256 total = store.availableBalance(_token);
            unclaimedRewards[_token] = total.div(100).mul(currentCyclePayoutPercent);
            previousCycleRewardShare[_token] = unclaimedRewards[_token].div(shareCount);
        }
    }

    
    
    
    
    function _deregisterToken(address _token) private {
        address lastToken = registeredTokens[registeredTokens.length.sub(1)];
        uint256 deletedTokenIndex = registeredTokenIndex[_token].sub(1);
        
        registeredTokens[deletedTokenIndex] = lastToken;
        registeredTokenIndex[lastToken] = registeredTokenIndex[_token];
        
        
        registeredTokens.length = registeredTokens.length.sub(1);
        registeredTokenIndex[_token] = 0;

        emit LogTokenDeregistered(_token);
    }

    
    
    function _updateTokenList() private {
        
        uint arrayLength = pendingTokens.length;
        for (uint i = 0; i < arrayLength; i++) {
            address token = pendingTokens[i];
            registeredTokens.push(token);
            registeredTokenIndex[token] = registeredTokens.length;
            emit LogTokenRegistered(token);
        }
        pendingTokens.length = 0;
    }

}