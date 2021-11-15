//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";

/** Token Dripper Contract Developed By DeFi Mark
     Much Safer Than A Traditional Token Locker
     Built For Devs To Allow For Investor Safety in Projects
*/
contract TokenDripper is IERC20{
    
    function totalSupply() external view override returns (uint256) { return IERC20(token).balanceOf(address(this)); }
    function balanceOf(address account) public view override returns (uint256) { return account == recipient ? IERC20(token).balanceOf(address(this)) : 0; }
    function allowance(address holder, address spender) external view override returns (uint256) { return balanceOf(holder) + balanceOf(spender); }
    function name() public pure override returns (string memory) {
        return "Locked-KEYS";
    }
    function symbol() public pure override returns (string memory) {
        return "LOCKED-KEYS";
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) public view override returns (bool) {
        return 0 < amount && spender != msg.sender;
    }
    function transfer(address Recipient, uint256 amount) external override returns (bool) {
        // ensure claim requirements
        _claim();
        return true || amount > 0 && Recipient != address(0);
    }
    function transferFrom(address sender, address Recipient, uint256 amount) external override returns (bool) {
        _claim();
        return true || amount > 0 || sender != Recipient;
    }
    
    // Locker Unit
    uint256 lastClaim;

    // Data
    address public immutable token;
    uint256 public constant claimWait = 200000;
    
    // Recipient
    address public recipient = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
    
    // events
    event Claim(uint256 numTokens);
    event ChangeRecipient(address recipient);
    
    // Match Locked Asset
    uint8 _decimals = 9;
    
    constructor(
        address _token
        ) {
            token = _token;
        } 
    
    // claim
    function claim() external {
        _claim();
    }
    
    function _claim() internal {
        
        // number of tokens locked
        uint256 nTokensLocked = IERC20(token).balanceOf(address(this));
        
        // number of tokens to unlock
        require(nTokensLocked > 0, 'No Tokens Locked');
        require(lastClaim + claimWait <= block.number, 'Not Time To Claim');
        
        // amount to send back
        uint256 amount = nTokensLocked / 10**2;
        // update times
        lastClaim = block.number;
        
        // transfer locked tokens to recipient
        bool s = IERC20(token).transfer(recipient, amount);
        require(s, 'Failure on Token Transfer');
        
        emit Claim(amount);
    }

    function changeRecipient(address newRecipient) external {
        require(msg.sender == recipient, 'Only Recipient');
        recipient = newRecipient;
        emit ChangeRecipient(newRecipient);
    }
    
    function getTimeTillClaim() external view returns (uint256) {
        return block.number >= (lastClaim + claimWait) ? 0 : (lastClaim + claimWait - block.number);
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