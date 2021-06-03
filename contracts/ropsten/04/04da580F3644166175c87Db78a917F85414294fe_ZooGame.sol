/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
// 
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

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

// 
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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
// 
/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
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

contract ZooGame  {
    struct BidTicket { 
        address bid;
        uint256 time;
        uint256 value;
    }
    struct UserSummary{
        uint256[] unclaimRounds;
    }
    struct Animal{
        address token;
        address lPTokenWithUSD;
    }
    struct AnimalInRound{
        Animal amimal;
        uint256 firstPrice;
        uint256 lastPrice;
        uint256 totalAmount;
        bool isPositive;
        uint256 range;
    }
    struct GameRound{
        address winner;
        mapping(address=>AnimalInRound) animals;
        uint256 startTime;
        uint256 endTime;
        uint256 winningPriceIncrease;
        bool isPositive;
        bool isDraw;
    }
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20; 
    address public adminAddress;
    address[] public users;
    Animal[] public animals;
    mapping (uint256 => GameRound) public historyRounds;
    mapping (address => mapping(uint256=>BidTicket[])) public userInfo;//address=>round=>tiket
    mapping (address => UserSummary) private usersSummary;
    mapping (address => uint256) public remainingFee;
    uint256 public round = 1;
    uint roundPhase = 0;//0 is deactive, 1 is deposit, 2 is get price
    GameRound public currentRound;
    constructor() public {
        adminAddress = msg.sender;   
    }
    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Zoo: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }
    function transferAdmin(address _to) public onlyAdmin{
        adminAddress = _to;
    }
    function getLengthPending(address _player) public view returns(uint256){
        return usersSummary[_player].unclaimRounds.length;
    }
    function addAnimal(address _token, address _lPTokenWithUSD) public onlyAdmin{
        require(!isAnimalExist(_token),'animal aready exist');
        require(roundPhase==0,'round is running');
        Animal memory _animal = Animal(_token,_lPTokenWithUSD);
        animals.push(_animal);
    }
    function isAnimalExist(address _token) private view returns (bool){
        if(animals.length>0){
            for(uint i=0;i<animals.length;i++){
                if(animals[i].token==_token){
                    return true;
                }
            }
        }
        return false;
    }
    function newRound() public onlyAdmin {
        require(animals.length>0,'nothing to racing');
        require(roundPhase==0,'round is running');
        reset();
        roundPhase = 1;
    }
    function finishDeposit() public onlyAdmin{
        require(roundPhase==1,'wrong phase');
        roundPhase = 2;
        for(uint i=0;i<animals.length;i++){
            currentRound.animals[animals[i].token].firstPrice = getTokenPrice(animals[i].lPTokenWithUSD,animals[i].token);
        }
        currentRound.endTime = block.timestamp;
    }
    function endRound() public onlyAdmin{
        require(roundPhase == 2,'wrong phase');
        roundPhase = 0;
        if(block.timestamp >= currentRound.startTime.add(600) && block.timestamp <= currentRound.startTime.add(900))
        {
            determineTheWinner();
            calFee();
        }
        else{
            currentRound.isDraw = true;
        }
        historyRounds[round] = currentRound;
        
    }
    function determineTheWinner() private{
        for(uint i=0;i<animals.length;i++){
            AnimalInRound storage animalInRound = currentRound.animals[animals[i].token];
            if(animalInRound.totalAmount>0){
                animalInRound.lastPrice = getTokenPrice(animalInRound.amimal.lPTokenWithUSD,animalInRound.amimal.token);
                if(animalInRound.lastPrice>=animalInRound.firstPrice){
                    animalInRound.isPositive = true;
                    animalInRound.range = animalInRound.lastPrice.sub(animalInRound.firstPrice);
                }
                else{
                    animalInRound.isPositive = false;
                    animalInRound.range = animalInRound.firstPrice.sub(animalInRound.lastPrice);
                }
                updateWiningAnimal(animalInRound);    
            }
        }
    }
    function updateWiningAnimal(AnimalInRound memory _animal) private{
        if( (currentRound.isPositive && _animal.isPositive && currentRound.winningPriceIncrease<_animal.range)
            ||
            (!currentRound.isPositive && _animal.isPositive)
            ||
            (!currentRound.isPositive && !_animal.isPositive && currentRound.winningPriceIncrease > _animal.range)
        ){
            currentRound.winningPriceIncrease = _animal.range;
            currentRound.winner = _animal.amimal.token;
            currentRound.isPositive = _animal.isPositive;
            currentRound.isDraw = false;
        }
        else if(currentRound.isPositive == _animal.isPositive && currentRound.winningPriceIncrease == _animal.range){
            currentRound.isDraw = true;
        }
    }
    function getTokenPrice(address _pairAddress,address _token) private view returns(uint)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        address token0Address = pair.token0();
        address token1Address = pair.token1();
        require(_token == token0Address || _token == token1Address,'pair address not match token');
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        if(_token == token1Address){
            IBEP20 token1 = IBEP20(token1Address);
            uint256 res0 = Res0*(10**token1.decimals());
            return((1*res0)/Res1);
        }
        else{
            IBEP20 token0 = IBEP20(token0Address);
            uint256 res1 = Res1*(10**token0.decimals());
            return((1*res1)/Res0);
        }
    }
    function reset() private{
        require(animals.length>0,'nothing to racing');
        round = round.add(1);
        currentRound.winner=address(0);
        currentRound.startTime=block.timestamp;
        currentRound.endTime=0;
        currentRound.winningPriceIncrease=0;
        currentRound.isPositive=false;
        currentRound.isDraw=false;
        for(uint i=0;i<animals.length;i++){
            currentRound.animals[animals[i].token] = AnimalInRound(
                animals[i],
                0,
                0,
                0,
                false,
                0);
        }

        
    }
    function calFee() private{
        require(animals.length>0,'nothing to racing');
        if(!currentRound.isDraw){
            for(uint i=0;i<animals.length;i++){
                AnimalInRound storage animalInRound = currentRound.animals[animals[i].token];
                if(animalInRound.totalAmount>0){
                    remainingFee[animals[i].token] = remainingFee[animals[i].token].add(animalInRound.totalAmount.div(20));
                }
            }
        }
        
    }
    function claimReward() public lock{
        require(animals.length>0,'nothing to racing');
        for(uint i=0;i<animals.length;i++){
            uint256 rewardPending = calRewardPending(msg.sender,animals[i]);
            require(rewardPending>0,'nothing to claim');
            IBEP20(animals[i].token).safeTransfer(msg.sender, rewardPending);
        }
        delete usersSummary[msg.sender].unclaimRounds;            
    }
    function calRewardPending(address _player,Animal memory _animal) private view returns (uint256)  {
        uint256 _totalPending = 0;
        if(usersSummary[_player].unclaimRounds.length>0){
            uint256 _lastRoundCheck = 0;
            for(uint i = 0;i<usersSummary[_player].unclaimRounds.length;i++){
                if(usersSummary[_player].unclaimRounds[i]>_lastRoundCheck){
                    _lastRoundCheck = usersSummary[_player].unclaimRounds[i];
                    _totalPending = _totalPending.add(getRewardPendingInRound(_lastRoundCheck,_player,_animal));
                }
            }
        }
        return _totalPending;
        
    }
    function getRewardPendingInRound(uint256 _round,address _player,Animal memory _animal) private view returns (uint256) {
        uint256 _totalPendingRound = 0;
        for(uint i=0;i<userInfo[_player][_round].length;i++){
            BidTicket storage _ticket = userInfo[_player][_round][i];
            if( historyRounds[_round].isDraw==false && historyRounds[_round].winner == _ticket.bid){
                uint256 _allocPoint = historyRounds[_round].animals[_ticket.bid].totalAmount.div(_ticket.value);
                uint256 _getRewardPendingInRound = historyRounds[_round].animals[_animal.token].totalAmount.div(_allocPoint);
                _getRewardPendingInRound = _getRewardPendingInRound.mul(95).div(100);
                _totalPendingRound = _totalPendingRound.add(_getRewardPendingInRound);
            }
            else if(historyRounds[_round].isDraw && _ticket.bid == _animal.token){
                _totalPendingRound = _totalPendingRound.add(_ticket.value);
            }
        }
        return _totalPendingRound;
        
    }
    
    function deposit(address _animalToken, uint256 _value) public lock {
        require(roundPhase ==1,'the race has not started or has ended');
        require(currentRound.animals[_animalToken].firstPrice>0,'animal not exist');
        IBEP20(_animalToken).safeTransferFrom(msg.sender, address(this), _value);
        userInfo[msg.sender][round].push(BidTicket(_animalToken,block.timestamp,_value));
        usersSummary[msg.sender].unclaimRounds.push(round);
    }
    function withdrawalFee() public onlyAdmin {
        require(animals.length>0,'nothing to racing');
        for(uint i=0;i<animals.length;i++){
            if(remainingFee[animals[i].token] >0 ){
                IBEP20(animals[i].token).safeTransfer(adminAddress, remainingFee[animals[i].token]);
                remainingFee[animals[i].token] = 0;            
            }
        }
    
    }
    
}