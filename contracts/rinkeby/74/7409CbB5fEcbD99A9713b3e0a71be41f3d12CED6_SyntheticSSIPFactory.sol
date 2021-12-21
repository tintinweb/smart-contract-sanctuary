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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMigration.sol";
import "./interfaces/IRewarderFactory.sol";
import "./interfaces/ISyntheticSSIP.sol";
import "./interfaces/IRewarder.sol";
import "./interfaces/IExchangeAgent.sol";
import "./libraries/TransferHelper.sol";

contract SyntheticSSIP is ISyntheticSSIP, ReentrancyGuard {
    address public owner;
    address private exchangeAgent;
    address public migrateTo;
    address public immutable UNO_TOKEN;

    uint256 public constant LOCK_TIME = 10 days;
    uint256 public constant ACC_UNO_PRECISION = 1e18;

    address public rewarder;
    address public lpToken;

    uint256 lastRewardBlock;
    uint256 accUnoPerShare;
    uint256 unoPerBlock;

    struct UserInfo {
        uint256 lastWithdrawTime;
        uint256 rewardDebt;
        uint256 amount;
        uint256 pendingWithdrawAmount;
    }

    mapping(address => UserInfo) public userInfo;

    uint256 public totalStakedLPAmount;
    uint256 public totalWithdrawPending;

    event LogStakedInPool(address indexed _staker, address indexed _pool, uint256 _amount);
    event LogLeftPool(address indexed _staker, address indexed _pool, uint256 _requestAmount);
    event LogLeaveFromPending(address indexed _user, address indexed _pool, uint256 _withdrawAmount);
    event LogUpdatePool(uint256 _lastRewardBlock, uint256 _lpSupply, uint256 _accUnoPerShare);
    event LogHarvest(address indexed _user, address indexed _receiver, uint256 _amount);
    event LogSetExchangeAgent(address indexed _exchangeAgent);
    event LogCancelWithdrawRequest(address indexed _user, address indexed _pool, uint256 _cancelAmount);
    event LogCreateRewarder(address indexed _SSIP, address indexed _rewarder, address _currency);

    constructor(
        address _owner,
        address _exchangeAgent,
        address _lpToken,
        address _UNO_TOKEN
    ) {
        owner = _owner;
        exchangeAgent = _exchangeAgent;
        lpToken = _lpToken;
        UNO_TOKEN = _UNO_TOKEN;
        unoPerBlock = 1e18;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    function setExchangeAgent(address _exchangeAgent) external onlyOwner {
        require(_exchangeAgent != address(0), "UnoRe: zero address");
        exchangeAgent = _exchangeAgent;
        emit LogSetExchangeAgent(_exchangeAgent);
    }

    function setUnoPerBlock(uint256 _unoPerBlock) external onlyOwner {
        require(_unoPerBlock > 0, "UnoRe: zero value");
        unoPerBlock = _unoPerBlock;
    }

    function setMigrateTo(address _migrateTo) external onlyOwner {
        require(_migrateTo != address(0), "UnoRe: zero address");
        migrateTo = _migrateTo;
    }

    function createRewarder(
        address _operator,
        address _factory,
        address _currency
    ) external onlyOwner nonReentrant {
        require(_factory != address(0), "UnoRe: rewarder factory no exist");
        rewarder = IRewarderFactory(_factory).newRewarder(_operator, _currency, address(this));
        emit LogCreateRewarder(address(this), rewarder, _currency);
    }

    function migrate() external nonReentrant {
        require(migrateTo != address(0), "UnoRe: zero address");
        _harvest(msg.sender);
        if (
            userInfo[msg.sender].pendingWithdrawAmount > 0 && block.timestamp - userInfo[msg.sender].lastWithdrawTime >= LOCK_TIME
        ) {
            _leaveFromPending();
        } else {
            _cancelWithdrawRequest();
        }
        uint256 amount = userInfo[msg.sender].amount;
        IMigration(migrateTo).onMigration(msg.sender, amount, "");
        userInfo[msg.sender].amount = 0;
    }

    function pendingUno(address _to) external view returns (uint256 pending) {
        uint256 currentAccUnoPerShare = accUnoPerShare;
        if (block.number > lastRewardBlock && totalStakedLPAmount != 0) {
            uint256 blocks = block.number - lastRewardBlock;
            uint256 unoReward = blocks * unoPerBlock;
            currentAccUnoPerShare = accUnoPerShare + (unoReward * ACC_UNO_PRECISION) / totalStakedLPAmount;
        }
        uint256 userBalance = userInfo[_to].amount;
        pending = (userBalance * currentAccUnoPerShare) / ACC_UNO_PRECISION - userInfo[_to].rewardDebt;
    }

    function updatePool() public override {
        if (block.number > lastRewardBlock) {
            if (totalStakedLPAmount > 0) {
                uint256 blocks = block.number - lastRewardBlock;
                uint256 unoReward = blocks * unoPerBlock;
                accUnoPerShare = accUnoPerShare + ((unoReward * ACC_UNO_PRECISION) / totalStakedLPAmount);
            }
            lastRewardBlock = block.number;
            emit LogUpdatePool(lastRewardBlock, totalStakedLPAmount, accUnoPerShare);
        }
    }

    function enterInPool(uint256 _amount) external override nonReentrant {
        require(_amount != 0, "UnoRe: ZERO Value");
        updatePool();
        TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), _amount);
        userInfo[msg.sender].rewardDebt = userInfo[msg.sender].rewardDebt + (_amount * accUnoPerShare) / ACC_UNO_PRECISION;
        userInfo[msg.sender].amount = userInfo[msg.sender].amount + _amount;
        totalStakedLPAmount = totalStakedLPAmount + _amount;
        emit LogStakedInPool(msg.sender, address(this), _amount);
    }

    /**
     * @dev WR will be in pending for 10 days at least
     */
    function leaveFromPoolInPending(uint256 _amount) external override nonReentrant {
        // Withdraw desired amount from pool
        _harvest(msg.sender);
        uint256 amount = userInfo[msg.sender].amount;
        uint256 pendingWR = userInfo[msg.sender].pendingWithdrawAmount;
        require(amount - pendingWR >= _amount, "UnoRe: withdraw amount overflow");
        userInfo[msg.sender].pendingWithdrawAmount = userInfo[msg.sender].pendingWithdrawAmount + _amount;
        userInfo[msg.sender].lastWithdrawTime = block.timestamp;

        totalWithdrawPending = totalWithdrawPending + _amount;

        emit LogLeftPool(msg.sender, address(this), _amount);
    }

    /**
     * @dev user can submit claim again and receive his funds into his wallet after 10 days since last WR.
     */
    function leaveFromPending() external override nonReentrant {
        require(block.timestamp - userInfo[msg.sender].lastWithdrawTime >= LOCK_TIME, "UnoRe: Locked time");
        _harvest(msg.sender);
        _leaveFromPending();
    }

    function _leaveFromPending() private {
        uint256 amount = userInfo[msg.sender].amount;
        uint256 pendingWR = userInfo[msg.sender].pendingWithdrawAmount;
        uint256 accumulatedUno = (amount * accUnoPerShare) / ACC_UNO_PRECISION;

        TransferHelper.safeTransfer(lpToken, msg.sender, pendingWR);

        userInfo[msg.sender].rewardDebt = accumulatedUno - ((pendingWR * accUnoPerShare) / ACC_UNO_PRECISION);
        userInfo[msg.sender].amount = amount - pendingWR;
        userInfo[msg.sender].pendingWithdrawAmount = 0;
        totalWithdrawPending = totalWithdrawPending - pendingWR;
        totalStakedLPAmount = totalStakedLPAmount - pendingWR;
        emit LogLeaveFromPending(msg.sender, address(this), pendingWR);
    }

    function harvest(address _to) external override nonReentrant {
        _harvest(_to);
    }

    function _harvest(address _to) private {
        updatePool();
        uint256 amount = userInfo[_to].amount;
        uint256 accumulatedUno = (amount * accUnoPerShare) / ACC_UNO_PRECISION;
        uint256 _pendingUno = accumulatedUno - userInfo[_to].rewardDebt;

        // Effects
        userInfo[msg.sender].rewardDebt = accumulatedUno;

        uint256 expectedRewardAmount = 0;
        uint256 realRewardAmount = 0;
        address rewardCurrency = IRewarder(rewarder).currency();
        if (rewardCurrency == address(0)) {
            expectedRewardAmount = IExchangeAgent(exchangeAgent).getETHAmountForToken(UNO_TOKEN, _pendingUno);
        } else {
            expectedRewardAmount = IExchangeAgent(exchangeAgent).getNeededTokenAmount(UNO_TOKEN, rewardCurrency, _pendingUno);
        }
        if (rewarder != address(0) && _pendingUno > 0) {
            realRewardAmount = IRewarder(rewarder).onReward(_to, expectedRewardAmount);
        }

        emit LogHarvest(msg.sender, _to, realRewardAmount);
    }

    function cancelWithdrawRequest() external nonReentrant {
        _cancelWithdrawRequest();
    }

    function _cancelWithdrawRequest() private {
        uint256 pendingWR = userInfo[msg.sender].pendingWithdrawAmount;
        userInfo[msg.sender].pendingWithdrawAmount = 0;
        totalWithdrawPending = totalWithdrawPending - pendingWR;
        emit LogCancelWithdrawRequest(msg.sender, address(this), pendingWR);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "../SyntheticSSIP.sol";

contract SyntheticSSIPFactory {
    address public owner;
    address public exchangeAgent;
    address public lastNewSSIP;
    address[] public ssipList;

    constructor(address _owner, address _exchangeAgent) {
        owner = _owner;
        exchangeAgent = _exchangeAgent;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "UnoRe: Forbidden");
        _;
    }

    function newSyntheticSSIP(
        address _owner,
        address _lpToken,
        address _unoToken
    ) external onlyOwner returns (address) {
        SyntheticSSIP _ssip = new SyntheticSSIP(_owner, exchangeAgent, _lpToken, _unoToken);
        address _ssipAddr = address(_ssip);
        lastNewSSIP = _ssipAddr;
        ssipList.push(_ssipAddr);
        return _ssipAddr;
    }

    function allSSIPLength() external view returns (uint256) {
        return ssipList.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IExchangeAgent {
    function USDT_TOKEN() external view returns (address);

    function getTokenAmountForUSDT(address _token, uint256 _usdtAmount) external view returns (uint256);

    function getETHAmountForUSDT(uint256 _usdtAmount) external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMigration {
    function onMigration(
        address who_,
        uint256 amount_,
        bytes memory data_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IRewarder {
    function currency() external view returns (address);

    function onReward(address to, uint256 unoAmount) external payable returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface IRewarderFactory {
    function newRewarder(
        address _operator,
        address _currency,
        address _pool
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

interface ISyntheticSSIP {
    function updatePool() external;

    function enterInPool(uint256 _amount) external;

    function leaveFromPoolInPending(uint256 _amount) external;

    function leaveFromPending() external;

    function harvest(address _to) external;
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