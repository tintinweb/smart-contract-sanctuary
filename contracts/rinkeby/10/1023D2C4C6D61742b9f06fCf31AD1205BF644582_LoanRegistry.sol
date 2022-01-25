// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../utils/Ownable.sol";
import "../utils/ContractKeys.sol";

/**
 * @title  LoanRegistry
 * @author NFTfi
 * @dev Registry for Loan Types supported by NFTfi.
 * Each Loan type is associated with the address of a Loan contract that implements the loan type.
 */
contract LoanRegistry is Ownable {
    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @dev For each loan type, records the address of the contract that implements the type
     */
    mapping(bytes32 => address) private typeContracts;
    /**
     * @dev reverse mapping of loanTypes - for each contract address, records the associated loan type
     */
    mapping(address => bytes32) private contractTypes;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admins register a loan type.
     *
     * @param loanType - Loan type represented by keccak256('loan type').
     * @param loanContract - Address of the loan type contract.
     */
    event TypeUpdated(bytes32 indexed loanType, address indexed loanContract);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Sets the admin of the contract.
     * Initializes `contractTypes` with a batch of loan types.
     *
     * @param _admin - Initial admin of this contract.
     * @param _loanTypes - Loan types represented by keccak256('loan type').
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    constructor(
        address _admin,
        string[] memory _loanTypes,
        address[] memory _loanContracts
    ) Ownable(_admin) {
        _registerLoans(_loanTypes, _loanContracts);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice  Set or update the contract address that implements the given Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanType - Loan type represented by 'loan type'.
     * @param _loanContract - The address of the wrapper contract that implements the loan type's behaviour.
     */
    function registerLoan(string memory _loanType, address _loanContract) external onlyOwner {
        _registerLoan(_loanType, _loanContract);
    }

    /**
     * @notice  Batch set or update the contract addresses that implement the given batch Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanTypes - Loan types represented by 'loan type'.
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    function registerLoans(string[] memory _loanTypes, address[] memory _loanContracts) external onlyOwner {
        _registerLoans(_loanTypes, _loanContracts);
    }

    /**
     * @notice This function can be called by anyone to get the contract address that implements the given loan type.
     *
     * @param  _loanType - The loan type, e.g. bytes32("DIRECT_LOAN_FIXED"), or bytes32("DIRECT_LOAN_PRO_RATED").
     */
    function getContractFromType(bytes32 _loanType) external view returns (address) {
        return typeContracts[_loanType];
    }

    /**
     * @notice This function can be called by anyone to get the loan type of the given contract address.
     *
     * @param  _loanContract - The loan contract
     */
    function getTypeFromContract(address _loanContract) external view returns (bytes32) {
        return contractTypes[_loanContract];
    }

    /**
     * @notice  Set or update the contract address that implements the given Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanType - Loan type represented by 'loan type').
     * @param _loanContract - The address of the wrapper contract that implements the loan type's behaviour.
     */
    function _registerLoan(string memory _loanType, address _loanContract) internal {
        require(bytes(_loanType).length != 0, "loanType is empty");
        bytes32 loanTypeKey = ContractKeys.getIdFromStringKey(_loanType);

        typeContracts[loanTypeKey] = _loanContract;
        contractTypes[_loanContract] = loanTypeKey;

        emit TypeUpdated(loanTypeKey, _loanContract);
    }

    /**
     * @notice  Batch set or update the contract addresses that implement the given batch Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanTypes - Loan types represented by keccak256('loan type').
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    function _registerLoans(string[] memory _loanTypes, address[] memory _loanContracts) internal {
        require(_loanTypes.length == _loanContracts.length, "registerLoans function information arity mismatch");

        for (uint256 i = 0; i < _loanTypes.length; i++) {
            _registerLoan(_loanTypes[i], _loanContracts[i]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

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
 *
 * Modified version from openzeppelin/contracts/access/Ownable.sol that allows to
 * initialize the owner using a parameter in the constructor
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(_newOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Sets the owner.
     */
    function _setOwner(address _newOwner) private {
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title ContractKeys
 * @author NFTfi
 * @dev Common library for contract keys
 */
library ContractKeys {
    bytes32 public constant PERMITTED_ERC20S = bytes32("PERMITTED_ERC20S");
    bytes32 public constant PERMITTED_NFTS = bytes32("PERMITTED_NFTS");
    bytes32 public constant PERMITTED_PARTNERS = bytes32("PERMITTED_PARTNERS");
    bytes32 public constant NFT_TYPE_REGISTRY = bytes32("NFT_TYPE_REGISTRY");
    bytes32 public constant LOAN_REGISTRY = bytes32("LOAN_REGISTRY");
    bytes32 public constant PERMITTED_SNFT_RECEIVER = bytes32("PERMITTED_SNFT_RECEIVER");
    bytes32 public constant PERMITTED_BUNDLE_ERC20S = bytes32("PERMITTED_BUNDLE_ERC20S");
    bytes32 public constant PERMITTED_AIRDROPS = bytes32("PERMITTED_AIRDROPS");
    bytes32 public constant AIRDROP_RECEIVER = bytes32("AIRDROP_RECEIVER");
    bytes32 public constant AIRDROP_FACTORY = bytes32("AIRDROP_FACTORY");
    bytes32 public constant AIRDROP_FLASH_LOAN = bytes32("AIRDROP_FLASH_LOAN");
    bytes32 public constant NFTFI_BUNDLER = bytes32("NFTFI_BUNDLER");

    string public constant AIRDROP_WRAPPER_STRING = "AirdropWrapper";

    /**
     * @notice Returns the bytes32 representation of a string
     * @param _key the string key
     * @return id bytes32 representation
     */
    function getIdFromStringKey(string memory _key) external pure returns (bytes32 id) {
        require(bytes(_key).length <= 32, "invalid key");

        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := mload(add(_key, 32))
        }
    }
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