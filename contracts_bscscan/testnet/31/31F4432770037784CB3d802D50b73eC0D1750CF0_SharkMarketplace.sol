// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ISharkGenes {
    function born(uint8 star) external returns (uint256);
    function bornSkin(uint8 star) external returns (uint256);
    function breeding(uint256 sireGenes, uint256 matronGenes) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

import "../core/ISharkNFT.sol";
import "../core/ISharkGenes.sol";
import "../../token/IGameToken.sol";
import "../../wallet/IServerSig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SharkMarketplace is Pausable, Ownable {
    using SafeERC20 for IERC20;

    address public teamContract;
    address public stakingContract;
    address public activityContract;
    address public agentContract;

    mapping (address => uint256) public nonces;
    
    uint256 constant public denominator = 10000;
    // official: 90% to burn; 5.75% to inviter; 4.25% to fee
    uint256 public settlementBurnNumerator = 9000;
    uint256 public settlementInviteNumerator = 575;
    // personal: 95.75% to seller; 4.25% to fee
    uint256 public settlementSellerNumerator = 9575;
    // 手续费分润
    uint256 public settlementFeeTeamNumerator = 2000;
    uint256 public settlementFeeInviteNumerator = 700;
    uint256 public settlementFeeAgentNumerator = 300;
    uint256 public settlementFeeStakingNumerator = 7000;
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
    IServerSig private signator;

    event SettlementAuction(uint256 indexed tokenId, uint256 orderId, address seller, address buyer, uint256 amount);
    event Breeding(uint256 indexed tokenId, uint256 orderId, uint256 sireId, uint256 matronId, uint256 genes, uint256 seaAmount, uint256 sssAmount);
    event SetServerSig(address indexed signator_);
    event SetSharkGenes(address indexed sharkGenes_);
    event SetTeamContract(address indexed _teamContract);
    event SetActivityContract(address indexed _activityContract);
    event SetStakingContract(address indexed _stakingContract);
    event SetAgentContract(address indexed _agentContract);
    event SetBreedingDaoTokenNumerator(uint256 staking, uint256 activity, uint256 team);
    event SetSettlementOfficialNumerator(uint256 burn, uint256 invite);
    event SetSettlementNumerator(uint256 seller);
    event SetSettlementFeeNumerator(uint256 team, uint256 inviter, uint256 agent, uint256 staking);
    event SetPersonalSettlementFeeInviterNumerator(uint256[] numerators);
    event SetsettlementFeeAgentNumerator(uint256[] numerators);

    constructor(
        address signator_,
        address gameToken_,
        address daoToken_,
        address sharkGenes_,
        address stakingContract_,
        address activityContract_,
        address teamContract_,
        address agentContract_
    ) {
        signator = IServerSig(signator_);

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
        emit SetSharkGenes(sharkGenes_);
    }

    function setServerSig(address signator_) external onlyOwner {
        signator = IServerSig(signator_);
        emit SetServerSig(signator_);
    }

    function setTeamContract(address _teamContract) external onlyOwner {
        teamContract = _teamContract;
        emit SetTeamContract(_teamContract);
    }

    function setActivityContract(address _activityContract) external onlyOwner {
        activityContract = _activityContract;
        emit SetActivityContract(_activityContract);
    }

    function setStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = _stakingContract;
        emit SetStakingContract(_stakingContract);
    }
    function setAgentContract(address _agentContract) external onlyOwner {
        agentContract = _agentContract;
        emit SetAgentContract(_agentContract);
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

        emit SetBreedingDaoTokenNumerator(staking, activity, team);
    }

    function setSettlementOfficialNumerator(
        uint256 burn,
        uint256 invite
    ) 
        external 
        onlyOwner
    {
        require(burn + invite <= denominator, "SetSettlementOfficialNumerator: sum of numerator must not greater than denominator");

        settlementBurnNumerator = burn;
        settlementInviteNumerator = invite;

        emit SetSettlementOfficialNumerator(burn, invite);
    }

    function setSettlementNumerator(
        uint256 seller
    ) 
        external 
        onlyOwner
    {
        require(seller <= denominator, "SetSettlementNumerator: sum of numerator must not greater than denominator");

        settlementSellerNumerator = seller;

        emit SetSettlementNumerator(seller);
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

        emit SetSettlementFeeNumerator(team, inviter, agent, staking);
    }

    function setPersonalSettlementFeeInviterNumerator(
        uint256[] calldata numerators
    ) 
        external 
        onlyOwner
    {
        uint256 totalNumerator = 0;
        for(uint8 i = 0; i < numerators.length ; i++){
            totalNumerator += numerators[i];
        }
        require(totalNumerator <= denominator, "setPersonalSettlementFeeInviterNumerator: sum of numerator must not greater than denominator");
        inviterRewardsNumerators = numerators;

        emit SetPersonalSettlementFeeInviterNumerator(numerators);
    }

    function setsettlementFeeAgentNumerator(
        uint256[] calldata numerators
    ) 
        external 
        onlyOwner
    {
        uint256 totalNumerator = 0;
        for(uint8 i = 0; i < numerators.length ; i++){
            totalNumerator += numerators[i];
        }
        require(totalNumerator <= denominator, "setsettlementFeeAgentNumerator: sum of numerator must not greater than denominator");
        agentRewardsNumerators = numerators;

        emit SetsettlementFeeAgentNumerator(numerators);
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

        bytes32 message = keccak256(
            abi.encodePacked(
                _msgSender(),
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
        signator.checkSignature(message, signature);

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
        uint256 burnAmount = price * settlementBurnNumerator / denominator;
        gameToken.burnFrom(_msgSender(), burnAmount);

        uint256 inviteFee = price * settlementInviteNumerator / denominator;
        uint256 fee = price - burnAmount - inviteFee;

        gameToken.transferFrom(_msgSender(), address(this), fee + inviteFee);
        _distributionSettlementFeeToken(address(gameToken), fee, inviteFee, inviters, agents);

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
                _msgSender(),
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
        signator.checkSignature(message, signature);

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
        if (fee > 0) {
            _distributionSettlementFee(fee, inviters, agents);
        }

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
        uint256 inviteFee,
        address[] calldata inviters,
        address[] calldata agents
    )
        private 
    {
        uint256 _toTeam = fee * settlementFeeTeamNumerator / denominator;
        _rewardsTokenToTeam(token_, _toTeam);

        uint256 _toAgent = _rewardsTokenToAgent(
            agents,
            fee * settlementFeeAgentNumerator / denominator,
            token_
        );

        uint256 _toInviter = _rewardsTokenToInviter(
            token_,
            inviteFee + fee * settlementFeeInviteNumerator / denominator,
            inviters
        );
        uint256 _toBurn = fee + inviteFee - _toTeam - _toInviter - _toAgent;
        if (_toBurn > 0) {
            gameToken.burn(_toBurn);
        }
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGameToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IServerSig {
    function checkSignature(
        bytes32 message, 
        bytes calldata signature
    )
        external;
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