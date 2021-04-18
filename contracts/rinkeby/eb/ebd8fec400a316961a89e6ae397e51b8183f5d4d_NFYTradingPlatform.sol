/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-07
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.6.10;


contract Ownable is Context {

    address public owner;
    address private dev;

    modifier onlyOwner() {
        require(_msgSender() == owner, "Owner only");
        _;
    }

    modifier onlyDev() {
        require(_msgSender() == dev, "Dev only");
        _;
    }

    constructor(address _dev) public {
        owner = _msgSender();
        dev = _dev;
    }

    function transferOwnership(address payable _owner) public onlyOwner() {
        owner = _owner;
    }

    function transferDev(address _dev) public onlyDev() {
        dev = _dev;
    }

}

// File: contracts/NFYTradingPlatform.sol

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;




interface NFTContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function nftTokenId(address _stakeholder) external view returns(uint256 id);
}

contract NFYTradingPlatform is Ownable {
    using SafeMath for uint;

    bytes32[] private stakeTokenList;
    uint private nextTradeId;
    uint private nextOrderId;

    uint public platformFee;

    IERC20 public NFYToken;
    address public rewardPool;
    address public communityFund;
    address public devAddress;

    enum Side {
        BUY,
        SELL
    }

    struct StakeToken {
        bytes32 ticker;
        NFTContract nftContract;
        address nftAddress;
        address stakingAddress;
    }

    struct Order {
        uint id;
        address userAddress;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }

    struct PendingTransactions{
        uint pendingAmount;
        uint id;
    }

    mapping(bytes32 => mapping(address => PendingTransactions[])) private pendingETH;

    mapping(bytes32 => mapping(address => PendingTransactions[])) private pendingToken;

    mapping(bytes32 => StakeToken) private tokens;

    mapping(address => mapping(bytes32 => uint)) private traderBalances;

    mapping(bytes32 => mapping(uint => Order[])) private orderBook;

    mapping(address => uint) private ethBalance;

    // Event for a new trade
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address trader1,
        address trader2,
        uint amount,
        uint price,
        uint date
    );

    constructor(address _nfy, address _rewardPool, uint _fee, address _devFeeAddress, address _communityFundAddress, address _dev) Ownable(_dev) public {
        NFYToken = IERC20(_nfy);
        rewardPool = _rewardPool;
        platformFee = _fee;
        devAddress = _devFeeAddress;
        communityFund = _communityFundAddress;
    }

    // Function that updates platform fee
    function setFee(uint _fee) external onlyOwner() {
        platformFee = _fee;
    }

    // Function that updates dev address for portion of fee
    function setDevFeeAddress(address _devAddress) external onlyDev() {
        require(_devAddress != address(0), "Can not be 0 address");
        devAddress = _devAddress;
    }

    // Function that updates community address for portion of fee
    function setCommunityFeeAddress(address _communityAddress) external onlyOwner() {
        require(_communityAddress != address(0), "Can not be 0 address");
        communityFund = _communityAddress;
    }

    // Function that gets balance of a user
    function getTraderBalance(address _user, string memory ticker) external view returns(uint) {
        bytes32 _ticker = stringToBytes32(ticker);

        return traderBalances[_user][_ticker];
    }

    // Function that gets eth balance of a user
    function getEthBalance(address _user) external view returns(uint) {
        return ethBalance[_user];
    }

    // Function that adds staking NFT
    function addToken(string memory ticker, NFTContract _NFTContract, address _nftAddress, address _stakingAddress) onlyOwner() external {
        bytes32 _ticker = stringToBytes32(ticker);
        require(tokens[_ticker].stakingAddress == address(0), "Already exists");
        tokens[_ticker] = StakeToken(_ticker, _NFTContract, _nftAddress, _stakingAddress);
        stakeTokenList.push(_ticker);
    }

    // Function that allows user to deposit staking NFT
    function depositStake(string memory ticker, uint _tokenId, uint _amount) stakeNFTExist(ticker) external {
        bytes32 _ticker = stringToBytes32(ticker);
        require(tokens[_ticker].nftContract.ownerOf(_tokenId) == _msgSender(), "Owner of token is not user");

        (bool success, ) = tokens[_ticker].stakingAddress.call(abi.encodeWithSignature("decrementNFTValue(uint256,uint256)", _tokenId, _amount));
        require(success == true, "decrement call failed");

        traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].add(_amount);
    }

    // Function that allows a user to withdraw their staking NFT
    function withdrawStake(string memory ticker, uint _amount) stakeNFTExist(ticker) external {
        bytes32 _ticker = stringToBytes32(ticker);

        if(tokens[_ticker].nftContract.nftTokenId(_msgSender()) == 0){

            // Call to contract to add stake holder
            (bool addSuccess, ) = tokens[_ticker].stakingAddress.call(abi.encodeWithSignature("addStakeholderExternal(address)", _msgSender()));
            require(addSuccess == true, "add stakeholder call failed");
        }

        uint _tokenId = tokens[_ticker].nftContract.nftTokenId(_msgSender());
        require(traderBalances[_msgSender()][_ticker] >= _amount, 'balance too low');

        traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].sub(_amount);

        (bool success, ) = tokens[_ticker].stakingAddress.call(abi.encodeWithSignature("incrementNFTValue(uint256,uint256)", _tokenId, _amount));
        require(success == true, "increment call failed");
    }

    // Function that deposits eth
    function depositEth() external payable{
        ethBalance[_msgSender()] = ethBalance[_msgSender()].add(msg.value);
    }

    // Function that withdraws eth
    function withdrawEth(uint _amount) external{
        require(_amount > 0, "cannot withdraw 0 eth");
        require(ethBalance[_msgSender()] >= _amount, "Not enough eth in trading balance");

        ethBalance[_msgSender()] = ethBalance[_msgSender()].sub(_amount);

        _msgSender().transfer(_amount);
    }

    // Function that gets total all orders
    function getOrders(string memory ticker, Side side) external view returns(Order[] memory) {
        bytes32 _ticker = stringToBytes32(ticker);
        return orderBook[_ticker][uint(side)];
     }

    // Function that gets all trading
    function getTokens() external view returns(StakeToken[] memory) {
         StakeToken[] memory _tokens = new StakeToken[](stakeTokenList.length);
         for (uint i = 0; i < stakeTokenList.length; i++) {
             _tokens[i] = StakeToken(
               tokens[stakeTokenList[i]].ticker,
               tokens[stakeTokenList[i]].nftContract,
               tokens[stakeTokenList[i]].nftAddress,
               tokens[stakeTokenList[i]].stakingAddress
             );
         }
         return _tokens;
    }

    // Function that creates limit order
    function createLimitOrder(string memory ticker, uint _amount, uint _price, Side _side) external {

        uint devFee = platformFee.mul(10).div(100);
        uint communityFee = platformFee.mul(5).div(100);

        uint rewardFee = platformFee.sub(devFee).sub(communityFee);

        NFYToken.transferFrom(_msgSender(), devAddress, devFee);
        NFYToken.transferFrom(_msgSender(), communityFund, communityFee);
        NFYToken.transferFrom(_msgSender(), rewardPool, rewardFee);

        _limitOrder(ticker, _amount, _price, _side);
    }

    // Limit order Function
    function _limitOrder(string memory ticker, uint _amount, uint _price, Side _side) stakeNFTExist(ticker) internal {
        bytes32 _ticker = stringToBytes32(ticker);
        require(_amount > 0, "Amount can not be 0");
        require(_price > 0, "Price can not be 0");

        Order[] storage orders = orderBook[_ticker][uint(_side == Side.BUY ? Side.SELL : Side.BUY)];
        if(orders.length == 0){
            _createOrder(_ticker, _amount, _price, _side);
        }
        else{
            if(_side == Side.BUY){
                uint remaining = _amount;
                uint i;
                uint orderLength = orders.length;
                while(i < orders.length && remaining > 0) {

                    if(_price >= orders[i].price){
                        remaining = _matchOrder(_ticker,orders, remaining, i, _side);
                        nextTradeId = nextTradeId.add(1);

                        if(orders.length.sub(i) == 1 && remaining > 0){
                            _createOrder(_ticker, remaining, _price, _side);
                        }
                        i = i.add(1);
                    }
                    else{
                        i = orderLength;
                        if(remaining > 0){
                            _createOrder(_ticker, remaining, _price, _side);
                        }
                    }
                }
            }

            if(_side == Side.SELL){
                uint remaining = _amount;
                uint i;
                uint orderLength = orders.length;
                while(i < orders.length && remaining > 0) {
                    if(_price <= orders[i].price){
                        remaining = _matchOrder(_ticker,orders, remaining, i, _side);
                        nextTradeId = nextTradeId.add(1);

                        if(orders.length.sub(i) == 1 && remaining > 0){
                            _createOrder(_ticker, remaining, _price, _side);
                        }
                        i = i.add(1);
                    }
                    else{
                        i = orderLength;
                        if(remaining > 0){
                            _createOrder(_ticker, remaining, _price, _side);
                        }
                    }
                }
            }

           uint i = 0;

            while(i < orders.length && orders[i].filled == orders[i].amount) {
                for(uint j = i; j < orders.length.sub(1); j = j.add(1) ) {
                    orders[j] = orders[j.add(1)];
                }
            orders.pop();
            i = i.add(1);
            }
        }
    }

    function _createOrder(bytes32 _ticker, uint _amount, uint _price, Side _side) internal {
        if(_side == Side.BUY) {
            require(ethBalance[_msgSender()] > 0, "Can not purchase no stake");
            require(ethBalance[_msgSender()] >= _amount.mul(_price).div(1e18), "Eth too low");
            PendingTransactions[] storage pending = pendingETH[_ticker][_msgSender()];
            pending.push(PendingTransactions(_amount.mul(_price).div(1e18), nextOrderId));
            ethBalance[_msgSender()] = ethBalance[_msgSender()].sub(_amount.mul(_price).div(1e18));
        }
        else {
            require(traderBalances[_msgSender()][_ticker] >= _amount, "Token too low");
            PendingTransactions[] storage pending = pendingToken[_ticker][_msgSender()];
            pending.push(PendingTransactions(_amount, nextOrderId));
            traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].sub(_amount);
        }

        Order[] storage orders = orderBook[_ticker][uint(_side)];

        orders.push(Order(
            nextOrderId,
            _msgSender(),
            _side,
            _ticker,
            _amount,
            0,
            _price,
            now
        ));

        uint i = orders.length > 0 ? orders.length.sub(1) : 0;
        while(i > 0) {
            if(_side == Side.BUY && orders[i.sub(1)].price > orders[i].price) {
                break;
            }
            if(_side == Side.SELL && orders[i.sub(1)].price < orders[i].price) {
                break;
            }
            Order memory order = orders[i.sub(1)];
            orders[i.sub(1)] = orders[i];
            orders[i] = order;
            i = i.sub(1);
        }
        nextOrderId = nextOrderId.add(1);
    }

    function _matchOrder(bytes32 _ticker, Order[] storage orders, uint remaining, uint i, Side side) internal returns(uint left){
        uint available = orders[i].amount.sub(orders[i].filled);
        uint matched = (remaining > available) ? available : remaining;
        remaining = remaining.sub(matched);
        orders[i].filled = orders[i].filled.add(matched);

        emit NewTrade(
            nextTradeId,
            orders[i].id,
            _ticker,
            orders[i].userAddress,
            _msgSender(),
            matched,
            orders[i].price,
            now
        );

        if(side == Side.SELL) {
            traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].sub(matched);
            traderBalances[orders[i].userAddress][_ticker] = traderBalances[orders[i].userAddress][_ticker].add(matched);
            ethBalance[_msgSender()]  = ethBalance[_msgSender()].add(matched.mul(orders[i].price).div(1e18));

            PendingTransactions[] storage pending = pendingETH[_ticker][orders[i].userAddress];
            uint userOrders = pending.length;
            uint b = 0;
            uint id = orders[i].id;
            while(b < userOrders){
                if(pending[b].id == id && orders[i].filled == orders[i].amount){
                    for(uint o = b; o < userOrders.sub(1); o = o.add(1)){
                        pending[o] = pending[o.add(1)];
                        b = userOrders;
                    }
                    pending.pop();
                }
                b = b.add(1);
            }
        }

        if(side == Side.BUY) {
            require(ethBalance[_msgSender()] >= matched.mul(orders[i].price).div(1e18), 'eth balance too low');
            traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].add(matched);
            ethBalance[orders[i].userAddress]  = ethBalance[orders[i].userAddress].add(matched.mul(orders[i].price).div(1e18));
            ethBalance[_msgSender()]  = ethBalance[_msgSender()].sub(matched.mul(orders[i].price).div(1e18));

            PendingTransactions[] storage pending = pendingToken[_ticker][orders[i].userAddress];
            uint userOrders = pending.length;
            uint b = 0;
            while(b < userOrders){
                if(pending[b].id == orders[i].id && orders[i].filled == orders[i].amount){
                    for(uint o = b; o < userOrders.sub(1); o = o.add(1)){
                        pending[o] = pending[o.add(1)];
                        b = userOrders;
                    }
                    pending.pop();
                }
                b = b.add(1);
            }
        }
        left = remaining;
        return left;
    }

    function cancelOrder(string memory ticker, Side _side) external stakeNFTExist(ticker) {
        bytes32 _ticker = stringToBytes32(ticker);

        Order[] storage orders = orderBook[_ticker][uint(_side)];

        if(_side == Side.BUY) {
            PendingTransactions[] storage pending = pendingETH[_ticker][_msgSender()];
            uint amount = _cancelOrder(pending, orders, _side);
            ethBalance[_msgSender()]  = ethBalance[_msgSender()].add(amount);
        }
        else{
            PendingTransactions[] storage pending = pendingToken[_ticker][_msgSender()];
            uint amount = _cancelOrder(pending, orders, _side);
            traderBalances[_msgSender()][_ticker] = traderBalances[_msgSender()][_ticker].add(amount);
        }
    }

    function _cancelOrder(PendingTransactions[] storage pending, Order[] storage orders, Side _side) internal returns(uint left){
        int userOrders = int(pending.length - 1);
        require(userOrders >= 0, 'users has no pending order');
        uint userOrder = uint(userOrders);
        uint orderId = pending[userOrder].id;
        uint orderLength = orders.length;

        uint i = 0;
        uint amount;

        while(i < orders.length){

           if(orders[i].id == orderId){

                if(_side == Side.BUY){
                    amount = pending[userOrder].pendingAmount.sub(orders[i].filled.mul(orders[i].price).div(1e18));
                }

                else {
                    amount = pending[userOrder].pendingAmount.sub(orders[i].filled);
                }

                for(uint c = i; c < orders.length.sub(1); c = c.add(1)){
                    orders[c] = orders[c.add(1)];
                }

                orders.pop();
                pending.pop();
                i = orderLength;
           }

           i = i.add(1);
        }
        left = amount;
        return left;
    }

    modifier stakeNFTExist(string memory ticker) {
        bytes32 _ticker = stringToBytes32(ticker);
        require(tokens[_ticker].stakingAddress != address(0), "staking NFT does not exist");
        _;
    }

    //HELPER FUNCTION
    // CONVERT STRING TO BYTES32

    function stringToBytes32(string memory _source)
    public pure
    returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_source);
        string memory tempSource = _source;

        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(tempSource, 32))
        }
    }

}