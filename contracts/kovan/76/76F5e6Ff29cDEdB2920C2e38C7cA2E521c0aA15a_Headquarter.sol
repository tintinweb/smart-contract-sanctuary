// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Station.sol";

contract Headquarter is Ownable {
    Station[] public stations;
    event StationCreated(uint timestamp);
    function deployStation(
        string memory _metaUri, address payable treasury)
        public onlyOwner {
        Station project = new Station(
            _metaUri , treasury
        );
        stations.push(project);
        emit StationCreated(block.timestamp);
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
import "./Campaign.sol";
import "./interfaces/IStation.sol";

contract Station is Ownable, IStation {
    string metadata;
    address payable treasury;
    Campaign[] public campaigns;

    constructor(string memory _metadata, address payable _treasury){
        metadata = _metadata;
        treasury = _treasury;
    }

    function getStationMeta() external override view returns(string memory meta){
        return metadata;
    }

    function getAllCampaigns() external view returns(Campaign[] memory){
        return campaigns;
    }

    function startCampaign(
        string memory _projectName, 
        address payable _projectStarter, 
        uint256 _fundingEndTime, 
        uint256 _fundTarget, 
        uint256 _projectEndTime)
        external override{
        Campaign project = new Campaign(
            _projectName, 
            _projectStarter,
            _fundingEndTime,
            _fundTarget,
            _projectEndTime            
        );
        campaigns.push(project);
        emit CampaignCreated(address(this));
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICampaign.sol";

//contract template for initiating a project
contract Campaign is Ownable, ICampaign {
    mapping(address => uint256) public userDeposit;
    //variable for projectname

    string metadata;
    //variable for projectstarter (EOA projectstarter)
    address payable treasury;
    //starttime of fundingperiod (is this necessary?)
    uint256 fundingStartTime;
    //endtime of fundingperiod
    uint256 fundingEndTime;
    //Targetamount for funding
    uint256 fundTarget;
    //current balance of the project
    bool isInitialized;

    //put owner in constructor to use for initializing project
    constructor(
        string memory _metadata,
        address payable _treasury,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _fundingStartTime
    ) {
        treasury = _treasury;
        metadata = _metadata;
        fundTarget = _fundTarget;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
    }

    function pledge(uint256 amount, address token) external override {
        require(amount > 0, "Amount cannot be 0");
        require(fundingEndTime > block.timestamp, "Funding ended");

        userDeposit[msg.sender] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    //emergency function to stop the funding (and stop the project)
    function stopProject() public onlyOwner {
        fundingEndTime = block.timestamp;
    }

    function getProjectDetails()
        public
        view
        returns (
            string memory Metadata,
            address Treasury,
            uint256 Target,
            uint256 Balance
        )
    {
        Metadata = metadata;
        Treasury = treasury;
        Target = fundTarget;
        Balance = address(this).balance;
        return (Metadata, Treasury, Target, Balance);
    }

    //How to see these variables when calling function?

    //function for returning the funds
    function withdrawFunds(uint256 amount) public returns (bool success) {
        require(userDeposit[msg.sender] >= 0); // guards up front
        userDeposit[msg.sender] -= amount; // optimistic accounting
       payable(msg.sender).transfer(amount); // transfer
        return true;
    }

    function changeMetadata(string memory url) external override onlyOwner{
        metadata = url;
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

import "./ICampaign.sol";

interface IStation {
    event CampaignCreated(address newAddress);

    function getStationMeta() external view returns (string memory meta);

    function startCampaign(
        string memory _projectName,
        address payable _projectStarter,
        uint256 _fundingEndTime,
        uint256 _fundTarget,
        uint256 _projectEndTime
    ) external;
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

interface ICampaign {

    function pledge(uint256 amount, address token) external;

    function payOut(uint256 amount) external returns (uint256);

    function changeMetadata(string memory url) external;

    function changeTreasuryAddress(address payable newTreasury) external;
}