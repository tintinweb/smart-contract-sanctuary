// Chonker GachaChonk Machine Manager contract
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./ChonkMachine.sol";

contract ChonkMachineManager is ReentrancyGuard, Ownable, AccessControl {
    
    using SafeMath for uint256;

    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    address public teamAccount;
    address public liquidityAccount;
    address public nftAddress;
    address public taiyakiAddress;
    address public wethAddress;

    /* Gachapon Machine Options */
    uint256[8][] public options;     // [Team?, ETH-Spin?, TaiyakiLP %, Chonk Buyback %, Chonk LP %, Team Funds %, Artist Funds%, Burn %]

    uint256 lastMachineIdx;

    mapping(address => ChonkMachine) public machines;
    address[] public machineIndices;

    event MachineAdded(uint256 id, address addr, string name, string description, uint256 option_idx, uint256 price, address owner);
    
    constructor(address _team, address _liquidityAccount, address _nft, address _taiyaki, address _weth) public {
        teamAccount = _team;
        liquidityAccount = _liquidityAccount;
        nftAddress = _nft;
        taiyakiAddress = _taiyaki;
        wethAddress = _weth;
        lastMachineIdx = 0;

        _initOptions();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAFF_ROLE, msg.sender);
    }

    function _initOptions() internal {
        options.push([1, 1, 40, 40,  0, 20,  0,  0]);
        options.push([1, 0, 40, 40,  0, 20,  0,  0]);
        options.push([1, 0, 80,  0,  0, 20,  0,  0]);
        options.push([1, 0,  0,  0,  0, 20,  0, 80]);
        options.push([1, 1,  0,  0, 80, 20,  0,  0]); 
        options.push([0, 1, 20,  0,  0, 20, 60,  0]);
        options.push([0, 0, 20,  0,  0, 20, 60,  0]);
    }

    function getOption(uint256 idx) public view returns (uint256[8] memory) {
        require(idx < options.length, "invalid idx");
        return options[idx];
    }

    function getOptionLength() public view returns (uint256) {
        return options.length;
    }

    function addMachine(string calldata _title, string calldata _description, uint256 _option_idx, uint256 _price, address _owner) 
        external nonReentrant  returns(uint256) {

        require(hasRole(STAFF_ROLE, msg.sender), "Must be staff to add machine");
        require(hasRole(ARTIST_ROLE, _owner) || hasRole(STAFF_ROLE, _owner), "Machine Owner must be artist or staff");
        require(_option_idx < options.length, "Invalid option idx");

        uint256[8] memory option = getOption(_option_idx);
        
        ChonkMachine m = new ChonkMachine(
            lastMachineIdx,
            _title,
            _description,
            IChonkNFT(nftAddress),
            IERC20(option[1] == 1 ? wethAddress : taiyakiAddress),
            _price,
            _owner,
            owner(),
            teamAccount,
            liquidityAccount
        );

        m.setupMachineOption(_option_idx, option);
        
        machines[address(m)] = m;
        machineIndices.push(address(m));

        emit MachineAdded(lastMachineIdx, address(m), _title, _description, _option_idx, _price, _owner);

        lastMachineIdx ++;
    }

    function addStaffAccount(address account) public nonReentrant onlyOwner {
        require(account != address(0), "staff is zero address");
        grantRole(STAFF_ROLE, account);
        for(uint256 i = 0; i < machineIndices.length; i++) {
            ChonkMachine(machineIndices[i]).addStaffAccount(account);
        }
    }

    function removeStaffAccount(address account) public nonReentrant onlyOwner {
        require(account != address(0), "staff is zero address");
        revokeRole(STAFF_ROLE, account);
        for(uint256 i = 0; i < machineIndices.length; i++) {
            ChonkMachine(machineIndices[i]).removeStaffAccount(account);
        }
    }

    function transferAdministrator(address account) public nonReentrant onlyOwner {
        require(account != address(0), "new administrator is zero address");
        
        grantRole(STAFF_ROLE, account);
        grantRole(DEFAULT_ADMIN_ROLE, account);

        for(uint256 i = 0; i < machineIndices.length; i++) {
            ChonkMachine(machineIndices[i]).transferAdministrator(account);
        }
        revokeRole(STAFF_ROLE, msg.sender);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);

        transferOwnership(account);
    }

    function changeTeamAccount(address account) public nonReentrant onlyOwner {
        require(account != address(0), "New team account is zero address");

        for(uint256 i = 0; i < machineIndices.length; i++) {
            ChonkMachine(machineIndices[i]).changeTeamAccount(account);
        }
    }

    function changeMachineOption(address m_address, uint256 _option_idx) public nonReentrant {
        ChonkMachine machine = machines[m_address];
        require(machine.isStaffAccount(msg.sender), "only for staff account");
        
        machine.setupMachineOption(_option_idx, options[_option_idx]);
    }

    function changeLiquidityAccount(address account) public nonReentrant onlyOwner {
        require(account != address(0), "New liquidity account is zero address");

        for(uint256 i = 0; i < machineIndices.length; i++) {
            ChonkMachine(machineIndices[i]).changeLiquidityAccount(account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

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

    constructor () internal {
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

// Chonker Gachapon Machine contract 
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";


interface IChonkNFT {
  function safeTransferFrom(address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data) external;
  function balanceOf(address account, uint256 id) external view returns (uint256);
  function mint(address to, uint256 id, uint256 amount) external;
}

contract ChonkMachine {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev Game round
     */
    struct Round {
        uint256 id; // request id.
        address player; // address of player.
        RoundStatus status; // status of the round.
        uint256 times; // how many times of this round;
        uint256 totalTimes; // total time of an account.
        uint256[20] cards; // Prize card of this round.
    }

    enum RoundStatus { Pending, Finished } // status of this round
    mapping(address => Round) public gameRounds;
    uint256 public currentRoundIdCount; //until now, the total round of this Gamemachine.
    uint256 public totalRoundCount;

    uint256 public machineId;
    string public machineTitle;
    string public machineDescription;
    string public machineUri;
    // [Team?, ETH-Spin?, TaiyakiLP %, Chonk Buyback %, Chonk LP %, Team Funds %, Artist Funds%, Burn %]
    uint256 public machineOptionIdx;
    uint256[8] public machineOption;
    bool public maintaining = true;
    bool public banned = false;

    // This is a set which contains cardID
    EnumerableSet.UintSet private _cardsSet;
    // This mapping contains cardId => amount
    mapping(uint256 => uint256) public amountWithId;
    // Prize pool with a random number to cardId
    mapping(uint256 => uint256) private _prizePool;
    // The amount of cards in this machine.
    uint256 public cardAmount;

    uint256 private _salt;
    uint256 public shuffleCount = 20;

     //[TaiyakiLP %, Chonk Buyback %, Chonk LP %, Team Funds %, Artist Funds%, Burn %] 
    uint256[6] public totalAmounts;
    
    address public burnAccount;
    address public artistAccount;
    address public teamAccount;
    address public liquidityAccount;

    EnumerableSet.AddressSet private _staffAccountSet;
    
    address public manager;
    address public owner;
    address public administrator;

    // Currency of the game machine, like Taiyaki, WETH
    IERC20 public currencyToken;
    IChonkNFT public nftToken;

    uint256 public playOncePrice;
    
    event AddCard(uint256 cardId, uint256 amount, uint256 cardAmount);
    event RemoveCard(uint256 card, uint256 removeAmount, uint256 cardAmount);
    event RunMachine(address account, uint256 times, uint256 playFee);

    event MachineLocked(bool locked);

    constructor(uint256 _machineId, //machine id
                string memory _machineTitle, // machine title.
                string memory _machineDescription, // machine title.
                IChonkNFT _nftToken, // nft token address
                IERC20 _currencyToken, // currency address
                uint256 _price,
                address _owner,
                address _administrator,
                address _teamAccount,
                address _liquidityAccount
                ) public {
        machineId = _machineId;
        nftToken = _nftToken;
        currencyToken = _currencyToken;
        playOncePrice = _price;
    
        _setupMachineTitle(_machineTitle);
        _setupMachineDescription(_machineDescription);

        burnAccount = 0x000000000000000000000000000000000000dEaD;
        administrator = _administrator;
        owner = _owner;
        artistAccount = _owner;
        manager = msg.sender;
        teamAccount = _teamAccount;
        liquidityAccount = _liquidityAccount;

        _staffAccountSet.add(administrator);

        _salt = uint256(keccak256(abi.encodePacked(_nftToken, _currencyToken, block.timestamp))).mod(10000);
    }

    //setup title
    function _setupMachineTitle(string memory _title) private {
        machineTitle = _title;
    }

    function _setupMachineDescription(string memory _description) private {
        machineDescription = _description;
    }

    function _checkMachineOption(uint256[8] memory option) pure private {
        //[Team?, ETH-Spin?, TaiyakiLP %, Chonk Buyback %, Chonk LP %, Team Funds %, Artist Funds%, Burn %] 
        require(option[2].add(option[3]).add(option[4]).add(option[5]).add(option[6]).add(option[7]) <= 100, "Invalid Machine Option");
    }

    //setup Machine Option
    function setupMachineOption(uint256 _option_idx, uint256[8] memory option) public onlyManager {
        _checkMachineOption(option);
        machineOptionIdx = _option_idx;
        machineOption = option;
    }

    /**
     * @dev Add cards which have been minted, and your owned cards
     * @param cardId. Card id you want to add.
     * @param amount. How many cards you want to add.
     */
    function addCard(uint256 cardId, uint256 amount, bool _mint) public onlyOwner unbanned {
        if(_mint) {
            nftToken.mint(address(this), cardId, amount);
        }else {
            require(nftToken.balanceOf(msg.sender, cardId) >= amount, "You don't have enough Cards");
            nftToken.safeTransferFrom(msg.sender, address(this), cardId, amount, "Add Card");
        }

        _cardsSet.add(cardId);
        amountWithId[cardId] = amountWithId[cardId].add(amount);
        for (uint256 i = 0; i < amount; i ++) {
            _prizePool[cardAmount + i] = cardId;
        }
        cardAmount = cardAmount.add(amount);
        emit AddCard(cardId, amount, cardAmount);
    }

    function runMachine(uint256 userProvidedSeed, uint256 times) public onlyHuman unbanned {
        require(!maintaining, "This machine is under maintenance");
        require(!banned, "This machine is banned.");
        require(cardAmount > 0, "There is no card in this machine anymore.");
        require(times > 0, "Times can not be 0");
        require(times <= 20, "Over times.");
        require(times <= cardAmount, "You play too many times.");
        _createARound(times);
        // get random seed with userProvidedSeed and address of sender.
        uint256 seed = uint256(keccak256(abi.encode(userProvidedSeed, msg.sender)));

        if (cardAmount > shuffleCount) {
            _shufflePrizePool(seed);
        }

        for (uint256 i = 0; i < times; i ++) {
            // get randomResult with seed and salt, then mod cardAmount.
            uint256 randomResult = _getRandomNumebr(seed, _salt, cardAmount);
            // update random salt.
            _salt = ((randomResult + cardAmount + _salt) * (i + 1) * block.timestamp).mod(cardAmount) + 1;
            // transfer the cards.
            uint256 result = (randomResult * _salt).mod(cardAmount);
            _updateRound(result, i);
        }

        totalRoundCount = totalRoundCount.add(times);
        uint256 playFee = playOncePrice.mul(times);
        _transferAndBurnToken(playFee);
        _distributePrize();

        emit RunMachine(msg.sender, times, playFee);
    }

    /**
     * @param amount how much token will be needed and will be burned.
     */
    function _transferAndBurnToken(uint256 amount) private {
        uint256 totalPaid = 0;
        address[6] memory accounts = [liquidityAccount, liquidityAccount, liquidityAccount, teamAccount, artistAccount, burnAccount];
        for(uint i = 0 ; i < 6; i++) {
            if(machineOption[i+2] != 0 && accounts[i] != address(0x0)) {
                uint256 rateAmount = amount.mul(machineOption[i+2]).div(100);
                currencyToken.transferFrom(msg.sender, accounts[i], rateAmount);
                totalAmounts[i] = totalAmounts[i].add(rateAmount);
                totalPaid = totalPaid.add(rateAmount);
            }
        }
        uint256 remainingAmount = amount.sub(totalPaid);
        currencyToken.transferFrom(msg.sender, teamAccount, remainingAmount);
    }


    function _distributePrize() private {
        for (uint i = 0; i < gameRounds[msg.sender].times; i ++) {
            uint256 cardId = gameRounds[msg.sender].cards[i];
            require(amountWithId[cardId] > 0, "No enough cards of this kind in the Mchine.");

            nftToken.safeTransferFrom(address(this), msg.sender, cardId, 1, 'Your prize from Chonker Gachapon');

            amountWithId[cardId] = amountWithId[cardId].sub(1);
            if (amountWithId[cardId] == 0) {
                _removeCardId(cardId);
            }
        }
        gameRounds[msg.sender].status = RoundStatus.Finished;
    }

    function _updateRound(uint256 randomResult, uint256 rand) private {
        uint256 cardId = _prizePool[randomResult];
        _prizePool[randomResult] = _prizePool[cardAmount - 1];
        cardAmount = cardAmount.sub(1);
        gameRounds[msg.sender].cards[rand] = cardId;
    }

    function _getRandomNumebr(uint256 seed, uint256 salt, uint256 mod) view private returns(uint256) {
        return uint256(keccak256(abi.encode(block.timestamp, block.difficulty, block.coinbase, block.gaslimit, seed, block.number))).mod(mod).add(seed).add(salt);
    }

    function _createARound(uint256 times) private {
        gameRounds[msg.sender].id = currentRoundIdCount + 1;
        gameRounds[msg.sender].player = msg.sender;
        gameRounds[msg.sender].status = RoundStatus.Pending;
        gameRounds[msg.sender].times = times;
        gameRounds[msg.sender].totalTimes = gameRounds[msg.sender].totalTimes.add(times);
        currentRoundIdCount = currentRoundIdCount.add(1);
    }

    // shuffle the prize pool again.
    function _shufflePrizePool(uint256 seed) private {
        for (uint256 i = 0; i < shuffleCount; i++) {
            uint256 randomResult = _getRandomNumebr(seed, _salt, cardAmount);
            _salt = ((randomResult + cardAmount + _salt) * (i + 1) * block.timestamp).mod(cardAmount);
            _swapPrize(i, _salt);
        }
    }

    function _swapPrize(uint256 a, uint256 b) private {
        uint256 temp = _prizePool[a];
        _prizePool[a] = _prizePool[b];
        _prizePool[b] = temp;
    }

    function _removeCardId(uint256 _cardId) private {
        _cardsSet.remove(_cardId);
    }

    function cardIdCount() view public returns(uint256) {
        return _cardsSet.length();
    }

    function cardIdWithIndex(uint256 index) view public returns(uint256) {
        return _cardsSet.at(index);
    }

    function changePlayOncePrice(uint256 newPrice) public onlyOwner {
        playOncePrice = newPrice;
    }

    function getCardId(address account, uint256 at) view public returns(uint256) {
        return gameRounds[account].cards[at];
    }

    function unlockMachine() public onlyOwner {   
        maintaining = false;
        emit MachineLocked(maintaining);
    }

    function lockMachine() public onlyOwner {
        maintaining = true;
        emit MachineLocked(maintaining);
    }

    // ***************************
    // For Admin Account ***********
    // ***************************
    function addStaffAccount(address account) public onlyManager {
        _staffAccountSet.add(account);
    }

    function removeStaffAccount(address account) public onlyManager {
        _staffAccountSet.remove(account);
    }

    function getStaffAccount(uint256 index) view public returns(address) {
        return _staffAccountSet.at(index);
    }

    function isStaffAccount(address account) view public returns(bool) {
        return _staffAccountSet.contains(account);
    }

    function staffAccountLength() view public returns(uint256) {
        return _staffAccountSet.length();
    }

    function transferAdministrator(address account) public onlyManager {
        require(account != address(0), "Ownable: new owner is zero address");
        administrator = account;
    }

    // transfer this machine to artist
    function transferOwnership(address newOwner) public onlyAdministrator {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    function removeOwnership() public onlyAdministrator {
        owner = address(0x0);
        artistAccount = address(0x0);
    }

    function changeArtistAccount(address account) public onlyOwner {
        require(account != address(0), "New artist is zero address");
        artistAccount = account;
    }

    function changeTeamAccount(address account) public onlyManager {
        require(account != address(0), "New team account is zero address");
        teamAccount = account;
    }

    function changeLiquidityAccount(address account) public onlyManager {
        require(account != address(0), "New liquidity account is zero address");
        liquidityAccount = account;
    }

    function changeShuffleCount(uint256 _shuffleCount) public onlyAdministrator {
        shuffleCount = _shuffleCount;
    }

    function banThisMachine() public onlyAdministrator {
        banned = true;
    }

    function unbanThisMachine() public onlyAdministrator {
        banned = false;
    }

    function changeMachineTitle(string memory title) public onlyOwner {
        machineTitle = title;
    }

    function changeMachineDescription(string memory description) public onlyOwner {
        machineDescription = description;
    }

    function changeMachineUri(string memory newUri) public onlyOwner {
        machineUri = newUri;
    }

    function cleanMachine() public onlyOwner returns(bool) {
        maintaining = true;
        banned = true;

        for (uint256 i = 0; i < cardIdCount(); i ++) {
            uint256 cardId = cardIdWithIndex(i);
            if (amountWithId[cardId] > 0) {
                nftToken.safeTransferFrom(address(this), owner, cardId, amountWithId[cardId], "Reset Machine");
                cardAmount = cardAmount.sub(amountWithId[cardId]);
                amountWithId[cardId] = 0;
            }
        }

        return true;
    }

    // This is a emergency function. you should not always call this function.
    function emergencyWithdrawCard(uint256 cardId) public onlyOwner {
        if (amountWithId[cardId] > 0) {
            nftToken.safeTransferFrom(address(this), owner, cardId, amountWithId[cardId], "Reset Machine");
            cardAmount = cardAmount.sub(amountWithId[cardId]);
            amountWithId[cardId] = 0;
        }
    }

    function isContract(address _addr) view private returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    // Modifiers
    modifier onlyHuman() {
        require(!isContract(address(msg.sender)) && tx.origin == msg.sender, "Only for human.");
        _;
    }

    modifier onlyAdministrator() {
        require(address(msg.sender) == administrator, "Only for administrator.");
        _;
    }

    modifier onlyManager() {
        require(address(msg.sender) == manager, "Only for manager.");
        _;
    }

    modifier onlyOwner() {
        require(address(msg.sender) == owner 
        || address(msg.sender) == administrator 
        || isStaffAccount(address(msg.sender)),
         "Only for owner.");
        _;
    }

    modifier unbanned() {
        require(!banned, "This machine is banned.");
        _;
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
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
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
        return address(uint160(uint256(_at(set._inner, index))));
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

