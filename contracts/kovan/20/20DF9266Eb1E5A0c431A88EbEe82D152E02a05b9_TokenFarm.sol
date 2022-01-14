// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // *********
    // below is for old contracts
    // mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;
    address[] public allowedTokens;
    IERC20 public dappToken;

    // ******************
    // the real contract is from here
    // to do
    // 1. sushi
    // 2. transcation cost

    // uncomment this below if need real ETH price !!!!!!!!
    //import "AggregatorV3Interface.sol";

    uint256 private constant NO_TRADE_CLOSE_TO_EXPIRE = 10; //seconds
    uint256 private constant MIN_BUYER_SIZE = 1e2;
    uint256 private constant MIN_SELLER_SIZE = 1e3;
    uint256 private constant MIN_DEPOSIT_SIZE = 5e2;
    uint256 private constant TRANSACTION_COST = 1; // so 1% for each trade or we use a formula

    // prevent two people draw liquidity at same time
    enum contract_status {
        open,
        locked
    }
    contract_status private STATUS = contract_status.open;

    //Pricefeed interfaces from chainlink
    // uncomment this below if need real ETH price !!!!!!!!
    // AggregatorV3Interface internal ethFeed;
    uint256 public ethPrice;

    address payable contract_address;

    // store cash balance for each user, not used in any option sub-pool
    mapping(address => uint256) public cash_balance; // for testing, this value can be negtive, but not allowed in production

    // bid_struct: each bid in bids (bids is the order book for each option)
    struct bid_struct {
        uint256 price; // usd per option
        uint256 size; // number of option x strike
        address user_id; //user address
    }
    // bids[id] is the order book for each option[id]
    mapping(uint256 => bid_struct[]) public bids;

    // user_struct saves all info for each user
    enum option_side {
        not_open,
        buyer,
        seller,
        exercised
    }
    struct user_struct {
        // size: for buyer is number of eth option x strike price he placed
        // size: for seller is number of eth option x strike price x (1+ yield) on expiry day
        uint256 size; //in USD,
        option_side side; //after expiry, re-allocate payoff depends on buyer or seller of option
        uint256 unusedpremium; //in USD, premium in the pool but not traded, for buyer only
    }
    // user[user_address][option-id] is each user
    mapping(address => mapping(uint256 => user_struct)) public user;

    // option_struct saves info for each option
    struct option_struct {
        uint256 strike; //Price in USD, for example 3300
        uint256 expiry; //Unix timestamp of expiration time, in second
        uint256 supply; //buyer place bid and seller can sell the bid; supply = number of option x strike
        uint256[] order; //order book sequence pointer, low bid to high bid, bids[id][order[0]] is the lowest bid
    }
    // op[id] is each option
    option_struct[] public op;

    // ********************
    // for testing purpose
    uint256 private id = 0; // for testing we only have one option
    uint256[] private order_for_test;
    bid_struct[] private order_book_for_one_option;
    // settlement_amount is only for testing purples, need to delete in production
    uint256 public settlement_amount;
    address public ethAddress;

    // ********************

    //Kovan feeds: https://docs.chain.link/docs/reference-contracts
    constructor(address _dappTokenAddress, address _ethAddress) public {
        dappToken = IERC20(_dappTokenAddress);

        //ETH/USD Kovan feed
        // uncomment this below if need real ETH price !!!!!!!!
        // ethFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        contract_address = payable(address(this));

        // ********************
        // create fake option for testing
        option_struct memory option = option_struct({
            strike: 3300 * 1e18, // in USDC
            expiry: block.timestamp + 30 days, // 30seconds option, for testing purpose
            supply: 0, // after buyer place bid, supply will increase, in producation initial value =0
            order: order_for_test
        });
        op.push(option);
        // for testing purpose i give you fake money to play
        cash_balance[msg.sender] = 200000;
        ethAddress = _ethAddress;
        // ********************
    }

    function placeBid(uint256 newbid, uint256 premium) public {
        // buyer place bid order but nothing traded yet
        // newbid in usd, eth option price
        address _user = msg.sender;
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            user[_user][id].side != option_side.seller,
            "seller of option cannot buy"
        );
        require(premium >= MIN_BUYER_SIZE, "Min size = 100");
        require(premium <= cash_balance[_user], "not enough cash"); //cash actually sell the balance first
        // update buyer
        // btw user.size only updated when seller sell the bid / only when trade
        user[_user][id].side = option_side.buyer;
        user[_user][id].unusedpremium += premium; //premium not used if seller not selling it
        cash_balance[_user] -= premium;

        // update option supply
        // below line convert the same unit as option seller, ie: number of eth option x strike price (not number of eth option x ethPrice)
        // 1x of dual contract needs: ethPrice/stirke size of option to hedge; size/strike > size/current spot!
        // Warnning below line: first multiply then divide to keep precision
        uint256 _size = (premium * op[id].strike) / newbid;
        op[id].supply += _size;

        // update order book
        bids[id].push(bid_struct(newbid, _size, _user));
        if (op[id].order.length == 0) {
            op[id].order.push(bids[id].length - 1);
        } else {
            insertBid(newbid);
        }
    }

    function cancelBid() public {
        // to make it easy, cancel all bids for testing stage
        // can make it cancel specific bid, but need more coding
        address payable _user = payable(msg.sender);
        require(
            STATUS == contract_status.open,
            "contract busy, try again later"
        );
        require(
            user[_user][id].side == option_side.buyer,
            "you need to buy option first"
        );
        require(
            user[_user][id].unusedpremium > 0,
            "your oder has been filled or cancelled"
        );
        STATUS = contract_status.locked;
        // update buyer
        //_user.transfer(user[_user][id].unusedpremium);
        cash_balance[_user] += user[_user][id].unusedpremium;
        user[_user][id].unusedpremium = 0;

        // update order book and option supply
        uint256[] memory old_order = op[id].order;
        uint256 k = 0;
        for (uint256 i = 0; i < old_order.length; i++) {
            if (bids[id][old_order[i]].user_id != _user) {
                // if this bid is not from this user
                op[id].order[k] = old_order[i];
                // k = how many bids we need to keep
                k++;
            } else {
                op[id].supply -= bids[id][old_order[i]].size;
            }
        }
        for (uint256 i = 0; i < old_order.length - k; i++) {
            op[id].order.pop();
        }
        STATUS = contract_status.open;
    }

    function sellBid(uint256 seller_size) public {
        // seller size is in usd, full notional / collateral collected
        // seller option == buyer dual conntract!
        address _user = msg.sender;
        require(op[id].order.length > 0, "cannot sell if there is no bid");
        require(
            op[id].expiry > block.timestamp - NO_TRADE_CLOSE_TO_EXPIRE,
            "Already expired or too close to expiry"
        );
        require(
            user[_user][id].side != option_side.buyer,
            "buyer of option cannot sell"
        );
        require(seller_size >= MIN_SELLER_SIZE, "Min size = 1000");
        require(seller_size <= op[id].supply, "low supply");
        require(seller_size <= cash_balance[_user], "not enough cash"); //cash actually sell the balance first
        cash_balance[_user] -= seller_size;

        // update order book
        uint256 remain = seller_size;
        uint256 sizexprice = 0;
        uint256 each_size;
        uint256 i = op[id].order.length - 1;
        // sell multiple bids to have enough size
        while (remain > 0) {
            each_size = bids[id][op[id].order[i]].size;
            if (remain >= each_size) {
                // update buyer
                user[bids[id][op[id].order[i]].user_id][id].size += each_size;
                user[bids[id][op[id].order[i]].user_id][id]
                    .unusedpremium -= ((each_size *
                    bids[id][op[id].order[i]].price) / op[id].strike);
                // update seller
                sizexprice += (each_size * bids[id][op[id].order[i]].price);
                // update option
                op[id].supply -= each_size;
                // update order book
                bids[id][op[id].order[i]].size = 0;
                // last one is the highest one, pop the highest bid
                op[id].order.pop();
                remain -= each_size;
                i--;
            } else {
                // update buyer
                user[bids[id][op[id].order[i]].user_id][id].size += remain;
                user[bids[id][op[id].order[i]].user_id][id]
                    .unusedpremium -= ((remain *
                    bids[id][op[id].order[i]].price) / op[id].strike);
                // update seller
                sizexprice += (remain * bids[id][op[id].order[i]].price);
                // update option
                op[id].supply -= remain;
                // update order book
                bids[id][op[id].order[i]].size -= remain;
                remain = 0;
            }
        }
        // update seller
        getEthPrice();
        //expiry = (sizexprice / seller_size / ethPrice + 1 )x seller_size
        user[_user][id].size += ((sizexprice + seller_size * ethPrice) /
            ethPrice);
        user[_user][id].side = option_side.seller;
    }

    function getBestBid(uint256 seller_size)
        public
        view
        returns (uint256 average_bid)
    {
        // same logic as sellOption Function but not updating options and users
        require(op[id].order.length > 0, "cannot sell if there is no bid");
        require(seller_size >= MIN_SELLER_SIZE, "min size = 1000");
        require(seller_size <= op[id].supply, "low supply");
        uint256 remain = seller_size;
        uint256 sizexprice = 0;
        uint256 each_bid_amount;
        uint256 i = op[id].order.length - 1;
        while (remain > 0) {
            each_bid_amount = bids[id][op[id].order[i]].size;
            if (remain >= each_bid_amount) {
                sizexprice += (each_bid_amount *
                    bids[id][op[id].order[i]].price);
                remain -= each_bid_amount;
                i--;
            } else {
                sizexprice += (remain * bids[id][op[id].order[i]].price);
                remain = 0;
            }
        }
        average_bid = sizexprice / seller_size;
        return average_bid;
    }

    function exercise() public {
        // for testing purpose please set a fake eth price
        address _user = msg.sender;
        option_side _side = user[_user][id].side;
        require(
            _side == option_side.seller || _side == option_side.buyer,
            "You have no position"
        );
        require(
            op[id].expiry <= block.timestamp,
            "Cannot exercise before expiry"
        );
        require(_side != option_side.exercised, "You already excercised ");
        uint256 _size = user[_user][id].size;
        uint256 _strike = op[id].strike;
        if (_side == option_side.buyer) {
            require(_size > 0, "No one sell your bid and nothing to expire");
            require(ethPrice < _strike, "Expire worth zero");
            if (user[_user][id].unusedpremium > 0) {
                cancelBid();
            }
        }
        if (_side == option_side.seller) {
            if (ethPrice < _strike) {
                // Be very careful!!!!!!!!!!!!
                // NEED to transfer/sushi USD into ETH here !!! below is ETH amount!!!
                //_user.transfer(_size / _strike);
                cash_balance[_user] += _size / _strike;
                // please delete below line later
                settlement_amount = _size / _strike;
            } else {
                //_user.transfer(_size);
                cash_balance[_user] += _size;
                // please delete below line later
                settlement_amount = _size;
            }
        } else {
            if (ethPrice < _strike) {
                // below is for cash settlement in usd
                // noted: when we record buyer size = usd_collected / %price * strike / ethPrice
                //_user.transfer((_size * (_strike - ethPrice)) / _strike);
                cash_balance[_user] += ((_size * (_strike - ethPrice)) /
                    _strike);
                // please delete below line later
                settlement_amount = (_size * (_strike - ethPrice)) / _strike;
            } // else do nothing: expire worth zero
        }
        user[_user][id].side = option_side.exercised;
    }

    function insertBid(uint256 newbid) internal {
        // insert the newbid in to bids according to the newbid level, lowest bid at 0 position
        uint256 left = 0;
        uint256 right = op[id].order.length - 1;
        uint256 mid;

        // binary tree insert
        while (left < right) {
            mid = (left + right) / 2;
            if (newbid > bids[id][op[id].order[mid]].price) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        // when loop ends:
        // if left > right mid is correct position to insert
        // if left == right, need to compare once more with right
        if (left == right) {
            if (newbid > bids[id][op[id].order[left]].price) {
                mid = left + 1;
            } else {
                mid = left;
            }
        }
        // first push the pointer of newbid /last one of bids into the order array
        op[id].order.push(bids[id].length - 1);
        if (mid < op[id].order.length - 1) {
            for (uint256 i = op[id].order.length - 1; i > mid; i--) {
                // copy the old value to the right next one
                op[id].order[i] = op[id].order[i - 1];
            }
            // insert the pointer(aka order) of newbid
            op[id].order[mid] = bids[id].length - 1;
        } // else if mid == order.lenghth, newbid is highest and already been pushed to the last one of order
    }

    //Returns the latest ETH price
    function getEthPrice() public {
        // uncomment this below if need real ETH price !!!!!!!!
        //(
        //    uint80 roundID,
        //    int256 price,
        //    uint startedAt,
        //    uint timeStamp,
        //    uint80 answeredInRound
        //) = ethFeed.latestRoundData();
        //// If the round is not complete yet, timestamp is 0
        //require(timeStamp > 0, "Round not complete");
        ////Price should never be negative thus cast int to unit is ok
        ////Price is 8 decimal places and will require 1e10 correction later to 18 places
        //ethPrice = uint256(price);
        //ethPrice = 3799;
        (uint256 price, uint256 decimals) = getTokenValue(ethAddress);
        ethPrice = price * 1e10;
    }

    function deposit() public payable {
        require(msg.value >= MIN_DEPOSIT_SIZE, "Min size = 500");
        cash_balance[msg.sender] += msg.value;
    }

    function PoolBalance() public view returns (uint256) {
        return (contract_address.balance);
    }

    function getOrder() public view returns (uint256[] memory) {
        return op[id].order;
    }

    function getBid() public view returns (uint256) {
        return bids[id][op[id].order[op[id].order.length - 1]].price;
    }

    function userBalance(address _user) public view returns (uint256) {
        return cash_balance[_user];
    }

    function userUnusedPremium(address _user) public view returns (uint256) {
        return user[_user][id].unusedpremium;
    }

    function userSize(address _user) public view returns (uint256) {
        return user[_user][id].size;
    }

    function getSupply() public view returns (uint256) {
        return op[id].supply;
    }

    function getETH() public view returns (uint256) {
        (uint256 price, uint256 decimals) = getTokenValue(ethAddress);
        return price * 1e10;
    }

    function getSide(address _user) public view returns (uint256) {
        return uint256(user[_user][id].side);
    }

    function SecondToExpiry() public view returns (uint256) {
        return (op[id].expiry - block.timestamp);
    }

    function setFakeETH(uint256 _eth) public {
        ethPrice = _eth;
    }

    function forceExercise() public {
        setFakeExpiry(block.timestamp - 777);
        exercise();
    }

    function setFakeExpiry(uint256 fake_expiry) public {
        op[id].expiry = fake_expiry;
    }

    function createFakeBuyer() private {
        // for testing only, we create an option with some supply
        // only use before before placeBid, otherwise order will be wrong!!!
        address fake_user = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
        order_book_for_one_option.push(bid_struct(330, 1650, fake_user));
        order_book_for_one_option.push(bid_struct(396, 1320, fake_user));
        order_book_for_one_option.push(bid_struct(132, 6600, fake_user));
        order_book_for_one_option.push(bid_struct(198, 16500, fake_user));
        bids[id] = order_book_for_one_option;
        user[fake_user][id].side = option_side.buyer;
        user[fake_user][id].unusedpremium += 709;
        op[id].supply += 26070;
        op[id].order = [2, 3, 0, 1];
        cash_balance[fake_user] = 100000;
    }

    // **************************
    // we only need stake and unstake for now

    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently no allowed");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
        cash_balance[msg.sender] = getUserTotalValue(msg.sender);
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Cash balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        cash_balance[msg.sender] -= getUserSingleTokenValue(msg.sender, _token);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    // **************************
    // below is just supportive functions we dont really need

    function viewStakedToken(address _token) public returns (uint256) {
        // this is useless btw...
        uint256 balance = stakingBalance[_token][msg.sender];
        return stakingBalance[_token][msg.sender];
    }

    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
                return true;
            }
        }
        return false;
    }

    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function issueTokens() public onlyOwner {
        // Issue tokens to all stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        // price of the token * stakingBalance[_token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return // 10000000000000000000 ETH
        // ETH/USD -> 10000000000
        // 10 * 100 = 1,000
        ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}