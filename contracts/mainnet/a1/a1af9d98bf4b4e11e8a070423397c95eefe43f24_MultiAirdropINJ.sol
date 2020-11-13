// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
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
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

}

contract MultiAirdropINJ {
    IERC20 public inj;
    address public  owner;
    mapping(address => uint256) public claimableAmounts;

    constructor () public {
        owner = msg.sender;
        inj = IERC20(0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30);
    }

    function safeAddAmountsToAirdrop(
        address[] memory to,
        uint256[] memory amounts
    )
    public
    {
        require(msg.sender == owner, "Only Owner");
        require(to.length == amounts.length);
        uint256 totalAmount;
        for(uint256 i = 0; i < to.length; i++) {
            claimableAmounts[to[i]] = amounts[i];
            totalAmount += amounts[i];
        }
        require(inj.allowance(msg.sender, address(this)) >= totalAmount, "not enough allowance");
        inj.transferFrom(msg.sender, address(this), totalAmount);
    }

    function returnINJ() external {
        require(msg.sender == owner, "Only Owner");
        require(inj.transfer(msg.sender, inj.balanceOf(address(this))), "Transfer failed");
    }
    
    function returnAnyToken(IERC20 token) external {
        require(msg.sender == owner, "Only Owner");
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer failed");
    }

    function claim() external {
        require(claimableAmounts[msg.sender] > 0, "Cannot claim 0 tokens");
        uint256 amount = claimableAmounts[msg.sender];
        claimableAmounts[msg.sender] = 0;
        require(inj.transfer(msg.sender, amount), "Transfer failed");
    }

    function claimFor(address _for) external {
        require(claimableAmounts[_for] > 0, "Cannot claim 0 tokens");
        uint256 amount = claimableAmounts[_for];
        claimableAmounts[_for] = 0;
        require(inj.transfer(_for, amount), "Transfer failed");
    }
    
    function transferOwnerShip(address newOwner) external {
        require(msg.sender == owner, "Only Owner");
        owner = newOwner;
    }
}