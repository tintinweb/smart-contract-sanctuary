/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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
    uint256[49] private __gap;
}


// File contracts/Interface/IAddressResolver.sol

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// File contracts/Tools/CacheResolver.sol

pragma solidity ^0.8.0;

// Inheritance
// Internal References
contract CacheResolver is OwnableUpgradeable  {
    
    IAddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    function _cacheInit(address _resolver) internal initializer {
        resolver = IAddressResolver(_resolver);
    }

    /** ========== public view functions ========== */

    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses)  {}


    /** ========== external mutative functions ========== */
    function rebuildCache() external {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /** ========== external view functions ========== */
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /** ========== internal view functions ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /** ========== event ========== */

    event CacheUpdated(bytes32 name, address destination);
}


// File contracts/Interface/ITokenState.sol

interface ITokenState {
    function setAllowance(address tokenOwner, address spender, uint value) external;

    function setBalanceOf(address account, uint value) external;
    
    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
}


// File contracts/Token/ExternStateToken.sol

pragma solidity ^0.8.0;

// Inheritance
// Internal References
contract ExternStateToken is OwnableUpgradeable{

    /* ERC20 parameter. */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    address public minter;
    ITokenState public tokenState;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the contract's permit
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    
    function _externStateTokenInit(
        string memory _name,
        string memory _symbol,
        uint8  _decimals,
        address _minter,
        address _tokenState
    ) internal initializer {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        minter = _minter;
        tokenState = ITokenState(_tokenState);
    }
    
    /* ========== public mutative functions ========== */

    function approve(address spender, uint value) public  returns (bool) {

        tokenState.setAllowance(_msgSender(), spender, value);
        emit Approval(_msgSender(), spender, value);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param holder The address to approve from
     * @param spender The address to be approved
     * @param _amount The number of tokens that are approved (2^256-1 means infinite)
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address holder, 
        address spender, 
        uint256 nonce, 
        uint256 expiry, 
        uint _amount,
        bool allowed, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) public
    {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH,keccak256(bytes(name)),keccak256(bytes("1")),getChainId(),address(this)));
        bytes32 STRUCTHASH = keccak256(abi.encode(PERMIT_TYPEHASH,holder,spender,nonce,expiry,allowed));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,STRUCTHASH));

        require(holder != address(0), "invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "permit-expired");
        require(nonce == nonces[holder]++, "invalid-nonce");
        uint amount = allowed ? _amount : 0;
        tokenState.setAllowance(holder, spender, amount);
        emit Approval(holder, spender, amount);
    }

    /* ========== public view functions ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender) public view returns (uint) {
        return tokenState.allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     * @param account token's owner
     */
    function balanceOf(address account) public view returns (uint) {
        return tokenState.balanceOf(account);
    }

    // /* ========== OnlyOwner functions ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(address _tokenState) external onlyOwner {
        tokenState = ITokenState(_tokenState);
        emit TokenStateUpdated(_tokenState);
    }

    /* ========== external mutative functions ========== */

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == minter, "Test:setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }


    /* ========== internal mutative functions ========== */

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0) && to != address(this), "Cannot transfer to this address");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from) - value);
        tokenState.setBalanceOf(to, tokenState.balanceOf(to) + value);

        // Emit a standard ERC20 transfer event
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transferByProxy(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        return _internalTransfer(from, to, value);
    }

    /*
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFromByProxy(
        address sender,
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState.setAllowance(from, sender, tokenState.allowance(from, sender) - value);
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Mint new tokens
     * @param to The address of the destination account
     * @param value The number of tokens to be minted
     */
    function _internalmint(address to, uint value) internal {
        require(msg.sender == minter, "Test:mint: only the minter can mint");
        require(to != address(0) && value != 0, "this mint is invalid");
        
        totalSupply = totalSupply + value;
        tokenState.setBalanceOf(to, value);
        emit Minted(address(0), to, value);
    }


    function _internalbrun(address from, uint value) internal {
        require(msg.sender == from, "you are not allowed to burn the token which don't belong to you.");
        
        totalSupply = totalSupply - value;
        _internalTransfer(from, address(0), value);
        emit Burned(from, value);
    }


    /* ========== internal view functions ========== */


    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }


    /* ========== event ========== */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event MinterChanged(address indexed minter,address indexed minter_);
    event Minted(address indexed from, address indexed to, uint indexed value);
    event Burned(address indexed from, uint indexed value);
    event TokenStateUpdated(address indexed newtokenstate);
}


// File contracts/Interface/IVoteRecord.sol

interface IVoteRecord {

    /** ========== view functions ========== */

    function getPriorVotes(address account, uint blockNumber) external view returns (uint);

    function getCurrentVotes(address account) external view returns (uint);

    /** ========== mutative functions ========== */

    function moveDelegates(address srcRep, address dstRep, uint amount) external;

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/Interface/ISystemStatus.sol

interface ISystemStatus {


    // global access list controller
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);


    // Be similar with the feature of requir(), the following function is used to check whether the section is active or not.
    function requireSystemActive() external view;

    function requireRewardPoolActive() external view;

    function requireCollectionTradingActive() external view;

    function requireActivitiesActive() external view;

    function requireStableCoinActive() external view;

    function requireDAOActive() external view;

    // status of key functions of each system section
    // function voterecordingActive() external view;

    function requireFunctionActive(string memory functionname, bytes32 section) external view;


    // whether tbe system is upgrading or not
    function isSystemUpgrading() external view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(string memory functionname, bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}


// File contracts/Token/Token.sol

pragma solidity ^0.8.0;

// Inheritance
// Internal references
contract Token is OwnableUpgradeable, CacheResolver, ExternStateToken {

    /** erc20 token details */

    string public constant TOKEN_NAME = "TEST";
    string public constant TOKEN_SYMBOL = "TT";
    uint8 public constant TOKEN_DECIMALS = 18;
    
    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";



    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_VOTERECORD;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        return addresses;
    }



    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }


    /* ========== ERC20 token function ========== */

    /*
     * @description: Replace Constructor function due to Transparent Proxy module.
     * @dev: The initialize function will be called as a calldata while proxy contract deployment.
     * @param {account} accept the initial supplyment of token and be set as a minter to have the authority to mint new supplyment.
     * @param {_totalSupply} the initial supplyment
     */ 
    function token_initialize(
        address _owner,
        address _tokenState,
        address _resolver
        )
        public initializer 
    {
        _externStateTokenInit(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            TOKEN_DECIMALS,
            _owner,
            _tokenState
        );

        _cacheInit(_resolver);
        
        __Ownable_init();
        minter = _owner;
        emit MinterChanged(address(0), minter);
    }


    /** ========== public mutative functions ========== */

    function transfer(address from, address to, uint value) public systemActive {

        // record user's vote amount after transfer
        voteRecord().moveDelegates(from, to, value);

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(from, to, value);
    }

    function transferFrom(address from, address to, uint value) public systemActive {

        // record user's vote amount after transfer
        voteRecord().moveDelegates(from, to, value);

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferFromByProxy(from,from, to, value);
    }


    function mint(address to, uint value) public systemActive mintfunctionActive {
        _internalmint(to, value);
        voteRecord().moveDelegates(address(0), to, value);
    }


    
    function burn(address from, uint value) public systemActive burnfunctionActive {
        _internalbrun(from, value);
        voteRecord().moveDelegates(from, address(0), value);
    }

    


    /** ========== public view functions ========== */


    /** ========== external mutative functions ========== */

    
    /** ========== external view functions ========== */




    /** ========== internal mutative functions ========== */

    function _cantransfer(address account, uint value) internal view returns (bool) {
        
    }




    /** ========== modifier ========== */

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function _mintfunctionActive() private view {
        string memory functionname = "tokenmint";
        bytes32 section_system = "System";
        systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier mintfunctionActive() {
        _mintfunctionActive();
        _;
    }

    function _burnfunctionActive() private view {
        string memory functionname = "tokenburn";
        bytes32 section_system = "System";
        systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier burnfunctionActive() {
        _burnfunctionActive();
        _;
    }

    /** ========== event ========== */

}