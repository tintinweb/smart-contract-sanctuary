/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT (@JVP)

/* SOHO Presale contract
*
*/

pragma solidity >=0.6.8;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        _previousOwner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


contract v7_presale is Context, Ownable {

// -- var --
    using SafeMath for uint256;

    enum status {
        presale,
        sale,
        postSale
    }

    status sale_status;

    uint256 individualBnbCap;
    uint256 nbOfTokenPerBNB;

    IERC20 token;
    address uniPair;
    IPancakeRouter02 public pancakeSwapV2Router;

    mapping (address => uint256) private allowanceOf;

    event PriceAndCap(uint256, uint256);
    event AddToWhitelist(address);
    event RemoveFromWhitelist(address);
    event Buy(address, uint256);
    event LiquidityTransferred();

    modifier beforeSale() {
        require(sale_status == status.presale, "Sale: already started");
        _;
    }

    modifier duringSale() {
        require(sale_status == status.sale, "Sale: not active");
        _;
    }

    modifier postSale() {
        require(sale_status == status.postSale, "Sale: sale not over");
        _;
    }


// -- init --
    constructor(address _token_address) {
        token = IERC20(_token_address);
        sale_status = status.presale;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //ropsten
        
        // set the rest of the contract variables
        pancakeSwapV2Router = _pancakeRouter;
    }


// -- presale --
    function setPriceAndCap(uint256 _individualBnbCap, uint256 _nbOfTokenPerBNB) external onlyOwner beforeSale {
        individualBnbCap = _individualBnbCap; //use 18 decimals
        nbOfTokenPerBNB = _nbOfTokenPerBNB; //use 9 decimals
        emit PriceAndCap(individualBnbCap, nbOfTokenPerBNB);

    }

    //@dev whitelisting can be modified during the sale.
    //     If this is not expected behavior, add the duringSale modifier
    function addWhitelisting(address[] calldata adrs) external onlyOwner {
        require(individualBnbCap > 0, "First set the cap & price");
        for (uint256 i = 0; i < adrs.length; i++) {
            if (allowanceOf[adrs[i]] == 0) {
                allowanceOf[adrs[i]] = individualBnbCap;
                emit AddToWhitelist(adrs[i]);
            }
        }
    }

    function removeWhitelisting(address adr) external onlyOwner {
        require(allowanceOf[adr] != 0, "Whitelist: address not whitelisted");
         allowanceOf[adr] = 0;
         emit RemoveFromWhitelist(adr);
    }

// -- sale --
    function startSale() external onlyOwner {
         sale_status = status.sale;
    }

    function getAllowanceLeftInBNB(address adr) external view returns(uint256) {
         return allowanceOf[adr];
    }

    //@dev max total buy is based only on whitelisted allowance cumsum - act accordingly
    function buy() external payable duringSale {
         require(allowanceOf[msg.sender] > 0, "Whitelist: 0 allowance");
         require(allowanceOf[msg.sender] >= msg.value, "Sale: Too much BNB sent");
         _buy(msg.sender, msg.value);
         emit Buy(msg.sender, msg.value);
    }


    function _buy(address sender, uint256 amountBNB) internal {
         allowanceOf[sender] = allowanceOf[sender].sub(amountBNB, "Internal: _buy: underflow. Not enough allowance!");
         uint256 amountToken = amountBNB.mul(nbOfTokenPerBNB);
         token.transfer(sender, amountToken);
    }

    function getAmountOfTokens(uint256 inputBnbInWei) public view returns(uint256) {
        return inputBnbInWei.mul(nbOfTokenPerBNB);
    }   

// -- post sale --

    //@dev convert BNB received and token left in pool liquidity. LP send to owner.
    //     Uni Router handles both scenario : existing and non-existing pair
    //@param TokenPerBNB inital number of token for 1 BNB in the pool
    //@param liquidityRatioInPercents ratio of presale BNB sent to the pool
    //       while the rest is transfered back to owner()
    function concludeAndAddLiquidity() external onlyOwner {

        uint256 balance_BNB = address(this).balance;
        uint256 balance_token = token.balanceOf(address(this));

        uint256 BNB_for_pool = balance_BNB;

        uint256 nbOfTokenPerBNBAfterSale = 180; //price to add liquidity: 1BNB per 180B tokens

        if (balance_token.div(BNB_for_pool) >= nbOfTokenPerBNBAfterSale) {
            balance_token = nbOfTokenPerBNBAfterSale.mul(BNB_for_pool);
            } 
        else {
            BNB_for_pool = balance_token.div(nbOfTokenPerBNBAfterSale);
            }

        TransferHelper.safeApprove(address(token), address(pancakeSwapV2Router), balance_token);
        pancakeSwapV2Router.addLiquidityETH{value: BNB_for_pool}(
            address(token),
            balance_token,
            balance_token, // sLiPpaGe iS uNaVoIdAbLe --> Initial liquidity, no slippage
            BNB_for_pool, // sLiPpaGe iS uNaVoIdAbLe --> Initial liquidity, no slippage
            owner(),
            block.timestamp
        );

        TransferHelper.safeTransfer(address(this), owner(), token.balanceOf(address(this)));
        TransferHelper.safeTransferETH(owner(), address(this).balance); //transfer the rest

        emit LiquidityTransferred();
    }

    function getFutureLiquidity() public view returns(uint256, uint256) {

        uint256 balance_BNB = address(this).balance;
        uint256 balance_token = token.balanceOf(address(this));

        uint256 BNB_for_pool = balance_BNB;

        uint256 nbOfTokenPerBNBAfterSale = 180; //price to add liquidity: 1BNB per 180B tokens

        if (balance_token.div(BNB_for_pool) >= nbOfTokenPerBNBAfterSale) {
            balance_token = nbOfTokenPerBNBAfterSale.mul(BNB_for_pool);
            } 
        else {
            BNB_for_pool = balance_token.div(nbOfTokenPerBNBAfterSale);
            }

        return (balance_token, BNB_for_pool);

    }

// -- div --
//@dev prevent this contract being spammed by shitcoins
    fallback () external {
        revert();
    }

}