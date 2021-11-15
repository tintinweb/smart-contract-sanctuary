//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IInvestmentSafeFactory.sol";
import "./InvestmentSafe.sol";

contract InvestmentSafeFactory is Ownable, IInvestmentSafeFactory {
    using SafeMath for uint256;

    mapping(address => bool) public hasCreatedSafe;
    address public override singleTokenJoin;
    address public override singleTokenExit;
    address public override weth;
    address public override childAmunWeth;
    IUniswapRouter public router;

    IChildAmunWeth public ChildAmunWeth;
    uint256 public immutable override EXIT_GAS = 1065035;
    uint256 public immutable override JOIN_GAS = 1451882;
    uint256 public immutable override GAS_CREATE_SAFE = 3145609;
    uint256 public maticToEthConversionRate = 402715000000000;

    bytes32 public immutable override _PERMIT_JOIN_TYPEHASH =
        keccak256(
            "PermitJoin(address sender,address targetToken,uint256 amount,uint256 targetAmount,uint256 nonce,uint256 deadline)"
        );

    bytes32 public immutable override _PERMIT_EXIT_TYPEHASH =
        keccak256(
            "PermitExit(address sender,address sourceToken,uint256 amount,uint256 targetAmount,uint256 nonce,uint256 deadline)"
        );

    constructor(
        address _singleTokenJoin,
        address _singleTokenExit,
        address _weth,
        address _childAmunWeth,
        address _router
    ) Ownable() {
        require(
            _singleTokenJoin != address(0),
            "new singleTokenJoin is the zero address"
        );
        require(
            _singleTokenExit != address(0),
            "new singleTokenExit is the zero address"
        );
        require(_weth != address(0), "new weth is the zero address");
        require(
            _childAmunWeth != address(0),
            "new childAmunWeth is the zero address"
        );
        require(_router != address(0), "new router is the zero address");

        singleTokenJoin = _singleTokenJoin;
        singleTokenExit = _singleTokenExit;
        weth = _weth;
        childAmunWeth = _childAmunWeth;
        router = IUniswapRouter(_router);
    }

    function _createSafe(address safeOwner)
        internal
        returns (address payable safe)
    {
        require(!hasCreatedSafe[safeOwner], "Safe already created for address");

        bytes memory bytecode = type(InvestmentSafe).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(safeOwner));
        assembly {
            safe := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(safe)) {
                revert(0, 0)
            }
        }
        hasCreatedSafe[safeOwner] = true;

        emit SafeCreated(safeOwner, safe);
    }

    /// @dev creates user's safe using CREATE2 opcode
    /// @param safeName The name of the user safe
    /// @param safeOwner The address of safe owner
    /// @param joinData Struct of all data required to join basket and validate signature
    /// @param minReturn Minimal basket amount expected
    /// @param joinTokenTrades Trades to execute
    function createSafeAndJoinFor(
        string memory safeName,
        address safeOwner,
        InvestmentSafe.DelegateJoinData calldata joinData,
        uint256 minReturn,
        ISingleTokenJoinV2.UnderlyingTrade[] calldata joinTokenTrades
    ) external onlyOwner returns (address payable safe) {
        safe = _createSafe(safeOwner);
        InvestmentSafe(safe).initializeAndJoin(
            safeName,
            safeOwner,
            address(this),
            msg.sender,
            joinData,
            minReturn,
            joinTokenTrades,
            msg.sender
        );
    }

    /// @dev creates user's safe using CREATE2 opcode
    /// @param safeName The name of the user safe
    /// @param safeOwner The address of safe owner
    /// @param exitData Struct of all data required to exit basket and validate signature
    /// @param minReturn Minimal basket amount expected
    /// @param exitTokenTrades Trades to execute
    function createSafeAndExitFor(
        string memory safeName,
        address safeOwner,
        InvestmentSafe.DelegateExitData calldata exitData,
        uint256 minReturn,
        ISingleNativeTokenExitV2.ExitUnderlyingTrade[] calldata exitTokenTrades
    ) external onlyOwner returns (address payable safe) {
        safe = _createSafe(safeOwner);
        InvestmentSafe(safe).initializeAndExit(
            safeName,
            safeOwner,
            address(this),
            msg.sender,
            exitData,
            minReturn,
            exitTokenTrades,
            msg.sender
        );
    }

    /// @dev creates user's safe using CREATE2 opcode
    /// @param safeName The name of the user safe
    /// @param safeOwner The address of safe owner
    function createSafeFor(string memory safeName, address safeOwner)
        external
        override
        onlyOwner
        returns (address payable safe)
    {
        safe = _createSafe(safeOwner);

        InvestmentSafe(safe).initialize(
            safeName,
            safeOwner,
            address(this),
            msg.sender
        );
    }

    /// @dev creates user's safe using CREATE2 opcode
    /// @param safeName The name of the user safe
    function createSafe(string memory safeName)
        external
        returns (address payable safe)
    {
        safe = _createSafe(msg.sender);
        InvestmentSafe(safe).initialize(
            safeName,
            msg.sender,
            address(this),
            msg.sender
        );
    }

    /// @dev calculates the CREATE2 address for an address
    /// @param safeOwner The address of safe owner
    /// @return safe The safe address of safeOwner
    function safeFor(address safeOwner)
        external
        view
        override
        returns (address safe)
    {
        bytes memory bytecode = type(InvestmentSafe).creationCode;

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                keccak256(abi.encodePacked(safeOwner)),
                keccak256(bytecode)
            )
        );

        safe = address(uint160(uint256(hash)));
    }

    /// @dev Sets conversion rate used to pay gasfee in eth
    /// @param _maticToEthConversionRate The conversion rate to set
    function setMaticToEthConversionRate(uint256 _maticToEthConversionRate)
        external
        onlyOwner
    {
        maticToEthConversionRate = _maticToEthConversionRate;
    }

    function getWethUsedForGas(uint256 gas)
        external
        view
        override
        returns (uint256 wethUsedForSafe)
    {
        return getWethUsedForGas2(gas, tx.gasprice);
    }

    function getWethUsedForGas2(uint256 gas, uint256 gasprice)
        public
        view
        returns (uint256 wethUsedForSafe)
    {
        wethUsedForSafe = gasprice.mul(gas).mul(maticToEthConversionRate).div(
            1 ether
        );
    }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IChildAmunWeth.sol";

interface IUniswapRouter {
    function WETH() external view returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IInvestmentSafeFactory {
    event SafeCreated(address indexed safeOwner, address safeAddress);

    function singleTokenJoin() external view returns (address);

    function singleTokenExit() external view returns (address);

    function weth() external view returns (address);

    function childAmunWeth() external view returns (address);

    function _PERMIT_JOIN_TYPEHASH() external view returns (bytes32);

    function _PERMIT_EXIT_TYPEHASH() external view returns (bytes32);

    function EXIT_GAS() external view returns (uint256);

    function JOIN_GAS() external view returns (uint256);

    function GAS_CREATE_SAFE() external view returns (uint256);

    function createSafeFor(string memory, address)
        external
        returns (address payable safe);

    function safeFor(address) external view returns (address safe);

    function getWethUsedForGas(uint256 gas)
        external
        view
        returns (uint256 wethUsedForSafe);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./EIP712.sol";
import "./interfaces/IChildAmunWeth.sol";
import "./interfaces/IPolygonERC20Wrapper.sol";
import "./interfaces/ISingleTokenJoinV2.sol";
import "./interfaces/ISingleNativeTokenExitV2.sol";
import "./interfaces/IInvestmentSafe.sol";
import "./interfaces/IInvestmentSafeFactory.sol";

contract InvestmentSafe is EIP712, IInvestmentSafe {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public owner;
    mapping(address => uint256) public nonces;

    mapping(address => Steps) public exitStep;
    mapping(address => bool) public isSecondJoinStep;
    uint256 public bridgeAmount;

    IInvestmentSafeFactory public investmentSafeFactory;

    event SafeWithdraw(
        address indexed token,
        address indexed beneficiary,
        uint256 amount
    );
    event DelegatedJoin(
        address indexed token,
        address indexed beneficiary,
        uint256 sourceAmount,
        uint256 targetAmount
    );
    event DelegatedExit(
        address indexed token,
        address indexed beneficiary,
        uint256 sourceAmount,
        uint256 targetAmount
    );
    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    modifier requireNonZero(address token, uint256 amount) {
        require(token != address(0), "token not set");
        require(amount > 0, "amount is zero");

        _;
    }

    function _initialize(
        string memory safeName,
        address _owner,
        address _investmentSafeFactory,
        address _creator
    ) internal {
        require(_owner != address(0), "new owner is the zero address");
        require(
            _investmentSafeFactory != address(0),
            "new investmentSafeFactory is the zero address"
        );
        require(_creator != address(0), "new creator is the zero address");
        owner = _owner;
        initializeEIP712(safeName, "1");
        investmentSafeFactory = IInvestmentSafeFactory(_investmentSafeFactory);
    }

    function _paybackGas(address recipient, uint256 gas) internal {
        uint256 amount = investmentSafeFactory.getWethUsedForGas(gas);
        IERC20(investmentSafeFactory.weth()).safeTransfer(recipient, amount);
    }

    function initialize(
        string memory safeName,
        address _owner,
        address _investmentSafeFactory,
        address _creator
    ) external initializer {
        _initialize(safeName, _owner, _investmentSafeFactory, _creator);

        if (_owner != _creator) {
            _paybackGas(_creator, investmentSafeFactory.GAS_CREATE_SAFE());
        }
    }

    function initializeAndJoin(
        string memory safeName,
        address _owner,
        address _investmentSafeFactory,
        address _creator,
        DelegateJoinData calldata joinData,
        uint256 minReturn,
        ISingleTokenJoinV2.UnderlyingTrade[] calldata joinTokenTrades,
        address _permitCaller
    ) external initializer {
        _initialize(safeName, _owner, _investmentSafeFactory, _creator);
        uint256 gasCost = investmentSafeFactory.getWethUsedForGas(
            investmentSafeFactory.GAS_CREATE_SAFE()
        );
        _delegatedJoin(joinData, minReturn, joinTokenTrades, _creator, gasCost, _permitCaller);
    }

    function initializeAndExit(
        string memory safeName,
        address _owner,
        address _investmentSafeFactory,
        address _creator,
        DelegateExitData calldata exitData,
        uint256 minReturn,
        ISingleNativeTokenExitV2.ExitUnderlyingTrade[] calldata exitTokenTrades,
        address _permitCaller
    ) external initializer {
        _initialize(safeName, _owner, _investmentSafeFactory, _creator);
        uint256 gasCost = 0;
        if (_owner != _creator) {
            gasCost = investmentSafeFactory.getWethUsedForGas(
                investmentSafeFactory.GAS_CREATE_SAFE()
            );
        }
        _delegatedExit(exitData, minReturn, exitTokenTrades, _creator, gasCost, _permitCaller);
    }

    /// @dev Invalidate nonces
    /// @param user The user address to set nonce for
    /// @param nonce The new nonce
    function setNonce(address user, uint256 nonce) external onlyOwner {
        require(nonce > nonces[user], "can only invalidate new nonces");
        nonces[user] = nonce;
    }

    /// @dev Remove ERC20 token from safe
    /// @param token ERC20 address
    /// @param amount The amount to be withdrawn
    function withdrawFromSafe(address token, uint256 amount)
        external
        onlyOwner
    {
        _withdrawFromSafe(token, msg.sender, amount);
    }

    function _withdrawFromSafe(
        address _token,
        address _beneficiary,
        uint256 _amount
    ) internal requireNonZero(_token, _amount) {
        IERC20(_token).safeTransfer(_beneficiary, _amount);

        emit SafeWithdraw(_token, _beneficiary, _amount);
    }

    /// @dev Check ERC20 token balances
    /// @param token ERC20 address
    function balanceOfInSafe(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    // fallback function
    receive() external payable onlyOwner {}

    /// @dev Remove native token from safe
    /// @param amount The amount to be withdrawn
    function withdrawNativeTokenFromSafe(uint256 amount) external onlyOwner {
        _withdrawNativeTokenFromSafe(msg.sender, amount);
    }

    function _withdrawNativeTokenFromSafe(address _beneficiary, uint256 _amount)
        internal
    {
        require(_amount > 0, "amount is zero");
        (bool success, ) = _beneficiary.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /// @dev Check native token balance
    function balanceOfNativeTokenInSafe() external view returns (uint256) {
        return address(this).balance;
    }

    function _maxApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) < amount) {
            token.approve(spender, type(uint256).max);
        }
    }

    //////////////////////////  PERMIT FUNCTIONS //////////////////////////

    function getPermitHash(
        bytes32 permitHash,
        address sender,
        address token,
        uint256 amount,
        uint256 targetAmount,
        uint256 nonce,
        uint256 deadline
    ) public view returns (bytes32 hash) {
        bytes32 structHash = keccak256(
            abi.encode(
                permitHash,
                sender,
                token,
                amount,
                targetAmount,
                nonce,
                deadline
            )
        );

        hash = _hashTypedDataV4(structHash);
    }

    function _checkJoinSignature(DelegateJoinData calldata joinData, address caller)
        internal
        virtual
    {
        bytes32 hash = getPermitHash(
            investmentSafeFactory._PERMIT_JOIN_TYPEHASH(),
            caller,
            joinData.targetToken,
            joinData.amount,
            joinData.targetAmount,
            nonces[caller],
            joinData.deadline
        );
        address signer = ECDSA.recover(
            hash,
            joinData.v,
            joinData.r,
            joinData.s
        );
        require(signer == owner, "JoinPermit: invalid signature");
    }

    /// @dev Delegated join and bridging back of target token
    /// @param joinData Struct of all data required to join basket and validate signature
    /// @param minReturn Minimal basket amount expected
    /// @param joinTokenTrades Trades to execute
    function delegatedJoin(
        DelegateJoinData calldata joinData,
        uint256 minReturn,
        ISingleTokenJoinV2.UnderlyingTrade[] calldata joinTokenTrades
    ) external override {
        _delegatedJoin(joinData, minReturn, joinTokenTrades, msg.sender, 0, msg.sender);
    }

    function _delegatedJoin(
        DelegateJoinData calldata joinData,
        uint256 minReturn,
        ISingleTokenJoinV2.UnderlyingTrade[] calldata joinTokenTrades,
        address caller,
        uint256 extraGas,
        address permitCaller
    ) internal {
        require(
            block.timestamp <= joinData.deadline,
            "JoinPermit: expired deadline"
        );
        require(
            minReturn >= joinData.targetAmount,
            "JoinPermit: minReturn to small"
        );
        require(!isSecondJoinStep[permitCaller], "NOT_STEP1");
        isSecondJoinStep[permitCaller] = true;

        IERC20 weth = IERC20(investmentSafeFactory.weth());
        uint256 balance = weth.balanceOf(address(this));
        require(
            balance >= joinData.amount,
            "JoinPermit: amount exceeds balance"
        );
        uint256 gasCost = investmentSafeFactory
            .getWethUsedForGas(investmentSafeFactory.JOIN_GAS())
            .add(extraGas);
        uint256 amountAfterGasCost = joinData.amount.sub(gasCost);

        {
            _checkJoinSignature(joinData, permitCaller);

            weth.safeTransfer(caller, gasCost);
        }

        address underlying = IPolygonERC20Wrapper(joinData.targetToken)
            .underlying();
        ISingleTokenJoinV2.JoinTokenStructV2
            memory joinParams = ISingleTokenJoinV2.JoinTokenStructV2(
                investmentSafeFactory.weth(),
                underlying,
                amountAfterGasCost,
                minReturn,
                joinTokenTrades,
                joinData.deadline,
                0
            );

        _maxApprove(
            weth,
            investmentSafeFactory.singleTokenJoin(),
            amountAfterGasCost
        );
        bridgeAmount = IERC20(underlying).balanceOf(address(this));

        ISingleTokenJoinV2(investmentSafeFactory.singleTokenJoin())
            .joinTokenSingle(joinParams);
        require(
            balance <= weth.balanceOf(address(this)).add(joinData.amount),
            "JoinPermit: Insufficient input"
        );
        _maxApprove(IERC20(underlying), joinData.targetToken, minReturn);
        bridgeAmount = IERC20(underlying).balanceOf(address(this)).sub(
            bridgeAmount
        );
    }

    function delegatedJoin2(DelegateJoinData calldata joinData) external {
        require(isSecondJoinStep[msg.sender], "NOT_STEP2");
        isSecondJoinStep[msg.sender] = false;
        _checkJoinSignature(joinData, msg.sender);
        nonces[msg.sender] = nonces[msg.sender] + 1;

        IPolygonERC20Wrapper(joinData.targetToken).withdrawTo(
            bridgeAmount,
            owner
        );
        emit DelegatedJoin(
            joinData.targetToken,
            owner,
            joinData.amount,
            bridgeAmount
        );
    }

    function _checkExitSignature(DelegateExitData calldata exitData, address caller)
        internal
        virtual
    {
        bytes32 hash = getPermitHash(
            investmentSafeFactory._PERMIT_EXIT_TYPEHASH(),
            caller,
            exitData.sourceToken,
            exitData.amount,
            exitData.targetAmount,
            nonces[caller],
            exitData.deadline
        );

        address signer = ECDSA.recover(
            hash,
            exitData.v,
            exitData.r,
            exitData.s
        );
        require(signer == owner, "ExitPermit: invalid signature");
    }

    /// @dev Delegated exit and bridging back of target token
    /// @param exitData Struct of all data required to exit basket and validate signature
    /// @param minReturn Minimal basket amount expected
    /// @param exitTokenTrades Trades to execute
    function delegatedExit(
        DelegateExitData calldata exitData,
        uint256 minReturn,
        ISingleNativeTokenExitV2.ExitUnderlyingTrade[] calldata exitTokenTrades
    ) public override {
        _delegatedExit(exitData, minReturn, exitTokenTrades, msg.sender, 0, msg.sender);
    }

    /// @dev Delegated exit and bridging back of target token
    /// @param exitData Struct of all data required to exit basket and validate signature
    /// @param minReturn Minimal basket amount expected
    /// @param exitTokenTrades Trades to execute
    function _delegatedExit(
        DelegateExitData calldata exitData,
        uint256 minReturn,
        ISingleNativeTokenExitV2.ExitUnderlyingTrade[] calldata exitTokenTrades,
        address caller,
        uint256 extraGas,
        address permitCaller
    ) internal {
        require(
            block.timestamp <= exitData.deadline,
            "ExitPermit: expired deadline"
        );
        require(
            minReturn >= exitData.targetAmount,
            "ExitPermit: minReturn to small"
        );
        require(exitStep[permitCaller] == Steps.One, "NOT_STEP_ONE");
        exitStep[permitCaller] = Steps.Two;

        _checkExitSignature(exitData, permitCaller);

        ISingleNativeTokenExitV2.ExitTokenStructV2
            memory _exitTokenStruct = ISingleNativeTokenExitV2
                .ExitTokenStructV2(
                    exitData.sourceToken,
                    exitData.amount,
                    minReturn,
                    exitData.deadline,
                    0,
                    exitTokenTrades
                );
        IERC20 weth = IERC20(investmentSafeFactory.weth());

        uint256 amountBefore = weth.balanceOf(address(this));

        _maxApprove(
            IERC20(exitData.sourceToken),
            investmentSafeFactory.singleTokenExit(),
            exitData.amount
        );
        ISingleNativeTokenExitV2(investmentSafeFactory.singleTokenExit()).exit(
            _exitTokenStruct
        );
        uint256 targetAmount = weth.balanceOf(address(this)).sub(amountBefore);

        require(minReturn <= targetAmount, "ExitPermit: Insufficient output");

        {
            uint256 gasCost = investmentSafeFactory.getWethUsedForGas(
                investmentSafeFactory.EXIT_GAS()
            ).add(extraGas);
            bridgeAmount = targetAmount.sub(gasCost);
            weth.safeTransfer(caller, gasCost);
        }

        _maxApprove(weth, investmentSafeFactory.childAmunWeth(), bridgeAmount);
    }

    function delegatedExit2(DelegateExitData calldata exitData) external {
        require(exitStep[msg.sender] == Steps.Two, "NOT_STEP_TWO");
        exitStep[msg.sender] = Steps.Three;
        _checkExitSignature(exitData, msg.sender);

        IChildAmunWeth(investmentSafeFactory.childAmunWeth()).getAmunWeth(
            bridgeAmount
        );
    }

    function delegatedExit3(DelegateExitData calldata exitData) external {
        require(exitStep[msg.sender] == Steps.Three, "NOT_STEP_THREE");
        exitStep[msg.sender] = Steps.One;
        _checkExitSignature(exitData, msg.sender);
        nonces[msg.sender] = nonces[msg.sender] + 1;

        IChildAmunWeth(investmentSafeFactory.childAmunWeth()).withdrawTo(
            bridgeAmount,
            owner
        );
        emit DelegatedExit(
            exitData.sourceToken,
            owner,
            exitData.amount,
            bridgeAmount
        );
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IChildAmunWeth {
    function getAmunWeth(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawTo(uint256 amount, address receiver) external;
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

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    uint256 private _CACHED_CHAIN_ID;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function initializeEIP712(string memory name, string memory version)
        public
        initializer
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = 1;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(
            typeHash,
            hashedName,
            hashedVersion
        );
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (1 == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    1,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IPolygonERC20Wrapper {
    function underlying() external view returns (address);

    function withdrawTo(uint256 amount, address reciver) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ISingleTokenJoinV2 {
    struct UnderlyingTrade {
        UniswapV2SwapStruct[] swaps;
        uint256 quantity; //Quantity to buy
    }

    struct UniswapV2SwapStruct {
        address exchange;
        address[] path;
    }
    struct JoinTokenStructV2 {
        address inputToken;
        address outputBasket;
        uint256 inputAmount;
        uint256 outputAmount;
        UnderlyingTrade[] trades;
        uint256 deadline;
        uint16 referral;
    }

    function joinTokenSingle(JoinTokenStructV2 calldata _joinTokenStruct)
        external
        payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ISingleNativeTokenExitV2 {
    struct ExitUnderlyingTrade {
        ExitUniswapV2SwapStruct[] swaps;
    }

    struct ExitUniswapV2SwapStruct {
        address exchange;
        address[] path;
    }
    struct ExitTokenStructV2 {
        address inputBasket;
        uint256 inputAmount;
        uint256 minAmount;
        uint256 deadline;
        uint16 referral;
        ExitUnderlyingTrade[] trades;
    }

    function exit(ExitTokenStructV2 calldata _exitTokenStruct) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./ISingleTokenJoinV2.sol";
import "./ISingleNativeTokenExitV2.sol";

interface IInvestmentSafe {
    enum Steps {
        One,
        Two,
        Three
    }

    struct DelegateJoinData {
        address targetToken;
        uint256 amount;
        uint256 targetAmount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct DelegateExitData {
        address sourceToken;
        uint256 amount;
        uint256 targetAmount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @dev Delegated join and bridging back of target token
    function delegatedJoin(
        DelegateJoinData calldata joinData,
        uint256 minReturn,
        ISingleTokenJoinV2.UnderlyingTrade[] calldata _joinTokenTrades
    ) external;

    /// @dev Delegated exit and bridging back of target token
    function delegatedExit(
        DelegateExitData calldata exitData,
        uint256 minReturn,
        ISingleNativeTokenExitV2.ExitUnderlyingTrade[] calldata trades
    ) external;
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

