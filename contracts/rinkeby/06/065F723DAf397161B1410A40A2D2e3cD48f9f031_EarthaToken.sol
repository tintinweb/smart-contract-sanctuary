// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import './extensions/ERC20Ratable.sol';
import './interface/IEarthaTokenRate.sol';
import './interface/IEscrowToken.sol';
import './interface/IEarthaToken.sol';
import './interface/IEscrowNFT.sol';

contract EarthaToken is ERC20, AccessControl, ERC20Ratable, IEarthaToken {
    using Counters for Counters.Counter;

    bytes32 public constant CREATIVE_REWARDS_WITHDRAWER_ROLE = keccak256('CREATIVE_REWARDS_WITHDRAWER_ROLE');

    uint256 public constant ESCROW_MAX_INCENTIVE = 0 ether;
    uint256 public constant ESCROW_AMOUNT_INCENTIVE_USD = 5 ether;
    uint256 public constant ESCROW_CREATIVE_REWARD_USD = 1 ether / 2;
    uint256 public constant ESCROW_MIN_AMOUNT = 400 ether;

    IEscrowNFT public immutable escrowNFT;
    uint256 private immutable _cap;

    mapping(uint256 => EscrowDetail) private _escrowDetail;
    Counters.Counter private _escrowIdTracker = Counters.Counter(1);

    uint256 public suppliedIncentives;
    uint256 public unpaidCreativeRewards;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_,
        IEscrowNFT escrowNFT_
    ) AccessControl() ERC20(name_, symbol_) {
        require(cap_ > 0, 'EarthaToken: cap is 0');
        _cap = cap_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(CREATIVE_REWARDS_WITHDRAWER_ROLE, _msgSender());

        ERC20._mint(_msgSender(), cap_ - ESCROW_MAX_INCENTIVE);
        ERC20._mint(address(this), ESCROW_MAX_INCENTIVE);
        escrowNFT = escrowNFT_;
    }

    modifier withdrawerOnly() {
        require(
            hasRole(CREATIVE_REWARDS_WITHDRAWER_ROLE, _msgSender()),
            'EarthaToken: must have withdrawer role to withdrawCreativeRewards'
        );
        _;
    }

    function createEscrow(
        address to,
        uint256 currencyValue,
        bool canRefund,
        uint256 terminatedTime,
        uint256 canRefundTime,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external virtual override {
        uint256 amount = tokenRate.getXToWithHedgeRate(currencyValue, currencyCode, hedgeRate);
        require(amount > ESCROW_MIN_AMOUNT, 'Minimum is 400 EAR');
        _transfer(_msgSender(), address(this), amount);
        EscrowDetail memory ed =
            EscrowDetail({
                creater: _msgSender(),
                recipient: to,
                createrTokenId: 0,
                recipientTokenId: 0,
                value: amount,
                currencyValue: currencyValue,
                status: EscrowStatus.Pending,
                currencyCode: currencyCode,
                hedgeRate: hedgeRate,
                canRefund: canRefund,
                terminatedTime: terminatedTime,
                canRefundTime: canRefundTime
            });
        uint256 escrowId = _escrowIdTracker.current();
        _escrowDetail[escrowId] = ed;
        _escrowIdTracker.increment();

        emit CreateNewEscrow(escrowId, ed.creater, ed.recipient);
    }

    function buyerSettlement(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender(), 'EarthaToken: not creater');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');

        ed.status = EscrowStatus.Completed;
        EscrowSettlementAmounts memory esa = _payOffEscrow(recipientAddress, createrAddress, ed);

        emit BuyerSettlement(escrowId, createrAddress, recipientAddress, esa);
    }

    function sellerSettlement(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(recipientAddress == _msgSender(), 'EarthaToken: not recepient');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.terminatedTime < block.timestamp, 'EarthaToken: terminatedTime error');

        ed.status = EscrowStatus.Terminated;
        EscrowSettlementAmounts memory esa = _payOffEscrow(recipientAddress, createrAddress, ed);

        emit SellerSettlement(escrowId, createrAddress, recipientAddress, esa);
    }

    function refund(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        address createrAddress = ed.createrTokenId != 0 ? escrowNFT.ownerOf(ed.createrTokenId) : ed.creater;
        address recipientAddress = ed.recipientTokenId != 0 ? escrowNFT.ownerOf(ed.recipientTokenId) : ed.recipient;
        require(createrAddress == _msgSender() || recipientAddress == _msgSender(), 'EarthaToken: not user');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.canRefund, 'EarthaToken: can not refund');
        require(ed.canRefundTime >= block.timestamp, 'EarthaToken: canRefundTime error');

        ed.status = EscrowStatus.Refunded;
        _transfer(address(this), createrAddress, ed.value);

        emit Refund(escrowId, createrAddress, recipientAddress);
    }

    function estimateEscrowSettlement(uint256 escrowId)
        external
        view
        virtual
        override
        returns (EscrowSettlementAmounts memory)
    {
        EscrowDetail memory ed = _escrowDetail[escrowId];
        EscrowSettlementAmounts memory esa;

        uint256 ratedAmount = tokenRate.getXTo(ed.currencyValue, ed.currencyCode);
        esa.recipientSubAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        esa.createrSubAmount = ed.value - esa.recipientSubAmount;
        if (esa.recipientSubAmount > 0) {
            (esa.recipientAmount, esa.recipientCreativeReward, esa.recipientIncentive) = _estimate(
                esa.recipientSubAmount
            );
        }
        if (esa.createrSubAmount > 0) {
            (esa.createrAmount, esa.createrCreativeReward, esa.createrIncentive) = _estimate(esa.createrSubAmount);
        }

        return (esa);
    }

    function createBuyerEscrowNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.creater == _msgSender(), 'EarthaToken: not creater');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.createrTokenId == 0, 'EarthaToken: Already exists');
        uint256 tokenId = escrowNFT.mint(ed.creater, escrowId);
        ed.createrTokenId = tokenId;
        emit CreateBuyerEscrowNFT(escrowId, tokenId, ed.creater);
    }

    function createSellerEscrowNFT(uint256 escrowId) external virtual override {
        EscrowDetail storage ed = _escrowDetail[escrowId];
        require(ed.recipient == _msgSender(), 'EarthaToken: not recipient');
        require(ed.status == EscrowStatus.Pending, 'EarthaToken: EscrowStatus is not Pending');
        require(ed.recipientTokenId == 0, 'EarthaToken: Already exists');
        if (ed.canRefund) {
            require(ed.canRefundTime < block.timestamp, 'EarthaToken: canRefundTime error');
        }
        uint256 tokenId = escrowNFT.mint(ed.recipient, escrowId);
        ed.recipientTokenId = tokenId;
        emit CreateSellerEscrowNFT(escrowId, tokenId, ed.recipient);
    }

    function getEscrowDetail(uint256 escrowId) external view virtual override returns (EscrowDetail memory) {
        return _escrowDetail[escrowId];
    }

    function withdrawCreativeRewards(address recipient) external virtual override withdrawerOnly() {
        require(unpaidCreativeRewards > 0, 'EarthaToken: unpaidCreativeRewards is 0');
        _transfer(address(this), recipient, unpaidCreativeRewards);
    }

    function cap() public view virtual override returns (uint256) {
        return _cap;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Ratable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _estimate(uint256 amount)
        internal
        view
        virtual
        returns (
            uint256 actualAmount,
            uint256 creativeReward,
            uint256 incentive
        )
    {
        uint256 incentiveRated = tokenRate.getXTo(ESCROW_AMOUNT_INCENTIVE_USD, 'USD');
        if (ESCROW_MAX_INCENTIVE >= (suppliedIncentives + incentiveRated)) {
            incentive = incentiveRated;
            amount += incentive;
        }
        uint256 creativeRewardRated = tokenRate.getXTo(ESCROW_CREATIVE_REWARD_USD, 'USD');
        creativeReward = amount > creativeRewardRated ? creativeRewardRated : amount;
        amount -= creativeReward;
        return (amount, creativeReward, incentive);
    }

    function _payOffEscrow(
        address recipientAddress,
        address createrAddress,
        EscrowDetail memory ed
    ) internal virtual returns (EscrowSettlementAmounts memory) {
        EscrowSettlementAmounts memory esa;

        uint256 ratedAmount = tokenRate.getXTo(ed.currencyValue, ed.currencyCode);
        esa.recipientSubAmount = ratedAmount > ed.value ? ed.value : ratedAmount;
        esa.createrSubAmount = ed.value - esa.recipientSubAmount;

        if (esa.recipientSubAmount > 0) {
            (esa.recipientAmount, esa.recipientCreativeReward, esa.recipientIncentive) = _estimate(
                esa.recipientSubAmount
            );
            suppliedIncentives += esa.recipientIncentive;
            unpaidCreativeRewards += esa.recipientCreativeReward;
            if (esa.recipientAmount > 0) {
                _transfer(address(this), recipientAddress, esa.recipientAmount);
            }
        }
        if (esa.createrSubAmount > 0) {
            (esa.createrAmount, esa.createrCreativeReward, esa.createrIncentive) = _estimate(esa.createrSubAmount);
            suppliedIncentives += esa.createrIncentive;
            unpaidCreativeRewards += esa.createrCreativeReward;
            if (esa.createrAmount > 0) {
                _transfer(address(this), createrAddress, esa.createrAmount);
            }
        }
        return esa;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../interface/IERC20Ratable.sol';
import '../interface/IEarthaTokenRate.sol';

abstract contract ERC20Ratable is ERC20, IERC20Ratable {
    IEarthaTokenRate public tokenRate;
    bool public initializedTokenRate = false;

    function initializeTokenRate(IEarthaTokenRate rate) external virtual {
        require(!initializedTokenRate, 'already initialized');
        tokenRate = rate;
        initializedTokenRate = true;
    }

    function totalSupply(string calldata currencyCode) external view virtual override returns (uint256) {
        uint256 totalSupplyValue = totalSupply();
        return _getToX(totalSupplyValue, currencyCode);
    }

    function balanceOf(address owner, string calldata currencyCode) external view virtual override returns (uint256) {
        uint256 balance = balanceOf(owner);
        return _getToX(balance, currencyCode);
    }

    function transfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transfer(recipient, ratedAmount);
    }

    function allowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view virtual override returns (uint256) {
        uint256 allowanceValue = allowance(owner, spender);
        return _getToX(allowanceValue, currencyCode);
    }

    function approve(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return approve(spender, ratedAmount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAmount = _getXTo(amount, currencyCode);
        return transferFrom(sender, recipient, ratedAmount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedAddedValue = _getXTo(addedValue, currencyCode);
        return increaseAllowance(spender, ratedAddedValue);
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external virtual override returns (bool) {
        uint256 ratedSubtractedValue = _getXTo(subtractedValue, currencyCode);
        return decreaseAllowance(spender, ratedSubtractedValue);
    }

    function _getXTo(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        return tokenRate.getXTo(amount, currencyCode);
    }

    function _getToX(uint256 amount, string calldata currencyCode) internal view virtual returns (uint256) {
        return tokenRate.getToX(amount, currencyCode);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface IERC20Ratable {
    function totalSupply(string calldata currencyCode) external view returns (uint256);

    function balanceOf(address owner, string calldata currencyCode) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function allowance(
        address owner,
        address spender,
        string calldata currencyCode
    ) external view returns (uint256);

    function approve(
        address spender,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        string calldata currencyCode
    ) external returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue,
        string calldata currencyCode
    ) external returns (bool);

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue,
        string calldata currencyCode
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IERC20Ratable.sol';
import './IEscrowToken.sol';

interface IEarthaToken is IERC20, IERC20Ratable, IEscrowToken {
    function withdrawCreativeRewards(address recipient) external;

    function cap() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import './ITokenRate.sol';
import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

interface IEarthaTokenRate is ITokenRate {
    event UpdatedSource(string currencyCode, AggregatorV3Interface source);

    function getXToWithHedgeRate(
        uint256 amount,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external view returns (uint256);

    function setSource(string calldata currencyCode, AggregatorV3Interface source) external returns (bool);

    function setUSDSource(AggregatorV3Interface source) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IEscrowNFT is IERC721 {
    function mint(address to, uint256 escrowId) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface IEscrowToken {
    event CreateNewEscrow(uint256 escrowId, address indexed creater, address indexed recipient);
    event BuyerSettlement(
        uint256 indexed escrowId,
        address indexed creater,
        address indexed recipient,
        EscrowSettlementAmounts esa
    );
    event SellerSettlement(
        uint256 indexed escrowId,
        address indexed creater,
        address indexed recipient,
        EscrowSettlementAmounts esa
    );
    event Refund(uint256 indexed escrowId, address indexed creater, address indexed recipient);
    event CreateBuyerEscrowNFT(uint256 indexed escrowId, uint256 tokenId, address tokenCreater);
    event CreateSellerEscrowNFT(uint256 indexed escrowId, uint256 tokenId, address tokenCreater);

    enum EscrowStatus {Pending, Completed, Terminated, Refunded}

    struct EscrowDetail {
        address creater;
        address recipient;
        uint256 createrTokenId;
        uint256 recipientTokenId;
        uint256 currencyValue;
        uint256 value;
        string currencyCode;
        uint16 hedgeRate;
        EscrowStatus status;
        bool canRefund;
        uint256 canRefundTime;
        uint256 terminatedTime;
    }
    struct EscrowSettlementAmounts {
        uint256 recipientAmount;
        uint256 recipientSubAmount;
        uint256 recipientCreativeReward;
        uint256 recipientIncentive;
        uint256 createrAmount;
        uint256 createrSubAmount;
        uint256 createrCreativeReward;
        uint256 createrIncentive;
    }

    function createEscrow(
        address to,
        uint256 currencyValue,
        bool canRefund,
        uint256 terminatedTime,
        uint256 canRefundTime,
        string calldata currencyCode,
        uint16 hedgeRate
    ) external;

    function buyerSettlement(uint256 escrowId) external;

    function sellerSettlement(uint256 escrowId) external;

    function refund(uint256 escrowId) external;

    function estimateEscrowSettlement(uint256 escrowId) external view returns (EscrowSettlementAmounts memory);

    function createBuyerEscrowNFT(uint256 escrowId) external;

    function createSellerEscrowNFT(uint256 escrowId) external;

    function getEscrowDetail(uint256 escrowId) external view returns (EscrowDetail memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.22 <0.9.0;

interface ITokenRate {
    function getToX(uint256 amount, string calldata currencyCode) external view returns (uint256);

    function getXTo(uint256 amount, string calldata currencyCode) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 800
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