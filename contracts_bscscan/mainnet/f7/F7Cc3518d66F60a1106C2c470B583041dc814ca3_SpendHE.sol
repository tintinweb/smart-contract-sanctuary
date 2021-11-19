/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.0;
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
interface IBEP20 { 
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
	function mint(address account, uint256 amount) external returns (bool);
	function burn(address account, uint256 amount) external returns (bool);
	function addOperator(address minter) external returns (bool);
	function removeOperator(address minter) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval( address indexed owner, address indexed spender, uint256 value );
}
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        // uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeBEP20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: ERC20 operation did not succeed");
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
} 
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom( address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data ) external;

    struct HeroesInfo {uint256 heroesNumber; string name; string race; string class; string tier; string tierBasic; string uri;}
    function getHeroesNumber(uint256 _tokenId) external view returns (HeroesInfo memory);
    function safeMint(address _to, uint256 _tokenId) external;
    function burn(address _from, uint256 _tokenId) external;
    function addHeroesNumber(uint256 _tokenId, uint256 _heroesNumber, string memory name, string memory race, string memory class, string memory tier, string memory tierBasic) external;
    function editTier(uint256 tokenId, string memory _tier) external;
    function deleteHeroesNumber(uint256 tokenId) external;
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) { return interfaceId == type(IERC165).interfaceId; }
}
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }
    mapping(bytes32 => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool){
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view override returns (bool) { return _roles[role].members[account]; }
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) { return _roles[role].adminRole; }
    function grantRole(bytes32 role, address account) public virtual override { 
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public virtual override {
        require( hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");
        _revokeRole(role, account);
    }
    function renounceRole(bytes32 role, address account) public virtual override
    {
        require( account == _msgSender(), "AccessControl: can only renounce roles for self" );
        _revokeRole(role, account);
    }
    function _setupRole(bytes32 role, address account) internal virtual { _grantRole(role, account); }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
contract SpendHE is AccessControl {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IBEP20 public heroesToken;
    bytes32 public constant CREATOR_ADMIN_SERVER = keccak256("CREATOR_ADMIN_SERVER");
    address public receiveFee = 0x06eD3d7ef90551333b7185412337c9DF6F17C795;
    uint256 public feeClan = 2500000000000000000000; 
    uint256 public feeEditClan = 25000000000000000000; 
    uint256 public feeEditName = 12000000000000000000; 
    uint256 public feeRefreshChallengeStore = 25000000000000000000;
    uint256 public feeRefreshClanStore = 25000000000000000000;
    uint256 public unitTimeDeposit = 86400; 
    uint256 public limitDepositPerDay = 5000*1e18;
    uint256 public startTimeDeposit;
    constructor( address minter, address _heroesToken, uint256 _startTime ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN_SERVER, minter);
        heroesToken = IBEP20(_heroesToken); // Token Heroes
        startTimeDeposit = _startTime;
	}
    event clanmap(
        address Owner,
        uint256 fee,
        uint256 timeClan
    );
     event editname(
        address Owner,
        uint256 fee,
        uint256 timeName
    );
    event unionblessing(
        address Owner,
        uint256 slot,
        uint256 fee,
        uint256 timeUnion
    );
    event BuySlot(
        address Owner,
        uint256 slot,
        uint256 fee,
        uint256 timeBuyslot
    );
    event FeeRefreshChallengeStore(
        address Owner,
        uint256 fee,
        uint256 timeFeeRefreshChallengeStore
    );
    event FeeRefreshClanStore(
        address Owner,
        uint256 fee,
        uint256 timeFeeRefreshClanStore
    );
    event PurchaseItemDungeon(
        address Owner,
        uint256 fee,
        string item,
        uint256 timePurchaseItemDungeon
    );
    event Deposit(
        address Owner,
        uint256 fee,
        uint256 timeDeposit
    );
    mapping(uint256 => uint256) public feeUnionBlessing;
    mapping(uint256 => uint256) public feeBuySlot;
    mapping(uint256 => mapping(address => uint256)) public amountDeposit;
    function changeLimitDepositPerDay(uint256 _amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_amount > 0,"amount > 0");
        limitDepositPerDay = _amount;
    }
    function changeStartTimeDeposit(uint256 _time) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_time > 0,"time > 0");
        startTimeDeposit = _time;
    }
    function getDepositPerDay(address _address) public view returns(uint256){
        uint256 unitTime = (block.timestamp - startTimeDeposit).div(unitTimeDeposit);
        return amountDeposit[unitTime][_address];
    }
    function deposit(uint256 _amount) public {
        require(_amount > 0,"amount > 0");
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), _amount);
        uint256 unitTime = (block.timestamp - startTimeDeposit).div(unitTimeDeposit);
        require(amountDeposit[unitTime][msg.sender].add(_amount) <= limitDepositPerDay, "The limit has been exceeded");
        amountDeposit[unitTime][msg.sender] = amountDeposit[unitTime][msg.sender].add(_amount);
        emit Deposit(
            address(msg.sender),
            _amount,
            block.timestamp
        );
    }
    function changeReceiveFee(address _receive) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receive != address(0));
        receiveFee = _receive;
    }
    function changeFeeRefreshChallengeStore(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee >= 0, 'need fee >= 0');
        feeRefreshChallengeStore = _fee;
    }
     function changeFeeRefreshClanStore(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee >= 0, 'need fee >= 0');
        feeRefreshClanStore = _fee;
    }
    function changeFeeClan(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee >= 0, 'need fee >= 0');
        feeClan = _fee;
    }
    function changeFeeEditName(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee >= 0, 'need fee >= 0');
        feeEditName = _fee;
    }
    function changeFeeEditClan(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee >= 0, 'need fee >= 0');
        feeEditClan = _fee;
    } 
    function addFeeUnionBlessing(uint256[] memory slot, uint256[] memory amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(slot.length == amount.length, 'Input not true');
        for(uint256 i = 0; i < slot.length; i++){
            feeUnionBlessing[slot[i]] = amount[i]*1e18;
        }
    }
    function addFeeSlot(uint256[] memory slot, uint256[] memory amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(slot.length == amount.length, 'Input not true');
        for(uint256 i = 0; i < slot.length; i++){
            feeBuySlot[slot[i]] = amount[i]*1e18;
        }
    }
    function refreshChallengeStore() public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeRefreshChallengeStore);
        emit FeeRefreshChallengeStore(
            address(msg.sender),
            feeRefreshChallengeStore,
            block.timestamp
        );
    }
    function refreshClanStore() public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeRefreshClanStore);
        emit FeeRefreshClanStore(
            address(msg.sender),
            feeRefreshClanStore,
            block.timestamp
        );
    }
    function purchaseItemDungeon(uint256 _amount, string memory _item) public {
        require(_amount > 0, "need amount > 0");
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), _amount);
        emit PurchaseItemDungeon(
            msg.sender,
            _amount,
            _item,
            block.timestamp
        );
    }
    function clan() public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeClan);
        emit clanmap(
            address(msg.sender),
            feeClan,
            block.timestamp
        );
    }
    function editName() public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeEditName);
        emit editname(
            address(msg.sender),
            feeClan,
            block.timestamp
        );
    }
    function editClan() public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeEditClan);
        emit clanmap(
            address(msg.sender),
            feeClan,
            block.timestamp
        );
    }
    function unionBlessing(uint256 slot) public {
        uint256 feeUnion = feeUnionBlessing[slot];
        require(feeUnion > 0, "Amoun <= 0");
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeUnion);
        emit unionblessing(
            address(msg.sender),
            slot,
            feeUnion,
            block.timestamp
        );
    }

    function buySlot(uint256 slot) public {
        uint256 feeSlot = feeBuySlot[slot];
         require(feeSlot > 0, "Amoun <= 0");
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeSlot);
        emit BuySlot(
            address(msg.sender),
            slot,
            feeSlot,
            block.timestamp
        );
    }
   
}