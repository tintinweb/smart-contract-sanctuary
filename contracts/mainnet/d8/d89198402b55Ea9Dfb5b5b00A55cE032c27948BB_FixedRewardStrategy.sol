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

// Copied from compound/EIP20Interface
/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// Copied from compound/EIP20NonStandardInterface
/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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

contract Staking is Redistributor {
    // The token to deposit
    address public property;

    /*** Events ***/
    // Event emitted when new property tokens is deposited
    event Deposit(address account, uint amount);

    // Event emitted when new property tokens is withdrawed
    event Withdraw(address account, uint amount);

    constructor(address property_, Distributor superior_) Redistributor(superior_) public {
        property = property_;
    }

    function totalDeposits() external view returns (uint) {
        return totalShares;
    }

    function accountState(address account) external view returns (uint, uint, uint) {
        AccountState memory state = accountStates[account];
        return (state.share, state.accruedIndex, state.accruedAmount);
    }

    // Deposit property tokens
    function deposit(uint amount) external returns (uint) {
        address account = msg.sender;

        // accrue & distribute
        accrueInternal();
        distributeInternal(account);

        // transfer property token in
        uint actualAmount = doTransferIn(account, amount);

        // update storage
        AccountState storage state = accountStates[account];
        totalShares = add_(totalShares, actualAmount);
        state.share = add_(state.share, actualAmount);

        emit Deposit(account, actualAmount);

        return actualAmount;
    }

    // Withdraw property tokens
    function withdraw(uint amount) external returns (uint) {
        address account = msg.sender;
        AccountState storage state = accountStates[account];
        require(state.share >= amount, "withdraw: insufficient value");

        // accrue & distribute
        accrueInternal();
        distributeInternal(account);

        // decrease total deposits
        totalShares = sub_(totalShares, amount);
        state.share = sub_(state.share, amount);

        // transfer property tokens back to account
        doTransferOut(account, amount);

        emit Withdraw(account, amount);

        return amount;
    }

    /*** Safe Token ***/

    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(property);
        uint balanceBefore = EIP20Interface(property).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(property).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    function doTransferOut(address to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(property);
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}

contract FixedRewardStrategy is ExponentialNoError {
    // Represents percent of staked FILST under which the reward will be split
    uint internal constant splitThreshold = 0.6e18; // 60%
    // If split, take 60% for staking
    uint internal constant stakingPartInPercentage = 0.6e18; // 60%
    // If split, take 30% for repurchase
    uint internal constant repurchasePartInPercentage = 0.3e18; // 30%
    // If split, take 10% for safeguardFund
    uint internal constant safeguardPartInPercentage = 0.1e18; // 10%

    address public filstAddress;
    address public repurchase;
    address public safeguardFund;

    constructor(address _filstAddress, address _repurchase, address _safeguardFund) public{
        filstAddress = _filstAddress;
        repurchase = _repurchase;
        safeguardFund = _safeguardFund;
    }

    function allocate(Staking staking, uint rewardAmount) external view returns (uint stakingPart, address[] memory others, uint[] memory othersParts) {
        require(staking.property() == filstAddress, "Staking.property mismatch");

        uint totalSupply = EIP20Interface(filstAddress).totalSupply();
        uint totalDeposits = staking.totalDeposits();

        Exp memory stakingRatio = div_(Exp({mantissa: totalDeposits}), Exp({mantissa: totalSupply}));
        if (greaterThanExp(stakingRatio, Exp({mantissa: splitThreshold}))) {
            stakingPart = rewardAmount;
            others = new address[](0);
            othersParts = new uint[](0);
        } else {
            stakingPart = div_(mul_(rewardAmount, stakingPartInPercentage), mantissaOne);

            others = new address[](2);
            others[0] = repurchase;
            others[1] = safeguardFund;

            othersParts = new uint[](2);
            othersParts[0] = div_(mul_(rewardAmount, repurchasePartInPercentage), mantissaOne);
            othersParts[1] = sub_(sub_(rewardAmount, stakingPart), othersParts[0]);
        }
    }
}