// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is AccessControl, ReentrancyGuard {
    PoolInfo[12] public pools;

    mapping(address => mapping(uint8 => UserInfo)) public processForInvestor; // UserInfo for address and index

    struct UserInfo {
        uint256 amount; // amount of staked tokens
        uint256 rewardGot; // reward user already got
        uint256 start; // time when user made stake
        uint256 unlocked;
        uint256 index;
        mapping(uint256 => uint256) timeLocked;
        mapping(uint256 => uint256) sumLocked;
    }

    struct PoolInfo {
        address rewardsToken; // tokens for reward
        address stakingToken; // tokens for staking
        address feeKeeper; // address for getting percent for dtaking
        address rewardKeeper; // address which hold tokens for rewards
        uint256 amountStaked; // amount staked at this pool
        uint256 timeLockUp; // time of lock up
        uint8 fee; // percent of fee
        uint16 APY; // necessary apy
        address[] stakeholders; // users which stake tokens at this pool
        mapping(address => uint256) index; // index for user in array of stakeholders
    }

    event StakeTokenForUser(
        address investor,
        uint256 amount,
        uint8 poolId,
        uint256 start
    );

    event GetRewardForUser(
        address investor,
        uint8 poolId,
        uint256 amount,
        uint256 timeGotReward
    );

    event IncreaseStakeForUser(address investor, uint256 amount, uint8 poolId);

    event DecreaseForUser(address investor, uint8 poolId, uint256 amount);

    modifier onlyHolderOrAdmin(address _investor) {
        require(
            _investor == _msgSender() ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Staking: have no rights"
        );
        _;
    }

    constructor(
        address[12] memory _stakingTokens,
        address[12] memory _rewardTokens,
        address[12] memory _feeKeeper,
        address[12] memory _rewardKeeper,
        uint256[12] memory _timeLockUp,
        uint8[12] memory _fee,
        uint16[12] memory _APY
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint8 i = 0; i < 12; i++) {
            if (i != 10) {
                require(
                    _stakingTokens[i] != address(0),
                    "Staking: staking token is zero address"
                );
            }
            require(
                _rewardTokens[i] != address(0),
                "Staking: reward token is zero address"
            );
            pools[i].stakingToken = _stakingTokens[i];
            pools[i].rewardsToken = _rewardTokens[i];
            pools[i].feeKeeper = _feeKeeper[i];
            pools[i].rewardKeeper = _rewardKeeper[i];
            pools[i].timeLockUp = _timeLockUp[i];
            pools[i].fee = _fee[i];
            pools[i].APY = _APY[i];
        }
    }

    receive() external payable {}

    /**
     * @param _poolId pool id
     */
    function getPoolInfo(uint8 _poolId)
        external
        view
        returns (
            address rewardsToken_,
            address stakingToken_,
            address feeKeeper_,
            uint256 amountStaked_,
            uint256 timeLockUp_,
            uint256 fee_,
            uint256 APY_,
            address[] memory stakeholders_
        )
    {
        PoolInfo storage poolSign = pools[_poolId];
        rewardsToken_ = poolSign.rewardsToken;
        stakingToken_ = poolSign.stakingToken;
        feeKeeper_ = poolSign.feeKeeper;
        amountStaked_ = poolSign.amountStaked;
        timeLockUp_ = poolSign.timeLockUp;
        fee_ = poolSign.fee;
        APY_ = poolSign.APY;
        stakeholders_ = poolSign.stakeholders;
    }

    /**
     * calculate amount of reward for user at process numbered #_index
     * @param _poolId pool id
     * @param _investor inevstor
     * @return rewardAmount reward amount
     */
    function _calculateReward(uint8 _poolId, address _investor)
        public
        view
        returns (uint256 rewardAmount)
    {
        UserInfo storage userSign = processForInvestor[_investor][_poolId];
        rewardAmount =
            (userSign.amount *
                pools[_poolId].APY *
                (block.timestamp - userSign.start)) / (100*365);
            //(100 * 60 * 60 * 24 * 365);
        if (
            _poolId == 2 ||
            _poolId == 3 ||
            _poolId == 4 ||
            _poolId == 11 ||
            _poolId == 10 ||
            _poolId == 9
        ) rewardAmount = rewardAmount / 10000000000;
        rewardAmount = rewardAmount - userSign.rewardGot;
    }

    /**
     * @param _investor owner of token which will be returned
     * @param _poolId number of process
     */
    function getProcessInfoForUser(address _investor, uint8 _poolId)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardGot,
            uint256 start
        )
    {
        UserInfo storage userSign = processForInvestor[_investor][_poolId];
        amount = userSign.amount;
        rewardGot = userSign.rewardGot;
        start = userSign.start;
    }

    /**
     * creat stake position at pool
     * @param _stake amount of token for staking
     * @param _poolId pool for staking
     */
    function createStake(uint256 _stake, uint8 _poolId)
        external
        payable
        nonReentrant
    {
        address investor = _msgSender();

        if (_poolId == 10) {
            _stake = msg.value;
        } else {
            require(msg.value == 0, "Staking: you shouldn`t use ETH");
        }

        require(_stake > 0, "Staking: it is not allowed to stake zero tokens");
        require(_poolId < 12, "Staking: there are only 12 pools");
        require(
            processForInvestor[investor][_poolId].amount == 0,
            "Staking: stake exists"
        );

        PoolInfo storage poolSign = pools[_poolId];
        uint256 amountFee = (_stake * poolSign.fee) / 100;
        poolSign.stakeholders.push(investor);
        poolSign.index[investor] = poolSign.stakeholders.length - 1;

        _stake -= amountFee;
        processForInvestor[investor][_poolId].amount = _stake;
        processForInvestor[investor][_poolId].start = block.timestamp;

        if (poolSign.timeLockUp > 0) {
            processForInvestor[investor][_poolId].timeLocked[0] = block
                .timestamp;
            processForInvestor[investor][_poolId].sumLocked[0] = _stake;
        }

        poolSign.amountStaked += _stake;
        transferStakeAndFee(_poolId, investor, _stake, amountFee);
        emit StakeTokenForUser(investor, _stake, _poolId, block.timestamp);
    }

    /**
     * allows user get his reward for process numbered #index
     * @param _poolId number of process
     * @param _investor address of investor
     */
    function withdrawReward(uint8 _poolId, address _investor)
        external
        nonReentrant
        onlyHolderOrAdmin(_investor)
    {
        _withdrawReward(_poolId, _investor);
    }

    /**
     * allows user return some of the tokens from staking
     * @param _investor owner of token which will be returned
     * @param _poolId number of process
     * @param _amount amount of tokens which should be returned
     */
    function removePartOfStake(
        address _investor,
        uint8 _poolId,
        uint256 _amount
    ) external payable nonReentrant onlyHolderOrAdmin(_investor) {
        PoolInfo storage poolSign = pools[_poolId];
        UserInfo storage userSign = processForInvestor[_investor][_poolId];

        require(
            _amount <= userSign.amount,
            "Staking: user has not enough tokens"
        );

        if (poolSign.timeLockUp > 0) {
            uint256 i = 0;
            while (i <= userSign.index && _amount > userSign.unlocked) {
                i = unlock(_poolId, _investor, i);
            }
            require(
                userSign.unlocked >= _amount,
                "Staking: now is period of lock up"
            );
        }

        _withdrawReward(_poolId, _investor);

        userSign.amount -= _amount;
        poolSign.amountStaked -= _amount;

        if (poolSign.timeLockUp > 0) {
            userSign.unlocked -= _amount;
        }

        userSign.rewardGot = calculateReward(
            _poolId,
            userSign.amount,
            userSign.start
        );

        if (userSign.amount == 0) {
            address[] memory holders = poolSign.stakeholders;
            uint256 i = poolSign.index[_investor];
            poolSign.index[holders[holders.length - 1]] = i;
            poolSign.index[_investor] = 0;
            poolSign.stakeholders[i] = holders[holders.length - 1];
            poolSign.stakeholders.pop();
            delete (processForInvestor[_investor][_poolId]);
        }

        if (_poolId != 10) {
            require(
                IERC20(poolSign.stakingToken).transfer(_investor, _amount),
                "Vesting: tokens didn`t transfer"
            );
        } else {
            (bool success, ) = payable(_investor).call{value: _amount}("");
            require(success, "Vesting: tokens didn`t transfer");
        }

        emit DecreaseForUser(_investor, _poolId, _amount);
    }

    /**
     * allows user increase their stake
     * @param _poolId number of pool
     * @param _amount amount of tokens which should be added to pool
     */
    function increaseStake(uint8 _poolId, uint256 _amount)
        external
        payable
        nonReentrant
    {
        address _investor = _msgSender();
        UserInfo storage userSign = processForInvestor[_investor][_poolId];
        PoolInfo storage poolSign = pools[_poolId];

        if (_poolId == 10) {
            _amount = msg.value;
        } else {
            require(msg.value == 0, "Staking: you shouldn`t use ETH");
        }

        require(0 < userSign.amount, "Staking: stake don`t exist");
        require(0 < _amount, "Staking: you can`t increase such sum");

        uint256 amountFee = (_amount * pools[_poolId].fee) / 100;
        _amount -= amountFee;

        if (poolSign.timeLockUp > 0) {
            userSign.index = userSign.index + 1;
            userSign.timeLocked[userSign.index] = block.timestamp;
            userSign.sumLocked[userSign.index] = _amount;
        }

        userSign.amount += _amount;
        poolSign.amountStaked += _amount;
        userSign.rewardGot =
            userSign.rewardGot +
            calculateReward(_poolId, _amount, userSign.start);
        transferStakeAndFee(_poolId, _investor, _amount, amountFee);

        emit IncreaseStakeForUser(_investor, _amount, _poolId);
    }

    /**
     * calculate amount of reward for user at process numbered #_index
     * @param _poolId pool id
     * @param _apy new apy for pool
     */
    function setAPYForPool(uint8 _poolId, uint16 _apy) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Staking: have no rights"
        );
        pools[_poolId].APY = _apy;
    }

    /**
     * calculate amount of reward for user at process numbered #_index
     * @param _poolId pool id
     * @return rewardAmount reward amount
     */
    function calculateReward(
        uint8 _poolId,
        uint256 _amount,
        uint256 _start
    ) internal view returns (uint256 rewardAmount) {
        rewardAmount =
            (_amount * pools[_poolId].APY * (block.timestamp - _start)) / (100*365);
            //(100 * 60 * 60 * 24 * 365);
        if (
            _poolId == 2 ||
            _poolId == 3 ||
            _poolId == 4 ||
            _poolId == 11 ||
            _poolId == 10 ||
            _poolId == 9
        ) rewardAmount = rewardAmount / 10000000000;
    }

    function _withdrawReward(uint8 _poolId, address _investor) internal {
        UserInfo storage userSign = processForInvestor[_investor][_poolId];
        require(userSign.amount > 0, "Staking: user has no staked tokens");
        uint256 amount = calculateReward(
            _poolId,
            userSign.amount,
            userSign.start
        );
        amount -= userSign.rewardGot;
        userSign.rewardGot += amount;

        require(
            IERC20(pools[_poolId].rewardsToken).transferFrom(
                pools[_poolId].rewardKeeper,
                _investor,
                amount
            ),
            "Staking: tokens didn`t transfer"
        );

        emit GetRewardForUser(_investor, _poolId, amount, block.timestamp);
    }

    function unlock(
        uint8 _poolId,
        address _investor,
        uint256 i
    ) internal returns (uint256 index) {
        UserInfo storage userSign = processForInvestor[_investor][_poolId];
        PoolInfo storage poolSign = pools[_poolId];
        if ((block.timestamp - userSign.timeLocked[i]) >= poolSign.timeLockUp) {
            userSign.unlocked = userSign.unlocked + userSign.sumLocked[i];
            userSign.timeLocked[i] = userSign.timeLocked[userSign.index];
            userSign.sumLocked[i] = userSign.sumLocked[userSign.index];
            userSign.timeLocked[userSign.index] = 0;
            userSign.sumLocked[userSign.index] = 0;
            if (userSign.index >= 1) {
                userSign.index = userSign.index - 1;
                index = i;
            } else {
                index = i + 1;
            }
        } else {
            index = i + 1;
        }
    }

    function transferStakeAndFee(
        uint8 _poolId,
        address _investor,
        uint256 _stake,
        uint256 _amountFee
    ) internal {
        PoolInfo storage poolSign = pools[_poolId];

        if (_poolId != 10) {
            require(
                IERC20(poolSign.stakingToken).transferFrom(
                    _investor,
                    address(this),
                    _stake
                ),
                "Vesting: tokens didn`t transfer"
            );

            if (poolSign.feeKeeper != address(0) && _amountFee > 0) {
                require(
                    IERC20(poolSign.stakingToken).transferFrom(
                        _investor,
                        poolSign.feeKeeper,
                        _amountFee
                    ),
                    "Vesting: fee didn`t transfer"
                );
            }
        } else {
            bool success;

            if (poolSign.feeKeeper != address(0) && _amountFee > 0) {
                (success, ) = payable(poolSign.feeKeeper).call{
                    value: _amountFee
                }("");
                require(success, "Vesting: fee didn`t transfer");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}