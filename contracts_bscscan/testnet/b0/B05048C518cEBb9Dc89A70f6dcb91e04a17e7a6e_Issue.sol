// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IAccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
    function getDuck(uint256 _tokenId) external view returns (uint256 level, uint256 exp,  bool stakeFreeze, uint remainToNextLevel, uint createTimestamp, address tokenOwner, string memory uri);    
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


    //DUCKRANDOM
    uint public duckChancesBase;
    uint8 private _levelUpPercent; //in percents
    uint[7] private _expTable;
    uint[7] private _levelTable;
    uint public constant MAX_ARRAY_LENGTH_PER_REQUEST = 30;
    
    uint public MAXEGGSUMMON =  5;
    uint256 public feeSummon =  50000000000000000000;
    uint256 public feeSummons = 500000000000000000000;
    uint256 private _lastTokenId;
    uint256 private _initialExpBoost;
    address payable BurnFee = payable(0x000000000000000000000000000000000000dEaD);
    address payable TreasuryFee = payable(0x000000000000000000000000000000000000dEaD);
    address payable MarketingFee = payable(0x000000000000000000000000000000000000dEaD);
    address payable JackpotFee = payable(0x000000000000000000000000000000000000dEaD);

    uint256 amountBurnFee = 30;
    uint256 amountTreasuryFee = 30;
    uint256 amountMarketingFee = 20;
    uint256 amountJackpotFee = 20;




    constructor( address minter, address _heroesNft, address _heroesToken ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATOR_ADMIN_SERVER, minter);
        _setupRole(TOKEN_MINTER_ROLE, minter);
        _initialExpBoost = 0;
		heroesNFT = IERC721(_heroesNft); // Token Hero Assets
        heroesToken = IBEP20(_heroesToken); // Token Heroes

        
        duckChancesBase = 1000;
        _levelUpPercent = 10; //10%

        _expTable[0] = 100 ether;
        _expTable[1] = 10 ether;
        _expTable[2] = 100 ether;
        _expTable[3] = 1000 ether;
        _expTable[4] = 10000 ether;
        _expTable[5] = 50000 ether;
        _expTable[6] = 150000 ether;

        _levelTable[0] = 0;
        _levelTable[1] = 6;
        _levelTable[2] = 5;
        _levelTable[3] = 4;
        _levelTable[4] = 3;
        _levelTable[5] = 2;
        _levelTable[6] = 0;



        duckChance.push(ChanceTableDuck({level: 1, maxValue: 4, minValue: 3, chance: 500}));
        duckChance.push(ChanceTableDuck({level: 1, maxValue: 6, minValue: 4, chance: 350}));
        duckChance.push(ChanceTableDuck({level: 1, maxValue: 9, minValue: 5, chance: 250}));
        duckChance.push(ChanceTableDuck({level: 2, maxValue: 20, minValue: 11, chance: 110}));
        duckChance.push(ChanceTableDuck({level: 2, maxValue: 60, minValue: 30, chance: 35}));
        duckChance.push(ChanceTableDuck({level: 2, maxValue: 90, minValue: 70, chance: 5}));    

	}

    /**
     * @notice Checks if the msg.sender is a contract or a proxy
     */
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    event summonhero(address Owner, uint256 tokenId, string nameHeroes, string category, uint256 exp, uint256 level);
    event RequestHero(uint256 tokenId, address Owner, string category);
    event LevelUp(address indexed user, uint indexed newLevel, uint[] parentsTokensId);

    struct ChanceTableDuck {uint8 level; uint128 maxValue; uint128 minValue;uint32 chance;}
    struct Heroes {string name; string category; uint256 exp; uint256 level; }
    struct Token {
        uint256 exp;
        uint256 level;
        bool stakeFreeze; //Lock a token when it is staked
        uint256 createTimestamp;
    }
    ChanceTableDuck[] public duckChance; //Duck chance table
    mapping(uint256 => Heroes) public heroes; //  tokenId=> Heroes Information 


//DUCKPART
    function setduckChanceTable(ChanceTableDuck[] calldata _newduckChanceTable)
        external
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        uint _duckChancesBase = 0;
        delete duckChance;
        for (uint i = 0; i < _newduckChanceTable.length; i++) {
            _duckChancesBase += _newduckChanceTable[i].chance;
            duckChance.push(_newduckChanceTable[i]);
        }
        duckChancesBase = _duckChancesBase;
    }

    //Internal functions --------------------------------------------------------------------------------------------

    function _isContract(address _addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function _distributePayment(uint Offer) internal {

        uint256 amountBurn = Offer.mul(amountBurnFee).div(100);
        uint256 amountTreasury = Offer.mul(amountTreasuryFee).div(100);
        uint256 amountMarketing = Offer.mul(amountMarketingFee).div(100);
        uint256 amountJackpot = Offer.mul(amountJackpotFee).div(100);
        
        heroesToken.safeTransferFrom(address(msg.sender), address(BurnFee), amountBurn);
        heroesToken.safeTransferFrom(address(msg.sender), address(TreasuryFee), amountTreasury);
        heroesToken.safeTransferFrom(address(msg.sender), address(MarketingFee), amountMarketing);
        heroesToken.safeTransferFrom(address(msg.sender), address(JackpotFee), amountJackpot); 
        
    }
    //Private functions --------------------------------------------------------------------------------------------

    function _getRandomDuck() private view returns (uint8, uint128) {
        ChanceTableDuck[] memory _duckChance = duckChance;
        uint _randomForLevel = _getRandomMinMax(1, duckChancesBase);
        uint count = 0;
        for (uint i = 0; i < _duckChance.length; i++) {
            count += _duckChance[i].chance;
            if (_randomForLevel <= count) {
                uint8 level = _duckChance[i].level;
                uint128 exp = uint128(_getRandomMinMax(_duckChance[i].minValue, _duckChance[i].maxValue));
                return (level, exp);
            }
        }
        revert("Cant find random level");
    }

    function _getRandomMinMax(uint _min, uint _max) private view returns (uint random) {
        uint diff = (_max - _min) + 1;
        random = (uint(keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()))) % diff) + _min;
    }

    function _mintLevelUp(uint level, uint[] memory tokenId) private {
        uint newEXP = 0;
        for (uint i = 0; i < tokenId.length; i++) {
            require(heroesNFT.ownerOf(tokenId[i]) == msg.sender, "Not owner of token");
            newEXP += heroesNFT.getHeroesNumber(tokenId[i]).exp;
            heroesNFT.burn(msg.sender, tokenId[i]);
            heroesNFT.deleteHeroesNumber(tokenId[i]);  
        }
        newEXP = newEXP + (newEXP * _levelUpPercent) / 100;
        _lastTokenId += 1;
        uint newTokenId = _lastTokenId;
        heroesNFT.addDuckNumber(newTokenId, level + 1, heroes[level + 1].name, heroes[level + 1].category, newEXP, level, block.timestamp, false );
        heroesNFT.safeMint(msg.sender, newTokenId);   
    }



    //Public functions --------------------------------------------------------------------------------------------

    function changeDistributeFee(address _receiveburn, address _receivetre, address _receivemarketing, address _receivejackpot) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_receiveburn != address(0) && _receivetre != address(0) && _receivemarketing != address(0) && _receivejackpot != address(0));
        BurnFee = payable(_receiveburn);
        TreasuryFee = payable(_receivetre);
        MarketingFee = payable(_receivemarketing);
        JackpotFee = payable(_receivejackpot);
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
    function changeEGGSUMMON(uint256 _max) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, address(msg.sender)), "Caller is not a owner");
        require(_max > 0, 'need Max > 0');
        MAXEGGSUMMON = _max;
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

    function summonegg(address to) public nonReentrant {
        require(hasRole(TOKEN_MINTER_ROLE, address(msg.sender)), "Caller is not a egg minter");
        require(to != address(0), "Address can not be zero");
        _lastTokenId += 1;
        uint tokenId = _lastTokenId;
        heroesNFT.addDuckNumber(tokenId, 1, heroes[1].name, heroes[1].category, heroes[1].exp, heroes[1].level, block.timestamp, false );
        heroesNFT.safeMint(to, tokenId);
    }

    function summoneggmax(address to, uint256 total) public nonReentrant {       
        require(total <= MAXEGGSUMMON, "Must below than Max Summon");    
        require(hasRole(TOKEN_MINTER_ROLE, address(msg.sender)), "Caller is not a egg minter");
        require(to != address(0), "Address can not be zero");
        for (uint i = 0; i < total; i++) {
            _lastTokenId += 1;
            uint tokenId = _lastTokenId;
            heroesNFT.addDuckNumber(tokenId, 1, heroes[1].name, heroes[1].category, heroes[1].exp, heroes[1].level, block.timestamp, false );
            heroesNFT.safeMint(to, tokenId);        
        }        


    }
    function hatcheggnormal(uint256 tokenId) public notContract nonReentrant {
        require(heroesNFT.ownerOf(tokenId) == msg.sender, "Not owner of token");
        require(heroesNFT.getHeroesNumber(tokenId).heroesNumber == 1, "Only Egg category can be hatch");
        heroesNFT.burn(msg.sender, tokenId);
        heroesNFT.deleteHeroesNumber(tokenId);  
        _lastTokenId += 1;
        uint newtokenId = _lastTokenId;
        heroesNFT.addDuckNumber(newtokenId, 2, heroes[2].name, heroes[2].category, heroes[2].exp, heroes[2].level, block.timestamp, false );
        heroesNFT.safeMint(msg.sender, newtokenId);        
    }


    function hatcheggpremium(uint256 tokenId) public notContract nonReentrant {
        require(heroesNFT.ownerOf(tokenId) == msg.sender, "Not owner of token");
        require(heroesNFT.getHeroesNumber(tokenId).heroesNumber == 1, "Only Egg category can be hatch");
        _distributePayment(feeSummon);
        heroesNFT.burn(msg.sender, tokenId);
        heroesNFT.deleteHeroesNumber(tokenId);  
        _lastTokenId += 1;
        uint newtokenId = _lastTokenId;
        (uint256 level, uint256 exp) = _getRandomDuck();

        heroesNFT.addDuckNumber(newtokenId, level + 1, heroes[level + 1].name, heroes[level + 1].category, exp * 1e18, level, block.timestamp, false );
        heroesNFT.safeMint(msg.sender, newtokenId);        
    }

    function levelUp(uint[] calldata tokenId) public nonReentrant {
        require(tokenId.length <= MAX_ARRAY_LENGTH_PER_REQUEST, "Array length gt max");
        uint currentLevel = heroesNFT.getHeroesNumber(tokenId[0]).level;
        require(_levelTable[currentLevel] != 0, "This level not upgradable");
        uint numbersOfToken = _levelTable[currentLevel];
        require(numbersOfToken == tokenId.length, "Wrong numbers of tokens received");
        uint neededEXP = numbersOfToken * _expTable[currentLevel];
        uint cumulatedEXP = 0;
        for (uint i = 0; i < numbersOfToken; i++) {
            (uint256 level, uint256 exp, , , , ,) = heroesNFT.getDuck(tokenId[i]); 
            require(level == currentLevel, "Token not from this level");
            cumulatedEXP += exp;
        }
        if (neededEXP == cumulatedEXP) {
            _mintLevelUp((currentLevel + 1), tokenId);
        } else {
            revert("Wrong exp amount");
        }
        emit LevelUp(msg.sender, (currentLevel + 1), tokenId);
    }











}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
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