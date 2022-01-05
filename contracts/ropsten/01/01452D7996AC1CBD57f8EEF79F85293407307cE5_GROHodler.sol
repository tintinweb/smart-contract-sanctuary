// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IHodler {
    function totalBonus() external view returns (uint256);

    function correctionAmount() external view returns (uint256);

    function claimDelay() external view returns (uint256);

    function maintainer() external view returns (address);

    function userClaims(address account) external view returns (uint256);
}

interface IVester {
    function vestingBalance(address _account) external view returns (uint256);

    function totalGroove() external view returns (uint256);

    function vest(
        bool vest,
        address account,
        uint256 amount
    ) external;
}

/// @notice GRP vesting bonus claims contract - Where all unvested GRO are returned if user exits vesting contract early
contract GROHodler is Ownable {
    uint256 public constant DEFAULT_DECIMAL_FACTOR = 1E18;
    // The main vesting contract
    address public vester;
    // Total amount of unvested GRO that has been tossed aside
    uint256 public totalBonus;
    // Estimation of total unvested GRO can become unreliable if there is a significant
    //  amount of users who have vesting periods that exceed their vesting end date.
    //  We use a manual correction variable to deal with this issue for now.
    uint256 public correctionAmount;
    // How long you have to wait between claims
    uint256 public claimDelay;
    // Contract that can help maintain the bonus contract by adjusting variables
    address public maintainer;

    // keep track of users last claim
    mapping(address => uint256) public userClaims;
    bool public paused = true;

    IHodler public oldHodler;

    event LogBonusAdded(uint256 amount);
    event LogBonusClaimed(address indexed user, bool vest, uint256 amount);
    event LogNewClaimDelay(uint256 delay);
    event LogNewCorrectionVariable(uint256 correction);
    event LogNewMaintainer(address newMaintainer);
    event LogNewStatus(bool status);

    constructor(address _vester, IHodler _oldHodler) {
        vester = _vester;
        if (address(_oldHodler) != address(0)) {
            oldHodler = _oldHodler;
            totalBonus = _oldHodler.totalBonus();
            correctionAmount = _oldHodler.correctionAmount();
            claimDelay = _oldHodler.claimDelay();
            maintainer = _oldHodler.maintainer();
        }
    }

    /// @notice every time a users exits a vesting position, the penalty gets added to this contract
    /// @param amount user penealty amount
    function add(uint256 amount) external {
        require(msg.sender == vester);
        totalBonus += amount;
        emit LogBonusAdded(amount);
    }

    function setVester(address _vester) external onlyOwner {
        vester = _vester;
    }

    /// @notice Set a new maintainer
    /// @param newMaintainer address of new maintainer
    /// @dev Maintainer will mostly be used to be able to change the correctionValue
    ///  on short notice, as this can change on short notice depending on if users interact with
    ///  their position in the vesting contract
    function setMaintainer(address newMaintainer) external onlyOwner {
        maintainer = newMaintainer;
        emit LogNewMaintainer(newMaintainer);
    }

    /// @notice Start or stop the bonus contract
    /// @param pause Contract Pause state
    function setStatus(bool pause) external {
        require(msg.sender == maintainer || msg.sender == owner(), "setCorrectionVariable: !authorized");
        paused = pause;
        emit LogNewStatus(pause);
    }

    /// @notice maintainer can correct total amount of vested GRO to adjust for drift of central curve vs user curves
    /// @param newCorrection a positive number to deduct from the unvested GRO to correct for central drift
    function setCorrectionVariable(uint256 newCorrection) external {
        require(msg.sender == maintainer || msg.sender == owner(), "setCorrectionVariable: !authorized");
        require(newCorrection <= IVester(vester).totalGroove(), "setCorrectionVariable: correctionAmount to large");
        correctionAmount = newCorrection;
        emit LogNewCorrectionVariable(newCorrection);
    }

    /// @notice after every bonus claim, a user has to wait some time before they can claim again
    /// @param delay time delay until next claim is possible
    function setClaimDelay(uint256 delay) external onlyOwner {
        claimDelay = delay;
        emit LogNewClaimDelay(delay);
    }

    /// @notice Get the pending bonus a user can claim
    function getPendingBonus() public view returns (uint256) {
        uint256 userGroove = IVester(vester).vestingBalance(msg.sender);
        // if the user doesnt have a vesting position, they cannot claim
        if (userGroove == 0) {
            return 0;
        }
        // if for some reason the user has a larger vesting position than the
        //  current vesting position - correctionAmount, then give them the whole bonus.
        // This should only happen if: theres only one vesting position, someone forgot to
        // update the correctionAmount;
        uint256 globalGroove = IVester(vester).totalGroove() - correctionAmount;
        if (userGroove >= globalGroove) {
            return totalBonus;
        }
        uint256 userAmount = (userGroove * totalBonus) / globalGroove;
        return userAmount;
    }

    /// @notice User claims available bonus
    function claim(bool vest) external returns (uint256) {
        // user cannot claim if they have claimed recently or the contract is paused
        if (getLastClaimTime(msg.sender) + claimDelay >= block.timestamp || paused) {
            return 0;
        }
        uint256 userAmount = getPendingBonus();
        if (userAmount > 0) {
            userClaims[msg.sender] = block.timestamp;
            totalBonus -= userAmount;
            IVester(vester).vest(vest, msg.sender, userAmount);
            emit LogBonusClaimed(msg.sender, vest, userAmount);
        }
        return userAmount;
    }

    function canClaim() external view returns (bool) {
        if (getLastClaimTime(msg.sender) + claimDelay >= block.timestamp || paused) {
            return false;
        }
        return true;
    }

    function getLastClaimTime(address account) private view returns (uint256 lastClaimTime) {
        lastClaimTime = userClaims[account];
        if (lastClaimTime == 0 && address(oldHodler) != address(0)) {
            lastClaimTime = oldHodler.userClaims(account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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