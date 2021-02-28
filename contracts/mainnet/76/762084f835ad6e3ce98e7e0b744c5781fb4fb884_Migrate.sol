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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/ownership/Ownable.sol

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

// File: contracts/bprotocol/governance/GovernanceExecutor.sol

pragma solidity 0.5.16;



contract GovernanceExecutor is Ownable {

    IRegistry public registry;
    uint public delay;
    // newPoolAddr => requestTime
    mapping(address => uint) public poolRequests;
    // target => function => list => requestTime
    mapping(address => mapping(bytes4 => mapping(bool => uint))) whitelistRequests;
    address public governance;

    event RequestPoolUpgrade(address indexed pool);
    event PoolUpgraded(address indexed pool);

    event RequestSetWhitelistCall(address indexed target, bytes4 functionSig, bool list);
    event WhitelistCallUpdated(address indexed target, bytes4 functionSig, bool list);

    constructor(address registry_, uint delay_) public {
        registry = IRegistry(registry_);
        delay = delay_;
    }

    /**
     * @dev Sets governance address
     * @param governance_ Address of the governance
     */
    function setGovernance(address governance_) external onlyOwner {
        require(governance == address(0), "governance-already-set");
        governance = governance_;
    }

    /**
     * @dev Transfer admin of BCdpManager
     * @param owner New admin address
     */
    function doTransferAdmin(address owner) external {
        require(msg.sender == governance, "unauthorized");
        registry.transferOwnership(owner);
    }

    /**
     * @dev Request pool contract upgrade
     * @param pool Address of new pool contract
     */
    function reqUpgradePool(address pool) external onlyOwner {
        poolRequests[pool] = now;
        emit RequestPoolUpgrade(pool);
    }

    /**
     * @dev Drop upgrade pool request
     * @param pool Address of pool contract
     */
    function dropUpgradePool(address pool) external onlyOwner {
        delete poolRequests[pool];
    }

    /**
     * @dev Execute pool contract upgrade after delay
     * @param pool Address of the new pool contract
     */
    function execUpgradePool(address pool) external {
        uint reqTime = poolRequests[pool];
        require(reqTime != 0, "request-not-valid");
        require(now >= add(reqTime, delay), "delay-not-over");

        delete poolRequests[pool];
        registry.setPool(pool);
        emit PoolUpgraded(pool);
    }

    /**
     * @dev Request whitelist upgrade
     * @param target Address of new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function reqSetWhitelistCall(address target, bytes4 functionSig, bool list) external onlyOwner {
        whitelistRequests[target][functionSig][list] = now;
        emit RequestSetWhitelistCall(target, functionSig, list);
    }

    /**
     * @dev Drop upgrade whitelist request
     * @param target Address of new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function dropWhitelistCall(address target, bytes4 functionSig, bool list) external onlyOwner {
        delete whitelistRequests[target][functionSig][list];
    }

    /**
     * @dev Execute pool contract upgrade after delay
     * @param target Address of the new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function execSetWhitelistCall(address target, bytes4 functionSig, bool list) external {
        uint reqTime = whitelistRequests[target][functionSig][list];
        require(reqTime != 0, "request-not-valid");
        require(now >= add(reqTime, delay), "delay-not-over");

        delete whitelistRequests[target][functionSig][list];
        registry.setWhitelistAvatarCall(target, functionSig, list);
        emit WhitelistCallUpdated(target, functionSig, list);
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "overflow");
        return c;
    }
}

// File: contracts/bprotocol/scoring/IBTokenScore.sol

pragma solidity 0.5.16;

interface IBTokenScore {
    function start() external view returns (uint);
    function spin() external;

    function getDebtScore(address user, address cToken, uint256 time) external view returns (uint);
    function getCollScore(address user, address cToken, uint256 time) external view returns (uint);

    function getDebtGlobalScore(address cToken, uint256 time) external view returns (uint);
    function getCollGlobalScore(address cToken, uint256 time) external view returns (uint);

    function endDate() external view returns(uint);
}

// File: contracts/bprotocol/connector/JarConnector.sol

pragma solidity 0.5.16;


/**
 * @notice B.Protocol Compound connector contract, which is used by Jar contract
 */
contract JarConnector {

    IBTokenScore public score;
    address[] public cTokens;

    constructor(address[] memory _cTokens, address _score) public {
        score = IBTokenScore(_score);

        cTokens = _cTokens;
    }

    function getUserScore(address user) external view returns (uint) {
        return _getTotalUserScore(user, now);
    }

    // this ignores the comp speed progress, but should be close enough
    function getUserScoreProgressPerSec(address user) external view returns (uint) {
        return _getTotalUserScore(user, now + 1) - _getTotalUserScore(user, now);
    }

    function getGlobalScore() external view returns (uint) {
        return _getTotalGlobalScore(now);
    }

    function _getTotalUserScore(address user, uint time) internal view returns (uint256) {
        uint totalScore = 0;
        for(uint i = 0; i < cTokens.length; i++) {
            uint debtScore = score.getDebtScore(user, cTokens[i], time);
            uint collScore = score.getCollScore(user, cTokens[i], time);
            totalScore = add_(add_(totalScore, debtScore), collScore);
        }
        return totalScore;
    }

    function _getTotalGlobalScore(uint time) internal view returns (uint256) {
        uint totalScore = 0;
        for(uint i = 0; i < cTokens.length; i++) {
            uint debtScore = score.getDebtGlobalScore(cTokens[i], time);
            uint collScore = score.getCollGlobalScore(cTokens[i], time);
            totalScore = add_(add_(totalScore, debtScore), collScore);
        }
        return totalScore;
    }

    function spin() external {
        require(score.endDate() < now, "too-early");
        score.spin();
    }

    function add_(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "overflow");
        return c;
    }
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

// File: contracts/bprotocol/governance/Migrate.sol

pragma solidity 0.5.16;





contract Migrate is Exponential {

    event NewProposal(uint indexed proposalId, address newOwner);
    event Voted(uint indexed proposalId, address user, uint score);
    event VoteCancelled(uint indexed proposalId, address user, uint score);
    event Queued(uint indexed proposalId);
    event Executed(uint indexed proposalId);

    struct Proposal {
        uint forVotes;
        uint eta;
        address newOwner;
        mapping (address => bool) voted; // user => voted
    }

    uint public constant DELAY = 2 days;

    JarConnector public jarConnector;
    IRegistry public registry;
    GovernanceExecutor public executor;

    Proposal[] public proposals;

    constructor(
        JarConnector jarConnector_,
        IRegistry registry_,
        GovernanceExecutor executor_
    ) public {
        jarConnector = jarConnector_;
        registry = registry_;
        executor = executor_;
    }

    function propose(address newOwner) external returns (uint) {
        require(newOwner != address(0), "newOwner-cannot-be-zero");

        Proposal memory proposal = Proposal({
            forVotes: 0,
            eta: 0,
            newOwner: newOwner
        });

        uint proposalId = sub_(proposals.push(proposal), uint(1));
        emit NewProposal(proposalId, newOwner);

        return proposalId;
    }

    function vote(uint proposalId) external {
        address user = msg.sender;
        Proposal storage proposal = proposals[proposalId];
        require(proposal.newOwner != address(0), "proposal-not-exist");
        require(! proposal.voted[user], "already-voted");
        require(registry.doesAvatarExistFor(user), "avatar-does-not-exist");

        uint score = jarConnector.getUserScore(user);
        proposal.forVotes = add_(proposal.forVotes, score);
        proposal.voted[user] = true;

        emit Voted(proposalId, user, score);
    }

    function cancelVote(uint proposalId) external {
        address user = msg.sender;
        Proposal storage proposal = proposals[proposalId];
        require(proposal.newOwner != address(0), "proposal-not-exist");
        require(proposal.voted[user], "not-voted");
        require(registry.doesAvatarExistFor(user), "avatar-does-not-exist");

        uint score = jarConnector.getUserScore(user);
        proposal.forVotes = sub_(proposal.forVotes, score);
        proposal.voted[user] = false;

        emit VoteCancelled(proposalId, user, score);
    }

    function queueProposal(uint proposalId) external {
        uint quorum = add_(jarConnector.getGlobalScore() / 2, uint(1)); // 50%
        Proposal storage proposal = proposals[proposalId];
        require(proposal.eta == 0, "already-queued");
        require(proposal.newOwner != address(0), "proposal-not-exist");
        require(proposal.forVotes >= quorum, "quorum-not-passed");

        proposal.eta = now + DELAY;

        emit Queued(proposalId);
    }

    function executeProposal(uint proposalId) external {
        Proposal memory proposal = proposals[proposalId];
        require(proposal.eta > 0, "proposal-not-queued");
        require(now >= proposal.eta, "delay-not-over");

        executor.doTransferAdmin(proposal.newOwner);

        emit Executed(proposalId);
    }
}