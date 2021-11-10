// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../libraries/Authorizable.sol";
import "../interfaces/IERC20.sol";

// Has governance tokens provided by the treasury, can execute calls to spend them
// Three separate functions which all spending different amounts. We enforce
// spending limit by block so that no governance proposal can execute a bundle
// of small spend transactions with low quorum.

contract Spender is Authorizable {
    // Mapping storing how much is spent in each block
    // Note - There's minor stability and griefing considerations around tracking the expenditure
    //        per block for all spend limits. Namely two proposals may try to get executed in the same block and have one
    //        fail on accident or on purpose. These are for semi-rare non contentious spending so
    //        we do not consider either a major concern.
    mapping(uint256 => uint256) public blockExpenditure;
    // The low, medium and high spending barriers
    uint256 public smallSpendLimit;
    uint256 public mediumSpendLimit;
    uint256 public highSpendLimit;
    // The immutable token contract
    IERC20 public immutable token;

    /// @notice Constructs and sets the permissions plus initial state variables
    /// @param _owner The contract owner who can change spending limits and authorized addresses
    /// @param _spender The first address authorized to spend
    /// @param _token the immutable token this contract has a balance of
    /// @param _smallSpendLimit The limit on how much spending a small spend proposal can do
    /// @param _mediumSpendLimit The limit on how much spending a medium spend proposal can do
    /// @param _highSpendLimit The limit on how much spending a high spend proposal can do
    constructor(
        address _owner,
        address _spender,
        IERC20 _token,
        uint256 _smallSpendLimit,
        uint256 _mediumSpendLimit,
        uint256 _highSpendLimit
    ) {
        // Configure access controls, by authorizing the spender and setting the owner.
        _authorize(_spender);
        setOwner(_owner);
        // Set state and immutable variables
        token = _token;
        smallSpendLimit = _smallSpendLimit;
        mediumSpendLimit = _mediumSpendLimit;
        highSpendLimit = _highSpendLimit;
    }

    /// @notice Spends up to the small spend limit
    /// @param amount the amount to spend
    /// @param destination the destination to send the token to
    function smallSpend(uint256 amount, address destination)
        external
        onlyAuthorized
    {
        _spend(amount, destination, smallSpendLimit);
    }

    /// @notice Spends up to the medium spend limit
    /// @param amount the amount to spend
    /// @param destination the destination to send the token to
    function mediumSpend(uint256 amount, address destination)
        external
        onlyAuthorized
    {
        _spend(amount, destination, mediumSpendLimit);
    }

    /// @notice Spends up to the high spend limit
    /// @param amount the amount to spend
    /// @param destination the destination to send the token to
    function highSpend(uint256 amount, address destination)
        external
        onlyAuthorized
    {
        _spend(amount, destination, highSpendLimit);
    }

    /// @notice The internal function to handle each of the spend call
    /// @param amount the amount to spend
    /// @param destination the destination to send the tokens to
    /// @param limit the per block spending limit enforced by this call
    function _spend(
        uint256 amount,
        address destination,
        uint256 limit
    ) internal {
        // Check that after processing this we will not have spent more than the block limit
        uint256 spentThisBlock = blockExpenditure[block.number];
        require(amount + spentThisBlock <= limit, "Spend Limit Exceeded");
        // Reentrancy is very unlikely in this context, but we still change state first
        blockExpenditure[block.number] = amount + spentThisBlock;
        // Transfer tokens
        token.transfer(destination, amount);
    }

    /// @notice Sets the low, medium, and high spend limits, must be called by the timelock
    /// @param limits [low spend limit, medium spend limit, high spend limit]
    /// @dev This function always sets all limits, to change only one the previous values
    ///      of the other two must be provided to this call.
    function setLimits(uint256[] memory limits) external onlyOwner {
        // Set the spend limits
        smallSpendLimit = limits[0];
        mediumSpendLimit = limits[1];
        highSpendLimit = limits[2];
    }

    /// @notice Part of the deprecation process, allows the timelock to move all of the funds
    ///         out of this contract.
    /// @param amount The amount of tokens to remove, max uint256 for the full balance
    /// @param destination the destination to send the tokens to
    function removeToken(uint256 amount, address destination)
        external
        onlyOwner
    {
        // If they use max then we just transfer out the balance
        if (amount == type(uint256).max) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(destination, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

contract Authorizable {
    // This contract allows a flexible authorization scheme

    // The owner who can change authorization status
    address public owner;
    // A mapping from an address to its authorization status
    mapping(address => bool) public authorized;

    /// @dev We set the deployer to the owner
    constructor() {
        owner = msg.sender;
    }

    /// @dev This modifier checks if the msg.sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    /// @dev This modifier checks if an address is authorized
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "Sender not Authorized");
        _;
    }

    /// @dev Returns true if an address is authorized
    /// @param who the address to check
    /// @return true if authorized false if not
    function isAuthorized(address who) public view returns (bool) {
        return authorized[who];
    }

    /// @dev Privileged function authorize an address
    /// @param who the address to authorize
    function authorize(address who) external onlyOwner() {
        _authorize(who);
    }

    /// @dev Privileged function to de authorize an address
    /// @param who The address to remove authorization from
    function deauthorize(address who) external onlyOwner() {
        authorized[who] = false;
    }

    /// @dev Function to change owner
    /// @param who The new owner address
    function setOwner(address who) public onlyOwner() {
        owner = who;
    }

    /// @dev Inheritable function which authorizes someone
    /// @param who the address to authorize
    function _authorize(address who) internal {
        authorized[who] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}