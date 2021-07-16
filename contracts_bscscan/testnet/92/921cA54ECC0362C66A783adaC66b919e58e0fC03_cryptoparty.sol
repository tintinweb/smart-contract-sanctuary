/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: MIT Licensed


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  
  function getRoundData(uint80 _roundId)
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

contract cryptoparty{
    
    IBEP20 public BUSD;
    using SafeMath for uint256;
    using Address for address;
    AggregatorV3Interface public priceFeedBnb;
    AggregatorV3Interface public priceFeed;
    AggregatorV3Interface public temp;
    address payable public owner;
    address payable public MarketingWallet;
    uint256 public ticketPrice;
    struct User{
        address refrer;
        uint256 refferdUsers;
        uint256 refferdUsersticketsBought;
        uint256 ticketsOwned;
        uint256 buybackWorthbnb;
        uint256 buybackWorthbusd;
        uint256 refbonusbnb;
        uint256 refbonusbusd;
        bool alreadyUser;
        mapping(uint256 => address) refedUserlist;
        uint256 lastactivity;
    }
    mapping(address => User) public customers;
    mapping(uint256 => address) public top10;
    

    modifier onlyOwner() {
        require(msg.sender == owner,"CryptoParty: Not an owner");
        _;
    }
    constructor() public {
        owner = msg.sender; 
        BUSD = IBEP20(0xF85553FD7e1377B0f25F2Cd7cCBa2Dd1E1DfFC73);
        priceFeedBnb = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        ticketPrice = 5;
        customers[owner].alreadyUser = true;
        MarketingWallet = owner;
    }
    receive() external payable{}
    
    function buyTicketsBNB(address ref,uint256 ticket) public payable {
        User storage user = customers[msg.sender];
        User storage REFFF = customers[ref];
        require(ref != msg.sender && ref != address(0),'invalid refrer');
        require(customers[ref].alreadyUser || ref == owner,"refrer must be a customer first");
        require(msg.value >= USDtoBNB(ticket.mul(ticketPrice)),"need to pay According to price of ticket");
        if(!alreadyRefferd(msg.sender,ref)){
        REFFF.refedUserlist[REFFF.refferdUsers] = msg.sender;
        REFFF.refferdUsers++ ;
        }
        user.alreadyUser = true;
        user.refrer = ref;
        REFFF.refferdUsersticketsBought = REFFF.refferdUsersticketsBought.add(ticket);
        REFFF.refbonusbnb = REFFF.refbonusbnb.add(msg.value.mul(20).div(100));
        REFFF.buybackWorthbnb = REFFF.buybackWorthbnb.add(msg.value.mul(30).div(100));
        MarketingWallet.transfer(msg.value.div(2));
        user.ticketsOwned = user.ticketsOwned.add(ticket);
        REFFF.lastactivity = block.timestamp;
        updatetop10(ref);
    }
    function buyTicketsBUSD(address ref,uint256 ticket,uint256 amount) public {
        User storage user = customers[msg.sender];
        User storage REFFF = customers[ref];
        require(ref != msg.sender && ref != address(0),'invalid refrer');
        require(customers[ref].alreadyUser|| ref == owner,"refrer must be a customer first");
        require(amount >= ticketPrice.mul(ticket).mul(1e18),"PAY acording to busd price");
        if(!alreadyRefferd(msg.sender,ref)){
        REFFF.refedUserlist[REFFF.refferdUsers] = msg.sender;
        REFFF.refferdUsers = REFFF.refferdUsers.add(1);
        }
        BUSD.transferFrom(msg.sender,address(this),amount);
        user.alreadyUser = true;
        user.refrer = ref;
        REFFF.refferdUsersticketsBought = REFFF.refferdUsersticketsBought.add(ticket);
        customers[user.refrer].refbonusbusd = customers[user.refrer].refbonusbusd.add(amount.mul(20).div(100));
        customers[user.refrer].buybackWorthbusd = customers[user.refrer].buybackWorthbusd.add(amount.mul(30).div(100));
        user.ticketsOwned = user.ticketsOwned.add(ticket);
        BUSD.transfer(MarketingWallet,amount.div(2));
        REFFF.lastactivity = block.timestamp;
        updatetop10(ref);
    }
    function buyBackBnb(address token,uint256 amount,address pfeed) public {
        priceFeed = AggregatorV3Interface(pfeed);
        User storage user = customers[msg.sender];
        require(USDtoBNB(tokentoUSD(token,amount)).mul(180).div(100)<=user.buybackWorthbnb,"not ENough buybackamount");
        require((user.refferdUsers >=10 && user.ticketsOwned >=1) || (user.refferdUsers >=1 && user.ticketsOwned >=10) ,"Requirements for buyback not met" );
        IBEP20(token).transferFrom(msg.sender,owner,amount);
        msg.sender.transfer(USDtoBNB(tokentoUSD(token,amount)).mul(180).div(100));
    }
    function buyBackBusd(address token,uint256 amount,address pfeed) public {
        priceFeed = AggregatorV3Interface(pfeed);
        User storage user = customers[msg.sender];
        require(tokentoUSD(token,amount).mul(180).mul(1e18).div(100)<=user.buybackWorthbusd,"not ENough buybackamount");
        require((user.refferdUsers >=10 && user.ticketsOwned >=1) || (user.refferdUsers >=1 && user.ticketsOwned >=10) ,"Requirements for buyback not met" );
        IBEP20(token).transferFrom(msg.sender,owner,amount);
        BUSD.transfer(msg.sender,tokentoUSD(token,amount).mul(180).mul(1e18).div(100));
    }
    function claimRefBonusBNB()public{
        User storage user = customers[msg.sender];
        require(bnbtoUSD(user.refbonusbnb).div(ticketPrice) >= 2,"Bonus not enough for claim");
        msg.sender.transfer(user.refbonusbnb.mul(70).div(100));
    }
    function claimRefBonusBUSD()public{
        User storage user = customers[msg.sender];
        require(user.refbonusbusd.div(ticketPrice) >= 2,"Bonus not enough for claim");
        BUSD.transfer(msg.sender,user.refbonusbusd.mul(70).div(100));
    }
    function updatetop10(address add)internal{
        for(uint256 outer ; outer < 10 ; outer++){
            for(uint256 inner = outer; inner < 10 ; inner++)
            {
                if(customers[top10[outer]].refferdUsers > customers[top10[inner]].refferdUsers){
                 
                address swap = top10[outer];
                top10[outer] = top10[inner];
                top10[inner] = swap;
            } 
            }
        }
        for(uint256 i ; i < 10;i++){
            if(customers[add].refferdUsers > customers[top10[i]].refferdUsers){
                top10[i] = add;
            } 
        }
        for(uint256 outer ; outer < 10 ; outer++){
            for(uint256 inner = outer; inner < 10 ; inner++)
            {
                if(customers[top10[outer]].refferdUsers > customers[top10[inner]].refferdUsers){
                 
                address swap = top10[outer];
                top10[outer] = top10[inner];
                top10[inner] = swap;
            } 
            }
        }
    }
    function alreadyRefferd(address add,address ref) public view returns(bool){
        User storage user = customers[ref];
        for(uint256 i; i < user.refferdUsers ; i++){
            if(user.refedUserlist[i] == add){
                return true;
            }
        }
        return false;
    }
    // to get real time price of BNB
    function getLatestPriceBnb() public view returns (uint256) {
        (,int price,,,) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }
    function getLatestPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price).div(1e8);
    }
    // to check number of token for given BNB
    function bnbtoUSD(uint256 _amount) public view returns(uint256){
        uint256 precision = 1e2;
        uint256 bnbToUsd = precision.mul(_amount).mul(getLatestPriceBnb()).div(1e18);
        return bnbToUsd.div(precision);
    }
    function tokentoUSD(address token , uint256 _amount) public view returns(uint256){
        uint256 percision = 1e2;
        uint256 tokentousd = percision.mul(_amount).mul(getLatestPrice()).div(IBEP20(token).decimals());
        return tokentousd.div(percision);
    }
    function USDtoBNB(uint256 _amount) public view returns(uint256){
        uint256 precision = 1e2;
        uint256 usdtobnb = precision.mul(_amount).mul(1e18).div(getLatestPriceBnb());
        //uint256 numberOfTokens = bnbToUsd.mul(ticketPrice);
        return usdtobnb.div(precision);
    }
    function getLatestPriceRandomtoken() public view returns (uint256) {
        (,int price,,,) = temp.latestRoundData();
        return uint256(price).div(1e8);
    }
    function Price(address pricefeeedtemp) public returns(uint256){
        temp = AggregatorV3Interface(pricefeeedtemp);
        return getLatestPriceRandomtoken();
    }
    // to change Price of the token
    function changePrice(uint256 _ticketPrice) external onlyOwner{
        ticketPrice = _ticketPrice;
    }
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    function refaddress(address add) public view returns(address[20] memory downline){
        for(uint256 i; i < customers[add].refferdUsers;i++)
        {
               downline[i] = customers[add].refedUserlist[i];
        }
    }
    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns(bool){
        owner.transfer(_value);
        return true;
    }
    
    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
    function contractBalanceBnb() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return BUSD.allowance(owner, address(this));
    }
}