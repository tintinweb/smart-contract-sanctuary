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

// contracts/Wedding.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Wedding {

    address public lowbAddress;
    address public owner;
    uint private _randomSeed = 5201314;
    uint public balance;
    bool public isStart = true;
    uint public totalWY;

    struct Pool {
        address luckyLoser;
        uint luckyNumber;
        uint totalLoser;
        uint amount;
    }

    Pool[8] public poolOf;
    mapping (address => uint[8]) public luckyNumberOf;
    mapping (address => uint) public wyAmoutOf;

    
    event BlessNewlyweds(address indexed loser, uint indexed n, uint luckyNumber);
    event NewLuckyLoser(address indexed loser, uint indexed n, uint luckyNumber);

    constructor(address lowb_) {
        lowbAddress = lowb_;
        owner = msg.sender;
        poolOf[0].amount = 20000e18;
        poolOf[1].amount = 30000e18;
        poolOf[2].amount = 50000e18;
        poolOf[3].amount = 100000e18;
        poolOf[4].amount = 200000e18;
        poolOf[5].amount = 500000e18;
        poolOf[6].amount = 2000000e18;
        poolOf[7].amount = 10000000e18;
    }

    function getWyAmout(address player) public view returns(uint) {
        return wyAmoutOf[player];
    }
    
    function getPoolInfo(uint n) public view returns (Pool memory) {
      require(n < 8, "Index overflowed.");
      return poolOf[n];
    }

    function getPoolInfoV2(uint n) public view returns (address luckyLoser, uint luckyNumber, uint totalLoser, uint amount) {
      require(n < 8, "Index overflowed.");
      return (poolOf[n].luckyLoser, poolOf[n].luckyNumber, poolOf[n].totalLoser, poolOf[n].amount);
    }

    function setStart(bool _start) public {
        require(msg.sender == owner, "Only owner can start wedding!");
        isStart = _start;
    }
    
    function pullFunds() public {
        require(msg.sender == owner, "Only owner can pull the funds!");
        IERC20 lowb = IERC20(lowbAddress);
        lowb.transfer(msg.sender, balance);
        balance = 0;
    }

    function blessNewlyweds(uint n) public {
        require(isStart, "The weddig is not start.");
        require(n < 8, "Index overflowed.");
        IERC20 lowb = IERC20(lowbAddress);
        require(lowb.transferFrom(msg.sender, address(this), poolOf[n].amount), "Lowb transfer failed");
        _randomSeed = uint(keccak256(abi.encode(block.timestamp, msg.sender, _randomSeed)));
        uint luckyNumber = _randomSeed % 5201314;
        luckyNumberOf[msg.sender][n] = luckyNumber;
        balance += poolOf[n].amount;
        poolOf[n].totalLoser ++;
        wyAmoutOf[msg.sender] += poolOf[n].amount / 100;
        totalWY += poolOf[n].amount / 100;
        emit BlessNewlyweds(msg.sender, n, luckyNumber);
        if (poolOf[n].luckyLoser == address(0) || luckyNumber < poolOf[n].luckyNumber) {
            poolOf[n].luckyNumber = luckyNumber;
            poolOf[n].luckyLoser = msg.sender;
            emit NewLuckyLoser(msg.sender, n, luckyNumber);
        }
    }

}

