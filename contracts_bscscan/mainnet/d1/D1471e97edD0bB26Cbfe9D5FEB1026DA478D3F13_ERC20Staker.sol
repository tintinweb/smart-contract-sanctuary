// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Staker.sol";
import "./interfaces/INabeEmitter.sol";
import "./interfaces/INabe.sol";
import "./NabeDividend.sol";

contract ERC20Staker is NabeDividend, IERC20Staker {
    
    IERC20 public token;

    constructor(
        INabeEmitter nabeEmitter,
        uint256 pid,
        IERC20 _token
    ) NabeDividend(nabeEmitter, pid) {
        token = _token;
    }

    function stake(uint256 amount) external {
        _addShare(amount);
        token.transferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        _subShare(amount);
        token.transfer(msg.sender, amount);
        emit Unstake(msg.sender, amount);
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
pragma solidity ^0.8.9;

import "./INabeDividend.sol";

interface IERC20Staker is INabeDividend {
    
    event Stake(address indexed owner, uint256 amount);
    event Unstake(address indexed owner, uint256 amount);

    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INabe.sol";

interface INabeEmitter {

    event Add(address to, uint256 allocPoint);
    event Set(uint256 indexed pid, uint256 allocPoint);

    function nabe() external view returns (INabe);
    function emitPerBlock() external view returns (uint256);
    function startBlock() external view returns (uint256);

    function poolCount() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (
        address to,
        uint256 allocPoint,
        uint256 lastEmitBlock
    );
    function totalAllocPoint() external view returns (uint256);

    function pendingToken(uint256 pid) external view returns (uint256);
    function updatePool(uint256 pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFungibleToken.sol";

interface INabe is IFungibleToken {
    function mint(address to, uint256 amount) external;
    function burn(uint256 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/INabeDividend.sol";
import "./interfaces/INabeEmitter.sol";
import "./interfaces/INabe.sol";

abstract contract NabeDividend is INabeDividend {

    INabeEmitter public immutable nabeEmitter;
    INabe public immutable nabe;
    uint256 public override immutable pid;

    constructor(
        INabeEmitter _nabeEmitter,
        uint256 _pid
    ) {
        nabeEmitter = _nabeEmitter;
        nabe = _nabeEmitter.nabe();
        pid = _pid;
    }

    uint256 internal currentBalance = 0;
    uint256 internal totalShares = 0;
    mapping(address => uint256) public shares;

    uint256 constant internal pointsMultiplier = 2**128;
    uint256 internal pointsPerShare = 0;
    mapping (address => int256) internal pointsCorrection;
    mapping (address => uint256) internal claimed;

    function updateBalance() internal {
        if (totalShares > 0) {
            nabeEmitter.updatePool(pid);
            uint256 balance = nabe.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                pointsPerShare += value * pointsMultiplier / totalShares;
                emit Distribute(msg.sender, value);
            }
            currentBalance = balance;
        }
    }

    function claimedOf(address owner) override public view returns (uint256) {
        return claimed[owner];
    }

    function accumulativeOf(address owner) override public view returns (uint256) {
        uint256 _pointsPerShare = pointsPerShare;
        if (totalShares > 0) {
            uint256 balance = nabeEmitter.pendingToken(pid) + nabe.balanceOf(address(this));
            uint256 value = balance - currentBalance;
            if (value > 0) {
                _pointsPerShare += value * pointsMultiplier / totalShares;
            }
            return uint256(int256(_pointsPerShare * shares[owner]) + pointsCorrection[owner]) / pointsMultiplier;
        }
        return 0;
    }

    function claimableOf(address owner) override external view returns (uint256) {
        return accumulativeOf(owner) - claimed[owner];
    }

    function _accumulativeOf(address owner) internal view returns (uint256) {
        return uint256(int256(pointsPerShare * shares[owner]) + pointsCorrection[owner]) / pointsMultiplier;
    }

    function _claimableOf(address owner) internal view returns (uint256) {
        return _accumulativeOf(owner) - claimed[owner];
    }

    function claim() override external returns (uint256 claimable) {
        updateBalance();
        claimable = _claimableOf(msg.sender);
        if (claimable > 0) {
            claimed[msg.sender] += claimable;
            emit Claim(msg.sender, claimable);
            nabe.transfer(msg.sender, claimable);
            currentBalance -= claimable;
        }
    }

    function _addShare(uint256 amount) internal {
        updateBalance();
        totalShares += amount;
        shares[msg.sender] += amount;
        pointsCorrection[msg.sender] -= int256(pointsPerShare * amount);
    }

    function _subShare(uint256 amount) internal {
        updateBalance();
        totalShares -= amount;
        shares[msg.sender] -= amount;
        pointsCorrection[msg.sender] += int256(pointsPerShare * amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INabeDividend {

    event Distribute(address indexed by, uint256 distributed);
    event Claim(address indexed to, uint256 claimed);

    function pid() external view returns (uint256);
    function shares(address owner) external view returns (uint256);

    function accumulativeOf(address owner) external view returns (uint256);
    function claimedOf(address owner) external view returns (uint256);
    function claimableOf(address owner) external view returns (uint256);
    function claim() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFungibleToken is IERC20 {
    
    function version() external view returns (string memory);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

