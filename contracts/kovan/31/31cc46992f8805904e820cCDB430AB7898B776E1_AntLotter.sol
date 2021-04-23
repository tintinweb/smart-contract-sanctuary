/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity >=0.7.0 <0.9.0;

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

contract Ownable {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract AntLotter is Ownable {
    uint256 private prize;
    address private winner;
    
    address private ANTTOKEN_ADDRESS = 0xaFF4481D10270F50f203E0763e2597776068CBc5;
    IERC20  private ANTTOKEN = IERC20(ANTTOKEN_ADDRESS);
    uint256 private constant NEW_PRIZE = 3;
    address private DONATE_WALLET = 0x494Ecd798ab1c2224b1508201834422E585d2BE4;
    
    event Draw(address indexed newWinner, uint256 indexed newPrize);
    event Claim(address indexed winner, uint256 indexed prize);
    event Donate(address indexed winner, uint256 indexed prize);
    
    modifier isWinner() {
        require(msg.sender == winner, "Caller is not winner");
        _;
    }
    
    function getPrize() external isWinner view returns (uint256) {
        return prize;
    }
    function getWinner() external view returns (address) {
        return winner;
    }
    function newDraw(address newWinner) external isOwner {
        winner = newWinner;
        prize = prize + NEW_PRIZE;
        emit Draw(winner, prize);
    }
    function claimPrize() external isWinner {
        require(prize > 0, "Prize is already claimed to the winner");
        require(ANTTOKEN.balanceOf(address(this)) >= prize, "Not enough balance in the prize wallet");
        ANTTOKEN.transfer(winner, prize);
        Claim(winner, prize);
        prize = 0;
    }
    function donatePrize() external isWinner {
        require(prize > 0, "Prize is already donated to the charity");
        require(ANTTOKEN.balanceOf(address(this)) >= prize, "Not enough balance in the prize wallet");
        ANTTOKEN.transfer(DONATE_WALLET, prize);
        Donate(winner, prize);
        prize = 0;
    }
}