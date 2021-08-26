/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.5.16;


// Copied from Compound/ExponentialNoError
/**
 * @title Exponential module for storing fixed-precision decimals
 * @author DeFil
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
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
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
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
}

interface Distributor {
    // The asset to be distributed
    function asset() external view returns (address);

    // Return the accrued amount of account based on stored data
    function accruedStored(address account) external view returns (uint);

    // Accrue and distribute for caller, but not actually transfer assets to the caller
    // returns the new accrued amount
    function accrue() external returns (uint);

    // Claim asset, transfer the given amount assets to receiver
    function claim(address receiver, uint amount) external returns (uint);
}

contract Redistributor is Distributor, ExponentialNoError {
    /**
     * @notice The superior Distributor contract
     */
    Distributor public superior;

    // The accrued amount of this address in superior Distributor
    uint public superiorAccruedAmount;

    // The initial accrual index
    uint internal constant initialAccruedIndex = 1e36;

    // The last accrued block number
    uint public accrualBlockNumber;

    // The last accrued index
    uint public globalAccruedIndex;

    // Total count of shares.
    uint internal totalShares;

    struct AccountState {
        /// @notice The share of account
        uint share;
        // The last accrued index of account
        uint accruedIndex;
        /// @notice The accrued but not yet transferred to account
        uint accruedAmount;
    }

    // The AccountState for each account
    mapping(address => AccountState) internal accountStates;

    /*** Events ***/
    // Emitted when dfl is accrued
    event Accrued(uint amount, uint globalAccruedIndex);

    // Emitted when distribute to a account
    event Distributed(address account, uint amount, uint accruedIndex);

    // Emitted when account claims asset
    event Claimed(address account, address receiver, uint amount);

    // Emitted when account transfer asset
    event Transferred(address from, address to, uint amount);

    constructor(Distributor superior_) public {
        // set superior
        superior = superior_;
        // init accrued index
        globalAccruedIndex = initialAccruedIndex;
    }

    function asset() external view returns (address) {
        return superior.asset();
    }

    // Return the accrued amount of account based on stored data
    function accruedStored(address account) external view returns(uint) {
        uint storedGlobalAccruedIndex;
        if (totalShares == 0) {
            storedGlobalAccruedIndex = globalAccruedIndex;
        } else {
            uint superiorAccruedStored = superior.accruedStored(address(this));
            uint delta = sub_(superiorAccruedStored, superiorAccruedAmount);

            Double memory ratio = fraction(delta, totalShares);
            Double memory doubleGlobalAccruedIndex = add_(Double({mantissa: globalAccruedIndex}), ratio);
            storedGlobalAccruedIndex = doubleGlobalAccruedIndex.mantissa;
        }

        (, uint instantAccountAccruedAmount) = accruedStoredInternal(account, storedGlobalAccruedIndex);
        return instantAccountAccruedAmount;
    }

    // Return the accrued amount of account based on stored data
    function accruedStoredInternal(address account, uint withGlobalAccruedIndex) internal view returns(uint, uint) {
        AccountState memory state = accountStates[account];

        Double memory doubleGlobalAccruedIndex = Double({mantissa: withGlobalAccruedIndex});
        Double memory doubleAccountAccruedIndex = Double({mantissa: state.accruedIndex});
        if (doubleAccountAccruedIndex.mantissa == 0 && doubleGlobalAccruedIndex.mantissa > 0) {
            doubleAccountAccruedIndex.mantissa = initialAccruedIndex;
        }

        Double memory deltaIndex = sub_(doubleGlobalAccruedIndex, doubleAccountAccruedIndex);
        uint delta = mul_(state.share, deltaIndex);

        return (delta, add_(state.accruedAmount, delta));
    }

    function accrueInternal() internal {
        uint blockNumber = getBlockNumber();
        if (accrualBlockNumber == blockNumber) {
            return;
        }

        uint newSuperiorAccruedAmount = superior.accrue();
        if (totalShares == 0) {
            accrualBlockNumber = blockNumber;
            return;
        }

        uint delta = sub_(newSuperiorAccruedAmount, superiorAccruedAmount);

        Double memory ratio = fraction(delta, totalShares);
        Double memory doubleAccruedIndex = add_(Double({mantissa: globalAccruedIndex}), ratio);

        // update globalAccruedIndex
        globalAccruedIndex = doubleAccruedIndex.mantissa;
        superiorAccruedAmount = newSuperiorAccruedAmount;
        accrualBlockNumber = blockNumber;

        emit Accrued(delta, doubleAccruedIndex.mantissa);
    }

    /**
     * @notice accrue and returns accrued stored of msg.sender
     */
    function accrue() external returns (uint) {
        accrueInternal();

        (, uint instantAccountAccruedAmount) = accruedStoredInternal(msg.sender, globalAccruedIndex);
        return instantAccountAccruedAmount;
    }

    function distributeInternal(address account) internal {
        (uint delta, uint instantAccruedAmount) = accruedStoredInternal(account, globalAccruedIndex);

        AccountState storage state = accountStates[account];
        state.accruedIndex = globalAccruedIndex;
        state.accruedAmount = instantAccruedAmount;

        // emit Distributed event
        emit Distributed(account, delta, globalAccruedIndex);
    }

    function claim(address receiver, uint amount) external returns (uint) {
        address account = msg.sender;

        // keep fresh
        accrueInternal();
        distributeInternal(account);

        AccountState storage state = accountStates[account];
        require(amount <= state.accruedAmount, "claim: insufficient value");

        // claim from superior
        require(superior.claim(receiver, amount) == amount, "claim: amount mismatch");

        // update storage
        state.accruedAmount = sub_(state.accruedAmount, amount);
        superiorAccruedAmount = sub_(superiorAccruedAmount, amount);

        emit Claimed(account, receiver, amount);

        return amount;
    }

    function claimAll() external {
        address account = msg.sender;

        // accrue and distribute
        accrueInternal();
        distributeInternal(account);

        AccountState storage state = accountStates[account];
        uint amount = state.accruedAmount;

        // claim from superior
        require(superior.claim(account, amount) == amount, "claim: amount mismatch");

        // update storage
        state.accruedAmount = 0;
        superiorAccruedAmount = sub_(superiorAccruedAmount, amount);

        emit Claimed(account, account, amount);
    }

    function transfer(address to, uint amount) external {
        address from = msg.sender;

        // keep fresh
        accrueInternal();
        distributeInternal(from);

        AccountState storage fromState = accountStates[from];
        uint actualAmount = amount;
        if (actualAmount == 0) {
            actualAmount = fromState.accruedAmount;
        }
        require(fromState.accruedAmount >= actualAmount, "transfer: insufficient value");

        AccountState storage toState = accountStates[to];

        // update storage
        fromState.accruedAmount = sub_(fromState.accruedAmount, actualAmount);
        toState.accruedAmount = add_(toState.accruedAmount, actualAmount);

        emit Transferred(from, to, actualAmount);
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
}

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PrivilegedRedistributor is Redistributor, Ownable {
    /// @notice A list of all valid members
    address[] public members;

    /// @notice Emitted when members changed
    event Changed(address[] newMembers, uint[] newPercentages);

    constructor(Distributor superior_) Redistributor(superior_) public {}

    function allMembers() external view returns (address[] memory, uint[] memory) {
        address[] memory storedMembers = members;

        uint[] memory percentages = new uint[](storedMembers.length);
        for (uint i = 0; i < storedMembers.length; i++) {
            percentages[i] = accountStates[storedMembers[i]].share;
        }

        return (storedMembers, percentages);
    }

    function memberState(address member) external view returns (uint, uint, uint) {
        AccountState memory state = accountStates[member];
        return (state.share, state.accruedIndex, state.accruedAmount);
    }

    /*** Admin Functions ***/

    /**
     * @notice Admin function to change members and their percentages
     */
    function _setPercentages(uint[] calldata newPercentages) external onlyOwner {
        uint sumNewPercentagesMantissa;
        for (uint i = 0; i < newPercentages.length; i++) {
            sumNewPercentagesMantissa = add_(sumNewPercentagesMantissa, newPercentages[i]);
        }
        // Check sum of new percentages equals 1
        require(sumNewPercentagesMantissa == mantissaOne, "_setPercentages: bad sum");

        // reference storage
        address[] storage storedMembers = members;
        require(storedMembers.length == newPercentages.length, "_setPercentages: bad length");

        // accrue first
        accrueInternal();

        // distribute to members if its percentage changes
        for (uint i = 0; i < storedMembers.length; i++) {
            AccountState storage state = accountStates[storedMembers[i]];
            distributeInternal(storedMembers[i]);
            // set new percentage for member
            state.share = newPercentages[i];
        }

        emit Changed(storedMembers, newPercentages);
    }

    /**
     * @notice Admin function to change members and their percentages
     */
    function _setMembers(address[] memory newMembers, uint[] memory newPercentages) public onlyOwner {
        require(newMembers.length == newPercentages.length, "_setMembers: bad length");

        uint sumNewPercentagesMantissa;
        for (uint i = 0; i < newPercentages.length; i++) {
            require(newPercentages[i] != 0, "_setMembers: bad percentage");
            sumNewPercentagesMantissa = add_(sumNewPercentagesMantissa, newPercentages[i]);
        }
        // Check sum of new percentages equals 1
        require(sumNewPercentagesMantissa == mantissaOne, "_setMembers: bad sum");

        // accrue first
        accrueInternal();

        // distribute for old members
        address[] storage storedMembers = members;
        for (uint i = 0; i < storedMembers.length; i++) {
            distributeInternal(storedMembers[i]);
            AccountState storage state = accountStates[storedMembers[i]];
            state.share = 0;
        }

        // clear old members
        storedMembers.length = 0;
        for (uint i = 0; i < newMembers.length; i++) {
            AccountState storage state = accountStates[newMembers[i]];
            accountStates[newMembers[i]] = AccountState({share: newPercentages[i], accruedIndex: globalAccruedIndex, accruedAmount: state.accruedAmount});

            storedMembers.push(newMembers[i]);
        }

        totalShares = mantissaOne;
        emit Changed(newMembers, newPercentages);
    }
}