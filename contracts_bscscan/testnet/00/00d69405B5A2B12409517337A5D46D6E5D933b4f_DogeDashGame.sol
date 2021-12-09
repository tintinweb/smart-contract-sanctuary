// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

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

contract DogeDashGame {
    uint256 number;

    // DogeDash
    IERC20 public DogeDash;

    struct PlayerInfo {
        // Now playing
        bool isPlaying;
        // player level
        uint256 lvl;
        // timestamp when game start
        uint256 start_ts;
        // timestamp when game end
        uint256 claim_ts;
    }


    // DogeDash amount whenever play game
    // 100 DogeDash
    uint256 public deposit_amount = 100 * 10 ** 18;

    // address => playerInfo
    mapping(address => PlayerInfo) public players;

    constructor (address _dogeDash) {
        DogeDash = IERC20(_dogeDash);
    }

    // Deposit DogeToken to play game
    function deposit(uint256 amount) public {
        require(players[msg.sender].isPlaying == false, "Deposit: claim previous game reward before start new one");
        require(deposit_amount == amount, "Deposit: amount is not correct");

        PlayerInfo storage player = players[msg.sender];
        player.isPlaying = true;
        player.start_ts = block.timestamp;

        DogeDash.transferFrom(msg.sender, address(this), amount);
    }

    // withdraw reward
    function withdraw(uint256 amount) public {
        require(players[msg.sender].isPlaying, "Withdraw: not started game yet");
        require(amount <= DogeDash.balanceOf(address(this)), "Withdraw: Insufficient pool");
        PlayerInfo storage player = players[msg.sender];
        player.isPlaying = false;
        player.claim_ts = block.timestamp;

        DogeDash.transfer(msg.sender, amount);
    }

    // This function is for testing chainsafe
    function store(uint256 num) public {
        number = num;
    }

    // This function is for testing chainsafe
    function retrieve() public view returns (uint256) {
        return number;
    }
}