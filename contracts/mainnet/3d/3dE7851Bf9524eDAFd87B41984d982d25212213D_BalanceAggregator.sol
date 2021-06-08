/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]



pragma solidity ^0.8.0;

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
    constructor () {
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


// File contracts/BalanceAggregator.sol

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract Enum {
    enum Operation {
        Call, DelegateCall
    }
}

interface IAdapter {
    function getBalance(
        address token,
        address account
    )
        external
        view
        returns(
            uint256
        );
}

interface IERC20 {
    function balanceOf(
        address _owner
    )
        external
        view
        returns(
            uint256 balance
        );
}

contract BalanceAggregator is Ownable{

    event AddedAdapter(address owner);
    event RemovedAdapter(address owner);

    uint256 public adapterCount;
    IERC20 public token;

    address internal constant SENTINEL_ADAPTERS = address(0x1);

    // Mapping of adapter contracts
    mapping(address => address) internal adapters;

    /// @param _adapters adapters that should be enabled immediately
    constructor(
        address _token,
        address[] memory _adapters
    ){
        token = IERC20(_token);
        setupAdapters(_adapters);
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _adapters List of adapters.
    function setupAdapters(
        address[] memory _adapters
    )
        internal
    {
        // Initializing adapters.
        address currentAdapter = SENTINEL_ADAPTERS;
        for (uint256 i = 0; i < _adapters.length; i++) {
            address adapter = _adapters[i];
            require(adapter != address(0) && adapter != SENTINEL_ADAPTERS && adapter != address(this) && currentAdapter != adapter, "Adapter address cannot be null, the sentinel, or this contract.");
            require(adapters[adapter] == address(0), " No duplicate adapters allowed.");
            adapters[currentAdapter] = adapter;
            currentAdapter = adapter;
        }
        adapters[currentAdapter] = SENTINEL_ADAPTERS;
        adapterCount = _adapters.length;
    }

    /// @dev Allows to add a new adapter.
    /// @notice Adds the adapter `adapter`.
    /// @param adapter New adapter address.
    function addAdapter(
        address adapter
    )
        public
        onlyOwner
    {
        require(adapter != address(0) && adapter != SENTINEL_ADAPTERS && adapter != address(this), "Adapter address cannot be null, the sentinel, or this contract.");
        require(adapters[adapter] == address(0), "No duplicate adapters allowed.");
        adapters[adapter] = adapters[SENTINEL_ADAPTERS];
        adapters[SENTINEL_ADAPTERS] = adapter;
        adapterCount++;
        emit AddedAdapter(adapter);
    }

    /// @dev Allows to remove an adapter.
    /// @notice Removes the adapter `adapter`.
    /// @param prevAdapter Adapter that pointed to the adapter to be removed in the linked list.
    /// @param adapter Adapter address to be removed.
    function removeAdapter(
        address prevAdapter,
        address adapter
    )
        public
        onlyOwner
    {
        // Validate adapter address and check that it corresponds to adapter index.
        require(adapter != address(0) && adapter != SENTINEL_ADAPTERS, "Adapter address cannot be null or the sentinel.");
        require(adapters[prevAdapter] == adapter, "prevAdapter does not point to adapter.");
        adapters[prevAdapter] = adapters[adapter];
        adapters[adapter] = address(0);
        adapterCount--;
        emit RemovedAdapter(adapter);
    }

    /// @dev Returns array of adapters.
    /// @return Array of adapters.
    function getAdapters()
        public
        view
        returns(
            address[] memory
        )
    {
        address[] memory array = new address[](adapterCount);

        // populate return array
        uint256 index = 0;
        address currentAdapter = adapters[SENTINEL_ADAPTERS];
        while (currentAdapter != SENTINEL_ADAPTERS) {
            array[index] = currentAdapter;
            currentAdapter = adapters[currentAdapter];
            index++;
        }
        return array;
    }

    function balanceOf(address _owner)
        external
        view
        returns(
            uint256 balance
        )
    {
        address[] memory _adapters = getAdapters();
        uint256 _balance = token.balanceOf(_owner);

        for (uint i = 0; i < _adapters.length; i++){
            IAdapter adapter = IAdapter(_adapters[i]);
            uint adapterBalance = adapter.getBalance(address(token), _owner);
            _balance = _balance + adapterBalance;
        }
        return _balance;
    }
}