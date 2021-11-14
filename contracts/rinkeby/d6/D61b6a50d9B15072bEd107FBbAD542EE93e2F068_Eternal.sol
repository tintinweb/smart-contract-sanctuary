// File: github/TheGrandNobody/Eternal/contracts/interfaces/IEternal.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Eternal interface
 * @author Nobody (me)
 * @notice Methods are used for all gage-related functioning
 */
interface IEternal {
    
    function initiateStandardGage(uint32 users) external returns(uint256);
    function deposit(address asset, address user, uint256 amount, uint256 id) external;
    function withdraw(address user, uint256 id) external;
    
    event NewGage(uint256 id, address indexed gageAddress);
}
// File: @openzeppelin/contracts/utils/Context.sol



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

// File: github/TheGrandNobody/Eternal/contracts/interfaces/IGage.sol

pragma solidity ^0.8.0;

/**
 * @dev Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all gage contracts
 */
interface IGage {
    // Signals the addition of a user to a specific gage (whilst gage is still 'Open')
    event UserAdded(uint256 id, address indexed user);
    // Signals the removal of a user from a specific gage (whilst gage is still 'Open')
    event UserRemoved(uint256 id, address indexed user);
    // Signals the transition from 'Open' to 'Active for a given gage
    event GageInitiated(uint256 id);
    // Signals the transition from 'Active' to 'Closed' for a given gage
    event GageClosed(uint256 id); 

    // Adds a user to the gage
    function join(address asset, uint256 amount, uint8 risk, bool loyalty) external;
    // Removes a user from the gage
    function exit() external;
    // View the user count in the gage whilst it is not Active
    function viewGageUserCount() external view returns (uint32);
    // View the total user capacity of the gage
    function viewCapacity() external view returns (uint256);
    // View the gage's status
    function viewStatus() external view returns (uint);
    // View a given user's gage data
    function viewUserData(address user) external view returns (address, uint256, uint256, bool);
}
// File: github/TheGrandNobody/Eternal/contracts/interfaces/IGageV2.sol

pragma solidity ^0.8.0;


/**
 * @dev Gage V2 interface
 * @author Nobody (me)
 * @notice Methods are used for all gage contracts
 */
interface IGageV2 is IGage {
    // View the creator of the loyalty gage (usually token distributor)
    function viewCreator() external view returns (address);
    // View the buyer in the loyalty gage (usually the user)
    function viewBuyer() external view returns (address);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: github/TheGrandNobody/Eternal/contracts/main/Gage.sol

pragma solidity ^0.8.0;





contract Gage is Context, IGage {

    // Holds all possible statuses for a gage
    enum Status {
        Open,
        Active,
        Closed
    }

    // Holds user-specific information with regards to the gage
    struct UserData {
        address asset;                       // The AVAX address of the asset used as deposit     
        uint256 amount;                      // The entry deposit (in tokens) needed to participate in this gage        
        uint8 risk;                          // The percentage that is being risked in this gage  
        bool inGage;                         // Keeps track of whether the user is in the gage or not
        bool loyalty;                        // Determines whether the gage is a loyalty gage or not
    }

    // The eternal platform
    IEternal public eternal;                

    // Holds all users' information in the gage
    mapping (address => UserData) internal userData;

    // The id of the gage
    uint256 public immutable id;  
    // The maximum number of users in the gage
    uint32 public immutable  capacity; 
    // Keeps track of the number of users left in the gage
    uint32 internal users;
    // The state of the gage       
    Status internal status;         

    constructor (uint256 _id, uint32 _users) {
        id = _id;
        capacity = _users;
    }      

    /**
     * @dev Adds a stakeholder to this gage and records the initial data.
     * @param asset The address of the asset used as deposit by this user
     * @param amount The user's chosen deposit amount 
     * @param risk The user's chosen risk percentage
     * @param loyalty Whether the gage is a loyalty gage
     *
     * Requirements:
     *
     * - Risk must not exceed 100 percent
     * - User must not already be in the gage
     */
    function join(address asset, uint256 amount, uint8 risk, bool loyalty) external override {
        require(risk <= 100, "Invalid risk percentage");
        UserData storage data = userData[_msgSender()];
        require(!data.inGage, "User is already in this gage");

        data.amount = amount;
        data.asset = asset;
        data.risk = risk;
        data.inGage = true;
        data.loyalty = loyalty;
        users += 1;

        eternal.deposit(asset, _msgSender(), amount, id);
        emit UserAdded(id, _msgSender());
        // If contract is filled, update its status and initiate the gage
        if (users == capacity) {
            status = Status.Active;
            emit GageInitiated(id);
        }
    }

    /**
     * @dev Removes a stakeholder from this gage.
     *
     * Requirements:
     *
     * - User must be in the gage
     */
    function exit() external override {
        UserData storage data = userData[_msgSender()];
        require(data.inGage, "User is not in this gage");
        
        // Remove user from the gage first (prevent re-entrancy)
        data.inGage = false;

        if (status != Status.Closed) {
            users -= 1;
            emit UserRemoved(id, _msgSender());
        }

        if (status == Status.Active && users == 1) {
            // If there is only one user left after this one has left, update the gage's status accordingly
            status = Status.Closed;
            emit GageClosed(id);
        }

        eternal.withdraw(_msgSender(), id);
    }

    /////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @dev View the number of stakeholders in the gage (if it isn't yet active)
     * @return The number of stakeholders in the selected gage
     *
     * Requirements:
     *
     * - Gage status cannot be 'Active'
     */
    function viewGageUserCount() external view override returns (uint32) {
        require(status != Status.Active, "Gage can't be active");
        return users;
    }

    /**
     * @dev View the total user capacity of the gage
     * @return The total user capacity
     */
    function viewCapacity() external view override returns(uint256) {
        return capacity;
    }

    /**
     * @dev View the status of the gage
     * @return An integer indicating the status of the gage
     */
    function viewStatus() external view override returns (uint) {
        return uint(status);
    }

    /**
     * @dev View a given user's gage data 
     * @param user The address of the specified user
     * @return The asset, amount and risk for this user 
     */
    function viewUserData(address user) external view override returns (address, uint256, uint256, bool){
        UserData storage data = userData[user];
        return (data.asset, data.amount, data.risk, data.loyalty);
    }
}
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: github/TheGrandNobody/Eternal/contracts/interfaces/IEternalToken.sol

pragma solidity ^0.8.0;



/**
 * @dev ETRNL interface
 * @author Nobody (me)
 * @notice Methods are used for the DAO-governed section of Eternal and the gaging platform
 */
interface IEternalToken is IERC20, IERC20Metadata {

    // Holds all the different types of rates
    enum Rate {
        Liquidity,
        Funding,
        Redistribution,
        Burn
    }
    
    // Sets the value of any given rate
    function setRate(Rate rate, uint16 newRate) external;
    // Sets the address of the Eternal Liquidity contract
    function setEternalLiquidity(address newContract) external;
    // Sets the liquidity threshold to a given value
    function setLiquidityThreshold(uint64 value) external;
    // Designates a new Eternal DAO address
    function designateFund(address fund) external;
    // View the rate used to convert between the reflection and true token space
    function getReflectionRate() external view returns (uint256);
    // View whether an address is excluded from the transaction fees
    function isExcludedFromFee(address account) external view returns (bool);
    // View whether an address is excluded from rewards
    function isExcludedFromReward(address account) external view returns (bool);
    // View the total fee
    function viewTotalRate() external view returns (uint256);

    // Signals a change of value of a given rate in the Eternal Token contract
    event UpdateRate(uint256 oldRate, uint256 newRate, Rate rate);
    // Signals a change of address for the Eternal Liquidity contract
    event UpdateEternalLiquidity(address indexed oldContract, address indexed newContract);
    // Signals a change of value of the token liquidity threshold
    event UpdateLiquidityThreshold(uint256 oldThreshold, uint256 newThreshold);
}
// File: github/TheGrandNobody/Eternal/contracts/main/Eternal.sol

pragma solidity ^0.8.0;


/**
 * @title Contract for the Eternal gaging platform
 * @author Nobody (me)
 * @notice The Eternal contract holds all user-data and gage logic.
 */
contract Eternal is Context, IEternal {

    constructor (address _eternal) {
        // Initialize the ETRNL interface
        eternal = IEternalToken(_eternal);
    }

    // The ETRNL interface
    IEternalToken private immutable eternal;

    // Keeps track of the respective gage tied to any given ID
    mapping (uint256 => address) private gages;
    // Keeps track of the reflection rate for any given address and gage to recalculate rewards earned during the gage
    mapping (address => mapping (uint256 => uint256)) private reflectionRates;

    // Keeps track of the latest Gage ID
    uint256 public lastId;

/////–––««« Gage-logic functions »»»––––\\\\\

    /**
     * @dev Creates a standard n-holder gage contract with n users
     * @param users The desired number of users in the gage
     */
    function initiateStandardGage(uint32 users) external override returns(uint256) {
        lastId += 1;
        Gage newGage = new Gage(lastId, users);
        gages[lastId] = address(newGage);
        emit NewGage(lastId, address(newGage));

        return lastId;
    }

    /**
     * @dev Transfers a given user's gage funds to storage or further processing depending on the type of the gage
     */
    function deposit(address asset, address user, uint256 amount, uint256 id) external override {
        if (asset == address(eternal)) {
            reflectionRates[user][id] = eternal.getReflectionRate();
        }
        IERC20(asset).transferFrom(user, address(this), amount);
    }

    /**
     * @dev Withdraws a given user's gage return
     * @param id The id of the specified gage contract
     * @param user The address of the specified user
     *
     */
    function withdraw(address user, uint256 id) external override {
        require(_msgSender() == gages[id], "msg.sender must be the gage");
        IGageV2 gage = IGageV2(gages[id]);
        (address asset, uint256 amount, uint256 risk, bool loyalty) = gage.viewUserData(user);

        bool usingETRNL = asset == address(eternal);
        // Compute the amount minus the fee rate if using ETRNL
        uint256 netAmount = usingETRNL ? amount - (amount * eternal.viewTotalRate()) / 100000 : 0;
        // Compute any rewards accrued during the gage
        uint256 finalAmount = usingETRNL ? computeAccruedRewards(netAmount, user, id)  : computeAccruedRewards(amount, user, id);
        /** Users get the entire entry amount back if the gage wasn't active at the time of departure.
            If the user forfeited, the system substracts the loss incurred. 
            Otherwise, the gage return is awarded to the winner. */
        if (gage.viewStatus() == 1) {
            if (loyalty && user != gage.viewBuyer()) {
                (,uint256 otherAmount,,) = gage.viewUserData(gage.viewBuyer());
                finalAmount -= (otherAmount * risk / 100);
            } else {
                finalAmount -= (amount * risk / 100);
            }
        } else if (gage.viewStatus() == 2) {
            if (loyalty && user != gage.viewBuyer()) {
                (,uint256 otherAmount,,) = gage.viewUserData(gage.viewBuyer());
                finalAmount += (gage.viewCapacity() - 1) * otherAmount * risk / 100;
            } else {
                finalAmount += (gage.viewCapacity() - 1) * amount * risk / 100;
            }
        }
        IERC20(asset).transfer(user, finalAmount);
    }

/////–––««« Utility functions »»»––––\\\\\

    /**
     * @dev Calculates any redistribution rewards accrued during a given gage a given user participated in.
     * @param amount The specified entry deposit
     * @param user The address of the user who we calculate rewards for
     * @param id The id of the specified gage
     */
    function computeAccruedRewards(uint256 amount, address user, uint256 id) private view returns (uint256) {
        uint256 oldRate = reflectionRates[user][id];
        uint256 currentRate = eternal.isExcludedFromReward(user) ? oldRate : eternal.getReflectionRate();

        return (amount * (currentRate / oldRate));
    }

    function viewGageAddress(uint256 id) external view returns(address) {
        return gages[id];
    }
}