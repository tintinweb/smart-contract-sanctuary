// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../Cohort.sol";
import "../interfaces/ICohortFactory.sol";

contract CohortFactory is ICohortFactory {
    address public actuary;

    constructor(address _actuary) {
        actuary = _actuary;
    }

    function newCohort(
        address _owner,
        string memory _name,
        address _claimAssessor,
        uint256 _cohortStartCapital,
        address _premiumFactory,
        address _premiumCurrency,
        uint256 _minPremium
    ) external override returns (address) {
        require(msg.sender == actuary, "Uno Re:Forbidden");
        Cohort _cohort = new Cohort(_owner, _name, _claimAssessor, _cohortStartCapital);

        _cohort.createPremiumPool(_premiumFactory, _premiumCurrency, _minPremium);
        return address(_cohort);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRiskPoolFactory.sol";
import "./interfaces/ICohort.sol";
import "./interfaces/IRiskPool.sol";
import "./interfaces/IPremiumPoolFactory.sol";
import "./interfaces/IPremiumPool.sol";
import "./libraries/TransferHelper.sol";

contract Cohort is ICohort, ReentrancyGuard {
    // It should be okay if Protocol is struct
    struct Protocol {
        uint256 coverDuration; // Duration of the protocol cover products
        address protocolAddress; // Address of that protocol
        string name; // protocol name
        string productType; // Type of product i.e. Wallet insurance, smart contract bug insurance, etc.
        string premiumDescription;
        uint16 avgLR; // LR means Loss Ratio, default 1000 = 1
        bool exist; // initial true
    }

    address public factory;
    address public claimAssessor;
    address public premiumPool;
    address public owner;
    string public name;
    // uint public TVLc;
    // uint public combinedRisk;
    uint256 public duration;
    // uint8 public status;
    uint256 public cohortActiveFrom;

    // for now we set this as constant
    uint256 public immutable COHORT_START_CAPITAL;

    mapping(uint16 => Protocol) public getProtocol;
    uint16[] private allProtocols;

    mapping(uint8 => address) public getRiskPool;
    uint8[] private allRiskPools;

    // pool => amount => pool capital
    mapping(address => uint256) private poolCapital;
    uint256 private totalAPRofPools;
    uint256 private MAX_INTEGER = type(uint256).max;

    event ProtocolCreated(address indexed _cohort, uint16 _protocolIdx);
    event PremiumDeposited(address indexed _cohort, uint16 _protocolIdx, uint256 _amount);
    event RiskPoolCreated(address indexed _cohort, address indexed _pool);
    event StakedInPool(address indexed _staker, address indexed pool, uint256 _amount);
    event LeftPool(address indexed _staker, address indexed _pool);
    event ClaimPaid(address indexed _claimer, uint256 _protocolIdx, uint256 _amount);

    constructor(
        address _owner,
        string memory _name,
        address _claimAssessor,
        uint256 _cohortStartCapital
    ) {
        owner = _owner;
        name = _name;
        COHORT_START_CAPITAL = _cohortStartCapital;
        claimAssessor = _claimAssessor;
        factory = msg.sender;
    }

    modifier onlyCohortOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    function allProtocolsLength() external view returns (uint256) {
        return allProtocols.length;
    }

    function allRiskPoolLength() external view returns (uint256) {
        return allRiskPools.length;
    }

    /**
     * @dev We separated createPremiumPool from constructor to keep light constructor
     */
    function createPremiumPool(
        address _factory,
        address _currency,
        uint256 _minimum
    ) external {
        require(msg.sender == factory, "UnoRe: Forbidden");
        premiumPool = IPremiumPoolFactory(_factory).newPremiumPool(_currency, _minimum);
    }

    // This action can be done only by cohort owner
    function addProtocol(
        string calldata _name,
        address _protocolAddress,
        string calldata _productType,
        string calldata _premiumDescription,
        uint256 _coverDuration
    ) external onlyCohortOwner {
        uint16 lastIdx = allProtocols.length > 0 ? allProtocols[allProtocols.length - 1] + 1 : 0;
        allProtocols.push(lastIdx);
        getProtocol[lastIdx] = Protocol({
            coverDuration: _coverDuration,
            protocolAddress: _protocolAddress,
            name: _name,
            productType: _productType,
            premiumDescription: _premiumDescription,
            avgLR: 1000, //
            exist: true
        });

        if (duration < _coverDuration) {
            duration = _coverDuration;
        }
        emit ProtocolCreated(address(this), lastIdx);
    }

    /**
     * @dev create Risk pool from cohort owner
     */
    function createRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _factory,
        address _currency,
        uint256 _APR,
        uint256 _maxSize
    ) external onlyCohortOwner returns (address pool) {
        uint256 len = allRiskPools.length;
        pool = IRiskPoolFactory(_factory).newRiskPool(_name, _symbol, address(this), _currency, _APR, _maxSize);

        uint8 lastIdx = len > 0 ? allRiskPools[len - 1] + 1 : 0;
        allRiskPools.push(lastIdx);
        getRiskPool[lastIdx] = pool;
        totalAPRofPools += _APR;
        poolCapital[pool] = MAX_INTEGER;
        emit RiskPoolCreated(address(this), pool);
    }

    function depositPremium(uint16 _protocolIdx, uint256 _amount) external nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        TransferHelper.safeTransferFrom(IPremiumPool(premiumPool).currency(), msg.sender, premiumPool, _amount);
        IPremiumPool(premiumPool).depositPremium(_protocolIdx, _amount);
        emit PremiumDeposited(address(this), _protocolIdx, _amount);
    }

    function enterInPool(
        address _from,
        address _pool,
        uint256 _amount
    ) external nonReentrant {
        require(cohortActiveFrom == 0, "UnoRe: Staking was Ended");
        require(poolCapital[_pool] == MAX_INTEGER || poolCapital[_pool] != 0, "UnoRe: RiskPool not exist");
        require(_amount != 0, "UnoRe: ZERO Value");
        uint256 _poolMaxSize = IRiskPool(_pool).maxSize();
        uint256 _currentSupply = IERC20(_pool).totalSupply(); // It's Okay using totalSupply here, because there's no withdrawl during staking.
        require(_poolMaxSize >= (_amount + _currentSupply), "UnoRe: RiskPool overflow");
        address token = IRiskPool(_pool).currency();
        TransferHelper.safeTransferFrom(token, _from, _pool, _amount);
        IRiskPool(_pool).enter(_from, _amount);
        poolCapital[_pool] == MAX_INTEGER ? poolCapital[_pool] = _amount : poolCapital[_pool] += _amount;
        _startCohort();

        emit StakedInPool(_from, _pool, _amount);
    }

    /**
     * @dev for now we assume protocols send premium to cohort smart contract
     */
    function leaveFromPool(address _to, address _pool) external nonReentrant {
        require(cohortActiveFrom != 0 && block.timestamp - cohortActiveFrom > duration, "UnoRe: Forbidden");
        require(poolCapital[_pool] != 0 && poolCapital[_pool] != MAX_INTEGER, "UnoRe: RiskPool not exist or empty");
        // Withdraw remaining from pool
        uint256 amount = IERC20(_pool).balanceOf(_to);
        require(amount != 0, "UnoRe: ZERO Value");
        // get premium rewards
        /**
         * @dev It's okay using for loop here, because the max length of pools is 3 at the moment
         */
        for (uint256 ii = 0; ii < allProtocols.length; ii++) {
            uint16 protocolIdx = allProtocols[ii];
            IPremiumPool(premiumPool).setPremiumReward(protocolIdx);
            uint256 _pr = premiumReward(_to, _pool, protocolIdx);
            IPremiumPool(premiumPool).withdrawPremium(_to, protocolIdx, _pr);
        }

        IRiskPool(_pool).leave(_to);
        emit LeftPool(_to, _pool);
    }

    /**
     * @dev This function shows the premium reward which user can get.
     * It can be changed in staking and coverage duration, but should be fixed value after coverage.
     */
    function premiumReward(
        address _account,
        address _riskPool,
        uint16 _protocolIdx
    ) public view returns (uint256) {
        if (poolCapital[_riskPool] == 0 || poolCapital[_riskPool] == MAX_INTEGER || totalAPRofPools == 0) {
            return 0;
        }
        uint256 _totalPr = IPremiumPool(premiumPool).premiumRewardOf(_protocolIdx);
        uint256 amount = IERC20(_riskPool).balanceOf(_account);
        uint256 denominator = poolCapital[_riskPool] * totalAPRofPools;
        uint256 numerator = _totalPr * amount * IRiskPool(_riskPool).APR();
        return numerator / denominator;
    }

    /**
     * @dev for now all premiums and risk pools are paid in stable coin
     * @dev we can trust claim request from ClaimAssesor
     */
    function requestClaim(
        address _from,
        uint16 _protocolIdx,
        uint256 _amount
    ) external override nonReentrant {
        require(msg.sender == claimAssessor, "UnoRe: Forbidden");
        require(_amount != 0, "UnoRe: ZERO Value");
        require(block.timestamp - cohortActiveFrom <= duration && cohortActiveFrom != 0, "UnoRe: Forbidden");
        (bool hasEnough, uint256 minPremium) = hasEnoughCapital(_protocolIdx, _amount);
        require(hasEnough == true, "UnoRe: Capital is not enough");

        uint256 currentPremium = IPremiumPool(premiumPool).balanceOf(_protocolIdx);
        /** We should remain minimum amount in premium pool
         * Uno Res reinsurance mechanism works in the following manner.
         * There is a premium pool, into which all the premium collected from various protocols is held.
         * At the end of the policy period, the premium is distributed to the 3 risk pools in accordance with the rewards distribution formula.
         *
         * The claims payout, is first done from the premium pool,
         * after it's exhaustion the risk pool 1 is used then risk pool 2 and so on.
         *
         * There is a need of a minimum reserve premium to account for case scenarios
         * where claims are incurred and premium pool and risk pool 1 is completely exhausted.
         * The min premium reserve will be used to allocate rewards to all the pools (risk pool 1, risk pool 2, risk pool 3, etc.. )
         */
        if (_amount + minPremium <= currentPremium) {
            IPremiumPool(premiumPool).withdrawPremium(_from, _protocolIdx, _amount);
            emit ClaimPaid(_from, _protocolIdx, _amount);
            return;
        }
        if (currentPremium > minPremium) {
            // Tranfer from premium
            uint256 _paid = currentPremium - minPremium;
            IPremiumPool(premiumPool).withdrawPremium(_from, _protocolIdx, _paid);
            _amount -= _paid;
        }
        /**
         * @dev It's okay using for loop here, because the max length of pools is 3 at the moment
         */
        for (uint256 ii = 0; ii < allRiskPools.length; ii++) {
            if (_amount == 0) break;
            address _pool = getRiskPool[allRiskPools[ii]];
            address _token = IRiskPool(_pool).currency();
            uint256 _poolCapital = IERC20(_token).balanceOf(_pool);
            if (_amount <= _poolCapital) {
                _requestClaimToPool(_from, _amount, _pool);
                _amount = 0;
            } else {
                _requestClaimToPool(_from, _poolCapital, _pool);
                _amount -= _poolCapital;
            }
        }
        emit ClaimPaid(_from, _protocolIdx, _amount);
    }

    function _startCohort() private {
        uint256 totalCapital = 0;
        for (uint256 ii = 0; ii < allRiskPools.length; ii++) {
            address pool = getRiskPool[allRiskPools[ii]];
            // for now we use total supply cause we deal only Stable coins
            totalCapital += IERC20(pool).totalSupply();
        }
        if (totalCapital >= COHORT_START_CAPITAL) {
            cohortActiveFrom = block.timestamp;
        }
    }

    function hasEnoughCapital(uint16 _protocolIdx, uint256 _amount) private returns (bool hasEnough, uint256 minPremium) {
        uint256 totalCapital = IPremiumPool(premiumPool).balanceOf(_protocolIdx);
        uint256 len = allRiskPools.length;
        bool isLastPool = true;
        for (uint256 ii = 0; ii < len; ii++) {
            address pool = getRiskPool[allRiskPools[ii]];
            // for now we use total supply cause we deal only stable coins
            uint256 _ts = IERC20(pool).totalSupply();
            totalCapital += _ts;
            if (isLastPool && _ts != 0 && ii != len - 1) {
                isLastPool = false;
            }
        }
        minPremium = isLastPool ? 0 : IPremiumPool(premiumPool).minimumPremium();
        hasEnough = totalCapital >= (_amount + minPremium);
    }

    /**
     * @dev to save gas fee, we need this function
     */
    function _requestClaimToPool(
        address _from,
        uint256 _amount,
        address _pool
    ) private {
        IRiskPool(_pool).requestClaim(_from, _amount);
    }

    function setDuration(uint256 _duration) external onlyCohortOwner {
        duration = _duration;
    }

    function changePoolPriority(uint8 _prio1, uint8 _prio2) external onlyCohortOwner {
        address _temp = getRiskPool[allRiskPools[_prio1]];
        getRiskPool[_prio1] = getRiskPool[allRiskPools[_prio2]];
        getRiskPool[_prio2] = _temp;
    }

    function totalPremiumReward(address _account, address _riskPool) external view returns (uint256) {
        uint256 pr = 0;
        for (uint256 ii = 0; ii < allProtocols.length; ii++) {
            uint16 protocolIdx = allProtocols[ii];
            pr += premiumReward(_account, _riskPool, protocolIdx);
        }
        return pr;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ICohortFactory {
    function newCohort(
        address _owner,
        string memory _name,
        address _claimAssessor,
        uint256 _cohortStartCapital,
        address _premiumFactory,
        address _premiumCurrency,
        uint256 _minPremium
    ) external returns (address);
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

    constructor () {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPoolFactory {
    function newRiskPool(
        string calldata _name,
        string calldata _symbol,
        address _cohort,
        address _currency,
        uint256 _APR,
        uint256 _maxSize
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ICohort {
    function requestClaim(
        address _from,
        uint16 _protocolIdx,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRiskPool {
    function enter(address _from, uint256 _amount) external;

    function leave(address _to) external;

    function requestClaim(address _from, uint256 _amount) external;

    function currency() external view returns (address);

    function APR() external view returns (uint256);

    function maxSize() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPoolFactory {
    function newPremiumPool(address _currency, uint256 _minimum) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IPremiumPool {
    function depositPremium(uint16 _protocolIdx, uint256 _amount) external;

    function withdrawPremium(
        address _to,
        uint16 _protocolIdx,
        uint256 _amount
    ) external;

    function transferAsset(
        uint16 _protocolIdx,
        address _to,
        uint256 _amount
    ) external;

    function minimumPremium() external returns (uint256);

    function balanceOf(uint16 _protocolIdx) external view returns (uint256);

    function premiumRewardOf(uint16 _protocolIdx) external view returns (uint256);

    function currency() external view returns (address);

    function setPremiumReward(uint16 _protocolIdx) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
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

