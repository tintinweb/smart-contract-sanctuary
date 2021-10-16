/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]





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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]






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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/7/gas-manager/gas-tank/DappGasTank.sol





/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable {
    /*
     * Forwarder singleton we accept calls from
     */
    address public _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal initializer {
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal initializer {
        _trustedForwarder = trustedForwarder;
    }
    
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
    uint256[49] private __gap;
}

/* 
 * @title DappGasTank
 * @author livingrock (Biconomy)
 * @title Dapp Deposit Gas Tank Contract
 * @notice Handles customers deposits  
 */
contract DappGasTank is Initializable, OwnableUpgradeable, ERC2771ContextUpgradeable {

    address payable public masterAccount;
    uint256 public minDeposit = 1e18;
    uint8 internal _initializedVersion;
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //Maintain balances for each funding key
    mapping(uint256 => uint256) public dappBalances;

    //Maintains fundingKey and depositedAmount information for each Depositor
    //review mapping and how it is populated with each deposits
    mapping(address => mapping(uint256 => uint256) ) public depositorBalances;

    //Allowed tokens as deposit currency in Dapp Gas Tank
    mapping(address => bool) public allowedTokens;
    //Pricefeeds info should you require to calculate Token/ETH
    mapping(address => address) public tokenPriceFeed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initializes the contract
     */
    function initialize(address trustedForwarder) public initializer {
       __ERC2771Context_init(trustedForwarder);
       __Ownable_init();
       _initializedVersion = 0;
    }

    event Deposit(address indexed sender, uint256 indexed amount, uint256 indexed fundingKey); // fundingKey 
    
    event Withdraw(address indexed actor, uint256 indexed amount, address indexed receiver); // for when owner withdraws funds

    event MasterAccountChanged(address indexed account, address indexed actor);

    event MinimumDepositChanged(uint256 indexed minDeposit, address indexed actor);

    event DepositTokenAdded(address indexed token, address indexed actor);

    /**
     * @dev Emitted when trusted forwarder is updated to 
     * another (`trustedForwarder`).
     *
     * Note that `trustedForwarder` may be zero. `actor` is msg.sender for this action.
     */
    event TrustedForwarderChanged(address indexed truestedForwarder, address indexed actor);


    /**
     * returns the message sender
     */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * returns the message data
     */
    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes memory)
    {
        return ERC2771ContextUpgradeable._msgData();
    }


    /**
     * Admin function to set minimum deposit amount
     * emits and event 
     */
    function setMinDeposit(uint256 _newMinDeposit) external onlyOwner{
        minDeposit = _newMinDeposit;
        emit MinimumDepositChanged(_newMinDeposit,msg.sender);
    }

    /**
     * admin function to set trusted forwarder
     * @param _forwarder new trusted forwarder address
     *
     */
    function setTrustedForwarder(address payable _forwarder) external onlyOwner {
        require(_forwarder != address(0), "BICO:: Invalid address for new trusted forwarder");
        _trustedForwarder = _forwarder;
        emit TrustedForwarderChanged(_forwarder, msg.sender);
    }

    /**
     * Admin function to set master account which collects gas tank deposits
     */
    function setMasterAccount(address payable _newAccount) external onlyOwner{
        masterAccount = _newAccount;
        emit MasterAccountChanged(_newAccount, msg.sender);
    }

    /**
     * Admin function to set token allowed for depositing in gas tank 
     */
    function setTokenAllowed(address token, bool allowed) external onlyOwner{
        require(token != address(0), "Token address cannot be 0");  
        allowedTokens[token] = allowed;
        emit DepositTokenAdded(token,msg.sender);
    }
     
    /**
     * @param _fundingKey Associate funds with this funding key. 
     * Supply a deposit for a specified funding key. (This will be a unique unix epoch time)
     * Caution: The funding key must be an your identifier generated from biconomy dashboard 
     * Funds deposited will be forwarded to master account to fund the relayers
     * emits an event for off-chain accounting
     * @notice In the future this method may be upgraded to allow ERC20 token deposits 
     * @notice Generic depositFor could be added that allows deposit of ERC20 tokens and swaps them for native currency. 
     */
    function depositFor(uint256 _fundingKey) public payable { 
        require(msg.sender == tx.origin || msg.sender == _trustedForwarder, "sender must be EOA or trusted forwarder");
        require(msg.value > 0, "No value provided to depositFor.");
        require(msg.value >= minDeposit, "Must be grater than minimum deposit for this network");
        masterAccount.transfer(msg.value);
        dappBalances[_fundingKey] = dappBalances[_fundingKey] + msg.value; 
        //review
        depositorBalances[msg.sender][_fundingKey] = depositorBalances[msg.sender][_fundingKey] + msg.value;
        emit Deposit(msg.sender, msg.value, _fundingKey);
    }
  
    /** 
     * @dev If someone deposits funds directly to contract address
     * Here we wouldn't know the funding key!
     */ 
    receive() external payable {
        require(msg.value > 0, "No value provided to fallback.");
        require(tx.origin == msg.sender, "Only EOA can deposit directly.");
        //review
        //funding key stored is 0 
        depositorBalances[msg.sender][0] = depositorBalances[msg.sender][0] + msg.value;
        //All these types of deposits come under funding key 0
        emit Deposit(msg.sender, msg.value, 0);
    }

    /**
     * Admin function for sending/migrating any stuck funds. 
     */
    function withdraw(uint256 _amount) public onlyOwner {
        masterAccount.transfer(_amount);
        emit Withdraw(msg.sender, _amount, masterAccount);
    }
}