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

    struct HeroesInfo {uint256 heroesNumber; string name; string race; string class; string tier; string tierBasic;}
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
contract WishItem is AccessControl {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20; 
    IERC721 public heroesNFT;
    IBEP20 public heroesToken;
    bytes32 public constant CREATOR_SERVER = keccak256("CREATOR_SERVER");
    address payable revenueAddress = payable(0x06eD3d7ef90551333b7185412337c9DF6F17C795);
    constructor( address minter, address _heroesNft, address _heroesToken ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_SERVER, minter);
		heroesNFT = IERC721(_heroesNft); // Token Hero Assets
        heroesToken = IBEP20(_heroesToken); // Token Heroes
	}
    event ListItem(
        address owner,
        address nftContract,
        address paymentToken,
        uint256 id,
        uint256 numberHero,
        uint256 numberTier,
        uint256 amount,
        uint256 timeListItem
    );
    event Cancel(
        uint256 id,
        uint256 timeCancel
    );
    event ChangeAmount(
        uint256 id,
        uint256 amount,
        uint256 timeChangeAmount
    );
    event MatchTransaction(
        address buyer,
        address owner,
        uint256 tokenId,
        uint256 id,
        uint256 timeMatch
    );
    struct ItemInfo {
        address owner;
        uint256 numberHero;
        uint256 numberTier;
        uint256 amount;
        uint256 status; // 1 : list , 2 : cancel, 3 : match
    }
    mapping(uint256 => ItemInfo) public itemInfo;
    mapping(uint256 => uint256) public tierNumber;
    mapping(uint256 => bool) public idItem;
    uint256 public MaxTier; // 1 .. 15 => Common , Rare , Rare*, Epic, Epic*, Legendery, Legendery*, Immortal, Immortal*, Ultimate, Ultimate 1, Ultimate 2, Ultimate 3, Ultimate 4, Ultimate 5
    uint256 public MinAmount = 0;
    uint256 public fee = 0;
    string[] public heroTier;
    function addHeroTier(string[] memory _heroTier) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _heroTier.length ; i++) {
            heroTier.push(_heroTier[i]);
        }
    }
    function changeFee(uint256 _fee) public { // 1000 %
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, "fee > 0");
        fee = _fee;
    }
    function changeRevenueAddress(address _receive) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receive != address(0));
        revenueAddress = payable(_receive);
    }
    function addMaxTier(uint256 _maxTier) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_maxTier > 0, "maxTier > 0");
        MaxTier = _maxTier;
    }
    function addMinAmount(uint256 _minAmount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_minAmount > 0, "minAmount > 0");
        MinAmount = _minAmount;
    }
    function addHero(uint256[] memory heroId, uint256[] memory tier)public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(heroId.length == tier.length, 'Input not true');
        for(uint256 i = 0; i < heroId.length ; i ++) {
           tierNumber[heroId[i]] = tier[i];
        }
    }
    
    function listItem(uint256 id, uint256 _numberHero, uint256 _numberTier, uint256 _amount) public{
        require(!idItem[id], "idItem used");
        require(_amount >= MinAmount, "Price must be greater than minimum");
        require(tierNumber[_numberHero] != 0 && _numberTier <= MaxTier && tierNumber[_numberHero] <= _numberTier, "Tier is incorrect");
        itemInfo[id] = ItemInfo(msg.sender, _numberHero, _numberTier, _amount, 1);
        heroesToken.safeTransferFrom(msg.sender, address(this), _amount);
        idItem[id] = true;   
        emit ListItem(
            msg.sender,
            address(heroesNFT),
            address(heroesToken),
            id,
            _numberHero,
            _numberTier,
            _amount,
            block.timestamp
        );
    }
    function cancelList(uint256 id) public {
        require(itemInfo[id].owner == msg.sender, "You are not a listItem");
        require(itemInfo[id].status == 1, "Item not found");
        itemInfo[id].status = 2;
        emit Cancel(
            id,
            block.timestamp
        );
    }
    function changeAmount(uint256 id, uint256 amount) public {
        require(itemInfo[id].owner == msg.sender, "You are not a listItem");
        require(itemInfo[id].status == 1, "Item not found");
        require(amount > 0, "amount > 0");
        if(itemInfo[id].amount > amount){
            heroesToken.transfer(address(msg.sender), itemInfo[id].amount.sub(amount));
        }
        if(itemInfo[id].amount < amount){
            heroesToken.safeTransferFrom(msg.sender, address(this), amount.sub(itemInfo[id].amount));
        }
        itemInfo[id].amount = amount;
        emit ChangeAmount(
            id,
            amount,
            block.timestamp
        );
    }
    function matchTransaction(uint256 id, uint256 tokenId) public {
        require(itemInfo[id].status == 1, "Item not found");
        require(heroesNFT.ownerOf(tokenId) == msg.sender, "you is not owner of tokenid now");
        require(itemInfo[id].numberHero == heroesNFT.getHeroesNumber(tokenId).heroesNumber, "Hero does not match");
        uint256 tier = queryNumberTier(heroesNFT.getHeroesNumber(tokenId).tier);
        require(itemInfo[id].numberTier == tier, "Tier does not match");
        heroesNFT.safeTransferFrom(msg.sender, itemInfo[id].owner, tokenId);
        uint256 feeMarket = itemInfo[id].amount.mul(fee).div(1000);
        uint256 amountOfRecipient = itemInfo[id].amount.sub(feeMarket);
        heroesToken.transfer(itemInfo[id].owner, amountOfRecipient);
        heroesToken.transfer(revenueAddress, feeMarket);
        itemInfo[id].status = 3;
        emit MatchTransaction(
            msg.sender,
            itemInfo[id].owner,
            tokenId,
            id, 
            block.timestamp
        );
    }
    function queryNumberTier(string memory _tier) public view returns(uint256) {
        uint256 result = 100;
        for(uint256 i = 0 ; i < heroTier.length ; i ++) {
            if( keccak256(bytes(heroTier[i])) == keccak256(bytes(_tier)) ) {
                result = i + 1;
            }
        }
        return result;
    }
}