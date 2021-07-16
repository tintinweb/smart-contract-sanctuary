pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

pragma solidity ^0.8.0;

import "./IBEP20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TKONFTMarketplace is ERC721Holder, AccessControl, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _numAsk;
    AggregatorV3Interface internal priceFeed;

    struct AskEntry {
        address _seller;
        address _contractNFT;
        uint256 _tokenId;
        uint256 _price;
        bool _firstSellingMerchant;
    }
    
    IBEP20 private tkoContract;
    uint256 private _feeMarketplace;
    uint256 private _feeOwner;
    uint256 private _feeMerchant;
    uint256 private _feeCollector;
    address private _feeAddress;
    uint256 private _expiredTimes;
    
    bytes32 public constant OPS_ROLE = keccak256("OPS_ROLE");
    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");

    mapping(uint256 => AskEntry) private _NFTSellers;
    mapping(uint256 => bool) private _numAskSellNFT;
    mapping(address => bool) private _suspendCollector;
    mapping(uint256 => bool) private _suspendNFT;
    mapping(address => mapping(uint256 => bool)) private _suspendNFTDetail;
    mapping(address => bool) private _contractNFT;
    mapping(address => mapping(uint256 => address)) private _firstSellingTokens;

    event Trade(uint256 indexed ask, address indexed seller, address indexed buyer, address contractNFT, uint256 tokenId, uint256 price);
    event Ask(uint256 indexed ask, address indexed seller, address contractNFT, uint256 tokenId, uint256 price);
    event CancelSellNFT(uint256 indexed ask, address indexed seller, address contractNFT, uint256 tokenId);
    event SuspendNFT(uint256 indexed ask, address indexed contractNFT, uint256 tokenId);
    event ContractNFT(address indexed contractNFT);

    constructor(address contractTKO, address feeAddress_, address contractPrice) {
        _numAsk.increment();
        _feeAddress = feeAddress_;
        tkoContract = IBEP20(contractTKO);
        _setupRole(OPS_ROLE, _msgSender());
        _setupRole(MERCHANT_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(MERCHANT_ROLE, OPS_ROLE);
        _expiredTimes = 10 minutes;
        priceFeed = AggregatorV3Interface(contractPrice);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function setFee(uint256 feeMarketplace_, uint256 feeOwner_, uint256 feeMerchant_, uint256 feeCollector_) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        require(feeMarketplace_ <= 1e4);
        require(feeOwner_ <= 1e4);
        require(feeMerchant_ <= 1e4);
        require(feeCollector_ <= 1e4);
        _feeMarketplace = feeMarketplace_;
        _feeOwner = feeOwner_;
        _feeMerchant = feeMerchant_;
        _feeCollector = feeCollector_;
    }

    function showFee() external view returns(uint256, uint256, uint256, uint256) {
        return (_feeMarketplace, _feeOwner, _feeMerchant, _feeCollector);
    }

    function setFeeAddress(address feeAddress_) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _feeAddress = feeAddress_;
    }

    function showFeeAddress() external view returns(address) {
        return _feeAddress;
    }

    function addContractNFT(address contractNFT_) external onlyRole(OPS_ROLE) whenNotPaused {
        _contractNFT[contractNFT_] = true;
        emit ContractNFT(contractNFT_);
    }

    function removeContractNFT(address contractNFT_) external onlyRole(OPS_ROLE) whenNotPaused {
        require(_contractNFT[contractNFT_] == true);
        delete _contractNFT[contractNFT_];
    }

    function isContractNFT(address contractNFT_) external view returns (bool) {
        return _contractNFT[contractNFT_];
    }

    function suspendCollector(address collector_) external onlyRole(OPS_ROLE) whenNotPaused {
        require(_suspendCollector[collector_] == false);
        _suspendCollector[collector_] = true;
    }

    function unsuspendCollector(address collector_) external onlyRole(OPS_ROLE) whenNotPaused {
        require(_suspendCollector[collector_] == true);
        delete _suspendCollector[collector_];
    }

    function isSuspendCollector(address collector_) external view returns(bool) {
        return _suspendCollector[collector_];
    }

    function suspendNFT(uint256 numAsk_) external onlyRole(OPS_ROLE) whenNotPaused {
        require(_suspendNFT[numAsk_] == false);
        AskEntry memory NFTSeller = _NFTSellers[numAsk_];
        _suspendNFT[numAsk_] = true;
        _suspendNFTDetail[NFTSeller._contractNFT][NFTSeller._tokenId] = true;
        emit SuspendNFT(numAsk_, NFTSeller._contractNFT, NFTSeller._tokenId);
    }

    function suspendNFTBatch(uint256[] memory numAsks_) external onlyRole(OPS_ROLE) whenNotPaused {
        for(uint256 i = 0; i < numAsks_.length; i++) {
            require(_suspendNFT[numAsks_[i]] == false);
            _suspendNFT[numAsks_[i]] = true;
            _suspendNFTDetail[_NFTSellers[numAsks_[i]]._contractNFT][_NFTSellers[numAsks_[i]]._tokenId] = true;
            emit SuspendNFT(numAsks_[i], _NFTSellers[numAsks_[i]]._contractNFT, _NFTSellers[numAsks_[i]]._tokenId);
        }
    }

    function unsuspendNFT(uint256 numAsk_) external onlyRole(OPS_ROLE) whenNotPaused {
        require(_suspendNFT[numAsk_] == true);
        AskEntry memory NFTSeller = _NFTSellers[numAsk_];
        delete _suspendNFT[numAsk_];
        delete _suspendNFTDetail[NFTSeller._contractNFT][NFTSeller._tokenId];
    }

    function unsuspendNFTBatch(uint256[] memory numAsks_) external onlyRole(OPS_ROLE) whenNotPaused {
        for(uint256 i = 0; i < numAsks_.length; i++) {
            require(_suspendNFT[numAsks_[i]] == true);
            delete _suspendNFT[numAsks_[i]];
            delete _suspendNFTDetail[_NFTSellers[numAsks_[i]]._contractNFT][_NFTSellers[numAsks_[i]]._tokenId];
        }
    }

    function isSuspendNFT(uint256 numAsk_) public view returns(bool) {
        return _suspendNFT[numAsk_];
    }

    function isSuspendNFTBatch(uint256[] memory numAsks_) public view returns(bool[] memory) {
        bool[] memory boolAsks = new bool[](numAsks_.length);
        for(uint256 i = 0; i < numAsks_.length; i++) {
            boolAsks[i] = _suspendNFT[numAsks_[i]];
        }
        return boolAsks;
    }

    function sellNFT(address contractNFT_, uint256 tokenId_, uint256 price_) public whenNotPaused {
        address sender = _msgSender();
        require(price_ > 0);
        require(_contractNFT[contractNFT_] == true);
        require(_suspendCollector[sender] == false);
        require(_suspendNFTDetail[contractNFT_][tokenId_] == false);
        uint256 numAsk = _numAsk.current();
        IERC721(contractNFT_).safeTransferFrom(sender, address(this), tokenId_);
        _numAskSellNFT[numAsk] = true;
        _numAsk.increment();
        if (hasRole(MERCHANT_ROLE, sender) == true && _firstSellingTokens[contractNFT_][tokenId_] == address(0)) {
            _firstSellingTokens[contractNFT_][tokenId_] = sender;
            _NFTSellers[numAsk] = AskEntry(sender, contractNFT_, tokenId_, price_, true);
        } else {
            _NFTSellers[numAsk] = AskEntry(sender, contractNFT_, tokenId_, price_, false);
        }
        emit Ask(numAsk, sender, contractNFT_, tokenId_, price_);
    }

    function sellNFTBatch(address contractNFT_, uint256[] memory tokenIds_, uint256 price_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            sellNFT(contractNFT_, tokenIds_[i], price_);
        }
    }

    function setCurrentPrice(uint256 numAsk_, uint256 price_) public whenNotPaused {
        address sender = _msgSender();
        AskEntry memory NFTSeller = _NFTSellers[numAsk_];
        require(price_ > 0);
        require(_suspendNFT[numAsk_] == false);
        require(_suspendCollector[sender] == false);
        require(NFTSeller._seller == sender);
        require(_numAskSellNFT[numAsk_] == true);
        _NFTSellers[numAsk_]._price = price_;
        emit Ask(numAsk_, sender, NFTSeller._contractNFT, NFTSeller._tokenId, price_);
    }

    function setCurrentPriceBatch(uint256[] memory numAsks_, uint256 price_) external {
        for (uint256 i = 0; i < numAsks_.length; i++) {
            setCurrentPrice(numAsks_[i], price_);
        }
    }

    function cancelSellNFT(uint256 numAsk_) public whenNotPaused {
        address sender = _msgSender();
        AskEntry memory NFTSeller = _NFTSellers[numAsk_];
        require(NFTSeller._seller == sender);
        require(_numAskSellNFT[numAsk_] == true);
        IERC721(NFTSeller._contractNFT).safeTransferFrom(address(this), sender, NFTSeller._tokenId);
        delete _numAskSellNFT[numAsk_];
        delete _NFTSellers[numAsk_];
        emit CancelSellNFT(numAsk_, sender, NFTSeller._contractNFT, NFTSeller._tokenId);
    }

    function cancelSellNFTBatch(uint256[] memory numAsks_) external {
        for (uint256 i = 0; i < numAsks_.length; i++) {
            cancelSellNFT(numAsks_[i]);
        }
    }

    function buyNFT(uint256 numAsk_) external whenNotPaused {
        address sender = _msgSender();
        AskEntry memory NFTSeller = _NFTSellers[numAsk_];
        (
            uint256 price,
            uint256 startedAt,
            uint256 updatedAt
        ) = getThePrice(numAsk_);
        require(_suspendNFT[numAsk_] == false);
        require(_suspendCollector[sender] == false);
        require(_numAskSellNFT[numAsk_] == true);
        require(NFTSeller._seller != sender);
        require(updatedAt <= (startedAt + _expiredTimes));
        uint256 feeOwner = (price / 1e4);
        uint256 amountForSeller = price;
        if (hasRole(MERCHANT_ROLE, NFTSeller._seller) == true && NFTSeller._firstSellingMerchant == true) {
            feeOwner *= _feeMarketplace;
            amountForSeller -= feeOwner;
        } else {
            if (_firstSellingTokens[NFTSeller._contractNFT][NFTSeller._tokenId] != address(0)) {
                feeOwner *= _feeOwner;
                uint256 feeMerchant = (price / 1e4) * _feeMerchant;
                amountForSeller = amountForSeller - feeOwner - feeMerchant;
                tkoContract.transferFrom(sender, _firstSellingTokens[NFTSeller._contractNFT][NFTSeller._tokenId], feeMerchant);
            } else {
                feeOwner *= _feeCollector;
                amountForSeller -= feeOwner;
            }
        }
        tkoContract.transferFrom(sender, _feeAddress, feeOwner);
        tkoContract.transferFrom(sender, NFTSeller._seller, amountForSeller);
        IERC721(NFTSeller._contractNFT).safeTransferFrom(address(this), sender, NFTSeller._tokenId);
        delete _numAskSellNFT[numAsk_];
        delete _NFTSellers[numAsk_];
        emit Trade(numAsk_, NFTSeller._seller, sender, NFTSeller._contractNFT, NFTSeller._tokenId, price);
    }

    function getAsk(uint256 numAsk_) external view returns(AskEntry memory) {
        return _NFTSellers[numAsk_];
    }

    function getAskBatch(uint256[] memory numAsks_) external view returns(AskEntry[] memory) {
        AskEntry[] memory asks = new AskEntry[](numAsks_.length);
        for(uint256 i = 0;i < numAsks_.length; i++) {
            asks[i] = AskEntry(_NFTSellers[numAsks_[i]]._seller, _NFTSellers[numAsks_[i]]._contractNFT,
            _NFTSellers[numAsks_[i]]._tokenId, _NFTSellers[numAsks_[i]]._price, _NFTSellers[numAsks_[i]]._firstSellingMerchant);
        }
        return asks;
    }

    function getAsksByPage(uint256 page_, uint256 size_) external view returns(AskEntry[] memory) {
        require(page_ > 0);
        require(size_ > 0);
        uint256 from = ((page_ - 1) * size_) + 1;
        uint256 to = page_ * size_;
        uint256 i = 0;
        AskEntry[] memory asks = new AskEntry[]((to - from + 1));
        for(uint256 a = from;a <= to; a++) {
            asks[i] = AskEntry(_NFTSellers[a]._seller, _NFTSellers[a]._contractNFT,
            _NFTSellers[a]._tokenId, _NFTSellers[a]._price, _NFTSellers[a]._firstSellingMerchant);
            i++;
        }
        return asks;
    }

    function getAsksByPageDesc(uint256 page_, uint256 size_) external view returns(AskEntry[] memory) {
        require(page_ > 0);
        require(size_ > 0);
        uint256 numAsk = _numAsk.current() - 1;
        uint256 from = numAsk - ((page_ - 1) * size_);
        uint256 to = numAsk - (page_ * size_) + 1;
        uint256 i = 0;
        AskEntry[] memory asks = new AskEntry[]((from - to + 1));
        for(uint256 a = from;a >= to; a--) {
            asks[i] = AskEntry(_NFTSellers[a]._seller, _NFTSellers[a]._contractNFT,
            _NFTSellers[a]._tokenId, _NFTSellers[a]._price, _NFTSellers[a]._firstSellingMerchant);
            i++;
        }
        return asks;
    }

    function setExpiredTimes(uint256 expiredTimes_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _expiredTimes = expiredTimes_ * 1 minutes;
    }

    function expiredTimes() external view returns(uint256, uint256, uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return (startedAt, updatedAt, _expiredTimes);
    }

    function getThePrice(uint256 numAsk_) public view returns(uint256, uint256, uint256) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint8 decimalsPF = priceFeed.decimals();
        uint256 price = (_NFTSellers[numAsk_]._price * (10 ** uint256(tkoContract.decimals()))) / uint256(answer) / (10 ** uint256(decimalsPF));
        return (price, startedAt, updatedAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers.
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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