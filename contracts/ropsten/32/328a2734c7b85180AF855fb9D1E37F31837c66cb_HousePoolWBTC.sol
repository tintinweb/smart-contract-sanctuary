/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// Sources flattened with hardhat v2.7.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]



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


// File contracts/HousePoolWBTC.sol


pragma solidity 0.8.10;


interface WBTCclaimTokenInterface {
    function burn(address account,uint tokens)  external;
    function mint(address account,uint tokens)  external;
    function balanceOf(address tokenOwner) external view  returns (uint getBalance);
}

contract HousePoolWBTC is ReentrancyGuard {
    
    IERC20 wbtcToken;
    WBTCclaimTokenInterface WBTCclaimToken;
    address owner;
    uint256 wbtcLiquidity;
    uint256  ExchangeRatio = 100 ;
    
    mapping(address => uint256) userDepositAmount;

    constructor(address _wbtcToken, address _WBTCclaimToken) {
        wbtcToken = IERC20(_wbtcToken);
        WBTCclaimToken = WBTCclaimTokenInterface(_WBTCclaimToken);
        owner = msg.sender;
    }

    function getLiquidityStatus() view external returns(uint256) {
        return wbtcLiquidity;
    }

    function getMyBalance(address _user) view external returns(uint256) {
        return userDepositAmount[_user];
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0 && _amount <= wbtcToken.balanceOf(msg.sender),"WBTCHousePool: Check the Balance");
        wbtcLiquidity += _amount;
        userDepositAmount[msg.sender] += _amount;
        wbtcToken.transferFrom(msg.sender, address(this), _amount);
        uint256 claimTokensToMint = _amount / ExchangeRatio;
        WBTCclaimToken.mint(msg.sender, claimTokensToMint);
    }

    function withdraw(uint256 _LPTokens) external nonReentrant {
        require(_LPTokens > 0,"USDCHousePool: Zero Amount");
        require(_LPTokens <= WBTCclaimToken.balanceOf(msg.sender),"WBTCHousePool: Amount exceeded");
        uint256 amountToTransfer = _LPTokens * ExchangeRatio;
        wbtcLiquidity -= amountToTransfer;
        userDepositAmount[msg.sender] -= amountToTransfer;
        wbtcToken.transfer(msg.sender,amountToTransfer);
        WBTCclaimToken.burn(msg.sender, _LPTokens);
    }
    
}