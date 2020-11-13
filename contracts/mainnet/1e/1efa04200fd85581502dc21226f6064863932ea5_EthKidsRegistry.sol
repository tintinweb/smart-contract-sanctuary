// File: openzeppelin-solidity/contracts/GSN/Context.sol

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

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/SignerRole.sol

pragma solidity ^0.5.0;



contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/utils/EnumerableSet.sol

pragma solidity ^0.5.0;

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
 * As of v2.5.0, only `address` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.AddressSet;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta Cañada
 */
library EnumerableSet {

    struct AddressSet {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (address => uint256) index;
        address[] values;
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                address lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        address[] memory output = new address[](set.values.length);
        for (uint256 i; i < set.values.length; i++){
            output[i] = set.values[i];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(AddressSet storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return set.values[index];
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/BondingVaultInterface.sol

pragma solidity ^0.5.2;

interface BondingVaultInterface {

    function fundWithReward(address payable _donor) external payable;

    function getEthKidsToken() external view returns (address);

    function calculateReward(uint256 _ethAmount) external view returns (uint256 _tokenAmount);

    function calculateReturn(uint256 _tokenAmount) external view returns (uint256 _returnEth);

    function sweepVault(address payable _operator) external;

    function addWhitelisted(address account) external;

    function removeWhitelisted(address account) external;

}

// File: contracts/YieldVaultInterface.sol

pragma solidity ^0.5.8;

interface YieldVaultInterface {

    function withdraw(address _token, address _atoken, uint _amount) external;

    function addWhitelisted(address account) external;

    function removeWhitelisted(address account) external;

}

// File: contracts/RegistryInterface.sol

pragma solidity ^0.5.2;



interface RegistryInterface {

    function getCurrencyConverter() external view returns (address);

    function getBondingVault() external view returns (BondingVaultInterface);

    function yieldVault() external view returns (YieldVaultInterface);

    function getCharityVaults() external view returns (address[] memory);

    function communityCount() external view returns (uint256);

}

// File: contracts/RegistryAware.sol

pragma solidity ^0.5.2;


interface RegistryAware {

    function setRegistry(address _registry) external;

    function getRegistry() external view returns (RegistryInterface);
}

// File: contracts/community/IDonationCommunity.sol

pragma solidity ^0.5.2;

interface IDonationCommunity {

    function donateDelegated(address payable _donator) external payable;

    function name() external view returns (string memory);

    function charityVault() external view returns (address);
}

// File: contracts/EthKidsRegistry.sol

pragma solidity ^0.5.2;









/**
 * @title EthKidsRegistry
 * @dev Holds the list of the communities' addresses
 */
contract EthKidsRegistry is RegistryInterface, SignerRole {

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    BondingVaultInterface public bondingVault;
    YieldVaultInterface public yieldVault;
    EnumerableSet.AddressSet private communities;
    address public currencyConverter;

    event CommunityRegistered(address communityAddress);

    /**
    * @dev Default fallback function, just deposits funds to the community
    */
    function() external payable {
        address(bondingVault).toPayable().transfer(msg.value);
    }

    constructor (address payable _bondingVaultAddress, address _yieldVault) public {
        require(_bondingVaultAddress != address(0));
        bondingVault = BondingVaultInterface(_bondingVaultAddress);
        require(_yieldVault != address(0));
        yieldVault = YieldVaultInterface(_yieldVault);
    }

    function registerCommunity(address _communityAddress) onlySigner public {
        require(communities.add(_communityAddress), 'This community is already present!');
        ((RegistryAware)(_communityAddress)).setRegistry(address(this));
        bondingVault.addWhitelisted(_communityAddress);
        yieldVault.addWhitelisted(_communityAddress);
        emit CommunityRegistered(_communityAddress);
    }

    function registerCurrencyConverter(address _currencyConverter) onlySigner public {
        currencyConverter = _currencyConverter;
    }

    function removeCommunity(address _address) onlySigner public {
        bondingVault.removeWhitelisted(_address);
        yieldVault.removeWhitelisted(_address);
        communities.remove(_address);
    }

    function getCommunityAt(uint256 _index) public view returns (IDonationCommunity community) {
        return IDonationCommunity(communities.get(_index));
    }

    function communityCount() public view returns (uint256) {
        return communities.length();
    }

    function sweepVault() public onlySigner {
        bondingVault.sweepVault(msg.sender);
    }

    function distributeYieldVault(address _token, address _atoken, uint _amount) public onlySigner {
        yieldVault.withdraw(_token, _atoken, _amount);
    }

    function getCurrencyConverter() public view returns (address) {
        return currencyConverter;
    }

    function getBondingVault() public view returns (BondingVaultInterface) {
        return bondingVault;
    }

    function getCharityVaults() public view returns (address[] memory) {
        address[] memory result = communities.enumerate();
        for (uint8 i = 0; i < result.length; i++) {
            result[i] = IDonationCommunity(result[i]).charityVault();
        }
        return result;
    }


}