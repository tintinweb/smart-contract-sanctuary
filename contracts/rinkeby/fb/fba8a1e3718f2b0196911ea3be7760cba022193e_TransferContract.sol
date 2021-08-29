/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TransferContract {
    IERC20 public CatTokenNew;
    // New cat token address on the Rinkeby network
    address public owner1;
    // Old cat token address on the Rinkeby Networth
    address public owner2;

    IERC20 public CatTokenOld;
    // Amount that will be sent from Old Cat Token to New Cat Token
    uint256 public amount1;
    // Amount that will be sent from New Cat Token to Old Cat Token (2x their current balance)
    uint256 public amount2;

    constructor(
        // Contract address of cat token New
        address _CatTokenNew,
        // contract address of cat token old
        address _CatTokenOld,
        // address that holds all of Cat Token New
        address _owner1
    ) {
        CatTokenNew = IERC20(_CatTokenNew);
        CatTokenOld = IERC20(_CatTokenOld);
        owner1 = _owner1;
    }

    function approve_swap(
        address _approvers_address,
        uint256 _amount_to_approve
    ) public {
        require(_approvers_address == msg.sender, "Not authorized to approve");
        CatTokenOld.approve(address(this), _amount_to_approve);
    }

    function swap(address _owner2, uint256 _amount1) public {
        owner2 = _owner2;
        amount1 = _amount1;
        amount2 = (amount1 * 2);

        require(msg.sender == owner1 || msg.sender == owner2, "Not authorized");

        require(
            CatTokenOld.balanceOf(owner2) >= amount1,
            "Balance not high enough for Old Cat Token Holder"
        );

        // require(
        //     CatTokenOld.allowance(owner2, address(this)) >= amount1,
        //     "Token allowance too low for Old Cat Token owner"
        // );

        require(
            CatTokenNew.balanceOf(owner1) >= amount2,
            "Balance not high enough for New Cat Token Holder"
        );

        // require(
        //     CatTokenNew.allowance(owner1, address(this)) >= amount2,
        //     "Allowance not high enough for New Cat Token Holder"
        // );

        // transfer tokens
        _safeTransferFrom(CatTokenOld, owner2, owner1, amount1);
        _safeTransferFrom(CatTokenNew, owner1, owner2, amount2);
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function owner_approve_allowance(uint256 _approvalAmount) public {
        require(
            msg.sender == owner1,
            "You're not authorized to approve an allowance for the owner"
        );
        CatTokenNew.approve(address(this), _approvalAmount);
    }
}