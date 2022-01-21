// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Item {

    using Counters for Counters.Counter;
    Counters.Counter private idBuyBed;
    Counters.Counter private idBuyStaff;

    address private owner;
    address public token;
    address private buyBack;
    uint256 private priceBed;

    struct BuyBed {
        uint256 amount;
        uint time;
    }

    struct BuyStaff {
        uint256 amount;
        uint time;
    }

    mapping (address => mapping (uint => BuyBed)) public bed;
    mapping (address => mapping (uint => BuyStaff)) public staff;
    mapping (address => uint) public lastBed;
    mapping (address => uint) public lastStaff;

    event BuyBedCreated (
        uint256 amount,
        uint time
    );

    event BuyStaffCreated (
        uint256 amount,
        uint time
    );

    constructor (address master, address _token, address _buyBack) {
        owner = master;
        token = _token;
        buyBack = _buyBack;
    }

    function buyBed(uint256 amount) external {
        require(msg.sender != address(0), 'Address Zero');
        require(amount > 0, 'Not amount');

        lastBed[msg.sender] += 1;

        bed[msg.sender][lastBed[msg.sender]] = BuyBed(
            amount,
            block.timestamp
        );

        IERC20(token).transferFrom(msg.sender, buyBack, amount);

        emit BuyBedCreated(
            amount,
            block.timestamp
        );
    }

    function buyStaff(uint256 amount) external {
        require(msg.sender != address(0), 'Address Zero');
        require(amount > 0, 'Not amount');

        lastStaff[msg.sender] += 1;

        staff[msg.sender][lastStaff[msg.sender]] = BuyStaff(
            amount,
            block.timestamp
        );

        IERC20(token).transferFrom(msg.sender, buyBack, amount);

        emit BuyStaffCreated(
            amount,
            block.timestamp
        );
    }

    function setToken(address _token) external {
        require(owner == msg.sender, 'Only owner');
        token = _token;
    }

    function getToken() external view returns (address) {
        return token;
    }

    function setPriceBed(uint256 amount) external {
        require(msg.sender == owner, 'Only owner');
        priceBed = amount;
    }

    function getPriceBed() external view returns(uint256) {
        return priceBed;
    }

    function getBuyBedWallet(address user) external view returns(BuyBed[] memory) {
        BuyBed[] memory data = new BuyBed[](lastBed[user]);
        uint currentIndex = 0;

        for (uint i = 0; i < lastBed[user]; i++) {
            uint currentId = i + 1;
            BuyBed storage currentItem = bed[user][currentId];
            data[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return data;
    }

    function getBuyStaffWallet(address user) external view returns(BuyStaff[] memory) {
        BuyStaff[] memory data = new BuyStaff[](lastStaff[user]);
        uint currentIndex = 0;

        for (uint i = 0; i < lastStaff[user]; i++) {
            uint currentId = i + 1;
            BuyStaff storage currentItem = staff[user][currentId];
            data[currentIndex] = currentItem;
            currentIndex += 1;
        }

        return data;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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