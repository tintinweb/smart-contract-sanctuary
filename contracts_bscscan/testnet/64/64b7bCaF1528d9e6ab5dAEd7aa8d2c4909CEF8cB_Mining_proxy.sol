// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


interface IBCL{
    function holder_n() external view returns(uint256);
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
interface IMdexFactory {
    //event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    //function feeTo() external view returns (address);

    //function feeToSetter() external view returns (address);

    //function feeToRate() external view returns (uint256);

    //function initCodeHash() external view returns (bytes32);

    // function getPair(address tokenA, address tokenB) external view returns (address pair);

    // function allPairs(uint) external view returns (address pair);

    // function allPairsLength() external view returns (uint);

    // function createPair(address tokenA, address tokenB) external returns (address pair);

    // function setFeeTo(address) external;

    // function setFeeToSetter(address) external;

    // function setFeeToRate(uint256) external;

    // function setInitCodeHash(bytes32) external;

    // function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    // function pairFor(address tokenA, address tokenB) external view returns (address pair);

     function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB);

    // function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    // function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    // function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    // function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    // function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}


IMdexFactory constant factory = IMdexFactory(0xb0b670fc1F7724119963018DB0BfA86aDb22d941);
 
address constant bcl_addr=0x58efC89C4946AF64cdbF13A9BdCc2e6868315A53;
address constant base=0x65AaC413BE6e1845240d1Cd6541F890E6DABF6d2;  // base token, wBNB, decimals = 18 , BNB decimal = 8
address constant USDT = 0x55d398326f99059fF775485246999027B3197955;

address constant platform = 0x6F3ae4ea9aEE993aADba93A0AA2E5E2124FA1c56;
address constant taibao = 0x6F3ae4ea9aEE993aADba93A0AA2E5E2124FA1c56;
address constant node = 0x6F3ae4ea9aEE993aADba93A0AA2E5E2124FA1c56;
address constant sub_node =0x6F3ae4ea9aEE993aADba93A0AA2E5E2124FA1c56;

 library UserData{
    struct UserInfo{
        uint256 power; // computing power
        uint256 stakeAmount;
        uint256 staticRewards;
        uint256 staticRewards_claimed;
        uint256 dynamicRewards;
        uint256 dynamicRewards_claimed;
        address invitor;
        uint256 value; // in USDT at deposit time
        uint256 level;

    }
    
    struct slot{
        uint[10] weightedPower;
        uint[10] amount_main; // mainnet coin required
        uint[10] amount_bcl;  // actually staked
        uint[10] portion; // value portion of BCL
        uint[10] timestamp; // stake time or last rewards update time;
        uint[10] assetIds;
        uint[10] values; // in USDT at deposit time
    }
 }

 library Tools{
     // input token portion percent, >= 20
    function calculateComputingPower(uint256 portion) external pure returns(uint256){
        require(portion>=20 && portion <=100, "unsupported portion");
        uint256 computingPower = (1000 + 25 *(portion-20))/10;
        return computingPower;
    } 
    
    /*

    * input: mainToken address,
             BCL token amount,
             portion percent, BCL
      return: token amount needed in its own decimals
    */
    function calMainTokenRequired(address mainToken ,uint256 bcl_amount, uint256 portion) external view returns(uint256){
        require(portion<=100,"invalid portion percent");
        uint bcl_price = getPrice(bcl_addr, base);        
        uint token_price = getPrice(mainToken, base);
        
        uint256 value0 =  bcl_price * bcl_amount / 1e9;  // bcl amount equivalent wBNB amount
        uint256 value1 = value0 * (100-portion) / portion; // maintoken amount equivalnet wBNB amount
        uint d = 10**IBCL(mainToken).decimals();

        uint256 token_amount = value1 * d / token_price;
        
        return token_amount;
    }
    
    /*
    * input: mainToken address
             maintoken amount,
             maintoken portion,
        return bcl_amount required, with decimal = 9
    */
    function calBCLrequired(address mainToken, uint256 mainAmount, uint256 portion) external view returns(uint256){
        require(portion<=100,"invalid portion percent");
        uint256 bcl_price = getPrice(bcl_addr, base);        
        uint256 token_price = getPrice(mainToken, base);
        uint d = 10**IBCL(mainToken).decimals();
        
        uint256 bcl_amount =  mainAmount * token_price / portion * (100-portion)  * 1e9 / (bcl_price *d);
        return bcl_amount;
    }
    
   /**
    * get price tokenB/tokenA, i.e. amount of wBNB / amount of tokenA, with no decimals
    * return price rate with 18 decimals
   */ 
   function getPrice(address tokenA, address tokenB) internal view returns(uint256){
       (uint256 amount_A, uint256 amount_B) = factory.getReserves(tokenA, tokenB);
       uint256 d_a = 10**IBCL(tokenA).decimals();
       uint256 d_b = 10**IBCL(tokenB).decimals();
       uint256 price = amount_B *d_a * 1e18 /(d_b * amount_A);
       return price;
       
   }
   
  
    
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./libs.sol";

 contract Mining_proxy {
     using Address for address;
     
     // 12 tokens and BNB coinbase supported on BSC, notice the decimals
    mapping(uint256=>address) public Assets; // 12 tokens
     
    IBCL public bcl;

    bool public isAudit = false;
    uint public TotalRewards_static;
    uint public TotalRewards_dynamic;

    uint public rewardPerLPStored;
    uint public lastUpdateTime;
    uint public DURATION = 365 days;
    uint public miningEpoch; 
    
    
    uint public init_time_lp;
    bool public initiated;
    
    mapping(uint=>uint[5]) public dynamicRatio;

    
    mapping(address=>uint) public rewards; // user static rewards to claim
    mapping(address=>uint) public userRewardPerLpPaid;
    mapping(address=>UserData.UserInfo) public userInfo; // user info for LP mining pool
    
  
    uint public rewardRate = uint(1680000 * 1e9) / (365 days * 2); // reward rate by second
   
    
   
    address public owner;

    
       
    uint256 public ratio = 30; // mining ratio for production, varies with holders number
    uint256 public totalMiningPower; // whole network computing power
    uint256 public TVL; // total vault locked, BCL token amount
    
    mapping(address=>UserData.slot) userSlot; 
    
    // token address => (user=>amount)
    mapping(address=>mapping(address=>uint)) public AssetUserRequired;
    // BNB required for each user
    mapping(address=>uint) public BNBrequired; 
    
    mapping(address => uint) public upgradeCost;
    
    address public sync;
    
    address public delecall_1;
    address public delecall_2;
    address public delecall_3;
    address public delecall_4;
    

    event StakeLp(address indexed user, uint indexed amount);
    event ExitLp(address indexed user, uint indexed amount);
    
     
    event BondRefer(address indexed user, address indexed invitor);
    event Stake(address indexed user, uint indexed amount, uint indexed assetId);
    event Exit(address indexed user, uint indexed amount, uint indexed assetId);
    
    event ClaimStatic(address indexed user, uint indexed amount);
    event ClaimDynamic(address indexed user, uint indexed amount);
    
    
    
    
    modifier onlyOwner(){
        require(msg.sender==owner,"not owner");
        _;
    }


 
    
  
    // adjust productive ratio with holder number
    modifier updateRatio(){
        uint n = bcl.holder_n();
        
        if(n<=500){ratio = 30;}
        else if(n<=2000){ratio = 50;}
        else if(n<=5000){ratio = 70;}
        else{ratio = 100;}
        
        _;
    }
    
    










    constructor(){
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwner) external onlyOwner{
        owner = newOwner;
    }
    
    
    // initializing procedure
    function initiate(uint256 init_time) external onlyOwner{
        initiated = true;
        require(block.timestamp < init_time,"initial time should be later than now");
        init_time_lp = init_time;
        miningEpoch = init_time_lp + DURATION * 2;
        
        dynamicRatio[1] = [9,11,13,15,17];
        dynamicRatio[4] = [0,6,7,8,9];
        dynamicRatio[7] = [0,0,5,6,7];
        dynamicRatio[10] = [0,0,0,4,5];
        dynamicRatio[20] = [0,0,0,0,2];
        
        Assets[1] = USDT;
        
    
    }
   
    function setAssets(uint id, address token) external onlyOwner{
        Assets[id] = token;
    }
    
    
    function setSync(address SYNC) external onlyOwner{
        sync = SYNC;
    }
    
    
    

//-------------------------------------------Mining Tools------------------------------------------------------------------
    
  
   
    function calculateStaticReward(address _user) internal view returns (uint256){
        UserData.UserInfo memory user = userInfo[_user];

        if (user.invitor == address(0) ||user.power == 0 ){
            return 0;
        }
   
        return 
            user.power * (rewardPerLP() - userRewardPerLpPaid[_user]) / 1e18 + rewards[_user];
    }
    
    function lastTimeRewardApplicable() internal view returns (uint256) {
        if (block.timestamp >= miningEpoch){
            return miningEpoch;
        }else{
            return block.timestamp;
        }
    }

    
    function rewardPerLP() internal view returns (uint256) {
      if (TVL == 0){
            return rewardPerLPStored;
        }
        return
            rewardPerLPStored +(lastTimeRewardApplicable() - lastUpdateTime)*(rewardRate)* 1e18 / totalMiningPower;
    }
//---------------------------------------------User-End methods------------------------------------------------------


 
  
    
   
    
    /*
    * choose one main asset from 12 tokens;
      input BCL value portion;
      input BCL amount;
      
      get real time price data;
      check balance and execute stake;
      update user info and state variables;
    */
    
    
    function setDeleAdress (address addr1, address addr2, address addr3, address addr4) public onlyOwner {
        delecall_1 = addr1;
        delecall_2 = addr2;
        delecall_3 = addr3;
        delecall_4 = addr4;
    }
    
    
    function DelegateCallstakeWithExactBCL(uint assetId, 
           uint BCLportion, 
           uint BCLamount, 
           address invitor,
           uint slotId) external {
           Address.functionDelegateCall(delecall_1,abi.encodeWithSignature("stakeWithExactBCL(uint256,uint256,uint256,address,uint256)",assetId,BCLportion,BCLamount,invitor,slotId));
    }
    
    
    function DelegateCAllstakeWithExactMain(
            uint assetId,
            uint mainPortion,
            uint mainAmount,
            address invitor,
            uint slotId)
        external {
        Address.functionDelegateCall(delecall_1,abi.encodeWithSignature("stakeWithExactMain(uint256,uint256,uint256,address,uint256)",assetId,mainPortion,mainAmount,invitor,slotId));
        }
    
    
    
      
    
    function DelegateCheckStatic() public {
    Address.functionDelegateCall(delecall_1,abi.encodeWithSignature("checkStatic()"));
    }
    
    function DelegateCheckStatic_slot(uint slotId) public {
    Address.functionDelegateCall(delecall_1,abi.encodeWithSignature("checkStatic_slot(uint256)",slotId));
    }
    
    
    function DelegateStakeExactBCLwithBNB(uint256 BCLportion, 
                          uint BCLamount, 
                          address invitor,
                          uint slotId) public payable{
    Address.functionDelegateCall(delecall_2,abi.encodeWithSignature("stakeExactBCLwithBNB(uint256,uint256,address,uint256)",BCLportion,BCLamount,invitor,slotId));
    }
                          
    function DelegateStakeBCLwithExactBNB(uint256 mainPortion,
                                  uint256 mainAmount,
                                  address invitor,
                                  uint slotId)public payable{
    Address.functionDelegateCall(delecall_2,abi.encodeWithSignature("stakeBCLwithExactBNB(uint256,uint256,address,uint256)",mainPortion,mainAmount,invitor,slotId));                          
    }
    
   
    
    function DelegateUpgrade(uint256 amount) public{
        Address.functionDelegateCall(delecall_3,abi.encodeWithSignature("upgrade(uint256)",amount));
    }
    
    
    
  
    
    // view user accrued static rewards
    function userAccruedStatic(address user) public view returns(uint256){
        require(userInfo[user].power>0,"023");
        uint amount = calculateStaticReward(user);
        require(amount>0,"024");
        uint staticReward = amount * ratio / 100;
        
        uint userPower = userInfo[user].power;
        uint actPower;
        
        UserData.slot memory user_slot = userSlot[user];
        
        // iterate over 10 slots
        for(uint i=0; i<10;++i){
            if(user_slot.assetIds[i]==13 && BNBrequired[user] <= address(user).balance ){
                    actPower += user_slot.weightedPower[i];
                    user_slot.timestamp[i] = block.timestamp;
            }
            else if(IBCL(Assets[user_slot.assetIds[i]]).balanceOf(user) >= AssetUserRequired[Assets[user_slot.assetIds[i]]][user])
                {
                    actPower += user_slot.weightedPower[i];
                    user_slot.timestamp[i] = block.timestamp;
                }
        }
        
        uint reward = staticReward * actPower / userPower;
        return reward; 
    }
    
    
  
    
    
    function claimStatic_toWallet() public{
        require(userInfo[msg.sender].staticRewards>0);
        uint256 temp = userInfo[msg.sender].staticRewards;
        userInfo[msg.sender].staticRewards = 0;
        
        uint256 temp2 = temp * 99/100;
        userInfo[msg.sender].staticRewards_claimed += temp2;
        
        bcl.transfer(msg.sender, temp2);
        
        emit ClaimStatic(msg.sender,temp2);

    }
    
    function claimDynamic_toWallet() public{
        require(userInfo[msg.sender].dynamicRewards>0);
        uint256 temp = userInfo[msg.sender].dynamicRewards;
        userInfo[msg.sender].staticRewards = 0;
        
        uint256 temp2 = temp * 99/100;
        userInfo[msg.sender].dynamicRewards_claimed += temp2;
        
        bcl.transfer(msg.sender, temp2);
        
        emit ClaimDynamic(msg.sender,temp2);

    }
    
    

    
    // query slot info
    function queryUserSlot(address user, uint slotId) external view returns(
        uint weightedPower,
        uint amount_bcl,
        uint amount_main,
        uint timestamp,
        uint portion,
        uint assetId,
        uint valueInU){
        
        weightedPower = userSlot[user].weightedPower[slotId];
        amount_bcl = userSlot[user].amount_bcl[slotId];
        amount_main = userSlot[user].amount_main[slotId];
        timestamp = userSlot[user].timestamp[slotId];
        portion = userSlot[user].portion[slotId];
        assetId = userSlot[user].assetIds[slotId];
        valueInU = userSlot[user].values[slotId];
        
    }
    
    
   
    
    function sweep() external onlyOwner{
        bcl.transfer(msg.sender, bcl.balanceOf(address(this)));
    }
    
    function sweepBNB() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function saveStuckTokens(address token) external onlyOwner{
        uint256 temp = IBCL(token).balanceOf(address(this));
        IBCL(token).transfer(msg.sender, temp);
        }
    
     // To recieve BNB
    receive() external payable {}

    

 }

