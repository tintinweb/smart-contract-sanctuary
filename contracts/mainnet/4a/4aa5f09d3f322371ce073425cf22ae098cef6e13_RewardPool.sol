/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.5.16;


contract RewardPoolDelegationStorage {
    // The FILST token address
    address public filstAddress;

    // The eFIL token address
    address public efilAddress;

    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active implementation
    */
    address public implementation;

    /**
    * @notice Pending implementation
    */
    address public pendingImplementation;
}

interface IRewardCalculator {
    function calculate(uint filstAmount, uint fromBlockNumber) external view returns (uint);
}

interface IRewardStrategy {
    // returns allocated result
    function allocate(address staking, uint rewardAmount) external view returns (uint stakingPart, address[] memory others, uint[] memory othersParts);
}

interface IFilstManagement {
    function getTotalMintedAmount() external view returns (uint);
    function getMintedAmount(string calldata miner) external view returns (uint);
}

contract RewardPoolStorage is RewardPoolDelegationStorage {
    // The IFilstManagement
    IFilstManagement public management;

    // The IRewardStrategy
    IRewardStrategy public strategy;

    // The IRewardCalculator contract
    IRewardCalculator public calculator;

    // The address of FILST Staking contract
    address public staking;

    // The last accrued block number
    uint public accrualBlockNumber;

    // The accrued reward for each participant
    mapping(address => uint) public accruedRewards;

    struct Debt {
        // accrued index of debts 
        uint accruedIndex;

        // accrued debts
        uint accruedAmount;

        // The last time the miner repay debts
        uint lastRepaymentBlock;
    }

    // The last accrued index of debts
    uint public debtAccruedIndex;

    // The accrued debts for each miner
    // minerId -> Debt
    mapping(string => Debt) public minerDebts;
}

contract RewardPoolDelegator is RewardPoolDelegationStorage {
    /**
      * @notice Emitted when pendingImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingImplementation is accepted, which means implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when pendingAdmin is changed
      */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
      * @notice Emitted when pendingAdmin is accepted, which means admin is updated
      */
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(address filstAddress_, address efilAddress_) public {
        filstAddress = filstAddress_;
        efilAddress = efilAddress_;

        // Set admin to caller
        admin = msg.sender;
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) external {
        require(msg.sender == admin, "admin check");

        address oldPendingImplementation = pendingImplementation;
        pendingImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
    * @notice Accepts new implementation. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    */
    function _acceptImplementation() external {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "pendingImplementation check");

        // Save current values for inclusion in log
        address oldImplementation = implementation;
        address oldPendingImplementation = pendingImplementation;

        implementation = pendingImplementation;
        pendingImplementation = address(0);

        emit NewImplementation(oldImplementation, implementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingImplementation);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "admin check");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "pendingAdmin check");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }


    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    function () payable external {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
              let free_mem_ptr := mload(0x40)
              returndatacopy(free_mem_ptr, 0, returndatasize)

              switch success
              case 0 { revert(free_mem_ptr, returndatasize) }
              default { return(free_mem_ptr, returndatasize) }
        }
    }
}

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

contract RewardPool is RewardPoolStorage, Distributor, ExponentialNoError {
    // The initial accrual index
    uint internal constant initialAccruedIndex = 1e36;

    /*** Events ***/

    // Emitted when accrued rewards
    event Accrued(uint stakingPart, address[] others, uint[] othersParts, uint debtAccruedIndex);

    // Emitted when claimed rewards
    event Claimed(address account, address receiver, uint amount);

    // Emitted when distributed debt to miner 
    event DistributedDebt(string miner, uint debtDelta, uint accruedIndex);

    // Emitted when repayment happend
    event Repayment(string miner, address repayer, uint amount);

    // Emitted when account transfer rewards
    event Transferred(address from, address to, uint amount);

    // Emitted when strategy is changed
    event StrategyChanged(IRewardStrategy oldStrategy, IRewardStrategy newStrategy);

    // Emitted when calcaultor is changed
    event CalculatorChanged(IRewardCalculator oldCalculator, IRewardCalculator newCalculator);

    // Emitted when staking is changed
    event StakingChanged(address oldStaking, address newStaking);

    // Emitted when management is changed
    event ManagementChanged(IFilstManagement oldManagement, IFilstManagement newManagement);

    // Emitted when liquditity is added
    event LiqudityAdded(address benefactor, address admin, uint addAmount);

    constructor() public { }

    function asset() external view returns (address) {
        return efilAddress;
    }

    // Return the accrued reward of account based on stored data
    function accruedStored(address account) external view returns (uint) {
        if (accrualBlockNumber == getBlockNumber() || Staking(staking).totalDeposits() == 0) {
            return accruedRewards[account];
        }

        uint totalFilst = management.getTotalMintedAmount();
        // calculate rewards
        uint deltaRewards = calculator.calculate(totalFilst, accrualBlockNumber);

        // allocate rewards
        (uint stakingPart, address[] memory others, uint[] memory othersParts) = strategy.allocate(staking, deltaRewards);
        require(others.length == othersParts.length, "IRewardStrategy.allocalte: others length mismatch");

        if (staking == account) {
            return add_(accruedRewards[staking], stakingPart);
        } else {
            // add accrued rewards for others
            uint sumAllocation = stakingPart;
            uint accountAccruedReward = accruedRewards[account];

            for (uint i = 0; i < others.length; i ++) {
                sumAllocation = add_(sumAllocation, othersParts[i]);
                if (others[i] == account) {
                    accountAccruedReward = add_(accountAccruedReward, othersParts[i]);
                }
            }
            require(sumAllocation == deltaRewards, "sumAllocation mismatch");

            return accountAccruedReward;
        }
    }

    // Accrue and distribute for caller, but not actually transfer rewards to the caller
    // returns the new accrued amount
    function accrue() public returns (uint) {
        uint blockNumber = getBlockNumber();
        if (accrualBlockNumber == blockNumber) {
            return accruedRewards[msg.sender];
        }

        if (Staking(staking).totalDeposits() == 0) {
            accrualBlockNumber = blockNumber;
            return accruedRewards[msg.sender];
        }

        // total number of FILST that participates in dividends
        uint totalFilst = management.getTotalMintedAmount();
        // calculate rewards
        uint deltaRewards = calculator.calculate(totalFilst, accrualBlockNumber);
        // allocate rewards
        (uint stakingPart, address[] memory others, uint[] memory othersParts) = strategy.allocate(staking, deltaRewards);
        require(others.length == othersParts.length, "IRewardStrategy.allocalte: others length mismatch");

        // add accrued rewards for staking
        accruedRewards[staking] = add_(accruedRewards[staking], stakingPart);

        // add accrued rewards for others
        uint sumAllocation = stakingPart;
        for (uint i = 0; i < others.length; i ++) {
            sumAllocation = add_(sumAllocation, othersParts[i]);
            accruedRewards[others[i]] = add_(accruedRewards[others[i]], othersParts[i]);
        }
        require(sumAllocation == deltaRewards, "sumAllocation mismatch");

        // accure debts
        accureDebtInternal(deltaRewards);

        // update accrualBlockNumber
        accrualBlockNumber = blockNumber;

        // emint event
        emit Accrued(stakingPart, others, othersParts, debtAccruedIndex);

        return accruedRewards[msg.sender];
    }

    function accureDebtInternal(uint deltaDebts) internal {
        // require(accrualBlockNumber == getBlockNumber(), "freshness check");

        uint totalFilst = management.getTotalMintedAmount();
        Double memory ratio = fraction(deltaDebts, totalFilst);
        Double memory doubleAccruedIndex = add_(Double({mantissa: debtAccruedIndex}), ratio);

        // update debtAccruedIndex
        debtAccruedIndex = doubleAccruedIndex.mantissa;
    }


    // Return the accrued debts of miner based on stored data
    function accruedDebtStored(string calldata miner) external view returns(uint) {
        uint storedGlobalAccruedIndex;
        if (accrualBlockNumber == getBlockNumber() || Staking(staking).totalDeposits() == 0) {
            storedGlobalAccruedIndex = debtAccruedIndex;
        } else {
            uint totalFilst = management.getTotalMintedAmount();
            uint deltaDebts = calculator.calculate(totalFilst, accrualBlockNumber);
            
            Double memory ratio = fraction(deltaDebts, totalFilst);
            Double memory doubleAccruedIndex = add_(Double({mantissa: debtAccruedIndex}), ratio);
            storedGlobalAccruedIndex = doubleAccruedIndex.mantissa;
        }

        (, uint instantAccruedAmount) = accruedDebtStoredInternal(miner, storedGlobalAccruedIndex);
        return instantAccruedAmount;
    }

    // Return the accrued debt of miner based on stored data
    function accruedDebtStoredInternal(string memory miner, uint withDebtAccruedIndex) internal view returns(uint, uint) {
        Debt memory debt = minerDebts[miner];

        Double memory doubleDebtAccruedIndex = Double({mantissa: withDebtAccruedIndex});
        Double memory doubleMinerAccruedIndex = Double({mantissa: debt.accruedIndex});
        if (doubleMinerAccruedIndex.mantissa == 0 && doubleDebtAccruedIndex.mantissa > 0) {
            doubleMinerAccruedIndex.mantissa = initialAccruedIndex;
        }

        uint minerMintedAmount = management.getMintedAmount(miner);

        Double memory deltaIndex = sub_(doubleDebtAccruedIndex, doubleMinerAccruedIndex);
        uint delta = mul_(minerMintedAmount, deltaIndex);

        return (delta, add_(debt.accruedAmount, delta));
    }

    // accrue and distribute debt for given miner
    function accrue(string memory miner) public {
        accrue();
        distributeDebtInternal(miner);
    }

    function distributeDebtInternal(string memory miner) internal {
        (uint delta, uint instantAccruedAmount) = accruedDebtStoredInternal(miner, debtAccruedIndex);

        Debt storage debt = minerDebts[miner];
        debt.accruedIndex = debtAccruedIndex;
        debt.accruedAmount = instantAccruedAmount;

        // emit Distributed event
        emit DistributedDebt(miner, delta, debtAccruedIndex);
    }

    // Claim rewards, transfer given amount rewards to receiver
    function claim(address receiver, uint amount) external returns (uint) {
        address account = msg.sender;

        // keep fresh
        accrue();

        uint accruedReward = accruedRewards[account];
        require(accruedReward >= amount, "Insufficient value");

        // transfer reward to receiver
        transferRewardOut(receiver, amount);

        // update storage
        accruedRewards[account] = sub_(accruedReward, amount);

        emit Claimed(account, receiver, amount);

        return amount;
    }

    // Claim all accrued rewards
    function claimAll() external returns (uint) {
        address account = msg.sender;

        // keep fresh
        accrue();

        uint accruedReward = accruedRewards[account];

        // transfer
        transferRewardOut(account, accruedReward);

        // update storage
        accruedRewards[account] = 0;

        emit Claimed(account, account, accruedReward);
    }

    function transferRewardOut(address account, uint amount) internal {
        EIP20Interface efil = EIP20Interface(efilAddress);
        uint remaining = efil.balanceOf(address(this));
        require(remaining >= amount, "Insufficient cash");

        efil.transfer(account, amount);
    }

    // repay given amount of debts for miner
    function repayDebt(string calldata miner, uint amount) external {
        address repayer = msg.sender;

        // keep fresh (distribute debt for miner)
        accrue(miner);

        // reference storage
        Debt storage debt = minerDebts[miner];

        uint actualAmount = amount;
        if (actualAmount > debt.accruedAmount) {
            actualAmount = debt.accruedAmount;
        }

        EIP20Interface efil = EIP20Interface(efilAddress);
        require(efil.transferFrom(repayer, address(this), actualAmount), "transferFrom failed");

        debt.accruedAmount = sub_(debt.accruedAmount, actualAmount);
        debt.lastRepaymentBlock = getBlockNumber();

        emit Repayment(miner, repayer, actualAmount);
    }

    function transfer(address to, uint amount) external {
        address from = msg.sender;

        // keep fresh
        accrue();

        uint actualAmount = amount;
        if (actualAmount == 0) {
            actualAmount = accruedRewards[from];
        }
        require(accruedRewards[from] >= actualAmount, "Insufficient value");

        // update storage
        accruedRewards[from] = sub_(accruedRewards[from], actualAmount);
        accruedRewards[to] = add_(accruedRewards[to], actualAmount);

        emit Transferred(from, to, actualAmount);
    }
    
    /*** Admin Functions ***/

    // set management contract
    function setManagement(IFilstManagement newManagement) external {
        require(msg.sender == admin, "admin check");
        require(address(newManagement) != address(0), "Invalid newManagement");

        if (debtAccruedIndex == 0) {
            debtAccruedIndex = initialAccruedIndex;
        }

        // save old for event
        IFilstManagement oldManagement = management;
        // update
        management = newManagement;

        emit ManagementChanged(oldManagement, newManagement);
    }

    // set strategy contract
    function setStrategy(IRewardStrategy newStrategy) external {
        require(msg.sender == admin, "admin check");
        require(address(newStrategy) != address(0), "Invalid newStrategy");

        // save old for event
        IRewardStrategy oldStrategy = strategy;
        // update
        strategy = newStrategy;

        emit StrategyChanged(oldStrategy, newStrategy);
    }

    // set calculator contract
    function setCalculator(IRewardCalculator newCalculator) external {
        require(msg.sender == admin, "admin check");
        require(address(newCalculator) != address(0), "Invalid newCalculator");

        // save old for event
        IRewardCalculator oldCalculator = calculator;
        // update
        calculator = newCalculator;

        emit CalculatorChanged(oldCalculator, newCalculator);
    }

    // set staking contract
    function setStaking(address newStaking) external {
        require(msg.sender == admin, "admin check");
        require(address(Staking(newStaking).superior()) == address(this), "Staking superior mismatch");
        require(Staking(newStaking).property() == filstAddress, "Staking property mismatch");
        require(Staking(newStaking).asset() == efilAddress, "Staking asset mismatch");

        // save old for event
        address oldStaking = staking;
        // update
        staking = newStaking;

        emit StakingChanged(oldStaking, newStaking);
    }

    // add eFIL to pool
    function addLiqudity(uint amount) external {
        // transfer in
        require(EIP20Interface(efilAddress).transferFrom(msg.sender, address(this), amount), "transfer in failed");
        // added accrued rewards to admin
        accruedRewards[admin] = add_(accruedRewards[admin], amount);

        emit LiqudityAdded(msg.sender, admin, amount);
    }

    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    function _become(RewardPoolDelegator delegator) public {
        require(msg.sender == delegator.admin(), "only delegator admin can change implementation");
        delegator._acceptImplementation();
    }
}