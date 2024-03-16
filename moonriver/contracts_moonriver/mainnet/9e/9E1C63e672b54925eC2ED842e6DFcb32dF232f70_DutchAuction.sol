pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DutchAuction {
    uint256 public immutable START;
    uint256 public immutable DURATION;
    uint256 public immutable END;

    uint256 public immutable STARTPRICE;
    uint256 public immutable ENDPRICE;
    uint256 public immutable SUPPLY;

    address public immutable BENEFICIARY;
    address public immutable OWNER;

    IERC20 public immutable paymentToken;

    uint256 private counter = 1; //initialize counter at 1 for slot range 1-20
    bool halted;

    mapping(uint256 => address) public slotOwners;
    mapping(uint256 => string) public kanariaId;
    mapping(uint256 => string) public note;

    modifier saleOpen {
       require(block.timestamp >= START, "Sale not yet open");
       require(!halted, "Auction is halted");
       _;
    }

    modifier onlyOwner {
       require(msg.sender == OWNER);
       _;
    }

    ////////////////////////////////////
    //            EVENTS
    ////////////////////////////////////

    event ItemBought(address purchaser, uint256 itemId, uint256 price);

    ////////////////////////////////////
    //          CONSTRUCTOR
    ////////////////////////////////////

    constructor(
        uint256 _start,
        uint256 _duration,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _supply,
        address _beneficiary,
        address _paymentToken
    ) {
        require(_startPrice >= _endPrice, "start price < end price");
        require(_start > block.timestamp, "start in past");
        START = _start;
        DURATION = _duration;
        END = _start + _duration;
        STARTPRICE = _startPrice;
        ENDPRICE = _endPrice;
        SUPPLY = _supply;
        BENEFICIARY = _beneficiary;
        paymentToken = IERC20(_paymentToken);
        OWNER = BENEFICIARY;
    }

    ////////////////////////////////////
    //          INTERACTION
    ////////////////////////////////////

    function buy (string calldata _kanariaId, string calldata _note) external saleOpen {

        require(counter <= SUPPLY, "Auction sold out");
        uint256 price = getPrice();
        uint256 itemId = counter;
        counter+=1;

        paymentToken.transferFrom(msg.sender, BENEFICIARY, price);
        slotOwners[itemId] = msg.sender;
        kanariaId[itemId] = _kanariaId;
        note[itemId] = _note;

        emit ItemBought(msg.sender, itemId, price);
    }

    function halt(bool state) external onlyOwner {
        halted = state;
    }

    ////////////////////////////////////
    //          READ-ONLY
    ////////////////////////////////////

    function getPrice() public view returns (uint256 price) {
        uint256 totalDiscount = STARTPRICE - ENDPRICE;
        uint256 timeElapsed = getTimeElapsed(DURATION);
        uint256 discountAmount = getDiscountAmount(timeElapsed);
        price = STARTPRICE - discountAmount;
    }

    function getTimeElapsed(uint256 totalTime) public view returns(uint) {
        uint256 precision = 1_000_000;
        uint256 elapsed = START < block.timestamp ? (block.timestamp - START) : 0 ;
        elapsed = clamp_upper(elapsed, totalTime);
        return elapsed;
    }

    function slotsLeft() public view returns(uint256 slots) {
        slots = (SUPPLY + 1 - counter); //offset down for counter offset;
    }

    function getDiscountAmount(uint256 timeElapsed) internal view returns(uint) {
        uint256 totalDiscount = STARTPRICE - ENDPRICE;
        uint256 discountAmount = (totalDiscount * timeElapsed) / DURATION;
        return discountAmount;
    }

    function clamp_upper(uint256 value, uint256 clamp) internal view returns(uint) {
        if (value < clamp){
          return value;
        }
        else {
          return clamp;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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