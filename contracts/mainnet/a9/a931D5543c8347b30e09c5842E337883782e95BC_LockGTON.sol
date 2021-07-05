//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/ILockGTON.sol";

/// @title LockGTON
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockGTON is ILockGTON {
    /// @inheritdoc ILockGTON
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "ACW");
        _;
    }

    /// @inheritdoc ILockGTON
    IERC20 public override governanceToken;

    /// @inheritdoc ILockGTON
    bool public override canLock;

    constructor(IERC20 _governanceToken) {
        owner = msg.sender;
        governanceToken = _governanceToken;
    }

    /// @inheritdoc ILockGTON
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockGTON
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockGTON
    function migrate(address newLock) external override isOwner {
        uint256 amount = governanceToken.balanceOf(address(this));
        governanceToken.transfer(newLock, amount);
        emit Migrate(newLock, amount);
    }

    /// @inheritdoc ILockGTON
    function lock(uint256 amount) external override {
        require(canLock, "LG1");
        governanceToken.transferFrom(msg.sender, address(this), amount);
        emit LockGTON(address(governanceToken), msg.sender, msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @title The interface for Graviton governance token lock
/// @notice Locks governance tokens
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILockGTON {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if locking is allowed
    function canLock() external view returns (bool);

    /// @notice Sets the permission to lock to `_canLock`
    function setCanLock(bool _canLock) external;

    /// @notice Address of the governance token
    function governanceToken() external view returns (IERC20);

    /// @notice Transfers locked governance tokens to the next version of LockGTON
    function migrate(address newLock) external;

    /// @notice Locks `amount` of governance tokens
    function lock(uint256 amount) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `sender` locks `amount` of governance tokens
    /// @dev LockGTON event is not called Lock so the topic0 is different
    /// from the lp-token locking event when parsed by the oracle parser
    /// @param governanceToken The address of governance token
    /// @dev governanceToken is specified so the event has the same number of topics
    /// as the lp-token locking event when parsed by the oracle parser
    /// @param sender The account that locked governance tokens
    /// @param receiver The account to whose governance balance the tokens are added
    /// @dev receiver is always same as sender, kept for compatibility
    /// @param amount The amount of governance tokens locked
    event LockGTON(
        address indexed governanceToken,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the permission to lock is updated via `#setCanLock`
    /// @param owner The owner account at the time of change
    /// @param newBool Updated permission
    event SetCanLock(address indexed owner, bool indexed newBool);

    /// @notice Event emitted when the locked governance tokens are transfered the another version of LockGTON
    /// @param newLock The new Lock contract
    /// @param amount Amount of tokens migrated
    event Migrate(address indexed newLock, uint256 amount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function balanceOf(address _owner) external view returns (uint256 balance);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}