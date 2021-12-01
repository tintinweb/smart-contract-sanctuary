// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/* solhint-disable not-rely-on-time */
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./interfaces/IBlacksmith.sol";
import "./interfaces/IHolyCard.sol";
import "./interfaces/IHolyKnightCore.sol";
import "./interfaces/IHolyKnightCards.sol";
import "./interfaces/IHolyShieldCards.sol";
import "./interfaces/IHolyWeaponCards.sol";
import "./interfaces/IHolyArmorCards.sol";
import "./interfaces/IHolyLandCards.sol";
import "./interfaces/IHolyTrinketCards.sol";
import "./interfaces/IBankingSystem.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IRandoms.sol";
import "./interfaces/IMedieverse.sol";
import "./libs/Governance.sol";
import "./libs/HolyLibrary.sol";

contract HolyKnightCore is IMedieverse, IHolyKnightCore, Initializable, Governance {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;
    using SafeMath for uint24;

    uint256 private constant DAILY_CLAIMED_AMOUNT = 10001;
    uint256 private constant CLAIM_TIMESTAMP = 10002;
    uint256 private constant REWARD_TAX = 6;
    uint256 private constant CLAIM_DURATION = 7;
    uint256 private constant MANA_COST_FIGHT = 1;
    uint256 private constant SOLIDITY_COST_FIGHT = 2;
    uint256 private constant EXP_GAIN = 1;
    uint256 private constant REWARD_PER_FIGHT = 2;
    uint256 private constant REWARD_BASE = 3;
    uint256 private constant BONUS_BY_ELEMENT = 4;
    uint256 private constant ONE_FRACTION = 5;
    uint256 private constant USERVAR_CLAIM_TIMESTAMP = 6;

    uint256 public constant END_BLOCK = 1638485868;
    address[] public contractList;
    /**
    0: HolyKnightWinToken;
    1: IHolyCard;
    2: IHolyKnight;
    3: IHolyWeapon;
    4: IHolyShield;
    5: IHolyArmor;
    6: IHolyLand;
    7: IHolyTrinket;
    8: IBankingSystem;
    9: IBlacksmith;
    10: IMarketPlace;
    11: ChainlinkOracle;
    12: StakingReward;
    */
    // Mapped user variable(userVars[]) keys, one value per wallet
    uint8[] public costFight;
    int128[] public rewardArray;
    mapping(address => uint256) public isAvatar;
    mapping(address => UserKnightSlot) public userKnightSlot;
    mapping(address => mapping(uint256 => bool)) public tokenOwners;
    mapping(address => uint256) public lastBlockCalledByUser;

    modifier checkEnd() {
        //require(block.timestamp < END_BLOCK, "##Event has ended!!");
        require(isAvatar[msg.sender] == 0, "Account has Avatar already!");
        //require(msg.value >= 10**18, "Mint Avatar Fee 1");
        _;
    }

    modifier knightLimit(address _account) {
        require(userKnightSlot[msg.sender].limit < 5, "Max Slot Knight");
        _;
    }

    modifier fiveBlockDelay(address _account) {
        require(lastBlockCalledByUser[_account] <= block.number.sub(5), "Too many transaction");
        lastBlockCalledByUser[_account] = block.number;
        _;
    }

    function initialize() public virtual initializer {
        initGovernance();
    }

    function migrateFunction(address[] calldata _addresses) public onlyContractCaller {
        for (uint8 i = 0; i < _addresses.length; i++) {
            contractList[i] = _addresses[i];
        }
        costFight[0] = 0;
        costFight[MANA_COST_FIGHT] = 40;
        costFight[SOLIDITY_COST_FIGHT] = 2;
        rewardArray[0] = 0;
        rewardArray[EXP_GAIN] = ABDKMath64x64.fromUInt(32);
        rewardArray[REWARD_PER_FIGHT] = ABDKMath64x64.divu(23177, 100000);
        rewardArray[REWARD_BASE] = ABDKMath64x64.divu(344, 1000);
        rewardArray[BONUS_BY_ELEMENT] = ABDKMath64x64.divu(75, 100);
        rewardArray[ONE_FRACTION] = ABDKMath64x64.fromUInt(1);
        rewardArray[REWARD_TAX] = ABDKMath64x64.divu(75, 100);
        rewardArray[CLAIM_DURATION] = ABDKMath64x64.fromUInt(15 days);
    }

    function recoverToken(address tokenAddress, uint256 amount) public onlyContractCaller {
        IERC20Upgradeable(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function chosenAvatar(string memory _avatarURI, string memory _avatarName)
        public
        checkEnd
        fiveBlockDelay(msg.sender)
    {
        string memory _newName = string(abi.encodePacked("AVATAR:: ", _avatarName));
        uint256 _tokenId = IHolyCards(contractList[0]).createHolyCard(msg.sender, 0, 3, _avatarURI, _newName, 0);
        isAvatar[msg.sender] = _tokenId;
    }

    function mintKnight(string memory _knightName, uint8 _element)
        public
        knightLimit(msg.sender)
        fiveBlockDelay(msg.sender)
        returns (uint256 _tokenId)
    {
        uint256 _mintFee = IBlacksmith(contractList[9]).getFee(0);
        uint256 _giveawayId = 0;
        if (userKnightSlot[msg.sender].limit > 0) _mintFee = _mintFee.sub(_mintFee.div(10));
        uint256 _userBalance = IBankingSystem(contractList[8]).getBalance(msg.sender);
        require(_userBalance >= _mintFee, "User Balance Adequacy");
        if (_mintFee > 0) IBankingSystem(contractList[8]).payFee(msg.sender, _mintFee);
        uint256 _seed = HolyLibrary.getRandomSeed(msg.sender, HolyLibrary.parseInt(_knightName));
        string memory _uri = IHolyKnightCards(contractList[2]).getkURI(_element);
        _tokenId = IHolyCards(contractList[0]).createHolyCard(msg.sender, 1, _seed, _uri, _knightName, _mintFee);
        IHolyKnightCards(contractList[2]).knightMinted(msg.sender, _tokenId, _seed, _element);
        if (userKnightSlot[msg.sender].limit == 0) {
            _giveawayId = mintArmor("First Giveaway Armor", _element, true);
            IHolyKnightCards(contractList[2]).setKnightKit(_tokenId, _giveawayId);
            _giveawayId = mintShield("First Giveaway Armor", _element, true);
            IHolyKnightCards(contractList[2]).setKnightKit(_tokenId, _giveawayId);
            _giveawayId = mintWeapon("First Giveaway Armor", _element, true);
            IHolyKnightCards(contractList[2]).setKnightKit(_tokenId, _giveawayId);
        }
        userKnightSlot[msg.sender].slot[userKnightSlot[msg.sender].limit] = _tokenId;
        userKnightSlot[msg.sender].limit++;
        return _tokenId;
    }

    function mintArmor(
        string memory _armorName,
        uint8 _element,
        bool _isFirst
    ) public returns (uint256 _tokenId) {
        uint256 _mintFee = IBlacksmith(contractList[9]).getFee(0).div(2);
        if (_isFirst) _mintFee = 0;
        uint256 _userBalance = IBankingSystem(contractList[8]).getBalance(msg.sender);
        require(_userBalance >= _mintFee, "User Balance Adequacy");
        if (_mintFee > 0) IBankingSystem(contractList[8]).payFee(msg.sender, _mintFee);
        uint256 _seed = HolyLibrary.getRandomSeed(msg.sender, HolyLibrary.parseInt(_armorName));
        string memory _uri = IHolyKnightCards(contractList[2]).getkURI(_element);
        _tokenId = IHolyCards(contractList[0]).createHolyCard(msg.sender, 4, _seed, _uri, _armorName, 0);
        IHolyArmorCards(contractList[5]).armorMinted(msg.sender, _tokenId, _seed);
    }

    function mintWeapon(
        string memory _weaponName,
        uint8 _element,
        bool _isFirst
    ) public returns (uint256 _tokenId) {
        uint256 _mintFee = IBlacksmith(contractList[9]).getFee(0).div(2);
        if (_isFirst) _mintFee = 0;
        uint256 _userBalance = IBankingSystem(contractList[8]).getBalance(msg.sender);
        require(_userBalance >= _mintFee, "User Balance Adequacy");
        if (_mintFee > 0) IBankingSystem(contractList[8]).payFee(msg.sender, _mintFee);
        uint256 _seed = HolyLibrary.getRandomSeed(msg.sender, HolyLibrary.parseInt(_weaponName));
        string memory _uri = IHolyKnightCards(contractList[2]).getkURI(_element);
        _tokenId = IHolyCards(contractList[0]).createHolyCard(msg.sender, 3, _seed, _uri, _weaponName, 0);
        IHolyWeaponCards(contractList[3]).weaponMinted(msg.sender, _tokenId, _seed, _element);
    }

    function mintShield(
        string memory _shieldName,
        uint8 _element,
        bool _isFirst
    ) public returns (uint256 _tokenId) {
        uint256 _mintFee = IBlacksmith(contractList[9]).getFee(0).div(2);
        if (_isFirst) _mintFee = 0;
        uint256 _userBalance = IBankingSystem(contractList[8]).getBalance(msg.sender);
        require(_userBalance >= _mintFee, "User Balance Adequacy");
        if (_mintFee > 0) IBankingSystem(contractList[8]).payFee(msg.sender, _mintFee);
        uint256 _seed = HolyLibrary.getRandomSeed(msg.sender, HolyLibrary.parseInt(_shieldName));
        string memory _uri = IHolyKnightCards(contractList[2]).getkURI(_element);
        _tokenId = IHolyCards(contractList[0]).createHolyCard(msg.sender, 2, _seed, _uri, _shieldName, 0);
        IHolyShieldCards(contractList[4]).shieldMinted(msg.sender, _tokenId, _seed);
    }

    function applyKnightKit(uint256 _tokenId, uint256 _itemId) public returns (bool _res) {
        require(
            IHolyCards(contractList[0]).getTokenOwner(_tokenId) == msg.sender &&
                (IHolyCards(contractList[0]).getTokenOwner(_itemId) == msg.sender ||
                    (IHolyCards(contractList[0]).getTokenOwner(_itemId) == address(this) &&
                        tokenOwners[msg.sender][_itemId] == true)),
            "Not owner or approved"
        );
        KnightKit memory _knight = IHolyKnightCards(contractList[2]).getKnightKit(_tokenId);
        uint8 _type = IHolyCards(contractList[0]).getCardTypeByTokenId(_itemId);
        string memory itemType = "";
        uint256 _tempId = 0;
        if (_type == 2) {
            itemType = "Shield";
            _tempId = _knight.shield;
            if (_tempId == 0) {
                _knight.shield = _itemId;
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            } else if (_tempId == _itemId && tokenOwners[msg.sender][_itemId] == true) {
                _knight.shield = 0;
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _itemId);
                tokenOwners[msg.sender][_itemId] = false;
                _res = true;
            } else if (tokenOwners[msg.sender][_tempId]) {
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _tempId);
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                _knight.shield = _itemId;
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            }
        } else if (_type == 3) {
            itemType = "Weapon";
            _tempId = _knight.weapon;
            if (_tempId == 0) {
                _knight.weapon = _itemId;
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            } else if (_tempId == _itemId && tokenOwners[msg.sender][_itemId] == true) {
                _knight.weapon = 0;
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _itemId);
                tokenOwners[msg.sender][_itemId] = false;
                _res = true;
            } else if (tokenOwners[msg.sender][_tempId]) {
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _tempId);
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                _knight.weapon = _itemId;
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            }
        } else if (_type == 4) {
            itemType = "Armor";
            _tempId = _knight.armor;
            if (_tempId == 0) {
                _knight.armor = _itemId;
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            } else if (_tempId == _itemId && tokenOwners[msg.sender][_itemId] == true) {
                _knight.armor = 0;
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _itemId);
                tokenOwners[msg.sender][_itemId] = false;
                _res = true;
            } else if (tokenOwners[msg.sender][_tempId]) {
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _tempId);
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                _knight.armor = _itemId;
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            }
        } else if (_type == 5) {
            itemType = "Land";
            _tempId = _knight.land;
            if (_tempId == 0) {
                _knight.land = _itemId;
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            } else if (_tempId == _itemId && tokenOwners[msg.sender][_itemId] == true) {
                _knight.land = 0;
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _itemId);
                tokenOwners[msg.sender][_itemId] = false;
                _res = true;
            } else if (tokenOwners[msg.sender][_tempId]) {
                IHolyCards(contractList[0]).transferCards(address(this), msg.sender, _tempId);
                IHolyCards(contractList[0]).transferCards(msg.sender, address(this), _itemId);
                _knight.land = _itemId;
                tokenOwners[msg.sender][_itemId] = true;
                _res = true;
            }
        }
        require(_res, "Invalid Cards ID");
        IHolyKnightCards(contractList[2]).setKnightKit(_knight, _tokenId, itemType);
        return _res;
    }

    function calcKnightPower(uint256 _tokenId) public view returns (uint24) {
        return IHolyKnightCards(contractList[2]).getkPower(_tokenId);
    }

    function getList() public view override returns (address[] memory) {
        return contractList;
    }

    function setList(address[] memory _lists) public override onlyContractCaller {
        for (uint8 i = 0; i < _lists.length; i++) contractList[i] = _lists[i];
    }

    function userDeposit(uint256 _amount) public fiveBlockDelay(msg.sender) {
        uint256 _holyToken = _amount.div(IPriceOracle(contractList[11]).getPrice());
        uint256 _tokenId = isAvatar[msg.sender];
        require(_tokenId > 0, "User Avatar Require");
        IERC20Upgradeable(contractList[0]).safeTransferFrom(msg.sender, address(this), _holyToken);
        IBankingSystem(contractList[8]).earnGold(_tokenId, _amount, true);
    }

    function userWithdrawal(uint256 _amount) public fiveBlockDelay(msg.sender) {
        uint256 _holyToken = _amount.div(IPriceOracle(contractList[11]).getPrice());
        uint256 _tokenId = isAvatar[msg.sender];
        require(_tokenId > 0, "User Avatar Require");
        require(IBankingSystem(contractList[8]).earnGold(_tokenId, _amount, false), "Fail to withdraw");
        IERC20Upgradeable(contractList[0]).safeTransferFrom(address(this), msg.sender, _holyToken);
    }

    function killMobs(uint256 _tokenId, uint8 _multiplier) public returns (uint8 _wins, uint8 _loses) {
        require(_multiplier > 0 && _multiplier < 17, "Limit by MaxMana");
        uint8 _turnLeft = IHolyKnightCards(contractList[2]).getkTurnLeft(
            _tokenId,
            IHolyKnightCards(contractList[2]).getLastBattle(_tokenId)
        );
        require(_turnLeft >= _multiplier, "Not enough turn left");
        require(IHolyKnightCards(contractList[2]).canRaid(_tokenId), "Knight cannot Raid");
        uint24 _knightPower = IHolyKnightCards(contractList[2]).getkPower(_tokenId);
        uint32[] memory _target = getMobs(_knightPower, _multiplier);
        uint32 _knightStat = (_knightPower << 8) |
            (IHolyKnightCards(contractList[2]).getkElement(_tokenId) & 0x7) |
            ((IHolyCards(contractList[0]).getRarityByTokenId(_tokenId) & 0x7) << 3) |
            ((IBankingSystem(contractList[8]).getNobleRank(_tokenId) & 0x3) << 6);
        for (uint8 i = 0; i < _multiplier; i++) {
            if (
                HolyLibrary.calcBattle(
                    _knightStat,
                    _target[5 * i + HolyLibrary.randomSeededMinMax(0, 5, block.timestamp)]
                )
            ) _wins += 1;
            else _loses += 1;
        }
        IHolyKnightCards(contractList[2]).setLastBattle(_tokenId, block.timestamp);
    }

    function getMobs(uint24 _knightPower, uint8 _multiplier) public view returns (uint32[] memory _mobs) {
        for (uint8 i = 0; i < _multiplier * 5; i++) _mobs[i] = _getMob(_knightPower);
    }

    function _getMob(uint24 _knightPower) internal view returns (uint32 _mobPower) {
        uint24 _tenPercent = _knightPower / 10;
        uint256 _seed = HolyLibrary.getRandomSeed(msg.sender, _knightPower);
        _mobPower = uint24(
            HolyLibrary.randomSeededMinMax(
                uint256(_knightPower.sub(_tenPercent)),
                uint256(_knightPower.add(_tenPercent)),
                _seed
            )
        );
        uint8 _mobStat = (uint8(HolyLibrary.randomSeededMinMax(0, 5, _seed)) & 0x7) |
            ((uint8(HolyLibrary.randomSeededMinMax(0, 7, _seed)) & 0x7) << 3) |
            ((uint8(HolyLibrary.randomSeededMinMax(0, 4, _seed)) & 0x3) << 6);
        _mobPower = _mobStat | (_mobPower << 8);
    }

    function getMobStat(uint32 _mobStat)
        public
        pure
        returns (
            uint8 _element,
            uint8 _rarity,
            uint8 _rank,
            uint24 _power
        )
    {
        _element = uint8(_mobStat & 0xFF) & 0x7;
        _rarity = (uint8(_mobStat & 0xFF) >> 3) & 0x7;
        _rank = uint8(_mobStat & 0xFF) >> 6;
        _power = uint24(_mobStat >> 8);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IBlacksmith is IMedieverse {
    function getOutfitSeed(uint256 _tokenId) external view returns (uint256);

    function reforgeItem(uint256 _tokenId, uint256 _trinketId) external;

    function engraveItem(uint256 _tokenId, uint256 _engraveId) external;

    function upgrade(
        address _account,
        uint256 _tokenId1,
        uint256 _tokenId2
    ) external returns (uint256);

    function rename(uint256 _tokenId, string memory _name) external;

    function migrateFunction(address[] calldata _contractList) external;

    function recoverToken(address tokenAddress, uint256 amount) external;

    event EngraveGiven(address indexed _account, uint32 _amount);

    function setBitwises(address[] memory _account, uint8 _bitwise) external;

    function unsetBitwises(address[] memory _account, uint8 _bitwise) external;

    function getBitwise(address _account, uint8 _bitwise) external view returns (bool);

    function getFee(uint8 _index) external view returns (uint256);

    function setFee(uint8 _index, uint256 _usdCents) external;

    function setFee(
        uint8 _index,
        uint256 _numerator,
        uint256 _denominator
    ) external;

    function purchaseShield() external;

    event OutfitGiven(address indexed _account, uint32 _outfit, uint32 _amount);
    event OutfitUsed(address indexed _account, uint32 _outfit, uint32 _amount);
    event OutfitRestored(address indexed _account, uint32 _outfit, uint32 _amount);
    event OutfitTakeByAdmin(address indexed _account, uint32 _outfit, uint32 _amount);
    event KnightUpgraded(address _account, uint256 tokenId, uint8 _holyRarity);
    event ShieldUpgraded(address _account, uint256 tokenId, uint8 _holyRarity);
    event WeaponUpgraded(address _account, uint256 tokenId, uint8 _holyRarity);
    event ArmorUpgraded(address _account, uint256 tokenId, uint8 _holyRarity);
    event ShieldReforged(uint256 _tokenId, uint16 _rareBonus, uint16 _legendBonus, uint16 _exoticBonus);
    event WeaponReforged(uint256 _tokenId, uint16 _rareBonus, uint16 _legendBonus, uint16 _exoticBonus);
    event ArmorReforged(uint256 _tokenId, uint16 _rareBonus, uint16 _legendBonus, uint16 _exoticBonus);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyCards is IMedieverse {
    function getRarityByIndex(uint8 _index) external view returns (uint256);

    function getRarityByTokenId(uint256 _tokenId) external view returns (uint8);

    function getName(uint256 _tokenId) external view returns (string memory);

    function getCardPrice(uint256 _tokenId) external view returns (uint256);

    function getHolyCardsByIndex(uint256 holyCardIndex) external view returns (HolyCardsIndex memory);

    function setHolyCardByIndex(HolyCardsIndex memory _newHolyCard, uint256 _tokenIndex) external;

    function createHolyCard(
        address _account,
        uint8 _holyType,
        uint256 _holyShit,
        string memory _uri,
        string memory _holyName,
        uint256 _price
    ) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function transferCards(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getTokenMetaData(uint _tokenId) external view returns (string memory);

    //function getTotalSupply() external view returns (uint256);

    function getAccountBalance(address _account) external view returns (uint256);

    function getTokenExists(uint256 _tokenId) external view returns (bool);

    function getTokenOwner(uint256 _tokenId) external view returns (address);

    function getCardTypeByIndex(uint8 _index) external view returns (uint256);

    function getCardTypeByTokenId(uint256 _tokenId) external view returns (uint8);

    function addCardType(string memory _type) external;

    function buyHolyCard(uint256 _tokenId) external payable;

    function changeCardPrice(uint256 _tokenId, uint256 _newPrice) external;

    function changeCardName(uint256 _tokenId, string memory _name) external;

    function changeCardRarity(
        uint256 _tokenId,
        uint8 _newRarity,
        string memory _newURI
    ) external;

    function toggleForSale(uint256 _tokenId) external;

    /* 
    function getRequireHoly(
        address _account,
        uint256 _holyAmount,
        bool _isAllow
    ) external view returns (uint256 requiredHoly);

    function getHolyToSubtract(
        uint256 _inGameOnlyFunds,
        uint256 _tokenRewards,
        uint256 _holyAmount
    )
        external
        pure
        returns (
            uint256 fromInGameOnlyFunds,
            uint256 fromTokenRewards,
            uint256 fromUserWallet
        );

    function getMonsterPower(uint32 _target) external pure returns (uint24);

    function getHolyGained(uint24 _monsterPower) external view returns (uint256);

    function getExpGained(uint24 _playerPower, uint24 _monsterPower) external view returns (uint16);

    function getPlayerPowerRoll(
        uint24 _playerFightPower,
        uint24 _element,
        uint256 _seed
    ) external view returns (uint24);

    function getMonsterPowerRoll(uint24 _monsterPower, uint256 _seed) external pure returns (uint24);

    function getPlayerPower(
        uint24 _basePower,
        int128 _weaponMultiplier,
        uint24 _bonusPower
    ) external pure returns (uint24);

    function getPlayerElementBonusAgainst(uint24 _element) external view returns (int128);

    function getTargets(uint256 _knightId, uint256 _weaponId) external view returns (uint32[5] memory);

    function isElementEffectiveAgainst(uint8 _attacker, uint8 _defender) external pure returns (bool);

    function getTokenRewards() external view returns (uint256);

    function getExpRewards(uint256 knightId) external view returns (uint256);

    function getTokenRewardsFor(address _account) external view returns (uint256);

    function getTotalHolyOwnedBy(address _account) external view returns (uint256);

    function getDataTable(uint256 _index) external returns (uint256); */

    event CreatHolyCard(address _to, string _holyName, uint8 _holyType, uint8 _holyRarity, uint256 _price);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyKnightCore {
    struct ContractList {
        address card;
        address knight;
        address weapon;
        address shield;
        address armor;
        address land;
        address trinket;
        address banking;
        address blacksmith;
        address marketplace;
        address holyToken;
        address chainlink;
        address staking;
    }

    function getList() external returns (address[] memory);

    function setList(address[] memory) external;
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyKnightCards is IMedieverse {
    function knightMinted(
        address _account,
        uint256 _tokenId,
        uint256 _seed,
        uint8 _element
    ) external;

    function customkMint(
        address _account,
        uint256 _tokenId,
        uint16 _exp,
        uint8 _level,
        uint8 _element,
        uint256 _seed
    ) external;

    function getk(uint256 _tokenId) external view returns (HolyKnight memory);

    function getKnightKit(uint256 _tokenId) external view returns (KnightKit memory);

    function getLastBattle(uint256 _tokenId) external view returns (uint256);

    function setLastBattle(uint256 _tokenId, uint256 _timestamp) external;

    function setk(HolyKnight memory _knight, uint256 _tokenId) external;

    function setKnightKit(
        KnightKit memory _knight,
        uint256 _tokenId,
        string memory _itemType
    ) external;

    function setKnightKit(uint256 _tokenId, uint256 _itemId) external;

    function getkURI(uint8 _index) external view returns (string memory);

    function getkLevel(uint256 _tokenId) external view returns (uint8);

    function getkExp4NextLevel(uint8 _curLevel) external view returns (uint16);

    function getkPower(uint256 _tokenId) external view returns (uint24);

    function getkPowerAtLevel(uint8 _level) external pure returns (uint24);

    function getkDamage(uint256 _tokenId) external view returns (uint64);

    function getkElement(uint256 _tokenId) external view returns (uint8);

    function getkExp(uint256 _tokenId) external view returns (uint32);

    function getkHitPoint(uint256 _tokenId) external view returns (uint64);

    function getkTurnLeft(uint256 _tokenId, uint256 _timestamp) external view returns (uint8 _turnLeft);

    function getkLimit() external view returns (uint8);

    //function getkNameMinSize() external view returns (uint8);

    //function getkNameMaxSize() external view returns (uint8);

    function getkManaLeft(uint256 _tokenId) external view returns (uint8);

    function getkManaByTimestamp(uint64 _timestamp) external view returns (uint8);

    //function getkOutfit(uint256 _tokenId) external view returns (uint32);

    function getkAfterCombat(
        uint256 _tokenId,
        uint8 _amount,
        bool _isNegative
    ) external returns (uint96);

    function isManaFull(uint256 _tokenId) external view returns (bool);

    //function isTurnReset(uint256 _tokenId) external view returns (bool);

    function canRaid(uint256 _tokenId) external view returns (bool);

    function registerBossEvent(
        address _account,
        uint256 _tokenId,
        bool _isWon,
        uint16 _exp
    ) external;

    function gainExp(
        address _account,
        uint256 _tokenId,
        uint16 _exp
    ) external;

    //function applykOutfit(uint256 _tokenId, uint32 _outfit) external;

    //function removekOutfit(uint256 _tokenId) external;

    //function setkNameMinSize(uint8 _newMinSize) external;

    //function setkNameMaxSize(uint8 _newMaxSize) external;

    function setkURI(uint8 _index, string memory _uri) external;

    //function setkOutfit(uint256 _tokenId, uint32 _outfit) external;

    function setkLimit(uint8 _maxKnight) external;

    //function setkName(uint256 _tokenId, string memory _newName) external;

    function setkElement(uint256 _tokenId, uint8 _element) external;

    function updatekHitPoint(uint256 _tokenId) external;

    function setTurnLeft(uint256 _tokenId, uint8 _turn) external;

    event NewHolyKnight(address indexed _account, uint256 indexed _tokenId);
    event HolyKnightRenamed(address indexed _account, uint256 indexed _tokenId);
    event KnightKitItemApply(uint256 _tokenId, string _itemType);
    event HolyKnightLevelUp(address indexed _account, uint256 indexed _tokenId, uint16 _level);
    event HolyKnightOutfitApplied(address indexed _account, uint256 indexed _tokenId, uint32 _outfit);
    event HolyKnightOutfitRemoved(address indexed _account, uint256 indexed _tokenId, uint32 _outfit);
    event HolyKnightElementChangedToAir(address indexed _account, uint256 indexed _tokenId, uint8 _oldElement);
    event HolyKnightElementChangedToFire(address indexed _account, uint256 indexed _tokenId, uint8 _oldElement);
    event HolyKnightElementChangedToEarth(address indexed _account, uint256 indexed _tokenId, uint8 _oldElement);
    event HolyKnightElementChangedToWater(address indexed _account, uint256 indexed _tokenId, uint8 _oldElement);
    event HolyKnightElementChangedToSpirit(address indexed _account, uint256 indexed _tokenId, uint8 _oldElement);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";
import "../interfaces/IBlacksmith.sol";

interface IHolyShieldCards is IMedieverse {
    function getShieldByTokenId(uint256 _tokenId) external view returns (HolyShields memory);

    function applyBonusPower(
        uint256 _tokenId,
        uint16 _amountRare,
        uint16 _amountLegend,
        uint16 _amountExotic
    ) external;

    function getShieldStatMin(uint8 _rarity) external pure returns (uint16);

    function getShieldStatMax(uint8 _rarity) external pure returns (uint16);

    function getShieldStatCount(uint8 _rarity) external pure returns (uint8);

    function getShieldRarity(uint256 _tokenId) external view returns (uint8);

    function getShieldElement(uint256 _tokenId) external view returns (uint8);

    function getGuardianElement(uint8 _statPattern) external pure returns (uint8);

    function getResistanceElement(uint8 _statPattern) external pure returns (uint8);

    function getBlockedElement(uint8 _statPattern) external pure returns (uint8);

    //function getDefMultiplier(uint256 _tokenId) external view returns (int128);

    function getShieldMilitancy(uint256 _tokenId, uint8 _knightElement)
        external
        view
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getShieldAfterCombat(
        uint256 _tokenId,
        uint8 _knightElement,
        uint8 _sapAmount
    )
        external
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getShieldTimestamp(uint256 _tokenId) external view returns (uint64);

    function getShieldSolidityByTokenId(uint256 _tokenId) external view returns (uint8);

    function getShieldByTimestamp(uint64 _timestamp) external view returns (uint8);

    function isSoliditydFull(uint256 _tokenId) external view returns (bool);

    function sapSolidity(uint256 _tokenId, uint8 _amount) external;

    function setShieldBlacksmith(IBlacksmith _wBlacksmith) external;

    function setShieldTimestamp(uint256 _tokenId, uint64 _timestamp) external;

    function shieldMinted(
        address _account,
        uint256 _tokenId,
        uint256 _seed
    ) external;

    function setShieldByTokenId(HolyShields memory _shield, uint256 _tokenId) external;

    function mintLegendShield(address _account, uint256 _tokenId) external;

    event NewShieldMinted(uint256 indexed _tokenId, address indexed _account);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IBlacksmith.sol";
import "./IMedieverse.sol";

interface IHolyWeaponCards is IMedieverse {
    function getWeapon(uint256 _tokenId) external view returns (HolyWeapons memory);

    function setw(HolyWeapons memory _weapon, uint256 _tokenId) external;

    function getWeaponStats(uint256 _tokenId)
        external
        view
        returns (
            uint16 _properties,
            uint16 _haste,
            uint16 _flawless,
            uint16 _critical,
            uint8 _level
        );

    function getWeaponURI(uint8 _index) external view returns (string memory);

    function setWeaponURI(uint8 _index, string memory _uri) external;

    function weaponMinted(
        address _account,
        uint256 _tokenId,
        uint256 _seed,
        uint8 _chosenElement
    ) external;

    function mintGiveawayWeapon(
        address _account,
        uint256 _tokenId,
        uint8 _rarity,
        uint8 _chosenElement
    ) external;

    function rawWeaponMinted(
        address _account,
        uint256 _tokenId,
        uint16 _properties,
        uint16 _haste,
        uint16 _flawless,
        uint16 _critical,
        uint8 _level
    ) external;

    function getRandomOutfit(
        uint256 _seed1,
        uint256 _seed2,
        uint8 _limit
    ) external pure returns (uint8);

    function applyBonusPower(
        uint256 _tokenId,
        uint16 _amountRare,
        uint16 _amountLegend,
        uint16 _amountExotic
    ) external;

    function getStatMin(uint8 _rarity) external pure returns (uint16);

    function getStatMax(uint8 _rarity) external pure returns (uint16);

    function getStatCount(uint8 _rarity) external pure returns (uint8);

    function getWeaponRarity(uint256 _tokenId) external view returns (uint8);

    function getWeaponElement(uint256 _tokenId) external view returns (uint8);

    function getStatPattern(uint256 _tokenId) external view returns (uint8);

    function getHasteElement(uint8 _statPattern) external pure returns (uint8);

    function getHasteValue(uint256 _tokenId) external view returns (uint16);

    function getFlawlessElement(uint8 _statPattern) external pure returns (uint8);

    function getFlawlessValue(uint256 _tokenId) external view returns (uint16);

    function getCriticalElement(uint8 _statPattern) external pure returns (uint8);

    function getCriticalValue(uint256 _tokenId) external view returns (uint16);

    function getWeaponLevel(uint256 _tokenId) external view returns (uint8);

    function getPowerMultiplier(uint256 _tokenId) external view returns (int128);

    function getPowerMultiplierByElement(uint256 _tokenId, uint8 _element) external view returns (int128);

    function getBonusPower4Fight(uint256 _tokenId) external view returns (uint24);

    function getWeaponMilitancy(uint256 _tokenId, uint8 _knightElement)
        external
        view
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getWeaponAfterCombat(
        address _account,
        uint256 _tokenId,
        uint8 _knightElement,
        uint8 _sapAmount,
        bool _isNegative
    )
        external
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getwTimestamp(uint256 _tokenId) external view returns (uint64);

    function getwSolidityByTokenId(uint256 _tokenId) external view returns (uint8);

    function getwSolidityByTimestamp(uint64 _timestamp) external view returns (uint8);

    function iswSolidityFull(uint256 _tokenId) external view returns (bool);

    function iswReady4Fight(uint256 _tokenId) external view returns (bool);

    function setwBonusMultiplier(uint256 _multiplier) external;

    function setwRareBonus(uint256 _bonus) external;

    function setwLegendBonus(uint256 _bonus) external;

    function setwExoticBonus(uint256 _bonus) external;

    function setwTimestamp(uint256 _tokenId, uint64 _timestamp) external;

    event WeaponOutfitApplied(address indexed _account, uint256 indexed _tokenId, uint32 _outfit);
    event WeaponOutfitRemoved(address indexed _account, uint256 indexed _tokenId, uint32 _outfit);
    event WeaponBurned(address indexed _account, uint256 indexed _tokenId);
    event NewWeapon(uint256 indexed _tokenId, address indexed _account);
    event WeaponReforged(
        address indexed _account,
        uint256 indexed _reforgedId,
        uint256 indexed _burnId,
        uint8 lowPoints,
        uint8 fourPoints,
        uint8 fivePoints
    );
    event WeaponReforgedWithDust(
        address indexed _account,
        uint256 indexed _reforgedId,
        uint8 rareDust,
        uint8 legendDust,
        uint8 exoticDust,
        uint8 rareBonus,
        uint8 legendBonus,
        uint8 exoticBonus
    );
    event WeaponRenamed(address indexed _account, uint256 indexed _tokenId);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";
import "../interfaces/IBlacksmith.sol";

interface IHolyArmorCards is IMedieverse {
    function getArmorByTokenId(uint256 _tokenId) external view returns (HolyArmors memory);

    function getArmorStatMin(uint8 _rarity) external pure returns (uint16);

    function getArmorStatMax(uint8 _rarity) external pure returns (uint16);

    function getArmorStatCount(uint8 _rarity) external pure returns (uint8);

    function getArmorRarity(uint256 _tokenId) external view returns (uint8);

    function getArmorElement(uint256 _tokenId) external view returns (uint8);

    function getGuardianElement(uint8 _statPattern) external pure returns (uint8);

    function getResistanceElement(uint8 _statPattern) external pure returns (uint8);

    function getBlockedElement(uint8 _statPattern) external pure returns (uint8);

    //function getDefMultiplier(uint256 _tokenId) external view returns (int128);

    function getArmorMilitancy(uint256 _tokenId, uint8 _knightElement)
        external
        view
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getArmorAfterCombat(
        uint256 _tokenId,
        uint8 _knightElement,
        uint8 _sapAmount
    )
        external
        returns (
            int128,
            int128,
            uint24,
            uint8
        );

    function getArmorTimestamp(uint256 _tokenId) external view returns (uint64);

    function getArmorSolidityByTokenId(uint256 _tokenId) external view returns (uint8);

    function getArmorByTimestamp(uint64 _timestamp) external view returns (uint8);

    function isSoliditydFull(uint256 _tokenId) external view returns (bool);

    function sapSolidity(uint256 _tokenId, uint8 _amount) external;

    function applyBonusPower(
        uint256 _tokenId,
        uint16 _amountRare,
        uint16 _amountLegend,
        uint16 _amountExotic
    ) external;

    function setArmorBlacksmith(IBlacksmith _wBlacksmith) external;

    function setArmorTimestamp(uint256 _tokenId, uint64 _timestamp) external;

    function armorMinted(
        address _account,
        uint256 _tokenId,
        uint256 _seed
    ) external;

    function setArmorByTokenId(HolyArmors memory _armor, uint256 _tokenId) external;

    function mintLegendArmor(address _account, uint256 _tokenId) external;

    event NewArmorMinted(uint256 indexed _tokenId, address indexed _account);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyLandCards is IMedieverse {
    function getLand(uint256 _tokenId) external view returns (HolyLand memory);

    function setLand(uint256 _tokenId, HolyLand memory _land) external;

    function renameLand(string memory _name, uint256 _tokenId) external;

    function landMinted(
        address _account,
        uint256 _tokenId,
        uint16 chunkId
    ) external;

    event LandRename(string _name, uint256 _tokenId, uint8 _landTier, uint16 _chunkId);
    event LandTransfered(address indexed _from, address indexed _to, uint256 _tokenId);
    event LandTokenMinted(address indexed _account, uint256 _tokenId, uint8 _landTier, uint16 _chunkId);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IHolyTrinketCards is IMedieverse {
    function getTrinket(uint256 _tokenId)
        external
        view
        returns (
            uint8,
            uint16,
            uint16,
            uint16,
            uint8
        );

    function trinketMinted(
        address _account,
        uint256 _tokenId,
        uint8 _rarity,
        uint8 _effect
    ) external;

    function setTrinket(
        uint256 _tokenId,
        uint8 _rarity,
        uint16 _rareBonus,
        uint16 _legendBonus,
        uint16 _exoticBonus,
        uint8 _effect
    ) external;

    event TrinketMinted(uint256 indexed _tokenId, address indexed _account);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;
import "./IMedieverse.sol";

interface IBankingSystem is IMedieverse {
    function migrateFunction(address[] calldata _contractLists) external;

    function getBalance(address _account) external view returns (uint256);

    function earnGold(
        uint256 _tokenId,
        uint256 _amount,
        bool _isSpend
    ) external returns (bool);

    function getNobleRank(uint256 _tokenId) external view returns (uint8);

    function earnRank(uint256 _tokenId, bool _uod) external returns (uint8);

    function stakeHolyLand(
        address _account,
        uint256 _knightId,
        uint256 _landId,
        uint256 _amount,
        uint256 _cert
    ) external;

    function withdrawReward(uint256 _knightId) external;

    function unstakeHolyLand(address _account, uint256 _knightId) external;

    function payFee(address _account, uint256 _amount) external;

    event GoldDeposit(address _account, uint256 _tokenId, uint256 _amount);
    event GoldWidthraw(address _account, uint256 _tokenId, uint256 _amount);
    event NobleUpgraded(address _account, uint256 _tokenId, uint8 _rank);
    event NobleDowngrade(address _account, uint256 _tokenId, uint8 _rank);
    event Stake(address _account, uint256 _amount, uint256 _timestamp);
    event UnStake(address _account, uint256 _tokenId, uint256 _amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0-rc.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;
import "./IMedieverse.sol";

interface IPriceOracle is IMedieverse {
    function getPrice() external view returns (uint256 _price);

    function setPrice(uint256 _price) external;

    event PriceUpdated(uint256 _price);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0-rc.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

interface IRandoms {
    function getRandomSeed(address _account) external view returns (uint256 _seed);

    function getRandomSeedUsingHash(address _account, bytes32 _hash) external view returns (uint256 _seed);
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;

interface IMedieverse {
    struct HolyCardsIndex {
        string holyName;
        uint8 holyType;
        uint8 holyRarity;
        string tokenURI;
        address mintedBy;
        address curOwner;
        address prevOwner;
        uint256 price;
        uint16 transferCount;
        bool forSale;
    }
    struct HolyKnight {
        uint16 exp;
        uint8 level;
        uint8 element;
        uint8 turnLeft;
        uint64 hitpoint;
    }
    struct KnightKit {
        uint8 version;
        uint256 armor;
        uint256 weapon;
        uint256 shield;
        uint256 land;
        uint256 seed;
    }
    struct HolyBlacksmith {
        string engrave;
        uint8 rareBonusReturn;
        uint8 legendBonusReturn;
        uint8 exoticBonusReturn;
        uint8 version;
        uint256 seed;
    }
    struct HolyMaxBonus {
        uint16 maxRare;
        uint16 maxLegend;
        uint16 maxExotic;
    }
    struct MintPayment {
        bytes32 blockHash;
        uint256 blockNumber;
        address nftAddress;
        uint count;
    }
    struct MintPaymentHolyDeposited {
        uint256 holy4Wallet;
        uint256 holy4Rewards;
        uint256 holy4Igo;
        uint256 holy1Wallet;
        uint256 holy1Rewards;
        uint256 holy1Igo;
        uint256 refund4Timestamp;
    }
    struct HolyArmors {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 extraHP;
        uint16 vitality;
        uint16 superior;
    }
    struct HolyLand {
        uint8 landTier;
        string landName;
        uint16 chunkId;
        uint8 cordX;
        uint8 cordY;
    }
    struct HolyShields {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 guardian;
        uint16 resistance;
        uint16 blocked;
    }
    struct HolyTrinket {
        uint8 rarity;
        uint16 rareBonus;
        uint16 legendBonus;
        uint16 exoticBonus;
        uint8 effect;
    }
    struct HolyWeapons {
        // right2left: 3bit=rarity, 2b=element, 7b=pattern, 4b=reserve, each point refers to .25% improvement
        uint16 properties;
        uint16 haste;
        uint16 flawless;
        uint16 critical;
        uint8 level;
    }
    struct WeaponBonusMultiply {
        uint bonusBase; // 2
        uint bonusRare; // 15
        uint bonusLegend; // 30
        uint bonusExotic; // 60
    }
    struct WeaponPowerBase {
        int128 weaponBase; // 1.0
        int128 powBasic; // 0.25%
        int128 powAdvanced; // 0.2575% (+3%)
        int128 powExpert; // 0.2675% (+7%)
    }
    struct BankingSystem {
        uint256 gold;
        uint8[] noble;
        uint256[] knight;
    }
    struct StakeCardInfo {
        uint256 landId;
        uint64 timestamp;
        int128 apy;
        uint256 certificate;
    }
    struct UserKnightSlot {
        uint256[] slot;
        uint8 limit;
    }
    struct HolyMaps {
        uint256 one;
        uint256 two;
        uint256 three;
        uint256 four;
        uint256 five;
        uint256 six;
        uint256 seven;
        uint256 eight;
        uint256 nine;
    }
    struct BattleMap {
        uint8 position;
        uint8 element;
        uint256 hitpoint;
        uint256 power;
    }
}

// SPDX-License-Identifier: MIT
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Governance is Initializable {
    address public _governance;
    mapping(address => bool) public isContractCaller;

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance() {
        require(msg.sender == _governance, "not governance");
        _;
    }

    modifier onlyContractCaller() {
        require(isContractCaller[msg.sender] || msg.sender == _governance, "Access Denied");
        _;
    }

    function initGovernance() internal initializer {
        _governance = msg.sender;
        isContractCaller[msg.sender] = true;
    }

    function getGovernance() public view returns (address) {
        return _governance;
    }

    function setGovernance(address governance) public onlyGovernance {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }

    function setContractCaller(address _caller) external onlyGovernance {
        require(_caller != address(0), "Cannot called by address zero");
        isContractCaller[_caller] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/* solhint-disable */
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Base64.sol";

library HolyLibrary {
    using SafeMath for uint256;

    function formatTokenURI(string memory imageURI) internal pure returns (string memory) {
        string memory baseURI = "data:application/json;base64,";
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                "REPLACE",
                                '", "description": "',
                                "REPLACE",
                                '", "attributes": "',
                                "REPLACE",
                                '", "image": "',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function svgToImageURI(string memory svg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));
    }

    function randomSeededMinMax(
        uint min,
        uint max,
        uint seed
    ) internal pure returns (uint) {
        uint diff = max > min ? max.sub(min).add(1) : min.sub(max).add(1);
        uint randomVar = uint(keccak256(abi.encodePacked(seed))).mod(diff);
        randomVar = randomVar.add(min);
        return randomVar;
    }

    function getRandomSeed(address user, uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, seed, block.timestamp)));
    }

    function getRandomSeedUsingHash(
        address user,
        uint256 seed,
        bytes32 hash
    ) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(user, seed, hash, block.timestamp)));
    }

    function combineSeeds(uint seed1, uint seed2) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seed1, seed2)));
    }

    function combineSeeds(uint[] memory seeds) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked(seeds)));
    }

    function plusMinus10PercentSeeded(uint256 num, uint256 seed) internal pure returns (uint256) {
        uint256 tenPercent = num.div(10);
        return num.sub(tenPercent).add(randomSeededMinMax(0, tenPercent.mul(2), seed));
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }

    function bytesToUint(bytes memory b) internal pure returns (uint256) {
        uint256 number;
        for (uint i = 0; i < b.length; i++) {
            number = number + uint8(b[i]) * (2**(8 * (b.length - (i + 1))));
        }

        return number;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function calcRarity(uint256 _seed) internal pure returns (uint8) {
        uint16 _index = uint16(_seed % 10000);
        if (_index < 4) {
            return 6;
        } else if (_index < 36) {
            return 5;
        } else if (_index < 144) {
            return 4;
        } else if (_index < 784) {
            return 3;
        } else if (_index < 2304) {
            return 2;
        } else if (_index < 5184) {
            return 1;
        }
        return 0;
    }

    function calcBattle(uint32 _knightStat, uint32 _mobStat) internal pure returns (bool) {
        uint24 _knightPower = uint24(_knightStat >> 8);
        uint24 _mobPower = uint24(_mobStat >> 8);
        uint8 _knightSeed = uint8(_knightStat & 0xFF);
        uint8 _mobSeed = uint8(_mobStat & 0xFF);
        if (_knightSeed > _mobSeed) {
            _knightPower = _knightPower + (((_knightSeed - _mobSeed) / 12) * _knightPower) / 100;
        } else {
            _knightPower = _knightPower - (((_mobSeed - _knightSeed) / 12) * _knightPower) / 100;
        }
        if (_knightPower >= _mobPower) return true;
        else return false;
    }

    function increaseRarity(uint16 _properties) internal pure returns (uint16) {
        uint8 _rarity = uint8(_properties & 0x7);
        uint8 _element = uint8(_properties & 0x7) << 3;
        uint8 _pattern = uint8(_properties & 0x7F) << 6;
        _rarity += 1;
        return uint16(_rarity | _element | _pattern);
    }

    function parseInt(string memory _a) internal pure returns (uint8 _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if ((uint8(uint8(bresult[i])) >= 48) && (uint8(uint8(bresult[i])) <= 57)) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function hdiv(uint256 _a) internal pure returns (uint8) {
        uint256 _b;
        while (_a > 10) _b = _a / 10;
        return uint8(_b);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
/* solhint-disable */

library Base64 {
    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}