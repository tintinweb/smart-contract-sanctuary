pragma solidity ^0.8.0;

interface ITrustK {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function owner() external view returns (address);

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
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Burn token 
     * Returns a boolean value indicating whether the operation succeeded. 
     * 
     * Through {Burn}
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Freeze token 
     * Returns a boolean value indicating whether the operation succeeded. 
     * 
     * Through {Freeze}
     */
    function freeze(uint256 amount) external returns (bool);

    /**
     * @dev Unfreeze token 
     * Returns a boolean value indicating whether the operation succeeded. 
     * 
     * Through {Unfreeze}
     */
    function unfreeze(uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when `value` tokens are burn.
     */
    event Burn(address indexed owner, uint256 value);

    /**
     * @dev Emitted when `value` tokens are freeze.
     */
    event Freeze(address indexed owner, uint256 value);

    /**
     * @dev Emitted when `value` tokens are unfreeze.
     */
    event Unfreeze(address indexed owner, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITrustK.sol";

contract TimeLockBEP20 {
    address public owner;
    ITrustK public tokenLock;
    uint256 public unlockDate;
    uint256 public createdAt;

    event WithdrewTokens(ITrustK tokenLock, address to, uint256 amount);

    constructor(address _owner, ITrustK _tokenLock, uint256 _unlockDate){
        unlockDate = _unlockDate;
        createdAt = block.timestamp;
        tokenLock = _tokenLock;
        owner = _owner;
    }

    function withdrawTokens() public {
        require(block.timestamp >= unlockDate);

        uint256 amount = tokenLock.balanceOf(address(this));

        (bool success, bytes memory data) = address(this).call(abi.encodeWithSelector(0xa9059cbb, owner, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');

        emit WithdrewTokens(tokenLock, owner, amount);
    }

    function info() public view returns(ITrustK, address, uint256, uint256, uint256) {
        return (tokenLock, owner, unlockDate, createdAt, tokenLock.balanceOf(address(this)));
    }

}

