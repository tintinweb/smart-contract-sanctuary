/**
 *Submitted for verification at polygonscan.com on 2021-07-19
*/

pragma solidity ^0.6.12;
//import "./Interfaces.sol";
pragma experimental ABIEncoderV2;

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

interface IChi is IERC20 {
    function mint(uint256 value) external;
    function free(uint256 value) external returns (uint256 freed);
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IGasDiscountExtension {
    function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external view returns (IChi, uint256);
}

interface IAggregationExecutor is IGasDiscountExtension {
    function callBytes(bytes calldata data) external payable;  // 0xd9c45357
}

struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

interface I1inch {
    function discountedSwap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft, uint256 chiSpent);
        
    function Swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);
        
}

interface IWarden {
    function tradeWithLearned(
        IERC20    _src,
        uint256   _srcAmount,
        IERC20    _dest,
        uint256   _minDestAmount,
        uint256   _learnedId,
        uint256   _partnerIndex,
        address   _receiver
    )
        external
        payable
        returns(uint256 _destAmount);

function tradeStrategies(
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        uint256[]   memory _subRoutes,
        IERC20[]    memory _correspondentTokens,
        uint256     _partnerIndex,
        address     _receiver
    )
        external
        payable
        returns(uint256 _destAmount);

function tradingPairLearnedLength(address _src, address _dest) external returns (uint);

function tradingPairLearnedHashes(address _src, address _dest, uint _index) external returns (bytes32);

function learnedIds(bytes32 _hash) external returns (uint);

}

interface IWETH {

function deposit() external payable ;

function withdraw(uint wad) external ;

function approve(address guy, uint wad) external returns (bool) ;

function transfer(address dst, uint wad) external returns (bool) ;

}

contract MultiSwap {
    //mapping (address => IAggregationExecutor)  public addr;
    
    receive() external payable {}
    
    constructor() public {}
    
    function multiSwap(address _from, address _to) external payable {
        IWarden ROUTER = IWarden(0x3657952d7bA5A0A4799809b5B6fdfF9ec5B46293);
        SwapDescription memory desc;
        IERC20[] memory path;
        uint[] memory Route;
        uint amount;
        if (_from == address(0)) {
            amount = msg.value;
            _from = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
            IWETH(_from).deposit{value:amount}();
        } else {
        require(IERC20(_from).allowance(msg.sender,address(this)) >= amount,"transfer amount exceeds allowance");
        }
        desc.srcToken = IERC20(_from);
        desc.dstToken = IERC20(_to);
        desc.srcReceiver = 0xFEFF91C350bB564cA5Dc7D6F7DcD12ac092F94FF;
        desc.dstReceiver = address(this);
        desc.amount = amount;
        desc.minReturnAmount = 0;
        desc.flags = 0;
        IWETH(_from).approve(address(ROUTER), uint(~0));
        //IWETH(_from).transfer(desc.srcReceiver, amount);
        //if (IERC20(_from).allowance(address(this),0x11111112542D85B3EF69AE05771c2dCCff4fAa26) < amount) IERC20(_from).approve(0x11111112542D85B3EF69AE05771c2dCCff4fAa26, uint(~0));
        //if (IERC20(_from).allowance(address(this),0x11111112542D85B3EF69AE05771c2dCCff4fAa26) < amount) IERC20(_from).approve(0x11111112542D85B3EF69AE05771c2dCCff4fAa26, uint(~0));
        //require(IERC20(_from).transferFrom(address(this),desc.srcReceiver,amount), "transfer failed");
        //desc.permit = '0x';
        bytes32 hashes = ROUTER.tradingPairLearnedHashes(_from, _to, ROUTER.tradingPairLearnedLength(_from, _to) - 1);
        //ROUTER.tradeWithLearned(IERC20(_from), amount, IERC20(_to), ROUTER.learnedIds(hashes), 0, 0, msg.sender);
        //return;
        Route = new uint[](1);
        Route[0] = ROUTER.tradingPairLearnedLength(_from, _to) - 1;
        path= new IERC20[](2);
        path[0] = IERC20(_from);
        path[1] = IERC20(_to);
        IWarden(ROUTER).tradeStrategies(IERC20(_from), amount, IERC20(_to), 0, Route, path, 0, msg.sender);
        //I1inch(0x11111112542D85B3EF69AE05771c2dCCff4fAa26).Swap(IAggregationExecutor(0x0F85A912448279111694F4Ba4F85dC641c54b594), desc,'0x');
    }
}