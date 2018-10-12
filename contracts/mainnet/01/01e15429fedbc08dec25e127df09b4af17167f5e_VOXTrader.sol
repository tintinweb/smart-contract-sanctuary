pragma solidity 0.4.24;


/**
* VOXTrader for the talketh.io ICO by Horizon-Globex.com of Switzerland.
*
* An ERC20 compliant DEcentralized eXchange [DEX] https://talketh.io/dex
*
* ICO issuers that utilize the Swiss token issuance standard from Horizon Globex
* are supplied with a complete KYC+AML platform, an ERC20 token issuance platform,
* a Transfer Agent service, and a post-ICO ERC20 DEX for their investor exit strategy.
*
* Trade events shall be rebroadcast on issuers Twitter feed https://twitter.com/talkethICO
*
* -- DEX Platform Notes --
* 1. By default, only KYC&#39;ed hodlers of tokens may participate on this DEX.
*    - Issuer is free to relax this restriction subject to counsels Legal Opinion.
* 2. The issuer has sole discretion to set a minimum bid and a maximum ask. 
* 3. Seller shall pay a trade execution fee in ETH which is automatically deducted herein. 
*    - Issuer is free to amend the trade execution fee percentage from time to time.
*
*/

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20/ERC20Basic.sol
// 
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function allowance(address approver, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed approver, address indexed spender, uint256 value);
}



//
// base contract for all our horizon contracts and tokens
//
contract HorizonContractBase {
    // The owner of the contract, set at contract creation to the creator.
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // Contract authorization - only allow the owner to perform certain actions.
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}




 

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
 * Source: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/// math.sol -- mixin for inline numerical wizardry

// Taken from: https://dapp.tools/dappsys/ds-math.html

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



library DSMath {
    
    function dsAdd(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function dsMul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = dsAdd(dsMul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = dsAdd(dsMul(x, WAD), y / 2) / y;
    }
}


/**
* VOXTrader for the talketh.io ICO by Horizon-Globex.com of Switzerland.
*
* An ERC20 compliant DEcentralized eXchange [DEX] https://talketh.io/dex
*
* ICO issuers that utilize the Swiss token issuance standard from Horizon Globex
* are supplied with a complete KYC+AML platform, an ERC20 token issuance platform,
* a Transfer Agent service, and a post-ICO ERC20 DEX for their investor exit strategy.
*
* Trade events shall be rebroadcast on issuers Twitter feed https://twitter.com/talkethICO
*
* -- DEX Platform Notes --
* 1. By default, only KYC&#39;ed hodlers of tokens may participate on this DEX.
*    - Issuer is free to relax this restriction subject to counsels Legal Opinion.
* 2. The issuer has sole discretion to set a minimum bid and a maximum ask. 
* 3. Seller shall pay a trade execution fee in ETH which is automatically deducted herein. 
*    - Issuer is free to amend the trade execution fee percentage from time to time.
*
*/
contract VOXTrader is HorizonContractBase {
    using SafeMath for uint256;
    using DSMath for uint256;

    struct TradeOrder {
        uint256 quantity;
        uint256 price;
        uint256 expiry;
    }

    // The owner of this contract.
    address public owner;

    // The balances of all accounts.
    mapping (address => TradeOrder) public orderBook;

    // The contract containing the tokens that we trade.
    address public tokenContract;

    // The price paid for the last sale of tokens on this contract.
    uint256 public lastSellPrice;

    // The highest price an asks can be placed.
    uint256 public sellCeiling;

    // The lowest price an ask can be placed.
    uint256 public sellFloor;

    // The percentage taken off the cost of buying tokens in Ether.
    uint256 public etherFeePercent;
    
    // The minimum Ether fee when buying tokens (if the calculated percent is less than this value);
    uint256 public etherFeeMin;

    // Both buying and selling tokens is restricted to only those who have successfully passed KYC.
    bool public enforceKyc;

    // The addresses of those allowed to trade using this contract.
    mapping (address => bool) public tradingWhitelist;

    // A sell order was put into the order book.
    event TokensOffered(address indexed who, uint256 quantity, uint256 price, uint256 expiry);

    // A user bought tokens from another user.
    event TokensPurchased(address indexed purchaser, address indexed seller, uint256 quantity, uint256 price);

    // A user updated their ask.
    event TokenOfferChanged(address who, uint256 quantity, uint256 price, uint256 expiry);

    // A user bought phone credit using a top-up voucher, buy VOX Tokens on thier behalf to convert to phone credit.
    event VoucherRedeemed(uint256 voucherCode, address voucherOwner, address tokenSeller, uint256 quantity);

    // The contract has been shut down.
    event ContractRetired(address newAddcontract);


    /**
     * @notice Set owner and the target ERC20 contract containing the tokens it trades.
     *
     * @param tokenContract_    The ERC20 contract whose tokens this contract trades.
     */
    constructor(address tokenContract_) public {
        owner = msg.sender;
        tokenContract = tokenContract_;

        // On publication the only person allowed trade is the issuer/owner.
        enforceKyc = true;
        setTradingAllowed(msg.sender, true);
    }

    /**
     * @notice Get the trade order for the specified address.
     *
     * @param who    The address to get the trade order of.
     */
    function getOrder(address who) public view returns (uint256 quantity, uint256 price, uint256 expiry) {
        TradeOrder memory order = orderBook[who];
        return (order.quantity, order.price, order.expiry);
    }

    /**
     * @notice Offer tokens for sale, you must call approve on the ERC20 contract first, giving approval to
     * the address of this contract.
     *
     * @param quantity  The number of tokens to offer for sale.
     * @param price     The unit price of the tokens.
     * @param expiry    The date and time this order ends.
     */
    function offer(uint256 quantity, uint256 price, uint256 expiry) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(quantity > 0, "You must supply a quantity.");
        require(price > 0, "The sale price cannot be zero.");
        require(expiry > block.timestamp, "Cannot have an expiry date in the past.");
        require(price >= sellFloor, "The ask is below the minimum allowed.");
        require(sellCeiling == 0 || price <= sellCeiling, "The ask is above the maximum allowed.");

        uint256 allowed = ERC20Interface(tokenContract).allowance(msg.sender, this);
        require(allowed >= quantity, "You must approve the transfer of tokens before offering them for sale.");

        uint256 balance = ERC20Interface(tokenContract).balanceOf(msg.sender);
        require(balance >= quantity, "Not enough tokens owned to complete the order.");

        orderBook[msg.sender] = TradeOrder(quantity, price, expiry);
        emit TokensOffered(msg.sender, quantity, price, expiry);
    }

    /**
     * @notice Buy tokens from an existing sell order.
     *
     * @param seller    The current owner of the tokens for sale.
     * @param quantity  The number of tokens to buy.
     * @param price     The ask price of the tokens.
    */
    function execute(address seller, uint256 quantity, uint256 price) public payable {
        require(enforceKyc == false || (isAllowedTrade(msg.sender) && isAllowedTrade(seller)), "Buyer and Seller must be approved to trade on this exchange.");
        TradeOrder memory order = orderBook[seller];
        require(order.price == price, "Buy price does not match the listed sell price.");
        require(block.timestamp < order.expiry, "Sell order has expired.");
        require(price >= sellFloor, "The bid is below the minimum allowed.");
        require(sellCeiling == 0 || price <= sellCeiling, "The bid is above the maximum allowed.");

        // Deduct the sold tokens from the sell order immediateley to prevent re-entrancy.
        uint256 tradeQuantity = order.quantity > quantity ? quantity : order.quantity;
        order.quantity = order.quantity.sub(tradeQuantity);
        if (order.quantity == 0) {
            order.price = 0;
            order.expiry = 0;
        }
        orderBook[seller] = order;

        uint256 cost = tradeQuantity.wmul(order.price);
        require(msg.value >= cost, "You did not send enough Ether to purchase the tokens.");

        uint256 etherFee = calculateFee(cost);

        if(!ERC20Interface(tokenContract).transferFrom(seller, msg.sender, tradeQuantity)) {
            revert("Unable to transfer tokens from seller to buyer.");
        }

        // Pay the seller and if applicable the fee to the issuer.
        seller.transfer(cost.sub(etherFee));
        if(etherFee > 0)
            owner.transfer(etherFee);

        lastSellPrice = price;

        emit TokensPurchased(msg.sender, seller, tradeQuantity, price);
    }

    /**
     * @notice Cancel an outstanding order.
     */
    function cancel() public {
        orderBook[msg.sender] = TradeOrder(0, 0, 0);

        TradeOrder memory order = orderBook[msg.sender];
        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);
    }

    /** @notice Allow/disallow users from participating in trading.
     *
     * @param who       The user 
     * @param canTrade  True to allow trading, false to disallow.
    */
    function setTradingAllowed(address who, bool canTrade) public onlyOwner {
        tradingWhitelist[who] = canTrade;
    }

    /**
     * @notice Check if a user is allowed to trade.
     *
     * @param who   The user to check.
     */
    function isAllowedTrade(address who) public view returns (bool) {
        return tradingWhitelist[who];
    }

    /**
     * @notice Restrict trading to only those who are whitelisted.  This is true during the ICO.
     *
     * @param enforce   True to restrict trading, false to open it up.
    */
    function setEnforceKyc(bool enforce) public onlyOwner {
        enforceKyc = enforce;
    }

    /**
     * @notice Modify the price of an existing ask.
     *
     * @param price     The new price.
     */
    function setOfferPrice(uint256 price) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(price >= sellFloor && (sellCeiling == 0 || price <= sellCeiling), "Updated price is out of range.");

        TradeOrder memory order = orderBook[msg.sender];
        require(order.price != 0 || order.expiry != 0, "There is no existing order to modify.");
        
        order.price = price;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);
    }

    /**
     * @notice Change the number of VOX Tokens offered by this user.  NOTE: to set the quantity to zero use cancel().
     *
     * @param quantity  The new quantity of the ask.
     */
    function setOfferSize(uint256 quantity) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(quantity > 0, "Size must be greater than zero, change rejected.");
        uint256 balance = ERC20Interface(tokenContract).balanceOf(msg.sender);
        require(balance >= quantity, "Not enough tokens owned to complete the order change.");
        uint256 allowed = ERC20Interface(tokenContract).allowance(msg.sender, this);
        require(allowed >= quantity, "You must approve the transfer of tokens before offering them for sale.");

        TradeOrder memory order = orderBook[msg.sender];
        order.quantity = quantity;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, quantity, order.price, order.expiry);
    }

    /**
     * @notice Modify the expiry date of an existing ask.
     *
     * @param expiry    The new expiry date.
     */
    function setOfferExpiry(uint256 expiry) public {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");
        require(expiry > block.timestamp, "Cannot have an expiry date in the past.");

        TradeOrder memory order = orderBook[msg.sender];
        order.expiry = expiry;
        orderBook[msg.sender] = order;

        emit TokenOfferChanged(msg.sender, order.quantity, order.price, order.expiry);        
    }

    /**
     * @notice Set the percent fee applied to the Ether used to pay for tokens.
     *
     * @param percent   The new percentage value at 18 decimal places.
     */
    function setEtherFeePercent(uint256 percent) public onlyOwner {
        require(percent <= 100000000000000000000, "Percent must be between 0 and 100.");
        etherFeePercent = percent;
    }

    /**
     * @notice Set the minimum amount of Ether to be deducted during a buy.
     *
     * @param min   The new minimum value.
     */
    function setEtherFeeMin(uint256 min) public onlyOwner {
        etherFeeMin = min;
    }

    /**
     * @notice Calculate the company&#39;s fee for facilitating the transfer of tokens.  The fee is in Ether so
     * is deducted from the seller of the tokens.
     *
     * @param ethers    The amount of Ether to pay for the tokens.
     * @return fee      The amount of Ether taken as a fee during a transfer.
     */
    function calculateFee(uint256 ethers) public view returns (uint256 fee) {

        fee = ethers.wmul(etherFeePercent / 100);
        if(fee < etherFeeMin)
            fee = etherFeeMin;            

        return fee;
    }

    /**
     * @notice Buy from multiple sellers at once to fill a single large order.
     *
     * @dev This function is to reduce the transaction costs and to make the purchase a single transaction.
     *
     * @param sellers       The list of sellers whose tokens make up this buy.
     * @param lastQuantity  The quantity of tokens to buy from the last seller on the list (the other asks
     *                      are bought in full).
     */
    function multiExecute(address[] sellers, uint256 lastQuantity) public payable returns (uint256 totalVouchers) {
        require(enforceKyc == false || isAllowedTrade(msg.sender), "You are unknown and not allowed to trade.");

        totalVouchers = 0;

        for (uint i = 0; i < sellers.length; i++) {
            TradeOrder memory to = orderBook[sellers[i]];
            if(i == sellers.length-1) {
                execute(sellers[i], lastQuantity, to.price);
                totalVouchers += lastQuantity;
            }
            else {
                execute(sellers[i], to.quantity, to.price);
                totalVouchers += to.quantity;
            }
        }

        return totalVouchers;
    }

    /**
     * @notice A user has redeemed a top-up voucher for phone credit.  This is executed by the owner as it is an internal process
     * to convert a voucher to phone credit via VOX Tokens.
     *
     * @param voucherCode   The code on the e.g. scratch card that is to be redeemed for call credit.
     * @param voucherOwner  The wallet id of the user redeeming the voucher.
     * @param seller        The wallet id selling the VOX Tokens needed to fill the voucher.
     * @param quantity      The quantity of VOX tokens needed to fill the voucher.
     */
    function redeemVoucherSingle(uint256 voucherCode, address voucherOwner, address seller, uint256 quantity) public onlyOwner payable {

        // Send ether to the token owner and as we buy them as the owner they get burned.
        TradeOrder memory order = orderBook[seller];
        execute(seller, quantity, order.price);

        // Log the event so the system can detect the successful top-up and transfer credit to the voucher owner.
        emit VoucherRedeemed(voucherCode, voucherOwner, seller, quantity);
    }

    /**
     * @notice A user has redeemed a top-up voucher for phone credit.  This is executed by the owner as it is an internal process
     * to convert a voucher to phone credit via VOX Tokens.
     *
     * @param voucherCode   The code on the e.g. scratch card that is to be redeemed for call credit.
     * @param voucherOwner  The wallet id of the user redeeming the voucher.
     * @param sellers       The wallet id(s) selling the VOX Tokens needed to fill the voucher.
     * @param lastQuantity  The quantity of the last seller&#39;s ask to use, the other orders are used in full.
     */
    function redeemVoucher(uint256 voucherCode, address voucherOwner, address[] sellers, uint256 lastQuantity) public onlyOwner payable {

        // Send ether to the token owner and as we buy them as the owner they get burned.
        uint256 totalVouchers = multiExecute(sellers, lastQuantity);

        // If we fill the voucher from multiple sellers we set the seller address to zero, the associated
        // TokensPurchased events will contain the details of the orders filled.
        address seller = sellers.length == 1 ? sellers[0] : 0;
        emit VoucherRedeemed(voucherCode, voucherOwner, seller, totalVouchers);
    }

    /**
     * @notice Set the highest price an ask can be listed.
     *
     * @param ceiling   The new maximum price allowed for a sale.
     */
    function setSellCeiling(uint256 ceiling) public onlyOwner {
        sellCeiling = ceiling;
    }

    /**
     * @notice Set the lowest price an ask can be listed.
     *
     * @param floor   The new minimum price allowed for a sale.
     */
    function setSellFloor(uint256 floor) public onlyOwner {
        sellFloor = floor;
    }

    /**
    * @dev A newer version of this contract is available and this contract is now discontinued.
    *
    * @param recipient      Which account would get any ether from this contract (it shouldn&#39;t have any).
    * @param newContract    The address of the newer version of this contract.
    */
    function retire(address recipient, address newContract) public onlyOwner {
        emit ContractRetired(newContract);

        selfdestruct(recipient);
    }
}