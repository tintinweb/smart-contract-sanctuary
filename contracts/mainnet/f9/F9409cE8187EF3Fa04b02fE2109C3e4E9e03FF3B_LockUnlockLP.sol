/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

//SPDX-License-Identifier: MIT
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


/// @title The interface for Graviton lp-token lock-unlock
/// @notice Locks liquidity provision tokens
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
interface ILockUnlockLP {
    /// @notice User that can grant access permissions and perform privileged actions
    function owner() external view returns (address);

    /// @notice Transfers ownership of the contract to a new account (`_owner`).
    /// @dev Can only be called by the current owner.
    function setOwner(address _owner) external;

    /// @notice Look up if locking is allowed
    function canLock() external view returns (bool);

    /// @notice Sets the permission to lock to `_canLock`
    function setCanLock(bool _canLock) external;

    /// @notice Look up if the locking of `token` is allowed
    function isAllowedToken(address token) external view returns (bool);

    /// @notice Look up if the locking of `token` is allowed
    function lockLimit(address token) external view returns (uint256);

    /// @notice Sets minimum lock amount limit for `token` to `_lockLimit`
    function setLockLimit(address token, uint256 _lockLimit) external;

    /// @notice The total amount of locked `token`
    function tokenSupply(address token) external view returns (uint256);

    /// @notice The total amount of all locked lp-tokens
    function totalSupply() external view returns (uint256);

    /// @notice Sets permission to lock `token` to `_isAllowedToken`
    function setIsAllowedToken(address token, bool _isAllowedToken) external;

    /// @notice The amount of `token` locked by `depositer`
    function balance(address token, address depositer)
        external
        view
        returns (uint256);

    /// @notice Locks `amount` of `token` in the name of `receiver`
    function lock(
        address token,
        address receiver,
        uint256 amount
    ) external;

    /// @notice Transfer `amount` of `token` to the `receiver`
    function unlock(
        address token,
        address receiver,
        uint256 amount
    ) external;

    /// @notice Event emitted when the owner changes via `#setOwner`.
    /// @param ownerOld The account that was the previous owner of the contract
    /// @param ownerNew The account that became the owner of the contract
    event SetOwner(address indexed ownerOld, address indexed ownerNew);

    /// @notice Event emitted when the `sender` locks `amount` of `token` lp-tokens in the name of `receiver`
    /// @param token The address of the lp-token
    /// @param sender The account that locked lp-token
    /// @param receiver The account to whose lp-token balance the tokens are added
    /// @param amount The amount of lp-tokens locked
    event Lock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the `sender` unlocks `amount` of `token` lp-tokens in the name of `receiver`
    /// @param token The address of the lp-token
    /// @param sender The account that unlocked lp-tokens
    /// @param receiver The account to whom the lp-tokens were transferred
    /// @param amount The amount of lp-tokens unlocked
    event Unlock(
        address indexed token,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Event emitted when the permission to lock token is updated via `#setIsAllowedToken`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param newBool Updated permission
    event SetIsAllowedToken(
        address indexed owner,
        address indexed token,
        bool indexed newBool
    );

    /// @notice Event emitted when the minimum lock amount limit updated via `#setLockLimit`
    /// @param owner The owner account at the time of change
    /// @param token The lp-token whose permission was updated
    /// @param _lockLimit New minimum lock amount limit
    event SetLockLimit(
        address indexed owner,
        address indexed token,
        uint256 indexed _lockLimit
    );

    /// @notice Event emitted when the permission to lock is updated via `#setCanLock`
    /// @param owner The owner account at the time of change
    /// @param newBool Updated permission
    event SetCanLock(
        address indexed owner,
        bool indexed newBool
    );
}


/// @title LockUnlockLP
/// @author Artemij Artamonov - <[email protected]>
/// @author Anton Davydov - <[email protected]>
contract LockUnlockLP is ILockUnlockLP {

    /// @inheritdoc ILockUnlockLP
    address public override owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /// @inheritdoc ILockUnlockLP
    mapping(address => bool) public override isAllowedToken;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override lockLimit;
    mapping(address => mapping(address => uint256)) internal _balance;
    /// @inheritdoc ILockUnlockLP
    mapping(address => uint256) public override tokenSupply;
    /// @inheritdoc ILockUnlockLP
    uint256 public override totalSupply;

    /// @inheritdoc ILockUnlockLP
    bool public override canLock;

    constructor(address[] memory allowedTokens) {
        owner = msg.sender;
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            isAllowedToken[allowedTokens[i]] = true;
        }
    }

    /// @inheritdoc ILockUnlockLP
    function setOwner(address _owner) external override isOwner {
        address ownerOld = owner;
        owner = _owner;
        emit SetOwner(ownerOld, _owner);
    }

    /// @inheritdoc ILockUnlockLP
    function setIsAllowedToken(address token, bool _isAllowedToken)
        external
        override
        isOwner
    {
        isAllowedToken[token] = _isAllowedToken;
        emit SetIsAllowedToken(owner, token, _isAllowedToken);
    }

    /// @inheritdoc ILockUnlockLP
    function setLockLimit(address token, uint256 _lockLimit)
        external
        override
        isOwner
    {
        lockLimit[token] = _lockLimit;
        emit SetLockLimit(owner, token, _lockLimit);
    }

    /// @inheritdoc ILockUnlockLP
    function setCanLock(bool _canLock) external override isOwner {
        canLock = _canLock;
        emit SetCanLock(owner, _canLock);
    }

    /// @inheritdoc ILockUnlockLP
    function balance(address token, address depositer)
        external
        view
        override
        returns (uint256)
    {
        return _balance[token][depositer];
    }

    /// @inheritdoc ILockUnlockLP
    function lock(
        address token,
        address receiver,
        uint256 amount
    ) external override {
        require(canLock, "lock is not allowed");
        require(isAllowedToken[token], "token not allowed");
        require(amount >= lockLimit[token], "limit exceeded");
        _balance[token][receiver] += amount;
        tokenSupply[token] += amount;
        totalSupply += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Lock(token, msg.sender, receiver, amount);
    }

    /// @inheritdoc ILockUnlockLP
    function unlock(
        address token,
        address receiver,
        uint256 amount
    ) external override {
        require(_balance[token][msg.sender] >= amount, "not enough balance");
        _balance[token][msg.sender] -= amount;
        tokenSupply[token] -= amount;
        totalSupply -= amount;
        IERC20(token).transfer(receiver, amount);
        emit Unlock(token, msg.sender, receiver, amount);
    }
}