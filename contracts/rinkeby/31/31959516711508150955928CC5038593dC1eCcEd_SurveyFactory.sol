// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./TrustedSurvey.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Survey Marketplace
/// @author Dhruvin
/// @notice A contract that creates survey
contract SurveyFactory is Ownable {

    /// @notice Details of the survey
    /// @param owner The address of the survey creator
    /// @param id    The id of the survey 
    struct SurveyDetails {
        address owner;
        uint256 id;
    }

    /// @notice Mandatory fees charged to survey creator
    uint256 public surveyCreationFees;

    /// @notice Stores all the surveys
    /// @dev Array of survey contract addresses
    address[] public surveys;

    /// @notice List of all the surveys with there corresponding creator and id
    mapping(address => SurveyDetails) public surveyOwners;
    

    /// @notice Logs the initiliization of the survey factory
    /// @param surveyCreationFees The mandatory fees to be paid by survey creator
    event SurveyFactoryInitialized(uint256 indexed surveyCreationFees);


    /// @notice Logs when a new survey is created
    /// @param owner The address of the survey creator
    /// @param surveyId The id of the survey
    /// @param surveyAddress The contract address of the survey creator
    event SurveyCreated(address indexed owner, uint256 indexed surveyId, address indexed surveyAddress);

    /// @notice Sets the survey creation fees
    /// @dev survey creation fees should be greater than zero
    /// @param _surveyCreationFees The value to be charged to survey creator
    constructor(uint _surveyCreationFees) {
        require(_surveyCreationFees > 0);
        surveyCreationFees = _surveyCreationFees;
        emit SurveyFactoryInitialized(surveyCreationFees);
    }

    /// @dev Check whether the caller is not owner
    modifier notTheOwner() {
        require(msg.sender != owner(), "SurveyFactory: restricted");
        _;
    }

    /// @notice Creates a surveys with a fee. It cannot be called by the owner
    /// @dev The value of ethers sent to this function should be greater tha survey creation fees
    ///      Emits an event with survey creator's address, survey Id and survey address 
    /// @return surveyId The ID of the survey
    /// @return newSurveyAddress The address of the survey contract
    function createSurvey() external notTheOwner payable returns(uint surveyId, address newSurveyAddress) {
        require(msg.value > surveyCreationFees, "SurveyFactory: Not enough ethers");
        // solhint-disable-next-line
        TrustedSurvey newSurvey = new TrustedSurvey{value: msg.value-surveyCreationFees}(msg.sender);
        newSurveyAddress = address(newSurvey);
        surveys.push(newSurveyAddress);
        surveyId = surveys.length - 1;
        surveyOwners[newSurveyAddress] = SurveyDetails({owner:msg.sender, id:surveyId});
        emit SurveyCreated(msg.sender, surveyId, newSurveyAddress);
    }

    ////////////////////////////
    //// Helper Functions //////
    ////////////////////////////

    /// @notice Retrieve the list of surveys
    /// @return address[] Array of the survey contract addresses
    function getAllSurveys() public view returns(address[] memory) {
        return surveys;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/// @title A survey contract
/// @author Dhruvin
/// @notice Initializes the survey
contract TrustedSurvey{

    /// @notice address of the survey owner
    address public owner;

    /// @notice contract address of the survey factory
    address public factory;

    /// @notice Logs when survey contract is created
    /// @param owner The address of the survey creator
    /// @param surveyReward Reward set for the survey participant
    event SurveyInitialized(address indexed owner, uint256 indexed surveyReward);

    /// @notice Creates the survey contract
    /// @dev The reward value should be greater than zero
    constructor(address _owner) payable {
        require(msg.value > 0, "Survey: amount greter than zero");
        factory = msg.sender;
        owner = _owner;
        emit SurveyInitialized(owner, msg.value);
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

