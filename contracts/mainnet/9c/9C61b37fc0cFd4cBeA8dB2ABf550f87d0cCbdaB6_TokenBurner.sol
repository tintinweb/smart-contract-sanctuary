//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IKeys.sol";

/** Burns KEY Tokens Quarterly
*/
contract TokenBurner {
    
    // Last Burn Time
    uint256 lastBurnTime;

    // Data
    address public immutable token;
    uint256 public constant burnWaitTime = 26 * 10**5;
    uint256 public constant amount = 5 * 10**6 * 10**9;
    
    // events
    event Burned(uint256 numTokens);
    
    constructor(
        address _token
        ) {
            token = _token;
        } 
    
    // claim
    function burn() external {
        _burn();
    }
    
    function _burn() internal {
        
        // number of tokens locked
        uint256 tokensToBurn = IERC20(token).balanceOf(address(this));
        
        // number of tokens to unlock
        require(tokensToBurn > 0, 'No Tokens To Burn');
        require(lastBurnTime + burnWaitTime <= block.number, 'Not Time To Burn');
        
        // amount to burn
        uint256 amountToBurn = amount > tokensToBurn ? tokensToBurn : amount;
        // update times
        lastBurnTime = block.number;
        
        // burn tokens
        IKeys(token).burnTokensIncludingDecimals(amountToBurn);
        
        emit Burned(amount);
    }
    
    receive() external payable {
        _burn();
        (bool s,) = payable(msg.sender).call{value: msg.value}("");
        if (s) {}
    }

    function getTimeTillBurn() external view returns (uint256) {
        return block.number >= (lastBurnTime + burnWaitTime) ? 0 : (lastBurnTime + burnWaitTime - block.number);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IKeys {

function burnTokensIncludingDecimals(uint256 numTokens) external;
}