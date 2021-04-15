/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IERC20Metadata is IERC20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FundRaising is Ownable {

    // use mantissa (ori * 10**18) to reserve precision
    // price means x usdt per token
    mapping(uint256 => uint256) public prices;
    
    address public usdt;
    address public mis;

    struct Round {
        uint256 price;
        uint start;
        uint duration;
        uint usdtMin;
        uint usdtMax;
        uint supply;
    }
    
    struct Record {
        uint256 lockedAmount;
        uint256 lockStartTs;
        bool useUnlockB;
    }
    // user => record amount
    mapping(address => uint256) public recordsLen;
    mapping(address => mapping(uint256 => Record)) public records;
    // round, account => paid
    mapping(uint => mapping(address => bool)) public paid;
    Round[] public rounds;
    // round => bought
    mapping(uint256 => uint256) public bought;

    // ============ Init ============ //
    
    constructor(address usdt_, address mis_) {
        usdt = usdt_;
        mis = mis_;

        uint256 usdtDecimals = IERC20Metadata(usdt).decimals();
        uint256 misDecimals = IERC20Metadata(mis).decimals();
        
        // 150 * 10**16 means 1.5 * 10**18

        rounds.push(Round(
            150 * 10**(16 + usdtDecimals - misDecimals),
            block.timestamp, // start
            72 * 3600,
            20000 * 10**usdtDecimals,
            50000 * 10**usdtDecimals,
            270000 * 10**usdtDecimals // token supply in usdt
        ));
        rounds.push(Round(
            200 * 10**(16 + usdtDecimals - misDecimals),
            block.timestamp + 72 * 3600, // start
            72 * 3600,
            100 * 10**usdtDecimals,
            1000 * 10**usdtDecimals,
            216000 * 10**usdtDecimals // token supply in usdt
        ));
        rounds.push(Round(
            250 * 10**(16 + usdtDecimals - misDecimals),
            block.timestamp + 2 * 72 * 3600, // start
            72 * 3600,
            100 * 10**usdtDecimals,
            1000 * 10**usdtDecimals,
            180000 * 10**usdtDecimals // token supply in usdt
        ));
    }

    // ============ Lock Rules ============ //
    
    // cliff
    // n: now
    // t: release ts
    // a: total amount
    // r: release rate
    function cliff(uint256 n, uint256 t, uint256 a, uint256 r) internal pure returns(uint256) {
        uint256 total = a * r / 10**18;
        return n >= t ? total : 0;
    }
    
    // linear
    // n: now
    // t0: release start ts
    // t1: release end ts
    // s: step length
    // a: total amount
    // r: release rate
    function linear(uint256 n, uint256 t0, uint256 t1, uint256 s, uint256 a, uint256 r) internal pure returns(uint256) {
        uint256 total = a * r / 10**18;
        if (n < t0) {
            return 0;
        }
        else if (n >= t1) {
            return total;
        }
        else {
            uint256 perStep = total / ((t1 - t0) / s);
            uint passedSteps = (n - t0) / s;
            return perStep * passedSteps;
        }
    }

    function getUnlockA(uint totalLocked, uint lockStartTs) internal view returns(uint) {
        uint256 n = block.timestamp;
        uint256 t0 = lockStartTs + 1 * 30 * 86400;
        uint256 t1 = lockStartTs + 6 * 30 * 86400;
        uint256 r0 = 50 * 10**16;
        uint256 r1 = 50 * 10**16;
        uint256 s = 30 * 86400;
        return cliff(n, t0, totalLocked, r0) + linear(n, t0, t1, s, totalLocked, r1);
    }
    
    function getUnlockB(uint totalLocked, uint lockStartTs) internal view returns(uint) {
        uint256 n = block.timestamp;
        uint256 t0 = lockStartTs;
        uint256 t1 = lockStartTs + 10 * 30 * 86400;
        uint256 r = 100 * 10**16;
        uint256 s = 30 * 86400;
        return linear(n, t0, t1, s, totalLocked, r);
    }

    // ============ Admin ============ //

    function deposit(address token, uint256 amount) public onlyOwner {
        IERC20Metadata(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address token, uint256 amount) public onlyOwner {
        IERC20Metadata(token).transfer(msg.sender, amount);
    }

    function updateRound(
        uint256 index,
        uint256 price,
        uint256 start,
        uint256 duration,
        uint256 usdtMin,
        uint256 usdtMax,
        uint256 supply
    ) public onlyOwner {
        Round memory round = Round(price, start, duration, usdtMin, usdtMax, supply);
        if (index > 0 && index < rounds.length) {
            rounds[index] = round;
        }
        else {
            rounds.push(round);
        }
    }
    
    // ============ Anyone ============ //    

    function _useUnlockPlanB(uint256 usdtAmount) public view returns(bool) {
        return usdtAmount >= 20000 * 10**IERC20Metadata(usdt).decimals();
    }
    
    function buy(uint256 roundId, uint256 usdtAmount) public {
        
        require(roundId < rounds.length, "WRONG_ROUND_ID");
        require(!paid[roundId][msg.sender], "ALREADY_BOUGHT");
        Round storage round = rounds[roundId];
        require(usdtAmount >= round.usdtMin, "LESS_THAN_MIN");
        require(usdtAmount <= round.usdtMax, "MORE_THAN_MAX");
        require(bought[roundId] + usdtAmount <= round.supply, "EXCEED_SUPPLY");
        
        // transfer
        IERC20Metadata(usdt).transferFrom(msg.sender, address(this), usdtAmount);
        
        // record
        
        records[msg.sender][recordsLen[msg.sender]] = Record(
            10**18 * usdtAmount / round.price,
            round.start + round.duration,
            _useUnlockPlanB(usdtAmount)
        );
        recordsLen[msg.sender] += 1;
        
        // post
        paid[roundId][msg.sender] = true;
        bought[roundId] += usdtAmount;
    }
    
    mapping(address => uint256) public claimed;
    
    function available(address account) public view returns(uint256) {
        uint len = recordsLen[account];
        uint total = 0;
        for(uint256 i=0;i< len;i++) {
            Record storage record = records[account][i];
            if (record.useUnlockB) {
                total += getUnlockB(record.lockedAmount, record.lockStartTs);
            }
            else {
                total += getUnlockA(record.lockedAmount, record.lockStartTs);
            }
        }
        return total - claimed[account];
    }
    
    function claim() public {
        uint a = available(msg.sender);
        require(a > 0, "NOTHING_TO_CLAIM");
        IERC20Metadata(mis).transfer(msg.sender, a);
        claimed[msg.sender] += a;
    }
}