// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

    struct DuckInfo {uint256 heroesNumber; string name; string category; uint256 exp; uint256 level; uint createTimestamp; bool stakeFreeze;}
    function getHeroesNumber(uint256 _tokenId) external view returns (DuckInfo memory);
    function safeMint(address _to, uint256 _tokenId) external;
    function burn(address _from, uint256 _tokenId) external;
    function addDuckNumber(uint256 tokenId, uint256 _heroesNumber, string memory name, string memory category, uint256 exp, uint256 level, uint createTimestamp, bool stakeFreeze) external;
    function editTier(uint256 tokenId, string memory _tier) external;
    function editLevel(uint256 tokenId, uint256 _level) external;
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
contract Issue is AccessControl, ReentrancyGuard {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20; 
    IERC721 public heroesNFT;
    IBEP20 public heroesToken;
    bytes32 public constant CREATOR_ADMIN_SERVER = keccak256("CREATOR_ADMIN_SERVER");
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER");
    string stringNull = "";
    uint256 public feeSummon =  50000000000000000000;
    uint256 public feeSummons = 500000000000000000000;
    uint256 public feeShard = 0;
    uint256 public feeCard = 0;
    uint256 private _lastTokenId;
    uint256 private _initialExpBoost;
    address payable receiveFee = payable(0x000000000000000000000000000000000000dEaD);
    constructor( address minter, address _heroesNft, address _heroesToken ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN_SERVER, minter);
        _setupRole(TOKEN_MINTER_ROLE, minter);
        _initialExpBoost = 0;
		heroesNFT = IERC721(_heroesNft); // Token Hero Assets
        heroesToken = IBEP20(_heroesToken); // Token Heroes
	}

    event summonhero(
        address Owner,
        uint256 tokenId,
        string nameHeroes,
        string category,
        uint256 exp,
        uint256 level
    );
    event openpackage(
        address Owner,
        uint256 tokenId,
        string nameHeroes,
        string category,
        uint256 level
    );

    struct Heroes {
        string name;
        string category;
        uint256 exp;
        uint256 level; 
    }
    event RequestHero(
        uint256 tokenId,
        address Owner,
        string category
    );
    mapping(uint256 => Heroes) public heroes; //  tokenId=> Heroes Information 
    mapping( uint256 => uint256 ) public amountLimitBreak;
    mapping(uint256 => bool) public heroOpenPack;
    mapping(uint256 => bool) public chestId;
    mapping(uint256 => bool) public summonId;
    function changeReceiveFee(address _receive) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receive != address(0));
        receiveFee = payable(_receive);
    }
    function addHeroOpenPack(uint256[] memory hero) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        for(uint256 i =0; i < hero.length; i++){
            heroOpenPack[hero[i]] = true;
        }
    }
    function getHeroes(uint256 _id) public view returns (Heroes  memory) {
        return heroes[_id];
    }
    function addHeroes(uint256[] memory id, string[] memory name, string[] memory category, uint256[] memory exp, uint256[] memory level) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(id.length == name.length && id.length == category.length && id.length == exp.length && id.length == level.length, 'Input not true');
        for(uint256 i = 0; i < name.length ; i ++) {
            heroes[id[i]] = Heroes(name[i], category[i], exp[i], level[i]);
        }
    }
    function editHeroes(uint256 _id, string memory name, string memory category, uint256 exp, uint256 level) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        heroes[_id].name = name;
        heroes[_id].category = category;
        heroes[_id].exp = exp;
        heroes[_id].level = level;
    }  
    function changeFeeShard(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, 'need fee > 0');
        feeShard = _fee;
    }
    function changeFeeCard(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, 'need fee > 0');
        feeCard = _fee;
    }
    function changeFee(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, 'need fee > 0');
        feeSummon = _fee;
    }
    function changeFees(uint256 _fee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_fee > 0, 'need fee > 0');
        feeSummons = _fee;
    }
    function requestShard(uint256 _tokenId) public{
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeShard);
        emit RequestHero(
            _tokenId,
            msg.sender,
            'Shard'
        );
    } 
    function requestCard(uint256 _tokenId) public{
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeCard);
        emit RequestHero(
            _tokenId,
            msg.sender,
            'Card'
        );
    }
    function requestSummon(uint256 _tokenId) public{
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeSummon);
        emit RequestHero(
            _tokenId,
            msg.sender,
            'Summon'
        );
    }
    function requestSummons(uint256[] memory _tokenId) public {
        heroesToken.safeTransferFrom(address(msg.sender), address(receiveFee), feeSummons);
        for(uint256 i = 0; i < _tokenId.length; i++){
            emit RequestHero(
            _tokenId[i],
            msg.sender,
            'Summon'
        );
        }
    }

    function summonegg(address to, uint256 _numberHero) public nonReentrant {
        require(hasRole(TOKEN_MINTER_ROLE, address(msg.sender)), "Caller is not a egg minter");
        require(to != address(0), "Address can not be zero");
        require(_numberHero == 1, "Only can Mint Egg");
        require(keccak256(bytes(heroes[_numberHero].name)) != keccak256(bytes(stringNull)), "Heroes not found");
        _lastTokenId += 1;
        uint tokenId = _lastTokenId;
        heroesNFT.addDuckNumber(tokenId, _numberHero, heroes[_numberHero].name, heroes[_numberHero].category, heroes[_numberHero].exp, heroes[_numberHero].level, block.timestamp, false );
        heroesNFT.safeMint(to, tokenId);
    }




}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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