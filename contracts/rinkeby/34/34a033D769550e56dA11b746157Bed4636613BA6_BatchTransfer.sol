/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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
}


contract BatchTransfer {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function batchTransfer(
        address tokenAddress,
        address[] memory to,
        uint256[] memory amount
    ) public {
        require(msg.sender == owner, "only owner");
        IERC20 token = IERC20(tokenAddress);
        require(to.length == amount.length, "length not match");
        for (uint8 i = 0; i < to.length; i++) {
            bytes memory callData = abi.encodeWithSelector(
                token.transferFrom.selector,
                msg.sender,
                to[i],
                amount[i]
            );
            (bool success, bytes memory returndata) = address(token).call(
                callData
            );
            require(success, "SafeERC20: low-level call failed");

            if (returndata.length > 0) {
                // Return data is optional
                // solhint-disable-next-line max-line-length
                require(
                    abi.decode(returndata, (bool)),
                    "SafeERC20: ERC20 operation did not succeed"
                );
            }
        }
    }

	function batchTransferWithVaule(
        address payable[] memory to,
		uint256[] memory value
    ) public payable{
        require(msg.sender == owner, "only owner");
        require(to.length == value.length, "length not match");
        for (uint8 i = 0; i < to.length; i++) {
            to[i].transfer(value[i]);
        }
    }
}