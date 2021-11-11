/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts/proxy/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
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
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
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
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/utils/[email protected]

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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
    constructor() {
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
}


// File @openzeppelin/contracts/proxy/utils/[email protected]

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


// File contracts/interfaces/IIDOAgreement.sol

struct DeFiCreationInfo{
    uint percentOfSale; /** @dev percent of sale that is used to provide liquidity for the swap pair */
    uint swapAllocation;
    address otherAsset; /** @dev the other asset in the new swap pair */
    uint farmAllocation; /** @dev amount of IDO token to allocate to corresponding lp farm */
    uint blockReward;
    uint lifeSpan; //in blocks
    uint bonusLifeSpan;
    uint bonus;
    bool created; /** bool used to track if corresponding defi assets were created, not used in agreement should be false */
    address lpToken; /** once swap pair has been made, the lp token address will be saved here */
    bool createCompounder;
}

interface IIDOAgreement {

    function initialize(address _owner, address IDOImplementation) external;

    function locked() external view returns (bool);
    function owner() external view returns (address);
    function percentDecimals() external view returns(uint);
    function defi(uint i) external view returns(DeFiCreationInfo memory);
    function package() external view returns(uint);
    function IDOImplementation() external view returns(address);
    function IDOToken() external view returns (address);
    function saleToken() external view returns (address);
    function price()external view returns(uint);
    function totalAmount()external view returns(uint);
    function saleStart()external view returns(uint);
    function saleEnd()external view returns(uint);
    function commission()external view returns(uint);
    function GFIcommission() external view returns(address);
    function treasury() external view returns(address);
    function reserves() external view returns(address);
    function GFISudoUser() external view returns(address);
    function clientSudoUser() external view returns(address);
    function timelock() external view returns(uint);
    function gracePeriod() external view returns(uint);
    function tierBuyLimits(uint i) external view returns(uint);
    function tierAmounts(uint i) external view returns(uint);
    function defiCount() external view returns(uint);
    function minCapitalRaised() external view returns(uint);
    function brokenTrustFee() external view returns(uint);
}


// File contracts/LaunchPad/IDOAgreement.sol


//TODO account for swap pairs needing a max amount of IDO tokens to work, ie if the swap pair gets 10% of the saleTokens,
// and the sale could raise $100,000 then $10,000 worth of IDO tokens needs to be set aside for the swap pair, even though it might not use all of them
contract IDOAgreement is Initializable{
    bool public locked; /** @dev bool used to irreversibly lock agreement once finalzed */
    address public owner; /** @dev address of the owner of the agreement */
    uint constant public percentDecimals = 10000;

    DeFiCreationInfo[] public defi; /** @dev store creation data for swap pairs, farms, and compounders */
    uint public defiCount;
    uint public package; /** @dev IDO package tier number from 1 -> 3*/
    address public IDOImplementation; /** @dev address of the IDO implementation to use for IDO logic */
    address public IDOToken; /** @dev address of the token the IDO is selling */
    address public saleToken; /** @dev address of the token participants use to buy the IDO token */
    uint public price; /** @dev the price of the IDO token w/r/t the sale token ie 0.000025 wETH/GFI */
    uint public totalAmount; /** @dev the total amount of tokens to be sold in the sale be mindful of decimals */
    uint public saleAmount; /** @dev amount of tokens to sell */
    uint public saleStart; /** @dev timestamp for when sale starts */
    uint public saleEnd; /** @dev timestamp for when sale ends */
    uint public commission; /** @dev number from 0 -> 10000 representing 00.00% -> 100.00% commission for the sale */
    uint public minCapitalRaised; /** @dev the minimum amount of saleTokens needed in order to carry on with distributing IDO tokens, else return users funds */

    address public GFIcommission; /** @dev where commission is sent */
    address public treasury; /** @dev where sale procedes is sent*/
    address public reserves; /** @dev where unsold IDO tokens is sent */
    address public GFISudoUser; /** @dev Gravity Finance address with elevated IDO privelages */
    address public clientSudoUser; /** @dev Client address with elevated IDO privelages */
    uint public timelock; /** @dev amount of time owner must wait until they can call adminWithdraw, timer doesn't start until withdraw() is called */
    uint public gracePeriod; /** @dev once sale is over how much time do people have to wait before claiming*/

    uint public tier1Allocation; /** @dev the max amount of sale tokens a tier 1 participant can invest */
    uint public tier2Allocation; /** @dev the max amount of sale tokens a tier 2 participant can invest */
    uint public publicAllocation; /** @dev the max amount of sale tokens a public participant can invest */
    uint[4] public tierBuyLimits;
    uint[4] public tierAmounts;
    uint public brokenTrustFee; /** @dev number from 0 -> 10000 representing 00.00% -> 100.00% fee for insubordination */

    modifier checkLock() {
        require(!locked, 'Gravity Finance: Agreement locked');
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, 'Gravity Finance: Caller not owner');
        _;
    }

    function initialize(address _owner, address _IDOImplementation) external initializer{
        owner = _owner;
        GFISudoUser = _owner; //make the owner of this contract a sudo for the IDO contract
        IDOImplementation = _IDOImplementation;
    }

    function lockVariables() external onlyOwner checkLock{
        require(GFIcommission != address(0), 'Gravity Finance: Commission address not set');
        require(package <= 3 && package > 0, 'Gravity Finance: Unsupported package');
        require(IDOToken != address(0), 'Gravity Finance: IDO Token address not set');
        require(saleToken != address(0), 'Gravity Finance: sale Token address not set');
        require(price > 0, 'Gravity Finance: Price not set');
        require(saleStart > 0, 'Gravity Finance: saleStart not set');
        require(saleEnd > saleStart, 'Gravity Finance: saleEnd not greater than saleStart');
        require(commission > 0 && commission <= 10000, 'Gravity Finance: Comission not correct');
        require(clientSudoUser != address(0), 'Gravity Finance: Client Sudo User not set');
        require(treasury != address(0), 'Gravity Finance: Treasury not set');
        require(reserves != address(0), 'Gravity Finacne: Reserves not set');
        require(timelock > 0, 'Gravity Finance: Timelock not set');
        require( (tierAmounts[0] + tierAmounts[1] + tierAmounts[2] + tierAmounts[3]) == saleAmount, 'Gravity Finance: Sale amounts do not add up');
        uint total;
        
        for(uint i = 0; i < defi.length; i++){
            total += defi[i].farmAllocation;
            total += defi[i].swapAllocation;
            if(defi[i].percentOfSale == 0){
                require(defi[i].lpToken != address(0), 'Gravity Finance: No pair creation, with no lp address');
            }
        }
        total += saleAmount;
        require(total == totalAmount, 'Gravity Finance: Total amounts do not add up');
        defiCount = defi.length;
        locked = true;
    }

    function setGFICommission(address _address) external onlyOwner checkLock{
        GFIcommission = _address;
    }

    function setPackage(uint _package) external onlyOwner checkLock{
        package = _package;
    }

    function setIDOToken(address _IDOToken) external onlyOwner checkLock{
        IDOToken = _IDOToken;
    }
    function setSaleToken(address _saleToken) external onlyOwner checkLock{
        saleToken = _saleToken;
    }
    function setPrice(uint _price) external onlyOwner checkLock{
        price = _price;
    }
    function setTotalAmount(uint _totalAmount) external onlyOwner checkLock{
        totalAmount = _totalAmount;
    }
    function setSaleAmount(uint _saleAmount) external onlyOwner checkLock{
        saleAmount = _saleAmount;
    }
    function setSaleStart(uint _saleStart) external onlyOwner checkLock{
        saleStart = _saleStart;
    }
    function setSaleEnd(uint _saleEnd) external onlyOwner checkLock{
        saleEnd = _saleEnd;
    }

    function setCommission(uint _commission) external onlyOwner checkLock{
        commission = _commission;
    }

    function setMinCapitalRaised(uint _min) external onlyOwner checkLock{
        require(minCapitalRaised < (price * saleAmount), 'Invalid min capital');
        minCapitalRaised = _min;
    }

    function adjustDeFi(uint _index, uint _percentOfSale, uint _swapAllocation, address _otherAsset, uint _farmAllocation, address _lpToken, bool _createCompounder, uint _blockReward, uint _lifeSpan, uint _bonusLifeSpan, uint _bonus) external onlyOwner checkLock{
        require(totalAmount > 0 && price > 0, 'Gravity Finance: Variables not set');
        uint requiredSwapAllocation = totalAmount * price *_percentOfSale / percentDecimals;
        require(requiredSwapAllocation >= _swapAllocation, 'Gravity Finance: Swap Allocation too low');
        DeFiCreationInfo memory defiInfo = DeFiCreationInfo({
            percentOfSale: _percentOfSale,
            swapAllocation: _swapAllocation,
            otherAsset: _otherAsset,
            farmAllocation: _farmAllocation,
            blockReward: _blockReward,
            lifeSpan: _lifeSpan,
            bonusLifeSpan: _bonusLifeSpan,
            bonus: _bonus,
            created: false,
            lpToken: _lpToken,
            createCompounder: _createCompounder
        });
        
        if(_index >= defi.length){//if trying to write to an index that doesn't exist, then push it
            defi.push(defiInfo);
        }
        else{//if index exists then just overwrite it(update and existing index)
            defi[_index] = defiInfo;
        }
    }

    function setBuyLimits( uint _public, uint _tier2, uint _tier1, uint _tier3) external onlyOwner checkLock{
        tierBuyLimits[0] = _public;
        tierBuyLimits[1] = _tier1;
        tierBuyLimits[2] = _tier2;
        tierBuyLimits[3] = _tier3;
    }

    /**
    * @dev 
    **/
    function adjustClientSudoUsers(address _address) external onlyOwner checkLock{
        clientSudoUser = _address;
    }

    /**
    * @dev set the address where sale procedes will go
    **/
    function setTreasury(address _address) external onlyOwner checkLock{
        treasury = _address;
    }

    /**
    * @dev set the address where excess IDO tokens will be sent
    **/
    function setReserves(address _address) external onlyOwner checkLock{
        reserves = _address;
    }

    /**
    * @dev amount of time that must pass before owner can call adminWithdraw()
    **/
    function setTimeLock(uint _timelock) external onlyOwner checkLock{
        timelock = _timelock;
    }

    function setGracePeriod(uint _gracePeriod) external onlyOwner checkLock{
        gracePeriod = _gracePeriod;
    }

    function setTierAmounts(uint _public, uint _tier1, uint _tier2, uint _tier3) external onlyOwner checkLock{
        require(saleAmount > 0, 'Gravity Finance: saleAmount not set');
        require((_tier1 + _tier2 + _tier3 + _public) == saleAmount, 'Gravity Finance: Pool amounts do not add up to saleAmount');
        tierAmounts[0] = _public;
        tierAmounts[1] = _tier1;
        tierAmounts[2] = _tier2;
        tierAmounts[3] = _tier3;
    }

    function setBrokenTrustFee(uint fee) external onlyOwner checkLock{
        brokenTrustFee = fee;
    }

}


// File contracts/interfaces/IFarmFactory.sol


interface IFarmFactory {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function getFarm(address depositToken, address rewardToken, uint version) external view returns (address farm);
    function getFarmIndex(address depositToken, address rewardToken) external view returns (uint fID);

    function whitelist(address _address) external view returns (bool);
    function governance() external view returns (address);
    function incinerator() external view returns (address);
    function harvestFee() external view returns (uint);
    function gfi() external view returns (address);
    function feeManager() external view returns (address);
    function allFarms(uint fid) external view returns (address); 
    function createFarm(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external;
    function farmVersion(address deposit, address reward) external view returns(uint);
}


// File contracts/interfaces/ICompounderFactory.sol

struct ShareInfo{
    address depositToken;
    address rewardToken;
    address shareToken;
    uint vaultFee;
    uint minHarvest;
    uint maxCallerReward;
    uint callerFeePercent;
    bool lpFarm;
    address lpA; //only applies to lpFarms
    address lpB;
}

interface ICompounderFactory {

    function farmAddressToShareInfo(address farm) external view returns(ShareInfo memory);
    function tierManager() external view returns(address);
    function getFarm(address shareToken) external view returns(address);
    function gfi() external view returns(address);
    function swapFactory() external view returns(address);
    function createCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _vaultFee, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external;
}


// File contracts/LaunchPad/IDOFactory.sol







interface IbaseIDOImplementation{
    function initializeIDO(address) external;
}


/**
 * @title The IDO factory creates Agreements, and IDOs using openzeppelin Clones library
 * @author crispymangoes
 */
contract IDOFactory is Ownable {
    mapping(bytes32 => bool) IDOValid;
    address[] public allIDOs;
    address public lastAgreement;

    address public farmFactory;
    address public compounderFactory;
    address public tierManager;
    mapping(address => bool) isIDO;

    struct ContractPackage{
        address IDOImplementation;
        address AgreementImplementation;
    }

    mapping(bytes32 => ContractPackage) public productList;

    /**
     * @notice emitted when new contract package is created
     * @param IDOtype a string identier used to distinguish between IDO types
     * @param version uint version number, so IDOtypes can be revised and improved upon
     * @param newIDOImplementation address to use for IDO implementation logic
     * @param requiredAgreement address to use for Agreement implementation logic
     */
    event ContractPackageCreated( string IDOtype, uint version, address newIDOImplementation, address requiredAgreement);

    /**
     * @notice emitted when updateSharedVariables is called
     * @notice emits the NEW variables
     */
    event SharedVariablesUpdated(address _tierManager, address _farmFactory, address _compounderFactory);

    /// @notice modifier used so that only IDOs can create farms and Compounders
    modifier onlyIDO() {
        require(isIDO[msg.sender], 'Gravity Finance: Forbidden');
        _;
    }

    constructor(address _tierManager) {
        tierManager = _tierManager;
    }

    /****************** External Priviledged Functions ******************/
    /**
     * @notice owner function to change the tier manager, farm factory, and compounder factory
     */
    function updateSharedVariables(address _tierManager, address _farmFactory, address _compounderFactory) external onlyOwner{
        tierManager = _tierManager;
        farmFactory = _farmFactory;
        compounderFactory = _compounderFactory;
        emit SharedVariablesUpdated(_tierManager, _farmFactory, _compounderFactory);
    }

    /**
     * @notice allows owner to add new IDO implementations and Agreement implementations
     * @dev IDOtype + version needs to be unique
     */
    function addNewIDOType(string memory IDOtype, uint version, address newIDOImplementation, address requiredAgreement)
        external
        onlyOwner
    {
        require(
            newIDOImplementation != address(0),
            "Gravity Finance: Can not make zero address and implementation"
        );
        require(
            requiredAgreement != address(0),
            "Gravity Finance: Can not make zero address and Agreement"
        );
        bytes32 record = getContractPackageID(IDOtype, version);
        
        //check if IDOtype already exists, sufficient check to just check if IDOImplementation is zero address
        // since above requires make it so that no ContractPackage can have zero address contracts
        require(productList[record].IDOImplementation == address(0), 'Gravity Finance: IDO Type already exists');
        
        productList[record] = ContractPackage({
            IDOImplementation: newIDOImplementation,
            AgreementImplementation: requiredAgreement
        });

        emit ContractPackageCreated(IDOtype, version, newIDOImplementation, requiredAgreement);
    }

    /**
     * @notice allows owner to approve or revoke IDO approval
     * @notice allows a 3rd party to retain control of IDO tokens 
     * if they need to be sent on IDO initialization
     */
    function approveOrRejectIDO(
        bool status,
        address from,
        address agreement
    ) external onlyOwner{
        bytes32 _hash = keccak256(
            abi.encodePacked(
                from,
                agreement
            )
        );
        IDOValid[_hash] = status;
    }

    /**
     * @notice First step in the IDO creation process
     * owner creates an agreement, finalizes it(by locking it)
     * then calls approveOrRejectIDO
     * finally the 3rd party must actually create the IDO
     */
    function createAgreement(string memory IDOtype, uint version) external onlyOwner{
        //create the agreement
        bytes32 record = getContractPackageID(IDOtype, version);
        address AgreementImplementation = productList[record].AgreementImplementation;
        address agreement = Clones.clone(AgreementImplementation);
        
        //initialize the agreement
        IIDOAgreement(agreement).initialize(msg.sender, productList[record].IDOImplementation);
        lastAgreement = agreement;
    }

    /**
     * @notice allows IDOs to create Gravity Finance farms 
     */
    function deployFarm(address _depositToken, address _rewardToken, uint _amount, uint _blockReward, uint _start, uint _end, uint _bonusEnd, uint _bonus) external onlyIDO{
        //create a farm
        IERC20(_rewardToken).approve(farmFactory, _amount);
        IFarmFactory(farmFactory).createFarm(_depositToken, _rewardToken, _amount, _blockReward, _start, _end, _bonusEnd, _bonus);
    }

    /**
     * @notice allows IDOs to create Gravity Finance compounder vaults
     */
    function deployCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external onlyIDO{
        //create the compounder
        ICompounderFactory(compounderFactory).createCompounder(_farmAddress, _depositToken, _rewardToken, 100, _maxCallerReward, _callerFee, _minHarvest, _lpFarm, _lpA, _lpB);
    }

    /****************** External State Changing Functions ******************/
    /**
     * @notice called by the 3rd party to actually create their IDO contract
     * @notice the agreement for this IDO must be locked
     */
    function createIDO(address agreement) external {
        bytes32 _hash = _getIDOHash(msg.sender, agreement);
        require(IDOValid[_hash], 'Gravity Finance: IDO parameters not valid');
        IDOValid[_hash] = false;
        IIDOAgreement Agreement = IIDOAgreement(agreement);
        require(Agreement.locked(), 'Gravity Finance: Agreement not locked!');
        bytes32 salt = keccak256(abi.encodePacked(Agreement.IDOToken(), Agreement.saleToken(), block.timestamp));
        address IDOClone = Clones.cloneDeterministic(Agreement.IDOImplementation(), salt);
        IbaseIDOImplementation(IDOClone).initializeIDO(agreement);
        allIDOs.push(IDOClone);
        isIDO[IDOClone] = true;
    }

    /****************** Public Pure Functions ******************/
    /**
     * @dev helper function to get the bytes32 var used to interact with productList
     */
    function getContractPackageID(string memory name, uint version) public pure returns(bytes32 contractPackageID){
            contractPackageID = keccak256(abi.encodePacked(name, version));
    }

    /****************** Internal Pure Functions ******************/
    /**
     * @dev helper function used to get bytes32 hash for IDO creation
     */
    function _getIDOHash(
        address from,
        address agreement
    ) internal pure returns (bytes32 _hash) {
        _hash = keccak256(
            abi.encodePacked(
                from,
                agreement
            )
        );
    }
}