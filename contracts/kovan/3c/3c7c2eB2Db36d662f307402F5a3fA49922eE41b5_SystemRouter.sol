/**
 *Submitted for verification at Etherscan.io on 2021-05-27
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


    function setAddressResolver(address _resolver) external onlyOwner {
        require(_resolver != address(0), "the resolver is extremely important, so you must set a correct address");
        resolver = IAddressResolver(_resolver);
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


// File contracts/Interface/IMerkleDistribution.sol

interface IMerkleDistribution{
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
    // Claim the given amount of the token to the given address with an available amount from user's former contribution.
    function claimoflandholder(address _holder) external;

    function holdertokenvaults(address account) external view returns (uint, uint);

    function ClaimedToken(address account) external view returns (uint);

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
    
}


// File contracts/Interface/ILiquidityReward_Token_ETH.sol

interface ILiquidityReward_Token_ETH {

    function stake(address account, uint256 amount) external;

    function withdraw(address account,uint256 amount) external;

    function getReward(address account) external;

    function exit(address account) external;

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function earned(address account) external view returns (uint);

    function balanceOfStakeToken(address account) external view returns (uint);
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

    function requireFunctionActive(bytes32 functionname, bytes32 section) external view;


    // whether tbe system is upgrading or not
    function isSystemUpgrading() external view returns (bool);
    
    // check the details of suspension of each section.
    function getSuspensionStatus(bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );

    function getFunctionSuspendstionStatus(bytes32 functionname, bytes32 section) external view returns(
        bool suspend,
        uint reason,
        uint timestamp,
        address operator
    );


}


// File contracts/Interface/IToken.sol

interface IToken {
    function balanceOf(address account) external view returns (uint);

    function name() external view returns (string memory);

    function transfer(address account, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;
}


// File contracts/Interface/IUniswapV2Pair.sol

pragma solidity >=0.6.0;

interface IUniswapV2Pair {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/SystemRouter.sol

pragma solidity ^0.8.0;

// Inheritance
// Internal References
contract SystemRouter is OwnableUpgradeable, CacheResolver{

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_MERKLEDISTRIBUTION = "MerkleDistribution";
    bytes32 private constant CONTRACT_LIQUIDITY_TOKEN_ETH = "LiquidityReward_Token_ETH";

    function router_init(address _resolver) public initializer {
        __Ownable_init();
        _cacheInit(_resolver);
    }

    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_MERKLEDISTRIBUTION;
        addresses[1] = CONTRACT_LIQUIDITY_TOKEN_ETH;
        return addresses;
    }

    function merkleDistribution() internal view returns (IMerkleDistribution) {
        return IMerkleDistribution(requireAndGetAddress(CONTRACT_MERKLEDISTRIBUTION));
    }

    function liquidityReward_Token_ETH() internal view returns (ILiquidityReward_Token_ETH) {
        return ILiquidityReward_Token_ETH(requireAndGetAddress(CONTRACT_LIQUIDITY_TOKEN_ETH));
    }
    
    /** ========== public view functions ========== */

    function stakedBalanceOf(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().balanceOf(account);
    }

    function stakedTotalSupply() public view returns (uint) {
        return liquidityReward_Token_ETH().totalSupply();
    }

    function stakedEarned(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().earned(account);
    }

    function balanceOfStakeToken(address account) public view returns (uint) {
        return liquidityReward_Token_ETH().balanceOfStakeToken(account);
    }

   function holderVaults(address account) public view returns (uint, uint) {
        (uint tokenamount, uint acquiretime) = merkleDistribution().holdertokenvaults(account);
        return (tokenamount, acquiretime);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        return merkleDistribution().isClaimed(index);
    }

    function ClaimedToken(address account) public view returns (uint) {
        return merkleDistribution().ClaimedToken(account);
    }

    /** ========== external mutative functions ========== */

    // Merkle
    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external {
        merkleDistribution().claim(index, account, _amount, merkleProof);
    }

    function claimoflandholder(address _holder) external {
        merkleDistribution().claimoflandholder(_holder);
    }

    // Reward
    function stake(uint256 amount) external {
        liquidityReward_Token_ETH().stake(_msgSender(),amount);
    }

    function stakewithpermit(
        address stakingtoken,
        uint256 expiry, 
        uint value,
        uint8 v, 
        bytes32 r, 
        bytes32 s 
    ) public {
        IUniswapV2Pair(stakingtoken).permit(msg.sender, address(this), value, expiry, v, r, s);
        liquidityReward_Token_ETH().stake(_msgSender(),value);
    }

    function withdraw(uint256 amount) external {
        liquidityReward_Token_ETH().withdraw(_msgSender(),amount);
    }

    function getReward() external  {
        liquidityReward_Token_ETH().getReward(_msgSender());
    }

    function exit() external {
        liquidityReward_Token_ETH().exit(_msgSender());
    }

}