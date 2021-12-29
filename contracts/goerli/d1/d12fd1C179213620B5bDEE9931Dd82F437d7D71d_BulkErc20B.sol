// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We'll actually use ERC777, but any IERC20 instance (including ERC777)
// is supported.
import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';



contract BulkErc20B {


    address admin;

    constructor(){
        admin = msg.sender;
    }

    function release_bulk() external {
        require( (msg.sender == admin), 'Only admins allowed');
    
        IERC20  tokenContract = IERC20(0xdE5EeF552aFf10290C88040Aa2fa818570Ff3332);

        tokenContract.transfer(0x25A68Da8d0D3D03fF34Ff6b13B56FE46d67e4257,5000000000000000);
        tokenContract.transfer(0x84Ffaf0AcFF355b7832562E640bb61F140D2CD6B,5000000000000000);
        tokenContract.transfer(0x834663A7A8caC7f9757f586c8ca23acE6322D0cb,5000000000000000);
        tokenContract.transfer(0x4B6da55A24b8B6c37908Fcce7d3023CC9b08De50,5000000000000000);
        tokenContract.transfer(0x4bB4c2aA5668Aa29f8C5B7DA219d5EcB9233E507,5000000000000000);


        selfdestruct( payable(msg.sender));

    }


}


// 0x25A68Da8d0D3D03fF34Ff6b13B56FE46d67e4257 
// 0x84Ffaf0AcFF355b7832562E640bb61F140D2CD6B
// 0x834663A7A8caC7f9757f586c8ca23acE6322D0cb
// 0x4B6da55A24b8B6c37908Fcce7d3023CC9b08De50
// 0x4bB4c2aA5668Aa29f8C5B7DA219d5EcB9233E507

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