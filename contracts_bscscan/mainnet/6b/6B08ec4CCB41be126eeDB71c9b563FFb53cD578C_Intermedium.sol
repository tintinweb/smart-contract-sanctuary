/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *s
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
        require(c >= a, "S");

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
        return sub(a, b, "S");
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
        require(c / a == b, "S");

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
        return div(a, b, "S");
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
        return mod(a, b);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        require(address(this).balance >= amount);

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success);
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
      return functionCall(target, data);
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
        return functionCallWithValue(target, data, value);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value);
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target));

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender());
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender);
        require(block.timestamp > _lockTime);
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
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
    function decimals() external view returns (uint8);
}

interface IUniswapV2Pair {
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

library OrosHelper{
    function _orosPrice(address wBNB_OROS) public view returns(uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(wBNB_OROS);
        IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
        return ((Res0*((10**token1.decimals())))*(1))/(Res1);
    }
}

/**
    INTERMEDIUM contract
    Created by OROS.finance TEAM
    to interact with OROS token
 */
contract Intermedium is Context, Ownable {

    using Address for address;
    using SafeMath for uint;
    using SafeMath for uint256;

    uint private orosFee = 10; // retention fee (1% of bnb ---> pay by OROS) 
    uint private publishOrosFee = 3 * 10**15; // 3M OROS fixed fee now: can update
    uint256 private orosPrice;
    IERC20 private token;
    address private noOne = address(0);
    address private wBNB_OROS;

    struct User{
        string name;
        uint office;
        bool verified;
        bool active;
        uint success;
        uint total;
        uint fail;
        string dataHash;
        uint256 id;
        address account;
    }

    struct Job{
        string newDetailsHash;
        string detailsHash;
        uint delay;
        uint256 price;
        uint category;
        address requester;
        address worker;
        bool comunity;
        uint status;
        uint created_at;
        uint unit;
        uint256 id;
        bool agreedRequester;
        bool agreedWorker;
        bool earn;
    }

    Job[] private jobs;
    User[] private users;
    address[] private miniJobers;

    mapping(address => uint256) private retains;
    mapping(address => uint256) private user_indexes;
    mapping(address => uint256) private job_indexes;
    
    uint256 private userIndex = 1;
    uint256 private jobIndex = 1;
    uint256 private totalRetain = 0;

    constructor(
        address _token,
        uint256 initialOrosPrice, 
        address wBNB_OROS_pair
    ) {
        token = IERC20(_token);
        orosPrice = initialOrosPrice;
        wBNB_OROS = wBNB_OROS_pair;
        users.push(User('', 0, false, false, 0,0,0, '', 0,noOne));
        jobs.push(Job('','', 0,0, 0, noOne, noOne, true, 0, 0, 0, 0, false, false,false));
    }

    function doMiniJob(uint256 job_id) external{
        require(token.balanceOf(_msgSender()) > 1*10**9 && job_id > 0 && jobs[job_id].earn);
        delete job_indexes[jobs[job_id].requester];
        delete jobs[job_id];
        miniJobers.push(_msgSender());
    }

    function deleteJob(uint256 job_id) external{
        require(jobs[job_id].status == 1 && _msgSender() == jobs[job_id].requester);
        delete job_indexes[_msgSender()];
        delete jobs[job_id];
    }

    function deleteUser(address _user) external onlyOwner(){
        uint256 index = user_indexes[_user];
        delete user_indexes[_user];
        delete users[index];
    }

    function transf(uint256 amount) private {
        require(amount < token.balanceOf(_msgSender()));
        require(token.allowance(_msgSender(), address(this)) >= amount);
        require(token.transferFrom(_msgSender(), address(this), amount));
    }

    function proccessJob(string memory detailsHash,uint delay,uint category,address worker, uint unit) private {
        job_indexes[_msgSender()] = jobIndex;
        uint256 job_id = job_indexes[_msgSender()];
        jobs.push(Job('', detailsHash, delay,0, category, _msgSender(),worker, worker==noOne, 1, block.timestamp, unit, job_id, false, false, false));
        Job storage job = jobs[job_id];
        job.id = job_id;
        jobIndex++;
    }

    function acceptDeclineJob(address requester, bool accept, uint256 price, string memory newDetailsHash) external {
        require(requester != _msgSender() && requester != noOne && user_indexes[_msgSender()] != 0);
        Job storage job = jobs[job_indexes[requester]];
        require(job.status == 1 && job.requester == requester);

        if(accept){
            User storage user = users[user_indexes[_msgSender()]];
            require(job.category == user.office);
            job.worker = _msgSender();
            job.price = price;
            job.newDetailsHash = newDetailsHash;
            user.total++;
        }else job.earn = true;
        job.status = accept ? 2 : 3;
    }

    function payJob() external payable{
        uint256 amount = msg.value;
        Job storage job = jobs[job_indexes[_msgSender()]];
        require(job.status == 2 && _msgSender() == job.requester && _msgSender() != job.worker);
        uint256 bnbs = (amount.mul(orosFee*10**15)).div(10*10**18);
        orosPrice = OrosHelper._orosPrice(wBNB_OROS);
        (uint256 minOROS, uint256 realBNB) = ((((bnbs.mul(orosFee*10**17)).div(10*10**18)).div(orosPrice)).mul(10**9), amount.sub(bnbs));
        require(job.price <= realBNB);
        require(token.balanceOf(_msgSender()) > minOROS);
        // retain & take fee
        transf(minOROS);
        retains[_msgSender()] = realBNB;
        totalRetain = totalRetain.add(realBNB);
        job.status = 4;//working
    }

    function createJob(string memory dHash, uint delay,uint category,address worker, uint unit) external{
        require(!(worker == _msgSender() || user_indexes[_msgSender()] > 0));
        require(jobs[job_indexes[_msgSender()]].status < 1);
        transf(publishOrosFee);
        proccessJob(dHash, delay, category, worker, unit);
    }

    function saveUserInfo(string memory name,uint office,string memory dataHash) external {
        uint256 user_index = user_indexes[_msgSender()];
        delete user_indexes[_msgSender()];
        delete users[user_index];
        users.push(User(name, office, false, false, 0,0,0, dataHash, userIndex, _msgSender()));
        user_indexes[_msgSender()] = userIndex;
        uint256 user_id = user_indexes[_msgSender()];
        User storage user = users[user_id];
        user.id = user_id;
        userIndex++;
    }

    function saveUserInfoAdmin(string memory name,uint office,string memory dataHash, address _user) external onlyOwner(){
        uint256 user_index = user_indexes[_user];
        delete user_indexes[_user];
        delete users[user_index];
        users.push(User(name, office, false, false, 0,0,0, dataHash, userIndex, _user));
        user_indexes[_user] = userIndex;
        uint256 user_id = user_indexes[_user];
        User storage user = users[user_id];
        user.id = user_id;
        userIndex++;
    }

    function isPaid(uint256 job_id, address requester) external view returns(bool){
        return retains[requester] > 0 && jobs[job_id].requester == requester;
    }

    function agreedJob(address requester, string memory newDetailsHash) external {
        uint256 job_id = job_indexes[requester];
        Job storage job = jobs[job_id];
        require(job.requester == requester && (job.worker == _msgSender() || job.requester == _msgSender() || _msgSender() == owner()));
        if(job.worker == _msgSender() && job.requester == requester){
             job.agreedWorker = true;
             job.newDetailsHash = newDetailsHash;
        }
        if(job.agreedWorker && job.requester == _msgSender() && job.requester == requester){
            require(retains[_msgSender()] > 0);
            User storage user = users[user_indexes[job.worker]];
             // release retained pay to worker
            (bool success, ) = job.worker.call{value: retains[_msgSender()]}("");
            require(success);
            totalRetain = totalRetain.sub(retains[_msgSender()]);
            retains[_msgSender()] = 0;
            job.agreedWorker = true;
            job.earn = true;
            job.status = 5;
            user.success++;
        }
        // Set frozen job to earn state
        if(_msgSender() == owner())
            job.earn = true;
    }

    function setVerified(address userAddress, bool verified, uint fail, bool active) external onlyOwner(){
        uint256 user_id = user_indexes[userAddress];
        User storage user = users[user_id];
        user.verified = verified;
        user.active = active;
        user.fail = fail;
    }

    function withdrawTo(uint256 _amount, address payable _to, bool _oros) external onlyOwner() {
        if(_oros)
            token.transfer(_to, _amount);
        else{
            require(address(this).balance.sub(totalRetain) > _amount);
            (bool success, ) = _to.call{value: _amount}("");
            require(success);
        }
    }

    function setOrosFee(uint fee, bool _public, bool cleanJobers) external onlyOwner(){
        if(cleanJobers)
            delete miniJobers;
        if(_public)
            publishOrosFee = fee;
        else
            orosFee = fee;
    }

    function total(bool _usr, bool _retain, bool _orosFee, bool _orosPublicFee) external view returns (uint256){
        if(_orosPublicFee)
            return publishOrosFee;
        if(_orosFee)
            return orosFee;
        if(_retain)
            return totalRetain;
        return _usr ? users.length : jobs.length;
    }

    function getJobs() external view returns(Job[] memory){
        return jobs;
    }

    function getUsers() external view returns(User[] memory){
        return users;
    }

    function getMiniJobers() external view returns(address[] memory){
        return miniJobers;
    }

    function getJob(address requesterAddress) external view returns(Job memory){
      return jobs[job_indexes[requesterAddress]];
    }

    function getUser(address userAddress) external view returns(User memory){
      return users[user_indexes[userAddress]];
    }
}