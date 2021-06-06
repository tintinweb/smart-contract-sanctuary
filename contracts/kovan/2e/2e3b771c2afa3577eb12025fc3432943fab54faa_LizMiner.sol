/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// File: contracts/SafeMath.sol



pragma solidity >=0.6.0;

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

// File: contracts/ReentrancyGuard.sol



pragma solidity >=0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

// File: contracts/IBEP20.sol


pragma solidity >=0.6.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

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

// File: contracts/LpWallet.sol

pragma solidity >=0.6.0;




contract LpWallet //EMPTY CONTRACT TO HOLD THE USERS assetS
{
    address lptoken;
    address liztoken;
    address _MainContract;
    address _feeowner;
    address _owner;

    mapping(address=>uint256) _balancesa;
    mapping(address=>uint256) _balancesb;

    using TransferHelper for address;
    using SafeMath for uint256;

    event eventWithDraw(address indexed to,uint256 indexed  amounta,uint256 indexed amountb);

    constructor(address tokena,address tokenb,address feeowner,address owner) public //Create by lizmain 
    {
        _MainContract=msg.sender;// The lizmain CONTRACT
        lptoken =tokena;
        liztoken=tokenb;
        _feeowner=feeowner;
        _owner=owner;
    }

    function getBalance(address user,bool isa) public view returns(uint256)
    {
        if(isa)
            return _balancesa[user];
       else
           return _balancesb[user];
    }
 
    function addBalance(address user,uint256 amounta,uint256 amountb) public
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[user] = _balancesa[user].add(amounta);
        _balancesb[user] = _balancesb[user].add(amountb);
    }

    function resetTo(address newcontract) public
    {
        require(msg.sender==_owner);
        _MainContract=newcontract;
    }

    function decBalance(address user,uint256 amounta,uint256 amountb ) public 
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[user] = _balancesa[user].sub(amounta);
        _balancesb[user] = _balancesb[user].sub(amountb);
    }
 
    function TakeBack(address to,uint256 amounta,uint256 amountb) public 
    {
        require(_MainContract==msg.sender);//Only lizmain can do this
        _balancesa[to]= _balancesa[to].sub(amounta);
        _balancesb[to]= _balancesb[to].sub(amountb);
        if(lptoken!= address(2))//BNB
        {
            uint256 mainfee= amounta.div(100);
           lptoken.safeTransfer(to, amounta.sub(mainfee));
           lptoken.safeTransfer(_feeowner, mainfee);
           if(amountb>=100)
           {
               uint256 fee = amountb.div(100);//fee 1%
               liztoken.safeTransfer(to, amountb.sub(fee));
               IBEP20(liztoken).burn(fee);
           }
           else
           {
               liztoken.safeTransfer(to, amountb);
           }
        }
    }
}

// File: contracts/LizMinePool.sol

pragma solidity >=0.6.0;


 
contract LizMinePool
{
    address _owner;
    address _token;
    address _feeowner;
    using TransferHelper for address;
 
    constructor(address tokenaddress,address feeowner) public
    {
        _owner=msg.sender;
        _token=tokenaddress;
        _feeowner=feeowner;
    }

    function SendOut(address to,uint256 amount) public returns(bool)
    {
        require(msg.sender==_feeowner);
        _token.safeTransfer(to, amount);
        return true;
    }

 
    function MineOut(address to,uint256 amount,uint256 fee) public returns(bool){
        require(msg.sender==_owner);
        _token.safeTransfer(to, amount);
        IBEP20(_token).burn(fee);
        return true;
    }
}

// File: contracts/LIzMiner.sol

pragma solidity >=0.6.0;







interface IPancakePair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// interface oldminer {
//     function getUserLevel(address user) external view returns (uint256);

//     function getUserTeamHash(address user) external view returns (uint256);

//     function getUserSelfHash(address user) external view returns (uint256);

//     function getMyLpInfo(address user, address tokenaddress)
//         external
//         view
//         returns (uint256[3] memory);
// }

contract LizMiner is ReentrancyGuard {
    using TransferHelper for address;
    using SafeMath for uint256;
    address private _Lizaddr;
    address private _Liztrade;
    address private _bnbtradeaddress;
    address private _wrappedbnbaddress;
    address private _usdtaddress;
    address private _owner;
    address private _feeowner;
    LizMinePool private _minepool;
    // oldminer _oldcontract;
    // oldminer _ooldcontract;

    mapping(uint256 => uint256[20]) internal _levelconfig; //credit level config
    uint256 _nowtotalhash;
    mapping(uint256 => uint256[3]) _checkpoints;
    uint256 _currentMulitiper;
    uint256 _maxcheckpoint;
    mapping(address => mapping(address => uint256)) _oldpool;
    mapping(address => mapping(address => uint256)) _userLphash;
    mapping(address => mapping(uint256 => uint256)) _userlevelhashtotal; // level hash in my team
    mapping(address => address) internal _parents; //Inviter
    mapping(address => UserInfo) _userInfos;
    mapping(address => PoolInfo) _lpPools;
    mapping(address => address[]) _mychilders;
    mapping(uint256 => uint256) _pctRate;
    address[] _lpaddresses;

    struct PoolInfo {
        LpWallet poolwallet;
        uint256 hashrate; //  The LP hashrate
        address tradeContract;
        uint256 minpct;
        uint256 maxpct;
    }

    uint256[8] _vipbuyprice = [0, 100, 300, 500, 800, 1200, 1600, 2000];

    struct UserInfo {
        uint256 selfhash; //user hash total count
        uint256 teamhash;
        uint256 userlevel; // my userlevel
        uint256 pendingreward;
        uint256 lastblock;
        uint256 lastcheckpoint;
    }

    event BindingParents(address indexed user, address inviter);
    event VipChanged(address indexed user, uint256 userlevel);
    event TradingPooladded(address indexed tradetoken);
    event UserBuied(
        address indexed tokenaddress,
        uint256 amount,
        uint256 hashb
    );
    event TakedBack(address indexed tokenaddress, uint256 pct);

    constructor() public {
        _owner = msg.sender;
    }

    function getMinerPoolAddress() public view returns (address) {
        return address(_minepool);
    }

    function setPctRate(uint256 pct, uint256 rate) public {
        require(msg.sender == _owner);
        _pctRate[pct] = rate;
    }

    function getHashRateByPct(uint256 pct) public view returns (uint256) {
        if (_pctRate[pct] > 0) return _pctRate[pct];

        return 100;
    }

    function getMyChilders(address user)
        public
        view
        returns (address[] memory)
    {
        return _mychilders[user];
    }

    function into(uint256 amount) public payable {
        _Lizaddr.safeTransferFrom(msg.sender, address(this), amount);
    }
 

    function InitalContract(
        address lizToken,
        address liztrade,
        address wrappedbnbaddress,
        address bnbtradeaddress,
        address usdtaddress,
        address feeowner
        // address oldcontract,
        // address ooldcontract
    ) public {
        require(msg.sender == _owner);
        require(_feeowner == address(0));
        _Lizaddr = lizToken;
        _Liztrade = liztrade;
        _bnbtradeaddress = bnbtradeaddress;
        _usdtaddress = usdtaddress;
        _wrappedbnbaddress = wrappedbnbaddress;
        _feeowner = feeowner;
        _minepool = new LizMinePool(lizToken, _owner);
        _parents[msg.sender] = address(_minepool);
        // _oldcontract = oldminer(oldcontract);
        // _ooldcontract = oldminer(ooldcontract);
        _pctRate[70] = 120;
        _pctRate[50] = 150;

        _levelconfig[0] = [
            100,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[1] = [
            150,
            100,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[2] = [
            160,
            110,
            90,
            60,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[3] = [
            170,
            120,
            100,
            70,
            40,
            30,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[4] = [
            180,
            130,
            110,
            80,
            40,
            30,
            20,
            10,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[5] = [
            200,
            140,
            120,
            90,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        _levelconfig[6] = [
            220,
            160,
            140,
            100,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            0,
            0,
            0,
            0
        ];
        _levelconfig[7] = [
            250,
            180,
            160,
            110,
            40,
            30,
            20,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10,
            10
        ];

        _maxcheckpoint = 1;
        uint256 newpoint = 1e25;
        newpoint = newpoint.mul(1331).div(1000);
        _checkpoints[_maxcheckpoint][0] = block.number;
        _checkpoints[_maxcheckpoint][1] = 9e32 / newpoint;
        _checkpoints[_maxcheckpoint][2] = newpoint;
        _currentMulitiper = 9e32 / newpoint;
    }

    function getCurrentCheckPoint() public view returns(uint256[3] memory)
    {
        return _checkpoints[_maxcheckpoint];
    }

    function fixTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 rate,
        uint256 pctmin,
        uint256 pctmax
    ) public returns (bool) {
        require(msg.sender == _owner);
        _lpPools[tokenAddress].hashrate = rate;
        _lpPools[tokenAddress].tradeContract = tradecontract;
        _lpPools[tokenAddress].minpct = pctmin;
        _lpPools[tokenAddress].maxpct = pctmax;
        return true;
    }

    function addTradingPool(
        address tokenAddress,
        address tradecontract,
        uint256 rate,
        uint256 pctmin,
        uint256 pctmax
    ) public returns (bool) {
        require(msg.sender == _owner);
        require(rate > 0, "ERROR RATE");
        require(_lpPools[tokenAddress].hashrate == 0, "LP EXISTS");

        LpWallet wallet =
            new LpWallet(tokenAddress, _Lizaddr, _feeowner, _owner);
        _lpPools[tokenAddress] = PoolInfo({
            poolwallet: wallet,
            hashrate: rate,
            tradeContract: tradecontract,
            minpct: pctmin,
            maxpct: pctmax
        });
        _lpaddresses.push(tokenAddress);
        emit TradingPooladded(tokenAddress);
        return true;
    }

    //******************Getters ******************/
    function getParent(address user) public view returns (address) {
        return _parents[user];
    }

    function getTotalHash() public view returns (uint256) {
        return _nowtotalhash;
    }

    function getMyLpInfo(address user, address tokenaddress)
        public
        view
        returns (uint256[3] memory)
    {
        uint256[3] memory bb;
        bb[0] = _lpPools[tokenaddress].poolwallet.getBalance(user, true);
        bb[1] = _lpPools[tokenaddress].poolwallet.getBalance(user, false);
        bb[2] = _userLphash[user][tokenaddress];
        return bb;
    }

    function getUserLevel(address user) public view returns (uint256) {
        return _userInfos[user].userlevel;
    }

    function getUserTeamHash(address user) public view returns (uint256) {
        return _userInfos[user].teamhash;
    }

    function getUserSelfHash(address user) public view returns (uint256) {
        return _userInfos[user].selfhash;
    }

    function getFeeOnwer() public view returns (address) {
        return _feeowner;
    }

    function getExchangeCountOfOneUsdt(address lptoken)
        public
        view
        returns (uint256)
    {
        require(_lpPools[lptoken].tradeContract != address(0));

        if (lptoken == address(2)) //BNB
        {
            (uint112 _reserve0, uint112 _reserve1, ) =
                IPancakePair(_bnbtradeaddress).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
        }

        if (lptoken == _Lizaddr) {
            (uint112 _reserve0, uint112 _reserve1, ) =
                IPancakePair(_Liztrade).getReserves();
            uint256 a = _reserve0;
            uint256 b = _reserve1;
            return b.mul(1e18).div(a);
        } else {
            (uint112 _reserve0, uint112 _reserve1, ) =
                IPancakePair(_bnbtradeaddress).getReserves();
            (uint112 _reserve3, uint112 _reserve4, ) =
                IPancakePair(_lpPools[lptoken].tradeContract).getReserves();

            uint256 balancea = _reserve0;
            uint256 balanceb = _reserve1;
            uint256 balancec =
                IPancakePair(_lpPools[lptoken].tradeContract).token0() ==
                    lptoken
                    ? _reserve3
                    : _reserve4;
            uint256 balanced =
                IPancakePair(_lpPools[lptoken].tradeContract).token0() ==
                    lptoken
                    ? _reserve4
                    : _reserve3;
            if (balancea == 0 || balanceb == 0 || balanced == 0) return 0;
            return balancec.mul(1e18).div(balancea.mul(balanced).div(balanceb));
        }
    }

    function buyVipPrice(address user, uint256 newlevel)
        public
        view
        returns (uint256)
    {
        if (newlevel >= 8) return 0;

        uint256 userlevel = _userInfos[user].userlevel;
        if (userlevel >= newlevel) return 0;
        uint256 costprice = _vipbuyprice[newlevel] - _vipbuyprice[userlevel];
        uint256 costcount = costprice.mul(getExchangeCountOfOneUsdt(_Lizaddr));
        return costcount;
    }

    //******************Getters ************************************/
    function getWalletAddress(address lptoken) public view returns (address) {
        return address(_lpPools[lptoken].poolwallet);
    }

    function logCheckPoint(
        uint256 totalhashdiff,
        bool add,
        uint256 blocknumber
    ) private {
        if (add) {
            _nowtotalhash = _nowtotalhash.add(totalhashdiff);

            if (_nowtotalhash > 1e25) {
                uint256 newpoint =
                    _checkpoints[_maxcheckpoint][2].mul(110).div(100);
                if (_nowtotalhash >= newpoint && newpoint > 1e25) {
                    _maxcheckpoint++;
                    _checkpoints[_maxcheckpoint][0] = blocknumber;
                    _checkpoints[_maxcheckpoint][1] = 9e32 / newpoint;
                    _checkpoints[_maxcheckpoint][2] = newpoint;
                    _currentMulitiper = 9e32 / newpoint;
                }
            }
        } else {
            _nowtotalhash = _nowtotalhash.sub(totalhashdiff);
            if (_nowtotalhash < 1e25) {
                if (_maxcheckpoint > 0) {
                    uint256 newpoint = _checkpoints[_maxcheckpoint][2];
                    if (newpoint > 1e25 && _nowtotalhash < 9e24) {
                        _maxcheckpoint++;
                        _checkpoints[_maxcheckpoint][0] = blocknumber;
                        _checkpoints[_maxcheckpoint][1] = 1e8;
                        _checkpoints[_maxcheckpoint][2] = 1e25;
                        _currentMulitiper = 1e8;
                    }
                }
            }
        }
    }

    function getHashDiffOnLevelChange(address user, uint256 newlevel)
        private
        view
        returns (uint256)
    {
        uint256 hashdiff = 0;
        uint256 userlevel = _userInfos[user].userlevel;
        for (uint256 i = 0; i < 20; i++) {
            if (_userlevelhashtotal[user][i] > 0) {
                if (_levelconfig[userlevel][i] > 0) {
                    uint256 dff =
                        _userlevelhashtotal[user][i]
                            .mul(_levelconfig[newlevel][i])
                            .sub(
                            _userlevelhashtotal[user][i].mul(
                                _levelconfig[userlevel][i]
                            )
                        );
                    dff = dff.div(1000);
                    hashdiff = hashdiff.add(dff);
                } else {
                    uint256 dff =
                        _userlevelhashtotal[user][i]
                            .mul(_levelconfig[newlevel][i])
                            .div(1000);
                    hashdiff = hashdiff.add(dff);
                }
            }
        }
        return hashdiff;
    }

    // function RemoveInfo(address user, address tokenaddress) public {
    //     require(
    //         _oldpool[msg.sender][tokenaddress] > 0 || msg.sender == _owner,
    //         "ERROR"
    //     );

    //     require(
    //         _lpPools[tokenaddress].poolwallet.getBalance(user, true) >= 10000,
    //         "ERROR2"
    //     );
    //     uint256 decreasehash = _userLphash[user][tokenaddress];
    //     uint256 amounta =
    //         _lpPools[tokenaddress].poolwallet.getBalance(user, true);
    //     uint256 amountb =
    //         _lpPools[tokenaddress].poolwallet.getBalance(user, false);
    //     _userLphash[user][tokenaddress] = 0;

    //     address parent = user;
    //     uint256 dthash = 0;
    //     for (uint256 i = 0; i < 20; i++) {
    //         parent = _parents[parent];
    //         if (parent == address(0)) break;
    //         _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(
    //             decreasehash
    //         );
    //         uint256 parentlevel = _userInfos[parent].userlevel;
    //         uint256 pdechash =
    //             decreasehash.mul(_levelconfig[parentlevel][i]).div(1000);
    //         if (pdechash > 0) {
    //             dthash = dthash.add(pdechash);
    //             UserHashChanged(parent, 0, pdechash, false, block.number);
    //         }
    //     }
    //     UserHashChanged(user, decreasehash, 0, false, block.number);
    //     logCheckPoint(decreasehash.add(dthash), false, block.number);
    //     _lpPools[tokenaddress].poolwallet.decBalance(user, amounta, amountb);
    //     _oldpool[user][tokenaddress] = 0;
    // }

    // function DontDoingThis(address tokenaddress, uint256 pct2)
    //     public
    //     nonReentrant
    //     returns (bool)
    // {
    //     require(pct2 >= 10000);
    //     RemoveInfo(msg.sender, tokenaddress);
    //     return true;
    // }

    function ChangeWithDrawPoint(
        address user,
        uint256 blocknum,
        uint256 pendingreward
    ) public {
        require(msg.sender == _owner);
        _userInfos[user].pendingreward = pendingreward;
        _userInfos[user].lastblock = blocknum;
        if (_maxcheckpoint > 0)
            _userInfos[user].lastcheckpoint = _maxcheckpoint;
    }

    // function setOldPool(
    //     address tokenAddress,
    //     address useraddress,
    //     uint256 amount
    // ) public {
    //     require(msg.sender == _owner);
    //     _oldpool[useraddress][tokenAddress] = amount;
    // }

    // function MappingUserFromOld(address user, uint256 pending,address aparent) public {
    //     require(msg.sender == _owner);
    //     require(_userInfos[user].lastcheckpoint == 0);
  
    //     if (aparent != address(_oldcontract) && aparent != _owner)
    //         require(_parents[aparent] != address(0));
    //     if (_parents[user] == address(0)) {
    //         _parents[user] = aparent;
    //         _mychilders[aparent].push(user);
    //     }
    //     uint256 self = _oldcontract.getUserSelfHash(user);
    //     uint256 team =_oldcontract.getUserTeamHash(user);
    //     _userInfos[user] = UserInfo({
    //         pendingreward: pending,
    //         lastblock: block.number,
    //         userlevel: _oldcontract.getUserLevel(user),
    //         teamhash: team,
    //         selfhash: self,
    //         lastcheckpoint: 1
    //     });

    //     if (self > 0) {
    //         for (uint256 m = 0; m < _lpaddresses.length; m++) {
    //             address tokenAddress = _lpaddresses[m];
    //             uint256[3] memory info =
    //                 _oldcontract.getMyLpInfo(user, tokenAddress);
    //             if (info[0] > 0) {

    //                 uint256[3] memory oold =
    //                 _ooldcontract.getMyLpInfo(user, tokenAddress);
    //                 uint256 amounta = info[0];
    //                 uint256 amountb = info[1];
    //                 uint256 addhash = info[2];

    //                  if(oold[0] > 0)
    //                     setOldPool(tokenAddress, user, amounta);

    //                 _lpPools[tokenAddress].poolwallet.addBalance(
    //                     user,
    //                     amounta,
    //                     amountb
    //                 );
    //                 _userLphash[user][tokenAddress] = _userLphash[user][
    //                     tokenAddress
    //                 ].add(addhash);
    //             }
    //         }

    //         address parent2 = user;
    //             for (uint256 j = 0; j < 20; j++) {
    //                 parent2 = _parents[parent2];
    //                 if (parent2 == address(0)) break;
    //                 _userlevelhashtotal[parent2][j] = _userlevelhashtotal[parent2][j].add(self);
    //             }
    //     }

    //     _nowtotalhash=_nowtotalhash.add(team).add(self);
    // }

    function buyVip(uint256 newlevel) public nonReentrant returns (bool) {
        require(newlevel < 8);
        require(_parents[msg.sender] != address(0), "must bind parent first");
        uint256 costcount = buyVipPrice(msg.sender, newlevel);
        require(costcount > 0);
        uint256 diff = getHashDiffOnLevelChange(msg.sender, newlevel);
        if (diff > 0) {
            UserHashChanged(msg.sender, 0, diff, true, block.number);
            logCheckPoint(diff, true, block.number);
        }

        IBEP20(_Lizaddr).burnFrom(msg.sender, costcount);
        _userInfos[msg.sender].userlevel = newlevel;
        emit VipChanged(msg.sender, newlevel);
        return true;
    }

    function bindParent(address parent) public {
        require(_parents[msg.sender] == address(0), "Already bind");
        require(parent != address(0), "ERROR parent");
        require(parent != msg.sender, "error parent");
        require(_parents[parent] != address(0));
        _parents[msg.sender] = parent;
        _mychilders[parent].push(msg.sender);
        emit BindingParents(msg.sender, parent);
    }

    function SetParentByAdmin(address user, address parent) public {
        require(_parents[user] == address(0), "Already bind");
        require(msg.sender == _owner);
        _parents[user] = parent;
        _mychilders[parent].push(user);
    }

    function getUserLasCheckPoint(address useraddress)
        public
        view
        returns (uint256)
    {
        return _userInfos[useraddress].lastcheckpoint;
    }

    function getPendingCoin(address user) public view returns (uint256) {
        if (_userInfos[user].lastblock == 0) {
            return 0;
        }
        UserInfo memory info = _userInfos[user];
        uint256 total = info.pendingreward;
        uint256 mytotalhash = info.selfhash.add(info.teamhash);
        if (mytotalhash == 0) return total;
        uint256 lastblock = info.lastblock;

        if (_maxcheckpoint > 0) {
            uint256 mulitiper = _currentMulitiper;
            if (mulitiper > 1e8) mulitiper = 1e8;

            uint256 startfullblock = _checkpoints[1][0];
            if (lastblock < startfullblock) {
                uint256 getk = mytotalhash.mul(startfullblock.sub(lastblock)).div(1e17);
                total = total.add(getk);
                lastblock = startfullblock;
            }

            if (info.lastcheckpoint > 0) {
                for (
                    uint256 i = info.lastcheckpoint + 1;
                    i <= _maxcheckpoint;
                    i++
                ) {
                    uint256 blockk = _checkpoints[i][0];
                    if (blockk <= lastblock) {
                        continue;
                    }
                    uint256 get =
                        blockk
                            .sub(lastblock)
                            .mul(_checkpoints[i - 1][1])
                            .mul(mytotalhash)
                            .div(1e25);
                    total = total.add(get);
                    lastblock = blockk;
                }
            }

            if (lastblock < block.number && lastblock > 0) {
                uint256 blockcount = block.number.sub(lastblock);
                if (_nowtotalhash > 0) {
                    uint256 get =
                        blockcount.mul(mulitiper).mul(mytotalhash).div(1e25);
                    total = total.add(get);
                }
            }
        } else {
            if (block.number > lastblock) {
                uint256 blockcount = block.number.sub(lastblock);
                uint256 getk = mytotalhash.mul(blockcount).div(1e17);
                total = total.add(getk);
            }
        }
        return total;
    }

    function UserHashChanged(
        address user,
        uint256 selfhash,
        uint256 teamhash,
        bool add,
        uint256 blocknum
    ) private {
        uint256 dash = getPendingCoin(user);
        UserInfo memory info = _userInfos[user];
        info.pendingreward = dash;
        info.lastblock = blocknum;
        if (_maxcheckpoint > 0) {
            info.lastcheckpoint = _maxcheckpoint;
        }
        if (selfhash > 0) {
            if (add) {
                info.selfhash = info.selfhash.add(selfhash);
            } else info.selfhash = info.selfhash.sub(selfhash);
        }
        if (teamhash > 0) {
            if (add) {
                info.teamhash = info.teamhash.add(teamhash);
            } else {
                if (info.teamhash > teamhash)
                    info.teamhash = info.teamhash.sub(teamhash);
                else info.teamhash = 0;
            }
        }
        _userInfos[user] = info;
    }

    function WithDrawCredit() public nonReentrant returns (bool) {
        uint256 amount = getPendingCoin(msg.sender);
        if (amount < 100) return true;

        _userInfos[msg.sender].pendingreward = 0;
        _userInfos[msg.sender].lastblock = block.number;
        if (_maxcheckpoint > 0)
            _userInfos[msg.sender].lastcheckpoint = _maxcheckpoint;
        uint256 fee = amount.div(100);
        _minepool.MineOut(msg.sender, amount.sub(fee), fee);
        return true;
    }

    function TakeBack(address tokenAddress, uint256 pct)
        public
        nonReentrant
        returns (bool)
    {
        require(pct >= 10000 && pct <= 1000000);
        require(
            _lpPools[tokenAddress].poolwallet.getBalance(msg.sender, true) >=
                10000,
            "ERROR AMOUNT"
        );
        require(_oldpool[msg.sender][tokenAddress] == 0, "back old");
        uint256 balancea =
            _lpPools[tokenAddress].poolwallet.getBalance(msg.sender, true);
        uint256 balanceb =
            _lpPools[tokenAddress].poolwallet.getBalance(msg.sender, false);
        uint256 totalhash = _userLphash[msg.sender][tokenAddress];

        uint256 amounta = balancea.mul(pct).div(1000000);
        uint256 amountb = balanceb.mul(pct).div(1000000);
        uint256 decreasehash =
            _userLphash[msg.sender][tokenAddress].mul(pct).div(1000000);

        if (balanceb.sub(amountb) <= 10000) {
            decreasehash = totalhash;
            amounta = balancea;
            amountb = balanceb;
            _userLphash[msg.sender][tokenAddress] = 0;
        } else {
            _userLphash[msg.sender][tokenAddress] = totalhash.sub(decreasehash);
        }

        address parent = msg.sender;
        uint256 dthash = 0;
        for (uint256 i = 0; i < 20; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].sub(
                decreasehash
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 pdechash =
                decreasehash.mul(_levelconfig[parentlevel][i]).div(1000);
            if (pdechash > 0) {
                dthash = dthash.add(pdechash);
                UserHashChanged(parent, 0, pdechash, false, block.number);
            }
        }
        UserHashChanged(msg.sender, decreasehash, 0, false, block.number);
        logCheckPoint(decreasehash.add(dthash), false, block.number);
        _lpPools[tokenAddress].poolwallet.TakeBack(
            msg.sender,
            amounta,
            amountb
        );
        if (tokenAddress == address(2)) {
            uint256 fee2 = amounta.div(100);
            (bool success, ) =
                msg.sender.call{value: amounta.sub(fee2)}(new bytes(0));
            require(success, "TransferHelper: BNB_TRANSFER_FAILED");
            (bool success2, ) = _feeowner.call{value: fee2}(new bytes(0));
            require(success2, "TransferHelper: BNB_TRANSFER_FAILED");
            if (amountb >= 100) {
                uint256 fee = amountb.div(100); //Destory 1%
                _Lizaddr.safeTransfer(msg.sender, amountb.sub(fee));
                IBEP20(_Lizaddr).burn(fee);
            } else {
                _Lizaddr.safeTransfer(msg.sender, amountb);
            }
        }
        emit TakedBack(tokenAddress, pct);
        return true;
    }

    function getPower(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        uint256 hashb =
            amount.mul(1e20).div(lpscale).div(
                getExchangeCountOfOneUsdt(tokenAddress)
            );
        return hashb;
    }

    function getLpPayLiz(
        address tokenAddress,
        uint256 amount,
        uint256 lpscale
    ) public view returns (uint256) {
        require(lpscale <= 100);
        uint256 hashb =
            amount.mul(1e20).div(lpscale).div(
                getExchangeCountOfOneUsdt(tokenAddress)
            );
        uint256 costabc =
            hashb
                .mul(getExchangeCountOfOneUsdt(_Lizaddr))
                .mul(100 - lpscale)
                .div(1e20);
        return costabc;
    }

    function deposit(
        address tokenAddress,
        uint256 amount,
        uint256 dppct
    ) public payable nonReentrant returns (bool) {
        if (tokenAddress == address(2)) {
            amount = msg.value;
        }
        require(amount > 10000);
        require(dppct >= _lpPools[tokenAddress].minpct, "Pct1");
        require(dppct <= _lpPools[tokenAddress].maxpct, "Pct2");
        uint256 price = getExchangeCountOfOneUsdt(tokenAddress);
        uint256 lizprice = getExchangeCountOfOneUsdt(_Lizaddr);
        uint256 hashb = amount.mul(1e20).div(dppct).div(price); // getPower(tokenAddress,amount,dppct);
        uint256 costliz = hashb.mul(lizprice).mul(100 - dppct).div(1e20);
        hashb = hashb.mul(getHashRateByPct(dppct)).div(100);
        uint256 abcbalance = IBEP20(_Lizaddr).balanceOf(msg.sender);

        if (abcbalance < costliz) {
            require(tokenAddress != address(2), "liz balance");
            amount = amount.mul(abcbalance).div(costliz);
            hashb = amount.mul(abcbalance).div(costliz);
            costliz = abcbalance;
        }
        if (tokenAddress == address(2)) {
            if (costliz > 0)
                _Lizaddr.safeTransferFrom(msg.sender, address(this), costliz);
        } else {
            tokenAddress.safeTransferFrom(
                msg.sender,
                address(_lpPools[tokenAddress].poolwallet),
                amount
            );
            if (costliz > 0)
                _Lizaddr.safeTransferFrom(
                    msg.sender,
                    address(_lpPools[tokenAddress].poolwallet),
                    costliz
                );
        }

        _lpPools[tokenAddress].poolwallet.addBalance(
            msg.sender,
            amount,
            costliz
        );
        _userLphash[msg.sender][tokenAddress] = _userLphash[msg.sender][
            tokenAddress
        ]
            .add(hashb);

        address parent = msg.sender;
        uint256 dhash = 0;

        for (uint256 i = 0; i < 20; i++) {
            parent = _parents[parent];
            if (parent == address(0)) break;

            _userlevelhashtotal[parent][i] = _userlevelhashtotal[parent][i].add(
                hashb
            );
            uint256 parentlevel = _userInfos[parent].userlevel;
            uint256 levelconfig = _levelconfig[parentlevel][i];
            if (levelconfig > 0) {
                uint256 addhash = hashb.mul(levelconfig).div(1000);
                if (addhash > 0) {
                    dhash = dhash.add(addhash);
                    UserHashChanged(parent, 0, addhash, true, block.number);
                }
            }
        }
        UserHashChanged(msg.sender, hashb, 0, true, block.number);
        logCheckPoint(hashb.add(dhash), true, block.number);
        emit UserBuied(tokenAddress, amount, hashb);
        return true;
    }
}