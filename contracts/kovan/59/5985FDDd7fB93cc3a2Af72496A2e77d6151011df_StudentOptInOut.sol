/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/StudentOptInOut.sol


pragma solidity ^0.8.2;


contract StudentOptInOut is Ownable {

    mapping(address => string) optInOutFlag;
    mapping(address => address) processorChoice;
    event DataCollectionConsent(address _address, string _choice);
    event joinProcessor(address _student, address _processor);
    event leaveProcessor(address _student, address _processor);

    function setStudentCollectionConsent(address _addr, string memory _choice) public onlyOwner {
        bytes memory x = bytes(_choice);
        bytes32 Hash = keccak256(x);
        bool validChoice;

        if (Hash == keccak256("Out") || Hash == keccak256("out")) {
            validChoice = true;
            optInOutFlag[_addr] =  "Out";
        }
        else if (Hash == keccak256("Training") || Hash == keccak256("training")) {
            validChoice = true;
            optInOutFlag[_addr] =  "Training";
        }
        else if (Hash == keccak256("Prediction") || Hash == keccak256("prediction")) {
            validChoice = true;
            optInOutFlag[_addr] =  "Prediction";
        }
        require(validChoice, "Invalid choice");

        emit DataCollectionConsent(_addr, optInOutFlag[_addr]);
    }

    function setProcesorChoice(address _addr1, address _addr2) public onlyOwner {
        require(_addr1 != _addr2, 'Student cannot be a processor');
        processorChoice[_addr1] = _addr2;

       emit joinProcessor(_addr1, _addr2);
    }

    function leaveProcesorChoice(address _addr1, address _addr2) public onlyOwner {
        require(_addr1 != _addr2, 'Student cannot be a processor');
        processorChoice[_addr1] = address(0);

       emit leaveProcessor(_addr1, _addr2);
    }

    function getProcesorChoice(address _address) public view returns(address) {
        return processorChoice[_address];
    }

    function getStudentCollectionConsent(address _addr) public view returns(string memory) {
        bytes memory tempEmptyStringTest = bytes(optInOutFlag[_addr]); // Uses memory
        require(tempEmptyStringTest.length > 0, "Consent has not yet been set for this student"); 
        return optInOutFlag[_addr];
    }

    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here"); //not possible with this smart contract
    }

    function transferOwnership(address _addr) public view override onlyOwner {
        _addr = address(0);
        revert("Cannot Transfer Ownership"); //not possible with this smart contract
    }
}