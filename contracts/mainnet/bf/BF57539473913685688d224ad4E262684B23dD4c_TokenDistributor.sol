// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {AddressProvider} from "../core/AddressProvider.sol";
import {ACLTrait} from "../core/ACLTrait.sol";
import {AccountMining} from "../core/AccountMining.sol";
import {GearToken} from "../tokens/GearToken.sol";
import {IGearToken} from "../interfaces/IGearToken.sol";
import {StepVesting} from "../tokens/Vesting.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";



contract TokenDistributor is ACLTrait {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum VotingPower {
        A, // A-type voting power & A-type vesting parameters
        B, // B-type voting power & B-type vesting parameters
        ZERO_VOTING_POWER // zero voting power & B-type vesting parameters
    }

    struct TokenShare {
        address holder; // address of contributor wallet,
        uint256 amount; // amount in tokens which should be transferred to contributor
        bool isCompany; // flag, which used for contributor B only, If set, the voting contract has zero voting power.
    }

    struct VestingContract {
        address contractAddress; // vesting contract address
        VotingPower votingPower; // enum for voting power(0 means "A", 1 means "B" and 2 means "ZERO VOTING")
    }

    address treasury; // treasury wallet address

    struct TokenDistributionOpts {
        TokenShare[] contributorsA;
        TokenShare[] contributorsB;
        uint256 treasuryAmount; // amount of tokens which should be transferred to Treasury wallet
        address accountMiner;
        uint256 accountsToBeMined; // Quantity of accounts to be mined
        address testersAirdrop;
        uint256 airdropAmount;
    }

    // Steps for StepVestring contract
    uint256 public constant steps = 10_000;

    // GEAR token
    GearToken public gearToken;

    // Address of master contract which will be cloned
    address public masterVestingContract;

    // Mapping contributor => vesting contracts
    mapping(address => VestingContract) public vestingContracts;

    // Contributors set
    EnumerableSet.AddressSet private contributorsSet;

    // Voting weights
    uint256 public weightA;
    uint256 public weightB;

    // Default voting weights
    uint256 public constant defaultWeightA = 25_00;
    uint256 public constant defaultWeightB = 12_50;

    // emits each time when voting power weights were updated
    event NewWeights(uint256 weightA, uint256 weightB);

    // emits each time when new vesting contract is deployed
    event NewVestingContract(
        address indexed holder,
        address indexed vestingContract,
        VotingPower votingPower
    );

    event VestingContractHolderUpdate(
        address indexed vestingContract,
        address indexed prevHolder,
        address indexed newHolder
    );

    /// @param addressProvider address of Address provider
    constructor(AddressProvider addressProvider)
        ACLTrait(address(addressProvider))
    {
        gearToken = GearToken(addressProvider.getGearToken()); // T:[TD-1]
        treasury = addressProvider.getTreasuryContract();
        _updateVotingWeights(defaultWeightA, defaultWeightB); // T:[TD-1]
    }

    /// @dev Deploys vesting contracts and distributes tokens
    /// @param opts - struct which describes token distribution
    function distributeTokens(TokenDistributionOpts calldata opts)
        external
        configuratorOnly // T:[TD-2]
    {
        for (uint256 i = 0; i < opts.contributorsA.length; i++) {
            _deployVestingContract(opts.contributorsA[i], VotingPower.A); // T:[TD-3]
        }

        for (uint256 i = 0; i < opts.contributorsB.length; i++) {
            _deployVestingContract(
                opts.contributorsB[i],
                opts.contributorsB[i].isCompany
                    ? VotingPower.ZERO_VOTING_POWER
                    : VotingPower.B
            ); // T:[TD-3]
        }

        AccountMining am = AccountMining(opts.accountMiner);
        //        accountMining = new AccountMining(
        //            address(gearToken),
        //            opts.merkleRoot,
        //            opts.rewardPerMinedAccount,
        //            addressProvider
        //        ); // T:[GD-1,2]

        gearToken.transfer(treasury, opts.treasuryAmount); // T:[GD-1]
        gearToken.transfer(opts.testersAirdrop, opts.airdropAmount); // T:[GD-1]
        gearToken.transfer(
            opts.accountMiner,
            am.amount() * opts.accountsToBeMined
        ); // T:[GD-1]

        require(
            gearToken.balanceOf(address(this)) == 0,
            Errors.TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION
        ); // T:[TD-3, 4]
    }

    /// @dev Returns token balance aligned with voting power based on contributor type. It's used for snapshot voting.
    function balanceOf(address holder) external view returns (uint256) {
        uint256 vestingBalanceWeighted; // T:[TD-6]

        VestingContract memory vc = vestingContracts[holder]; // T:[TD-62]
        if (
            vc.contractAddress != address(0) &&
            vc.votingPower != VotingPower.ZERO_VOTING_POWER
        ) {
            address receiver = StepVesting(vc.contractAddress).receiver(); // T:[TD-6]

            if (receiver == holder) {
                vestingBalanceWeighted = gearToken
                .balanceOf(vc.contractAddress)
                .mul(vc.votingPower == VotingPower.A ? weightA : weightB)
                .div(PercentageMath.PERCENTAGE_FACTOR); // T:[TD-6]
            }
        }

        return vestingBalanceWeighted.add(gearToken.balanceOf(holder)); // T:[TD-6]
    }

    function updateContributors() external {
        // Initially we copy contributors set into array, cause it would be changed during the cycle
        address[] memory contributorsArray = new address[](
            contributorsSet.length()
        ); // T:[TD-11]
        for (uint256 i = 0; i < contributorsArray.length; i++) {
            contributorsArray[i] = contributorsSet.at(i); // T:[TD-11]
        }

        for (uint256 i = 0; i < contributorsArray.length; i++) {
            updateVestingHolder(contributorsArray[i]); // T:[TD-11]
        }
    }

    /// @dev Updates vestingContracts map, if receiver was changed in StepVesting contract
    /// @notice balanceOf method would return 0, if receiver was changed and vestingContracts map wasn't updated yet.
    /// use this method to update it, to transfer voting power and make it possible to vote using your vesting contract.
    /// @param prevOwner Previously registered owner
    function updateVestingHolder(address prevOwner) public {
        require(
            contributorsSet.contains(prevOwner),
            Errors.TD_CONTRIBUTOR_IS_NOT_REGISTERED
        ); // T:[TD-9]
        VestingContract memory vc = vestingContracts[prevOwner]; // T:[TD-8, 10, 11]

        address currentOwner = StepVesting(vc.contractAddress).receiver(); // T:[TD-8, 10, 11]

        if (prevOwner != currentOwner) // T:[TD-10]
        {
            require(
                vestingContracts[currentOwner].contractAddress == address(0),
                Errors.TD_WALLET_IS_ALREADY_CONNECTED_TO_VC
            ); // T:[TD-8, 10, 11, 14]

            delete vestingContracts[prevOwner]; // T:[TD-8, 10, 11]
            contributorsSet.remove(prevOwner); // T:[TD-8, 10, 11]

            vestingContracts[currentOwner] = vc; // T:[TD-8, 10, 11]
            contributorsSet.add(currentOwner); // T:[TD-8, 10, 11]

            emit VestingContractHolderUpdate(
                vc.contractAddress,
                prevOwner,
                currentOwner
            ); // T:[TD-8, 10, 11]
        }
    }

    /// @dev Updates voting power for contributor types
    /// @param _weightA - weight for contributors type A in PERCENTAGE format (1 = 10_000)
    /// @param _weightB - weight for contributors type B in PERCENTAGE format (1 = 10_000)
    /// @notice _weightA should be always gte than _weightB and all of them less than 10_000
    function updateVotingWeights(uint256 _weightA, uint256 _weightB)
        external
        configuratorOnly // T:[TD-2]
    {
        _updateVotingWeights(_weightA, _weightB); // T:[TD-12]
    }

    //
    // GETTERS
    //

    /// @return Count of contributors
    function countContributors() external view returns (uint256) {
        return contributorsSet.length(); // T:[TD-3]
    }

    /// @return List of holders
    function contributorsList() external view returns (address[] memory) {
        address[] memory result = new address[](contributorsSet.length()); // T:[TD-3]

        for (uint256 i = 0; i < contributorsSet.length(); i++) {
            result[i] = contributorsSet.at(i); // T:[TD-3]
        }

        return result; // T:[TD-3]
    }

    /// @return List of addresses of vesting contracts
    function vestingContractsList() external view returns (address[] memory) {
        address[] memory result = new address[](contributorsSet.length()); // T:[TD-3]

        for (uint256 i = 0; i < contributorsSet.length(); i++) {
            result[i] = vestingContracts[contributorsSet.at(i)].contractAddress; // T:[TD-3]
        }

        return result; // T:[TD-3]
    }

    //
    // INTERNAL FUNCTIONS
    //

    /// @dev Deploys (clone) new vesting contract
    /// @param tokenShare token holder and amount to be distributed
    /// @param contributorType contributor voting power (vesting parameters depends on it also)
    function _deployVestingContract(
        TokenShare memory tokenShare,
        VotingPower contributorType
    ) internal {
        require(
            !contributorsSet.contains(tokenShare.holder),
            Errors.TD_WALLET_IS_ALREADY_CONNECTED_TO_VC
        ); // T:[TD-5]

        if (masterVestingContract == address(0)) {
            masterVestingContract = address(new StepVesting());
        }

        address vc = contributorsSet.length() == 0
            ? masterVestingContract
            : Clones.clone(address(masterVestingContract)); // T:[TD-3]

        StepVesting(vc).initialize(
            IGearToken(address(gearToken)),
            block.timestamp,
            Constants.SECONDS_PER_YEAR,
            (
                contributorType == VotingPower.A
                    ? Constants.SECONDS_PER_YEAR
                    : Constants.SECONDS_PER_ONE_AND_HALF_YEAR
            ) / steps,
            0,
            tokenShare.amount / steps,
            steps,
            tokenShare.holder
        ); // T:[TD-3]

        contributorsSet.add(tokenShare.holder); // T:[TD-3]

        vestingContracts[tokenShare.holder] = VestingContract(
            vc,
            contributorType
        ); // T:[TD-3]

        gearToken.transfer(vc, tokenShare.amount); // T:[TD-3]
        emit NewVestingContract(tokenShare.holder, vc, contributorType); // T:[TD-3]
    }

    function _updateVotingWeights(uint256 _weightA, uint256 _weightB) internal {
        require(
            _weightA <= PercentageMath.PERCENTAGE_FACTOR &&
                _weightB <= _weightA,
            Errors.TD_INCORRECT_WEIGHTS
        ); // T:[TD-12, 13]
        weightA = _weightA; // T:[TD-12]
        weightB = _weightB; // T:[TD-12]
        emit NewWeights(weightA, weightB); // T:[TD-12]
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.7.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0; // T:[PM-1]
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-1]

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR; // T:[PM-1]
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO); // T:[PM-2]
        uint256 halfPercentage = percentage / 2; // T:[PM-2]

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        ); // T:[PM-2]

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Errors library
library Errors {
    //
    // COMMON
    //

    string public constant ZERO_ADDRESS_IS_NOT_ALLOWED = "Z0";
    string public constant NOT_IMPLEMENTED = "NI";
    string public constant INCORRECT_PATH_LENGTH = "PL";
    string public constant INCORRECT_ARRAY_LENGTH = "CR";
    string public constant REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY = "CP";
    string public constant REGISTERED_POOLS_ONLY = "RP";
    string public constant INCORRECT_PARAMETER = "IP";

    //
    // MATH
    //

    string public constant MATH_MULTIPLICATION_OVERFLOW = "M1";
    string public constant MATH_ADDITION_OVERFLOW = "M2";
    string public constant MATH_DIVISION_BY_ZERO = "M3";

    //
    // POOL
    //

    string public constant POOL_CONNECTED_CREDIT_MANAGERS_ONLY = "PS0";
    string public constant POOL_INCOMPATIBLE_CREDIT_ACCOUNT_MANAGER = "PS1";
    string public constant POOL_MORE_THAN_EXPECTED_LIQUIDITY_LIMIT = "PS2";
    string public constant POOL_INCORRECT_WITHDRAW_FEE = "SP3";
    string public constant POOL_CANT_ADD_CREDIT_MANAGER_TWICE = "PS4";

    //
    // CREDIT MANAGER
    //

    string public constant CM_NO_OPEN_ACCOUNT = "CM1";
    string
        public constant CM_ZERO_ADDRESS_OR_USER_HAVE_ALREADY_OPEN_CREDIT_ACCOUNT =
        "CM2";

    string public constant CM_INCORRECT_AMOUNT = "CM3";
    string public constant CM_CAN_LIQUIDATE_WITH_SUCH_HEALTH_FACTOR = "CM4";
    string public constant CM_CAN_UPDATE_WITH_SUCH_HEALTH_FACTOR = "CM5";
    string public constant CM_WETH_GATEWAY_ONLY = "CM6";
    string public constant CM_INCORRECT_PARAMS = "CM7";
    string public constant CM_INCORRECT_FEES = "CM8";
    string public constant CM_MAX_LEVERAGE_IS_TOO_HIGH = "CM9";
    string public constant CM_CANT_CLOSE_WITH_LOSS = "CMA";
    string public constant CM_TARGET_CONTRACT_iS_NOT_ALLOWED = "CMB";
    string public constant CM_TRANSFER_FAILED = "CMC";
    string public constant CM_INCORRECT_NEW_OWNER = "CME";

    //
    // ACCOUNT FACTORY
    //

    string public constant AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK =
        "AF1";
    string public constant AF_MINING_IS_FINISHED = "AF2";
    string public constant AF_CREDIT_ACCOUNT_NOT_IN_STOCK = "AF3";
    string public constant AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN = "AF4";

    //
    // ADDRESS PROVIDER
    //

    string public constant AS_ADDRESS_NOT_FOUND = "AP1";

    //
    // CONTRACTS REGISTER
    //

    string public constant CR_POOL_ALREADY_ADDED = "CR1";
    string public constant CR_CREDIT_MANAGER_ALREADY_ADDED = "CR2";

    //
    // CREDIT_FILTER
    //

    string public constant CF_UNDERLYING_TOKEN_FILTER_CONFLICT = "CF0";
    string public constant CF_INCORRECT_LIQUIDATION_THRESHOLD = "CF1";
    string public constant CF_TOKEN_IS_NOT_ALLOWED = "CF2";
    string public constant CF_CREDIT_MANAGERS_ONLY = "CF3";
    string public constant CF_ADAPTERS_ONLY = "CF4";
    string public constant CF_OPERATION_LOW_HEALTH_FACTOR = "CF5";
    string public constant CF_TOO_MUCH_ALLOWED_TOKENS = "CF6";
    string public constant CF_INCORRECT_CHI_THRESHOLD = "CF7";
    string public constant CF_INCORRECT_FAST_CHECK = "CF8";
    string public constant CF_NON_TOKEN_CONTRACT = "CF9";
    string public constant CF_CONTRACT_IS_NOT_IN_ALLOWED_LIST = "CFA";
    string public constant CF_FAST_CHECK_NOT_COVERED_COLLATERAL_DROP = "CFB";
    string public constant CF_SOME_LIQUIDATION_THRESHOLD_MORE_THAN_NEW_ONE =
        "CFC";
    string public constant CF_ADAPTER_CAN_BE_USED_ONLY_ONCE = "CFD";
    string public constant CF_INCORRECT_PRICEFEED = "CFE";
    string public constant CF_TRANSFER_IS_NOT_ALLOWED = "CFF";
    string public constant CF_CREDIT_MANAGER_IS_ALREADY_SET = "CFG";

    //
    // CREDIT ACCOUNT
    //

    string public constant CA_CONNECTED_CREDIT_MANAGER_ONLY = "CA1";
    string public constant CA_FACTORY_ONLY = "CA2";

    //
    // PRICE ORACLE
    //

    string public constant PO_PRICE_FEED_DOESNT_EXIST = "PO0";
    string public constant PO_TOKENS_WITH_DECIMALS_MORE_18_ISNT_ALLOWED = "PO1";
    string public constant PO_AGGREGATOR_DECIMALS_SHOULD_BE_18 = "PO2";

    //
    // ACL
    //

    string public constant ACL_CALLER_NOT_PAUSABLE_ADMIN = "ACL1";
    string public constant ACL_CALLER_NOT_CONFIGURATOR = "ACL2";

    //
    // WETH GATEWAY
    //

    string public constant WG_DESTINATION_IS_NOT_WETH_COMPATIBLE = "WG1";
    string public constant WG_RECEIVE_IS_NOT_ALLOWED = "WG2";
    string public constant WG_NOT_ENOUGH_FUNDS = "WG3";

    //
    // LEVERAGED ACTIONS
    //

    string public constant LA_INCORRECT_VALUE = "LA1";
    string public constant LA_HAS_VALUE_WITH_TOKEN_TRANSFER = "LA2";
    string public constant LA_UNKNOWN_SWAP_INTERFACE = "LA3";
    string public constant LA_UNKNOWN_LP_INTERFACE = "LA4";
    string public constant LA_LOWER_THAN_AMOUNT_MIN = "LA5";
    string public constant LA_TOKEN_OUT_IS_NOT_COLLATERAL = "LA6";

    //
    // YEARN PRICE FEED
    //
    string public constant YPF_PRICE_PER_SHARE_OUT_OF_RANGE = "YP1";
    string public constant YPF_INCORRECT_LIMITER_PARAMETERS = "YP2";

    //
    // TOKEN DISTRIBUTOR
    //
    string public constant TD_WALLET_IS_ALREADY_CONNECTED_TO_VC = "TD1";
    string public constant TD_INCORRECT_WEIGHTS = "TD2";
    string public constant TD_NON_ZERO_BALANCE_AFTER_DISTRIBUTION = "TD3";
    string public constant TD_CONTRIBUTOR_IS_NOT_REGISTERED = "TD4";
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {IAppAddressProvider} from "../interfaces/app/IAppAddressProvider.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title AddressRepository
/// @notice Stores addresses of deployed contracts
contract AddressProvider is Ownable, IAppAddressProvider {
    // Mapping which keeps all addresses
    mapping(bytes32 => address) public addresses;

    // Emits each time when new address is set
    event AddressSet(bytes32 indexed service, address indexed newAddress);

    // This event is triggered when a call to ClaimTokens succeeds.
    event Claimed(uint256 user_id, address account, uint256 amount, bytes32 leaf);

    // Repositories & services
    bytes32 public constant CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
    bytes32 public constant ACL = "ACL";
    bytes32 public constant PRICE_ORACLE = "PRICE_ORACLE";
    bytes32 public constant ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
    bytes32 public constant DATA_COMPRESSOR = "DATA_COMPRESSOR";
    bytes32 public constant TREASURY_CONTRACT = "TREASURY_CONTRACT";
    bytes32 public constant GEAR_TOKEN = "GEAR_TOKEN";
    bytes32 public constant WETH_TOKEN = "WETH_TOKEN";
    bytes32 public constant WETH_GATEWAY = "WETH_GATEWAY";
    bytes32 public constant LEVERAGED_ACTIONS = "LEVERAGED_ACTIONS";

    // Contract version
    uint256 public constant version = 1;

    constructor() {
        // @dev Emits first event for contract discovery
        emit AddressSet("ADDRESS_PROVIDER", address(this));
    }

    /// @return Address of ACL contract
    function getACL() external view returns (address) {
        return _getAddress(ACL); // T:[AP-3]
    }

    /// @dev Sets address of ACL contract
    /// @param _address Address of ACL contract
    function setACL(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACL, _address); // T:[AP-3]
    }

    /// @return Address of ContractsRegister
    function getContractsRegister() external view returns (address) {
        return _getAddress(CONTRACTS_REGISTER); // T:[AP-4]
    }

    /// @dev Sets address of ContractsRegister
    /// @param _address Address of ContractsRegister
    function setContractsRegister(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(CONTRACTS_REGISTER, _address); // T:[AP-4]
    }

    /// @return Address of PriceOracle
    function getPriceOracle() external view override returns (address) {
        return _getAddress(PRICE_ORACLE); // T:[AP-5]
    }

    /// @dev Sets address of PriceOracle
    /// @param _address Address of PriceOracle
    function setPriceOracle(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(PRICE_ORACLE, _address); // T:[AP-5]
    }

    /// @return Address of AccountFactory
    function getAccountFactory() external view returns (address) {
        return _getAddress(ACCOUNT_FACTORY); // T:[AP-6]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setAccountFactory(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(ACCOUNT_FACTORY, _address); // T:[AP-7]
    }

    /// @return Address of AccountFactory
    function getDataCompressor() external view override returns (address) {
        return _getAddress(DATA_COMPRESSOR); // T:[AP-8]
    }

    /// @dev Sets address of AccountFactory
    /// @param _address Address of AccountFactory
    function setDataCompressor(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(DATA_COMPRESSOR, _address); // T:[AP-8]
    }

    /// @return Address of Treasury contract
    function getTreasuryContract() external view returns (address) {
        return _getAddress(TREASURY_CONTRACT); //T:[AP-11]
    }

    /// @dev Sets address of Treasury Contract
    /// @param _address Address of Treasury Contract
    function setTreasuryContract(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(TREASURY_CONTRACT, _address); //T:[AP-11]
    }

    /// @return Address of GEAR token
    function getGearToken() external view override returns (address) {
        return _getAddress(GEAR_TOKEN); // T:[AP-12]
    }

    /// @dev Sets address of GEAR token
    /// @param _address Address of GEAR token
    function setGearToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(GEAR_TOKEN, _address); // T:[AP-12]
    }

    /// @return Address of WETH token
    function getWethToken() external view override returns (address) {
        return _getAddress(WETH_TOKEN); // T:[AP-13]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWethToken(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_TOKEN, _address); // T:[AP-13]
    }

    /// @return Address of WETH token
    function getWETHGateway() external view override returns (address) {
        return _getAddress(WETH_GATEWAY); // T:[AP-14]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setWETHGateway(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(WETH_GATEWAY, _address); // T:[AP-14]
    }

    /// @return Address of WETH token
    function getLeveragedActions() external view override returns (address) {
        return _getAddress(LEVERAGED_ACTIONS); // T:[AP-7]
    }

    /// @dev Sets address of WETH token
    /// @param _address Address of WETH token
    function setLeveragedActions(address _address)
        external
        onlyOwner // T:[AP-15]
    {
        _setAddress(LEVERAGED_ACTIONS, _address); // T:[AP-7]
    }

    /// @return Address of key, reverts if key doesn't exist
    function _getAddress(bytes32 key) internal view returns (address) {
        address result = addresses[key];
        require(result != address(0), Errors.AS_ADDRESS_NOT_FOUND); // T:[AP-1]
        return result; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    }

    /// @dev Sets address to map by its key
    /// @param key Key in string format
    /// @param value Address
    function _setAddress(bytes32 key, address value) internal {
        addresses[key] = value; // T:[AP-3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        emit AddressSet(key, value); // T:[AP-2]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {ACL} from "./ACL.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL Trait
/// @notice Trait which adds acl functions to contract
abstract contract ACLTrait is Pausable {
    // ACL contract to check rights
    ACL private _acl;

    /// @dev constructor
    /// @param addressProvider Address of address repository
    constructor(address addressProvider) {
        require(
            addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        _acl = ACL(AddressProvider(addressProvider).getACL());
    }

    /// @dev  Reverts if msg.sender is not configurator
    modifier configuratorOnly() {
        require(
            _acl.isConfigurator(msg.sender),
            Errors.ACL_CALLER_NOT_CONFIGURATOR
        ); // T:[ACLT-8]
        _;
    }

    ///@dev Pause contract
    function pause() external {
        require(
            _acl.isPausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1]
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external {
        require(
            _acl.isUnpausableAdmin(msg.sender),
            Errors.ACL_CALLER_NOT_PAUSABLE_ADMIN
        ); // T:[ACLT-1],[ACLT-2]
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import {AddressProvider} from "./AddressProvider.sol";
import {AccountFactory} from "./AccountFactory.sol";
import {IMerkleDistributor} from "../interfaces/IMerkleDistributor.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @dev Account Mining contract, based on https://github.com/Uniswap/merkle-distributor
/// It's needed only during Account Mining phase before protocol will be launched
contract AccountMining is IMerkleDistributor {
    address public immutable override token;
    uint256 public immutable amount;
    bytes32 public immutable override merkleRoot;
    AccountFactory public immutable accountFactory;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 amount_,
        AddressProvider addressProvider
    ) {
        require(
            token_ != address(0) &&
                merkleRoot_.length > 0 &&
                address(addressProvider) != address(0),
            Errors.INCORRECT_PARAMETER
        );
        token = token_;
        merkleRoot = merkleRoot_;
        amount = amount_;
        accountFactory = AccountFactory(addressProvider.getAccountFactory());
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        uint256 salt,
        bytes32[] calldata merkleProof
    ) external override {
        require(
            !isClaimed(index),
            "MerkleDistributor: Account is already mined."
        );

        address account = msg.sender;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, salt));
        require(
            merkleProof.length > 0 &&
                MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(
            IERC20(token).transfer(account, amount),
            "MerkleDistributor: Transfer failed."
        );

        accountFactory.mineCreditAccount();
        emit Claimed(index, account);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/// @dev Governance Gearbox token
/// based on https://github.com/Uniswap/governance/blob/master/contracts/Uni.sol
contract GearToken {
    /// @notice EIP-20 token name for this token
    string public constant name = "Gearbox";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "GEAR";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint256 public constant totalSupply = 10_000_000_000e18; // 10 billion Gear

    // Allowance amounts on behalf of others
    mapping(address => mapping(address => uint96)) internal allowances;

    // Official record of token balances for each account
    mapping(address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    // A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice Flag which allows token transfers
    bool public transfersAllowed;

    /// @notice Contract owner which can allow token transfers
    address public manager;

    /// @notice Miner address which can send tokens during account mining
    address public miner;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    event OwnershipTransferred(address indexed owner, address indexed newOwner);

    event MinerSet(address indexed miner);

    event TransferAllowed();

    modifier managerOnly() {
        require(msg.sender == manager, "Gear::caller is not the manager");
        _;
    }

    /**
     * @notice Construct a new Gear token
     * @param account The initial account to grant all the tokens
     */
    constructor(address account) {
        require(account != address(0), "Zero address is not allowed");
        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        manager = msg.sender;
        transfersAllowed = false;
    }

    function transferOwnership(address newManager)
        external
        managerOnly // T:[GT-3]
    {
        require(newManager != address(0), "Zero address is not allowed"); // T:[GT-5]
        emit OwnershipTransferred(manager, newManager); // T:[GT-6]
        manager = newManager; // T:[GT-6]
    }

    function setMiner(address _miner)
        external
        managerOnly // T:[GT-3]
    {
        require(_miner != address(0), "Zero address is not allowed");
        miner = _miner; // T:[GT-4]
        emit MinerSet(miner); // T:[GT-4]
    }

    function allowTransfers()
        external
        managerOnly // T:[GT-3]
    {
        transfersAllowed = true; // T:[GT-1]
        emit TransferAllowed();
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount)
        external
        returns (bool)
    {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Gear::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Gear::permit: amount exceeds 96 bits");
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                rawAmount,
                nonces[owner]++,
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Gear::permit: invalid signature");
        require(signatory == owner, "Gear::permit: unauthorized");
        require(block.timestamp <= deadline, "Gear::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 rawAmount) external returns (bool) {
        uint96 amount = safe96(
            rawAmount,
            "Gear::transfer: amount exceeds 96 bits"
        );
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 rawAmount
    ) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(
            rawAmount,
            "Gear::approve: amount exceeds 96 bits"
        );

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(
                spenderAllowance,
                amount,
                "Gear::transferFrom: transfer amount exceeds spender allowance"
            );
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Gear::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Gear::delegateBySig: invalid nonce"
        );
        require(
            block.timestamp <= expiry,
            "Gear::delegateBySig: signature expired"
        );
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "Gear::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(
        address src,
        address dst,
        uint96 amount
    ) internal {
        require(
            transfersAllowed || msg.sender == manager || msg.sender == miner,
            "Gear::transfers are forbidden"
        );
        require(
            src != address(0),
            "Gear::_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "Gear::_transferTokens: cannot transfer to the zero address"
        );

        balances[src] = sub96(
            balances[src],
            amount,
            "Gear::_transferTokens: transfer amount exceeds balance"
        );
        balances[dst] = add96(
            balances[dst],
            amount,
            "Gear::_transferTokens: transfer amount overflows"
        );
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "Gear::_moveVotes: vote amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "Gear::_moveVotes: vote amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "Gear::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IGearToken is IERC20 {
    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 rawAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external;

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96);

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IGearToken} from "../interfaces/IGearToken.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


// Based on https://github.com/1inch/governance-contracts/blob/master/contracts/StepVesting.sol
contract StepVesting is Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IGearToken;

    event ReceiverChanged(address oldWallet, address newWallet);

    uint256 public started;
    IGearToken public token;
    uint256 public cliffDuration;
    uint256 public stepDuration;
    uint256 public cliffAmount;
    uint256 public stepAmount;
    uint256 public numOfSteps;

    address public receiver;
    uint256 public claimed;

    modifier onlyReceiver {
        require(msg.sender == receiver, "access denied");
        _;
    }

    function initialize(
        IGearToken _token,
        uint256 _started,
        uint256 _cliffDuration,
        uint256 _stepDuration,
        uint256 _cliffAmount,
        uint256 _stepAmount,
        uint256 _numOfSteps,
        address _receiver
    ) external initializer {
        require(
            address(_token) != address(0) && _receiver != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        token = _token;
        started = _started;
        cliffDuration = _cliffDuration;
        stepDuration = _stepDuration;
        cliffAmount = _cliffAmount;
        stepAmount = _stepAmount;
        numOfSteps = _numOfSteps;
        receiver = _receiver;
    }

    function available() public view returns (uint256) {
        return claimable().sub(claimed);
    }

    function claimable() public view returns (uint256) {
        if (block.timestamp < started.add(cliffDuration)) {
            return 0;
        }

        uint256 passedSinceCliff = block.timestamp.sub(
            started.add(cliffDuration)
        );
        uint256 stepsPassed = Math.min(
            numOfSteps,
            passedSinceCliff.div(stepDuration)
        );
        return cliffAmount.add(stepsPassed.mul(stepAmount));
    }

    function setReceiver(address _receiver) public onlyReceiver {
        require(_receiver != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);
        emit ReceiverChanged(receiver, _receiver);
        receiver = _receiver;
    }

    function delegate(address delegatee) external onlyReceiver {
        require(delegatee != address(0), Errors.ZERO_ADDRESS_IS_NOT_ALLOWED);
        token.delegate(delegatee);
    }

    function claim() external onlyReceiver {
        uint256 amount = available();
        claimed = claimed.add(amount);
        token.safeTransfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {PercentageMath} from "../math/PercentageMath.sol";

library Constants {
    uint256 constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // 25% of MAX_INT
    uint256 constant MAX_INT_4 =
        0x3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // REWARD FOR LEAN DEPLOYMENT MINING
    uint256 constant ACCOUNT_CREATION_REWARD = 1e5;
    uint256 constant DEPLOYMENT_COST = 1e17;

    // FEE = 10%
    uint256 constant FEE_INTEREST = 1000; // 10%

    // FEE + LIQUIDATION_FEE 2%
    uint256 constant FEE_LIQUIDATION = 200;

    // Liquidation premium 5%
    uint256 constant LIQUIDATION_DISCOUNTED_SUM = 9500;

    // 100% - LIQUIDATION_FEE - LIQUIDATION_PREMIUM
    uint256 constant UNDERLYING_TOKEN_LIQUIDATION_THRESHOLD =
        LIQUIDATION_DISCOUNTED_SUM - FEE_LIQUIDATION;

    // Seconds in a year
    uint256 constant SECONDS_PER_YEAR = 365 days;
    uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = SECONDS_PER_YEAR * 3 /2;

    // 1e18
    uint256 constant RAY = 1e27;
    uint256 constant WAD = 1e18;

    // OPERATIONS
    uint8 constant OPERATION_CLOSURE = 1;
    uint8 constant OPERATION_REPAY = 2;
    uint8 constant OPERATION_LIQUIDATION = 3;

    // Decimals for leverage, so x4 = 4*LEVERAGE_DECIMALS for openCreditAccount function
    uint8 constant LEVERAGE_DECIMALS = 100;

    // Maximum withdraw fee for pool in percentage math format. 100 = 1%
    uint8 constant MAX_WITHDRAW_FEE = 100;

    uint256 constant CHI_THRESHOLD = 9950;
    uint256 constant HF_CHECK_INTERVAL_DEFAULT = 4;

    uint256 constant NO_SWAP = 0;
    uint256 constant UNISWAP_V2 = 1;
    uint256 constant UNISWAP_V3 = 2;
    uint256 constant CURVE_V1 = 3;
    uint256 constant LP_YEARN = 4;

    uint256 constant EXACT_INPUT = 1;
    uint256 constant EXACT_OUTPUT = 2;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Optimised for front-end Address Provider interface
interface IAppAddressProvider {
    function getDataCompressor() external view returns (address);

    function getGearToken() external view returns (address);

    function getWethToken() external view returns (address);

    function getWETHGateway() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLeveragedActions() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title ACL keeps admins addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is Ownable {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    // emits each time when new pausable admin added
    event PausableAdminAdded(address indexed newAdmin);

    // emits each time when pausable admin removed
    event PausableAdminRemoved(address indexed admin);

    // emits each time when new unpausable admin added
    event UnpausableAdminAdded(address indexed newAdmin);

    // emits each times when unpausable admin removed
    event UnpausableAdminRemoved(address indexed admin);

    /// @dev Adds pausable admin address
    /// @param newAdmin Address of new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes pausable admin
    /// @param admin Address of admin which should be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is pausable admin and false if not
    function isPausableAdmin(address addr) external view returns (bool) {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Removes unpausable admin
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    function isUnpausableAdmin(address addr) external view returns (bool) {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if addr has configurator rights
    function isConfigurator(address account) external view returns (bool) {
        return account == owner(); // T:[ACL-6]
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {IAccountFactory} from "../interfaces/IAccountFactory.sol";
import {IAccountMiner} from "../interfaces/IAccountMiner.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {ICreditManager} from "../interfaces/ICreditManager.sol";

import {AddressProvider} from "./AddressProvider.sol";
import {ContractsRegister} from "./ContractsRegister.sol";
import {CreditAccount} from "../credit/CreditAccount.sol";
import {ACLTrait} from "./ACLTrait.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {DataTypes} from "../libraries/data/Types.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

/// @title Abstract reusable credit accounts factory
/// @notice Creates, holds & lend credit accounts to pool contract
contract AccountFactory is IAccountFactory, ACLTrait, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    //
    //     head
    //      ⬇
    //    -------       -------        -------        -------
    //   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  ->  address(0)
    //    -------       -------        -------        -------
    //                                                   ⬆
    //                                                  tail
    //

    // Credit accounts connected list
    mapping(address => address) private _nextCreditAccount;

    // Head on connected list
    address public override head;

    // Tail of connected list
    address public override tail;

    // Address of master credit account for cloning
    address public masterCreditAccount;

    // Credit accounts list
    EnumerableSet.AddressSet private creditAccountsSet;

    // List of approvals which is needed during account mining campaign
    DataTypes.MiningApproval[] public miningApprovals;

    // Contracts register
    ContractsRegister public _contractsRegister;

    // Flag that there is no mining yet
    bool public isMiningFinished;

    // Contract version
    uint256 public constant version = 1;

    modifier creditManagerOnly() {
        require(
            _contractsRegister.isCreditManager(msg.sender),
            Errors.REGISTERED_CREDIT_ACCOUNT_MANAGERS_ONLY
        );
        _;
    }

    /**
     * @dev constructor
     * After constructor the list should be as following
     *
     *     head
     *      ⬇
     *    -------
     *   |  VA1  | ->   address(0)
     *    -------
     *      ⬆
     *     tail
     *
     * @param addressProvider Address of address repository
     */
    constructor(address addressProvider) ACLTrait(addressProvider) {
        require(
            addressProvider != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        _contractsRegister = ContractsRegister(
            AddressProvider(addressProvider).getContractsRegister()
        ); // T:[AF-1]

        masterCreditAccount = address(new CreditAccount()); // T:[AF-1]
        CreditAccount(masterCreditAccount).initialize(); // T:[AF-1]

        addCreditAccount(); // T:[AF-1]
        head = tail; // T:[AF-1]
        _nextCreditAccount[address(0)] = address(0); // T:[AF-1]
    }

    /**
     * @dev Provides a new credit account to the pool. Creates a new one, if needed
     *
     *   Before:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       -------        -------        -------
     *   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  ->  address(0)
     *    -------       -------        -------        -------
     *                                                   ⬆
     *                                                  tail
     *
     *   After:
     *  ---------
     *
     *    head
     *     ⬇
     *   -------        -------        -------
     *  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  ->  address(0)
     *   -------        -------        -------
     *                                    ⬆
     *                                   tail
     *
     *
     *   -------
     *  |  VA1  |  ->  address(0)
     *   -------
     *
     *  If had points the last credit account, it adds a new one
     *
     *    head
     *     ⬇
     *   -------
     *  |  VA2  |  ->   address(0)     =>    _addNewCreditAccount()
     *   -------
     *     ⬆
     *    tail
     *
     * @return Address of credit account
     */
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    )
        external
        override
        creditManagerOnly // T:[AF-12]
        returns (address)
    {
        // Create a new credit account if no one in stock
        _checkStock(); // T:[AF-3]

        address result = head;
        head = _nextCreditAccount[head]; // T:[AF-2]
        _nextCreditAccount[result] = address(0); // T:[AF-2]

        // Initialize creditManager
        ICreditAccount(result).connectTo(
            msg.sender,
            _borrowedAmount,
            _cumulativeIndexAtOpen
        ); // T:[AF-11, 14]

        emit InitializeCreditAccount(result, msg.sender); // T:[AF-5]
        return result; // T:[AF-14]
    }

    /**
     * @dev Takes credit account back and adds it to the stock
     *
     *   Before:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       -------        -------        -------
     *   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  ->  address(0)
     *    -------       -------        -------        -------
     *                                                   ⬆
     *                                                  tail
     *
     *   After:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       -------        -------        -------       ---------------
     *   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  -> |  usedAccount  |  ->  address(0)
     *    -------       -------        -------        -------       ---------------
     *                                                                     ⬆
     *                                                                    tail
     *
     *
     * @param usedAccount Address of used credit account
     */
    function returnCreditAccount(address usedAccount)
        external
        override
        creditManagerOnly // T:[AF-12]
    {
        require(
            creditAccountsSet.contains(usedAccount),
            Errors.AF_EXTERNAL_ACCOUNTS_ARE_FORBIDDEN
        );
        require(
            ICreditAccount(usedAccount).since() != block.number,
            Errors.AF_CANT_CLOSE_CREDIT_ACCOUNT_IN_THE_SAME_BLOCK
        ); // T:[CM-20]

        _nextCreditAccount[tail] = usedAccount; // T:[AF-7]
        tail = usedAccount; // T:[AF-7]
        emit ReturnCreditAccount(usedAccount); // T:[AF-8]
    }

    /// @dev Gets next available credit account or address(0) if you are in tail
    function getNext(address creditAccount)
        external
        view
        override
        returns (address)
    {
        return _nextCreditAccount[creditAccount];
    }

    /**
     * @dev Deploys new credit account and adds it to list tail
     *
     *   Before:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       -------        -------        -------
     *   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  ->  address(0)
     *    -------       -------        -------        -------
     *                                                   ⬆
     *                                                  tail
     *
     *   After:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       -------        -------        -------       --------------
     *   |  VA1  | ->  |  VA2  |  ->  |  VA3  |  ->  |  VA4  |  -> |  newAccount  |  ->  address(0)
     *    -------       -------        -------        -------       --------------
     *                                                                    ⬆
     *                                                                   tail
     *
     *
     */
    function addCreditAccount() public {
        address clonedAccount = Clones.clone(masterCreditAccount); // T:[AF-2]
        ICreditAccount(clonedAccount).initialize();
        _nextCreditAccount[tail] = clonedAccount; // T:[AF-2]
        tail = clonedAccount; // T:[AF-2]
        creditAccountsSet.add(clonedAccount); // T:[AF-10, 16]
        emit NewCreditAccount(clonedAccount);
    }

    /// @dev Takes unused credit account from list forever and connects it with "to" parameter
    function takeOut(
        address prev,
        address creditAccount,
        address to
    )
        external
        configuratorOnly // T:[AF-13]
    {
        _checkStock();

        if (head == creditAccount) {
            address prevHead = head;
            head = _nextCreditAccount[head]; // T:[AF-21] it exists cause we called _checkStock();
            _nextCreditAccount[prevHead] = address(0); // T:[AF-21]
        } else {
            require(
                _nextCreditAccount[prev] == creditAccount,
                Errors.AF_CREDIT_ACCOUNT_NOT_IN_STOCK
            ); // T:[AF-15]

            // updates tail if we take the last one
            if (creditAccount == tail) {
                tail = prev; // T:[AF-22]
            }

            _nextCreditAccount[prev] = _nextCreditAccount[creditAccount]; // T:[AF-16]
            _nextCreditAccount[creditAccount] = address(0); // T:[AF-16]
        }
        ICreditAccount(creditAccount).connectTo(to, 0, 0); // T:[AF-16, 21]
        creditAccountsSet.remove(creditAccount); // T:[AF-16]
        emit TakeForever(creditAccount, to); // T:[AF-16, 21]
    }

    ///
    /// MINING
    ///

    /// @dev Adds credit account token to factory and provide approvals
    /// for protocols & tokens which will be offered to accept by DAO
    /// All protocols & tokens in the list should be non-upgradable contracts
    /// Account mining will be finished before deployment any pools & credit managers
    function mineCreditAccount() external nonReentrant {
        require(!isMiningFinished, Errors.AF_MINING_IS_FINISHED); // T:[AF-17]
        addCreditAccount(); // T:[AF-18]
        ICreditAccount(tail).connectTo(address(this), 1, 1); // T:[AF-18]
        for (uint256 i = 0; i < miningApprovals.length; i++) {
            ICreditAccount(tail).approveToken(
                miningApprovals[i].token,
                miningApprovals[i].swapContract
            ); // T:[AF-18]
        }
    }

    /// @dev Adds pair token-contract to initial mining approval list
    /// These pairs will be used during accoutn mining which is designed
    /// to reduce gas prices for the first N reusable credit accounts
    function addMiningApprovals(
        DataTypes.MiningApproval[] calldata _miningApprovals
    )
        external
        configuratorOnly // T:[AF-13]
    {
        require(!isMiningFinished, Errors.AF_MINING_IS_FINISHED); // T:[AF-17]
        for (uint256 i = 0; i < _miningApprovals.length; i++) {
            require(
                _miningApprovals[i].token != address(0) &&
                    _miningApprovals[i].swapContract != address(0),
                Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
            );
            DataTypes.MiningApproval memory item = DataTypes.MiningApproval(
                _miningApprovals[i].token,
                _miningApprovals[i].swapContract
            ); // T:[AF-19]
            miningApprovals.push(item); // T:[AF-19]
        }
    }

    /// @dev Finishes mining activity. Account mining is desinged as one-time
    /// activity and should be finished before deployment pools & credit managers.
    function finishMining()
        external
        configuratorOnly // T:[AF-13]
    {
        isMiningFinished = true; // T:[AF-17]
    }

    /**
     * @dev Checks available accounts in stock and deploys new one if there is the last one
     *
     *   If:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------
     *   |  VA1  | ->   address(0)
     *    -------
     *      ⬆
     *     tail
     *
     *   Then:
     *  ---------
     *
     *     head
     *      ⬇
     *    -------       --------------
     *   |  VA1  | ->  |  newAccount  |  ->  address(0)
     *    -------       --------------
     *                       ⬆
     *                      tail
     *
     */
    function _checkStock() internal {
        // T:[AF-9]
        if (_nextCreditAccount[head] == address(0)) {
            addCreditAccount(); // T:[AF-3]
        }
    }

    /// @dev Cancels allowance for particular contract
    /// @param account Address of credit account to be cancelled allowance
    /// @param token Address of token for allowance
    /// @param targetContract Address of contract to cancel allowance
    function cancelAllowance(
        address account,
        address token,
        address targetContract
    )
        external
        configuratorOnly // T:[AF-13]
    {
        ICreditAccount(account).cancelAllowance(token, targetContract); // T:[AF-20]
    }

    //
    // GETTERS
    //

    /// @dev Counts how many credit accounts are in stock
    function countCreditAccountsInStock()
        external
        view
        override
        returns (uint256)
    {
        uint256 count = 0;
        address pointer = head;
        while (pointer != address(0)) {
            pointer = _nextCreditAccount[pointer];
            count++;
        }
        return count;
    }

    /// @dev Count of deployed credit accounts
    function countCreditAccounts() external view override returns (uint256) {
        return creditAccountsSet.length(); // T:[AF-10]
    }

    function creditAccounts(uint256 id)
        external
        view
        override
        returns (address)
    {
        return creditAccountsSet.at(id);
    }

    function isCreditAccount(address addr) external view returns (bool) {
        return creditAccountsSet.contains(addr); // T:[AF-16]
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;


// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {

    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    // Returns the merkle root of the merkle tree containing accounts and salt needed to claim.
    function merkleRoot() external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        uint256 salt,
        bytes32[] calldata merkleProof
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../libraries/data/Types.sol";

interface IAccountFactory {
    // emits if new account miner was changed
    event AccountMinerChanged(address indexed miner);

    // emits each time when creditManager takes credit account
    event NewCreditAccount(address indexed account);

    // emits each time when creditManager takes credit account
    event InitializeCreditAccount(
        address indexed account,
        address indexed creditManager
    );

    // emits each time when pool returns credit account
    event ReturnCreditAccount(address indexed account);

    // emits each time when DAO takes account from account factory forever
    event TakeForever(address indexed creditAccount, address indexed to);

    /// @dev Provide new creditAccount to pool. Creates a new one, if needed
    /// @return Address of creditAccount
    function takeCreditAccount(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external returns (address);

    /// @dev Takes credit account back and stay in tn the queue
    /// @param usedAccount Address of used credit account
    function returnCreditAccount(address usedAccount) external;

    /// @dev Returns address of next available creditAccount
    function getNext(address creditAccount) external view returns (address);

    /// @dev Returns head of list of unused credit accounts
    function head() external view returns (address);

    /// @dev Returns tail of list of unused credit accounts
    function tail() external view returns (address);

    /// @dev Returns quantity of unused credit accounts in the stock
    function countCreditAccountsInStock() external view returns (uint256);

    /// @dev Returns credit account address by its id
    function creditAccounts(uint256 id) external view returns (address);

    /// @dev Quantity of credit accounts
    function countCreditAccounts() external view returns (uint256);

    //    function miningApprovals(uint i) external returns(DataTypes.MiningApproval calldata);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

interface IAccountMiner {
    /// @dev Pays gas compensation for user
    function mineAccount(address payable user) external;

    /// @dev Returns account miner type
    function kind() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title Reusable Credit Account interface
/// @notice Implements general credit account:
///   - Keeps token balances
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Approves tokens for 3rd party contracts
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/creditManager/vanillacreditAccount

interface ICreditAccount {
    /// @dev Initializes clone contract
    function initialize() external;

    /// @dev Connects credit account to credit manager
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    //    /// @dev Set general credit account parameters. Restricted to credit managers only
    //    /// @param _borrowedAmount Amount which pool lent to credit account
    //    /// @param _cumulativeIndexAtOpen Cumulative index at open. Uses for interest calculation
    //    function setGenericParameters(
    //
    //    ) external;

    /// @dev Updates borrowed amount. Restricted to credit managers only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external;

    /// @dev Approves particular token for swap contract
    /// @param token ERC20 token for allowance
    /// @param swapContract Swap contract address
    function approveToken(address token, address swapContract) external;

    /// @dev Cancels allowance for particular contract
    /// @param token Address of token for allowance
    /// @param targetContract Address of contract to cancel allowance
    function cancelAllowance(address token, address targetContract) external;

    /// Transfers tokens from credit account to provided address. Restricted for pool calls only
    /// @param token Token which should be tranferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @dev Returns borrowed amount
    function borrowedAmount() external view returns (uint256);

    /// @dev Returns cumulative index at time of opening credit account
    function cumulativeIndexAtOpen() external view returns (uint256);

    /// @dev Returns Block number when it was initialised last time
    function since() external view returns (uint256);

    /// @dev Address of last connected credit manager
    function creditManager() external view returns (address);

    /// @dev Address of last connected credit manager
    function factory() external view returns (address);

    /// @dev Executed financial order on 3rd party service. Restricted for pool calls only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        returns (bytes memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {ICreditFilter} from "../interfaces/ICreditFilter.sol";
import {IAppCreditManager} from "./app/IAppCreditManager.sol";
import {DataTypes} from "../libraries/data/Types.sol";


/// @title Credit Manager interface
/// @notice It encapsulates business logic for managing credit accounts
///
/// More info: https://dev.gearbox.fi/developers/credit/credit_manager
interface ICreditManager is IAppCreditManager {
    // Emits each time when the credit account is opened
    event OpenCreditAccount(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed creditAccount,
        uint256 amount,
        uint256 borrowAmount,
        uint256 referralCode
    );

    // Emits each time when the credit account is closed
    event CloseCreditAccount(
        address indexed owner,
        address indexed to,
        uint256 remainingFunds
    );

    // Emits each time when the credit account is liquidated
    event LiquidateCreditAccount(
        address indexed owner,
        address indexed liquidator,
        uint256 remainingFunds
    );

    // Emits each time when borrower increases borrowed amount
    event IncreaseBorrowedAmount(address indexed borrower, uint256 amount);

    // Emits each time when borrower adds collateral
    event AddCollateral(
        address indexed onBehalfOf,
        address indexed token,
        uint256 value
    );

    // Emits each time when the credit account is repaid
    event RepayCreditAccount(address indexed owner, address indexed to);

    // Emit each time when financial order is executed
    event ExecuteOrder(address indexed borrower, address indexed target);

    // Emits each time when new fees are set
    event NewParameters(
        uint256 minAmount,
        uint256 maxAmount,
        uint256 maxLeverage,
        uint256 feeInterest,
        uint256 feeLiquidation,
        uint256 liquidationDiscount
    );

    event TransferAccount(address indexed oldOwner, address indexed newOwner);

    //
    // CREDIT ACCOUNT MANAGEMENT
    //

    /**
     * @dev Opens credit account and provides credit funds.
     * - Opens credit account (take it from account factory)
     * - Transfers trader /farmers initial funds to credit account
     * - Transfers borrowed leveraged amount from pool (= amount x leverageFactor) calling lendCreditAccount() on connected Pool contract.
     * - Emits OpenCreditAccount event
     * Function reverts if user has already opened position
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#open-credit-account
     *
     * @param amount Borrowers own funds
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param leverageFactor Multiplier to borrowers own funds
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external override;

    /**
     * @dev Closes credit account
     * - Swaps all assets to underlying one using default swap protocol
     * - Pays borrowed amount + interest accrued + fees back to the pool by calling repayCreditAccount
     * - Transfers remaining funds to the trader / farmer
     * - Closes the credit account and return it to account factory
     * - Emits CloseCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#close-credit-account
     *
     * @param to Address to send remaining funds
     * @param paths Exchange type data which provides paths + amountMinOut
     */
    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external
        override;

    /**
     * @dev Liquidates credit account
     * - Transfers discounted total credit account value from liquidators account
     * - Pays borrowed funds + interest + fees back to pool, than transfers remaining funds to credit account owner
     * - Transfer all assets from credit account to liquidator ("to") account
     * - Returns credit account to factory
     * - Emits LiquidateCreditAccount event
     *
     * More info: https://dev.gearbox.fi/developers/credit/credit_manager#liquidate-credit-account
     *
     * @param borrower Borrower address
     * @param to Address to transfer all assets from credit account
     * @param force If true, use transfer function for transferring tokens instead of safeTransfer
     */
    function liquidateCreditAccount(
        address borrower,
        address to,
        bool force
    ) external;

    /// @dev Repays credit account
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#repay-credit-account
    ///
    /// @param to Address to send credit account assets
    function repayCreditAccount(address to) external override;

    /// @dev Repays credit account with ETH. Restricted to be called by WETH Gateway only
    ///
    /// @param borrower Address of borrower
    /// @param to Address to send credit account assets
    function repayCreditAccountETH(address borrower, address to)
        external
        returns (uint256);

    /// @dev Increases borrowed amount by transferring additional funds from
    /// the pool if after that HealthFactor > minHealth
    /// More info: https://dev.gearbox.fi/developers/credit/credit_manager#increase-borrowed-amount
    ///
    /// @param amount Amount to increase borrowed amount
    function increaseBorrowedAmount(uint256 amount) external override;

    /// @dev Adds collateral to borrower's credit account
    /// @param onBehalfOf Address of borrower to add funds
    /// @param token Token address
    /// @param amount Amount to add
    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external override;

    /// @dev Returns true if the borrower has opened a credit account
    /// @param borrower Borrower account
    function hasOpenedCreditAccount(address borrower)
        external
        view
        override
        returns (bool);

    /// @dev Calculates Repay amount = borrow amount + interest accrued + fee
    ///
    /// More info: https://dev.gearbox.fi/developers/credit/economy#repay
    ///           https://dev.gearbox.fi/developers/credit/economy#liquidate
    ///
    /// @param borrower Borrower address
    /// @param isLiquidated True if calculated repay amount for liquidator
    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        override
        returns (uint256);

    /// @dev Returns minimal amount for open credit account
    function minAmount() external view returns (uint256);

    /// @dev Returns maximum amount for open credit account
    function maxAmount() external view returns (uint256);

    /// @dev Returns maximum leveraged factor allowed for this pool
    function maxLeverageFactor() external view returns (uint256);

    /// @dev Returns underlying token address
    function underlyingToken() external view returns (address);

    /// @dev Returns address of connected pool
    function poolService() external view returns (address);

    /// @dev Returns address of CreditFilter
    function creditFilter() external view returns (ICreditFilter);

    /// @dev Returns address of CreditFilter
    function creditAccounts(address borrower) external view returns (address);

    /// @dev Executes filtered order on credit account which is connected with particular borrowers
    /// @param borrower Borrower address
    /// @param target Target smart-contract
    /// @param data Call data for call
    function executeOrder(
        address borrower,
        address target,
        bytes memory data
    ) external returns (bytes memory);

    /// @dev Approves token for msg.sender's credit account
    function approve(address targetContract, address token) external;

    /// @dev Approve tokens for credit accounts. Restricted for adapters only
    function provideCreditAccountAllowance(
        address creditAccount,
        address toContract,
        address token
    ) external;

    function transferAccountOwnership(address newOwner) external;

    /// @dev Returns address of borrower's credit account and reverts of borrower has no one.
    /// @param borrower Borrower address
    function getCreditAccountOrRevert(address borrower)
        external
        view
        override
        returns (address);

//    function feeSuccess() external view returns (uint256);

    function feeInterest() external view returns (uint256);

    function feeLiquidation() external view returns (uint256);

    function liquidationDiscount() external view returns (uint256);

    function minHealthFactor() external view returns (uint256);

    function defaultSwapContract() external view override returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Errors} from "../libraries/helpers/Errors.sol";
import {ACLTrait} from "./ACLTrait.sol";


/// @title Pools & Contract managers registry
/// @notice Keeps pools & contract manager addresses
contract ContractsRegister is ACLTrait {
    // Pools list
    address[] public pools;
    mapping(address => bool) public isPool;

    // Credit Managers list
    address[] public creditManagers;
    mapping(address => bool) public isCreditManager;

    // Contract version
    uint256 public constant version = 1;

    // emits each time when new pool was added to register
    event NewPoolAdded(address indexed pool);

    // emits each time when new credit Manager was added to register
    event NewCreditManagerAdded(address indexed creditManager);

    constructor(address addressProvider) ACLTrait(addressProvider) {}

    /// @dev Adds pool to list
    /// @param newPoolAddress Address on new pool added
    function addPool(address newPoolAddress)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newPoolAddress != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        require(!isPool[newPoolAddress], Errors.CR_POOL_ALREADY_ADDED); // T:[CR-2]
        pools.push(newPoolAddress); // T:[CR-3]
        isPool[newPoolAddress] = true; // T:[CR-3]

        emit NewPoolAdded(newPoolAddress); // T:[CR-4]
    }

    /// @dev Returns array of registered pool addresses
    function getPools() external view returns (address[] memory) {
        return pools;
    }

    /// @return Returns quantity of registered pools
    function getPoolsCount() external view returns (uint256) {
        return pools.length; // T:[CR-3]
    }

    /// @dev Adds credit accounts manager address to the registry
    /// @param newCreditManager Address on new pausableAdmin added
    function addCreditManager(address newCreditManager)
        external
        configuratorOnly // T:[CR-1]
    {
        require(
            newCreditManager != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        require(
            !isCreditManager[newCreditManager],
            Errors.CR_CREDIT_MANAGER_ALREADY_ADDED
        ); // T:[CR-5]
        creditManagers.push(newCreditManager); // T:[CR-6]
        isCreditManager[newCreditManager] = true; // T:[CR-6]

        emit NewCreditManagerAdded(newCreditManager); // T:[CR-7]
    }

    /// @dev Returns array of registered credit manager addresses
    function getCreditManagers() external view returns (address[] memory) {
        return creditManagers;
    }

    /// @return Returns quantity of registered credit managers
    function getCreditManagersCount() external view returns (uint256) {
        return creditManagers.length; // T:[CR-6]
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ICreditAccount} from "../interfaces/ICreditAccount.sol";
import {Constants} from "../libraries/helpers/Constants.sol";
import {Errors} from "../libraries/helpers/Errors.sol";


/// @title Credit Account
/// @notice Implements generic credit account logic:
///   - Keeps token balances
///   - Stores general parameters: borrowed amount, cumulative index at open and block when it was initialized
///   - Approves tokens for 3rd party contracts
///   - Transfers assets
///   - Execute financial orders
///
///  More: https://dev.gearbox.fi/developers/credit/credit_account
contract CreditAccount is ICreditAccount, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    address public override factory;

    // Keeps address of current credit Manager
    address public override creditManager;

    // Amount borrowed to this account
    uint256 public override borrowedAmount;

    // Cumulative index at credit account opening
    uint256 public override cumulativeIndexAtOpen;

    // Block number when it was initialised last time
    uint256 public override since;

    // Contract version
    uint constant public version = 1;

    /// @dev Restricts operation for current credit manager only
    modifier creditManagerOnly {
        require(msg.sender == creditManager, Errors.CA_CONNECTED_CREDIT_MANAGER_ONLY);
        _;
    }

    /// @dev Initialise used instead of constructor cause we use contract cloning
    function initialize() external override initializer {
        factory = msg.sender;
    }

    /// @dev Connects credit account to credit account address. Restricted to account factory (owner) only
    /// @param _creditManager Credit manager address
    function connectTo(
        address _creditManager,
        uint256 _borrowedAmount,
        uint256 _cumulativeIndexAtOpen
    ) external override {
        require(msg.sender == factory, Errors.CA_FACTORY_ONLY);
        creditManager = _creditManager; // T:[CA-7]
        borrowedAmount = _borrowedAmount; // T:[CA-3,7]
        cumulativeIndexAtOpen = _cumulativeIndexAtOpen; //  T:[CA-3,7]
        since = block.number; // T:[CA-7]
    }

    /// @dev Updates borrowed amount. Restricted for current credit manager only
    /// @param _borrowedAmount Amount which pool lent to credit account
    function updateParameters(uint256 _borrowedAmount, uint256 _cumulativeIndexAtOpen)
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        borrowedAmount = _borrowedAmount; // T:[CA-4]
        cumulativeIndexAtOpen = _cumulativeIndexAtOpen;
    }

    /// @dev Approves token for 3rd party contract. Restricted for current credit manager only
    /// @param token ERC20 token for allowance
    /// @param swapContract Swap contract address
    function approveToken(address token, address swapContract)
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        IERC20(token).safeApprove(swapContract, 0); // T:[CA-5]
        IERC20(token).safeApprove(swapContract, Constants.MAX_INT); // T:[CA-5]
    }

    /// @dev Removes allowance token for 3rd party contract. Restricted for factory only
    /// @param token ERC20 token for allowance
    /// @param targetContract Swap contract address
    function cancelAllowance(address token, address targetContract)
        external
        override
    {
        require(msg.sender == factory, Errors.CA_FACTORY_ONLY);
        IERC20(token).safeApprove(targetContract, 0);
    }

    /// @dev Transfers tokens from credit account to provided address. Restricted for current credit manager only
    /// @param token Token which should be transferred from credit account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    )
        external
        override
        creditManagerOnly // T:[CA-2]
    {
        IERC20(token).safeTransfer(to, amount); // T:[CA-6]
    }

    /// @dev Executes financial order on 3rd party service. Restricted for current credit manager only
    /// @param destination Contract address which should be called
    /// @param data Call data which should be sent
    function execute(address destination, bytes memory data)
        external
        override
        creditManagerOnly
        returns (bytes memory)
    {
        return destination.functionCall(data); // T: [CM-48]
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;


/// @title DataType library
/// @notice Contains data types used in data compressor.
library DataTypes {
    struct Exchange {
        address[] path;
        uint256 amountOutMin;
    }

    struct TokenBalance {
        address token;
        uint256 balance;
        bool isAllowed;
    }

    struct ContractAdapter {
        address allowedContract;
        address adapter;
    }

    struct CreditAccountData {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
    }

    struct CreditAccountDataExtended {
        address addr;
        address borrower;
        bool inUse;
        address creditManager;
        address underlyingToken;
        uint256 borrowedAmountPlusInterest;
        uint256 totalValue;
        uint256 healthFactor;
        uint256 borrowRate;
        TokenBalance[] balances;
        uint256 repayAmount;
        uint256 liquidationAmount;
        bool canBeClosed;
        uint256 borrowedAmount;
        uint256 cumulativeIndexAtOpen;
        uint256 since;
    }

    struct CreditManagerData {
        address addr;
        bool hasAccount;
        address underlyingToken;
        bool isWETH;
        bool canBorrow;
        uint256 borrowRate;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 maxLeverageFactor;
        uint256 availableLiquidity;
        address[] allowedTokens;
        ContractAdapter[] adapters;
    }

    struct PoolData {
        address addr;
        bool isWETH;
        address underlyingToken;
        address dieselToken;
        uint256 linearCumulativeIndex;
        uint256 availableLiquidity;
        uint256 expectedLiquidity;
        uint256 expectedLiquidityLimit;
        uint256 totalBorrowed;
        uint256 depositAPY_RAY;
        uint256 borrowAPY_RAY;
        uint256 dieselRate_RAY;
        uint256 withdrawFee;
        uint256 cumulativeIndex_RAY;
        uint256 timestampLU;
    }

    struct TokenInfo {
        address addr;
        string symbol;
        uint8 decimals;
    }

    struct AddressProviderData {
        address contractRegister;
        address acl;
        address priceOracle;
        address traderAccountFactory;
        address dataCompressor;
        address farmingFactory;
        address accountMiner;
        address treasuryContract;
        address gearToken;
        address wethToken;
        address wethGateway;
    }

    struct MiningApproval {
        address token;
        address swapContract;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

interface ICreditFilter {
    // Emits each time token is allowed or liquidtion threshold changed
    event TokenAllowed(address indexed token, uint256 liquidityThreshold);

   // Emits each time token is allowed or liquidtion threshold changed
    event TokenForbidden(address indexed token);

    // Emits each time contract is allowed or adapter changed
    event ContractAllowed(address indexed protocol, address indexed adapter);

    // Emits each time contract is forbidden
    event ContractForbidden(address indexed protocol);

    // Emits each time when fast check parameters are updated
    event NewFastCheckParameters(uint256 chiThreshold, uint256 fastCheckDelay);

    event TransferAccountAllowed(
        address indexed from,
        address indexed to,
        bool state
    );

    event TransferPluginAllowed(
        address indexed pugin,
        bool state
    );

    event PriceOracleUpdated(address indexed newPriceOracle);

    //
    // STATE-CHANGING FUNCTIONS
    //

    /// @dev Adds token to the list of allowed tokens
    /// @param token Address of allowed token
    /// @param liquidationThreshold The constant showing the maximum allowable ratio of Loan-To-Value for the i-th asset.
    function allowToken(address token, uint256 liquidationThreshold) external;

    /// @dev Adds contract to the list of allowed contracts
    /// @param targetContract Address of contract to be allowed
    /// @param adapter Adapter contract address
    function allowContract(address targetContract, address adapter) external;

    /// @dev Forbids contract and removes it from the list of allowed contracts
    /// @param targetContract Address of allowed contract
    function forbidContract(address targetContract) external;

    /// @dev Checks financial order and reverts if tokens aren't in list or collateral protection alerts
    /// @param creditAccount Address of credit account
    /// @param tokenIn Address of token In in swap operation
    /// @param tokenOut Address of token Out in swap operation
    /// @param amountIn Amount of tokens in
    /// @param amountOut Amount of tokens out
    function checkCollateralChange(
        address creditAccount,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external;

    function checkMultiTokenCollateral(
        address creditAccount,
        uint256[] memory amountIn,
        uint256[] memory amountOut,
        address[] memory tokenIn,
        address[] memory tokenOut
    ) external;

    /// @dev Connects credit managaer, hecks that all needed price feeds exists and finalize config
    function connectCreditManager(address poolService) external;

    /// @dev Sets collateral protection for new credit accounts
    function initEnabledTokens(address creditAccount) external;

    function checkAndEnableToken(address creditAccount, address token) external;

    //
    // GETTERS
    //

    /// @dev Returns quantity of contracts in allowed list
    function allowedContractsCount() external view returns (uint256);

    /// @dev Returns of contract address from the allowed list by its id
    function allowedContracts(uint256 id) external view returns (address);

    /// @dev Reverts if token isn't in token allowed list
    function revertIfTokenNotAllowed(address token) external view;

    /// @dev Returns true if token is in allowed list otherwise false
    function isTokenAllowed(address token) external view returns (bool);

    /// @dev Returns quantity of tokens in allowed list
    function allowedTokensCount() external view returns (uint256);

    /// @dev Returns of token address from allowed list by its id
    function allowedTokens(uint256 id) external view returns (address);

    /// @dev Calculates total value for provided address
    /// More: https://dev.gearbox.fi/developers/credit/economy#total-value
    ///
    /// @param creditAccount Token creditAccount address
    function calcTotalValue(address creditAccount)
        external
        view
        returns (uint256 total);

    /// @dev Calculates Threshold Weighted Total Value
    /// More: https://dev.gearbox.fi/developers/credit/economy#threshold-weighted-value
    ///
    ///@param creditAccount Credit account address
    function calcThresholdWeightedValue(address creditAccount)
        external
        view
        returns (uint256 total);

    function contractToAdapter(address allowedContract)
        external
        view
        returns (address);

    /// @dev Returns address of underlying token
    function underlyingToken() external view returns (address);

    /// @dev Returns address & balance of token by the id of allowed token in the list
    /// @param creditAccount Credit account address
    /// @param id Id of token in allowed list
    /// @return token Address of token
    /// @return balance Token balance
    function getCreditAccountTokenById(address creditAccount, uint256 id)
        external
        view
        returns (
            address token,
            uint256 balance,
            uint256 tv,
            uint256 twv
        );

    /**
     * @dev Calculates health factor for the credit account
     *
     *         sum(asset[i] * liquidation threshold[i])
     *   Hf = --------------------------------------------
     *             borrowed amount + interest accrued
     *
     *
     * More info: https://dev.gearbox.fi/developers/credit/economy#health-factor
     *
     * @param creditAccount Credit account address
     * @return Health factor in percents (see PERCENTAGE FACTOR in PercentageMath.sol)
     */
    function calcCreditAccountHealthFactor(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Calculates credit account interest accrued
    /// More: https://dev.gearbox.fi/developers/credit/economy#interest-rate-accrued
    ///
    /// @param creditAccount Credit account address
    function calcCreditAccountAccruedInterest(address creditAccount)
        external
        view
        returns (uint256);

    /// @dev Return enabled tokens - token masks where each bit is "1" is token is enabled
    function enabledTokens(address creditAccount)
        external
        view
        returns (uint256);

    function liquidationThresholds(address token)
        external
        view
        returns (uint256);

    function priceOracle() external view returns (address);

    function updateUnderlyingTokenLiquidationThreshold() external;

    function revertIfCantIncreaseBorrowing(
        address creditAccount,
        uint256 minHealthFactor
    ) external view;

    function revertIfAccountTransferIsNotAllowed(
        address onwer,
        address creditAccount
    ) external view;

    function approveAccountTransfers(address from, bool state) external;

    function allowanceForAccountTransfers(address from, address to)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;
pragma abicoder v2;

import {DataTypes} from "../../libraries/data/Types.sol";


/// @title Optimised for front-end credit Manager interface
/// @notice It's optimised for light-weight abi
interface IAppCreditManager {
    function openCreditAccount(
        uint256 amount,
        address onBehalfOf,
        uint256 leverageFactor,
        uint256 referralCode
    ) external;

    function closeCreditAccount(address to, DataTypes.Exchange[] calldata paths)
        external;

    function repayCreditAccount(address to) external;

    function increaseBorrowedAmount(uint256 amount) external;

    function addCollateral(
        address onBehalfOf,
        address token,
        uint256 amount
    ) external;

    function calcRepayAmount(address borrower, bool isLiquidated)
        external
        view
        returns (uint256);

    function getCreditAccountOrRevert(address borrower)
        external
        view
        returns (address);

    function hasOpenedCreditAccount(address borrower)
        external
        view
        returns (bool);

    function defaultSwapContract() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}