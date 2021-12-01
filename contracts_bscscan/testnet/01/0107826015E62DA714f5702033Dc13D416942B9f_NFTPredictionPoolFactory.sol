// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Role/PoolCreator.sol";
import "../Interfaces/IRewardManager.sol";
import "./NFTPredictionPoolProxy.sol";

contract NFTPredictionPoolFactory is PoolCreator{
    ISparksToken public immutable sparksToken;
    IRewardManager public immutable rewardManager;
    address public usdStorage;

    address public superAdmin;
    address public immutable usdTokenAddress;
    address public nftPredictionPoolImplementationAddr;

    uint256 public nftPoolTaxRate;
    uint256 public minimumStakeAmount;

    event PoolCreated(
        address indexed pool,
        string poolType,
        string priceCurrency,
        address nftContract,
        // uint256 launchDate,
        // uint256 maturityTime,
        // uint256 lockTime,
        // uint256 purchaseExpirationTime,
        // uint256 sizeAllocation,
        // uint256 stakeApr,
        // uint256 prizeAmount,
        // uint256 stakingPoolTaxRate,
        // uint256 purchasePriceInUSD,
        // uint256 minimumStakeAmount,
        // uint256 nftType
        uint256[11] variables,
        uint256[8] ranks,
        uint256[8] percentages
    );

    event NewNFTPoolImplemnetationWasSet();

    event NewSuperAdminWasSet();
    event NewUSDStorageWasSet();

    constructor(
        ISparksToken _sparksToken,
        IRewardManager _rewardManager,
        address _usdStorage,
        address _usdTokenAddress,
        address _nftPredictionPoolImplementationAddr,
        address _superAdmin
    ) {
        sparksToken = _sparksToken;
        rewardManager = _rewardManager;

        usdStorage = _usdStorage;
        usdTokenAddress = _usdTokenAddress;

        nftPredictionPoolImplementationAddr = _nftPredictionPoolImplementationAddr;
        superAdmin = _superAdmin;
        
        nftPoolTaxRate = 300;
    }

    function createPoolProxy(
        string memory _poolType,
        string memory _priceCurrency,
        address _nftToken,
        // uint256 launchDate,
        // uint256 maturityTime,
        // uint256 lockTime,
        // uint256 purchaseExpirationTime,
        // uint256 sizeAllocation,
        // uint256 stakeApr,
        // uint256 prizeAmount, 
        // uint256 burnRate,
        // uint256 purchasePriceInUSD,
        // uint256 minimumStakeAmount,
        // uint256 nftType
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages
        
    ) external onlyPoolCreator returns (address) {

        require(
            _ranks.length == _percentages.length,
            "length of ranks and percentages should be same"
        );

        NFTPredictionPoolProxy nftPoolProxy = new NFTPredictionPoolProxy();
        address nftPoolProxyAddr = address(nftPoolProxy);

        nftPoolProxy.upgradeTo(nftPredictionPoolImplementationAddr);

        if (_variables[6] == 0) {
            _variables[6] = nftPoolTaxRate;
        }
  

        nftPoolProxy.initialize(
            _poolType,
            _priceCurrency,
            sparksToken, 
            rewardManager, 
            usdStorage,
            usdTokenAddress,
            _nftToken, 
            _msgSender(),
            _variables, 
            _ranks, 
            _percentages
        );

        emit PoolCreated(
            nftPoolProxyAddr,
            _poolType,
            _priceCurrency,
            _nftToken,
            _variables,
            _ranks,
            _percentages
        );

        nftPoolProxy.transferOwnership(superAdmin);

        rewardManager.addPool(nftPoolProxyAddr);

        return nftPoolProxyAddr;
    }

    // Call this in case you want to use a new StakingPoolImplementation from now on
    // Notice that in case you want to upgrade a working pool, you should not call this
    // ToDO: need new modifier other than onlyPoolCreator to prevent mistakes?
    function setNewNFTPoolImplementationAddr(address _ImpAdr) external onlyPoolCreator {
        require(
            nftPredictionPoolImplementationAddr != _ImpAdr, 
            'This address is the implementation that is  already being used'
        );
        nftPredictionPoolImplementationAddr = _ImpAdr;
        emit NewNFTPoolImplemnetationWasSet();
    }


    /**
     * @notice Changes superAdmin's address so that new StakingPoolProxies have this new superAdmin
    */
    function setNewSuperAdmin(address _superAdmin) external onlyPoolCreator {
        superAdmin = _superAdmin;
        emit NewSuperAdminWasSet();
    }

    function setNewUSDStorage(address _usdStorage) external onlyPoolCreator {
        usdStorage = _usdStorage;
        emit NewUSDStorageWasSet();
    }

    function setDefaultTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "0720 Tax connot be over 100% (10000 BP)"
        );
        nftPoolTaxRate = newStakingPoolTaxRate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Roles.sol";

contract PoolCreator is Context {
    using Roles for Roles.Role;

    event PoolCreatorAdded(address indexed account);
    event PoolCreatorRemoved(address indexed account);

    Roles.Role private _poolCreators;

    constructor() {
        if (!isPoolCreator(_msgSender())) {
            _addPoolCreator(_msgSender());
        }
    }

    modifier onlyPoolCreator() {
        require(
            isPoolCreator(_msgSender()),
            "PoolCreatorRole: caller does not have the PoolCreator role"
        );
        _;
    }

    function isPoolCreator(address account) public view returns (bool) {
        return _poolCreators.has(account);
    }

    function addPoolCreator(address account) public onlyPoolCreator {
        _addPoolCreator(account);
    }

    function renouncePoolCreator() public {
        _removePoolCreator(_msgSender());
    }

    function _addPoolCreator(address account) internal {
        _poolCreators.add(account);
        emit PoolCreatorAdded(account);
    }

    function _removePoolCreator(address account) internal {
        _poolCreators.remove(account);
        emit PoolCreatorRemoved(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: provide an interface so IDO-prediction can work with that
interface IRewardManager {

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTPredictionPoolStorageStructure.sol";

contract NFTPredictionPoolProxy is NFTPredictionPoolStorageStructure {

    modifier onlyPoolCreator() {
        require (msg.sender == poolCreator, "msg.sender is not an owner");
        _;
    }

    event ImplementationUpgraded();

    constructor() {
        poolCreator = msg.sender;
        upgradeEnabled = true;
    }

    // here we can upgrade our implementation
    function upgradeTo(address _newNFTPredictionPoolImplementation) external onlyPoolCreator {
        require(upgradeEnabled, "Upgrade is not enabled yet");
        require(nftPredictionPoolImplementation != _newNFTPredictionPoolImplementation);
        _setNFTPoolImplementation(_newNFTPredictionPoolImplementation);
        upgradeEnabled = false;
    }

    /**
     * @notice StakingPoolImplementation can't be upgraded unless superAdmin sets upgradeEnabled
     */
    function enableUpgrade() external onlyOwner{
        upgradeEnabled = true;
    }

    function disableUpgrade() external onlyOwner{
        upgradeEnabled = false;
    }

    // initializer modifier is used to make sure initialize() is not called more than once
    // because we want it to act like a constructor
    function initialize(
        string memory _poolType,
        string memory _priceCurrency,
        ISparksToken _sparksToken,
        IRewardManager _rewardManager,
        address _usdStorage,
        address _usdTokenAddress,
        address _nftToken,
        address _poolCreator,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages
    ) public initializer onlyPoolCreator
    {
        // we should call inits because we don't have a constructor to do it for us
        OwnableUpgradeable.__Ownable_init();
        ContextUpgradeable.__Context_init();

        require(
            _variables[0] > block.timestamp,
            "0301 launch date can't be in the past"
        );

        require(
            _variables[10] == erc721 || _variables[10] == erc1155,
            "0302 only 721 and 1155 ERCs"
        );

        
        poolType = _poolType;
        priceCurrency = _priceCurrency;

        sparksToken = _sparksToken;
        rewardManager = _rewardManager;
        
        usdStorage = _usdStorage;
        usdToken = IERC20(_usdTokenAddress);

        nftToken = _nftToken;
        poolCreator = _poolCreator;

        // deployDate = block.timestamp;
        launchDate = _variables[0];

        maturityTime = _variables[1];
        lockTime = _variables[2];
        purchaseExpirationTime = _variables[3];

        sizeAllocation = _variables[4];
        stakeApr = _variables[5];
        prizeAmount = _variables[6];
        stakeTaxRate = _variables[7];
        purchasePriceInUSD = _variables[8];
        minimumStakeAmount = _variables[9];
        nftType = _variables[10];

        for (uint256 i = 0; i < _ranks.length; i++) {

            if (_percentages[i] == 0) break;

            prizeRewardRates.push(
                PrizeRewardRate({
                    rank: _ranks[i], 
                    percentage: _percentages[i]
                })
            );
        }


        lps.launchDate = launchDate;
        lps.lockTime = lockTime;
        lps.maturityTime = maturityTime;
        lps.floorPriceOnMaturity = floorPriceOnMaturity;
        lps.prizeAmount = prizeAmount;
        lps.stakeApr = stakeApr;
        lps.isMatured = isMatured;
    }

    fallback() external payable {
        address opr = nftPredictionPoolImplementation;
        require(opr != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), opr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    // Added to get rid of the warning
    receive() external payable {
        // custom function code
    }

    function _setNFTPoolImplementation(address _newNFTPool) internal {
        nftPredictionPoolImplementation = _newNFTPool;
        emit ImplementationUpgraded();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
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
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Note that we must use upgradeable forms of these contracts, otherwise we must set our contracts
// as abstract because the top level contract which is StakingPoolProxy does not have a constructor
// to call their constructors in it, so to avoid that error we must use upgradeable parent contrats
// their code size doesn't have noticable overheads
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../Interfaces/IRewardManager.sol";
import "../Interfaces/ISparksToken.sol";

import "../Libraries/BasisPoints.sol";
import "../Libraries/CalculateRewardLib.sol";
import "../Libraries/ClaimRewardLib.sol";

contract NFTPredictionPoolStorageStructure is
    OwnableUpgradeable,
    ERC721Holder,
    ERC1155Holder
{
    address public nftPredictionPoolImplementation;
    address public poolCreator;

    // declared for passing params to libraries
    struct LibParams {
        uint256 launchDate;
        uint256 lockTime;
        uint256 maturityTime;
        uint256 floorPriceOnMaturity;
        uint256 prizeAmount;
        uint256 stakeApr;
        bool isMatured;
    }
    LibParams public lps;

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction1;
        uint256 pricePrediction2;
        uint256 difference;
        uint256 rank;
        bool didPrizeWithdrawn;
        bool didUnstake;
    }

    struct NFTWithID {
        bool isWinner;
        bool isUSDPaid;
        uint256 nftID; 
    }

    struct PrizeRewardRate {
        uint256 rank;
        uint256 percentage;
    }

    address[] public stakers;
    address[] public winnerStakers;
    PrizeRewardRate[] public prizeRewardRates;

    mapping(address => StakeWithPrediction) public predictions;
    mapping(address => NFTWithID) public nftRecipients;

    // it wasn't possible to use totem token interface since we use taxRate variable
    ISparksToken public sparksToken;
    IRewardManager public rewardManager;
    address public usdStorage;
    IERC20 public usdToken;
    address public nftToken;
    
    // can be "ERC721" or "ERC1155"
    uint256 public constant erc721 = 721;
    uint256 public constant erc1155 = 1155;
    
    uint256 public nftType;

    string public poolType;
    // since most NFT's price is settled in ETH, but can be "BNB" or "USDT" too
    string public priceCurrency;

        // 100 means 1%
    uint256 public constant sizeLimitRangeRate = 500;


    
    // the default dexDecimal is 8 but can be modified in setIDOPrices
    uint256 public constant dexDecimal = 8;

    uint256 public constant tier1 = 3000*(10**18);
    uint256 public constant tier2 = 30000*(10**18);
    uint256 public constant tier3 = 150000*(10**18);
    

    uint256 public launchDate;
    uint256 public lockTime;
    uint256 public maturityTime;
    uint256 public purchaseExpirationTime;

    uint256 public sizeAllocation; // total TOTM can be staked
    uint256 public stakeApr; // the annual return rate for staking TOTM

    uint256 public prizeAmount;

    uint256 public stakeTaxRate;
    uint256 public minimumStakeAmount;

    uint256 public totalStaked;

    // matruing price and purchase price should have same decimals
    uint256 public floorPriceOnMaturity;
    uint256 public purchasePriceInUSD;


    bool public isAnEmergency;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;

    /**
     * @dev StakingPoolImplementation can't be upgraded unless superAdmin sets this flag.
     */
    bool public upgradeEnabled;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: add an interface for this to add the interface instead of 
interface ISparksToken {
    
    function setLocker(address _locker) external;

    function setDistributionTeamsAddresses(
        address _SeedInvestmentAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingRewardsAddr,
        address _CommunityDevelopmentAddr,
        address _MarketingDevelopmentAddr,
        address _LiquidityPoolAddr,
        address _AirDropAddr
    ) external;

    function distributeTokens() external;

    function getTaxationWallet() external returns (address);

    function setTaxationWallet(address _newTaxationWallet) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BasisPoints.sol";
import "../Staking/NFTPredictionPoolStorageStructure.sol";

library CalculateRewardLib {

    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant dexDecimal = 8;

    function calcStakingReturn(uint256 totalRewardRate, uint256 timeDuration, uint256 totalStakedBalance) 
        public
        pure
        returns (uint256) 
    {
        uint256 yearInSeconds = 365 days;

        uint256 first = (yearInSeconds**2)
            .mul(10**8);

        uint256 second = timeDuration
            .mul(totalRewardRate) 
            .mul(yearInSeconds)
            .mul(5000);
        
        uint256 third = totalRewardRate
            .mul(yearInSeconds**2)
            .mul(5000);

        uint256 forth = (timeDuration**2)
            .mul(totalRewardRate**2)
            .div(6);

        uint256 fifth = timeDuration
            .mul(totalRewardRate**2)
            .mul(yearInSeconds)
            .div(2);

        uint256 sixth = (totalRewardRate**2)
            .mul(yearInSeconds**2)
            .div(3);
 
        uint256 rewardPerStake = first.add(second).add(forth).add(sixth);

        rewardPerStake = rewardPerStake.sub(third).sub(fifth);

        rewardPerStake = rewardPerStake
            .mul(totalRewardRate)
            .mul(timeDuration);

        rewardPerStake = rewardPerStake
            .mul(totalStakedBalance)
            .div(yearInSeconds**3)
            .div(10**12);

        return rewardPerStake; 
    }

    // getTotalStakedBalance return remained staked balance
    function getTotalStakedBalance(NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake)
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance <= 0) return 0;

        uint256 totalStakedBalance = 0;

        if (!_userStake.didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                _userStake.stakedBalance
            );
        }

        return totalStakedBalance;
    }


    ////////////////////////// internal functions /////////////////////
    function _getPrizeAmount(
        uint256 _rank,
        NFTPredictionPoolStorageStructure.LibParams storage _lps,
        NFTPredictionPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        internal
        view
        returns (uint256)
    {

        for (uint256 i = 0; i < _prizeRewardRates.length; i++) {
            if (_rank <= _prizeRewardRates[i].rank) {
                return (_lps.prizeAmount).mulBP(_prizeRewardRates[i].percentage);
            }
        }

        return 0;
    } 

    function _getStakingReturnPerStake(
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake, 
        NFTPredictionPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {

        if (_userStake.didUnstake) {
            return 0;
        }

        uint256 maturityDate = 
            _lps.launchDate + 
            _lps.lockTime + 
            _lps.maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;


        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance
        uint256 rewardPerStake = calcStakingReturn(
            _lps.stakeApr,
            timeTo.sub(_userStake.stakedTime),
            _userStake.stakedBalance
        );

        rewardPerStake = rewardPerStake.sub(_userStake.amountWithdrawn);

        return rewardPerStake;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "./BasisPoints.sol";
import "../Staking/NFTPredictionPoolStorageStructure.sol";

library ClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;


    ////////////////////////// public functions /////////////////////
    function getStakingReturn(
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake,
        NFTPredictionPoolStorageStructure.LibParams storage _lps
    )
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance == 0) return 0;

        uint256 reward = CalculateRewardLib._getStakingReturnPerStake(_userStake, _lps);

        return reward;
    }

    function withdrawStakingReturn(
        uint256 _rewardPerStake,
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.lastWithdrawalTime = block.timestamp;
        _userStake.amountWithdrawn = _userStake.amountWithdrawn.add(
            _rewardPerStake
        );
    }

    function withdrawPrize(
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake
    )
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didPrizeWithdrawn = true;
    }

    function withdrawStakedBalance(
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didUnstake = true;
    }

    function getPrize(
        NFTPredictionPoolStorageStructure.StakeWithPrediction storage _userStake, 
        NFTPredictionPoolStorageStructure.LibParams storage _lps,
        NFTPredictionPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!_lps.isMatured) return 0;

        // users that don't stake don't get any prize also
        if (_userStake.stakedBalance <= 0) return 0;

        // uint256 maturingBTCPrizeAmount =
        //     (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        // uint256 btcReward = 0;

        // only calculate the prize amount for stakes that are not withdrawn yet
        if (!_userStake.didPrizeWithdrawn) {

            uint256 _totemAmount = CalculateRewardLib._getPrizeAmount(_userStake.rank, _lps, _prizeRewardRates);

            reward = reward.add(
                        _totemAmount
                );      
        }

        return reward;
    }


    // function withdrawNFT(
    //     NFTPredictionPoolStorageStructure.NFTWithID storage _winnerNFT
    // )
    //     public
    // {
    //     if (!_winnerNFT.isWinner) return;

    //     _winnerNFT.didNFTwithdrawn = true;
    // }

    function payUSDForNFT(
        NFTPredictionPoolStorageStructure.NFTWithID storage _winnerNFT
    )
        public
    {
        if (_winnerNFT.isUSDPaid) return;

        _winnerNFT.isUSDPaid = true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}