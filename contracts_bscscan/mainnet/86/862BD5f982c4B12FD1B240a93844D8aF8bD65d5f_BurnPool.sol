// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/INabeEmitter.sol";
import "./interfaces/INabe.sol";
import "./interfaces/IBurnPool.sol";

contract BurnPool is IBurnPool {

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

    function burn() override external {
        nabeEmitter.updatePool(pid);
        nabe.burn(nabe.balanceOf(address(this)));
    }
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

interface IBurnPool {
    function pid() external view returns (uint256);
    function burn() external;
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

