// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./test/TestTokens_BEP.sol"; 

contract Staking is AccessControl, ReentrancyGuard {
    PoolInfo[12] public pools;
    address lp_2;
    address lp_3;
    address lp_4;
    address lpKeeper;

    mapping(address => mapping(uint8 => UserInfo)) public processForInvestor; // UserInfo for address and index

    struct UserInfo {
        uint256 amount; // amount of staked tokens
        uint256 rewardGot; // reward user already got
        uint256 start; // time when user made stake
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
        uint16[12] memory _APY,
        address _lp_2,
        address _lp_3,
        address _lp_4,
        address lp_keeper
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
        pools[2].stakingToken = _lp_2;
        lp_2 = _lp_2;
        pools[3].stakingToken = _lp_3;
        lp_3 = _lp_3;
        lp_4 = _lp_4;
        pools[4].stakingToken = _lp_4;
        lpKeeper = lp_keeper;
    }

    receive() external payable {}

    function getPoolInfo(uint8 _poolId)
        external
        view
        returns (
            address rewardsToken_,
            address stakingToken_,
            address feeKeeper_,
            address rewardKeeper_,
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
        rewardKeeper_ = poolSign.rewardKeeper;
        amountStaked_ = poolSign.amountStaked;
        timeLockUp_ = poolSign.timeLockUp;
        fee_ = poolSign.fee;
        APY_ = poolSign.APY;
        stakeholders_ = poolSign.stakeholders;
    }

    function getProcessInfoForUser(address _investor, uint8 _poolId)
        external
        view
        returns (UserInfo memory)
    {
        return processForInvestor[_investor][_poolId];
    }

    function getLpTokensAndStake(address _investor, uint256 _amount1, uint256 _amount2, uint8 _poolId) external {
        address token1;
        address token2;
        if(_poolId == 2){
            token1 = pools[0].stakingToken;
            token2 = pools[1].stakingToken;
        } else if ( _poolId == 3) {
            token1 = pools[0].stakingToken;
            token2 = pools[0].rewardsToken;
        } else if ( _poolId == 4) {
            token1 = pools[1].stakingToken;
            token2 = pools[0].rewardsToken;
        }

        require(
            IERC20(token1).transferFrom(_investor, 
                                        address(this), 
                                        _amount1),
                "Vesting: tokens1 didn`t transfer"
        );
        require(
            IERC20(token2).transferFrom(_investor, 
                                        address(this), 
                                        _amount2),
                "Vesting: tokens2 didn`t transfer"
        );

        PoolInfo storage poolSign = pools[_poolId];

        poolSign.stakeholders.push(_investor);
        poolSign.index[_investor] = poolSign.stakeholders.length - 1;

        processForInvestor[_investor][_poolId] = UserInfo(
            2,
            0,
            block.timestamp
        );

        poolSign.amountStaked += 2;

        TestToken_BEP(pools[_poolId].stakingToken)._mint(address(this), 2);
        
        emit StakeTokenForUser(_investor, 2, _poolId, block.timestamp);
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
        require( _poolId != 2 && _poolId != 3 && _poolId != 4, "");
        address investor = _msgSender();

        if (_poolId == 10) {
            require(_stake == msg.value, "Staking: amount of ETH != _stake");
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
        processForInvestor[investor][_poolId] = UserInfo(
            _stake,
            0,
            block.timestamp
        );

        poolSign.amountStaked += _stake;
        transferStakeAndFee(_poolId, investor, _stake, amountFee);
        emit StakeTokenForUser(investor, _stake, _poolId, block.timestamp);
    }

    /**
     * allows user get his reward for process numbered #index
     * @param _poolId number of process
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
        UserInfo memory userSign = processForInvestor[_investor][_poolId];
        PoolInfo storage poolSign = pools[_poolId];

        require(
            _amount <= userSign.amount,
            "Staking: user has not enough tokens"
        );
        require(
            block.timestamp - userSign.start > poolSign.timeLockUp,
            "Staking: now is period of lock up"
        );

        _withdrawReward(_poolId, _investor);

        processForInvestor[_investor][_poolId].amount =
            userSign.amount -
            _amount;
        poolSign.amountStaked -= _amount;
        processForInvestor[_investor][_poolId].rewardGot = calculateReward(
            _poolId,
            poolSign.amountStaked,
            userSign.start
        );

        if ( (userSign.amount - _amount) == 0) {
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

  
    function increaseStake(uint8 _poolId, uint256 _amount1, uint256 _amount2)
        external
        payable
        nonReentrant
    {
        address _investor = _msgSender();
        UserInfo memory userSign = processForInvestor[_investor][_poolId];
        PoolInfo storage poolSign = pools[_poolId];

        if( _poolId != 2 && _poolId != 3 && _poolId != 4) {
            if (_poolId == 10) {
                require(_amount1 == msg.value, "Staking: amount of ETH != _stake");
            } else {
                require(msg.value == 0, "Staking: you shouldn`t use ETH");
            }

            require(0 < userSign.amount, "Staking: stake don`t exist");
            require(0 < _amount1, "Staking: you can`t increase such sum");

            uint256 amountFee = (_amount1 * pools[_poolId].fee) / 100;
            _amount1 -= amountFee;

            processForInvestor[_investor][_poolId].amount =
                userSign.amount +
                _amount1;
            poolSign.amountStaked += _amount1;
            processForInvestor[_investor][_poolId].rewardGot =
                userSign.rewardGot +
                calculateReward(_poolId, _amount1, userSign.start);

            transferStakeAndFee(_poolId, _investor, _amount1, amountFee);
            emit IncreaseStakeForUser(_investor, _amount1, _poolId);
        } else {
            address token1;
            address token2;
            if(_poolId == 2){
                token1 = pools[0].stakingToken;
                token2 = pools[1].stakingToken;
            } else if (_poolId == 3) {
                token1 = pools[0].stakingToken;
                token2 = pools[0].rewardsToken;
            } else if ( _poolId == 4) {
                token1 = pools[1].stakingToken;
                token2 = pools[0].rewardsToken;
            }

            require(
                IERC20(token1).transferFrom(_investor, 
                                            address(this), 
                                            _amount1),
                    "Vesting: tokens1 didn`t transfer"
            );
            require(
                IERC20(token2).transferFrom(_investor, 
                                            address(this), 
                                            _amount2),
                    "Vesting: tokens2 didn`t transfer"
            );

            processForInvestor[_investor][_poolId].amount =
                userSign.amount +
                2;

            processForInvestor[_investor][_poolId].rewardGot =
                userSign.rewardGot +
                calculateReward(_poolId, 2, userSign.start);

            TestToken_BEP(pools[_poolId].stakingToken)._mint(address(this), 2);

            emit IncreaseStakeForUser(_investor, 2, _poolId);
        
        } 
        
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
    ) public view returns (uint256 rewardAmount) {
        rewardAmount =
            (_amount * pools[_poolId].APY * (block.timestamp - _start)) / (100*365);
            //(100 * 60 * 60 * 24 * 365);
    }

    function _withdrawReward(uint8 _poolId, address _investor) internal {
        UserInfo memory userSign = processForInvestor[_investor][_poolId];
        require(userSign.amount > 0, "Staking: user has no staked tokens");
        uint256 amount = calculateReward(
            _poolId,
            userSign.amount,
            userSign.start
        );
        amount -= userSign.rewardGot;
        processForInvestor[_investor][_poolId].rewardGot += amount;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

abstract contract BEP20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address who) public virtual view returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract BEP20 is BEP20Basic {
  function allowance(address owner, address spender)
    public virtual view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public virtual returns (bool);

  function approve(address spender, uint256 value) virtual public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is BEP20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public override view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public override returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public override view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is BEP20, BasicToken {
    using SafeMath for uint256;
   mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    virtual
    override 
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    override 
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract MainToken is StandardToken, Ownable  
{
    using SafeMath for uint256;
    uint public constant TOKEN_DECIMALS = 8;
    uint8 public constant TOKEN_DECIMALS_UINT8 = 8;
    uint public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    string public TOKEN_NAME;
    string public TOKEN_SYMBOL;
  
    constructor(string memory _name, string memory _symbol) {
        TOKEN_NAME = _name;
        TOKEN_SYMBOL = _symbol;
    }

    function _mint(
        address _to,
        uint256 _amount
    )
        public
        returns (bool)
    {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        return true;
    }

    function name() public view returns (string memory _name) {
        return TOKEN_NAME;
    }

    function symbol() public view returns (string memory _symbol) {
        return TOKEN_SYMBOL;
    }

    function decimals() public pure returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool _success) {
        return super.transferFrom(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public override returns (bool _success) {
        return super.transfer(_to, _value);
    }

    
}

contract TestToken_BEP is MainToken {

    constructor(string memory name, string memory symbol) payable MainToken(name, symbol) 
    {
        uint256 initialSupply = 100 ** 2 * 10 ** uint256(decimals());
        _mint(msg.sender, initialSupply);
    }

    
}

