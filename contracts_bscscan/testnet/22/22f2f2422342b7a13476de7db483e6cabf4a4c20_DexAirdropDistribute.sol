/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

contract DexAirdropDistribute {
    mapping(address => uint) private distributeMap;
    mapping(address => bool) private checkExistMap;
    address[] private keys;
    address private selfOwner;

    event DidExecuteDistribute(address owner, uint amount);

    constructor() {
        selfOwner = msg.sender;
    }

    // struct AirdropInfo {
    //     address receiver 
    // }

    modifier onlyOwner() {
        require(selfOwner == msg.sender, "msg sender is not owner");
        _;
    }

    function updateSingleDistribute(address receiver, uint amount) public onlyOwner {
        require(amount > 0, "amount can not less than or equal to zero");
        require(receiver != address(0), "receiver address can not be empty");
        distributeMap[receiver] += amount;
        if (!checkExistMap[receiver]) {
            checkExistMap[receiver] = true;
            keys.push(receiver);
        }
    }

    // function checkReceiverIsExist(address key) external returns(bool){
    //     return checkExistMap[key];
    // }

    // function updateMultiDistribute(mapping(address => uint) memory groupMap) {
    //     distributeMap = groupMap;
    // }

    // reset single receiver's amount
    function resetSingleReceiverDistribute(address receiver, uint amount) public onlyOwner {
        require(receiver != address(0), "receiver address can not be empty");
        if (checkExistMap[receiver]) {
            distributeMap[receiver] = amount;
        } else {

        }
    }

    /**
     * @dev Execute distribute 
     */
    function executeDistribute(address token, uint amount) public onlyOwner {
        require(token != address(0), "token address can not be empty");
        require(distributeMap[selfOwner] >= amount, "balance is not enough");
        IERC20(token).transfer(selfOwner, amount);
        emit DidExecuteDistribute(selfOwner, amount);
    }

    /**
     * @dev Check Balances
     */
    function searchBalance(address receiver) view public returns(uint) {
        require(receiver != address(0), "token address can not be empty");
        return distributeMap[receiver];
    }

    /**
     * @dev Withdraw the remaining amount.
     */
    function withdrawLeftAmount(address token, address wallet) public onlyOwner {
        // require(wallet != address(0), "wallet address can not be empty");
        uint totalLeftAmount = 0;
        for(uint i = 0; i < keys.length; i++) {
            totalLeftAmount += distributeMap[keys[i]];
        }
        
        IERC20(token).transfer(wallet, IERC20(token).balanceOf(address(this)));
    }
    // 合约当前余额
    function getBalanceOfContract(address token) public view returns(uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getBalance(address payable _add) public view returns(uint) {
        return _add.balance;
    }

    function thisBalance() public view returns(uint) {
        return address(this).balance;
    }
}