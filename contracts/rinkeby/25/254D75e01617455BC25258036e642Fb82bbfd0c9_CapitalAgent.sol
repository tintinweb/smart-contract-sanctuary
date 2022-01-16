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

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISalesPolicy.sol";
import "./interfaces/IExchangeAgent.sol";
import "./interfaces/ISingleSidedInsurancePool.sol";
import "./interfaces/IRiskPool.sol";
import "./interfaces/ICapitalAgent.sol";

contract CapitalAgent is ICapitalAgent, ReentrancyGuard {
    address public owner;
    address public exchangeAgent;
    address public salesPolicyFactory;
    address public UNO_TOKEN;
    address public USDC_TOKEN;

    struct PoolInfo {
        uint256 totalCapital;
        bool exist;
    }

    struct PolicyInfo {
        address policy;
        uint256 utilizedAmount;
        bool exist;
    }

    mapping(address => PoolInfo) public poolInfo;

    uint256 public totalCapitalStaked;

    PolicyInfo public policyInfo;

    uint256 public totalUtilizedAmount;

    uint256 public MCR;
    uint256 public MLR;

    uint256 public CALC_PRECISION = 1e18;

    mapping(address => bool) public poolWhiteList;

    event LogAddPool(address indexed _ssip);
    event LogRemovePool(address indexed _ssip);
    event LogSetPolicy(address indexed _salesPolicy);
    event LogRemovePolicy(address indexed _salesPolicy);
    event LogUpdatePoolCapital(address indexed _ssip, uint256 _poolCapital, uint256 _totalCapital);
    event LogUpdatePolicyCoverage(
        address indexed _policy,
        uint256 _amount,
        uint256 _policyUtilized,
        uint256 _totalUtilizedAmount
    );
    event LogUpdatePolicyExpired(address indexed _policy, uint256 _policyTokenId);
    event LogMarkToClaimPolicy(address indexed _policy, uint256 _policyTokenId);
    event LogSetMCR(address indexed _owner, address indexed _capitalAgent, uint256 _MCR);
    event LogSetMLR(address indexed _owner, address indexed _capitalAgent, uint256 _MLR);
    event LogSetExchangeAgent(address indexed _owner, address indexed _capitalAgent, address _exchangeAgent);
    event LogSetSalesPolicyFactory(address indexed _factory);
    event LogAddPoolWhiteList(address indexed _pool);
    event LogRemovePoolWhiteList(address indexed _pool);

    constructor(
        address _exchangeAgent,
        address _UNO_TOKEN,
        address _USDC_TOKEN
    ) {
        require(_exchangeAgent != address(0), "UnoRe: zero exchangeAgent address");
        require(_UNO_TOKEN != address(0), "UnoRe: zero UNO address");
        require(_USDC_TOKEN != address(0), "UnoRe: zero USDC address");
        owner = msg.sender;
        exchangeAgent = _exchangeAgent;
        UNO_TOKEN = _UNO_TOKEN;
        USDC_TOKEN = _USDC_TOKEN;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "UnoRe: Capital Agent Forbidden");
        _;
    }

    modifier onlyPoolWhiteList() {
        require(poolWhiteList[msg.sender], "UnoRe: Capital Agent Forbidden");
        _;
    }

    function setSalesPolicyFactory(address _factory) external onlyOwner nonReentrant {
        require(_factory != address(0), "UnoRe: zero factory address");
        salesPolicyFactory = _factory;
        emit LogSetSalesPolicyFactory(_factory);
    }

    function addPoolWhiteList(address _pool) external onlyOwner nonReentrant {
        require(_pool != address(0), "UnoRe: zero pool address");
        require(!poolWhiteList[_pool], "UnoRe: white list already");
        poolWhiteList[_pool] = true;
        emit LogAddPoolWhiteList(_pool);
    }

    function removePoolWhiteList(address _pool) external onlyOwner nonReentrant {
        require(_pool != address(0), "UnoRe: zero pool address");
        require(poolWhiteList[_pool], "UnoRe: no white list");
        poolWhiteList[_pool] = false;
        emit LogRemovePoolWhiteList(_pool);
    }

    function addPool(address _ssip) external override onlyPoolWhiteList {
        require(_ssip != address(0), "UnoRe: zero address");
        require(!poolInfo[_ssip].exist, "UnoRe: already exist pool");
        poolInfo[_ssip] = PoolInfo({totalCapital: 0, exist: true});

        emit LogAddPool(_ssip);
    }

    function removePool(address _ssip) external onlyOwner nonReentrant {
        require(_ssip != address(0), "UnoRe: zero address");
        require(poolInfo[_ssip].exist, "UnoRe: no exit pool");
        if (poolInfo[_ssip].totalCapital > 0) {
            totalCapitalStaked = totalCapitalStaked - poolInfo[_ssip].totalCapital;
        }
        delete poolInfo[_ssip];
        emit LogRemovePool(_ssip);
    }

    function setPolicy(address _policy) external override nonReentrant {
        require(salesPolicyFactory != address(0), "UnoRe: not set factory address yet");
        require(salesPolicyFactory == msg.sender, "UnoRe: only salesPolicyFactory can call");
        policyInfo = PolicyInfo({policy: _policy, utilizedAmount: 0, exist: true});

        emit LogSetPolicy(_policy);
    }

    function removePolicy() external onlyOwner nonReentrant {
        require(policyInfo.exist, "UnoRe: no exit pool");
        if (policyInfo.utilizedAmount > 0) {
            totalCapitalStaked = totalUtilizedAmount - policyInfo.utilizedAmount;
        }
        address _policy = policyInfo.policy;
        policyInfo.policy = address(0);
        policyInfo.exist = false;
        policyInfo.utilizedAmount = 0;
        emit LogRemovePolicy(_policy);
    }

    function SSIPWithdraw(uint256 _withdrawAmount) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        require(_checkCapitalByMCR(_withdrawAmount), "UnoRe: minimum capital underflow");
        _updatePoolCapital(msg.sender, _withdrawAmount, false);
    }

    function SSIPPolicyCaim(uint256 _withdrawAmount) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        _updatePoolCapital(msg.sender, _withdrawAmount, false);
    }

    function SSIPStaking(uint256 _stakingAmount) external override nonReentrant {
        require(poolInfo[msg.sender].exist, "UnoRe: no exist ssip");
        _updatePoolCapital(msg.sender, _stakingAmount, true);
    }

    function checkCapitalByMCR(uint256 _withdrawAmount) external view override returns (bool) {
        return _checkCapitalByMCR(_withdrawAmount);
    }

    function checkCoverageByMLR(uint256 _coverageAmount) external view override returns (bool) {
        return _checkCoverageByMLR(_coverageAmount);
    }

    function policySale(uint256 _coverageAmount) external override nonReentrant {
        require(msg.sender == policyInfo.policy, "UnoRe: only salesPolicy can call");
        require(policyInfo.exist, "UnoRe: no exist policy");
        require(_checkCoverageByMLR(_coverageAmount), "UnoRe: maximum leverage overflow");
        _updatePolicyCoverage(_coverageAmount, true);
    }

    function updatePolicyStatus(uint256 _policyId) external override nonReentrant {
        require(policyInfo.policy != address(0), "UnoRe: no exist salesPolicy");
        (uint256 _coverageAmount, uint256 _coverageDuration, uint256 _coverStartAt) = ISalesPolicy(policyInfo.policy)
            .getPolicyData(_policyId);
        bool isExpired = block.timestamp >= _coverageDuration + _coverStartAt;
        if (isExpired) {
            _updatePolicyCoverage(_coverageAmount, false);
            ISalesPolicy(policyInfo.policy).updatePolicyExpired(_policyId);
            emit LogUpdatePolicyExpired(policyInfo.policy, _policyId);
        }
    }

    function markToClaimPolicy(uint256 _policyId) external onlyOwner nonReentrant {
        require(policyInfo.policy != address(0), "UnoRe: no exist salesPolicy");
        (uint256 _coverageAmount, , ) = ISalesPolicy(policyInfo.policy).getPolicyData(_policyId);
        _updatePolicyCoverage(_coverageAmount, false);
        ISalesPolicy(policyInfo.policy).markToClaim(_policyId);
        emit LogMarkToClaimPolicy(policyInfo.policy, _policyId);
    }

    function _updatePoolCapital(
        address _pool,
        uint256 _amount,
        bool isAdd
    ) private {
        if (!isAdd) {
            require(poolInfo[_pool].totalCapital >= _amount, "UnoRe: pool capital overflow");
        }
        poolInfo[_pool].totalCapital = isAdd ? poolInfo[_pool].totalCapital + _amount : poolInfo[_pool].totalCapital - _amount;
        totalCapitalStaked = isAdd ? totalCapitalStaked + _amount : totalCapitalStaked - _amount;
        emit LogUpdatePoolCapital(_pool, poolInfo[_pool].totalCapital, totalCapitalStaked);
    }

    function _updatePolicyCoverage(uint256 _amount, bool isAdd) private {
        if (!isAdd) {
            require(policyInfo.utilizedAmount >= _amount, "UnoRe: policy coverage overflow");
        }
        policyInfo.utilizedAmount = isAdd ? policyInfo.utilizedAmount + _amount : policyInfo.utilizedAmount - _amount;
        totalUtilizedAmount = isAdd ? totalUtilizedAmount + _amount : totalUtilizedAmount - _amount;
        emit LogUpdatePolicyCoverage(policyInfo.policy, _amount, policyInfo.utilizedAmount, totalUtilizedAmount);
    }

    function _checkCapitalByMCR(uint256 _withdrawAmount) private view returns (bool) {
        return totalCapitalStaked - _withdrawAmount >= (totalCapitalStaked * MCR) / CALC_PRECISION;
    }

    function _checkCoverageByMLR(uint256 _newCoverageAmount) private view returns (bool) {
        uint256 totalCapitalStakedInUSDC = IExchangeAgent(exchangeAgent).getNeededTokenAmount(
            UNO_TOKEN,
            USDC_TOKEN,
            totalCapitalStaked
        );
        return totalUtilizedAmount + _newCoverageAmount <= (totalCapitalStakedInUSDC * MLR) / CALC_PRECISION;
    }

    function setMCR(uint256 _MCR) external onlyOwner nonReentrant {
        require(_MCR > 0, "UnoRe: zero mcr");
        MCR = _MCR;
        emit LogSetMCR(msg.sender, address(this), _MCR);
    }

    function setMLR(uint256 _MLR) external onlyOwner nonReentrant {
        require(_MLR > 0, "UnoRe: zero mlr");
        MLR = _MLR;
        emit LogSetMLR(msg.sender, address(this), _MLR);
    }

    function setExchangeAgent(address _exchangeAgent) external onlyOwner nonReentrant {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        exchangeAgent = _exchangeAgent;
        emit LogSetExchangeAgent(msg.sender, address(this), _exchangeAgent);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ICapitalAgent {
    function addPool(address _ssip) external;

    function setPolicy(address _policy) external;

    function SSIPWithdraw(uint256 _withdrawAmount) external;

    function SSIPStaking(uint256 _stakingAmount) external;

    function SSIPPolicyCaim(uint256 _withdrawAmount) external;

    function checkCapitalByMCR(uint256 _withdrawAmount) external view returns (bool);

    function checkCoverageByMLR(uint256 _coverageAmount) external view returns (bool);

    function policySale(uint256 _coverageAmount) external;

    function updatePolicyStatus(uint256 _policyId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDC_TOKEN() external view returns (address);

    function getTokenAmountForUSDC(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDC(uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForToken(address _token, uint256 _tokenAmount) external view returns (uint256);

    function getNeededTokenAmount(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external view returns (uint256);

    function convertForToken(
        address _token0,
        address _token1,
        uint256 _token0Amount
    ) external returns (uint256);

    function convertForETH(address _token, uint256 _convertAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function enter(address _from, uint256 _amount) external;

    function leaveFromPoolInPending(address _to, uint256 _amount) external;

    function leaveFromPending(address _to) external returns (uint256, uint256);

    function cancelWithrawRequest(address _to) external returns (uint256, uint256);

    function policyClaim(address _to, uint256 _amount) external returns (uint256 realClaimAmount);

    function migrateLP(
        address _to,
        address _migrateTo,
        bool _isUnLocked
    ) external returns (uint256);

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

interface ISalesPolicy {
    function setPremiumPool(address _premiumPool) external;

    function setExchangeAgent(address _exchangeAgent) external;

    function setCapitalAgent(address _capitalAgent) external;

    function setBuyPolicyMaxDeadline(uint256 _maxDeadline) external;

    function approvePremium(address _premiumCurrency) external;

    function setProtocolURI(string memory newURI) external;

    function setSigner(address _signer) external;

    function updatePolicyExpired(uint256 _policyId) external;

    function markToClaim(uint256 _policyId) external;

    function allPoliciesLength() external view returns (uint256);

    function getPolicyData(uint256 _policyId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISingleSidedInsurancePool {
    function updatePool() external;

    function enterInPool(uint256 _amount) external;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;

    function lpTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function riskPool() external view returns (address);
}