// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "./SecurityTokenStorage.sol";

contract SecurityTokenProxy is SecurityTokenStorage {

    /// @dev Implementation
    address internal implementation;

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /**
     * @dev constructor that sets the owner address
     */
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation address of the new implementation
     */
    function upgradeTo(address _newImplementation) external onlyOwner {
        require(implementation != _newImplementation);
        implementation = _newImplementation;
    }
    
    /**
     * @dev Fallback function allowing to perform a delegatecall 
     * to the given implementation. This function will return 
     * whatever the implementation call returns
     */
    fallback() external payable {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract SecurityTokenStorage {
    /// @notice Name of the security token.
    string public name;

    /// @notice Symbol of the security token.
    string public symbol;

    /// @notice Decimals which will decide whether it's divisible or not and if divisible then upto how many decimal places.
    uint8 public decimals;

    /// @notice Owner of the security token.
    address public owner;

    /// @notice Maximum no. of investors allowed.
    uint256 public maxInvestors;

    /// @notice Current no. of investors.
    uint256 public investorsCount = 0;

    /// @notice List of whitelisted addresses.
    mapping(address => bool) public isWhitelisted;

    /// @notice Bool value representing whether transfer of token requires whitelisting.
    bool public isKycRequiredForTransfer;

    // A mapping for storing balances of investors
    mapping(address => uint256) internal _balances;

    // A mapping for storing allowances
    mapping(address => mapping(address => uint256)) internal _allowed;

    // Current total supply of token
    uint256 internal _totalSupply;

    // Represents whether token is issuable
    bool internal issuance = true;

    /// @notice An event thats emitted when issuance is finalized.
    event IssuanceFinalized();

    /// @notice An event thats emitted when any address is whitelisted.
    event Whitelisted(address account);
}

