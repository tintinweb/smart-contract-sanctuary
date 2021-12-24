/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// File: Presale/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: Presale/Ownable.sol



pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Presale/library/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: Presale/interfaces/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: Presale/interfaces/IPancakeFactory.sol


pragma solidity ^0.8.0;

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

// File: Presale/interfaces/IPancakeRouter01.sol


pragma solidity ^0.8.0;

interface IPancakeRouter01 {
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

// File: Presale/interfaces/IPancakeRouter02.sol


pragma solidity ^0.8.0;


interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: Presale/Presale.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;







contract Presale is Ownable{

    using SafeMath for uint256;

    uint public count = 0;
    uint public upfrontfee = 100;
    uint8 public salesFeeInPercent = 2;

    // Declare a set state variable    
    address public teamAddr = 0xE813d775f33a97BDA25D71240525C724423D4Cd0;
    address public devAddr = 0xE813d775f33a97BDA25D71240525C724423D4Cd0;
    
    //# PancakeSwap on BSC mainnet
    // address pancakeSwapFactoryAddr = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    // address pancakeSwapRouterAddr = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // address WBNBAddr = 0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c;
      
    //# PancakeSwap on BSC testnet:
    address public pancakeSwapFactoryAddr = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address public pancakeSwapRouterAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public WBNBAddr = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;    

    ////////////////////////////// MAPPINGS ///////////////////////////////////

    mapping(uint256 => PresaleInfo) public presaleInfo;
    mapping(uint256 => PresalectCounts) public presalectCounts;
    mapping(uint256 => PresaleParticipationCriteria) public presaleParticipationCriteria;
    mapping(uint256 => uint8) public salesFeeInPercentForAProject;

    mapping(uint256 => InternalData) public internalData;
    mapping(address => bool) public isUserWhitelistedToStartProject;
    mapping(uint256 => mapping(address => Participant)) public participant;

    ////////////////////////////// ENUMS ///////////////////////////////////

    enum PresaleType {open, onlyWhiteListed, onlyTokenHolders}
    enum PreSaleStatus {pending, inProgress, succeed, failed}
    enum Withdrawtype {burn, withdraw}

    ////////////////////////////// STRUCTS ///////////////////////////////////

    struct InternalData {
        uint totalTokensSold;
        uint revenueFromPresale;
        uint tokensAddedToLiquidity;
        uint extraTokens;
        uint poolShareBNB;
        uint devTeamShareBNB;
        uint ownersShareBNB;
    }

    struct Participant {
        uint256 value;
        uint256 tokens;
        bool whiteListed;
    }
    
    struct PresaleTimes{
        uint256 startedAt;
        uint256 expiredAt;
    }

    struct ReqestedTokens{
        uint256 minTokensReq;
        uint256 maxTokensReq;
    }

    struct PresalectCounts {
        uint256 participantsCount;
        uint256 claimsCount;
    }
    
    struct PresaleInfo {
        // Contract Info
        PresaleType typeOfPresale;
        address preSaleContractAddr;
        address presaleOwnerAddr;
        
        // Token distribution
        uint256 priceOfEachToken;
        uint256 tokensForSale;              // 1000
        uint256 reservedTokensPCForLP;      // 70% = 0.7   =>   1700/1.7 = 700
        uint256 remainingTokensForSale;
        uint256 accumulatedBalance;
        address pairAddress;
        PreSaleStatus preSaleStatus;
    }

    struct PresaleParticipationCriteria {
        // Contract Info
        address preSaleContractAddr;
        
        // Participation Criteria
        address criteriaTokenAddr;
        uint256 minTokensForParticipation;
        ReqestedTokens reqestedTokens;
        uint256 softCap;
        PresaleTimes presaleTimes;  
    }    

    ////////////////////////////// MODIFIRES //////////////////////////////

    modifier isIDValid(uint _id) {
        require (presaleInfo[_id].preSaleContractAddr != address(0), "Not a valid ID");
        _;
    }

    modifier isPresaleActive(uint _id) {
        require (block.timestamp >= presaleParticipationCriteria[_id].presaleTimes.startedAt, "Presale hasn't begin yet. please wait");
        require( block.timestamp < presaleParticipationCriteria[_id].presaleTimes.expiredAt, "Presale is over. Try next time");
        if(presaleInfo[_id].preSaleStatus == PreSaleStatus.pending){
            presaleInfo[_id].preSaleStatus = PreSaleStatus.inProgress;
        }
        require(presaleInfo[_id].preSaleStatus == PreSaleStatus.inProgress, "Presale is not in progress");
        _;
    }

    modifier onlyPresaleOwner(uint _id) {
        require(presaleInfo[_id].presaleOwnerAddr == _msgSender(), "Ownable: caller is not the owner of this presale");
        _;
    }

    ////////////////////////////// FUNCTIONS ///////////////////////////////////

    function setFactoryAddr(address _address) public onlyOwner {
        pancakeSwapFactoryAddr = _address;
    } 

    function setRouterAddr(address _address) public onlyOwner {
        pancakeSwapRouterAddr = _address;
    }

    function whiteListUsersToStartProject(address _address) public onlyOwner {
        isUserWhitelistedToStartProject[_address] = true;
    }

    function whiteListUsersToBuyTokens(uint _id, address _address) public onlyPresaleOwner(_id) {
        participant[_id][_address].whiteListed = true;
    }

    function updateFees(uint _upfrontFee, uint8 _salesFeeInPercent) public onlyOwner {
        upfrontfee = _upfrontFee;
        salesFeeInPercent = _salesFeeInPercent;
    }

    function updateSalesFeeInPercentForAProject(uint _id, uint8 _fee) public onlyOwner {
        salesFeeInPercentForAProject[_id] = _fee;
    }

    function setPresale(
        // Contract Info
        PresaleType _presaleType,
        address _preSaleContractAddress,
        address _criteriaTokenAddr,
        uint8 _reservedTokensPCForLP,
        uint256 _tokensForSale,

        // Participation Criteria
        uint256 _priceOfEachToken,
        uint256 _minTokensForParticipation,
        PresaleTimes memory _presaleTimes,
        ReqestedTokens memory _reqestedTokens,
        uint256 _softCap

        ) payable public returns(uint){

        if( msg.sender != owner() ){
            if(!isUserWhitelistedToStartProject[msg.sender]){
                require( msg.value >= upfrontfee, "Insufficient Funds to start the presale");
            }
        }
        
        if(_presaleType == PresaleType.onlyTokenHolders){
            require( _criteriaTokenAddr != address(0), "Criteria token address shouldn't be a null address");
        }

        require( _reservedTokensPCForLP >= 50 && _reservedTokensPCForLP <= 100, "Tokens for liquidity should be at least 50% of the total tokens offered on sale");
        require( _softCap >= _tokensForSale.div(2), "softcap should be at least 50% of the total tokens offered on sale");
        
        require( _preSaleContractAddress != address(0), "Presale project address can't be null");
        require( _tokensForSale > 0, "tokens for sale must be more than 0");

        require( _reqestedTokens.maxTokensReq > _reqestedTokens.minTokensReq, "_maxTokensReq > _minTokensReq");
        require( _presaleTimes.expiredAt > _presaleTimes.startedAt, "expiredAt > startedAt");
        require( 
            _presaleTimes.startedAt > block.timestamp && 
            _presaleTimes.expiredAt > block.timestamp,
            "expiredAt and startedAt should be more than now"
            );
        
        uint reservedTokens = _tokensForSale.mul(_reservedTokensPCForLP).div(100);
        bool transfer = IERC20(_preSaleContractAddress).transferFrom(msg.sender, address(this), _tokensForSale.add(reservedTokens));
        require( transfer, "Unable to transfer presale tokens to the contract");

        count++;
        
        address _address = IPancakeFactory(pancakeSwapFactoryAddr).createPair(_preSaleContractAddress, WBNBAddr);

        presaleInfo[count] = PresaleInfo(
            _presaleType,
            _preSaleContractAddress,
            msg.sender,

            _priceOfEachToken,
            _tokensForSale,                     // 1000    tokensForSale
            _reservedTokensPCForLP,
            _tokensForSale,                     // remainingTokensForSale = tokensForSale (initially)
            0,
            _address,
            PreSaleStatus.pending
        );

        presaleParticipationCriteria[count] = PresaleParticipationCriteria(
            _preSaleContractAddress,
            _criteriaTokenAddr,
            _minTokensForParticipation,
            _reqestedTokens,
            _softCap,
            _presaleTimes
        );

        presalectCounts[count] = PresalectCounts (
            0,
            0
        );

        salesFeeInPercentForAProject[count] = salesFeeInPercent;       
        return count;
    }

    function deletePresaleContractInfo (uint256 _id) public onlyPresaleOwner(_id) isIDValid(_id){
        require(presaleInfo[_id].preSaleStatus == PreSaleStatus.pending, "Presale is in progress, can't delete it now");
        delete presaleInfo[_id];
        delete presalectCounts[_id];
        delete presaleParticipationCriteria[_id];
        // removeActiveSale(_id);
    }

    function buyTokensOnPresale(uint256 _id, uint256 _numOfTokensRequested) payable public isIDValid(_id) isPresaleActive(_id)  {

        PresaleInfo memory info = presaleInfo[_id];
        PresaleParticipationCriteria memory criteria = presaleParticipationCriteria[_id];
        Participant memory currentParticipant = participant[_id][msg.sender];

        require(info.remainingTokensForSale > 0 , "the sale is sold out");

        if(info.typeOfPresale == PresaleType.onlyWhiteListed){
            require( currentParticipant.whiteListed == true, "Only whitelisted users are allowed to participate");
        }
        else if(info.typeOfPresale == PresaleType.onlyTokenHolders){
            require(IERC20(criteria.criteriaTokenAddr).balanceOf(msg.sender) >= criteria.minTokensForParticipation, "You don't hold enough criteria tokens");
        }

        require(_numOfTokensRequested <= info.remainingTokensForSale, "insufficient tokens to fulfill this order");
        require(msg.value >= _numOfTokensRequested*info.priceOfEachToken, "insufficient funds");
        
        if(currentParticipant.tokens == 0){
            presalectCounts[_id].participantsCount++;
            require(_numOfTokensRequested >= criteria.reqestedTokens.minTokensReq, "Request for tokens is low, Please request more than minTokensReq");
        }
        require(_numOfTokensRequested + currentParticipant.tokens <= criteria.reqestedTokens.maxTokensReq, "Request for tokens is high, Please request less than maxTokensReq");
        

        presaleInfo[_id].accumulatedBalance = info.accumulatedBalance.add(msg.value);
        presaleInfo[_id].remainingTokensForSale = info.remainingTokensForSale.sub(_numOfTokensRequested);

        uint newValue = currentParticipant.value.add(msg.value);
        uint newTokens = currentParticipant.tokens.add(_numOfTokensRequested);

        participant[_id][msg.sender] = Participant(newValue, newTokens, currentParticipant.whiteListed);
        
    }

    function claimTokensOrARefund(uint _id) public isIDValid(_id) {
        
        Participant memory _participant = participant[_id][msg.sender];

        PreSaleStatus _status = presaleInfo[_id].preSaleStatus;
        uint totalBalance = preSaleTokenBalanceOfContract(_id);
        require(_status == PreSaleStatus.succeed || _status == PreSaleStatus.failed, "Presale is not concluded yet");
        
        
        if (_status == PreSaleStatus.succeed){
            require(_participant.tokens > 0, "No tokens to claim");
            require(_participant.tokens <= totalBalance, "Not enough tokens are available");
            bool tokenDistribution = IERC20(presaleParticipationCriteria[_id].preSaleContractAddr).transfer(msg.sender, _participant.tokens);
            require(tokenDistribution, "Unable to transfer tokens to the participant");
            participant[_id][msg.sender] = Participant(0, 0, _participant.whiteListed);
            presalectCounts[_id].claimsCount++;
        }
        else if(_status == PreSaleStatus.failed){
            require(_participant.value > 0, "No amount to refund");
            bool refund = payable(msg.sender).send(_participant.value);
            require(refund, "Unable to refund amount to the participant");
            participant[_id][msg.sender] = Participant(0, 0, _participant.whiteListed);
            presalectCounts[_id].claimsCount++;

        }

    }
    
    function endPresale(uint _id) public onlyPresaleOwner(_id) isIDValid(_id) returns (uint, uint, uint){
        
        require(presaleInfo[_id].preSaleStatus == PreSaleStatus.inProgress, "Presale is not in progress");

        PresaleInfo memory info = presaleInfo[_id];

        require(
            block.timestamp > presaleParticipationCriteria[_id].presaleTimes.expiredAt ||
            info.remainingTokensForSale == 0, 
            "Presale is not over yet"
        );
        
        uint256 totalTokensSold = info.tokensForSale.sub(info.remainingTokensForSale);
        
        if( totalTokensSold >= presaleParticipationCriteria[_id].softCap ){
            
            uint256 tokensToAddLiquidity = totalTokensSold.mul(info.reservedTokensPCForLP).div(100);
            
                uint256 poolShareBNB = distributeRevenue(_id);

                require(IERC20(info.preSaleContractAddr).approve(pancakeSwapRouterAddr, tokensToAddLiquidity), "unable to approve token tranfer to pancakeSwapRouterAddr");

                (uint amountToken, uint amountETH, uint liquidity) = IPancakeRouter02(pancakeSwapRouterAddr).addLiquidityETH{value : poolShareBNB}(
                    info.preSaleContractAddr,
                    tokensToAddLiquidity,
                    0,
                    0,
                    info.presaleOwnerAddr,
                    block.timestamp + 5*60
                );

                internalData[_id].totalTokensSold = totalTokensSold;
                internalData[_id].tokensAddedToLiquidity = tokensToAddLiquidity;
                internalData[_id].extraTokens = info.remainingTokensForSale +  info.remainingTokensForSale.mul(info.reservedTokensPCForLP).div(100) ;
                presaleInfo[_id].preSaleStatus = PreSaleStatus.succeed;

                return (amountToken, amountETH, liquidity);
            
        }
        else {

            internalData[_id].extraTokens = info.tokensForSale +  info.tokensForSale.mul(info.reservedTokensPCForLP).div(100);
            presaleInfo[_id].preSaleStatus = PreSaleStatus.failed;
            // removeActiveSale(_id);
            return (0,0,0);

        }
        
    }

    function distributeRevenue(uint _id) private returns (uint256) {

        PresaleInfo memory info = presaleInfo[_id];

        uint256 revenueFromPresale = info.accumulatedBalance;
        require(revenueFromPresale > 0, "No revenue to add liquidity");

        uint256 devTeamShareBNB = revenueFromPresale.mul(salesFeeInPercentForAProject[_id]).div(100);
        uint256 poolShareBNB = revenueFromPresale.mul(info.reservedTokensPCForLP).div(100);
        uint256 ownersShareBNB = revenueFromPresale.sub(poolShareBNB.add(devTeamShareBNB));

        // require(payable(info.presaleOwnerAddr).send(ownersShareBNB), "cannot send owner's share");
        payable(info.presaleOwnerAddr).transfer(ownersShareBNB);


        uint devShare = devTeamShareBNB.mul(75).div(100);
        // require(payable(devAddr).send(devShare), "cannot send dev's share"); 
        payable(devAddr).transfer(devShare);

        uint teamShare = devTeamShareBNB.sub(devShare);
        // require(payable(teamAddr).send(teamShare), "cannot send devTeam's share");
        payable(teamAddr).transfer(teamShare);
        
        internalData[_id].revenueFromPresale = revenueFromPresale;
        internalData[_id].poolShareBNB = poolShareBNB;
        internalData[_id].devTeamShareBNB = devTeamShareBNB;
        internalData[_id].ownersShareBNB = ownersShareBNB;

        return  poolShareBNB;

    }

    function burnOrWithdrawTokens(uint _id, Withdrawtype _withdrawtype ) public onlyPresaleOwner(_id) isIDValid(_id){

        require(internalData[_id].extraTokens > 0, "No tokens to withdraw");

        PresaleInfo memory info = presaleInfo[_id];

        // require( 
        //     info.remainingTokensForSale != 0 && info.remainingTokensForSale != 1, "Can't withdraw before concluding the sales"
        //     );

        IERC20 _token = IERC20(info.preSaleContractAddr);
        uint totalTokens = _token.balanceOf(address(this));

        require( totalTokens >= internalData[_id].extraTokens, "Contract has no presale tokens");

        if(_withdrawtype == Withdrawtype.withdraw ){
            bool tokenDistribution = _token.transfer(msg.sender, internalData[_id].extraTokens);
            require( tokenDistribution, "unable to send tokens to the owner");
            internalData[_id].extraTokens = 0;
        }
        else{
            bool tokenDistribution = _token.transfer(0x000000000000000000000000000000000000dEaD , internalData[_id].extraTokens);
            require( tokenDistribution, "unable to send tokens to the owner");
            internalData[_id].extraTokens = 0;
        }
        // presaleInfo[_id].tokensForSale = 0;
        // presaleInfo[_id].remainingTokensForSale = 0;
        // // presaleInfo[_id].preSaleStatus = PreSaleStatus.consluded;
    }

    function BNBbalanceOfContract() public view returns(uint){
        return address(this).balance;
    }

    function updatePresaleTime(uint _id, uint _starttime, uint _endTime) public onlyPresaleOwner(_id) isIDValid(_id){
        
        require(presaleInfo[_id].preSaleStatus == PreSaleStatus.pending, "Presale is in progress, you can't change criteria now");

        presaleParticipationCriteria[_id].presaleTimes.startedAt = _starttime;
        presaleParticipationCriteria[_id].presaleTimes.expiredAt = _endTime;
    }

    function updateParticipationCriteria (
            uint _id, uint _priceOfEachToken, uint _minTokensReq, uint _maxTokensReq, uint _softCap
        ) public onlyPresaleOwner(_id) isIDValid(_id) {

        require(presaleInfo[_id].preSaleStatus == PreSaleStatus.pending, "Presale is in progress, you can't change criteria now");
        require( _softCap >= presaleInfo[_id].tokensForSale.div(2), "softcap should be at least 50% of the total tokens offered on sale");
        
        presaleInfo[_id].priceOfEachToken = _priceOfEachToken;
        presaleParticipationCriteria[_id].reqestedTokens.minTokensReq = _minTokensReq;
        presaleParticipationCriteria[_id].reqestedTokens.maxTokensReq = _maxTokensReq;
        presaleParticipationCriteria[_id].softCap = _softCap;
    }

    function updateteamAddr(address _teamAddr) public onlyOwner {
        teamAddr = _teamAddr;
    }

    // // Helping functions;
    function preSaleTokenBalanceOfContract (uint _id) public view returns(uint256){
        return IERC20(presaleParticipationCriteria[_id].preSaleContractAddr).balanceOf(address(this));
    }
    
    function preSaleTokenBalanceOfUser (uint _id) public view returns(uint256){       
        return IERC20(presaleInfo[_id].preSaleContractAddr).balanceOf(address(msg.sender));
    }

    function criteriaTokenBalanceOfUser(uint _id) public view returns (uint){
        return IERC20(presaleParticipationCriteria[_id].criteriaTokenAddr).balanceOf(address(msg.sender));
    }

}

    // function updateTokensForSale( uint _id, uint _tokensForSale, uint _reservedTokensPCForLP ) public onlyPresaleOwner(_id) isIDValid(_id) {
    //     presaleInfo[_id].tokensForSale = _tokensForSale;
    //     presaleInfo[_id].remainingTokensForSale = _tokensForSale;
    //     presaleInfo[_id].reservedTokensPCForLP = _reservedTokensPCForLP;
    // }

    // function setCriteriaToken(
    //     uint _id, 
    //     address _criteriaToken, 
    //     uint _minTokensForParticipation
    // ) public onlyPresaleOwner(_id) {
    //     presaleParticipationCriteria[_id].minTokensForParticipation = _minTokensForParticipation;
    //     presaleParticipationCriteria[_id].criteriaTokenAddr = _criteriaToken;
    // }


    // function pausePresale(uint _id) public onlyPresaleOwner(_id) isIDValid(_id) {
    //     presaleInfo[_id].preSaleStatus = PreSaleStatus.paused;
    // }
    
    // function unpausePresale(uint _id) public onlyPresaleOwner(_id) isIDValid(_id) {
    //     presaleInfo[_id].preSaleStatus = PreSaleStatus.inProgress;
    // }