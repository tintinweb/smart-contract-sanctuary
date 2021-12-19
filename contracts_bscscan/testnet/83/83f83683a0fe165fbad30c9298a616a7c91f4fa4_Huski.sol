/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Utilities
library Address 
{
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal 
    {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) 
    {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) 
    {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) 
    {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) 
    {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) 
    {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) 
    {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) 
    {
        if (success) 
        {
            return returndata;
        } 
        else 
        {
            if (returndata.length > 0) 
            {
                assembly 
                {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } 
            else 
            {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) 
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) 
    {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () 
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) 
    {
        return _owner;
    }

    modifier onlyOwner() 
    {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner 
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner 
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Chainlink contracts
interface LinkTokenInterface 
{
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

contract VRFRequestIDBase 
{
    /**
    * @notice returns the seed which is actually input to the VRF coordinator
    *
    * @dev To prevent repetition of VRF output due to repetition of the
    * @dev user-supplied seed, that seed is combined in a hash with the
    * @dev user-specific nonce, and the address of the consuming contract. The
    * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
    * @dev the final seed, but the nonce does protect against repetition in
    * @dev requests which are included in a single block.
    *
    * @param _userSeed VRF seed input provided by user
    * @param _requester Address of the requesting contract
    * @param _nonce User-specific nonce at the time of the request
    */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
    * @notice Returns the id for this request
    * @param _keyHash The serviceAgreement ID to be used for this request
    * @param _vRFInputSeed The seed to be passed directly to the VRF
    * @return The id for this request
    *
    * @dev Note that _vRFInputSeed is not the seed passed by the consuming
    * @dev contract, but the one generated by makeVRFInputSeed
    */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

abstract contract VRFConsumerBase is VRFRequestIDBase 
{
    /**
    * @notice fulfillRandomness handles the VRF response. Your contract must
    * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
    * @notice principles to keep in mind when implementing your fulfillRandomness
    * @notice method.
    *
    * @dev VRFConsumerBase expects its subcontracts to have a method with this
    * @dev signature, and will call it once it has verified the proof
    * @dev associated with the randomness. (It is triggered via a call to
    * @dev rawFulfillRandomness, below.)
    *
    * @param requestId The Id initially returned by requestRandomness
    * @param randomness the VRF output
    */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
    * @dev In order to keep backwards compatibility we have kept the user
    * seed field around. We remove the use of it because given that the blockhash
    * enters later, it overrides whatever randomness the used seed provides.
    * Given that it adds no security, and can easily lead to misunderstandings,
    * we have removed it from usage and can now provide a simpler API.
    */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
    * @notice requestRandomness initiates a request for VRF output given _seed
    *
    * @dev The fulfillRandomness method receives the output, once it's provided
    * @dev by the Oracle, and verified by the vrfCoordinator.
    *
    * @dev The _keyHash must already be registered with the VRFCoordinator, and
    * @dev the _fee must exceed the fee specified during registration of the
    * @dev _keyHash.
    *
    * @dev The _seed parameter is vestigial, and is kept only for API
    * @dev compatibility with older versions. It can't *hurt* to mix in some of
    * @dev your own randomness, here, but it's not necessary because the VRF
    * @dev oracle will mix the hash of the block containing your request into the
    * @dev VRF seed it ultimately uses.
    *
    * @param _keyHash ID of public key against which randomness is generated
    * @param _fee The amount of LINK to send with the request
    *
    * @return requestId unique ID for this request
    *
    * @dev The returned requestId can be used to distinguish responses to
    * @dev concurrent requests. It is passed as the first argument to
    * @dev fulfillRandomness.
    */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal immutable LINK;
    address private immutable vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
        private nonces;

    /**
    * @param _vrfCoordinator address of VRFCoordinator contract
    * @param _link address of LINK token contract
    *
    * @dev https://docs.chain.link/docs/link-token-contracts
    */
    constructor(address _vrfCoordinator, address _link) {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// Uniswap interfaces
interface IUniswapV2Factory 
{
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

interface IUniswapV2Pair 
{
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

interface IUniswapV2Router01 
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// ERC20 standards
interface IERC20 
{
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 
{
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Lottery is VRFConsumerBase
{
    // Lottery
    struct TicketBalance
    {
        uint256 balance;
        uint256 timestamp;
        address owner;
    }

    event TicketsBought(address indexed from, uint256 amount);
    event LotteryAwarded(address indexed to, uint256 value);
    event LotteryRollover(uint256 value);

    mapping(address => uint256) internal _holderIndexes;
    TicketBalance[] internal _tickets;
    
    uint256 internal _ticketCount;
    uint256 internal _holderCount;

    uint256 internal _ticketPrice;

    mapping (address => uint256) internal _tRewards;
    uint internal _tUnclaimedRewards;
    
    address internal _lotteryWallet;
    uint256 internal _lotteryStart;
    uint256 internal _lotteryDuration;

    function lotteryPool() public view virtual returns (uint256) {}
    function buyTickets() public payable virtual returns (bool) { }
    function claimReward(address account) public virtual returns (bool) { }

    function _checkLottery() internal virtual { }
    function _lotteryRollover() internal virtual returns (bool) { }
    function _drawLottery(uint256 randomNumber) internal virtual { }
    function _claimReward(address account) internal virtual { }

    // Chainlink
    bytes32 internal _vrfKeyHash;
    uint256 internal _vrfFee;
    bool internal _vrfLocked;

    /*
        Lottery functions
    */

    function totalUnclaimedRewards() public view returns (uint256)
    {
        return _tUnclaimedRewards;
    }

    function remainingLotteryTime() public view returns (uint256)
    {
        return _lotteryStart + _lotteryDuration - block.timestamp;
    }

    function ticketsBought() public view returns (uint256)
    {
        return _ticketCount;
    }

    function ticketBalanceOf(address account) public view returns (uint256)
    {
        uint256 index = _holderIndexes[account];

        if(_tickets[index].timestamp == _lotteryStart)
        {
            return _tickets[index].balance;
        }

        return 0;
    }

    function _lotteryFinished() internal view returns (bool)
    {
        return (block.timestamp > _lotteryStart + _lotteryDuration);
    }

    function _restartLottery() internal 
    {
        _lotteryStart = block.timestamp;
        _ticketCount = 0;
        _holderCount = 0;
    }

    /*
        Chainlink functions
    */

    event RequestsRandom();
    event GotRandom();

    //Requests randomness 
    function requestRandomTicket() internal returns (bytes32 requestId) 
    {
        require(LINK.balanceOf(address(this)) >= _vrfFee, "Not enough LINK - fill contract with faucet");
        _vrfLocked = true;
        emit RequestsRandom();
        return requestRandomness(_vrfKeyHash, _vrfFee);
    }

    //Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override 
    { 
        emit GotRandom();
        _drawLottery(randomness);
    }
}


// Huski token
contract Huski is IERC20, IERC20Metadata, Lottery, Context, Ownable
{
    // Libraries
    using Address for address;

    // Token
    event Burn(address indexed from, uint256 value);

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _tTotal;
    uint256 private _rTotal;

    uint256 private _tReflectTotal;
    uint256 private _tBurnTotal;
    uint256 private _tLotteryTotal;
    
    uint256 private constant _burnTax = 5;
    uint256 private constant _reflectTax = 5;
    uint256 private constant _lotteryTax = 5;

    uint256 private constant MAX = ~uint256(0);

    // Uniswap
    event LiquidityLocked(address indexed from, uint256 hskiValue, uint256 bnbValue, uint256 lpValue);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address[] private _bnbToLINK;
    address[] private _bnbToHSKI;

    //DEBUG
    uint256 public vrfNumber;
    uint256 public lastDrawnTicket;

    constructor()    
        VRFConsumerBase
        (
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, //TESTNET VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06  //TESTNET LINK Token
        )
    {
        //Set token values
        _name = "Huski";
        _symbol = "HSKI";
        _decimals = 18;

        _tTotal = (10**9) * (10**_decimals); //1 billion
        _rTotal = (MAX - (MAX % _tTotal));

        //Supply sent to contract deployer
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(this), _msgSender(), _tTotal);

        //Setup lottery
        _vrfFee = (10**17) * 2; //0.2 LINK
        _vrfKeyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186; //TESTNET

        _ticketPrice = 10**15; //0.001 BNB
        _lotteryDuration = 14 days;
        _lotteryWallet = address(this);
        
        _restartLottery();

        //Uniswap router values
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //TESTNET https://pancake.kiemtienonline360.com/#/swap
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        //Uniswap routing paths
        //BNB -> LINK
        _bnbToLINK = new address[](2);
        _bnbToLINK[0] = _uniswapV2Router.WETH();
        _bnbToLINK[1] = 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06; //LINK Testnet address

        //BNB -> HSKI
        _bnbToHSKI = new address[](2);
        _bnbToHSKI[0] = _uniswapV2Router.WETH();
        _bnbToHSKI[1] = address(this);
    }

    // Recieve BNB from Pancakeswap router when swaping
    receive() external payable { } 

    /*
        Uniswap methods
    */
    
    function _lockLiquidity() private
    {
        //Use all BNB in contract address
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0);
        uint256 bnbAmount = contractBalance / 2;

        uint256 startingHskiAmount = balanceOf(address(this));

        //Swap BNB for HSKI
        _swapBNBforHSKI(bnbAmount);

        uint256 hskiAmount = balanceOf(address(this)) - startingHskiAmount;

        //Add liquidity to uniswap
        (uint256 hskiAdded, uint256 bnbAdded, uint256 lpReceived) = _addLiquidity(hskiAmount, bnbAmount);
        
        emit LiquidityLocked(address(this), hskiAdded, bnbAdded, lpReceived);
    }

    function _swapBNBforHSKI(uint256 bnbAmount) private
    {
        //Swap BNB and recieve HSKI to contract address
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value : bnbAmount } //BNB value
        (
            0,              //Minimum HSKI
            _bnbToHSKI,     //Routing path
            address(this),  //Receiver
            block.timestamp //Deadline
        );
    }

    function _swapBNBforLINK(uint256 bnbAmount, uint256 linkAmount) public
    {
        //Swap BNB and recieve LINK to contract address 
        uniswapV2Router.swapETHForExactTokens{ value : bnbAmount } //BNB value
        (
            linkAmount,     //Exact LINK
            _bnbToLINK,     //Routing path
            address(this),  //Receiver
            block.timestamp //Deadline
        );
    }

    function _addLiquidity(uint256 hskiAmount, uint256 bnbAmount) private returns (uint256, uint256, uint256)
    {
        //Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), hskiAmount);

        //Add liquidity to BNB/HSKI pool
        return uniswapV2Router.addLiquidityETH{ value : bnbAmount } //BNB value
        (
            address(this),  //Token address
            hskiAmount,     //HSKI amount
            0,              //Minimum HSKI
            0,              //Minimum BNB
            address(this),  //LP token receiver
            block.timestamp //Deadline
        );
    }

    /*
        Lottery methods
    */

    // DEBUG METHOD
    function stopLottery() public onlyOwner returns (bool) //DO NOT DEPLOY TO MAINNET
    {
        _lotteryStart = block.timestamp - 100 days;

        _checkLottery();

        return true;
    }

    function lotteryPool() public view override returns(uint256)
    {
        return balanceOf(_lotteryWallet) - _tUnclaimedRewards;
    }

    function buyTickets() public payable override returns (bool)
    {
        require(_lotteryFinished() == false);
        uint256 value = msg.value; //Value is in BNB
        require(value >= _ticketPrice);

        address sender = _msgSender();
        uint256 senderIndex = _holderIndexes[sender];
        uint256 ticketAmount = value / _ticketPrice;

        if(senderIndex <= 0 || _tickets[senderIndex].timestamp != _lotteryStart)
        {
            _holderCount += 1;

            _holderIndexes[sender] = _holderCount;

            TicketBalance memory senderBalance;
            senderBalance.balance = ticketAmount;
            senderBalance.owner = sender;
            senderBalance.timestamp = block.timestamp;

            if(_holderCount >= _tickets.length)
            {
                _tickets.push(senderBalance);
            } 
            else
            {
                _tickets[_holderCount] = senderBalance;
            }
        }
        else
        {
            _tickets[senderIndex].balance += ticketAmount;
        }

        _ticketCount += ticketAmount;

        emit TicketsBought(sender, ticketAmount);

        return true;
    }

    function claimReward(address account) public override returns (bool)
    {
        _claimReward(account);
        return true;
    }

    function _checkLottery() internal override
    {
        if(_lotteryFinished() && _vrfLocked == false)
        {
            if(_lotteryRollover() == false)
            {
                requestRandomTicket();
            }
        }
    }

    function _lotteryRollover() internal override returns(bool)
    {
        if(LINK.balanceOf(address(this)) < _vrfFee)
        {
            _swapBNBforLINK(address(this).balance, _vrfFee);
        }

        if(_ticketCount <= 0 || LINK.balanceOf(address(this)) < _vrfFee)
        {
            _restartLottery();

            emit LotteryRollover(lotteryPool());
            return true;
        }

        return false;
    }

    //Called by Lottery.fulfillRandomness()
    function _drawLottery(uint256 randomNumber) internal override
    {
        uint256 drawnTicket = randomNumber % _ticketCount; //Random number within range

        address winner = address(this);
        uint256 ticketSum = 0;

        //For each ticket purchased add senders address to tickets array
        for (uint256 i = 1; i < _holderCount + 1; i++) 
        {
            ticketSum += _tickets[i].balance;

            if(drawnTicket < ticketSum)
            {
                //Winner
                winner = _tickets[i].owner;
                break;
            }
        }

        uint256 tLotteryPool = lotteryPool();

        _tRewards[winner] += tLotteryPool;

        _tUnclaimedRewards += tLotteryPool;

        _restartLottery();

        _vrfLocked = false;

        emit LotteryAwarded(winner, tLotteryPool);
    }

    function _claimReward(address account) internal override
    {
        uint256 tReward = _tRewards[account];

        require(tReward > 0);

        _transfer(_lotteryWallet, account, tReward);

        _tUnclaimedRewards = _tUnclaimedRewards - tReward;

        _tLotteryTotal = _tLotteryTotal + tReward;

        if(address(this).balance > 0)
        {
            _lockLiquidity();
        }
    }

    /*
        Token methods
    */

    function name() public view override returns (string memory) 
    {
        return _name;
    }

    function symbol() public view override returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public view override returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) 
    {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) 
    {
        return _tokenFromReflection(_rOwned[account]);
    }

    function totalReflection() public view returns (uint256) 
    {
        return _tReflectTotal;
    }

    function totalBurn() public view returns (uint256)
    {
        return _tBurnTotal;
    }

    function totalLotteryRewards() public view returns (uint256)
    {
        return _tLotteryTotal;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        unchecked 
        {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) 
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) 
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        unchecked 
        {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function burn(uint256 amount) public returns (bool)
    {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public returns (bool)
    {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
        return true;
    }

    function _tokenFromReflection(uint256 rAmount) private view returns(uint256) 
    {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate; //tAmount
    }

    function _reflectionFromToken(uint256 tAmount) public view returns(uint256) 
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        return tAmount * currentRate; //rAmount
    }

    function _reflectFee(uint256 rReflect, uint256 tReflect) private 
    {
        _rTotal = _rTotal - rReflect;
        _tReflectTotal = _tReflectTotal + tReflect;
    }

    function _burnFee(uint256 rBurn, uint256 tBurn) private
    {
        _rTotal = _rTotal - rBurn;
        _tTotal = _tTotal - tBurn;
        _tBurnTotal = _tBurnTotal + tBurn;
    }

    function _lotteryFee(uint256 rLottery) private
    {
        _rOwned[_lotteryWallet] = _rOwned[_lotteryWallet] + rLottery;
    }

    function _transferValues(uint256 tAmount) private view returns (uint256, uint256, uint256)
    {
        uint256 currentRate = _getRate();

        uint256 rAmount = tAmount * currentRate;

        uint256 tTax = (tAmount / 100) * (_reflectTax + _burnTax + _lotteryTax);
        uint256 rTax = tTax * currentRate;

        uint256 tTransferAmount = tAmount - tTax;
        uint256 rTransferAmount = rAmount - rTax;

        return(rAmount, rTransferAmount, tTransferAmount);
    }

    function _taxValues(uint256 tAmount) private view returns(uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 currentRate = _getRate();

        uint256 tReflect = (tAmount / 100) * _reflectTax;
        uint256 tBurn = (tAmount / 100) * _burnTax;
        uint256 tLottery = (tAmount / 100) * _lotteryTax;

        uint256 rReflect = tReflect * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 rLottery = tLottery * currentRate;

        return (rReflect, tReflect, rBurn, tBurn, rLottery, tLottery);
    }

    function _getRate() private view returns(uint256) 
    {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) 
    {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      

        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        {
            return (rSupply, tSupply);
        }
    }

    function _transfer(address sender, address recipient, uint256 tAmount) private 
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");

        (uint256 rAmount, uint256 rTransferAmount, uint256 tTransferAmount) = _transferValues(tAmount);
        (uint256 rReflect, uint256 tReflect, uint256 rBurn, uint256 tBurn, uint256 rLottery,) = _taxValues(tAmount);
        
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        _reflectFee(rReflect, tReflect);
        _burnFee(rBurn, tBurn);
        _lotteryFee(rLottery);
        
        _checkLottery();

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) private 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 tAmount) private
    {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _rOwned[account];
        uint256 rAmount = _reflectionFromToken(tAmount);
        require(accountBalance >= rAmount, "ERC20: burn amount exceeds balance");

        unchecked 
        {
            _rOwned[account] = accountBalance - rAmount;
        }

        _burnFee(rAmount, tAmount);

        emit Burn(account, tAmount);
    }
}