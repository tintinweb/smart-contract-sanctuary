/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

//import "hardhat/console.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     * - the calling contract must have an BNB balance of at least `value`.
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

//import './interfaces/IPancakePair.sol';
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}



interface IPancakeRouter02 {
   function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPool {
    function notifyReward() external payable ;
}

interface ICakeVaultFactory {
    function fee() external view returns(uint);
    function pancake_router() external view returns(address);
    function toFee() external view returns(uint);    
}

 
 contract BakedVault  {
    using Address for address;
    using SafeMath for uint;

    address public factory;
    address public factory_owner;

    uint public locked = 0;

    uint public withdrawFeeLocked = 0;

    uint public liquidityAdmin = 0;
    uint public liquiditySC = 0;

    address public owner;
    address public token;
    address public baked_address; 

    uint public softCap;
    uint public hardCap;
    uint public start_date;
    uint public end_date;
    uint public rate;               // coin sale rate 1 USDT = 1 BAKED (rate = 1e18) <=> 1 USDT = 10 BAKED (rate = 1e19) 
    uint public min_allowed;
    uint public max_allowed;        // Max USDT 
    uint public collected;          // collected USDT
    uint public lock_duration;      // duration wished to keep the LP tokens locked
    uint public withdrewToken;
    uint public min_Baked_Token = 5000 * 1e18;
    bool public doRefund = false;
    bool public adminApproveStatus;
    uint256 public presaleTokenAmount;
    uint256 public totalTokenAmount;
    uint256 public verstingPercentage;
    uint256 public playSharePercent;
    uint256 public playShareFeeAmount;
    mapping(address => uint256) public lastVestingTime;
    mapping(address => uint256) public releseToken;
    mapping(address => uint256) public vesting;
    mapping(address => bool) public adminWhitelisted;
    mapping(address => uint256) public ticket;
    uint256 public liquidityPercentage;
    uint256 public remainingUsdt;

    address public liquidityAddress;

    uint256 public pancake_rate;
    uint256 public pancake_percentage;

    uint public unlock_date = 0;

    uint256 public tokeReleseStatusManual = 0;
    uint256 public tokeReleseStatusSC = 0;

     uint256 public usdtTokenAmt;
     uint256 public campTokenAmt;

    uint256 public campaignOwnerWiyhdrawStatus = 0;

    uint256 public panckaeDuration;

    uint256 public participantCount = 0;




    IBEP20 public USDC = IBEP20(0xFC0251249704ad340cc7539aF56C56f7d613D6Ac);


    
    constructor() public{
        factory = msg.sender;
    }
    
    mapping(address => uint) public participant;
    mapping(address => uint256) public participantBalance;
    
    modifier only_factory_authorised(){
        require(owner == msg.sender || factory_owner == msg.sender,'Error:Unauthorised');
        _;
    }
    
    // Initilaize  a new campaign (can only be triggered by the factory contract)
    function initilaize(uint[] calldata _data,address _token,address _owner_Address, address factory_owner_,address _liquidity_Address,uint256 _vesting_Percentage,uint256 _lock_Duration, uint256 _total_Token_Amount,uint256 _playShare_percent) external returns (uint){
      require(msg.sender == factory,'You are not allowed to initialize a new Campaign');
      owner = _owner_Address; 
      softCap = _data[0];
      hardCap = _data[1];
      start_date = _data[2];
      end_date = _data[3];
      rate = _data[4]; 
      min_allowed = _data[5];
      max_allowed = _data[6];
      presaleTokenAmount = _data[7];
      pancake_percentage = _data[8];
      pancake_rate = _data[9];
      panckaeDuration = _data[10];
      token = _token;                                 
      factory_owner = factory_owner_;
      adminApproveStatus=false;
      liquidityAddress = _liquidity_Address;
      lock_duration = _lock_Duration;
      totalTokenAmount = _total_Token_Amount;
      verstingPercentage = _vesting_Percentage;
      playSharePercent = _playShare_percent;
      
    }

    
    modifier onlyAdmin() {
        require(msg.sender == factory_owner,'error : you are not the owner');
        _;
    } 

    function adminApproval() public onlyAdmin{
        adminApproveStatus = true;
    }

    // get the adminApproveStatus
    function campaignApprovalStatus() public view returns(bool){
        return adminApproveStatus;
    }

    // Admin can add whitelisted people by manually
    function adminWhitelist(address _addr, uint256 _ticket) public onlyAdmin {
        require(campaignApprovalStatus(),"The campaign is not Approved yet");
        adminWhitelisted[_addr] = true;
        ticket[_addr] = _ticket;
    }
    // Admin add whitelisted people by bulk transaction
    function batchAdminWhitelisted(address[] memory _addr, uint256[] memory _tickets ) public onlyAdmin{
        require(_addr.length == _tickets.length);
        for (uint i = 0; i < _addr.length; i++) {
            if (_addr[i] != address(0)) {
                adminWhitelisted[_addr[i]]= true;
                ticket[_addr[i]] = _tickets[i];
            }
            
        }
    }
    // Check Admin whitelisted true or false
    function checkWhitelisted(address _addr) public view returns(bool){
        if(adminWhitelisted[_addr] == true){
            return true;
        }
        else{
            return false;
        }
    }

  
    // Check whether the campaign failed
    function failed() public view returns(bool){
        if((block.timestamp >= end_date) && (softCap > collected)){
            return true;
            
        }
        return false;
    }

    // Check wether the campaign is Upcoming
    function upComing() public view returns(bool){
        if(block.timestamp < start_date){
            return true;
        }
        return false;
    }

    // Check wheteher the campaign completed
    function success()public view returns(bool){
        if((collected >= softCap && block.timestamp >= end_date) || (collected >= hardCap)){
            return true;
        }
        return false;
    }
    

    // Checks whether the campaign is still Live
    function isLive() public view returns(bool){
        if((collected >= hardCap)) return false;
        if(collected >= softCap && block.timestamp >= end_date) return false;
        
        if((adminWhitelisted[msg.sender] == true)) {
            if(block.timestamp >= start_date.sub(300)) return true;
        }

        if((block.timestamp < start_date )) return false; 
        if((block.timestamp >= end_date)) return false;
       
        return true;
    }

    modifier campaignConclude() {
        require((failed() || doRefund || locked == 1), "error : allowed withdraw in case of campaign failed or liquidity couldn't locked within 24 hours from end date.");
        require(msg.sender == owner,'error : you are not the owner');
        _;
    }   

    // participants can buy tokens using USDT
    function buyTokens(uint256 _amount) public returns (uint){
        require(campaignApprovalStatus(),"The campaign is not Approved yet");
        require(isLive(),"campaign is not live");

        if(participant[msg.sender] == 0){
            participantCount++;
        }

        if((checkWhitelisted(msg.sender) == true)){
            uint256 Ticket = 0;
            Ticket =  ticket[msg.sender];
            require((_amount >= min_allowed) && (_amount <= max_allowed) && (getGivenAmount(msg.sender).add(_amount.mul(1e18)) <= max_allowed.mul(Ticket).mul(1e18)),"The contract has insufficent funds or you are not allowed");
            participant[msg.sender] = participant[msg.sender].add(_amount);
            participantBalance[msg.sender] = participantBalance[msg.sender].add(_amount.mul(1e18));
            collected = (collected).add(_amount);
            IBEP20(USDC).transferFrom(msg.sender, address(this), _amount * 1e6 );
            return 1;
        }
        else{
            require((_amount >= min_allowed) && (getGivenAmount(msg.sender).add(_amount.mul(1e18)) <= max_allowed.mul(1e18)),"The contract has insufficent funds or you are not allowed");
            participant[msg.sender] = participant[msg.sender].add(_amount);
            participantBalance[msg.sender] = participantBalance[msg.sender].add(_amount.mul(1e18));
            collected = (collected).add(_amount);
            IBEP20(USDC).transferFrom(msg.sender, address(this), _amount * 1e6 );
            return 1;
        }
    }

     // Allows Participants to withdraw funds in case of campaign fails
    function withdrawFunds() public returns(uint){
        require(failed() || doRefund, "error : campaign didn't fail");
        require(participant[msg.sender] >0 ,"error : you didn't participate in the campaign or Allready withdrawed");
        uint withdrawAmount = participant[msg.sender];
        participant[msg.sender] = 0;

       IBEP20(USDC).transfer(msg.sender, withdrawAmount * 1e6 );
    }

    //allow admin to withdraw remaining asset, if campaign fails
    function withDrawRemainingAssetsFailed() public campaignConclude {
        require(campaignOwnerWiyhdrawStatus == 0 ,"Campaign owner alredy withdraw the assets");
        require(failed() || doRefund, "error : campaign didn't fail");
            uint256 totalToken = 0;
            totalToken = IBEP20(address(token)).balanceOf(address(this));
            IBEP20(token).transfer(msg.sender,totalToken);
            campaignOwnerWiyhdrawStatus=1;

    }

    // admin lock liquidity through manual
    function adminAddLiquidityManual() public only_factory_authorised {
        require((locked == 0) && (liquidityAdmin == 0),"Liquidity is already locked");
        require(!isLive(),"Presale is still live");
        require(!failed(),"Presale failed , can't lock liquidity");
        require(msg.sender == owner,"You are not the owner");
        IBEP20(USDC).transfer(liquidityAddress, collected.mul(1e6) );
        locked = 1;
        liquidityAdmin=1;       
    }
    //  admin relese token after adding liquidity manual
    function adminReleseToken() public only_factory_authorised {
        require((locked == 1) && (liquidityAdmin == 1),"Liquidity not locked yet");
        require(tokeReleseStatusManual == 0 ,"Token alredy relesed");
        tokeReleseStatusManual = 1; 
    }

    // admin withdraw remaining asset, if campaign success and add liquidity manual
    function manualWithDrawRemainingAssets() public campaignConclude {
            require(campaignOwnerWiyhdrawStatus == 0 ,"Campaign owner alredy withdraw the assets");
            require(locked == 1,"Liquidity not locked yet");
            require(tokeReleseStatusManual == 1,"Admin not relesed the tokens yet");

                uint256 totalToken = 0;
                playShareFeeAmount =((collected.mul(rate).mul(playSharePercent)).div(100));
                
                totalToken = totalTokenAmount
                                .sub(collected.mul(rate))
                                .sub(playShareFeeAmount);
                IBEP20(token).transfer(msg.sender,totalToken);
                campaignOwnerWiyhdrawStatus =1;

    }
    //participant withdraw token, if campaign sucess and liquidity manual
    function manualWithdrawTokens() public returns (uint){
        require(locked == 1,"liquidity is not yet added");
        require(participant[msg.sender] >0 ,"error : you didn't participate in the campaign or You withdraw all Tokens allready");
        require(lastVestingTime[msg.sender].add(lock_duration) <= block.timestamp,"Tokens allredy climed wait for realese Tokens");
        require(tokeReleseStatusManual == 1,"Admin not relese the token yet");
            if(vesting[msg.sender] == 0){
                uint256 totalOwnedByParticipant =(calculateAmount(participant[msg.sender])).mul(1e18);
                uint256 VP = (verstingPercentage.mul(1e18)).div(100);
                uint256 vestingAmount = (totalOwnedByParticipant.mul(VP)).div(1e18);
                releseToken[msg.sender] = vestingAmount;
                IBEP20(address(token)).transfer(msg.sender,releseToken[msg.sender]);
                withdrewToken = withdrewToken.add(vestingAmount);
                participantBalance[msg.sender] = participantBalance[msg.sender].sub((releseToken[msg.sender]).div(rate).mul(1e18));
               // participant[msg.sender] = (participant[msg.sender].mul(1e18)).sub(releseToken[msg.sender]);
                lastVestingTime[msg.sender] = block.timestamp;
                vesting[msg.sender] = 1;
            }
            else{
                if((participantBalance[msg.sender]) >= (releseToken[msg.sender].div(rate).mul(1e18))){
                     withdrewToken = withdrewToken.add(releseToken[msg.sender]);
                    require(IBEP20(address(token)).transfer(msg.sender,releseToken[msg.sender]),"can't transfer");
                    participantBalance[msg.sender] = participantBalance[msg.sender].sub((releseToken[msg.sender]).div(rate).mul(1e18));
                   // participant[msg.sender] = participant[msg.sender].sub(releseToken[msg.sender]);
                    lastVestingTime[msg.sender] = block.timestamp;
                }
                else{
                    require(IBEP20(address(token)).transfer(msg.sender,(participant[msg.sender].mul(rate))),"can't transfer");
                    //withdrewToken = 0;
                     participant[msg.sender] = 0;
                     participantBalance[msg.sender] = 0;
                }
            }

    }
        


    // Add liquidity to pancake can be only executed by authorised when the campaign completes
    function bakedVAULT() public only_factory_authorised returns(uint){
        require(locked == 0,"Liquidity is already locked");
        require(!isLive(),"Presale is still live");
        require(!failed(),"Presale failed , can't lock liquidity");
        require(softCap <= collected,"didn't reach soft cap");
        require(addLiquidity(),"Error for adding liquidity to pancakeswap");
        locked = 1;
        liquiditySC = 1;
        unlock_date = (block.timestamp).add(panckaeDuration);
        return 1;
    }

    function addLiquidity() internal returns(bool){

    usdtTokenAmt = collected.mul(pancake_percentage.mul(1e6)).div(100);
    campTokenAmt = (usdtTokenAmt.mul(pancake_rate)).div(1e18);
    // liquidityPercentage = (collected.mul(_liquidity_Percentage.mul(1e18)).div(100));
        if(pancake_rate > 0){

                IBEP20(address(token)).approve(0xD99D1c33F9fC3444f8101754aBC46c52416550D1,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                IBEP20(address(USDC)).approve(0xD99D1c33F9fC3444f8101754aBC46c52416550D1,0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

                    // IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1)).addLiquidity(address(token),address(USDT), collected.mul(rate),(collected.mul(pancake_rate.mul(1e18)).div(100)), 0, 0, address(this), block.timestamp + 100000000);
                IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1).addLiquidity(address(token),address(USDC),campTokenAmt,usdtTokenAmt,0,0, address(this), block.timestamp + 100000000);

            
            } else {
                doRefund = true;
            }
        
        return true;
    }

            // unlock liquidity provider (lp) tokens
    function unlock(address _LPT,uint _amount) public returns (bool){
        require(tokeReleseStatusSC == 0,"Admin not Not relese the tokens or alredy relesed");
        require(locked == 1 || failed(),'liquidity is not yet locked');
        require(liquiditySC == 1,"Liquidity is not yet added");
        require(address(_LPT) != address(token),'You are not allowed to withdraw tokens');
        require(block.timestamp >= unlock_date ,"can't receive LP tokens");
        require(msg.sender == owner,'You are not the owner');
        IBEP20(address(_LPT)).transfer(msg.sender,_amount);
        tokeReleseStatusSC = 1;
    }


    // Allow campaign owner witdraw remaining tokens, when,
    // Campaign fails.
    // Campaign Sucess
    function automaticWithDrawRemainingAssets() public campaignConclude {
        require(campaignOwnerWiyhdrawStatus == 0 ,"Campaign owner alredy withdraw the assets");
        require(liquiditySC == 1,"Not added liquidity yet");
        require(tokeReleseStatusSC == 1,"Token relese status is false");
        
        uint256 totalToken = 0;
                playShareFeeAmount =((collected.mul(rate).mul(playSharePercent)).div(100));

                remainingUsdt = (collected.mul(1e6)).sub(usdtTokenAmt);

                totalToken = totalTokenAmount
                                .sub(collected.mul(rate))       //collected by participants
                                .sub(playShareFeeAmount)       //playshare fee amount
                                .sub(campTokenAmt);             //collected by pancakeswap
                IBEP20(token).transfer(msg.sender,totalToken);
                IBEP20(USDC).transfer(msg.sender,remainingUsdt);
                campaignOwnerWiyhdrawStatus = 1;
         
    }


 // Participants withdraw funds when,
    // Liquidity is added and Campaign success admin manually aded liquidity
    // Here we are using vesting mechanisom to relese tokens
    function automaticWithdrawTokens() public returns (uint){
       // require(locked == 0,"Admin not Unlock LP tokens");
        require(participant[msg.sender] >0 ,"error : you didn't participate in the campaign or You withdraw all Tokens allready");
        require(lastVestingTime[msg.sender].add(lock_duration) <= block.timestamp,"Tokens allredy climed wait for realese Tokens");
        require(tokeReleseStatusSC == 1,"Admin not relese the token yet");
            if(vesting[msg.sender] == 0){
                uint256 totalOwnedByParticipant =(calculateAmount(participant[msg.sender])).mul(1e18);
                uint256 VP = (verstingPercentage.mul(1e18)).div(100);
                uint256 vestingAmount = (totalOwnedByParticipant.mul(VP)).div(1e18);
                releseToken[msg.sender] = vestingAmount;
                IBEP20(address(token)).transfer(msg.sender,releseToken[msg.sender]);
                withdrewToken = withdrewToken.add(vestingAmount);
                participantBalance[msg.sender] = participantBalance[msg.sender].sub((releseToken[msg.sender]).div(rate).mul(1e18));
               // participant[msg.sender] = (participant[msg.sender].mul(1e18)).sub(releseToken[msg.sender]);
                lastVestingTime[msg.sender] = block.timestamp;
                vesting[msg.sender] = 1;
            }
            else{
                if((participantBalance[msg.sender]) >= (releseToken[msg.sender].div(rate).mul(1e18))){
                     withdrewToken = withdrewToken.add(releseToken[msg.sender]);
                    require(IBEP20(address(token)).transfer(msg.sender,releseToken[msg.sender]),"can't transfer");
                    participantBalance[msg.sender] = participantBalance[msg.sender].sub((releseToken[msg.sender]).div(rate).mul(1e18));
                   // participant[msg.sender] = participant[msg.sender].sub(releseToken[msg.sender]);
                    lastVestingTime[msg.sender] = block.timestamp;
                }
                else{
                    require(IBEP20(address(token)).transfer(msg.sender,(participant[msg.sender].mul(rate))),"can't transfer");
                    //withdrewToken = 0;
                     participant[msg.sender] = 0;
                     participantBalance[msg.sender] = 0;
                }
            }

    }


    // Admin can withdraw playshare Fee amount using any wallet address
    function withdrawFee(address _addr) public onlyAdmin {
       // require(locked == 1,"liquidity is not yet added");
        require(withdrawFeeLocked == 0, "You already withdrawed");
        playShareFeeAmount =((collected.mul(rate).mul(playSharePercent)).div(100));
        IBEP20(token).transfer(_addr,playShareFeeAmount);
        withdrawFeeLocked = 1;
    
    }


    // Calculate tokens based on USDT amount
    function calculateAmount(uint _amount) public view returns(uint){
        return (_amount.mul(rate)).div(1e18);
    }
    
    // Gets remaining USDT to reach hardCap
    function getRemaining() public view returns (uint){
        return (hardCap).sub(collected);
    }

    // Check invested USDT in pre-sale
    function getGivenAmount(address _address) public view returns (uint){
        return participant[_address].mul(1e18);
    }

    // Get token symbol
    function getSymbol()public view returns(string memory){
        return IBEP20(token).symbol();
    }
    // Get token Name
    function getName()public view returns(string memory){
        return IBEP20(token).name();
    }
    // Get token decimals
    function getDecimal()public view returns(uint256){
        return IBEP20(token).decimals();
    }
    // Get token Total Supply
    function getTotalSupply()public view returns(uint256){
        return IBEP20(token).totalSupply();
    }

    
  
}

contract BakedVaultFactory  {

    using Address for address;
    using SafeMath for uint;

    address[] public campaigns;
    address public factory_owner;
    uint256 public playshare_percent;
    mapping(address=>address) public tokenCampaign;
    uint balance_required;   

            
    event CreateCampaign(address indexed _campaign_address, uint _index);
    
    constructor(uint256 _playshare_percent) public {
        factory_owner = msg.sender;
        playshare_percent = _playshare_percent;           
    }
    
    modifier only_factory_Owner(){
        require(factory_owner == msg.sender,'You are not the owner');
        _;
    }
    
    function createCampaign(uint[] memory _data,address _token,address _liquidity_address,uint256 _vesting_percentage,uint256 _lock_Duration) external returns (address campaign_address){

        
        require(_data[0] < _data[1],"Error :  soft cap can't be higher than hard cap" );
        require(_data[2] >= block.timestamp, "Error : start date must be higher than current date");
        require(_data[2] < _data[3] ,"Error :  start date can't be higher than end date");
        require(block.timestamp < _data[3] ,"Error : end date can't be higher than current date");
        require(_data[5] < _data[1],"Error : minimum allowed can't be higher than hard cap");
        require(_data[4] != 0,"Error : rate can't be null");

        uint256 totalTokenAmount = calculateTokenforManual( _data[4],_data[6],_data[7]);
        if((_data[8] >0) && (_data[9] >0)){

            require(_data[8] >= 0 && _data[8] <= 98, "Error : pancake liquidity ratio required between 1 to 98%");

            uint256 a = calculateTokenforAutomatic(_data[1],_data[4],_data[6],_data[8], _data[9]);
            uint256 Total = totalTokenAmount.add(a);
            bytes memory bytecode = type(BakedVault).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));
            assembly {
                campaign_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            
            BakedVault(campaign_address).initilaize(_data,_token,msg.sender, factory_owner,_liquidity_address,_vesting_percentage,_lock_Duration,Total,playshare_percent );
            campaigns.push(campaign_address);
            tokenCampaign[_token] = campaign_address;


         //   require(IBEP20(address(_token)).balanceOf(msg.sender) >= Total ,"You don't have sufficent token to create campaign");
            IBEP20(address(_token)).transferFrom(msg.sender,address(campaign_address),Total);
            emit CreateCampaign(campaign_address, campaigns.length);
            
            return campaign_address;
        }
        else{

            bytes memory bytecode = type(BakedVault).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(_token, msg.sender));
            assembly {
                campaign_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            
            BakedVault(campaign_address).initilaize(_data,_token,msg.sender, factory_owner,_liquidity_address,_vesting_percentage,_lock_Duration,totalTokenAmount,playshare_percent );
            campaigns.push(campaign_address);
            tokenCampaign[_token] = campaign_address;


            require(IBEP20(address(_token)).balanceOf(msg.sender) >= totalTokenAmount ,"You don't have sufficent token to create campaign");
            IBEP20(address(_token)).transferFrom(msg.sender,address(campaign_address),totalTokenAmount);
            emit CreateCampaign(campaign_address, campaigns.length);
            
            return campaign_address;
        }
        
    }

    function calculateTokenforManual(uint256 _data4 ,uint256 _data6 , uint256 _data7) public view returns(uint256){
        uint256 maximumWallet = _data6.mul(_data4);
        uint256 TokenAmount = _data7.add(maximumWallet);
        uint256 totalTokenAmount = TokenAmount.add((TokenAmount.mul(playshare_percent).div(100)));
        return totalTokenAmount;
    }
    function calculateTokenforAutomatic(uint256 _data1,uint256 _data4,uint256 _data6 ,uint256 _data8 , uint256 _data9) public view returns(uint256){

        uint256 a = _data1.add(_data6);
        uint256 b =  (a.mul(_data8.mul(_data9)).div(1e20)).mul(1e18) ;
        return b;
    }

    
}