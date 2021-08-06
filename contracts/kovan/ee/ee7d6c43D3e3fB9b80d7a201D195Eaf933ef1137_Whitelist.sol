pragma solidity 0.5.16;

/// @title Ownable
/// @dev Provide a simple access control with a single authority: the owner
contract Ownable {

    // Ethereum address of current owner
    address public owner;

    // Ethereum address of the next owner
    // (has to claim ownership first to become effective owner)
    address public newOwner;

    // @dev Log event on ownership transferred
    // @param previousOwner Ethereum address of previous owner
    // @param newOwner Ethereum address of new owner
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev Forbid call by anyone but owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Restricted to owner");
        _;
    }

    /// @dev Deployer account becomes initial owner
    constructor() public {
        owner = msg.sender;
    }

    /// @dev  Transfer ownership to a new Ethereum account (safe method)
    ///       Note: the new owner has to claim his ownership to become effective owner.
    /// @param _newOwner  Ethereum address to transfer ownership to
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0), "New owner is zero");

        newOwner = _newOwner;
    }

    /// @dev  Transfer ownership to a new Ethereum account (unsafe method)
    ///       Note: It's strongly recommended to use the safe variant via transferOwnership
    ///             and claimOwnership, to prevent accidental transfers to a wrong address.
    /// @param _newOwner  Ethereum address to transfer ownership to
    function transferOwnershipUnsafe(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0), "New owner is zero");

        _transferOwnership(_newOwner);
    }

    /// @dev  Become effective owner (if dedicated so by previous owner)
    function claimOwnership() public {
        require(msg.sender == newOwner, "Restricted to new owner");

        _transferOwnership(msg.sender);
    }

    /// @dev  Transfer ownership (internal method)
    /// @param _newOwner  Ethereum address to transfer ownership to
    function _transferOwnership(address _newOwner) private {
        if (_newOwner != owner) {
            emit OwnershipTransferred(owner, _newOwner);

            owner = _newOwner;
        }
        newOwner = address(0x0);
    }

}

pragma solidity 0.5.16;

import "../ownership/Ownable.sol";


/// @title Whitelist
/// @author STOKR
contract Whitelist is Ownable {

    // Set of admins
    mapping(address => bool) public admins;

    // Set of Whitelisted addresses
    mapping(address => bool) public isWhitelisted;

    /// @dev Log entry on admin added to set
    /// @param admin An Ethereum address
    event AdminAdded(address indexed admin);

    /// @dev Log entry on admin removed from set
    /// @param admin An Ethereum address
    event AdminRemoved(address indexed admin);

    /// @dev Log entry on investor added set
    /// @param admin An Ethereum address
    /// @param investor An Ethereum address
    event InvestorAdded(address indexed admin, address indexed investor);

    /// @dev Log entry on investor removed from set
    /// @param admin An Ethereum address
    /// @param investor An Ethereum address
    event InvestorRemoved(address indexed admin, address indexed investor);

    /// @dev Only admin
    modifier onlyAdmin() {
        require(admins[msg.sender], "Restricted to whitelist admin");
        _;
    }

    /// @dev Add admin to set
    /// @param _admin An Ethereum address
    function addAdmin(address _admin) public onlyOwner {
        require(_admin != address(0x0), "Whitelist admin is zero");

        if (!admins[_admin]) {
            admins[_admin] = true;

            emit AdminAdded(_admin);
        }
    }

    /// @dev Remove admin from set
    /// @param _admin An Ethereum address
    function removeAdmin(address _admin) public onlyOwner {
        require(_admin != address(0x0), "Whitelist admin is zero");  // Necessary?

        if (admins[_admin]) {
            admins[_admin] = false;

            emit AdminRemoved(_admin);
        }
    }

    /// @dev Add investor to set of whitelisted addresses
    /// @param _investors A list where each entry is an Ethereum address
    function addToWhitelist(address[] calldata _investors) external onlyAdmin {
        for (uint256 i = 0; i < _investors.length; i++) {
            if (!isWhitelisted[_investors[i]]) {
                isWhitelisted[_investors[i]] = true;

                emit InvestorAdded(msg.sender, _investors[i]);
            }
        }
    }

    /// @dev Remove investor from set of whitelisted addresses
    /// @param _investors A list where each entry is an Ethereum address
    function removeFromWhitelist(address[] calldata _investors) external onlyAdmin {
        for (uint256 i = 0; i < _investors.length; i++) {
            if (isWhitelisted[_investors[i]]) {
                isWhitelisted[_investors[i]] = false;

                emit InvestorRemoved(msg.sender, _investors[i]);
            }
        }
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}