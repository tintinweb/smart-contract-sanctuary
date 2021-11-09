// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../strategies/StandardCampaignStrategy.sol";
import "../interfaces/IFactory.sol";
import "../Campaign.sol";

contract StandardCampaignFactory is Ownable, IFactory {
    mapping(uint => Campaign) public campaigns;
    mapping(address => mapping(uint => Campaign)) public deployerOf;

    uint256 public deployedCampaigns;

    function getAllCampaigns() external view returns(Campaign[] memory){
        Campaign[] memory campaignList = new Campaign[](deployedCampaigns);
    for (uint i = 0; i < deployedCampaigns; i++) {
        campaignList[i] = campaigns[i];
    }
    return campaignList;
    }
    

    function deployCampaign(
        string memory metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime)
        external override{
        Campaign project = new Campaign( metadata , new StandardCampaignStrategy(
            _treasury, 
            _fundingEndTime,
            _fundTarget,
            _fundingStartTime            
        ));
        campaigns[deployedCampaigns] = project;
        deployerOf[msg.sender][deployedCampaigns] = project;
        deployedCampaigns += 1;
        emit CampaignCreated(address(this));
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategy.sol";

//contract template for initiating a project
contract StandardCampaignStrategy is Ownable, IStrategy {
    mapping(address => uint256) public userDeposit;
    //@notice project metadata can be hosted on IPFS or centralized storages.
    address payable public treasury;
    //@notice the start time of crowdfunding session
    uint256 public fundingStartTime;
    //@notice the end of crowdfunding session time
    uint256 public fundingEndTime;
    //@notice the amount of funds to reach a goal
    uint256 public fundTarget;

    IERC20 public supportedCurrency;

    //put owner in constructor to use for initializing project
    constructor(
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) {
        treasury = _treasury;
        fundTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(IERC20(token) == supportedCurrency);
        require(fundingEndTime > block.timestamp, "Funding ended");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        userDeposit[msg.sender] += amount;
    }

    //emergency function to stop the funding (and stop the project)
    function stopProject() public onlyOwner {
        fundingEndTime = block.timestamp;
    }

    function balanceOf(address user, address erc20) external override view returns (uint256){
        require(IERC20(erc20) == supportedCurrency);
        return userDeposit[msg.sender];
    }


    function getProjectDetails()
        public
        view
        returns (
            
            address Treasury,
            uint256 Target,
            uint256 Balance
        )
    {
        
        Treasury = treasury;
        Target = fundTarget;
        Balance = address(this).balance;
        return (Treasury, Target, Balance);
    }

    //function for returning the funds
    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(userDeposit[msg.sender] >= 0); // guards up front
        userDeposit[msg.sender] -= amount; // optimistic accounting
        IERC20(supportedCurrency).transferFrom(address(this), msg.sender, amount); // transfer
        return true;
    }

    function changeTreasuryAddress(address payable newTreasury) external override onlyOwner{
        treasury = newTreasury;
    }

    function payOut(uint256 amount) external override returns (uint success) {
        require(msg.sender == treasury);
        require(fundingEndTime < block.timestamp);
        require(amount >= address(this).balance);

        treasury.transfer(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IStrategy.sol";
interface IFactory {
    event CampaignCreated(address newAddress);

    function deployCampaign(
        string memory metadata,
         address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStrategy.sol";

contract Campaign is Ownable {
    string metadata_uri;
    IStrategy strategy;

    constructor(string memory metadata, IStrategy strat) {
        metadata_uri = metadata;
        strategy = strat;
    }

    function changeMetadata(string memory newMetadata) external {
       metadata_uri = newMetadata;
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
pragma solidity ^0.8.6;

interface IStrategy {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address user, address erc20) external view returns (uint256);

    function pledge(uint256 amount, address token) external;

    function payOut(uint256 amount) external returns (uint256);

    function changeTreasuryAddress(address payable newTreasury) external;
}