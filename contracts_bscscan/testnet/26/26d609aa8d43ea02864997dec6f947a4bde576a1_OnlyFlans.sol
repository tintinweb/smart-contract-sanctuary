/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;


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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external pure returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external pure returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external pure returns (uint8);
}


/*
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IUniswapV2Router01 {
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

interface IUniswapV2Factory {
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


contract OnlyFlans is IERC20, IERC20Metadata
{
    using SafeMath for uint256;
    using Address for address; 
    
    string private constant tokenName = "OnlyFlans";
    string private constant tokenSymbol = "FLANS";
    uint8 private constant tokenDecimals = 9;
    uint256 public TokenMaxSupply = 1000000000000000 * (10 ** uint256(tokenDecimals));
    
    IUniswapV2Router02 public immutable UniswapV2Router;
    address public immutable UniswapV2Pair;
    
    uint256 private constant liquidityFee = 5;
    uint256 private constant holdersShareFee = 5;
    bool private penalization = false;
    bool private penalizationActivated = false;
    
    uint256 public holdersCirculatingSupply;
    uint256 private totalHolderShareFees;
    
    uint256 private constant maxAllowedTokenPerAddress = 10000000000000 * (10 ** uint8(tokenDecimals));
    
    address private constant projectFundAddress = 0x3174E3CC3C005a0F9B539D54D2a4943D5fDEd7d6;
    address private constant blackHoleAddress = 0x35F1D1D9f55da9fFf3Ba468B7CB91ff63adeAfCA;
    address private tokenCreator;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => uint256) private addressLastDividends;
    
    constructor()
    {
        //Give all tokens to creator address. 
        tokenCreator = msg.sender;
        balances[tokenCreator] = TokenMaxSupply;
        emit Transfer(address(0), tokenCreator, TokenMaxSupply);
        
        //This address will give 10% of tokens to Project Fund address
        uint256 projectFundAddressTokens = TokenMaxSupply.mul(10).div(100);
        balances[projectFundAddress] = projectFundAddressTokens;
        balances[tokenCreator] = balances[tokenCreator].sub(projectFundAddressTokens);
        emit Transfer(tokenCreator, projectFundAddress, projectFundAddressTokens);
        
        //1% of tokens to Black Hole address (max tokens per account)
        uint256 blackHoleAddressTokens = TokenMaxSupply.mul(1).div(100);
        balances[blackHoleAddress] = blackHoleAddressTokens;
        balances[tokenCreator] = balances[tokenCreator].sub(blackHoleAddressTokens);
        emit Transfer(tokenCreator, blackHoleAddress, blackHoleAddressTokens);
        
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        UniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        UniswapV2Router = uniswapV2Router;
    }
    
    function name() public pure override returns (string memory) {
        return tokenName;
    }

    function symbol() public pure override returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure override returns (uint8) {
        return tokenDecimals;
    }

    /**
    * @dev Returns the total supply of this token
    */
    function totalSupply() public view override returns (uint256)
    {
        return TokenMaxSupply;
    }
    
    /**
    * @dev Check the number of tokens owned by an address including holder reflections
    */
    function balanceOf(address addressToCheck) public view override returns (uint256)
    {
        return balances[addressToCheck] + GetAddressDividends(addressToCheck);
    }
    
    /**
    * @dev Check the allowance between addresses
    */
    function allowance(address from, address to) public view override returns (uint256)
    {
        return allowances[from][to];
    }
    
    /**
    * @dev Sets `amount` as the allowance of `receiverAddress` over the caller's tokens.
    */
    function approve(address receiverAddress, uint256 amount) public override returns (bool)
    {
        return ApproveTransaction(msg.sender, receiverAddress, amount);
    }
    
    /**
    * @dev Transfers tokens from one address to another. This includes receiving or sending to pancakeswap
    */
    function transfer(address addressToSend, uint256 amount) public override returns (bool)
    {
        return transferFrom(msg.sender, addressToSend, amount);
    }
    
    function transferFrom(address senderAddress, address addressToSend, uint256 amount) public override returns (bool)
    {
        return TransferTokens(senderAddress, addressToSend, amount);
    }

    /**
    * @dev Destroys tokens and decreases the max amount of tokens that exist
    */
    function BurnTokens(address tokensAddress, uint256 amount) public
    {
        require(tokensAddress != address(0), 'Invalid Address.');
        require(balances[tokensAddress] >= amount, 'Not enough tokens to burn');
        
        //Decrease the amount of token to be burned from address
        balances[tokensAddress] = balances[tokensAddress].sub(amount);
        //Decrease the max supply of tokens
        TokenMaxSupply = TokenMaxSupply.sub(amount);
        
        emit Transfer(tokensAddress, address(0), amount);
    }
    
    /**
    * @dev Increase the allowance between addresses
    */
    function IncreaseAddressAllowance(address addressToIncreae, uint256 amount) public returns (bool)
    {
        require(addressToIncreae != address(0), 'Invalid Address.');
        
        allowances[msg.sender][addressToIncreae] = (allowances[msg.sender][addressToIncreae].add(amount));
        
        emit Approval(msg.sender, addressToIncreae, allowances[msg.sender][addressToIncreae]);
        return true;
    }
    
    /**
    * @dev Decreases the allowance between addresses
    */
    function DecreaseAddressAllowance(address addressToDecrease, uint256 amount) public returns (bool)
    {
        require(addressToDecrease != address(0), 'Invalid Address.');
                
        uint256 oldValue = allowances[msg.sender][addressToDecrease];
        
        if (amount > oldValue) 
        {
            allowances[msg.sender][addressToDecrease] = 0;
        } 
        else 
        {
            allowances[msg.sender][addressToDecrease] = oldValue.sub(amount);
        }
        
        emit Approval(msg.sender, addressToDecrease, allowances[msg.sender][addressToDecrease]);
        return true;
    }
    
    /**
    * @dev Activates x2 fees when selling. Cannot be activated more than 1 time
    */
    function ActivatePenalization() public
    {
        require(msg.sender == tokenCreator, "This address cannot activate the multiplier");
        
        if(!penalizationActivated)
        {
            //If penalization has been activated, return to normal fees and prevent from been activated again
            penalization = true;
            penalizationActivated = true;
        }
        else
        {
            penalization = false;
        }
    }
    
    /**
    * @dev Transfers tokens from one address to another. This includes receiving or sending to pancakeswap
    */
    function TransferTokens(address sendingAddress, address addressToSend, uint256 amount) private returns (bool)
    {
        require(addressToSend != address(0), 'Invalid Address.');
        require(sendingAddress != address(0), 'Invalid sending Address.');
        
        /*if(sendingAddress != UniswapV2Pair)
        {
            require(GetAddressBalanceWithReflection(sendingAddress) >= amount, 'Not enough tokens to transfer.');
        }
        
        if(addressToSend != UniswapV2Pair)
        {
            require(balances[addressToSend] + amount <= maxAllowedTokenPerAddress, 'Cannot transfer tokens to this address. Max tokens in address is 1% of total supply');
        }*/
        
        ApproveTransaction(sendingAddress, addressToSend, amount);
        NoFeeTransaction(sendingAddress, addressToSend, amount);
        
        //projectFundAddress is excluded from fees
        /*if(sendingAddress == projectFundAddress || addressToSend == projectFundAddress)
        {
            NoFeeTransaction(sendingAddress, addressToSend, amount);
        }
        else
        {
            FeeTransaction(sendingAddress, addressToSend, amount);
        }*/
        
        //Reset adresses allowance
        allowances[sendingAddress][addressToSend] = 0;
        
        UpdateAndburnBlackHoleAddress();
        
        emit Transfer(sendingAddress, addressToSend, amount);
        return true;
    }
    
    function FeeTransaction(address sendingAddress, address addressToSend, uint256 amount) private
    {
        require(allowances[sendingAddress][addressToSend] >= amount, 'Allowance is not enough');
        
        //Calculate fees (holders + liquidity)
        uint256 holdersFee = amount.mul(holdersShareFee).div(100);
        uint256 liqFee = amount.mul(liquidityFee).div(100);
        
        //Exclude transaction address from receiving holder fees
        if(sendingAddress == UniswapV2Pair)
        {
            //Buying
            holdersCirculatingSupply = holdersCirculatingSupply.add(amount.sub(liqFee));
            addressLastDividends[addressToSend] = addressLastDividends[addressToSend].add(holdersFee);
        }
        else if(addressToSend == UniswapV2Pair)
        {
            //Selling
            if(penalization)
            {
                holdersFee *= 2;
                liqFee *= 2;   
            }
            holdersCirculatingSupply = holdersCirculatingSupply.sub(amount);
            addressLastDividends[sendingAddress] = addressLastDividends[sendingAddress].add(holdersFee);
        }
        else
        {
            //Transfer between address
            addressLastDividends[addressToSend] = addressLastDividends[addressToSend].add(holdersFee);
            addressLastDividends[sendingAddress] = addressLastDividends[sendingAddress].add(holdersFee);
        }
        
        //Decrease sender balance
        balances[sendingAddress] = balances[sendingAddress].sub(amount);
        
        //Calculate the amount that other address will receive 
        uint256 newAmount = amount - (holdersFee + liqFee);
        
        //Add the new amount to receiver address
        balances[addressToSend] = balances[addressToSend].add(newAmount);
        
        //Add holders fee to be shared later
        totalHolderShareFees = totalHolderShareFees.add(holdersFee);
        
        //Add liquidity fee to liquidity pool
        AddLiquidity(liqFee);
    }
    
    function NoFeeTransaction(address sendingAddress, address addressToSend, uint256 amount) private
    {
        require(allowances[sendingAddress][addressToSend] >= amount, 'Allowance is not enough');
        
        //Decrease sender balance
        balances[sendingAddress] = balances[sendingAddress].sub(amount);
        
        //Add the new amount to receiver address
        balances[addressToSend] = balances[addressToSend].add(amount);
    }
    
    function UpdateAndburnBlackHoleAddress() private
    {
        uint256 currentTokens = balances[blackHoleAddress];
        uint256 newTokens = GetAddressBalanceWithReflection(blackHoleAddress).sub(currentTokens);
        
        BurnTokens(blackHoleAddress ,newTokens);
    }
    
    /**
    * @dev Check that transaction is valid
    */
    function ApproveTransaction(address senderAddress, address receiverAddress, uint256 amount) private returns (bool)
    {
        require(senderAddress != address(0), "Sender address is invalid");
        require(receiverAddress != address(0), "Receiver address is invalid");
        
        allowances[senderAddress][receiverAddress] = amount;
        
        emit Approval(senderAddress, receiverAddress, amount);
        return true;
    }
    
    function ApproveTransaction(address receiverAddress, uint256 amount) private returns (bool) 
    {
        return ApproveTransaction(msg.sender, receiverAddress, amount);
    }
    
    function GetAddressDividends(address addressToCheck) private view returns(uint256) 
    {
        if(holdersCirculatingSupply == 0)
        {
            return 0;
        }
        
        uint256 newDividendPoints = totalHolderShareFees - addressLastDividends[addressToCheck];
        return (balances[addressToCheck].mul(newDividendPoints)).div(holdersCirculatingSupply);
    }
    
    /**
    * @dev Calculate the amount of tokens the account will receive from total holder fees
    */
    function GetAddressBalanceWithReflection(address addressToUpdate) private returns (uint256)
    {
        uint256 owing = GetAddressDividends(addressToUpdate);
        
        //exclude tokenCreator from adding holders fees
        if(addressToUpdate != tokenCreator && owing > 0) 
        {
            balances[addressToUpdate] = balances[addressToUpdate].add(owing);
            addressLastDividends[addressToUpdate] = totalHolderShareFees;
        }
        
        return balances[addressToUpdate];
    }
    
    /**
    * @dev Adds liquidity to liquidity pool and burns the LP tokens received
    */
    function AddLiquidity(uint256 amount) private
    {
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        uint256 initialBalance = address(this).balance;

        ChangeTokensToETH(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        ApproveTransaction(address(this), address(UniswapV2Router), otherHalf);

        UniswapV2Router.addLiquidityETH{value: newBalance}(address(this), otherHalf, 0, 0, address(0), block.timestamp);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    
    /**
    * @dev Tokens are changed to ETH. Necessary to add liquidity
    */
    function ChangeTokensToETH(uint256 amount) private
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        ApproveTransaction(address(this), address(UniswapV2Router), amount);

        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }
    
    /**
    * @dev To recieve ETH from uniswapV2Router when swapping
    */
    receive() external payable {}
}