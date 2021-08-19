/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

pragma solidity ^0.6.12;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

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
contract TTTCrowdsale15{
    IBEP20 public token;
    IBEP20 public BUSD;
    using SafeMath for uint256;
    using Address for address;
    address payable public owner;
    uint256 public tokenPrice;
    uint256 private minAmount;
    address private charitywallet;
    uint256 private maxAmount;
    uint256 public launchTime;
    uint256 public soldToken;
    uint256 public maxSell;
    uint256 [4] private timelock = [90 seconds, 120 seconds, 180 seconds, 0];
    uint256 [4] private timelockBonus = [25,40,50,0];
    uint256 [4] public referralPercent = [5,8,10,12];
    struct User{
        address referrer;
        uint256 referredamount;
        uint256 boughtamount;
        bool isExist;
        uint256 selectedplan;
        uint256 claimtime;
        uint256 usertimelockBonus;
        uint256 canclaimBUSDAmount;
        uint256 claimedBusd;
        bool claiminBusd;
        bool claimed;
        bool Alreadybought;
    }
    mapping(address => User) public users;
    mapping(address => uint256) public balances;
    mapping(address => bool) public claimed;
    

    modifier onlyOwner() {
        require(msg.sender == owner,"BEP20: Not an owner");
        _;
    }
    
    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);
    
    constructor() public {
        owner = 0xF9226E4e251b29Eda3A9b0542c3ef6f3e6EA3D48;
        token = IBEP20(0xde195b269752Ee554C9f8eeE2C0A16A269d1D0E7);
        BUSD = IBEP20(0x8840DD8080b4ddDc1D0a5C2A825C96D127c43FcD);
        charitywallet = 0xe6EA06cEE5689dB44DBF2f8de9Efe86ed5504a40;
        tokenPrice = 20;
        minAmount = 5000;
        maxSell = 1 * 10 ** 12 * 10 ** 18;
        launchTime = block.timestamp + 1 hours;
    }
    
    receive() external payable{}
    
    function buyTokenBUSD(address _referrer,uint256 plan,uint256 Amount)  public {
        require(plan>=0 && plan<=3,"Only # plans available");
        require(busdtotoken(Amount) >= minAmount,"cannot buy less than 5000 token");
        require(block.timestamp < launchTime,"BEP20: PreSale over");
        uint256 numberOfTokens = busdtotoken(Amount);
        require(soldToken.add(numberOfTokens) <= maxSell,"BEP20: Amount exceed preSale limit");
        require(!users[msg.sender].Alreadybought,"you can only buy once");
        if (users[msg.sender].claiminBusd == true){
            uint256 refBUSDAmount = Amount.mul(15).div(100);
            users[msg.sender].canclaimBUSDAmount = refBUSDAmount;
            Amount = Amount.sub(refBUSDAmount);
            BUSD.transferFrom(msg.sender, address(this), refBUSDAmount);
        }
        BUSD.transferFrom(msg.sender, owner, Amount);
        users[msg.sender].Alreadybought = true;
        users[msg.sender].isExist = true;
        users[msg.sender].referrer = _referrer;
        users[msg.sender].selectedplan = plan;
        users[msg.sender].claimtime = timelock[plan];
        users[msg.sender].boughtamount = numberOfTokens;
        users[msg.sender].usertimelockBonus = numberOfTokens.mul(timelockBonus[plan]).mul(1e18).div(10000);
        users[_referrer].referredamount = users[_referrer].referredamount.add(busdtotoken(Amount));
        token.transferFrom(owner, address(this), users[msg.sender].usertimelockBonus);
        balances[msg.sender] = balances[msg.sender].add(numberOfTokens.mul(1e18));
        token.transferFrom(owner, address(this), numberOfTokens.mul(1e18));
        
        uint256 multiplier = 0;
        if(busdtotoken(Amount) >= 150000 && busdtotoken(Amount) < 300000){
	        multiplier = 2;
        }else if(busdtotoken(Amount) >= 300000 && busdtotoken(Amount) < 500000){
	        multiplier = 3;
        }else if(busdtotoken(Amount) >= 500000 && busdtotoken(Amount) < 1000000){
	        multiplier = 5;
        }else if(busdtotoken(Amount) > 1000000){
	        multiplier = 8;
        }
        if (multiplier != 0 ){
	        balances[msg.sender] = balances[msg.sender].add(numberOfTokens.mul(1e18));   
	        balances[msg.sender] = balances[msg.sender].add(numberOfTokens.mul(multiplier).mul(1e18).div(100));
	        uint256 temp = numberOfTokens.mul(multiplier).mul(1e18).div(100);
	        token.transferFrom(owner, address(this), temp);
        }   
        emit BuyToken(msg.sender, balances[msg.sender]);
    }
  


    // to claim token after launch => for web3 use
    function claim() public {
        require(block.timestamp >= launchTime,"BEP20: Can not claim before launch");
        require(claimed[msg.sender] == false,"BEP20: Already claimed");
        require(block.timestamp >= launchTime+users[msg.sender].claimtime , "cannot claim before selectedplan time");
        require(balances[msg.sender] > 0 || users[msg.sender].referredamount > 0 , "You haven't tokens to claim");
        require(!users[msg.sender].claimed,"you can only claim once");
        uint256 userBalance = balances[msg.sender];
        
        uint multiplier = 0;
        if(users[msg.sender].referredamount >= minAmount && users[msg.sender].referredamount <= 100000 ){
            multiplier = referralPercent[0];
        }else if(users[msg.sender].referredamount >= 100001 && users[msg.sender].referredamount <= 500000 ){
	        multiplier = referralPercent[1];
        }else if(users[msg.sender].referredamount >= 500001 && users[msg.sender].referredamount <= 1000000 ){
    	    multiplier = referralPercent[2];
        }else if(users[msg.sender].referredamount >= 500001 && users[msg.sender].referredamount <= 1000000 ){
            multiplier = referralPercent[3];
        }
        if (multiplier != 0){
            uint256 userReferredBalance = users[msg.sender].referredamount.mul(multiplier).div(100).mul(1e18);
            token.transferFrom(owner, address(this), userReferredBalance);
            token.transfer(msg.sender,userReferredBalance);
        }
        
        if (userBalance > 0){
             token.transfer(msg.sender, userBalance);
        }
        if(users[msg.sender].selectedplan != 3){
            token.transfer(msg.sender,users[msg.sender].usertimelockBonus);
        }
        claimed[msg.sender] = true;
        balances[msg.sender] = 0;
        emit ClaimToken(msg.sender, userBalance);
    }
    
    function ClaimBusd() public {
        require(users[msg.sender].referredamount > 0,"You haven't balance to claim");
        require(users[msg.sender].claiminBusd,"You can not claim BUSD");
        uint256 userReferredBalance = users[msg.sender].canclaimBUSDAmount; 
        users[msg.sender].claimedBusd = users[msg.sender].claimedBusd.add(userReferredBalance);
        BUSD.transferFrom(address(this), msg.sender, userReferredBalance);
        users[msg.sender].canclaimBUSDAmount = 0;
        emit ClaimToken(msg.sender, userReferredBalance);
        
    }
    // to check number of token for given BNB
    function busdtotoken(uint256 _amount) public view returns(uint256){
        uint256 numberOfTokens = _amount.mul(tokenPrice).div(1e18);
        return numberOfTokens;
    }
    function setBUSDClaim(address buyer,bool canclaimBUSD) public onlyOwner() {
        users[buyer].claiminBusd = canclaimBUSD;
    }
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner{
        tokenPrice = _price;
    }
    
    function setMinAmount(uint256 _amount) external onlyOwner{
        minAmount = _amount;
    }
    
    function setMaxAmount(uint256 _amount) external onlyOwner{
        maxAmount = _amount;
    }
    
    function setLaunchTime(uint256 _time) external onlyOwner{
        launchTime = _time;
    }
    
    function setMaxSell(uint256 _amount) external onlyOwner{
        maxSell = _amount;
    }
    
    function setReferralPercent(uint256 [] memory _percent) external onlyOwner{
        referralPercent[0] = _percent[0];
        referralPercent[1] = _percent[1];
        referralPercent[2] = _percent[2];
        referralPercent[3] = _percent[3];
    }
    
    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    // to draw funds for liquidity
    function transferFunds() external onlyOwner returns(bool){
        owner.transfer(address(this).balance);
        return true;
    }
    
    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }
    
    function contractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.allowance(owner, address(this));
    }
    
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