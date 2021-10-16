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

interface ISharkGenes {
    function born() external returns (uint256);
    function breeding(uint256 sireGenes, uint256 matronGenes) external returns (uint256);
}

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

    function safeTransferFrom(
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
import "../core/ISharkGenes.sol";
import "../token/IGameToken.sol";
import "../../common/Utils.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "hardhat/console.sol";

contract SharkMarketplace is Pausable, AccessControl, Utils {
    using SafeERC20 for IERC20;

    bytes32 public constant SIGNATURE_ROLE = keccak256("SIGNATURE_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant REVENUE_ROLE = keccak256("REVENUE_ROLE");

    address public teamContract;
    address public stakingContract;
    address public activityContract;
    address public agentContract;

    mapping (address => uint256) public nonces;
    
    mapping(uint256 => uint256) public revenues;
    uint256 public revenue;

    // 分润配置
    uint256 public denominator = 10000;
    // 95.75% 归售卖用户, 4.25%手续费
    uint256 public settlementSellerNumerator = 9575;
    uint256 public settlementFeeNumerator = 425;
    // 手续费分润
    uint256 public settlementFeeTeamNumerator = 2000;
    uint256 public settlementFeeInviteNumerator = 1000;
    uint256 public settlementFeeAgentNumerator = 300;
    uint256 public settlementFeeStakingNumerator = 6700;
    // 合成daotoken分润 10%给团队, 30%给质押用户, 60%给活动奖励, 
    uint256 public breedingDaoTokenTeamNumerator = 1000;
    uint256 public breedingDaoTokenStakingNumerator = 3000;
    uint256 public breedingDaoTokenActivityNumerator = 6000;
    // 代理奖励分润
    uint256[] public agentRewardsNumerators = [6666, 3334];
    // 裂变奖励分润
    uint256[] public inviterRewardsNumerators = [6000, 4000];

    IGameToken private gameToken;
    IERC20 private daoToken;
    ISharkGenes private sharkGenes;

    event SettlementAuction(uint256 indexed tokenId, uint256 orderId, address seller, address buyer, uint256 amount);
    event Breeding(uint256 indexed tokenId, uint256 orderId, uint256 sireId, uint256 matronId, uint256 genes);
    event RevenueSettlement(uint256 indexed blockNumber, uint256 revenue);

    constructor(
        address gameToken_,
        address daoToken_,
        address sharkGenes_,
        address stakingContract_,
        address activityContract_,
        address teamContract_,
        address agentContract_
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(REVENUE_ROLE, msg.sender);

        gameToken = IGameToken(gameToken_);
        daoToken = IERC20(daoToken_);
        sharkGenes = ISharkGenes(sharkGenes_);
        
        stakingContract = stakingContract_;
        activityContract = activityContract_;
        teamContract = teamContract_;
        agentContract = agentContract_;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    function setSharkGenes(address sharkGenes_) external onlyRole(MANAGER_ROLE) {
        sharkGenes = ISharkGenes(sharkGenes_);
    }

    function setTeamContract(address _teamContract) external onlyRole(MANAGER_ROLE) {
        teamContract = _teamContract;
    }

    function setActivityContract(address _activityContract) external onlyRole(MANAGER_ROLE) {
        activityContract = _activityContract;
    }

    function setStakingContract(address _stakingContract) external onlyRole(MANAGER_ROLE) {
        stakingContract = _stakingContract;
    }
    function setAgentContract(address _agentContract) external onlyRole(MANAGER_ROLE) {
        agentContract = _agentContract;
    }

    function setBreedingDaoTokenNumerator(
        uint256 staking,
        uint256 activity,
        uint256 team
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(staking + activity + team == denominator, "SetBreedingDaoTokenNumerator: sum of numerator must equal denominator");

        breedingDaoTokenTeamNumerator = team;
        breedingDaoTokenStakingNumerator = staking;
        breedingDaoTokenActivityNumerator = activity;
    }

    function setSettlementNumerator(
        uint256 seller,
        uint256 fee
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(seller + fee == denominator, "SetSettlementNumerator: sum of numerator must equal denominator");

        settlementSellerNumerator = seller;
        settlementFeeNumerator = fee;
    }

    function setSettlementFeeNumerator(
        uint256 team,
        uint256 inviter,
        uint256 agent,
        uint256 staking
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(team + inviter + agent + staking == denominator, "SetSettlementFeeNumerator: sum of numerator must equal denominator");
        settlementFeeTeamNumerator = team;
        settlementFeeInviteNumerator = inviter;
        settlementFeeAgentNumerator = agent;
        settlementFeeStakingNumerator = staking;
    }

    function setPersonalSettlementFeeInviterNumerator(
        uint[] calldata numerators
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        inviterRewardsNumerators = numerators;
    }

    function setsettlementFeeAgentNumerator(
        uint[] calldata numerators
    ) 
        external 
        onlyRole(MANAGER_ROLE)
    {
        agentRewardsNumerators = numerators;
    }

    function settlementAuction(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents,
        uint256 deadline
    )
        external
        payable
        whenNotPaused
    {
        require(deadline >= block.timestamp, "SettlementAuction: expired");
        require(tokenId > 0, "SettlementAuction: tokenId error");

        _settlementAuction(orderId, nftAddress, tokenId, price, inviters, agents);
    }

    function settlementAuctionFinal(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents,
        uint256 deadline,
        bytes calldata signature
    )
        external
        payable
        whenNotPaused
    {
        require(deadline >= block.timestamp, "SettlementAuction: expired");
        require(tokenId > 0, "SettlementAuction: tokenId error");
        require(price <= msg.value, "SettlementAuction: price error");

        bytes32 message = keccak256(abi.encodePacked(orderId, nftAddress, tokenId, price, inviters, agents, nonces[_msgSender()]++, deadline));
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "SettlementAuction: signature invalid");

        _settlementAuction(orderId, nftAddress, tokenId, price, inviters, agents);
    }

    function _settlementAuction(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents
    )
        internal
    {
        ISharkNFT sharkNFT = _getNftContract(nftAddress);
        (, uint256 bornAt) = sharkNFT.getShark(tokenId);
        if (bornAt == 0) {
            _officalSettlement(orderId, sharkNFT, tokenId, price, inviters, agents);
        } else {
            _personalSettlement(orderId, sharkNFT, tokenId, price, inviters, agents);
        }
    }

    function revenueSettlement() external onlyRole(REVENUE_ROLE) {
        require(revenues[block.number] == 0);
        revenues[block.number] = revenue;
        revenue = 0;

        emit RevenueSettlement(block.number, revenue);
    }

    function _officalSettlement(
        uint256 orderId,
        ISharkNFT sharkNFT,
        uint256 tokenId,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents
    )
        internal
    {
        // burn sea
        uint256 burnAmount = price * settlementSellerNumerator / denominator;
        gameToken.burnFrom(_msgSender(), burnAmount);
        uint256 fee = price - burnAmount;

        gameToken.transferFrom(_msgSender(), address(this), fee);
        _distributionSettlementFeeToken(address(gameToken), fee, inviters, agents);

        // born shark
        uint256 genes = sharkGenes.born();
        sharkNFT.bornShark(tokenId, genes, _msgSender());

        emit SettlementAuction(tokenId, orderId, address(0), _msgSender(), price);
    }
  
    function breeding(
        uint256 orderId,
        address nftAddress,
        uint256 sireId,
        uint256 matronId,
        uint256 tokenId,
        uint256 gameTokenAmount,
        uint256 daoTokenAmount,
        uint256 deadline
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "Breeding: expired");
        require(tokenId > 0, "Breeding: tokenId error");
        require(gameTokenAmount > 0, "Breeding: SEA amount error");
        require(daoTokenAmount > 0, "Breeding: SSS amount error");

        _breeding(orderId, nftAddress, sireId, matronId, tokenId, gameTokenAmount, daoTokenAmount);
    }

    function breedingFinal(
        uint256 orderId,
        address nftAddress,
        uint256 sireId,
        uint256 matronId,
        uint256 tokenId,
        uint256 gameTokenAmount,
        uint256 daoTokenAmount,
        uint256 deadline,
        bytes calldata signature
    )
        external
        whenNotPaused
    {
        require(deadline >= block.timestamp, "Breeding: expired");
        require(tokenId > 0, "Breeding: tokenId error");
        require(gameTokenAmount > 0, "Breeding: SEA amount error");
        require(daoTokenAmount > 0, "Breeding: SSS amount error");

        bytes32 message = keccak256(abi.encodePacked(orderId, nftAddress, sireId, matronId, tokenId, gameTokenAmount, daoTokenAmount, nonces[_msgSender()]++, deadline));
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "Breeding: signature invalid");

        _breeding(orderId, nftAddress, sireId, matronId, tokenId, gameTokenAmount, daoTokenAmount);
    }
    
    function _personalSettlement(
        uint256 orderId,
        ISharkNFT sharkNFT,
        uint256 tokenId,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents
    )
        internal
    {
        require(price <= msg.value, "SettlementAuction: price error");

        address seller = sharkNFT.ownerOf(tokenId);
        require(seller != address(0) && seller != _msgSender(), "PersonalSettlement: seller invalid");

        revenue += price;

        uint256 sellerIncome = price * settlementSellerNumerator / denominator;
        payable(seller).transfer(sellerIncome);

        uint256 fee = price - sellerIncome;
        _distributionSettlementFee(fee, inviters, agents);

        sharkNFT.safeTransferFrom(seller, _msgSender(), tokenId);

        emit SettlementAuction(tokenId, orderId, seller, _msgSender(), price);
    }

    function _breeding(
        uint256 orderId,
        address nftAddress,
        uint256 sireId,
        uint256 matronId,
        uint256 tokenId,
        uint256 gameTokenAmount,
        uint256 daoTokenAmount
    )
        internal
    {
        ISharkNFT sharkNFT = _getNftContract(nftAddress);
        require(sharkNFT.ownerOf(sireId) == _msgSender(), "Breeding: sireId invalid");
        require(sharkNFT.ownerOf(matronId) == _msgSender(), "Breeding matronId invalid");

        (uint256 sireGenes,) = sharkNFT.getShark(sireId);
        (uint256 matronGenes,) = sharkNFT.getShark(matronId);
        uint256 genes = sharkGenes.breeding(sireGenes, matronGenes);

        // Burn parents
        sharkNFT.retireShark(sireId);
        sharkNFT.retireShark(matronId);

        // Born child
        sharkNFT.bornShark(tokenId, genes, _msgSender());

        _distributionbreedingFee(gameTokenAmount, daoTokenAmount);

        emit Breeding(tokenId, orderId, sireId, matronId, genes);
    }

    function _distributionbreedingFee(uint256 gameTokenAmount, uint256 daoTokenAmount) internal {
        // Burn game token
        gameToken.burnFrom(_msgSender(), gameTokenAmount);

        // Allocation of rewards
        uint256 toTeamAmount = daoTokenAmount * breedingDaoTokenTeamNumerator / denominator;
        daoToken.transferFrom(_msgSender(), teamContract, toTeamAmount);
        uint256 toStakingAmount = daoTokenAmount * breedingDaoTokenStakingNumerator / denominator;
        daoToken.transferFrom(_msgSender(), stakingContract, toStakingAmount);
        uint256 toActivityAmount = daoTokenAmount - toTeamAmount - toStakingAmount;
        daoToken.transferFrom(_msgSender(), activityContract, toActivityAmount);
    }

    function _getNftContract(address _nftAddress) internal pure returns (ISharkNFT) {
        ISharkNFT sharkNFT = ISharkNFT(_nftAddress);
        return sharkNFT;
    }

    function _distributionSettlementFee(
        uint256 fee,
        address[] calldata inviters,
        address[] calldata agents
    )
        private 
    {
        uint256 _toTeam = fee * settlementFeeTeamNumerator / denominator;
        _rewardsToTeam(_toTeam);
        
        uint256 _toInviter = _rewardsToInviter(
            fee * settlementFeeInviteNumerator / denominator,
            inviters
        );

        uint256 _toAgent = _rewardsToAgent(
            agents,
            fee * settlementFeeAgentNumerator / denominator
        );

        uint256 _toStaking = fee - _toTeam - _toInviter - _toAgent;
        _rewardsToStaking(_toStaking);
    }

    function _distributionSettlementFeeToken(
        address token_,
        uint256 fee,
        address[] calldata inviters,
        address[] calldata agents
    )
        private 
    {
        uint256 _toTeam = fee * settlementFeeTeamNumerator / denominator;
        _rewardsTokenToTeam(token_, _toTeam);

        uint256 _toInviter = _rewardsTokenToInviter(
            token_,
            fee * settlementFeeInviteNumerator / denominator,
            inviters
        );
        uint256 _toAgent = _rewardsTokenToAgent(
            agents,
            fee * settlementFeeAgentNumerator / denominator,
            token_
        );
        uint256 _toStaking = fee - _toTeam - _toInviter - _toAgent;
        
        _rewardsTokenToStaking(token_, _toStaking);
    }

    function _rewardsToTeam(uint256 amount) private {
        payable(teamContract).transfer(amount);
    }

    function _rewardsTokenToTeam(address token_, uint256 amount) private {
        IERC20(token_).safeTransfer(teamContract, amount);
    }

    function _rewardsToInviter(
        uint256 amount,
        address[] calldata inviters
    )
        private 
        returns (uint256)
    {
        uint256 actualAmount;
        for (uint8 i = 0; i < Math.min(inviters.length, inviterRewardsNumerators.length); i++) {
            uint256 _amount = amount * inviterRewardsNumerators[i] / denominator;
            payable(inviters[i]).transfer(_amount);
            actualAmount += _amount;
        }
        return actualAmount;
    }

    function _rewardsTokenToInviter(
        address token_, 
        uint256 amount,
        address[] calldata inviters
    )
        private 
        returns (uint256)
    {
        uint256 actualAmount;
        for (uint8 i = 0; i < Math.min(inviters.length, inviterRewardsNumerators.length); i++) {
            uint256 _amount = amount * inviterRewardsNumerators[i] / denominator;
            IERC20(token_).safeTransfer(inviters[i], _amount);
            actualAmount += _amount;
        }
        return actualAmount;
    }

    function _rewardsToAgent(
        address[] calldata agents, 
        uint256 amount
    )
        private 
        returns (uint256)
    {
        uint256 actualAmount;
        for (uint8 i = 0; i < Math.min(agents.length, agentRewardsNumerators.length); i++) {
            uint256 _amount = amount * agentRewardsNumerators[i] / denominator;
            (bool success, ) = agentContract.call{value: _amount}(abi.encodeWithSignature("deposit(address)", agents[i]));

            require(success, "RewardsToAgent");
            actualAmount += _amount;
        }
        return actualAmount;
    }

    function _rewardsTokenToAgent(
        address[] calldata agents,
        uint256 amount,
        address token_
    )
        private 
        returns (uint256)
    {
        IERC20 token  = IERC20(token_);

        if (token.allowance(address(this), agentContract) == 0) {
            token.approve(agentContract, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }

        uint256 actualAmount;
        for (uint8 i = 0; i < Math.min(agents.length, agentRewardsNumerators.length); i++) {
            uint256 _amount = amount * agentRewardsNumerators[i] / denominator;
            (bool success, ) = agentContract.call(
                abi.encodeWithSignature(
                    "depositToken(address,address,uint256)", 
                    token_, 
                    agents[i],
                    _amount
                )
            );
            require(success, "RewardsTokenToAgent");
            actualAmount += _amount;
        }
        return actualAmount;
    }

    function _rewardsToStaking(uint256 amount) private {
        payable(stakingContract).transfer(amount);
    }

    function _rewardsTokenToStaking(address token_, uint256 amount) private {
        IERC20(token_).safeTransfer(stakingContract, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGameToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}