pragma solidity ^0.5.16;

interface IBridgeContract {
    function requireToPassMessage(
        address,
        bytes calldata,
        uint256
    ) external;

    function messageSender() external returns (address);
}

pragma solidity >=0.5.0 <0.7.0;

interface ICToken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

pragma solidity ^0.5.16;

interface IChainlinkOracle {
    function latestAnswer() external returns (int256);
}

pragma solidity 0.5.16;

interface IComptroller {
    function claimComp(address holder) external;
}

pragma solidity >=0.5.0;

interface IPERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity ^0.5.16;

interface IXGTGenerator {
    function tokensStaked(uint256 _amount, address _user) external;

    function tokensPooled(uint256 _amount, address _user) external;

    function tokensUnstaked(uint256 _amount, address _user) external;

    function tokensUnpooled(uint256 _amount, address _user) external;

    function claimXGT(address _user) external;

    function manualCorrectDeposit(uint256 _daiBalance, address _user) external;
}

pragma solidity 0.5.16;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
        );

    bytes32 internal domainSeperator;
    bool internal initializedAlready;

    function initBase(string memory name, string memory version) public {
        require(!initializedAlready, "BASE-ALREADY-INITIALIZED");
        initializedAlready = true;
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                getChainID(),
                address(this)
            )
        );
    }

    function getChainID() internal pure returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeperator() private view returns (bytes32) {
        return domainSeperator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

pragma solidity 0.5.16;

import "@openzeppelin/openzeppelin-contracts-upgradeable/contracts/math/SafeMath.sol";
import "./EIP712Base.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;

    bool internal initializedAlreadyMeta;

    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function initMeta(string memory name, string memory version) public {
        require(!initializedAlreadyMeta, "META-ALREADY-INITIALIZED");
        initializedAlreadyMeta = true;
        initBase(name, version);
    }

    function convertBytesToBytes4(bytes memory inBytes)
        internal
        pure
        returns (bytes4 outBytes4)
    {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(
            destinationFunctionSig != msg.sig,
            "functionSignature can not be of executeMetaTransaction method"
        );
        MetaTransaction memory metaTx =
            MetaTransaction({
                nonce: nonces[userAddress],
                from: userAddress,
                functionSignature: functionSignature
            });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) =
            address(this).call(
                abi.encodePacked(functionSignature, userAddress)
            );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer =
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/openzeppelin-contracts-upgradeable/contracts/math/SafeMath.sol";
import "@openzeppelin/openzeppelin-contracts-upgradeable/contracts/ownership/Ownable.sol";
import "../metatx/EIP712MetaTransaction.sol";
import "../metatx/EIP712Base.sol";
import "../interfaces/ICToken.sol";
import "../interfaces/IComptroller.sol";
import "../interfaces/IBridgeContract.sol";
import "../interfaces/IXGTGenerator.sol";
import "../interfaces/IPERC20.sol";
import "../interfaces/IChainlinkOracle.sol";

contract XGTStake is Initializable, Ownable, EIP712MetaTransaction {
    using SafeMath for uint256;

    IPERC20 public stakeToken;
    ICToken public cToken;
    IComptroller public comptroller;
    IPERC20 public comp;
    IBridgeContract public bridge;
    IChainlinkOracle public ethDaiOracle;
    IChainlinkOracle public gasOracle;

    address public xgtGeneratorContract;
    address public xgtFund;

    bool public paused;
    uint256 public averageGasPerDeposit;
    uint256 public averageGasPerWithdraw;
    address public refundAddress;

    uint256 public interestCut; // Interest Cut in Basis Points (250 = 2.5%)
    address public interestCutReceiver;

    mapping(address => uint256) public userDepositsDai;
    mapping(address => uint256) public userDepositsCDai;
    uint256 public totalDeposits;

    function initializeStake(
        address _stakeToken,
        address _cToken,
        address _comptroller,
        address _comp,
        address _bridge,
        address _interestAddress,
        address _refundAddress
    ) public {
        require(
            interestCutReceiver == address(0),
            "XGTSTAKE-ALREADY-INITIALIZED"
        );
        initMeta("XGTStake", "1");
        averageGasPerDeposit = 500000;
        averageGasPerWithdraw = 500000;
        interestCut = 250;
        _transferOwnership(msg.sender);
        stakeToken = IPERC20(_stakeToken);
        cToken = ICToken(_cToken);
        comptroller = IComptroller(_comptroller);
        comp = IPERC20(_comp);
        bridge = IBridgeContract(_bridge);
        ethDaiOracle = IChainlinkOracle(
            0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838
        );
        gasOracle = IChainlinkOracle(
            0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
        );
        interestCutReceiver = _interestAddress;
        refundAddress = _refundAddress;
    }

    function setXGTGeneratorContract(address _address) external {
        require(
            xgtGeneratorContract == address(0),
            "XGTSTAKE-GEN-ADDR-ALREADY-SET"
        );
        xgtGeneratorContract = _address;
    }

    function pauseContracts(bool _pause) external onlyOwner {
        paused = _pause;
    }

    function changeRefundAddress(address _address) external onlyOwner {
        refundAddress = _address;
    }

    function changeInterestAddress(address _address) external onlyOwner {
        interestCutReceiver = _address;
    }

    function changeGasOracle(address _address) external onlyOwner {
        gasOracle = IChainlinkOracle(_address);
    }

    function changePriceOracle(address _address) external onlyOwner {
        ethDaiOracle = IChainlinkOracle(_address);
    }

    function changeBridge(address _address) external onlyOwner {
        bridge = IBridgeContract(_address);
    }

    function changeInterestCut(uint256 _newValue) external onlyOwner {
        require(_newValue <= 9999, "XGTSTAKE-INVALID-CUT");
        interestCut = _newValue;
    }

    function changeGasCosts(uint256 _deposit, uint256 _withdraw)
        external
        onlyOwner
    {
        averageGasPerDeposit = _deposit;
        averageGasPerWithdraw = _withdraw;
    }

    function depositTokens(uint256 _amount) external notPaused {
        require(
            stakeToken.transferFrom(msgSender(), address(this), _amount),
            "XGTSTAKE-DAI-TRANSFER-FAILED"
        );

        uint256 amountLeft = _amount;

        // If it is a metatx, refund the executor in DAI
        if (msgSender() != msg.sender) {
            uint256 refundAmount = currentRefundCostDeposit();
            require(refundAmount < _amount, "XGTSTAKE-DEPOSIT-TOO-SMALL");
            amountLeft = _amount.sub(refundAmount);
            require(
                stakeToken.transfer(refundAddress, refundAmount),
                "XGTSTAKE-DAI-REFUND-FAILED"
            );
        }

        require(
            stakeToken.approve(address(cToken), _amount),
            "XGTSTAKE-DAI-APPROVE-FAILED"
        );

        uint256 balanceBefore = cToken.balanceOf(address(this));
        require(
            cToken.mint(amountLeft) == 0,
            "XGTSTAKE-COMPOUND-DEPOSIT-FAILED"
        );
        uint256 cDai = cToken.balanceOf(address(this)).sub(balanceBefore);

        userDepositsDai[msgSender()] = userDepositsDai[msgSender()].add(
            amountLeft
        );
        userDepositsCDai[msgSender()] = userDepositsCDai[msgSender()].add(cDai);
        totalDeposits = totalDeposits.add(amountLeft);

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensStaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, amountLeft, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function withdrawTokens(uint256 _amount) external {
        uint256 userDepositDai = userDepositsDai[msgSender()];
        uint256 userDepositCDai = userDepositsCDai[msgSender()];
        require(userDepositDai > 0, "XGTSTAKE-NO-DEPOSIT");

        // If user puts in MAX_UINT256, skip this calcualtion
        // and set it to the maximum possible
        uint256 cDaiToRedeem = uint256(2**256 - 1);
        uint256 amount = _amount;
        if (amount != cDaiToRedeem) {
            cDaiToRedeem = userDepositCDai.mul(amount).div(userDepositDai);
        }

        // If the calculation for some reason came up with too much
        // or if the user set to withdraw everything: set max
        if (cDaiToRedeem > userDepositCDai) {
            cDaiToRedeem = userDepositCDai;
            amount = userDepositDai;
        }

        totalDeposits = totalDeposits.sub(amount);
        userDepositsDai[msgSender()] = userDepositDai.sub(amount);
        userDepositsCDai[msgSender()] = userDepositCDai.sub(cDaiToRedeem);

        uint256 before = stakeToken.balanceOf(address(this));
        require(
            cToken.redeem(cDaiToRedeem) == 0,
            "XGTSTAKE-COMPOUND-WITHDRAW-FAILED"
        );
        uint256 diff = (stakeToken.balanceOf(address(this))).sub(before);
        require(diff >= amount, "XGTSTAKE-COMPOUND-AMOUNT-MISMATCH");

        // Deduct the interest cut
        uint256 interest = diff.sub(amount);
        uint256 cut = 0;
        if (interest != 0) {
            cut = (interest.mul(interestCut)).div(10000);
            require(
                stakeToken.transfer(interestCutReceiver, cut),
                "XGTSTAKE-INTEREST-CUT-TRANSFER-FAILED"
            );
        }

        uint256 amountLeft = diff.sub(cut);
        // If it is a metatx, refund the executor in DAI
        if (msgSender() != msg.sender) {
            uint256 refundAmount = currentRefundCostWithdraw();
            require(refundAmount < _amount, "XGTSTAKE-WITHDRAW-TOO-SMALL");
            amountLeft = amountLeft.sub(refundAmount);
            require(
                stakeToken.transfer(refundAddress, refundAmount),
                "XGTSTAKE-DAI-REFUND-FAILED"
            );
        }

        // Transfer the rest to the user
        require(
            stakeToken.transfer(msgSender(), amountLeft),
            "XGTSTAKE-USER-TRANSFER-FAILED"
        );

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensUnstaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, _amount, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function correctBalance(address _user) external {
        bytes4 _methodSelector =
            IXGTGenerator(address(0)).manualCorrectDeposit.selector;
        bytes memory data =
            abi.encodeWithSelector(
                _methodSelector,
                userDepositsDai[_user],
                _user
            );
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function claimComp() external {
        comptroller.claimComp(address(this));
        uint256 balance = comp.balanceOf(address(this));
        if (balance > 0) {
            require(
                comp.transferFrom(address(this), interestCutReceiver, balance),
                "XGTSTAKE-TRANSFER-FAILED"
            );
        }
    }

    function currentRefundCostDeposit() public returns (uint256) {
        return _getTXCost(averageGasPerDeposit);
    }

    function currentRefundCostWithdraw() public returns (uint256) {
        return _getTXCost(averageGasPerWithdraw);
    }

    function _getTXCost(uint256 _gasAmount) internal returns (uint256) {
        uint256 oracleAnswerPrice = uint256(ethDaiOracle.latestAnswer());
        uint256 oracleAnswerGas = uint256(gasOracle.latestAnswer());
        if (oracleAnswerPrice > 0 && oracleAnswerGas > 0) {
            uint256 refund =
                (
                    uint256(oracleAnswerGas)
                        .mul(_gasAmount)
                        .mul(uint256(1000000))
                        .div(oracleAnswerPrice)
                );
            return refund;
        }
        return 0;
    }

    modifier notPaused() {
        require(!paused, "XGTSTAKE-Paused");
        _;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}