// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IMigration.sol";
import "./interfaces/IRiskPoolFactory.sol";
import "./interfaces/ISingleSidedInsurancePool.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IRiskPool.sol";
import "./interfaces/IPremiumPool.sol";
import "./interfaces/ISalesPolicyFactory.sol";
import "./interfaces/ISalesPolicy.sol";
import "./libraries/TransferHelper.sol";

contract SingleSidedInsurancePool is ISingleSidedInsurancePool, ReentrancyGuard {
    using Counters for Counters.Counter;
    // It should be okay if Protocol is struct
    struct Protocol {
        uint256 coverDuration; // Duration of the protocol cover products
        uint256 mcr; // Maximum Capital Requirement Ratio of that protocol
        address protocolAddress; // Address of that protocol
        address protocolCurrency;
        string name; // protocol name
        string productType; // Type of product i.e. Wallet insurance, smart contract bug insurance, etc.
        string premiumDescription;
        address salesPolicy;
        bool exist; // initial true
    }

    address public premiumPool;
    address public owner;
    address public claimAssessor;
    address private exchangeAgent;
    address public migrateTo;

    uint256 public constant LOCK_TIME = 10 days;
    uint256 public constant ACC_UNO_PRECISION = 1e18;

    mapping(uint16 => Protocol) public getProtocol;
    Counters.Counter private protocolIds;

    address public rewarder;
    address public riskPool;
    struct PoolInfo {
        uint128 lastRewardBlock;
        uint128 accUnoPerShare;
        uint256 unoMultiplierPerBlock;
    }

    PoolInfo public poolInfo;
    mapping(address => uint256) private rewardDebt;
    // uint256 private totalAPRofPools;

    mapping(address => uint256) public lastWithdrawTime;

    event ProtocolCreated(address indexed _SSIP, uint16 _protocolIdx);
    event RiskPoolCreated(address indexed _SSIP, address indexed _pool);
    event StakedInPool(address indexed _staker, address indexed _pool, uint256 _amount);
    event LeftPool(address indexed _staker, address indexed _pool);
    event RewarderInitialize(address _rewarder, uint256 _amount);
    event LogUpdatePool(uint128 _lastRewardBlock, uint256 _lpSupply, uint256 _accUnoPerShare);
    event Harvest(address indexed _user, address indexed _receiver, uint256 _amount);
    event LogSetExchangeAgent(address indexed _exchangeAgent);
    event LogSetRewarder(address indexed _rewarder);
    event LogSetPremiumPool(address indexed _premiumPool);
    event LogSetProtocolMCR(uint16 _protocolIdx, uint256 _mcr);

    constructor(
        address _owner,
        address _claimAssessor,
        address _exchangeAgent,
        address _premiumPool
    ) {
        owner = _owner;
        exchangeAgent = _exchangeAgent;
        premiumPool = _premiumPool;
        claimAssessor = _claimAssessor;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    modifier onlyClaimAssessor() {
        require(msg.sender == claimAssessor, "UnoRe: Forbidden");
        _;
    }

    function allProtocolsLength() external view returns (uint256) {
        return protocolIds.current();
    }

    // TODO
    // check the case e.g protocol1's ExchangeAgent address is same to protocol2's ExchangeAgent
    // Need event emit
    function setExchangeAgent(address _exchangeAgent) external onlyOwner {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        exchangeAgent = _exchangeAgent;
        emit LogSetExchangeAgent(_exchangeAgent);
    }

    function setExchangeAgentInPolicy(uint16 _protocolIdx, address _exchangeAgent) external onlyOwner {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        address salesPolicy = getProtocol[_protocolIdx].salesPolicy;
        ISalesPolicy(salesPolicy).setExchangeAgent(_exchangeAgent);
    }

    function setRewardMultiplier(uint256 _rewardMultiplier) external onlyOwner {
        require(_rewardMultiplier > 0, "UnoRe: zero value");
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
    }

    function setRewarder(address _rewarder) external onlyOwner {
        require(_rewarder != address(0), "UnoRe: zero address");
        rewarder = _rewarder;
        emit LogSetRewarder(_rewarder);
    }

    // TODO: Need event
    function setPremiumPool(address _premiumPool) external onlyOwner {
        require(_premiumPool != address(0), "UnoRe: zero address");
        premiumPool = _premiumPool;
        emit LogSetPremiumPool(_premiumPool);
    }

    function setPremiumPoolInPolicy(uint16 _protocolIdx, address _premiumPool) external onlyOwner {
        require(_premiumPool != address(0), "UnoRe: zero address");
        address salesPolicy = getProtocol[_protocolIdx].salesPolicy;
        ISalesPolicy(salesPolicy).setPremiumPool(_premiumPool);
    }

    function setProtocolMCR(uint16 _protocolIdx, uint256 _mcr) external onlyOwner {
        require(_mcr > 0, "UnoRe: zero mcr");
        Protocol storage _protocol = getProtocol[_protocolIdx];
        _protocol.mcr = _mcr;
        emit LogSetProtocolMCR(_protocolIdx, _mcr);
    }

    function setProtocolURIInPolicy(uint16 _protocolIdx, string memory _uri) external onlyOwner {
        address salesPolicy = getProtocol[_protocolIdx].salesPolicy;
        ISalesPolicy(salesPolicy).setProtocolURI(_uri);
    }

    function setClaimAssessor(address _claimAssessor) external onlyOwner {
        require(_claimAssessor != address(0), "UnoRe: zero address");
        claimAssessor = _claimAssessor;
    }

    function setMigrateTo(address _migrateTo) external onlyOwner {
        require(_migrateTo != address(0), "UnoRe: zero address");
        migrateTo = _migrateTo;
    }

    function setMinLPCapital(uint256 _minLPCapital) external onlyOwner {
        require(_minLPCapital > 0, "UnoRe: not allow zero value");
        IRiskPool(riskPool).setMinLPCapital(_minLPCapital);
    }

    // This action can be done only by SSIP owner
    function addProtocol(
        string calldata _name,
        string calldata _productType,
        string calldata _premiumDescription,
        uint256 _coverDuration,
        address _protocolAddress,
        address _protocolCurrency,
        address salesPolicyFactory
    ) external onlyOwner {
        uint16 lastIdx = uint16(protocolIds.current());
        address currency = _protocolCurrency;
        address _salesPolicy = ISalesPolicyFactory(salesPolicyFactory).newSalesPolicy(lastIdx, exchangeAgent, premiumPool, "");

        getProtocol[lastIdx] = Protocol({
            name: _name,
            coverDuration: _coverDuration,
            mcr: 1,
            protocolAddress: _protocolAddress,
            protocolCurrency: currency,
            productType: _productType,
            premiumDescription: _premiumDescription,
            salesPolicy: _salesPolicy,
            exist: true
        });

        protocolIds.increment();
        emit ProtocolCreated(address(this), lastIdx);
    }

    /**
     * @dev create Risk pool with UNO from SSIP owner
     */
    function createRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _factory,
        address _currency,
        uint256 _rewardMultiplier
    ) external onlyOwner nonReentrant {
        require(riskPool == address(0), "UnoRe: risk pool created already");
        riskPool = IRiskPoolFactory(_factory).newRiskPool(_name, _symbol, address(this), _currency);
        poolInfo.lastRewardBlock = uint128(block.number);
        poolInfo.accUnoPerShare = 0;
        poolInfo.unoMultiplierPerBlock = _rewardMultiplier;
        emit RiskPoolCreated(address(this), riskPool);
    }

    function initialRewarder(address _rewarder, uint256 _amount) external onlyOwner nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        rewarder = _rewarder;
        address token = IRiskPool(riskPool).currency();
        TransferHelper.safeTransferFrom(token, msg.sender, rewarder, _amount);
        IRewarder(rewarder).initialRewardBalance(_amount);
        emit RewarderInitialize(rewarder, _amount);
    }

    function migrate(bool _isWithdraw) external nonReentrant {
        require(migrateTo != address(0), "UnoRe: zero address");
        updatePool();
        uint256 amount = IERC20(riskPool).balanceOf(msg.sender);
        if (amount > 0) {
            uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
            uint256 _pendingUno = accumulatedUno - rewardDebt[msg.sender];
            rewardDebt[msg.sender] = 0;
            if (rewarder != address(0)) {
                IRewarder(rewarder).onUnoReward(msg.sender, _pendingUno);
                emit Harvest(msg.sender, msg.sender, _pendingUno);
            }
        }
        bool isLocked = block.timestamp - lastWithdrawTime[msg.sender] > LOCK_TIME;
        IRiskPool(riskPool).migrateLP(msg.sender, migrateTo, _isWithdraw, isLocked);
        IMigration(migrateTo).onMigration(msg.sender, amount, "");
    }

    function pendingUno(address _to) external view returns (uint256 pending) {
        uint256 tokenSupply = IERC20(riskPool).totalSupply();
        uint128 accSushiPerShare = poolInfo.accUnoPerShare;
        if (block.number > poolInfo.lastRewardBlock && tokenSupply != 0) {
            uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
            uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
            accSushiPerShare = accSushiPerShare + uint128((unoReward * ACC_UNO_PRECISION) / tokenSupply);
        }
        uint256 userBalance = IERC20(riskPool).balanceOf(_to);
        pending = (userBalance * uint256(accSushiPerShare)) / ACC_UNO_PRECISION - rewardDebt[_to];
    }

    function updatePool() public override {
        if (block.number > poolInfo.lastRewardBlock) {
            uint256 tokenSupply = IERC20(riskPool).totalSupply();
            if (tokenSupply > 0) {
                uint256 blocks = block.number - uint256(poolInfo.lastRewardBlock);
                uint256 unoReward = blocks * poolInfo.unoMultiplierPerBlock;
                poolInfo.accUnoPerShare = poolInfo.accUnoPerShare + uint128(((unoReward * ACC_UNO_PRECISION) / tokenSupply));
            }
            poolInfo.lastRewardBlock = uint128(block.number);
            emit LogUpdatePool(poolInfo.lastRewardBlock, tokenSupply, poolInfo.accUnoPerShare);
        }
    }

    function enterInPool(address _from, uint256 _amount) external override nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        updatePool();
        address token = IRiskPool(riskPool).currency();
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        TransferHelper.safeTransferFrom(token, _from, riskPool, _amount);
        IRiskPool(riskPool).enter(_from, _amount);
        rewardDebt[_from] =
            rewardDebt[_from] +
            ((_amount * 1e18 * uint256(poolInfo.accUnoPerShare)) / lpPriceUno) /
            ACC_UNO_PRECISION;
        emit StakedInPool(_from, riskPool, _amount);
    }

    /**
     * @dev WR will be in pending for 10 days at least
     */
    function leaveFromPoolInPending(address _to, uint256 _amount) external override nonReentrant {
        require(_to == msg.sender, "UnoRe: Forbidden");
        // Withdraw desired amount from pool
        updatePool();
        uint256 amount = IERC20(riskPool).balanceOf(msg.sender);
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (uint256 pendingAmount, , ) = IRiskPool(riskPool).getWithdrawRequest(msg.sender);
        require(((amount - pendingAmount) * lpPriceUno) / 1e18 >= _amount, "UnoRe: withdraw amount overflow");
        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        uint256 _pendingUno = accumulatedUno - rewardDebt[msg.sender];
        rewardDebt[_to] =
            accumulatedUno -
            (((_amount * 1e18 * uint256(poolInfo.accUnoPerShare)) / lpPriceUno) / ACC_UNO_PRECISION);
        IRiskPool(riskPool).leaveFromPoolInPending(msg.sender, _amount);
        if (rewarder != address(0)) {
            IRewarder(rewarder).onUnoReward(_to, _pendingUno);
            emit Harvest(msg.sender, _to, _pendingUno);
        }

        lastWithdrawTime[msg.sender] = block.timestamp;

        emit LeftPool(msg.sender, riskPool);
    }

    /**
     * @dev user can submit claim again and receive his funds into his wallet after 10 days since last WR.
     */
    function leaveFromPending() external override nonReentrant {
        require(block.timestamp - lastWithdrawTime[msg.sender] >= LOCK_TIME, "UnoRe: Locked time");
        IRiskPool(riskPool).leaveFromPending(msg.sender);
        updatePool();
    }

    function harvest(address _to) external override nonReentrant {
        updatePool();
        uint256 amount = IERC20(riskPool).balanceOf(msg.sender);
        uint256 accumulatedUno = (amount * uint256(poolInfo.accUnoPerShare)) / ACC_UNO_PRECISION;
        uint256 _pendingUno = accumulatedUno - rewardDebt[msg.sender];

        // Effects
        rewardDebt[msg.sender] = accumulatedUno;

        if (rewarder != address(0) && _pendingUno != 0) {
            IRewarder(rewarder).onUnoReward(_to, _pendingUno);
        }

        emit Harvest(msg.sender, _to, _pendingUno);
    }

    function cancelWithdrawRequest() external nonReentrant {
        IRiskPool(riskPool).cancelWithrawRequest(msg.sender);
    }

    function policyClaim(address _to, uint256 _amount) external onlyClaimAssessor {
        require(_to != address(0), "UnoRe: zero address");
        require(_amount > 0, "UnoRe: zero amount");
        IRiskPool(riskPool).policyClaim(_to, _amount);
    }

    function getProtocolData(uint16 _protocolIdx)
        external
        view
        override
        returns (
            string memory protocolName,
            string memory productType,
            address protocolAddress
        )
    {
        return (getProtocol[_protocolIdx].name, getProtocol[_protocolIdx].productType, getProtocol[_protocolIdx].protocolAddress);
    }

    function getStakedAmountPerUser(address _to) external view returns (uint256 unoAmount, uint256 lpAmount) {
        lpAmount = IERC20(riskPool).balanceOf(_to);
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        unoAmount = (lpAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get withdraw request amount in pending per user in UNO
     */
    function getWithdrawRequestPerUser(address _user)
        external
        view
        returns (
            uint256 pendingAmount,
            uint256 pendingAmountInUno,
            uint256 originUnoAmount,
            uint256 requestTime
        )
    {
        uint256 lpPriceUno = IRiskPool(riskPool).lpPriceUno();
        (pendingAmount, requestTime, originUnoAmount) = IRiskPool(riskPool).getWithdrawRequest(_user);
        pendingAmountInUno = (pendingAmount * lpPriceUno) / 1e18;
    }

    /**
     * @dev get total withdraw request amount in pending for the risk pool in UNO
     */
    function getTotalWithdrawPendingAmount() external view returns (uint256) {
        return IRiskPool(riskPool).getTotalWithdrawRequestAmount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMigration {
    function onMigration(
        address who_,
        uint256 amount_,
        bytes memory data_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function withdrawPremium(
        address _currency,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function initialRewardBalance(uint256 amount) external;

    function onUnoReward(address to, uint256 unoAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function enter(address _from, uint256 _amount) external;

    function leaveFromPoolInPending(address _to, uint256 _amount) external;

    function leaveFromPending(address _to) external;

    function cancelWithrawRequest(address _to) external;

    function policyClaim(address _to, uint256 _amount) external;

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isWithdraw,
        bool _isLocked
    ) external;

    function setMinLPCapital(uint256 _minLPCapital) external;

    function currency() external view returns (address);

    function getTotalWithdrawRequestAmount() external view returns (uint256);

    function getWithdrawRequest(address _to)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function lpPriceUno() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPoolFactory {
    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _cohort,
        address _currency
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISalesPolicy {
    function setPremiumPool(address _premiumPool) external;

    function setExchangeAgent(address _exchangeAgent) external;

    function setProtocolURI(string memory newURI) external;

    function totalPremiumSoldInUNO() external view returns (uint256);

    function totalUtilizedAmount() external view returns (uint256);

    function allPoliciesLength() external view returns (uint256);

    function getPolicyIdx(uint256 _index) external view returns (uint256);

    function policyDetail(address _user)
        external
        view
        returns (
            uint256,
            uint64,
            uint64,
            uint64,
            uint64
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISalesPolicyFactory {
    function newSalesPolicy(
        uint16 _protocolIdx,
        address _exchangeAgent,
        address _premiumPool,
        string memory _protocolURI
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISingleSidedInsurancePool {
    function updatePool() external;

    function enterInPool(address _from, uint256 _amount) external;

    function leaveFromPoolInPending(address _to, uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function getProtocolData(uint16 _protocolIdx)
        external
        view
        returns (
            string memory protocolName,
            string memory productType,
            address protocolAddress
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}