// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISharkNFT {
    function getShark(uint256 _sharkId)
        external
        view
        returns (uint256 /* _genes */, uint256 /* _bornAt */);

    function bornShark(
        uint256 _sharkId,
        uint256 _genes,
        address _owner
    ) external;

    function retireShark(
        uint256 _sharkId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(
        uint256 tokenId
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../core/ISharkNFT.sol";
import "../token/ISharkShakeSea.sol";
import "../utils/utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SharkMarketplace is Pausable, AccessControl, Utils {
    bytes32 public constant SIGNATURE_ROLE = keccak256("SIGNATURE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address public teamContract;
    address public stakingContract;
    address public activityContract;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    // 合成分润配置
    uint256 public denominator = 10000;
    // gametoken 90% 燃烧掉, 10%归质押奖励
    uint256 public breedingGameTokenBurnNumerator = 9000;
    uint256 public breedingGameTokenStakingNumerator = 1000;
    // daotoken 30%给质押用户, 60%给活动奖励, 10%给团队
    uint256 public breedingDaoTokenStakingNumerator = 3000;
    uint256 public breedingDaoTokenActivityNumerator = 6000;
    uint256 public breedingDaoTokenTeamNumerator = 1000;
    // 二手售卖分润配置
    // 94% 归售卖用户, 6%手续费(60%归质押用户)
    uint256 public personalSettlementSellerNumerator = 9400;
    uint256 public personalSettlementFeeNumerator = 600;
    // 官方售卖分润配置
    // 60% 归质押用户 20%归活动奖励 10%给团队
    uint256 public officialSettlementStakingNumerator = 6000;
    uint256 public officialSettlementFissionNumerator = 2000;
    uint256 public officialSettlementTeamNumerator = 2000;
    // 裂变奖励分润
    // 50%归活动奖励 50%归邀请者
    uint256 public fissionActivityNumerator = 5000;
    uint256[] public fissionBonus = [5000, 3000, 2000];

    mapping (address => bool) public settlementEnableTokens;

    ISharkShakeSea private GameToken;
    IERC20 private DaoToken;

    // event AddSettlementToken(address _token);
    // event RemoveSettlementToken(address _token);
    event AuctionSuccessful(uint256 indexed _tokenId, uint256 _orderId, address _seller, address _buyer, address _token, uint256 _totalPrice);
    event BreedingSuccessful(uint256 indexed _tokenId, uint256 _orderId, uint256 _sireId, uint256 _matronId, uint256 _genes);
    // event SetTeamContract(address _teamContract);
    // event SetStakingContract(address _stakingContract);
    // event SetActivityContract(address _activityContract);

    constructor(
        address gameToken_,
        address daoToken_,
        address stakingContract_,
        address activityContract_,
        address teamContract_,
        address[] memory settlementEnableTokens_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        GameToken = ISharkShakeSea(gameToken_);
        DaoToken = IERC20(daoToken_);
        
        stakingContract = stakingContract_;
        activityContract = activityContract_;
        teamContract = teamContract_;

        // enable wbnb
        for (uint i = 0; i < settlementEnableTokens_.length; i++) {
            settlementEnableTokens[settlementEnableTokens_[i]] = true;
        }
    }

    function setTeamContract(address _teamContract) external onlyRole(MANAGER_ROLE) {
        teamContract = _teamContract;
        // emit SetTeamContract(_teamContract);
    }

    function setActivityContract(address _activityContract) external onlyRole(MANAGER_ROLE) {
        activityContract = _activityContract;
        // emit SetActivityContract(_activityContract);
    }

    function setStakingContract(address _stakingContract) external onlyRole(MANAGER_ROLE) {
        stakingContract = _stakingContract;
        // emit SetStakingContract(_stakingContract);
    }

    function addSettlementToken(address _token) external onlyRole(MANAGER_ROLE) {
        require(!settlementEnableTokens[_token], "SharkMarketplace: token exists");
        settlementEnableTokens[_token] = true;
        // emit AddSettlementToken(_token);
    }

    function removeSettlementToken(address _token) external onlyRole(MANAGER_ROLE) {
        require(settlementEnableTokens[_token], "SharkMarketplace: token noexists");
        settlementEnableTokens[_token] = false;
        // emit RemoveSettlementToken(_token);
    }

    function setBreedingGameTokenNumerator(
        uint256 burn,
        uint256 staking
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(burn + staking == denominator, "SharkMarketplace: sum of numerator must equal denominator");
        breedingGameTokenBurnNumerator = burn;
        breedingGameTokenStakingNumerator = staking;
    }

    function setBreedingDaoTokenNumerator(
        uint256 staking,
        uint256 activity,
        uint256 team
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(staking + activity + team == denominator, "SharkMarketplace: sum of numerator must equal denominator");

        breedingDaoTokenStakingNumerator = staking;
        breedingDaoTokenActivityNumerator = activity;
        breedingDaoTokenTeamNumerator = team;
    }

    function setPersonalSettlementNumerator(
        uint256 seller,
        uint256 fee
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(seller + fee == denominator, "SharkMarketplace: sum of numerator must equal denominator");

        personalSettlementSellerNumerator = seller;
        personalSettlementFeeNumerator = fee;
    }

    function setOfficialSettlementNumerator(
        uint256 staking,
        uint256 fission,
        uint256 team
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(staking + fission + team == denominator, "SharkMarketplace: sum of numerator must equal denominator");

        officialSettlementStakingNumerator = staking;
        officialSettlementFissionNumerator = fission;
        officialSettlementTeamNumerator = team;
    }

    function setFissionNumerator(
        uint256 activity,
        uint256 inviter,
        uint256[] memory inverterInternal
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(activity + inviter == denominator, "SharkMarketplace: sum of numerator must equal denominator");

        fissionActivityNumerator = activity;
        fissionBonus = inverterInternal;
    }

    function settlementAction(
        uint256 _orderId,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _genes,
        address token,
        uint256 amount,
        address[] calldata inviters,
        uint256 deadline
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "SettlementAction: expired");

        // 检查允许的tokens
        require(settlementEnableTokens[token], "SettlementAction: token not enabled");

        _settlementAction(_orderId, _nftAddress, _tokenId, _genes, token, amount, inviters);
    }

    function settlementActionFinal(
        uint256 _orderId,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _genes,
        address token,
        uint256 amount,
        address[] calldata inviters,
        uint256 deadline,
        bytes calldata signature
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "SettlementAction: expired");

        // 验证签名
        // bytes32 message = keccak256(abi.encodePacked(_nftAddress, _tokenId, _genes, token, amount, inviters, nonces[_msgSender()]++, deadline));
        bytes32 message = keccak256(abi.encodePacked(_orderId, _nftAddress, _tokenId, _genes, token, amount, nonces[_msgSender()]++, deadline));
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "SettlementAction: signature invalid");

        // 检查允许的tokens
        require(settlementEnableTokens[token], "SettlementAction: token not enabled");

        _settlementAction(_orderId, _nftAddress, _tokenId, _genes, token, amount, inviters);
    }

    function _settlementAction(
        uint256 _orderId,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _genes,
        address token,
        uint256 amount,
        address[] memory inviters
    )
        internal
    {
        // 转移资产
        address _seller;
        uint256 bornAt;
        ISharkNFT _nftContract = _getNftContract(_nftAddress);
        (, bornAt) = _nftContract.getShark(_tokenId);
        if (bornAt == 0) {
            _seller = address(0);
            _nftContract.bornShark(_tokenId, _genes, _msgSender());

            _officialSettlementBonus(token, amount, inviters);
        } else {
            _seller = _nftContract.ownerOf(_tokenId);
            require(_seller != _msgSender(), "SettlementAction: _seller invalid");
            _nftContract.transferFrom(_seller, _msgSender(), _tokenId);

            _personalSettlementBonus(token, amount, _seller, inviters);
        }

        emit AuctionSuccessful(_tokenId, _orderId, _seller, _msgSender(), token, amount);
    }

    // 官方售卖分润
    function _officialSettlementBonus(address token, uint256 amount, address[] memory inviters) private {
        _officialIncomeBonus(token, amount, inviters);
    }

    // 二手售卖分润
    function _personalSettlementBonus(address token, uint256 amount, address seller,  address[] memory inviters) private {
        // 94% 给用户
        IERC20 erc20Token = IERC20(token);

        uint256 _toSellerAmount = amount * personalSettlementSellerNumerator / denominator;
        erc20Token.transferFrom(_msgSender(), seller, _toSellerAmount);

        // 手续费
        uint256 feeAmount = amount - _toSellerAmount;
        _officialIncomeBonus(token, feeAmount, inviters);
    }

    // 官方收入分润
    function _officialIncomeBonus(address token, uint256 amount, address[] memory inviters) private {
        IERC20 erc20Token = IERC20(token);

        // 20归团队
        uint256 _toTeamAmount = amount * officialSettlementTeamNumerator / denominator;
        erc20Token.transferFrom(_msgSender(), teamContract, _toTeamAmount);

        // 20%裂变奖励
        uint256 _toFissionAmount = _fissionBonus(token, amount * officialSettlementFissionNumerator / denominator, inviters);

        // 60%质押用户
        // uint256 _toStakingAmount = amount * officialSettlementStakingNumerator / denominator;
        uint256 _toStakingAmount = amount - _toTeamAmount - _toFissionAmount;
        erc20Token.transferFrom(_msgSender(), stakingContract, _toStakingAmount);
    }

    // 裂变分润
    function _fissionBonus(
        address token, 
        uint256 amount, 
        address[] memory inviters
    ) 
        private 
        returns (uint256)
    {
        uint256 _fissionAmount;
        IERC20 erc20Token = IERC20(token);

        // 50% 用于活动奖励
        uint256 _toActivityAmount = amount * fissionActivityNumerator / denominator;
        erc20Token.transferFrom(_msgSender(), activityContract, _toActivityAmount);
        _fissionAmount += _toActivityAmount;

        // 50% 用于邀请者
        uint256 _toInviterAmount = amount - _toActivityAmount;
        for (uint8 i = 0; i < inviters.length; i++) {
            uint256 _numerator = fissionBonus[i];
            if (_numerator == 0) {
                break;
            }

            uint256 _bonusAmount = _toInviterAmount * _numerator / denominator;
            erc20Token.transferFrom(_msgSender(), inviters[i], _bonusAmount);

            _fissionAmount += _bonusAmount;
        }

        return _fissionAmount;
    }

    function breeding(
        uint256 _orderId,
        address _nftAddress,
        uint256 _sireId,
        uint256 _matronId,
        uint256 _tokenId,
        uint256 _genes,
        uint256 _gameTokenAmount,
        uint256 _daoTokenAmount,
        uint256 deadline
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "Breeding: expired");

        _breeding(_orderId, _nftAddress, _sireId, _matronId, _tokenId, _genes, _gameTokenAmount, _daoTokenAmount);
    }

    function breedingFinal(
        uint256 _orderId,
        address _nftAddress,
        uint256 _sireId,
        uint256 _matronId,
        uint256 _tokenId,
        uint256 _genes,
        uint256 _gameTokenAmount,
        uint256 _daoTokenAmount,
        uint256 deadline,
        bytes calldata signature
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "Breeding: expired");

        // TODO 还原genes

        // 验证签名
        bytes32 message = keccak256(abi.encodePacked(_orderId, _nftAddress, _sireId, _matronId, _tokenId, _genes, _gameTokenAmount, _daoTokenAmount, nonces[_msgSender()]++, deadline));
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "Breeding: signature invalid");

        _breeding(_orderId, _nftAddress, _sireId, _matronId, _tokenId, _genes, _gameTokenAmount, _daoTokenAmount);
    }

    function _breeding(
        uint256 _orderId,
        address _nftAddress,
        uint256 _sireId,
        uint256 _matronId,
        uint256 _tokenId,
        uint256 _genes,
        uint256 _gameTokenAmount,
        uint256 _daoTokenAmount
    )
        internal
    {
        ISharkNFT _nftContract = _getNftContract(_nftAddress);

        require(_nftContract.ownerOf(_sireId) == _msgSender(), "Breeding: _sireId invalid");
        require(_nftContract.ownerOf(_matronId) == _msgSender(), "Breeding _matronId invalid");

        // 烧掉父母
        _nftContract.retireShark(_sireId);
        _nftContract.retireShark(_matronId);

        // mint新的
        _nftContract.bornShark(_tokenId, _genes, _msgSender());

        // 扣费 & 分润
        // game token 90% 燃烧, 10% 给质押用户
        uint256 _toBurnAmount = _gameTokenAmount * breedingGameTokenBurnNumerator / denominator;
        GameToken.burnFrom(_msgSender(), _toBurnAmount);
    
        uint256 _toStakingAmount = _gameTokenAmount - _toBurnAmount;
        GameToken.transferFrom(_msgSender(), stakingContract, _toStakingAmount);

        // dao token
        // 10% 给团队
        uint256 _toTeamAmount = _daoTokenAmount * breedingDaoTokenTeamNumerator / denominator;
        DaoToken.transferFrom(_msgSender(), teamContract, _toTeamAmount);

        // 30% 给质押用户
        uint256 _toStakingAmount2 = _daoTokenAmount * breedingDaoTokenStakingNumerator / denominator;
        DaoToken.transferFrom(_msgSender(), stakingContract, _toStakingAmount2);

        // 60% 回到奖励池
        // uint256 _toActivityAmount = _daoTokenAmount * breedingDaoTokenActivityNumerator / denominator;
        uint256 _toActivityAmount = _daoTokenAmount - _toStakingAmount2 - _toTeamAmount;
        DaoToken.transferFrom(_msgSender(), activityContract, _toActivityAmount);

        emit BreedingSuccessful(_tokenId, _orderId, _sireId, _matronId, _genes);
    }

    // @dev Gets the NFT object from an address, validating that implementsERC721 is true.
    // @param _nftAddress - Address of the NFT.
    function _getNftContract(address _nftAddress) internal pure returns (ISharkNFT) {
        ISharkNFT candidateContract = ISharkNFT(_nftAddress);
        return candidateContract;
    }

    // must delete from product
    function kill() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        selfdestruct(payable(_msgSender()));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISharkShakeSea is IERC20 {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Utils {
    function _decryptGenes(
        uint256 genes_, 
        address account,
         uint256 nonce_
    ) 
        internal 
        pure 
        returns(uint256)
    {
        return genes_  ^ nonce_ ^ (uint256(uint160(address(account))) << 96);
    }

    function _recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = _splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
   }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
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
    constructor() {
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

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

