/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-25
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

library IterableMap {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.7;

contract DonateUSDT is ReentrancyGuard {
    using IterableMap for IterableMap.Map;
    IterableMap.Map private donateMap;

    uint256 private totalAmount;
    uint256 public startTime;
    uint256 public endTime;
    bool public isPaused;
    address private owner;

    event Donate(address, address, uint256);
    event Withdraw(address, address, uint256);

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "msg sender is not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, "Pausable: paused");
        _;
    }

    function pause() external onlyOwner {
        require(!isPaused, "Pausable: paused");
        isPaused = true;
    }

    function unpause() external onlyOwner {
        require(isPaused, "Pausable: not paused");
        isPaused = false;
    }

    function setTime(uint256 start, uint256 end) external onlyOwner {
        require(end > start, "end time must more than start time.");
        require(start > 0, "start time can not less than zero");
        require(end > 0, "end time can not less than zero");
        startTime = start;
        endTime = end;
    }

    function donate(address token, uint256 amount) external whenNotPaused nonReentrant {
        uint256 nowTime = block.timestamp;
        require((startTime != 0 && endTime != 0 && startTime <= nowTime), "donation has not stared");
        require(nowTime < endTime, "donation is over");
        require(amount > 0, "donate maount can not be zero");
        require(token != address(0), "invalid token address");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "donate fail");
        donateMap.set(msg.sender, donateMap.get(msg.sender) + amount);
        totalAmount += amount;
        emit Donate(token, msg.sender, amount);
    }

    function myDonate(address wallet) external view returns(uint256) {
        return donateMap.get(wallet);
    }

    function withdrawTo(address receiver, address token, uint256 amount) public onlyOwner whenNotPaused nonReentrant {
        require(token != address(0), "token address invalid");
        require(amount > 0, "amount can not be zero");
        require(amount <= IERC20(token).balanceOf(address(this)), "contract balance is not enough");
        IERC20(token).transfer(receiver, amount);
        emit Withdraw(token, receiver, amount);
    }

    function withdraw(address token) external onlyOwner {
        require(token != address(0), "token address invalid");
        withdrawTo(msg.sender, token, IERC20(token).balanceOf(address(this)));
    }

    function getBalanceOf(address token) external view returns(uint256) {
        require(token != address(0), "token address invalid");
        return IERC20(token).balanceOf(address(this));
    }

    function getTotalAmount() external view returns(uint256) {
        return totalAmount;
    }

    function getDonateRecords(uint index) external view returns(address, uint256) {
        require(index < donateMap.size(), "Arrays index out of bounds");
        address addr = donateMap.getKeyAtIndex(index);
        uint256 amount = donateMap.get(addr);
        return(addr, amount);
    }
}