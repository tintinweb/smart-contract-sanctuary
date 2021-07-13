/**
 *Submitted for verification at BscScan.com on 2021-07-13
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

/**
    THE WHEEL contract
    Created by OROS.finance TEAM
    to interact with OROS token
 */
contract Wheel is Context, Ownable {

    using Address for address;
    using SafeMath for uint;
    using SafeMath for uint256;

    IERC20 private token;
    address private noOne = address(0);
    address private deadAddress;

    address private jackSpotCharityContract;
    uint private theWheelFee = 7;
    uint private jackSpotCharityFee = 2;
    uint private burnFee = 1;
    uint private pools_index = 0;

    address [] private pairs;
    mapping(address => uint) private pairs_indexes;
    uint private current_pair_index = 1;

    struct Game{
        address[] joined_users;
        uint winnerNum;
        address winner;
    }

    struct Pool{
        string name;
        string description;
        uint256 price;
        uint max;
        uint joined;
        uint playedCount;
        uint256 bSelectJoin;
        uint256 bSelectSpin;
        uint256 spot;
    }

    Pool[] private pools;
    address[] private monthPlayers;
    mapping(string => uint) private pools_indexes;
    mapping(string => mapping(uint256 => Game)) private games;

    event Joined(string pool_name, uint256 indexed playedCount, uint joined, address[] users);
    event Spin(string pool_name, uint256 indexed playedCount, address indexed winner, uint winnerNum);

    constructor(
        address _token
    ) {
        token = IERC20(_token);
        pairs.push(address(0));
    }

    function addPool(string memory name, string memory description, uint256 price, uint max) external onlyOwner(){
        pools.push(Pool(name, description, price, max, 0, 0, 0, 0, 0));
        pools_indexes[name] = pools_index;
        pools_index++;
    }

    function _join(Pool storage pool) private {
        Game storage game = games[pool.name][pool.playedCount];
        game.joined_users.push(_msgSender());
        pool.joined = pool.joined.add(1);
        
        transf(pool.price, address(this));
        pool.bSelectJoin = block.number;
        emit Joined(pool.name, pool.playedCount, pool.joined, game.joined_users);
    }

    function setJackSpotCharityFee(uint fee) external onlyOwner(){
        jackSpotCharityFee = fee;
    }

    function getJackSpotCharityFee() external view returns(uint){
        return jackSpotCharityFee;
    }

    function getTheWheelFee() external view returns(uint){
        return theWheelFee;
    }

    function getBurnFee() external view returns(uint){
        return burnFee;
    }

    function getJackSpotCharityContract() external view returns(address){
        return jackSpotCharityContract;
    }

    function setTheWheelFee(uint fee) external onlyOwner(){
        theWheelFee = fee;
    }

    function setBurnFee(uint fee) external onlyOwner(){
        burnFee = fee;
    }

    function getDeadAddress() external view returns(address){
        return deadAddress;
    }

    function setDeadAddress(address dead) external onlyOwner(){
        deadAddress = dead;
    }

    function setJackSpotcharityContract(address _contract) external onlyOwner(){
        jackSpotCharityContract = _contract;
    }

    function transf(uint256 amount, address to) private {
        require(token.allowance(_msgSender(), to) >= amount);
        require(token.transferFrom(_msgSender(), to, amount));
    }

    function transf2(uint256 amount, address to) private {
        require(token.transfer(to, amount));
    }

    function terminateGame(uint pool_id, uint random) private{
        Pool storage pool = pools[pool_id];
        Game storage game = games[pool.name][pool.playedCount];
        game.winnerNum = random >= game.joined_users.length ? random.sub(1) : random;
        game.winner = game.joined_users[game.winnerNum];
        pool.spot = pool.price.mul(pool.max);

        uint256 theWheelWin = (pool.spot.mul(theWheelFee*10**9)).div(100*10**9);
        uint256 jackSpotWin = (pool.spot.mul(jackSpotCharityFee*10**9)).div(100*10**9);
        uint256 burnWin = (pool.spot.mul(burnFee*10**9)).div(100*10**9);
        uint256 userWin = pool.spot.sub(theWheelWin.add(jackSpotWin).add(burnWin));

        transf2(userWin, game.winner);
        transf2(jackSpotWin, jackSpotCharityContract);
        transf2(burnWin, deadAddress);

        uint256 _game_id = pool.playedCount;
        pool.playedCount = pool.playedCount.add(1);
        pool.bSelectSpin = block.number;
        emit Spin(pool.name, _game_id, game.winner, game.winnerNum);
    }

    function join(string memory pool_name) external {
        uint pool_id = pools_indexes[pool_name];
        Pool storage pool = pools[pool_id];

        require(!_isJoined(pool), "Nothing to do here");
        require(pool.joined < pool.max, "Wait for next");
        require(token.balanceOf(_msgSender()) >= pool.price, "Not enough tokens to join");
        require(token.allowance(_msgSender(), address(this)) >= pool.price, "Not enough allowence");

        if(pool.joined.add(1) == pool.max){
            _join(pool);
            _generateRandom(pool_id);
            _resetPool(pool);
        }else{
            _join(pool);
        }
    }

    function _resetPool(Pool storage pool) private {     
        pool.joined = 0;
        pool.spot = 0;
    }

    function removePool(uint pool_id) external onlyOwner(){
        delete pools[pool_id];
    }

    function updatePool(string memory name, uint256 price, uint max, uint pool_id, string memory description) external onlyOwner(){
        Pool storage pool = pools[pool_id];
        pool.name = name;
        pool.description = description;
        pool.price = price;
        pool.max = max;
    }

    function removePairAddress(uint pair_id) external onlyOwner(){
        delete pools[pair_id];
    }

    function getPoolById(uint pool_id) external view returns(Pool memory){
      return pools[pool_id];
    }

    function getPoolByName(string memory pool_name) external view returns(Pool memory){
      return pools[pools_indexes[pool_name]];
    }

     function getGame(string memory pool_name) external view returns(Game memory){
        Pool memory pool = pools[pools_indexes[pool_name]];
        return games[pool.name][pool.playedCount];
    }

    function getPools() external view returns(Pool[] memory){
      return pools;
    }

    /// random
    function _generateRandom(uint pool_id) private {
        Pool storage pool = pools[pool_id];
        uint random = _random(pool.max);
        terminateGame(pool_id, random);
    }

    function _isJoined(Pool memory _pool) private view returns(bool){
        Game memory game = games[_pool.name][_pool.playedCount];
        for (uint i = 0; i < game.joined_users.length; i++) 
            if(game.joined_users[i] == _msgSender())
                return true;
        
        return false;
    }

    function _random(uint max) private view returns(uint)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number +
            _generateNumber()
        )));
    
        return 1*(seed.sub((seed.div(max)) * max));
    }

    function _price(address pairAddress) private view returns(uint256)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 token1 = IERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
        return ((Res0*((10**token1.decimals())))*(1))/(Res1);
    }
    
    function _generateNumber() private view returns(uint256){
        uint256 totalPrice = 0;
        for(uint i = 0; i < pairs.length; i++)
            if(pairs[i] != address(0))
                totalPrice += _price(pairs[i]);
        
        return totalPrice;
    }
    
    function addPair(address _pair) external onlyOwner(){
        pairs_indexes[_pair] = current_pair_index;
        pairs.push(_pair);
        current_pair_index++;
    }
    
    function clearPair() external onlyOwner(){
        delete pairs;
    }

    receive() external payable {}
    fallback() external payable {}
}