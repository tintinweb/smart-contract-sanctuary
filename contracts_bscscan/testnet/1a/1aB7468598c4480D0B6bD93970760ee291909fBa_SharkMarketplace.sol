// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract AccessControl is Ownable, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;
    mapping(bytes32 => mapping(address => bool)) private _roles;
    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roleMembers[role].length();
    }

    function grantRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function revokeRole(bytes32 role, address account) public onlyOwner {
        _revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    function renounceRole(bytes32 role, address account) public {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Utils {
    function _recoverSigner(
        bytes32 message,
        bytes memory sig
    )
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

    function _splitSignature(
        bytes memory sig
    )
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
    function born(uint8 star) external returns (uint256);
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
import "../../common/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "hardhat/console.sol";

contract SharkMarketplace is Pausable, AccessControl, Utils {
    using SafeERC20 for IERC20;

    bytes32 public constant SIGNATURE_ROLE = keccak256("SIGNATURE_ROLE");

    address public teamContract;
    address public stakingContract;
    address public activityContract;
    address public agentContract;

    mapping (address => uint256) public nonces;
    
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
    event Breeding(uint256 indexed tokenId, uint256 orderId, uint256 sireId, uint256 matronId, uint256 genes, uint256 seaAmount, uint256 sssAmount);

    constructor(
        address gameToken_,
        address daoToken_,
        address sharkGenes_,
        address stakingContract_,
        address activityContract_,
        address teamContract_,
        address agentContract_
    ) {
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSharkGenes(address sharkGenes_) external onlyOwner {
        sharkGenes = ISharkGenes(sharkGenes_);
    }

    function setTeamContract(address _teamContract) external onlyOwner {
        teamContract = _teamContract;
    }

    function setActivityContract(address _activityContract) external onlyOwner {
        activityContract = _activityContract;
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
    }
    function setAgentContract(address _agentContract) external onlyOwner {
        agentContract = _agentContract;
    }

    function setBreedingDaoTokenNumerator(
        uint256 staking,
        uint256 activity,
        uint256 team
    )
        external 
        onlyOwner
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
        onlyOwner
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
        onlyOwner
    {
        require(team + inviter + agent + staking == denominator, "SetSettlementFeeNumerator: sum of numerator must equal denominator");
        settlementFeeTeamNumerator = team;
        settlementFeeInviteNumerator = inviter;
        settlementFeeAgentNumerator = agent;
        settlementFeeStakingNumerator = staking;
    }

    function setPersonalSettlementFeeInviterNumerator(
        uint256[] calldata numerators
    ) 
        external 
        onlyOwner
    {
        inviterRewardsNumerators = numerators;
    }

    function setsettlementFeeAgentNumerator(
        uint256[] calldata numerators
    ) 
        external 
        onlyOwner
    {
        agentRewardsNumerators = numerators;
    }

    function settlementAuctionFinal(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        address seller,
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

        bytes32 message = keccak256(
            abi.encodePacked(
                orderId,
                nftAddress,
                tokenId,
                seller,
                price,
                inviters,
                agents,
                nonces[_msgSender()]++,
                deadline
            )
        );
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "SettlementAuction: signature invalid");

        _settlementAuction(orderId, nftAddress, tokenId, seller, price, inviters, agents);
    }

    function _settlementAuction(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        address seller,
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
            _personalSettlement(orderId, sharkNFT, tokenId, seller, price, inviters, agents);
        }
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
        uint256 genes = sharkGenes.born(1);
        sharkNFT.bornShark(tokenId, genes, _msgSender());

        emit SettlementAuction(tokenId, orderId, address(0), _msgSender(), price);
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

        bytes32 message = keccak256(
            abi.encodePacked(
                orderId,
                nftAddress,
                sireId,
                matronId,
                tokenId,
                gameTokenAmount,
                daoTokenAmount,
                nonces[_msgSender()]++,
                deadline
            )
        );
        address signer = _recoverSigner(message, signature);
        require(hasRole(SIGNATURE_ROLE, signer), "Breeding: signature invalid");

        _breeding(orderId, nftAddress, sireId, matronId, tokenId, gameTokenAmount, daoTokenAmount);
    }
    
    function _personalSettlement(
        uint256 orderId,
        ISharkNFT sharkNFT,
        uint256 tokenId,
        address seller,
        uint256 price,
        address[] calldata inviters,
        address[] calldata agents
    )
        internal
    {
        require(price <= msg.value, "SettlementAuction: price error");

        address nftOwner = sharkNFT.ownerOf(tokenId);
        require(nftOwner != address(0) && seller == nftOwner && nftOwner != _msgSender(), "PersonalSettlement: seller invalid");


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

        emit Breeding(tokenId, orderId, sireId, matronId, genes, gameTokenAmount, daoTokenAmount);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}