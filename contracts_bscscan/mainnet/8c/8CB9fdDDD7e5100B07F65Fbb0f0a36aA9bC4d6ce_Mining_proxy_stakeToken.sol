/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

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
interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
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
library UserData{
    struct UserInfo{
        uint256 power; // computing power
        uint256 stakeAmount;
        uint256 staticRewards_claimed;
        uint256 dynamicRewards;
        uint256 dynamicRewards_claimed;
        address invitor;
        uint256 value; // in USDT at deposit time
        uint256 level;
        uint256 refer_n_direct;
        uint256 refer_n_node;
        
        uint256 nodeStakeAmount;
        uint256 nodePower;

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
interface IDatabase{
     function router() external view returns(address);
     function factory() external view returns(address);

     function bcl_addr() external view returns(address);
     function base() external view returns(address);
     function USDT() external view returns(address);
     function sync() external view returns(address);
     
     function platform() external view returns(address);
     function taibao() external view returns(address);
     function node() external view returns(address);
     function sub_node() external view returns(address);
 
 }
abstract contract Template{
     using Address for address;
     
     address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
 
     address public bcl_addr = 0x6CeB707e4f7C514E5900299107184C791B6FAc0E;
     address public base = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;  // base token, wBNB, decimals = 18 , BNB decimal = 8
     address public USDT = 0x55d398326f99059fF775485246999027B3197955;   // USDT Test token
     address public SYNC = 0x0C9cd9A6Bb56eE16cbD00e55B5e7d33CbB4855cd;
     address public platform = 0xa7ab1687BF7A6eF2E8D489948D6e0ae8CE50a77e;
     address public taibao = 0xB5C7C2a37C3f301247F29e0047ea1341D5eF6dD5;
     address public node = 0x5A4d28C7736892fDC4C79a3f6f971Ea1867601E6;
     address public sub_node =0x0df8fF0CB58FAd477E2ffe98E51E5d4fA7a9eDbe;
         
         
     
     // 12 tokens and BNB coinbase supported on BSC, notice the decimals
    mapping(uint256=>address) public Assets; // 12 tokens
    mapping(address=>uint256) public tokenPowerCoef;// token computing power coefficient
    

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
    // Upgrade SYNC dynamic rewards
    mapping(address => uint) public syncReward_toClaim;
    mapping(address => uint) public syncReward_claimed;
    
    // Upgrade BCL upgrade rewards
    mapping(address => uint) public bclReward_toClaim;
    mapping(address => uint) public bclReward_claimed;

    
    uint public n;
    address public delecall_1;
    address public delecall_2;
    address public delecall_3;
    address public delecall_4;

 }
abstract contract Template_mining is Template{
    
//-------------------------------------------Mining Tools------------------------------------------------------------------
    
  
   
    function calculateStaticReward(address _user) public view returns (uint256){
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
    function updateReward(address _user) internal {
        rewardPerLPStored = rewardPerLP();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_user != address(0)){
            rewards[_user]=calculateStaticReward(_user);
            userRewardPerLpPaid[_user]=rewardPerLP();
        }
    }
         
}
abstract contract Template_mining_plus is Template_mining{
    

//------------------------------------------- Tools------------------------------------------------------------------
    
    
    function calculateComputingPower(uint256 portion) public pure returns(uint256){
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
     function calMainTokenRequired(address mainToken ,uint256 bcl_amount, uint256 portion) public view returns(uint256){
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
     function calBCLrequired(address mainToken, uint256 mainAmount, uint256 portion) public view returns(uint256){
         require(portion<=100,"invalid portion percent");
         uint256 bcl_price = getPrice(bcl_addr, base);
         uint256 token_price = getPrice(mainToken, base);
         uint d = 10**IBCL(mainToken).decimals();

         uint256 bcl_amount =  mainAmount * token_price / portion * (100-portion)  * 1e9 / (bcl_price *d);
         return bcl_amount;
     }

     /**
      * get price tokenB/tokenA, 1 tokenA = ? tokenB
      * return price rate with 18 decimals
     */
     function getPrice(address tokenA, address tokenB) public view returns(uint256){
         if(tokenA == tokenB){
             return 1e18;
         }

         address pair = IPancakeFactory(factory).getPair(tokenA, tokenB);

         uint amount_A;
         uint amount_B;

         if(tokenA < tokenB){
            (amount_A,amount_B,) = IPancakePair(pair).getReserves();
        }else{
            (amount_B,amount_A,) = IPancakePair(pair).getReserves();
        }
         
         uint256 d_a = 10**IBCL(tokenA).decimals();
         uint256 d_b = 10**IBCL(tokenB).decimals();


         uint256 price = amount_B *d_a * 1e18 /(d_b * amount_A);
         return price;

     }
     

  
  
    // adjust productive ratio with holder number
    modifier updateRatio(){
        uint n = IBCL(bcl_addr).holder_n();
        
        if(n<=500){ratio = 30;}
        else if(n<=2000){ratio = 50;}
        else if(n<=5000){ratio = 70;}
        else{ratio = 100;}
        
        _;
    }
    
}



contract Mining_proxy_stakeToken is Template_mining_plus{
     


    event StakeLp(address indexed user, uint indexed amount);
    event ExitLp(address indexed user, uint indexed amount);
    
     
    event BondRefer(address indexed user, address indexed invitor);
    event Stake(address indexed user, uint indexed amount, uint indexed assetId);
    event Exit(address indexed user, uint indexed amount, uint indexed assetId);
    
    event ClaimStatic(address indexed user, uint indexed amount);
    event ClaimDynamic(address indexed user, uint indexed amount);

     /*
    * choose one main asset from 12 tokens;
      input BCL value portion;
      input BCL amount;
      
      get real time price data;
      check balance and execute stake;
      update user info and state variables;
    */
    function stakeWithExactBCL(uint256 assetId, 
                   uint256 BCLportion, 
                   uint BCLamount, 
                   address invitor,
                   uint slotId) external  updateRatio{
        require(assetId>=1 && assetId !=13 && BCLportion >=20 && BCLportion < 100, "001");
        
        
        require(BCLamount + userInfo[msg.sender].stakeAmount <= 500 * 1e9, "exceed stake limit!!!");
        updateReward(msg.sender);
        
        // first-time user, bond reference relation
        if(userInfo[msg.sender].invitor==address(0)){
            require(invitor==address(this) || userInfo[invitor].invitor!=address(0), "003");
            userInfo[msg.sender].invitor = invitor;
            emit BondRefer(msg.sender, invitor);
            
            userInfo[invitor].refer_n_direct += 1;
            
            address temp_user = invitor;
            
            for(uint i=0;i<n;++i){
                if(temp_user==address(0) || temp_user == address(this)){
                    break;
                }else{
                    userInfo[temp_user].refer_n_node += 1;
                }
                temp_user = userInfo[temp_user].invitor;
            }
        }
        
        uint256 asset_need = calMainTokenRequired(Assets[assetId], BCLamount, BCLportion);
        require(asset_need*99/100 + AssetUserRequired[Assets[assetId]][msg.sender] <= IBCL(Assets[assetId]).balanceOf(msg.sender), "004");
        uint d = 10**IBCL(Assets[assetId]).decimals();
        
        uint256 total_value_base = getPrice(Assets[assetId],base) *asset_need * 100 / (100-BCLportion) / d;

        IBCL(Assets[assetId]).transferFrom(msg.sender,platform,asset_need * 1 / 100);
        
        IBCL(bcl_addr).transferFrom(msg.sender, address(this), BCLamount);
        TVL += BCLamount;
        
        uint256 stake_power = total_value_base * calculateComputingPower(BCLportion) * tokenPowerCoef[Assets[assetId]];

        address temp_user2 = msg.sender;
        for(uint j=0;j<n;++j){
            if(temp_user2==address(0) || temp_user2 == address(this)){
                break;
            }else{
                userInfo[temp_user2].nodeStakeAmount += BCLamount;
                userInfo[temp_user2].nodePower += stake_power; 
            }
            temp_user2 = userInfo[temp_user2].invitor;

        }
        
        totalMiningPower = totalMiningPower + stake_power;
        require(userSlot[msg.sender].weightedPower[slotId] == 0 && slotId<=9, "006");
        
        userSlot[msg.sender].weightedPower[slotId] = stake_power;
        userSlot[msg.sender].amount_main[slotId] = asset_need*99/100;
        
        AssetUserRequired[Assets[assetId]][msg.sender] += asset_need*99/100;
        
        userSlot[msg.sender].amount_bcl[slotId] = BCLamount;
        userSlot[msg.sender].portion[slotId] = BCLportion;
        userSlot[msg.sender].timestamp[slotId] = block.timestamp;
        userSlot[msg.sender].assetIds[slotId] = assetId;
        userSlot[msg.sender].values[slotId] = total_value_base * getPrice(base, USDT) / 1e18;
        
        userInfo[msg.sender].power += stake_power;
        userInfo[msg.sender].stakeAmount += BCLamount;
        userInfo[msg.sender].value += total_value_base * getPrice(base, USDT) / 1e18;
        
        
        emit Stake(msg.sender, BCLamount, assetId);
        
        
    }
    
    
    function stakeWithExactMain(
            uint256 assetId,
            uint256 mainPortion,
            uint256 mainAmount,
            address invitor,
            uint slotId)
        external updateRatio{

        require(assetId>=1 && assetId!=13 && mainPortion >=20 && mainPortion < 100, "007");

        updateReward(msg.sender);
        // first-time user, bond reference relation
        if(userInfo[msg.sender].invitor==address(0)){
            require(invitor==address(this) || userInfo[invitor].invitor!=address(0), "009");
            userInfo[msg.sender].invitor = invitor;
            emit BondRefer(msg.sender, invitor);
            userInfo[invitor].refer_n_direct += 1;
            
            address temp_user = invitor;
            
            for(uint i=0;i<n;++i){
                if(temp_user==address(0) || temp_user == address(this)){
                    break;
                }else{
                    userInfo[temp_user].refer_n_node += 1;
                }
                temp_user = userInfo[temp_user].invitor;
            }

        }
        
        uint256 bcl_need = calBCLrequired(Assets[assetId], mainAmount, mainPortion);
        require(mainAmount*99/100 + AssetUserRequired[Assets[assetId]][msg.sender] <= IBCL(Assets[assetId]).balanceOf(msg.sender), "004");
        require(bcl_need + userInfo[msg.sender].stakeAmount <= 500 * 1e9, "exceed stake limit!!!");

        
        uint d = 10**IBCL(Assets[assetId]).decimals();
        
        uint256 total_value_base = getPrice(Assets[assetId],base) * mainAmount*100 / (mainPortion*d);

        IBCL(Assets[assetId]).transferFrom(msg.sender,platform, mainAmount * 1 / 100);
        IBCL(bcl_addr).transferFrom(msg.sender, address(this), bcl_need);
        
        TVL += bcl_need;
        address temp_user2 = msg.sender;
        uint256 stake_power = total_value_base * calculateComputingPower(100-mainPortion) * tokenPowerCoef[Assets[assetId]];

        for(uint j=0;j<n;++j){
            if(temp_user2==address(0) || temp_user2 == address(this)){
                break;
            }else{
                userInfo[temp_user2].nodeStakeAmount += bcl_need;
                userInfo[temp_user2].nodePower += stake_power;
            }
            temp_user2 = userInfo[temp_user2].invitor;

        }
        
        totalMiningPower += stake_power;
        require(slotId<=9 && userSlot[msg.sender].weightedPower[slotId] == 0, "012");
        
        userSlot[msg.sender].weightedPower[slotId] = stake_power;
        userSlot[msg.sender].amount_main[slotId] = mainAmount*99/100;
        
        AssetUserRequired[Assets[assetId]][msg.sender] += mainAmount*99/100;

        
        userSlot[msg.sender].amount_bcl[slotId] = bcl_need;
        userSlot[msg.sender].portion[slotId] = 100-mainPortion;
        userSlot[msg.sender].timestamp[slotId] = block.timestamp;
        userSlot[msg.sender].assetIds[slotId] = assetId;
        userSlot[msg.sender].values[slotId] = total_value_base * getPrice(base, USDT) / 1e18;

        userInfo[msg.sender].power += stake_power;
        userInfo[msg.sender].stakeAmount += bcl_need;
        userInfo[msg.sender].value += total_value_base * getPrice(base, USDT) / 1e18;
        
        
        emit Stake(msg.sender, bcl_need, assetId);
        
        
        
    }
    
     
     
       
    
    function checkStatic() public updateRatio{
        updateReward(msg.sender);
        
        require(userInfo[msg.sender].power>0,"025");
        uint amount = calculateStaticReward(msg.sender);
        // reset user rewards
        rewards[msg.sender] = 0;
        require(amount>0,"no rewards");
        uint staticReward = amount * ratio / 100;
        
        uint userPower = userInfo[msg.sender].power;
        uint actPower;
        
        UserData.slot memory user_slot = userSlot[msg.sender];
        
        // iterate over 10 slots
        for(uint i=0; i<10;++i){
            if(user_slot.assetIds[i]==0){
                // skip empty slot
                continue;
            }
            if(user_slot.assetIds[i]==13 && BNBrequired[msg.sender] <= address(msg.sender).balance ){
                    actPower += user_slot.weightedPower[i];
                    user_slot.timestamp[i] = block.timestamp;
            }
            else if(IBCL(Assets[user_slot.assetIds[i]]).balanceOf(msg.sender) >= AssetUserRequired[Assets[user_slot.assetIds[i]]][msg.sender])
                {
                    actPower += user_slot.weightedPower[i];
                    user_slot.timestamp[i] = block.timestamp;
                }
        }
        
        uint reward = staticReward * actPower / userPower;
        uint burnAmount = reward * (100-ratio) / ratio;
        require(IBCL(bcl_addr).transfer(address(0), burnAmount),"026");
        
        // reward /2 means half of static rewards belong to user, another half for dynamic
        userInfo[msg.sender].staticRewards_claimed += reward /2 * 99 / 100;
        IBCL(bcl_addr).transfer(msg.sender, reward / 2 * 99 /100);
        TotalRewards_static += reward / 2 * 99 / 100;

        emit ClaimStatic(msg.sender,reward / 2 * 99 / 100);


        // iterate n layers dynamic reference
        address temp_user = msg.sender;
        for(uint i=1; i<=n; ++i){
            temp_user = userInfo[temp_user].invitor;
            uint lev = userInfo[temp_user].level;
        
            if(temp_user==address(this)){break;}
            // if user stake value exceeds 100 USDT
            if(lev>0 && userInfo[temp_user].value >= 100 * 1e18){
                uint layer;
                
                if(i==1){layer=1;}
                else if(i<=4){layer=4;}
                else if(i<=7){layer=7;}
                else if(i<=10){layer=10;}
                else if(i<=20){layer=20;}
                
                uint256 dynamicReward = reward / 2 * dynamicRatio[layer][lev-1] /100;
                userInfo[temp_user].dynamicRewards += dynamicReward;
            }
        }
    }
    
    
    function checkStatic_slot(uint slotId) public updateRatio{
        updateReward(msg.sender);
        
        require(userInfo[msg.sender].power>0,"027");
        require(slotId<=9 && userSlot[msg.sender].weightedPower[slotId]>0, "028");
        
        uint amount = calculateStaticReward(msg.sender);
        // reset user rewards
        rewards[msg.sender] = 0;
        
        require(amount>0,"029");
        uint staticReward = amount * ratio /100;
        
        uint userPower = userInfo[msg.sender].power;
        uint actPower;
        
        UserData.slot memory user_slot = userSlot[msg.sender];
        
        // iterate over 10 slots
        if(user_slot.assetIds[slotId]==13 && BNBrequired[msg.sender] <= address(msg.sender).balance)
        {
            actPower = user_slot.weightedPower[slotId];
            user_slot.timestamp[slotId] = block.timestamp;
        }
        else if(IBCL(Assets[user_slot.assetIds[slotId]]).balanceOf(msg.sender) >= AssetUserRequired[Assets[user_slot.assetIds[slotId]]][msg.sender])
            {
                actPower = user_slot.weightedPower[slotId];
                user_slot.timestamp[slotId] = block.timestamp;
            }
        
        // reward from slots statisfying balanceOf conditions
        uint reward = staticReward * actPower / userPower;
        uint burnAmount = reward * (100-ratio) / ratio ; 
        IBCL(bcl_addr).transfer(address(0), burnAmount);
        
        userInfo[msg.sender].staticRewards_claimed += reward / 2 * 99 / 100;
        IBCL(bcl_addr).transfer(msg.sender, reward / 2 * 99 /100);
        TotalRewards_static += reward / 2 * 99 / 100;

        emit ClaimStatic(msg.sender,reward / 2 * 99 / 100);

        // iterate n layers dynamic reference
        address temp_user = msg.sender;
        for(uint i=1; i<=n; ++i){
            temp_user = userInfo[temp_user].invitor;
            uint lev = userInfo[temp_user].level;
        
            if(temp_user==address(this)){break;}
            if(lev>0 && userInfo[temp_user].value >= 100 * 1e18){
                uint layer;
                
                if(i==1){layer=1;}
                else if(i<=4){layer=4;}
                else if(i<=7){layer=7;}
                else if(i<=10){layer=10;}
                else if(i<=20){layer=20;}
                
                uint256 dynamicReward = reward / 2 * dynamicRatio[layer][lev-1] / 100;
                userInfo[temp_user].dynamicRewards += dynamicReward;
            }
        }
    }
    
   
    
    
     // view user accrued static rewards of all 10 slots
    function userAccruedStatic(address user) public view returns(uint256){
        if(userInfo[user].power == 0){return 0;}
        
        uint amount = calculateStaticReward(user);
        
        if(amount==0){return 0;}
        uint staticReward = amount * ratio / 100;
        
        uint userPower = userInfo[user].power;
        uint actPower;
        
        UserData.slot memory user_slot = userSlot[user];
        
        // iterate over 10 slots
        for(uint i=0; i<10;++i){
            if(user_slot.assetIds[i]==0){continue;}
            if(user_slot.assetIds[i]==13 && BNBrequired[user] <= address(user).balance ){
                    actPower += user_slot.weightedPower[i];
            }
            else if(IBCL(Assets[user_slot.assetIds[i]]).balanceOf(user) >= AssetUserRequired[Assets[user_slot.assetIds[i]]][user])
                {
                    actPower += user_slot.weightedPower[i];
                }
        }
        
        uint reward = staticReward * actPower / userPower;
        return reward / 2 * 99 / 100; 
    }
    
    
  
    /*
    * exit one specific slot
    */
    function exit(uint slotId) external {
        require(slotId <= 9 && userSlot[msg.sender].weightedPower[slotId]>0, "030");
        
        // check accrued static rewards
        checkStatic_slot(slotId);
        
        UserData.slot storage user_slot = userSlot[msg.sender];
        
        uint temp_power = user_slot.weightedPower[slotId];
        uint temp_bcl = user_slot.amount_bcl[slotId];
        uint temp_assetId = user_slot.assetIds[slotId];
        uint temp_assetRequired = user_slot.amount_main[slotId];
        uint temp_value = user_slot.values[slotId];
        
        
        user_slot.weightedPower[slotId] = 0;
        user_slot.amount_bcl[slotId] = 0;
        user_slot.amount_main[slotId] = 0;
        user_slot.timestamp[slotId] = 0;
        user_slot.portion[slotId] = 0;
        user_slot.assetIds[slotId] = 0;
        user_slot.values[slotId] = 0;
        
        TVL -= temp_bcl;
        totalMiningPower -= temp_power;
        address temp_user = msg.sender;
        for(uint j=0;j<n;++j){
            if(temp_user==address(0) || temp_user == address(this)){
                break;
            }else{
                userInfo[temp_user].nodeStakeAmount -= temp_bcl;
                userInfo[temp_user].nodePower -= temp_power;
            }
            temp_user = userInfo[temp_user].invitor;

        }
        userInfo[msg.sender].power -= temp_power;
        userInfo[msg.sender].value -= temp_value;
        userInfo[msg.sender].stakeAmount -= temp_bcl;
        
        if(temp_assetId==13){
            BNBrequired[msg.sender] -= temp_assetRequired;
        }else{
            AssetUserRequired[Assets[temp_assetId]][msg.sender] -= temp_assetRequired;
        }
        
        IBCL(bcl_addr).transfer(msg.sender,temp_bcl);
        
        emit Exit(msg.sender, temp_bcl, temp_assetId);
        
    }
    
 }