// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../interfaces/IVotingVault.sol";
import "../interfaces/IERC20.sol";

// This contract allows anybody to assign a grant to an address that can be claimed at a given timestamp.
// Governance can edit or revoke a grant at any give time and withdraw the funds from the solvency.
contract OptimisticGrants {
    IERC20 public immutable token;
    address _governance;
    uint256 public solvency;

    struct Grant {
        // total grant value
        uint128 amount;
        // grant expiration timestamp
        uint128 expiration;
    }

    mapping(address => Grant) public grants;

    /// @dev Modifier checks if the msg.sender is the governance address
    modifier onlyGovernance() {
        require(msg.sender == _governance, "!governance");
        _;
    }

    /// @notice Constructs and sets governance and token addresses
    /// @param _token Address of the ERC20 token the grants will work with
    /// @param __governance The governance address for ACL.
    constructor(IERC20 _token, address __governance) {
        _governance = __governance;
        token = _token;
    }

    /// @notice Deposit an amount of tokens to the contract solvency.
    /// @param _amount The amount to add to the solvency.
    function deposit(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        solvency += _amount;
    }

    /// @notice Withdraw from the solvency.
    /// @param _amount The amount to remove from the solvency.
    /// @param _recipient The address to send the withdrawn funds to.
    function withdraw(uint256 _amount, address _recipient)
        public
        onlyGovernance
    {
        require(_amount <= solvency, "insufficient funds");
        solvency -= _amount;
        token.transfer(_recipient, _amount);
    }

    /// @notice Create a grant or edit active grant parameters.
    /// @dev Will override an active grant.
    /// Only 1 grant is possible per address at any given time.
    /// @param _owner The grant recipient.
    /// @param _amount The grant amount.
    /// @param _expiration The expiration timestamp of the grant.
    function configureGrant(
        address _owner,
        uint128 _amount,
        uint128 _expiration
    ) external onlyGovernance {
        uint128 oldAmount = grants[_owner].amount;
        // if the new amount is greater, reduce the difference from the solvency.
        // will revert in case of insufficient solvency with underflow error.
        if (oldAmount < _amount) {
            solvency -= (_amount - oldAmount);
        }
        // if the new amount is smaller, add back to the solvency
        else {
            solvency += (oldAmount - _amount);
        }
        grants[_owner].amount = _amount;
        grants[_owner].expiration = _expiration;
    }

    /// @notice Claim a grant.
    /// @dev When a grant expires it can be claimed by the owner.
    /// @param _destination The address which will receive the grant.
    function claim(address _destination) public {
        require(block.timestamp >= grants[msg.sender].expiration, "not mature");

        // change state before transfer for reentrancy guard.
        uint256 amount = grants[msg.sender].amount;
        delete grants[msg.sender];

        token.transfer(_destination, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IVotingVault {
    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @param extraData Abi encoded optional extra data used by some vaults, such as merkle proofs
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata extraData
    ) external returns (uint256);
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