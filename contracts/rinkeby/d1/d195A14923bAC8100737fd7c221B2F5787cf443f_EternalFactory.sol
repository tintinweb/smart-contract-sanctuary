//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../interfaces/IEternalFactory.sol";
import "../interfaces/ILoyaltyGage.sol";
import "../gages/LoyaltyGage.sol";
import "../inheritances/OwnableEnhanced.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Contract for the Eternal gaging platform
 * @author Nobody (me)
 * @notice The Eternal contract holds all user-data and gage logic.
 */
contract EternalFactory is IEternalFactory, OwnableEnhanced {

/////–––««« Variables: Interfaces, Addresses and Hashes »»»––––\\\\\

    // The Eternal shared storage interface
    IEternalStorage public immutable eternalStorage;
    // The Eternal token interface
    IERC20 private eternal;
    // The Eternal treasury interface
    IEternalTreasury private eternalTreasury;

    // The keccak256 hash of this address
    bytes32 public immutable entity;

/////–––««« Variables: Hidden Mappings »»»––––\\\\\
/**
    // Keeps track of the respective gage tied to any given ID
    mapping (uint256 => address) gages

    // Keeps track of the risk percentage for any given asset's liquidity gage
    mapping (address => uint256) risk;

    // Keeps track of whether a user is in a liquid gage for a given asset
    mapping (address => mapping (address => bool)) inLiquidGage
*/

/////–––««« Variables: Gage Bookkeeping »»»––––\\\\\

    // Keeps track of the latest Gage ID
    bytes32 public immutable lastId;

/////–––««« Variables: Constants, Factors and Limits »»»––––\\\\\

    // The holding time constant used in the percent change condition calculation (decided by the Eternal Fund) (x 10 ** 6)
    bytes32 public immutable timeFactor;
    // The average amount of time that users provide liquidity for
    bytes32 public immutable timeConstant;
    // The risk constant used in the calculation of the treasury's risk (x 10 ** 4)
    bytes32 public immutable riskConstant;
    // The general limiting variable deciding the total amount of ETRNL which can be used from the treasury's reserves
    bytes32 public immutable psi;

/////–––««« Variables: Counters and Estimates »»»––––\\\\\
    // The total number of ETRNL transacted with fees in the last full 24h period
    bytes32 public immutable alpha;
    // The total number of ETRNL transacted with fees in the current 24h period (ongoing)
    bytes32 public immutable transactionCount;
    // Keeps track of the UNIX time to recalculate the average transaction estimate
    bytes32 public immutable oneDayFromNow;
    // The minimum token value estimate of transactions in 24h, used in case the alpha value is not determined yet
    bytes32 public immutable baseline;

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor (address _eternal, address _eternalStorage) {
        // Set the initial Eternal token and storage interfaces
        eternal = IERC20(_eternal);
        eternalStorage = IEternalStorage(_eternalStorage);

        // Initialize keccak256 hashes
        entity = keccak256(abi.encodePacked(address(this)));
        lastId = keccak256(abi.encodePacked("lastId"));
        timeFactor = keccak256(abi.encodePacked("timeFactor"));
        timeConstant = keccak256(abi.encodePacked("timeConstant"));
        riskConstant = keccak256(abi.encodePacked("riskConstant"));
        baseline = keccak256(abi.encodePacked("baseline"));
        psi = keccak256(abi.encodePacked("psi"));
        alpha = keccak256(abi.encodePacked("alpha"));
        transactionCount = keccak256(abi.encodePacked("transactionCount"));
        oneDayFromNow = keccak256(abi.encodePacked("oneDayFromNow"));
    }

    function initialize(address _treasury, address _fund) external onlyAdmin {
        // Set the initial treasury interface
        eternalTreasury = IEternalTreasury(_treasury);

        // Set initial constants, factors and limiting variables
        eternalStorage.setUint(entity, timeFactor, 6 * (10 ** 6));
        eternalStorage.setUint(entity, timeConstant, 15);
        eternalStorage.setUint(entity, riskConstant, 100);
        eternalStorage.setUint(entity, psi, 4167 * (10 ** 6) * (10 ** 18));
        // Set initial baseline
        eternalStorage.setUint(entity, baseline, 10 ** 7);
        // Initialize the transaction count time tracker
        eternalStorage.setUint(entity, oneDayFromNow, block.timestamp + 1 days);

        attributeFundRights(_fund);
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\

    /**
     * @notice Creates an ETRNL liquid gage contract for a given user, asset and amount
     * @param asset The address of the asset being deposited in the liquid gage by the receiver
     * @param amount The amount of the asset being deposited in the liquid gage by the receiver
     *
     * Requirements:
     *
     * - The asset must be supported by Eternal
     * - Receivers (users) cannot deposit ETRNL into liquid gages
     * - There must be less active gages than the liquid gage limit dictates
     * - Users are only able to join 1 liquid gage per Asset-ETRNL pair offered (the maximum being the number of existing liquid gage pairs)
     * - The Eternal Treasury cannot have a liquidity swap in progress
     */
    function initiateEternalLiquidGage(address asset, uint256 amount) external payable override returns(uint256) {
        // Checks
        uint256 userRisk = eternalStorage.getUint(entity, keccak256(abi.encodePacked("risk", asset)));
        require(userRisk > 0, "This asset is not supported");
        require(asset != address(eternal), "Receiver can't deposit ETRNL");
        uint256 treasuryRisk = userRisk - eternalStorage.getUint(entity, riskConstant);
        require(!_gageLimitReached(asset, amount, treasuryRisk), "ETRNL treasury reserves are dry");
        bool inLiquidGage = eternalStorage.getBool(entity, keccak256(abi.encodePacked("inLiquidGage", _msgSender(), asset)));
        require(!inLiquidGage, "Per-asset gaging limit reached");
        require(!eternalTreasury.viewUndergoingSwap(), "A liquidity swap is in progress");

        // Compute the percent change condition
        uint256 percent;
        {
        uint256 _timeConstant = eternalStorage.getUint(entity, timeConstant);
        uint256 _timeFactor = eternalStorage.getUint(entity, timeFactor);
        uint256 burnRate = eternalStorage.getUint(keccak256(abi.encodePacked(address(eternal))), keccak256(abi.encodePacked("burnRate")));
        uint256 _alpha = eternalStorage.getUint(entity, alpha) == 0 ? eternalStorage.getUint(entity, baseline) : eternalStorage.getUint(entity, alpha);
        percent = burnRate * _alpha * _timeConstant * _timeFactor / eternal.totalSupply();
        }

        // Incremement the lastId tracker
        uint256 idLast = eternalStorage.getUint(entity, lastId) + 1;
        eternalStorage.setUint(entity, lastId, idLast);

        // Deploy a new Gage
        LoyaltyGage newGage = new LoyaltyGage(idLast, percent, 2, false, address(eternalTreasury), _msgSender(), address(this));
        emit NewGage(idLast, address(newGage));
        eternalStorage.setAddress(entity, keccak256(abi.encodePacked("gages", idLast)), address(newGage));

        //Transfer the deposit to the treasury and join the gage for the user and the treasury
        if (msg.value == 0) {
            require(IERC20(asset).transferFrom(_msgSender(), address(eternalTreasury), amount), "Failed to deposit asset");
        }
        eternalTreasury.fundEternalLiquidGage{value: msg.value}(address(newGage), _msgSender(), asset, amount, userRisk, treasuryRisk);
        return idLast;
    }

    function _gageLimitReached(address asset, uint256 amountAsset, uint256 risk) private view returns(bool limitReached) {
        bytes32 treasury = keccak256(abi.encode(address(eternalTreasury)));
        // Convert the asset to ETRNL if it isn't already
        if (asset != address(eternal)) {
            (, , amountAsset) = eternalTreasury.computeMinAmounts(asset, address(eternal), amountAsset, 0);
        }

        uint256 _psi = eternalStorage.getUint(entity, psi);
        uint256 reserveStakedBalances = eternalStorage.getUint(treasury, keccak256(abi.encodePacked("reserveStakedBalances")));
        uint256 userStakedBalances = reserveStakedBalances - eternalStorage.getUint(treasury, keccak256(abi.encodePacked("reserveBalances", address(eternalTreasury))));
        // Available ETRNL is all the ETRNL which can be spent by the treasury on gages whilst still remaining sustainable
        uint256 availableETRNL = eternal.balanceOf(address(eternalTreasury)) - eternalTreasury.convertToStaked(userStakedBalances) - _psi; 
        
        limitReached = availableETRNL < amountAsset + (2 * amountAsset * risk / (10 ** 4));
    }

/////–––««« Counter/Minimax functions »»»––––\\\\\

    /**
     * @notice Update the 24h counters for the Eternal Token
     * @param amount The value used to update the counters
     * 
     * Requirements:
     *
     * - Only callable by the Eternal Token
     */
    function updateCounters(uint256 amount) external override {
        require(_msgSender() == address(eternal), "Caller must be the token");
        // If the 24h period is ongoing, then update the counter
        if (block.timestamp < eternalStorage.getUint(entity, oneDayFromNow)) {
            eternalStorage.setUint(entity, transactionCount, eternalStorage.getUint(entity, transactionCount) + amount);
        } else {
            // Update the baseline, alpha and the transaction count
            eternalStorage.setUint(entity, baseline, eternalStorage.getUint(entity, alpha));
            eternalStorage.setUint(entity, alpha, eternalStorage.getUint(entity, transactionCount));
            eternalStorage.setUint(entity, transactionCount, amount);
            // Reset the 24h period tracker
            eternalStorage.setUint(entity, oneDayFromNow, block.timestamp + 1 days);
        }
    }

/////–––««« Fund-only functions »»»––––\\\\\

    /**
     * @notice Updates the address of the Eternal Treasury contract
     * @param newContract The new address for the Eternal Treasury contract
     */
    function setEternalTreasury(address newContract) external onlyFund {
        eternalTreasury = IEternalTreasury(newContract);
    }

    /**
     * @notice Updates the address of the Eternal Token contract
     * @param newContract The new address for the Eternal Token contract
     */
    function setEternalToken(address newContract) external onlyFund {
        eternal = IERC20(newContract);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminRights}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * @notice This is a modified version of Openzeppelin's Ownable.sol, made to add certain functionalities
 * such as different modifiers (onlyFund and onlyAdminAndFund) and locking/unlocking
 */
abstract contract OwnableEnhanced is Context {

/////–––««« Variables: Addresses, Events and Locking »»»––––\\\\\

    address private _admin;
    address private _fund;

    event FundRightsAttributed(address indexed newFund);

    uint256 private _lockPeriod;

    // Used in preventing the admin from using functions a maximum of 2 weeks and 1 day after contract creation
    uint256 public immutable ownershipDeadline;

/////–––««« Constructor »»»––––\\\\\

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor () {
        address msgSender = _msgSender();
        _admin = msgSender;
        _fund = msgSender;
        ownershipDeadline = block.timestamp + 3 days;
    }

/////–––««« Modifiers »»»––––\\\\\
    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Caller is not the admin");
        require(ownershipDeadline > block.timestamp, "Admin's rights are over");
        _;
    }

    /**
     * @dev Throws if called by any account other than the fund.
     */
    modifier onlyFund() {
        require(_msgSender() == fund(), "Caller is not the fund");
        _;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Returns the address of the current fund.
     */
    function fund() public view virtual returns (address) {
        return _fund;
    }

/////–––««« Ownable-logic functions »»»––––\\\\\

    /**
     * @dev Attributes fund-rights for the Eternal Fund to a given address.
     * @param newFund The address of the new fund 
     *
     * Requirements:
     *
     * - New admin cannot be the zero address
     */
    function attributeFundRights(address newFund) public virtual onlyFund {
        require(newFund != address(0), "New fund is the zero address");
        _fund = newFund;
        emit FundRightsAttributed(newFund);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Gage.sol";
import "../interfaces/ILoyaltyGage.sol";

/**
 * @title Loyalty Gage contract
 * @author Nobody (me)
 * @notice A loyalty gage creates a healthy, symbiotic relationship between a distributor and a receiver
 */
contract LoyaltyGage is Gage, ILoyaltyGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // Address of the stakeholder which pays the discount in a loyalty gage
    address private immutable distributor;
    // Address of the stakeholder which benefits from the discount in a loyalty gage
    address private immutable receiver;
    // The asset used in the condition
    IERC20 private assetOfReference;

/////–––««« Variables: Condition computation »»»––––\\\\\

    // The percentage change condition for the total token supply (x 10 ** 11)
    uint256 private immutable percent;
    // The total supply at the time of the deposit
    uint256 private totalSupply;
    // Whether the token's supply is inflationary or deflationary
    bool private immutable inflationary;

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor(uint256 _id, uint256 _percent, uint256 _users, bool _inflationary, address _distributor, address _receiver, address _storage) Gage(_id, _users, _storage, true) {
        distributor = _distributor;
        receiver = _receiver;
        percent = _percent;
        inflationary = _inflationary;
    }
/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the address of the creator
     * @return The address of the creator
     */
    function viewDistributor() external view override returns (address){
        return distributor;
    }

    /**
     * @notice View the address of the buyer
     * @return The address of the buyer
     */
    function viewReceiver() external view override returns (address) {
        return receiver;
    }

    /**
     * @notice View the percent change condition for the total token supply of the deposit
     * @return The percent change condition for the total token supply
     */
    function viewPercent() external view override returns (uint256) {
        return percent;
    }

    /**
     * @notice View whether the deposited token suppply is inflationary or deflationary
     * @return True if the token is inflationary, False if it is deflationary
     */
    function viewInflationary() external view override returns (bool) {
        return inflationary;
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\
    /**
     * @notice Initializes a loyalty gage for the receiver and distributor
     * @param rAsset The address of the asset used as deposit by the receiver
     * @param dAsset The address of the asset used as deposit by the distributor
     * @param rAmount The receiver's chosen deposit amount 
     * @param dAmount The distributor's chosen deposit amount
     * @param rRisk The receiver's risk
     * @param dRisk The distributor's risk
     *
     * Requirements:
     *
     * - Only callable by an Eternal contract
     */
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external override {
        bytes32 entity = keccak256(abi.encodePacked(address(eternalStorage)));
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));
        require(_msgSender() == eternalStorage.getAddress(entity, sender), "msg.sender must be from Eternal");

        treasury = IEternalTreasury(_msgSender());

        // Save receiver parameters and data
        userData[receiver].inGage = true;
        userData[receiver].amount = rAmount;
        userData[receiver].asset = rAsset;
        userData[receiver].risk = rRisk;

        // Save distributor parameters and data
        userData[distributor].inGage = true;
        userData[distributor].amount = dAmount;
        userData[distributor].asset = dAsset;
        userData[distributor].risk = dRisk;

        // Save liquid gage parameters
        assetOfReference = IERC20(dAsset);
        totalSupply = assetOfReference.totalSupply();

        users = 2;

        status = Status.Active;
        emit GageInitiated(id);
    }

    /**
     * @notice Closes this gage and determines the winner
     *
     * Requirements:
     *
     * - Only callable by the receiver
     */
    function exit() external override {
        require(_msgSender() == receiver, "Only the receiver may exit");
        // Remove user from the gage first (prevent re-entrancy)
        userData[receiver].inGage = false;
        userData[distributor].inGage = false;
        // Calculate the change in total supply of the asset of reference
        uint256 deltaSupply = inflationary ? (assetOfReference.totalSupply() - totalSupply) : (totalSupply - assetOfReference.totalSupply());
        uint256 percentChange = deltaSupply * (10 ** 11) / totalSupply;
        // Determine whether the user is the winner
        bool winner = percentChange >= percent;
        emit GageClosed(id, winner);
        status = Status.Closed;
        // Communicate with an external treasury which offers gages
        treasury.settleGage(receiver, id, winner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IGage.sol";

/**
 * @dev Loyalty Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all loyalty gage contracts
 */
interface ILoyaltyGage is IGage {
    // Initializes the loyalty gage
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external;
    // View the distributor of the loyalty gage (usually token distributor)
    function viewDistributor() external view returns (address);
    // View the receiver in the loyalty gage (usually the user)
    function viewReceiver() external view returns (address);
    // View the gage's percent change in supply condition
    function viewPercent() external view returns (uint256);
    // View the whether the gage's deposit is inflationary or deflationary
    function viewInflationary() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal interface
 * @author Nobody (me)
 * @notice Methods are used for all gage-related functioning
 */
interface IEternalFactory {
    // Initiates a liquid gage involving an ETRNL liquidity pair
    function initiateEternalLiquidGage(address asset, uint256 amount) external payable returns(uint256);
    // Updates the 24h counters for the treasury and token
    function updateCounters(uint256 amount) external;
    
    // Signals the deployment of a new gage
    event NewGage(uint256 id, address indexed gageAddress);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all gage contracts
 */
interface IGage {
    // Holds all possible statuses for a gage
    enum Status {
        Open,
        Active,
        Closed
    }

    // Holds user-specific information with regards to the gage
    struct UserData {
        address asset;                       // The address of the asset used as deposit     
        uint256 amount;                      // The entry deposit (in tokens) needed to participate in this gage        
        uint256 risk;                        // The percentage (in decimal form) that is being risked in this gage (x 10 ** 4) 
        bool inGage;                         // Keeps track of whether the user is in the gage or not
    }         

    // Removes a user from the gage
    function exit() external;
    // View the user count in the gage whilst it is not Active
    function viewGageUserCount() external view returns (uint256);
    // View the total user capacity of the gage
    function viewCapacity() external view returns (uint256);
    // View the gage's status
    function viewStatus() external view returns (uint);
    // View whether the gage is a loyalty gage or not
    function viewLoyalty() external view returns (bool);
    // View a given user's gage data
    function viewUserData(address user) external view returns (address, uint256, uint256);

    // Signals the transition from 'Open' to 'Active for a given gage
    event GageInitiated(uint256 id);
    // Signals the transition from 'Active' to 'Closed' for a given gage
    event GageClosed(uint256 id, bool winner); 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IEternalStorage.sol";
import "../interfaces/IEternalTreasury.sol";
import "../interfaces/IGage.sol";

/**
 * @title Gage contract 
 * @author Nobody (me)
 * @notice Implements the basic necessities for any gage
 */
abstract contract Gage is Context, IGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // The Eternal Storage
    IEternalStorage public immutable eternalStorage;
    // The Eternal Treasury
    IEternalTreasury internal treasury;

/////–––««« Variables: Gage data »»»––––\\\\\

    // Holds all users' information in the gage
    mapping (address => UserData) internal userData;
    // The id of the gage
    uint256 internal immutable id;  
    // The maximum number of users in the gage
    uint256 internal immutable capacity; 
    // Keeps track of the number of users left in the gage
    uint256 internal users;
    // The state of the gage       
    Status internal status;
    // Determines whether the gage is a loyalty gage or not       
    bool private immutable loyalty;

/////–––««« Constructor »»»––––\\\\\
    
    constructor (uint256 _id, uint256 _users, address _eternalStorage, bool _loyalty) {
        require(_users > 1, "Gage needs at least two users");
        id = _id;
        capacity = _users;
        loyalty = _loyalty;
        eternalStorage = IEternalStorage(_eternalStorage);
    }   

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the number of stakeholders in the gage (if it isn't yet active)
     * @return The number of stakeholders in the selected gage
     */
    function viewGageUserCount() external view override returns (uint256) {
        return users;
    }

    /**
     * @notice View the total user capacity of the gage
     * @return The total user capacity
     */
    function viewCapacity() external view override returns(uint256) {
        return capacity;
    }

    /**
     * @notice View the status of the gage
     * @return An integer indicating the status of the gage
     */
    function viewStatus() external view override returns (uint256) {
        return uint256(status);
    }

    /**
     * @notice View whether the gage is a loyalty gage or not
     * @return True if the gage is a loyalty gage, else false
     */
    function viewLoyalty() external view override returns (bool) {
        return loyalty;
    }

    /**
     * @notice View a given user's gage data 
     * @param user The address of the specified user
     * @return The asset, amount and risk for this user 
     */
    function viewUserData(address user) external view override returns (address, uint256, uint256){
        UserData storage data = userData[user];
        return (data.asset, data.amount, data.risk);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Treasury interface
 * @author Nobody (me)
 * @notice Methods are used for all treasury functions
 */
interface IEternalTreasury {
    // Provides liquidity for a given liquid gage and transfers instantaneous rewards to the receiver
    function fundEternalLiquidGage(address _gage, address user, address asset, uint256 amount, uint256 risk, uint256 bonus) external payable;
    // Used by gages to compute and distribute ETRNL liquid gage rewards appropriately
    function settleGage(address receiver, uint256 id, bool winner) external;
    // Stake a given amount of ETRNL
    function stake(uint256 amount) external;
    // Unstake a given amount of ETRNL and withdraw staking rewards proportional to the amount (in ETRNL)
    function unstake(uint256 amount) external;
    // View the ETRNL/AVAX pair address
    function viewPair() external view returns(address);
    // View whether a liquidity swap is in progress
    function viewUndergoingSwap() external view returns(bool);
    // Provides liquidity for the ETRNL/AVAX pair for the ETRNL token contract
    function provideLiquidity(uint256 contractBalance) external;
    // Computes the minimum amount of two assets needed to provide liquidity given one asset amount
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) external view returns(uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset);
    // Converts a given staked amount into the reserve number space
    function convertToReserve(uint256 amount) external view returns(uint256);
    // Converts a given reserve amount into the regular number space (staked)
    function convertToStaked(uint256 reserveAmount) external view returns(uint256);
    // Allows the withdrawal of AVAX in the contract
    function withdrawAVAX(address payable recipient, uint256 amount) external;
    // Allows the withdrawal of an asset present in the contract
    function withdrawAsset(address asset, address recipient, uint256 amount) external;

    // Signals a disabling/enabling of the automatic liquidity provision
    event AutomaticLiquidityProvisionUpdated(bool value);
    // Signals that liquidity has been added to the ETRNL/WAVAX pair 
    event AutomaticLiquidityProvision(uint256 amountETRNL, uint256 totalSwappedETRNL, uint256 amountAVAX);
    // Signals that part of the locked AVAX balance has been cleared to a given address by decision of the DAO
    event AVAXTransferred(uint256 amount, address recipient);
    // Signals that some of an asset balance has been sent to a given address by decision of the DAO
    event AssetTransferred(address asset, uint256 amount, address recipient);
    // Signals that a user staked a given amount of ETRNL 
    event Stake(address indexed user, uint256 amount);
    // Signals that a user unstaked a given amount of ETRNL
    event Unstake(address indexed user, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns(uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns(int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns(address);
    function getBool(bytes32 entity, bytes32 key) external view returns(bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns(bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}