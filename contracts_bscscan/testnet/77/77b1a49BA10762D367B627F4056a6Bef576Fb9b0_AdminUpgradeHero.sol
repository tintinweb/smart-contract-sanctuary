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
contract AdminUpgradeHero is AccessControl {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;
    IERC721 public heroesNFT;
    IBEP20 public heroesToken;
    bytes32 public constant CREATOR_ADMIN_SERVER = keccak256("CREATOR_ADMIN_SERVER");
    string stringNull = "";
    address public receiveFee = 0x06eD3d7ef90551333b7185412337c9DF6F17C795;
    constructor( address minter, address _heroesNft, address _heroesToken ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN_SERVER, minter);
		heroesNFT = IERC721(_heroesNft); // Token Hero Assets
        heroesToken = IBEP20(_heroesToken); // Token Heroes
	}
    event limitBreak(
        address Owner,
        uint256 tokenId,
        uint256 level
    );
    event issue(
        address Owner,
        uint256 tokenId,
        string nameHeroes,
        string race,
        string tier
    );
    event ascend(
        address Owner,
        uint256 tokenId,
        string tier
    );
    struct RuleInfo {
        uint256 numberHero;
        uint256 requirementHeroOrRace; // 0 : Hero, 1: Race
        uint256 heroesTierFood;
    }
    struct RuleInfoSpecial {
        uint256 numberHero;
        uint256 heroesTierFood;
    }
    struct RequestHero {
        address Owner;
        uint256 numberHeroes;
        string tier;
    }
    struct TierName {
        string tierName;
    }
    mapping( uint256 => RequestHero ) public requestHero;
    TierName[] public tierName; // tier information 
    mapping(uint256 => RuleInfo) public ruleInfo; // tier => rule of tier
    mapping(uint256 => RuleInfoSpecial) public ruleInfoSpecial; // tier => rule of tier
    mapping( uint256 => uint256 ) public amountLimitBreak;
    function changeReceiveFee(address _receive) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receive != address(0));
        receiveFee = _receive;
    }
    modifier conditionOfCommon(uint256 tokenId) {
        uint256 tierMain = queryNumberTier(heroesNFT.getHeroesNumber(tokenId).tier);
        uint256 tierBasicMain = queryNumberTier(heroesNFT.getHeroesNumber(tokenId).tierBasic);
        if(tierBasicMain == 0){
            require(tierMain < 4, "Tier common max level");
        }
        _;
    }
    function addRuleLimitBreak(uint256[] memory level, uint256[] memory amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i = 0; i < level.length; i++){
            require(amount[i] > 0, 'Amount > 0');
            amountLimitBreak[level[i]] = amount[i]*1e18;
        }
    } 
    function editRuleLimitBreak(uint256 level, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(amount > 0, 'Amount > 0');
        amountLimitBreak[level] = amount;
    }
    function getTierName() public view returns (TierName[]  memory) {
        return tierName;
    }
    function addTierName(string[] memory _tierName) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < _tierName.length ; i++) {
            tierName.push(TierName(_tierName[i]));
        }
    }
    function editTierName(uint256 _id, string memory _tierName) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        tierName[_id].tierName = _tierName;
    }
    function addRule( uint256[] memory numberHero, uint256[] memory requirementHeroOrRace, uint256[] memory heroesTierFood) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i = 0 ; i < numberHero.length; i++){
            ruleInfo[i] = RuleInfo(numberHero[i], requirementHeroOrRace[i], heroesTierFood[i]);
        }
    }
    function editRule(uint256 _tier, uint256 numberHero, uint256 requirementHeroOrRace, uint256 heroesTierFood) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        // ruleInfo[_tier].heroesTierMain = heroesTierMain;
        ruleInfo[_tier].numberHero = numberHero;
        ruleInfo[_tier].requirementHeroOrRace = requirementHeroOrRace;
        ruleInfo[_tier].heroesTierFood = heroesTierFood;
    }
    function addRuleSpecial( uint256[] memory numberHero, uint256[] memory heroesTierFood) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i = 0 ; i < numberHero.length; i++){
            ruleInfoSpecial[i] = RuleInfoSpecial(numberHero[i], heroesTierFood[i]);
        }
    }
    function editRuleSpecial(uint256 _tier, uint256 numberHero, uint256 heroesTierFood) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        ruleInfoSpecial[_tier].numberHero = numberHero;
        ruleInfoSpecial[_tier].heroesTierFood = heroesTierFood;
    }

    function queryNumberTier(string memory _tier) public view returns(uint256) {
        uint256 result = 100;
        for(uint256 i = 0 ; i < tierName.length ; i ++) {
            if( keccak256(bytes(tierName[i].tierName)) == keccak256(bytes(_tier)) ) {
                result = i;
            }
        }
        return result;
    }
    
    function upgradeHero(uint256[] memory listHeroId) public conditionOfCommon(listHeroId[0]){
        uint256 heroesTierMain = listHeroId[0];       
        require(keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).tier )) != keccak256(bytes( tierName[tierName.length - 1].tierName )), "You are already at the highest level");
        require(queryNumberTier(heroesNFT.getHeroesNumber(heroesTierMain).tier) != 100, "Tier not found");
        if( ( keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).race )) == keccak256(bytes('Naga')) ) || ( keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).race )) == keccak256(bytes('Demon')) ) || ( keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).race )) == keccak256(bytes('God')) ) ){
            //Upgrade Special
            upgradeSpecial(listHeroId);
        }else{
            //Upgrade
            upgrade(listHeroId);
        }
    } 
    function upgrade(uint256[] memory listHeroId) public  {
        uint256 heroesTierMain = listHeroId[0]; 
        uint256 tierMain = queryNumberTier(heroesNFT.getHeroesNumber(heroesTierMain).tier);    
        uint256 numberRequestHero = ruleInfo[tierMain].numberHero;
        uint256 requestHeroOrRace = ruleInfo[tierMain].requirementHeroOrRace;
        uint256 heroesTierFood = ruleInfo[tierMain].heroesTierFood;
        require(listHeroId.length == (numberRequestHero + 1), "The number of heroes is incorrect");
        if(requestHeroOrRace == 0){
            //same hero
            for(uint256 i = 1; i < listHeroId.length ; i++){
                // require(keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).name )) == keccak256(bytes( heroesNFT.getHeroesNumber(listHeroId[i]).name )), "Not the same heroes");
                require( heroesNFT.getHeroesNumber(heroesTierMain).heroesNumber == heroesNFT.getHeroesNumber(listHeroId[i]).heroesNumber, "Not the same heroes");
                require(queryNumberTier(heroesNFT.getHeroesNumber(listHeroId[i]).tier) == heroesTierFood, "Tier food not is incorrect");
                heroesNFT.burn(msg.sender, listHeroId[i]);
                heroesNFT.deleteHeroesNumber(listHeroId[i]);
                delete requestHero[listHeroId[i]];
            } 
        } 
        if(requestHeroOrRace == 1){
            //same race
            for(uint256 i = 1; i < listHeroId.length ; i++){
                require(keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).race )) == keccak256(bytes( heroesNFT.getHeroesNumber(listHeroId[i]).race )), "Not the same race");
                require(queryNumberTier(heroesNFT.getHeroesNumber(listHeroId[i]).tier) == heroesTierFood, "Tier food not is incorrect");
                heroesNFT.burn(msg.sender, listHeroId[i]);
                heroesNFT.deleteHeroesNumber(listHeroId[i]);
            }          
        }
        // Update Heroes
        require(heroesNFT.ownerOf(heroesTierMain) ==  msg.sender, "You are not the owner");
        heroesNFT.editTier(heroesTierMain, tierName[tierMain + 1].tierName);
        emit ascend(
            msg.sender,
            heroesTierMain,
            tierName[tierMain + 1].tierName
        );
    }
    function upgradeSpecial(uint256[] memory listHeroId) internal {
        uint256 heroesTierMain = listHeroId[0]; 
        uint256 tierMain = queryNumberTier(heroesNFT.getHeroesNumber(heroesTierMain).tier);  
        uint256 numberRequestHero = ruleInfoSpecial[tierMain].numberHero;
        uint256 heroesTierFood = ruleInfoSpecial[tierMain].heroesTierFood;
        require(listHeroId.length == (numberRequestHero + 1), "The number of heroes is incorrect");
        for(uint256 i = 1; i < listHeroId.length; i++){
            // require(keccak256(bytes( heroesNFT.getHeroesNumber(heroesTierMain).name )) == keccak256(bytes( heroesNFT.getHeroesNumber(listHeroId[i]).name )), "Not the same heroes");
            require( heroesNFT.getHeroesNumber(heroesTierMain).heroesNumber == heroesNFT.getHeroesNumber(listHeroId[i]).heroesNumber, "Not the same heroes");
            require(queryNumberTier(heroesNFT.getHeroesNumber(listHeroId[i]).tier) == heroesTierFood, "Tier food not is incorrect");
            heroesNFT.burn(msg.sender, listHeroId[i]);
            heroesNFT.deleteHeroesNumber(listHeroId[i]);
        }
        // Update Heroes
        require(heroesNFT.ownerOf(heroesTierMain) ==  msg.sender, "You are not the owner");
        heroesNFT.editTier(heroesTierMain, tierName[tierMain + 1].tierName);
        emit ascend(
            msg.sender,
            heroesTierMain,
            tierName[tierMain + 1].tierName
        );
    }

    function upgradeLimitBreak( uint256 tokenId, uint256 level) public {
        uint256 amountLimit = amountLimitBreak[level];
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), amountLimit);
        emit limitBreak(
            msg.sender,
            tokenId,
            level
        );
    }
}