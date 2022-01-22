/**
 *Submitted for verification at BscScan.com on 2022-01-22
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

contract DexAirdrop {

    struct DistributeInfo {
        address receiver;
        uint airdropAmount;
        uint airdropTotalAmount;
        bool isExits;
    }

    mapping(address => DistributeInfo) private airdropMap;
    address private selfOwner;

    event DidExecuteChainAirdrop(address owner, uint amount);

    constructor() {
        selfOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(selfOwner == msg.sender, "msg sender is not owner");
        _;
    }

    function singleAirdrop(address receiver, uint amount) public onlyOwner {
        require(amount > 0, "amount can not less than or equal to zero");
        require(receiver != address(0), "receiver address can not be empty");

        if (airdropMap[receiver].isExits) {
            airdropMap[receiver].airdropAmount += amount;
            airdropMap[receiver].airdropTotalAmount += amount;
        } else {
            airdropMap[receiver] = DistributeInfo(receiver, amount, amount, true);
        }
    }
    /**
     * @dev Execute distribute 
     */
    function executeChainAirdrop(address token) public {
        require(token != address(0), "token address can not be empty");
        address ownerAddress = msg.sender;
        uint amount = airdropMap[ownerAddress].airdropAmount;
        require(IERC20(token).balanceOf(address(this)) >= amount, "contract balance is not enough");
        // IERC20(token).transferFrom(address(this), msg.sender, amount);
        IERC20(token).transfer(ownerAddress, amount);
        airdropMap[ownerAddress].airdropAmount = 0;
        emit DidExecuteChainAirdrop(ownerAddress, amount);
    }

    /**
     * @dev Check Airdrop Balances
     */
    function searchBalanceOfAirdrop(address receiver) view public returns(uint) {
        require(receiver != address(0), "token address can not be empty");
        return airdropMap[receiver].airdropAmount;
    }

    /**
     * @dev Check Airdrop Balances
     */
    function searchAirdropTotalAmount(address receiver) view public returns(uint) {
        require(receiver != address(0), "token address can not be empty");
        return airdropMap[receiver].airdropTotalAmount;
    }

    // get balance of contract
    function searchBalanceOfContract(address token) public view returns(uint) {
        return IERC20(token).balanceOf(address(this));
    }
    /**
     * @dev transfer 'amount' from wallet to contract.
     */
    function contractDeposit(address token, address wallet, uint amount) public onlyOwner {
        require(wallet != address(0), "wallet address can not be empty");
        require(amount > 0, "amount can not less than or equal to zero");
        IERC20(token).transferFrom(wallet, address(this), amount);
    }

    /**
     * @dev Withdraw the balance of contract.
     */
    function contractWithdraw(address token, address wallet) public onlyOwner {
        require(wallet != address(0), "wallet address can not be empty");
        require((IERC20(token).balanceOf(address(this))) > 0, "contract balance is empty");
        IERC20(token).transfer(wallet, IERC20(token).balanceOf(address(this)));
    }
}