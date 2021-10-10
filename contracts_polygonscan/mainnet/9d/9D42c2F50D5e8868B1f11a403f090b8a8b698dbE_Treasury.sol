/**
 *Submitted for verification at polygonscan.com on 2021-10-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/Treasury.sol


pragma solidity 0.6.12;



/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
    address payable public owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access to contract");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}
/*
    @brief: This contract 
*/

contract Treasury is Ownable {

    event TokenDepositEvent(
        address indexed depositorAddress,
        address indexed tokenContractAddress,
        uint256 amount
    );
    event EtherDepositEvent(address indexed depositorAddress, uint256 amount);

    enum DeositType {ETHER, TOKEN}

    receive() external payable {
        require(msg.value != 0, "Cannot deposit nothing into the treasury");
        emit EtherDepositEvent(msg.sender, msg.value);
    }

    function depositToken(address token) public payable {
        require(token != address(0x0), "token contract address cannot be null");

        require(
            address(token) != address(0),
            "tken contract address cannot be 0"
        );

        IERC20 tokenContract = IERC20(token);
        uint256 amountToDeposit = tokenContract.allowance(
            msg.sender,
            address(this)
        );

        require(
            amountToDeposit != 0,
            "Cannot deposit nothing into the treasury"
        );

        bool isSuccessful = tokenContract.transferFrom(
            msg.sender,
            address(this),
            amountToDeposit
        );
        require(isSuccessful == true, "Failed token deposit attempt");
        emit TokenDepositEvent(msg.sender, token, amountToDeposit);
    }

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) public view returns (uint256) {
        require(token != address(0x0), "token contract address cannot be null");

        require(
            address(token) != address(0),
            "tken contract address cannot be 0"
        );

        IERC20 tokenContract = IERC20(token);
        return tokenContract.balanceOf(address(this));
    }

    function withdrawEthers(uint256 amount) external {
        uint256 etherBalance = address(this).balance;
        require(etherBalance >= amount, "Insufficient ether balance");
        owner.transfer(amount);
    }

    function withdrawTokens(address tokenAddress, uint256 amount) external {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        require(tokenBalance >= amount, "Insufficient token balance");
        bool isSuccessful = tokenContract.transfer(owner, amount);
        require(isSuccessful == true, "Failed token withdrawal");
    }
}