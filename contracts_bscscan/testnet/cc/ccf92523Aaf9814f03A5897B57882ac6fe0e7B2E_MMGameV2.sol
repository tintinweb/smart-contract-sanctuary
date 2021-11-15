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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MMGameV2 {
    address admin;
    uint256 rand;
    uint256 nonce;
    uint256 max;
    
    function store(uint256 _max) public {
        admin = msg.sender;
        nonce = 0;
        max = _max;
    }
    
    function feedRandomness(uint _rand) external {
        require(msg.sender == admin, "Oracle: Insufficient permission.");
        rand = _rand;
    }
    
    function withdrawToken(IERC20 _token) public {
        require(_token.transfer(msg.sender, _token.balanceOf(address(this))), "Transfer failed");
    }
    
    function withdrawErc20(IERC20 token, uint256 _amount) public {
        require(token.transfer(msg.sender, _amount), "Transfer failed");
    }

    function getRandom() external returns(uint256){
        return _randModulos(max);
    }
    
    function updateMax(uint256 _max) external {
        max = _max;
    }
    
    function _randModulos(uint _mod) internal returns(uint256) {
        uint256 random = uint(keccak256(abi.encodePacked(
            nonce,
            rand,
            block.timestamp, 
            block.difficulty, 
            msg.sender
        ))) % _mod;
        nonce++;
        return random;
    }
    
    // Fomo3D logic
    function fullRand() public view returns(uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        return (seed - ((seed / max) * max));
    }
    
    function mine(IERC20 _token) external {
        _token.transfer(msg.sender, fullRand() * 10 ** 18);
    }
    
}

