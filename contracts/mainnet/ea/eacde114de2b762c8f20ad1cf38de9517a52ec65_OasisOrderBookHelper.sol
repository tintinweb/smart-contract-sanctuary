/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-11
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/interfaces/IMatchingMarket.sol

pragma solidity ^0.5.0;

//pragma experimental ABIEncoderV2;



interface IMatchingMarket {

    struct OfferInfo {
        uint      pay_amt;
        IERC20    pay_gem;
        uint      buy_amt;
        IERC20    buy_gem;
        address   owner;
        uint64    timestamp;
    }

    function getBestOffer(IERC20 sell_gem, IERC20 buy_gem) external view returns(uint);
    function getWorseOffer(uint id) external view returns(uint);
    function offers(uint) external view returns(OfferInfo memory);
    function getOfferCount(IERC20 sell_gem, IERC20 buy_gem) external view returns(uint);
}

// File: contracts/OasisOrderBookHelper.sol

pragma solidity ^0.5.12;

pragma experimental ABIEncoderV2;




contract OasisOrderBookHelper {

    IMatchingMarket constant oasisExchange = IMatchingMarket(0x5e3e0548935a83aD29fb2A9153d331dc6d49020f);

    struct Offer {
        uint256   payAmount;
        IERC20    payToken;
        uint256   buyAmount;
        IERC20    buyToken;
    }

    constructor() public {
    }

    function getOrderBookByPairs(
        IERC20[] calldata tokens0,
        IERC20[] calldata tokens1,
        uint256 maxOrders
    )
        external
        view
        returns (Offer[][][] memory orders)
    {
        orders = new Offer[][][](tokens0.length);
        for (uint i = 0; i < tokens0.length; i++) {
            orders[i] = getOrderBookByPair(tokens0[i], tokens1[i], maxOrders);
        }
    }

    function getOrderBookByPair(
        IERC20 token0,
        IERC20 token1,
        uint256 maxOrders
    )
        public
        view
        returns (Offer[][] memory orders)
    {
        orders = new Offer[][](2);
        orders[0] = getOrdersByPair(token0, token1, maxOrders); // bids
        orders[1] = getOrdersByPair(token1, token0, maxOrders); // asks
    }

    function getOrdersByPair(
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 maxOrders
    )
        public
        view
        returns (Offer[] memory orders)
    {

        uint256 offersCount = oasisExchange.getOfferCount(sellToken, buyToken);
        if (offersCount > maxOrders) {
            offersCount = maxOrders;
        }
        uint256 offerId = oasisExchange.getBestOffer(sellToken, buyToken);
        orders = new Offer[](offersCount);
        for(uint i = 0; i < offersCount; i++) {
            IMatchingMarket.OfferInfo memory info = oasisExchange.offers(offerId);
            orders[i].payAmount =  info.pay_amt;
            orders[i].payToken  =  info.pay_gem;
            orders[i].buyAmount =  info.buy_amt;
            orders[i].buyToken  =  info.buy_gem;
            offerId = oasisExchange.getWorseOffer(offerId);
        }
    }
}