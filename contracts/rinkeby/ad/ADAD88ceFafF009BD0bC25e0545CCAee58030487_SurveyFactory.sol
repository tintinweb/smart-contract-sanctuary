// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./TrustedSurvey.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SurveyFactory is Ownable {

    struct SurveyDetails {
        address owner;
        uint256 id;
    }

    uint256 public surveyCreationFees;
    address[] public surveys;
    mapping(address => SurveyDetails) public surveyOwners;
    event SurveyFactoryInitialized(uint256 indexed surveyCreationFees);
    event SurveyCreated(address indexed owner, uint256 indexed surveyId, address indexed surveyAddress);


    constructor(uint _surveyCreationFees) {
        surveyCreationFees = _surveyCreationFees;
        emit SurveyFactoryInitialized(surveyCreationFees);
    }

    modifier notTheOwner() {
        require(msg.sender != owner(), "SurveyFactory: restricted");
        _;
    }

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

    function getAllSurveys() public view returns(address[] memory) {
        return surveys;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract TrustedSurvey {

    address public owner;
    address public factory;

    event SurveyInitialized(address indexed owner, uint256 indexed surveyReward);

    constructor(address _owner) payable {
        require(_owner != address(0), "Survey:Invalid owner address");
        require(msg.value > 0, "Survey: amount greter than zero");
        owner = _owner;
        factory = msg.sender;
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
    constructor () {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

