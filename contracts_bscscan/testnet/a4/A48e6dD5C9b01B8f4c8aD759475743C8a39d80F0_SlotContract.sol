/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


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

interface ERC20 is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract Ownable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
}

contract SlotContract is Ownable {

    address public token = address(0x7D3DB1eAF60123A471D9337e9Ee8017B89F0D4fA);

    struct Bet {
        uint256 amount;
        uint IsWin;
    }

    mapping(address => Bet) private betRooms;

    function balanceOf(address player) public view returns (uint256) {
        return ERC20(token).balanceOf(player);
    }

    function deposit(uint256 amount) public {
        require(ERC20(token).balanceOf(msg.sender) >= amount, "Your balance is not enough.");
        ERC20(token).transferFrom(msg.sender, address(this), amount);

        Bet memory betItem = Bet(amount, 0);
        betRooms[msg.sender] = betItem;
    }

    function setWin(address player, uint state) public{
        betRooms[player].IsWin = state;
    }

    function rewardToBetWinner(address player) public{
        if (betRooms[player].IsWin == 1){
            ERC20(token).approve(address(this), betRooms[player].amount * 2);
            ERC20(token).transferFrom(address(this), player, betRooms[player].amount * 2);
        } else if (betRooms[player].IsWin == 3){
            ERC20(token).approve(address(this), betRooms[player].amount * 3);
            ERC20(token).transferFrom(address(this), player, betRooms[player].amount * 3);
        }

        delete betRooms[player];
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(ERC20(token).balanceOf(address(this)) >= amount, "Contract balance is not enough.");
        ERC20(token).approve(address(this), amount);
        ERC20(token).transferFrom(address(this), owner(), amount);
    }
}