/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WBNB() external pure returns (address);

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
/**
 * IERC20 standard interface.
 *
*/
interface IERC20 {

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
 * Allows for contract ownership along with multi-address authorization
 */
contract Auth is Context{
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor() {
        address msgSender = _msgSender();
        owner = msgSender;
        authorizations[owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}


contract AnySwapper is Auth {
    using SafeMath for uint;
    using SafeMath for uint256;
    address defaultContract;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IUniswapV2Router02  router;

    struct PartnerAllocations {
        uint256 totalPaidOut;
        uint256 totalPaitOutInPartnerToken;
        uint    partnerFee;
    }
    mapping (address => PartnerAllocations) public partner;
    mapping (address => bool) public isPartner;
    mapping (address => address) public receiverAddress;

    uint256 public  defaultTokenMinimumHODL     = 10 * 10**6 * 10**9;  // initial 10 million tokens required to use SWAP features
    uint256 feeDenominator                      = 10000;
    uint256 recieverFee                         = 250; //Fee for EarnPay team to convert partner token to EarnPay

    constructor () {
        
        router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        defaultContract = 0x3492180e11E55a5c5470931D3c2de55B9Fbe2143;
    }

    receive() external payable {
        buyTokens(msg.value, defaultContract);
    }

    function setTokenMinimumHODL(uint256 _newMinimum) external onlyOwner{
        defaultTokenMinimumHODL = _newMinimum;
    }

    function setPartner(address _partnerAddress, address _receiverAddress, uint _partnerFee) external onlyOwner{
        require(!isPartner[_partnerAddress], 'Already a Partner');
        receiverAddress[_partnerAddress] = _receiverAddress;
        isPartner[_partnerAddress] = true;
        partner[_partnerAddress].partnerFee = _partnerFee;
    }
    function removePartner(address _partnerAddress) external onlyOwner{
        require(isPartner[_partnerAddress], 'Not a Partner');
        isPartner[_partnerAddress] = false;
    }
    function getPartnerInfo(address _partnerAddress) public view returns (uint256, uint, address, bool)
    {
        return (partner[_partnerAddress].totalPaidOut, partner[_partnerAddress].partnerFee, receiverAddress[_partnerAddress], isPartner[_partnerAddress]);
    }

    function getBuyPath(address selectedContract) internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = selectedContract;
        return path;
    }

    function buyTokens(uint amt, address selectedContract) internal {
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(
            0,
            getBuyPath(selectedContract),
            msg.sender,
            block.timestamp
        );
    }
    function buySingleToken(address selectedContract) external payable returns (bool){
        buyTokens(msg.value, selectedContract);
        return true;
    }
    function buyMultipleTokens(address selectedContract, address selectedContract2) external payable returns (bool){
        uint part = msg.value.div(2);
        buyTokens(part, selectedContract);
        buyTokens(msg.value.sub(part), selectedContract2);
        return true;
    }

    function updateRouter(address _router) external onlyOwner
    {
        router = IUniswapV2Router02(_router);
        WBNB = router.WBNB();
    }

    function updateDefaultContract(address _defaultContract) external onlyOwner
    {
        defaultContract = _defaultContract;
    }

    function calculatePartnerFees(address partnerAddress, uint256 _amountIn) public view returns (uint256)
    {
        uint256 fee = _amountIn.mul(partner[partnerAddress].partnerFee).div(feeDenominator);
            return fee;
    }

    function getPartnerFee(address partnerAddress) public view returns (uint256)
    {
        return partner[partnerAddress].partnerFee;
    }


    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
        require((_tokenIn == defaultContract && isPartner[_tokenOut]) || (_tokenOut == defaultContract && isPartner[_tokenIn]), "Only Partner Pairs Allowed for Swapping");
        require(!(_tokenIn == _tokenOut), "Unable to swap for the same token");
        require(_amountIn > 0 && _amountOutMin >0, "amounts need to be > 0");
        uint256 _finalAmountIn;
        uint feeAmount;
        if(_tokenIn == defaultContract)
        {
            feeAmount = calculatePartnerFees(_tokenOut, _amountIn);
            require(IERC20(defaultContract).balanceOf(msg.sender).sub(_amountIn) >= defaultTokenMinimumHODL, 'Not holding the minimum EarnPay required');
            _finalAmountIn = _amountIn.sub(feeAmount);
        }
        else {
            require(IERC20(defaultContract).balanceOf(msg.sender) >= defaultTokenMinimumHODL, 'Not holding the minimum EarnPay required');
            feeAmount = 0;
            _finalAmountIn = _amountIn;
        }
        //first we need to transfer the amount in tokens from the msg.sender to this contract
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        IERC20(_tokenIn).approve(address(router), _finalAmountIn);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WBNB, tokenOut]
        //the if statement below takes into account if token in or token out is WBNB.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WBNB || _tokenOut == WBNB) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        }
        else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WBNB;
            path[2] = _tokenOut;
        }
        //_finalAmountIn = _amountIn;

        //If Converting from the default contract then send part of the fees to the Partner Address; 
        if(_tokenIn == defaultContract)
        {
            IERC20(defaultContract).transfer(receiverAddress[_tokenOut], feeAmount);
            partner[_tokenOut].totalPaidOut = partner[_tokenOut].totalPaidOut.add(feeAmount);
            uint256 newAmountOutMin = getAmountOutMin(_tokenIn, _tokenOut, _finalAmountIn);
            router.swapExactTokensForTokens(_finalAmountIn, newAmountOutMin, path, _to, block.timestamp);
        }
        
        //If Converting from a partner to the default contract, then send part of the fees from the receieving token to the Default Contract for distributor accumulations
        if(_tokenOut == defaultContract)
        {
            uint256 balanceBefore = IERC20(defaultContract).balanceOf(address(this));
            router.swapExactTokensForTokens(_finalAmountIn, _amountOutMin, path, address(this), block.timestamp);
            uint256 delta = IERC20(defaultContract).balanceOf(address(this)).sub(balanceBefore);
            uint256 fee = calculatePartnerFees(_tokenIn, delta);
            uint256 finalPurchase = delta.sub(fee);
            
            //Send final purchase (with fee removed) to recipient (swapper fees taken inside the default contract)
            IERC20(defaultContract).transferFrom(address(this), _to, finalPurchase);
            //Sends Fee Allocation to partner reciever address
            IERC20(defaultContract).transfer(receiverAddress[_tokenOut], fee);
            partner[_tokenIn].totalPaidOut = partner[_tokenIn].totalPaidOut.add(fee);
        }
        else
        {
            router.swapExactTokensForTokens(_finalAmountIn, _amountOutMin, path, _to, block.timestamp);
        }
    }
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256) {

       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WBNB, tokenOut]
       //the if statement below takes into account if token in or token out is WBNB.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WBNB || _tokenOut == WBNB) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WBNB;
            path[2] = _tokenOut;
        }
        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  
}