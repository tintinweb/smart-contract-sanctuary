/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

/** 
 *  SourceUnit: \robofi-contracts-core\contracts\BotCreatorReward.sol
*/
            
// SPDX-License-Identifier: MIT

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




/** 
 *  SourceUnit: \robofi-contracts-core\contracts\BotCreatorReward.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/** 
 *  SourceUnit: \robofi-contracts-core\contracts\BotCreatorReward.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


/** 
 *  SourceUnit: \robofi-contracts-core\contracts\BotCreatorReward.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/Context.sol";
////import "./Ownable.sol";

contract BotCreatorRewardManager is Context, Ownable {

    struct BotRewardApplication {
        address receiver;       // the receiver for the reward
        address[] approvers;
        uint amount;            // the approved reward amount for the bot
        uint status;            // 0 - new, 1 - canceled, 2 - proposed, 3 - approved, 4 - rejected, 
    }

    IERC20 private _vics;
    uint public numApproverPerApplication = 1;           // number of approvals for a reward proposal
    mapping(address => bool) private _approvers;
    mapping(address => BotRewardApplication) private _application;

    event ApplicationCreated(address indexed bot);
    event ApplicationCanceled(address indexed bot);
    event ApplicationRejected(address indexed bot);
    event ApplicationDeleted(address indexed bot);
    event ApplicationApproved(address indexed bot, address indexed receiver, uint amount);
    event RewardProposal(address indexed bot, uint amount);
    event UpdateApprover(address indexed account, bool approver);

    modifier onlyBotCreator(address botContract) {
        Ownable bot = Ownable(botContract);
        require(botContract != address(0), "RewardManager: invalid bot contract");
        require(bot.owner() == _msgSender(), "RewardManager: caller must be bot creator");

        _;
    }

    modifier onlyApprover() {
        require(_approvers[_msgSender()], "RewardManager: permission denied");

        _;
    }

    constructor(IERC20 vics) {
        _vics = vics;
        _approvers[_msgSender()] = true;
    }

    function emergencyWithdraw() external onlyOwner {
        _vics.transfer(_msgSender(), _vics.balanceOf(address(this)));        
    }

    function setApproverPerApplication(uint value) external onlyOwner {
        require(value > 0, "RequireManager: value must not be 0");
        numApproverPerApplication = value;
    }

    function updateApprovers(address[] calldata accounts, bool isApprover_) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _approvers[accounts[i]] = isApprover_;
            emit UpdateApprover(accounts[i], isApprover_);
        }
    }

    function isApprover(address account) external view returns(bool) {
        return _approvers[account];
    }

    /**
    @dev Create a scolarship application for a created bot. 
    Should be called by the bot creator.
     */
    function createApplication(address botContract) external onlyBotCreator(botContract) {
        BotRewardApplication storage application = _application[botContract];
        require(application.status <= 1, "RewardManager: application has been processed");
        application.status = 0;
        application.receiver = _msgSender();

        emit ApplicationCreated(botContract);
    }

    function applicationOf(address botContract) external view returns(BotRewardApplication memory result) {
        BotRewardApplication storage application = _application[botContract];
        result = application;
    }

    /**
    @dev Cancels an application.
    Should be called by the bot creator.
     */
    function cancelApplication(address botContract) external onlyBotCreator(botContract) {
        BotRewardApplication storage application = _application[botContract];
        require(application.status == 0, "RewardManager: application is not new");

        application.status = 1; /* canceled */
        emit ApplicationCanceled(botContract);
    }

    /**
    @dev Deletes an application, no matter its current status.
     */
    function deleteApplication(address botContract) external onlyOwner {
        require(botContract != address(0), "RewardMananger: zero bot contract");
        delete _application[botContract];
        emit ApplicationDeleted(botContract);
    }

    /**
    @dev Creates a reward proposal for a bot.
     */
    function createProposal(address botContract, uint amount) external onlyApprover {
        BotRewardApplication storage application = _application[botContract];
        require(application.status == 0 && application.receiver != address(0) /* proposed */, "RewardManager: invalid application status");

        application.status = 2; /* proposed */
        application.amount = amount;
        
        emit RewardProposal(botContract, amount);

        _approve(botContract, application);
    }

    /**
    @dev Rejects an application.
     */
    function rejectApplication(address botContract) external onlyApprover {
        BotRewardApplication storage application = _application[botContract];
        require(application.status == 2 /* proposed */ || application.status == 0 /* new */, "RewardManager: invalid application status");
        
        application.status = 4; /* rejected */
        emit ApplicationRejected(botContract);
    }

    function approveApplication(address botContract) external onlyApprover {
        BotRewardApplication storage application = _application[botContract];
        _approve(botContract, application);
    }

    function _approve(address botContract, BotRewardApplication storage application) internal {
        address approver = _msgSender();
        require(application.status == 2 /* proposed */, "RewardManager: invalid application status");

        // determine for duplication of approver
        for (uint i = 0; i < application.approvers.length; i++)
            if (application.approvers[i] == approver)
                revert("RewardManager: duplicated approver");
        application.approvers.push(approver);
        if (application.approvers.length == numApproverPerApplication) {
            application.status = 3; /* approved */
            _vics.transfer(application.receiver, application.amount);
            emit ApplicationApproved(botContract, application.receiver, application.amount);
            return;
        }
        emit ApplicationApproved(botContract, address(0), 0);
    }
}