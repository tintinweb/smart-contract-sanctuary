/**
 *Submitted for verification at Etherscan.io on 2021-01-05
*/

//SPDX-License-Identifier: UNLICENSED1
pragma solidity >=0.4.22 <0.7.0;

contract KatDataStore {
    address public owner;
    address payable public devAddr;
    address public katAddr;
    address public usdtAddr;
    address public katMan;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint public curEpoch = 1;
    uint public oneEth = 1 ether ;
    uint public buyBackMin ;
    uint public priceFirst;
    uint public priceSecond;
    uint public communitylen = 0;
    bool public isInit;

    
    constructor() public {
        owner = msg.sender;
        devAddr = msg.sender;
        userInfo[devAddr].registBlock = block.number;
        
    }
    fallback() payable external {}
    receive() payable external {}
    
    struct UserInfo {
        address invitor;
        uint registBlock;
        uint totalInvest;
        uint cid;
    }
    
    struct DepositInfo {
        uint depositVal;
        uint depositTimes;
        uint personReward;
        uint dynamicReward;
        bool isWithdraw;
        
    }
    struct EpochInfo {
        uint totalAmountToken;
        uint totalLimitEth;
        uint totalDeposit;
        bool isOver;
    }
    
    struct CommunityInfo{
        uint totalDeposit;
        uint totalUserCount;
        uint registBlock;
        string cname;
        address cowner;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier onlyKat(){
        require(msg.sender == katMan);
        _;
    }
    
    mapping(address => address[]) public referArr;
    mapping(address => mapping(uint => DepositInfo)) public depositInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(uint => EpochInfo) public epochInfo;
    mapping(uint => CommunityInfo) public communityInfo;
    mapping(string => bool) public cnameRegisted;

    function transferOwnerShip(address _owner) public onlyOwner {
        owner = _owner;
    }
    function setBuyBackMin(uint _minNum) public onlyOwner {
        buyBackMin = _minNum;
    }
    function setPriceFirst(uint _priceFirst) public onlyOwner {
        priceFirst = _priceFirst;
    }
    function setPriceSecond(uint _priceSecond) public onlyOwner {
        priceSecond = _priceSecond;
    }
    function setDevAddr(address payable _devAddr) public onlyOwner {
        devAddr = _devAddr;
    }
    function setKatManager(address _katMan) public onlyOwner {
        katMan = _katMan;
    }
    function initializeEpoch(address _katAddr,address _usdtAddr) public onlyOwner {
        require(!isInit);
        katAddr = _katAddr;
        usdtAddr = _usdtAddr;
        epochInfo[1] = EpochInfo(oneEth.mul(300_000),oneEth.mul(10_000),0,false );
        epochInfo[2] = EpochInfo(oneEth.mul(800_000),oneEth.mul(100_000),0,false );
        epochInfo[3] = EpochInfo(oneEth.mul(2200_000),oneEth.mul(1_000_000),0,false );
        isInit = true;
    }
    function getOutUsdt(address _to,uint _amount) public onlyOwner {
        safeTransferToken(usdtAddr,_to,_amount);
    }
    function getOutKat(address _to,uint _amount) public onlyOwner {
        safeTransferToken(katAddr,_to,_amount);
    }
    function sellKatForUsdt(uint _amount) public  {
        require(_amount >= buyBackMin);
        IERC20(katAddr).safeTransferFrom(msg.sender,devAddr,_amount);
        uint backUsdt = viewKatForUsdtAmount(_amount);
        safeTransferToken(usdtAddr , msg.sender, backUsdt);
    }
    function createCommunity(address _user,string memory _cname) public onlyOwner{
        require(!cnameRegisted[_cname]);
        communitylen = communitylen.add(1);
        communityInfo[communitylen] = CommunityInfo(0,0,block.number,_cname,_user);
        cnameRegisted[_cname] = true;
    }
    function depositTodo(address _user,address _invitor,uint _cid,uint depositVal,bool isNew) public onlyKat{
        EpochInfo storage epoch = epochInfo[curEpoch];
        UserInfo storage user = userInfo[_user];
        DepositInfo storage deposit = depositInfo[_user][curEpoch];
        CommunityInfo storage comm = communityInfo[_cid];
        epoch.totalDeposit = epoch.totalDeposit.add(depositVal);
        
        if(epoch.totalDeposit >= epoch.totalLimitEth){
            curEpoch = curEpoch.add(1);
            epoch.isOver = true;
        }
        
        user.totalInvest = user.totalInvest.add(depositVal);
        
        deposit.depositVal = deposit.depositVal.add(depositVal);
        deposit.depositTimes = deposit.depositTimes.add(1);
        
        comm.totalDeposit = comm.totalDeposit.add(depositVal);
        // devAddr.transfer(depositVal.mul(1000).div(10000));
        safeTransferEth(devAddr,depositVal.mul(1000).div(10000));
        if(isNew){
            user.invitor = _invitor;
            user.registBlock = block.number;
            user.cid = _cid;
            comm.totalUserCount = comm.totalUserCount.add(1);
            if(!findIsReffer(_invitor,_user)){
                referArr[_invitor].push(_user);
            }
        }
    }
    function findIsReffer(address _user,address _invitor) public view returns(bool isInsert){
        for(uint i;i< referArr[_user].length;i++){
            if(_invitor == referArr[_user][i]){
                isInsert = true;
                break;
            }
        }
    }
    function getEthTodo(address payable _user,uint _amount) public onlyKat{
        EpochInfo storage epoch = epochInfo[curEpoch];
        UserInfo storage user = userInfo[_user];
        DepositInfo storage deposit = depositInfo[_user][curEpoch];
        CommunityInfo storage comm = communityInfo[user.cid];
        require(deposit.depositVal >= _amount);
        require(user.totalInvest >= _amount);
        deposit.depositVal = deposit.depositVal.sub(_amount);
        epoch.totalDeposit = epoch.totalDeposit.sub(_amount);
        user.totalInvest = user.totalInvest.sub(_amount);
        comm.totalDeposit = comm.totalDeposit.sub(_amount);
        
        safeTransferEth(_user,_amount.mul(9000).div(10000));
        if(user.totalInvest == 0){
            user.cid = 0;
            user.registBlock = 0;
            user.invitor = address(0);
            comm.totalUserCount = comm.totalUserCount.sub(1);
        }
    }
    function getRewardTodo(address payable _user,uint _epoch) public onlyKat {
        
        DepositInfo storage deposit = depositInfo[_user][_epoch];
        uint reward = calReward(deposit.depositVal,_epoch);
        safeTransferEth(_user,deposit.depositVal.mul(9000).div(10000));
        safeTransferToken(katAddr ,_user, reward);
        deposit.personReward = reward;
        deposit.isWithdraw = true;
        execute(userInfo[_user].invitor, 1 ,reward.mul(5000).div(10000), _epoch);
    }
    function execute(address invitor,uint runtimes,uint _staticAm,uint epoch) private returns(uint) {
        if(runtimes <= 8 && invitor != address(0) && invitor != address(devAddr) && IERC20(katAddr).balanceOf(address(this))>0){
            DepositInfo storage deposit = depositInfo[invitor][epoch];
            if(deposit.depositVal > 0){
                safeTransferToken(katAddr , invitor, _staticAm);
                deposit.dynamicReward = deposit.dynamicReward.add(_staticAm);
            }
            return execute(userInfo[invitor].invitor,runtimes+1,_staticAm.mul(5000).div(10000),epoch);
        }
        return uint(0);
    }
    function viewContractEth() public view returns(uint){
        return address(this).balance;
    }
    function viewReward(address _user,uint _epoch) public view returns(uint){
        if(epochInfo[_epoch].isOver){
            DepositInfo memory deposit = depositInfo[_user][_epoch];
            if(deposit.isWithdraw){
                return deposit.dynamicReward.add(deposit.personReward);
            }
            uint reward = calReward(deposit.depositVal,_epoch);
            return reward.add(deposit.dynamicReward);
        }
        return uint(0);
    }
    function viewKatForUsdtAmount(uint amount) public view returns(uint){
        return uint(amount.mul(priceSecond).div(oneEth));
    }
    function calReward(uint amount,uint _epoch) public view returns(uint){
        return epochInfo[_epoch].totalAmountToken.mul(amount).mul(5000).div(10000).div(epochInfo[_epoch].totalDeposit);
    }
    function isRegisted(address _user) public view returns(bool){
        return userInfo[_user].registBlock > 0 ;
    }
    function safeTransferToken(address _token,address _user,uint _amount) private {
        uint contBalToken = IERC20(_token).balanceOf(address(this));
        if(contBalToken > _amount){
            IERC20(_token).safeTransfer(_user,_amount);
        }else{
            IERC20(_token).safeTransfer(_user,contBalToken);
        }
    }
    function safeTransferEth(address payable _user,uint _amount) private {
        if(address(this).balance > _amount){
            _user.transfer(_amount);
        }else{
            _user.transfer(address(this).balance);
        }
    }
    
}


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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external ;
    function transfer(address to, uint value) external ;
    function transferFrom(address from, address to, uint value) external ;
    function mint(address,uint) external;
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


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