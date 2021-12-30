/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

//SPDX-License-Identifier: MIT
/**
 *Submitted for verification at BscScan.com on 2021-08-29
*/

pragma solidity ^0.6.4;

interface IBEP20 {
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
    function getOwner() external view returns (address);

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


/**
* @title ICBF BulkSender Smart Contract
*
* @author Ata Taheri - [email protected]  - ICBF
* @notice Is used to transfer amounts of token X to multiple addresses
*
*/
contract ICBFBulksender {


    constructor () public {

    }


    /**
    * @notice The main and only method to bulk send to various addresses
    *
    * @param owner: platform (bulk) address
    * @param value: commission to our platform
    * @param _token : Address of BEP20 token
    * @param _to : Recipient addresses
    * @param _amounts : Sent amounts
    *
    */
    function send(address payable owner,
                  uint value,
                  address _token,
                  address[] memory _to,
                  uint256[] memory _amounts) public payable{
        require(_to.length == _amounts.length, "Invalid sizes");

        //@dev We don't need to check _amounts length as if will be the same as _to
        require(_to.length < 256, "Too much recipients");

        IBEP20 _tokenContract = IBEP20(_token);

        for (uint8 i = 0; i < _to.length; i++) {
            _tokenContract.transferFrom(msg.sender, _to[i], _amounts[i]);
        }
        owner.transfer(value);
    }
}