/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/


// File: user-rating/openzeppelin-contracts/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
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

// File: user-rating/openzeppelin-contracts/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
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
}

// File: user-rating/contracts/score/ScoringMachine.sol

pragma solidity ^0.5.12;


contract ScoringMachine is Ownable {
    struct AssetScore {
        // total score so far
        uint score;

        // current balance
        uint balance;

        // time when last update was
        uint last;
    }

    // user is bytes32 (will be the sha3 of address or cdp number)
    mapping(bytes32 => mapping(bytes32 => AssetScore[])) public checkpoints;

    mapping(bytes32 => mapping(bytes32 => AssetScore)) public userScore;

    bytes32 constant public GLOBAL_USER = bytes32(0x0);

    uint public start; // start time of the campaign;

    function spin() external onlyOwner { // start a new round
        start = now;
    }

    function assetScore(AssetScore storage score, uint time, uint spinStart) internal view returns(uint) {
        uint last = score.last;
        uint currentScore = score.score;
        if(last < spinStart) {
            last = spinStart;
            currentScore = 0;
        }

        return add(currentScore, mul(score.balance, sub(time, last)));
    }

    function addCheckpoint(bytes32 user, bytes32 asset) internal {
        checkpoints[user][asset].push(userScore[user][asset]);
    }

    function updateAssetScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        AssetScore storage score = userScore[user][asset];

        if(score.last < start) addCheckpoint(user, asset);

        score.score = assetScore(score, time, start);
        score.balance = add(score.balance, dbalance);
        
        score.last = time;
    }

    function updateScore(bytes32 user, bytes32 asset, int dbalance, uint time) internal {
        updateAssetScore(user, asset, dbalance, time);
        updateAssetScore(GLOBAL_USER, asset, dbalance, time);
    }

    function getScore(bytes32 user, bytes32 asset, uint time, uint spinStart, uint checkPointHint) public view returns(uint score) {
        if(time >= userScore[user][asset].last) return assetScore(userScore[user][asset], time, spinStart);

        // else - check the checkpoints
        uint checkpointsLen = checkpoints[user][asset].length;
        if(checkpointsLen == 0) return 0;

        // hint is invalid
        if(checkpoints[user][asset][checkPointHint].last < time) checkPointHint = checkpointsLen - 1;

        for(uint i = checkPointHint ; ; i--){
            if(checkpoints[user][asset][i].last <= time) return assetScore(checkpoints[user][asset][i], time, spinStart);
        }

        // this supposed to be unreachable
        return 0;
    }

    function getCurrentBalance(bytes32 user, bytes32 asset) public view returns(uint balance) {
        balance = userScore[user][asset].balance;
    }

    // Math functions without errors
    // ==============================
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        if(!(z >= x)) return 0;

        return z;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        if(!(y >= 0 || z <= x)) return 0;
        if(!(y <= 0 || z >= x)) return 0;

        return z;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        if(!(y <= x)) return 0;
        z = x - y;

        return z;
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        if (x == 0) return 0;

        z = x * y;
        if(!(z / x == y)) return 0;

        return z;
    }
}

// File: contracts/bprotocol/interfaces/IRegistry.sol

pragma solidity 0.5.16;


interface IRegistry {

    // Ownable
    function transferOwnership(address newOwner) external;

    // Compound contracts
    function comp() external view returns (address);
    function comptroller() external view returns (address);
    function cEther() external view returns (address);

    // B.Protocol contracts
    function bComptroller() external view returns (address);
    function score() external view returns (address);
    function pool() external view returns (address);

    // Avatar functions
    function delegate(address avatar, address delegatee) external view returns (bool);
    function doesAvatarExist(address avatar) external view returns (bool);
    function doesAvatarExistFor(address owner) external view returns (bool);
    function ownerOf(address avatar) external view returns (address);
    function avatarOf(address owner) external view returns (address);
    function newAvatar() external returns (address);
    function getAvatar(address owner) external returns (address);
    // avatar whitelisted calls
    function whitelistedAvatarCalls(address target, bytes4 functionSig) external view returns(bool);

    function setPool(address newPool) external;
    function setWhitelistAvatarCall(address target, bytes4 functionSig, bool list) external;
}

// File: contracts/bprotocol/interfaces/IComptroller.sol

pragma solidity 0.5.16;

interface IComptroller {

    // ComptrollerLensInterface.sol
    // =============================
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (address);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (address[] memory);
    function compAccrued(address) external view returns (uint);
    // Claim all the COMP accrued by holder in all markets
    function claimComp(address holder) external;
    // Claim all the COMP accrued by holder in specific markets
    function claimComp(address holder, address[] calldata cTokens) external;
    function claimComp(address[] calldata holders, address[] calldata cTokens, bool borrowers, bool suppliers) external;

    // Public storage defined in Comptroller contract
    // ===============================================
    function checkMembership(address account, address cToken) external view returns (bool);
    function closeFactorMantissa() external returns (uint256);
    function liquidationIncentiveMantissa() external returns (uint256);



    // Public/external functions defined in Comptroller contract
    // ==========================================================
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);

    function mintAllowed(address cToken, address minter, uint mintAmount) external returns (uint);
    function borrowAllowed(address cToken, address borrower, uint borrowAmount) external returns (uint);

    function getAllMarkets() external view returns (address[] memory);

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint actualRepayAmount) external view returns (uint, uint);

    function compBorrowState(address cToken) external returns (uint224, uint32);
    function compSupplyState(address cToken) external returns (uint224, uint32);
}

// File: contracts/bprotocol/lib/CarefulMath.sol

pragma solidity 0.5.16;

/**
  * @title Careful Math
  * @author Compound
  * @notice COPY TAKEN FROM COMPOUND FINANCE
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// File: contracts/bprotocol/lib/Exponential.sol

pragma solidity 0.5.16;


/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }


    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }


    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }

    // New functions added by BProtocol
    // =================================

    function mulTrucate(uint a, uint b) internal pure returns (uint) {
        return mul_(a, b) / expScale;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/bprotocol/interfaces/CTokenInterfaces.sol

pragma solidity 0.5.16;


contract CTokenInterface {
    /* ERC20 */
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /* User Interface */
    function isCToken() external view returns (bool);
    function underlying() external view returns (IERC20);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

}

contract ICToken is CTokenInterface {

    /* User Interface */
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// Defined separate contract as `mint()` override with `.value()` has issues
contract ICErc20 is ICToken {
    function mint(uint mintAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);
}

contract ICEther is ICToken {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

contract IPriceOracle {
    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(CTokenInterface cToken) external view returns (uint);
}

// File: contracts/bprotocol/interfaces/IBToken.sol

pragma solidity 0.5.16;

interface IBToken {
    function cToken() external view returns (address);
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

// File: contracts/bprotocol/interfaces/IAvatar.sol

pragma solidity 0.5.16;

contract IAvatarERC20 {
    function transfer(address cToken, address dst, uint256 amount) external returns (bool);
    function transferFrom(address cToken, address src, address dst, uint256 amount) external returns (bool);
    function approve(address cToken, address spender, uint256 amount) public returns (bool);
}

contract IAvatar is IAvatarERC20 {
    function initialize(address _registry, address comp, address compVoter) external;
    function quit() external returns (bool);
    function canUntop() public returns (bool);
    function toppedUpCToken() external returns (address);
    function toppedUpAmount() external returns (uint256);
    function redeem(address cToken, uint256 redeemTokens, address payable userOrDelegatee) external returns (uint256);
    function redeemUnderlying(address cToken, uint256 redeemAmount, address payable userOrDelegatee) external returns (uint256);
    function borrow(address cToken, uint256 borrowAmount, address payable userOrDelegatee) external returns (uint256);
    function borrowBalanceCurrent(address cToken) external returns (uint256);
    function collectCToken(address cToken, address from, uint256 cTokenAmt) public;
    function liquidateBorrow(uint repayAmount, address cTokenCollateral) external payable returns (uint256);

    // Comptroller functions
    function enterMarket(address cToken) external returns (uint256);
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    function exitMarket(address cToken) external returns (uint256);
    function claimComp() external;
    function claimComp(address[] calldata bTokens) external;
    function claimComp(address[] calldata bTokens, bool borrowers, bool suppliers) external;
    function getAccountLiquidity() external view returns (uint err, uint liquidity, uint shortFall);
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// CEther
contract IAvatarCEther is IAvatar {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
}

// CErc20
contract IAvatarCErc20 is IAvatar {
    function mint(address cToken, uint256 mintAmount) external returns (uint256);
    function repayBorrow(address cToken, uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address cToken, address borrower, uint256 repayAmount) external returns (uint256);
}

contract ICushion {
    function liquidateBorrow(uint256 underlyingAmtToLiquidate, uint256 amtToDeductFromTopup, address cTokenCollateral) external payable returns (uint256);    
    function canLiquidate() external returns (bool);
    function untop(uint amount) external;
    function toppedUpAmount() external returns (uint);
    function remainingLiquidationAmount() external returns(uint);
    function getMaxLiquidationAmount(address debtCToken) public returns (uint256);
}

contract ICushionCErc20 is ICushion {
    function topup(address cToken, uint256 topupAmount) external;
}

contract ICushionCEther is ICushion {
    function topup() external payable;
}

// File: contracts/bprotocol/interfaces/IBComptroller.sol

pragma solidity 0.5.16;

interface IBComptroller {
    function isCToken(address cToken) external view returns (bool);
    function isBToken(address bToken) external view returns (bool);
    function c2b(address cToken) external view returns (address);
    function b2c(address bToken) external view returns (address);
}

// File: contracts/bprotocol/scoring/BScore.sol

pragma solidity 0.5.16;









contract BScore is ScoringMachine, Exponential {

    IRegistry public registry;
    IComptroller public comptroller;
    string private constant parent = "BScore";
    uint public startDate;
    uint public endDate;

    // cToken => uint (supplyMultiplier)
    mapping(address => uint) public supplyMultiplier;
    // cToken => uint (borrowMultiplier)
    mapping(address => uint) public borrowMultiplier;

    // cToken => Snapshot{exchangeRate, supplyIndex, borrowIndex}
    mapping(address => Snapshot) public snapshot;
    mapping(address => Snapshot) public initialSnapshot;

    struct Snapshot {
        uint exchangeRate;
        uint224 supplyIndex;
        uint224 borrowIndex;
    }

    modifier onlyAvatar() {
        require(registry.doesAvatarExist(msg.sender), "Score: not-an-avatar");
        require(! IAvatar(msg.sender).quit(), "Score: avatar-quit");        
        _;
    }

    constructor(
        address _registry,
        uint _startDate,
        uint _endDate,
        address[] memory cTokens,
        uint[] memory sMultipliers,
        uint[] memory bMultipliers
    ) public {
        require(_endDate > now, "Score: end-date-not-in-future");

        registry = IRegistry(_registry);
        comptroller = IComptroller(registry.comptroller());

        startDate = _startDate;
        endDate = _endDate;
        for(uint i = 0; i < cTokens.length; i++) {
            require(cTokens[i] != address(0), "Score: cToken-address-is-zero");
            require(sMultipliers[i] > 0, "Score: supply-multiplier-is-zero");
            require(bMultipliers[i] > 0, "Score: borrow-multiplier-is-zero");

            supplyMultiplier[cTokens[i]] = sMultipliers[i];
            borrowMultiplier[cTokens[i]] = bMultipliers[i];
        }

        _updateIndex(cTokens, true);        
    }

    // Create Asset ID
    // ================
    function user(address _user) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, _user));
    }

    function debtAsset(address cToken) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, "debt", cToken));
    }

    function collAsset(address cToken) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, "coll", cToken));
    }

    // Update Score
    // =============
    function updateDebtScore(address _avatar, address cToken, int256 amount) external onlyAvatar {
        updateScore(user(_avatar), debtAsset(cToken), amount, now);
    }

    function updateCollScore(address _avatar, address cToken, int256 amount) external onlyAvatar {
        updateScore(user(_avatar), collAsset(cToken), amount, now);
    }

    function mul_(uint score, uint multiplier, uint224 index) internal pure returns (uint) {
        return mul_(mul_(score, multiplier), index);
    }

    function updateIndex(address[] calldata cTokens) external {
        _updateIndex(cTokens, false);        
    }

    function _updateIndex(address[] memory cTokens, bool init) internal {
        require(endDate > now, "Score: expired");
        for(uint i = 0 ; i < cTokens.length ; i++) {
            address cToken = cTokens[i];
            uint224 supplyIndex;
            uint224 borrowIndex;
            uint currExchangeRate = ICToken(cToken).exchangeRateCurrent();
            (supplyIndex,) = comptroller.compSupplyState(cToken);
            (borrowIndex,) = comptroller.compBorrowState(cToken);

            if(init) {
                initialSnapshot[cToken].exchangeRate = currExchangeRate;
                initialSnapshot[cToken].supplyIndex = supplyIndex;
                initialSnapshot[cToken].borrowIndex = borrowIndex;
            }
            else {
                snapshot[cToken].exchangeRate = currExchangeRate;
                snapshot[cToken].supplyIndex = supplyIndex;
                snapshot[cToken].borrowIndex = borrowIndex;
            }
        }
    }

    function _getDeltaSupplyIndex(address cToken) internal view returns (uint224 deltaSupplyIndex) {
        uint224 currSupplyIndex = snapshot[cToken].supplyIndex;
        uint deltaSupplyIndexForCToken = sub_(uint(currSupplyIndex), uint(initialSnapshot[cToken].supplyIndex));

        // NOTICE: supplyIndex takes cToken.totalSupply() which is in cToken quantity
        // We need the index normalized to underlying token quantity
        uint currExchangeRate = snapshot[cToken].exchangeRate;
        uint scaledIndex = mul_(deltaSupplyIndexForCToken, expScale);
        uint deltaSupplyIndexInUint = div_(scaledIndex, currExchangeRate);

        deltaSupplyIndex = safe224(deltaSupplyIndexInUint, "index-exceeds-224-bits");
    }

    function _getDeltaBorrowIndex(address cToken) internal view returns (uint224 deltaBorrowIndex) {
        uint224 currBorrowIndex = snapshot[cToken].borrowIndex;
        deltaBorrowIndex = safe224(
            sub_(uint(currBorrowIndex), uint(initialSnapshot[cToken].borrowIndex)),
            "unable-to-cast-to-uint224"
        );
        // NOTICE: borrowIndex is already normalized to underlying token quantity
    }

    function slashScore(address _user, address cToken) external {
        IBComptroller bComptroller = IBComptroller(registry.bComptroller());
        address _avatar = registry.avatarOf(_user);
        bool quit = IAvatar(_avatar).quit();
        IBToken bToken = IBToken(bComptroller.c2b(cToken));

        uint time = sub(start, 1 days);
        if(time < start) time = start;

        // Slash debtScore
        uint borrowBalB = quit ? 0 : bToken.borrowBalanceCurrent(_user);
        uint borrowBalScore = getCurrentBalance(user(_avatar), debtAsset(cToken));
        if(borrowBalB < borrowBalScore) {
            int256 debtRating = int256(sub(borrowBalScore, borrowBalB));
            updateScore(user(_avatar), debtAsset(cToken), (debtRating * -1), time);
        }

        // Slash collScore
        uint collBalB = quit ? 0 : bToken.balanceOfUnderlying(_user);
        uint collBalScore = getCurrentBalance(user(_avatar), collAsset(cToken));
        if(collBalB < collBalScore) {
            int256 collRating = int256(sub(collBalScore, collBalB));
            updateScore(user(_avatar), collAsset(cToken), (collRating * -1), time);
        }
    }

    // Get Score
    // ==========
    function getDebtScore(address _user, address cToken, uint256 time) public view returns (uint) {
        uint currTime = time > endDate ? endDate : time;
        address avatar = registry.avatarOf(_user);
        uint224 deltaBorrowIndex = _getDeltaBorrowIndex(cToken);
        uint score = getScore(user(avatar), debtAsset(cToken), currTime, startDate, 0);
        // (borrowMultiplier[cToken] * deltaBorrowIndex / 1e18) * score
        return mul_(div_(mul_(borrowMultiplier[cToken], deltaBorrowIndex), expScale), score);
    }

    function getDebtGlobalScore(address cToken, uint256 time) public view returns (uint) {
        uint currTime = time > endDate ? endDate : time;
        uint224 deltaBorrowIndex = _getDeltaBorrowIndex(cToken);
        uint score = getScore(GLOBAL_USER, debtAsset(cToken), currTime, startDate, 0);
        // (borrowMultiplier[cToken] * deltaBorrowIndex / 1e18) * score
        return mul_(div_(mul_(borrowMultiplier[cToken], deltaBorrowIndex), expScale), score);
    }

    function getCollScore(address _user, address cToken, uint256 time) public view returns (uint) {
        uint currTime = time > endDate ? endDate : time;
        address avatar = registry.avatarOf(_user);
        uint224 deltaSupplyIndex = _getDeltaSupplyIndex(cToken);
        uint score = getScore(user(avatar), collAsset(cToken), currTime, startDate, 0);
        // (supplyMultiplier[cToken] * deltaSupplyIndex / 1e18) * score
        return mul_(div_(mul_(supplyMultiplier[cToken], deltaSupplyIndex), expScale), score);
    }

    function getCollGlobalScore(address cToken, uint256 time) public view returns (uint) {
        uint currTime = time > endDate ? endDate : time;
        uint224 deltaSupplyIndex = _getDeltaSupplyIndex(cToken);
        uint score = getScore(GLOBAL_USER, collAsset(cToken), currTime, startDate, 0);
        // (supplyMultiplier[cToken] * deltaSupplyIndex / 1e18) * score
        return mul_(div_(mul_(supplyMultiplier[cToken], deltaSupplyIndex), expScale), score);
    }
}