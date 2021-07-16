//SourceUnit: UTRX.sol

pragma solidity ^0.5.8;

interface IJustswapExchange {
    event TokenPurchase(
        address indexed buyer,
        uint256 indexed trx_sold,
        uint256 indexed tokens_bought
    );
    event TrxPurchase(
        address indexed buyer,
        uint256 indexed tokens_sold,
        uint256 indexed trx_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256 indexed trx_amount,
        uint256 indexed token_amount
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256 indexed trx_amount,
        uint256 indexed token_amount
    );

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value).
     * @dev User cannot specify minimum output or deadline.
     */
    function() external payable;

    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param input_amount Amount of TRX or Tokens being sold.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens bought.
     */
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param output_amount Amount of TRX or Tokens being bought.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens sold.
     */
    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) external view returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens bought.
     */

    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256);

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies exact input (msg.value) && minimum output
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return  Amount of Tokens bought.
     */
    function trxToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256);

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return Amount of TRX sold.
     */
    function trxToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(
        uint256 tokens_sold,
        uint256 min_trx,
        uint256 deadline
    ) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return  Amount of TRX bought.
     */
    function tokenToTrxTransferInput(
        uint256 tokens_sold,
        uint256 min_trx,
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(
        uint256 trx_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxTransferOutput(
        uint256 trx_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256);

    /***********************************|
  |         Getter Functions          |
  |__________________________________*/

    /**
     * @notice external price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold)
        external
        view
        returns (uint256);

    /**
     * @notice external price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought)
        external
        view
        returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() external view returns (address);

    /**
     * @return Address of factory that created this exchange.
     */
    function factoryAddress() external view returns (address);

    /***********************************|
  |        Liquidity Functions        |
  |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
     * @dev min_liquidity does nothing when total UNI supply is 0.
     * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of UNI minted.
     */
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of UNI burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(
        uint256 amount,
        uint256 min_trx,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call.value(weiValue)(data);
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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mintTo(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract UTRX is Ownable {
    IERC20 public usdt;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IJustswapExchange public justswapexchange;
    address public operator;
    uint256 public constant delay = 5 minutes;
    uint256 private constant FEE_35 = 35000000;
    uint256 private constant FEE_30 = 30000000;
    uint256 private constant FEE_15 = 15000000;
    uint256 private constant FEE_10 = 10000000;
    uint256 private constant FEE_5 = 5000000;
    uint256 private constant FEE_105 = 105000000;
    uint256 private constant FEE_175 = 175000000;
    uint256 private constant FEE_50 = 50000000;
    uint256 private constant FEE_25 = 25000000;
    address payable private feeBigAddress;
    address payable private feeMiddleAddress;
    address payable private feeSmallAddress;

    event TrxPurchase(
        address indexed buyer,
        uint256 indexed tokens_sold,
        uint256 indexed trx_bought
    );

    event DepositedNormal(address indexed buyer, uint256 indexed amount);
    event DepositedTopMiner(address indexed buyer, uint256 indexed amount);
    event WithdrawToUser(address indexed buyer, uint256 indexed amount);

    modifier onlyOperatorAdmin() {
        require(
            msg.sender == owner || msg.sender == operator,
            "Not operator or admin"
        );
        _;
    }

    /**
     * @dev Function that sets the USDT-TRX exchange, USDT Token, approves this contract to interact with just swap and sets the operator address
     * @param _exch Just Swap USDT-TRX exchange address
     * @param _usdt USDT Token contract address
     * @param _operator Operators address
     * @param _feeBig Fee 35_105_175 address
     * @param _feeMiddle Fee 10_30_50 address
     * @param _feeSmall Fee 5_15_25 address
     */
    constructor(
        address payable _exch,
        address _usdt,
        address payable _operator,
        address payable _feeBig,
        address payable _feeSmall,
        address payable _feeMiddle
    ) public {
        justswapexchange = IJustswapExchange(_exch);
        usdt = IERC20(_usdt);
        usdt.approve(_exch, 9999999999999000000);
        operator = _operator;
        feeBigAddress = _feeBig;
        feeMiddleAddress = _feeMiddle;
        feeSmallAddress = _feeSmall;
    }

    /**
     * @dev Main deposit function that accepts any amount in  usdt and swaps to TRX.
     * @param _amount Deposit amount.
     */

    function deposit(uint256 _amount) external returns (uint256) {
        require(_amount > 0, "Amount must be higher than 0");
        usdt.safeTransferFrom(msg.sender, address(this), _amount); //transfer from user
        uint256 availtopurchase =
            justswapexchange.getTokenToTrxInputPrice(_amount);
        availtopurchase = availtopurchase.div(10);
        uint256 deadline = block.timestamp.add(delay);
        uint256 tokensSol =
            justswapexchange.tokenToTrxSwapInput(
                _amount,
                availtopurchase,
                deadline
            );

        emit TrxPurchase(msg.sender, tokensSol, availtopurchase);
        emit DepositedNormal(msg.sender, _amount);
        return tokensSol;
    }

    /**
     * @dev Approve contract function
     * @param _amount Amount to approve
     * @param _address Address to approve
     */
    function approveContractToUSDT(uint256 _amount, address payable _address)
        external
        onlyOperatorAdmin
    {
        require(_amount > 0, "number is 0");
        usdt.approve(_address, _amount);
    }

    /**
     * @dev Fallback function that accepts TRX from just swap.
     */
    function() external payable {}

    /**
     * @dev Second deposit function (Top miner activity) that accepts 300, 600 or 1500 USDT and swaps to TRX
     * @param _amount Deposit amount.
     */
    function depositTopMiners(uint256 _amount) external returns (uint256) {
        require(
            _amount == 300000000 ||
                _amount == 900000000 ||
                _amount == 1500000000,
            "not correct amount"
        );
        usdt.safeTransferFrom(msg.sender, address(this), _amount); //transfer from user
        uint256 availtopurchase =
            justswapexchange.getTokenToTrxInputPrice(_amount); //get full TRX amount
        uint256 feeBig;
        uint256 feeSmall;
        uint256 feeMiddle;
        if (_amount == 300000000) {
            feeBig = justswapexchange.getTokenToTrxInputPrice(FEE_35); //35 usdt in trx
            feeMiddle = justswapexchange.getTokenToTrxInputPrice(FEE_10); //10 usdt in trx
            feeSmall = justswapexchange.getTokenToTrxInputPrice(FEE_5); //5 usdt in trx
        } else if (_amount == 900000000) {
            feeBig = justswapexchange.getTokenToTrxInputPrice(FEE_105); //105 usdt in trx
            feeMiddle = justswapexchange.getTokenToTrxInputPrice(FEE_30); //30 usdt in trx
            feeSmall = justswapexchange.getTokenToTrxInputPrice(FEE_15); //15 usdt in trx
        } else if (_amount == 1500000000) {
            feeBig = justswapexchange.getTokenToTrxInputPrice(FEE_175); //175 usdt in trx
            feeMiddle = justswapexchange.getTokenToTrxInputPrice(FEE_50); //50 usdt in trx
            feeSmall = justswapexchange.getTokenToTrxInputPrice(FEE_25); //25 usdt in trx
        }

        availtopurchase = availtopurchase.div(10);
        uint256 deadline = block.timestamp.add(delay);
        uint256 tokensSol =
            justswapexchange.tokenToTrxSwapInput(
                _amount,
                availtopurchase,
                deadline
            );
        feeBigAddress.transfer(feeBig); //transfer fee
        feeSmallAddress.transfer(feeSmall); //transfer fee
        feeMiddleAddress.transfer(feeMiddle); //transfer fee
        emit DepositedTopMiner(msg.sender, _amount);
        return tokensSol;
    }

    /**
     * @dev Withdraw TRX rewards to user
     * @param _user user to receive rewards
     * @param _amount amount to withdraw to user
     */
    function withdrawToUser(address payable _user, uint256 _amount)
        external
        onlyOperatorAdmin
    {
        require(_amount > 0, "amount !0");
        _user.transfer(_amount);
        emit WithdrawToUser(_user, _amount);
    }


    /**
     * @dev change big fee addresses
     * @param _address new big fee address
     */
    function changeBigFeeAddress(address payable _address) external onlyOperatorAdmin {
        feeBigAddress = _address;
    }

    /**
     * @dev change small fee addresses
     * @param _address new small fee address
     */
    function changeSmallFeeAddress(address payable  _address)
        external
        onlyOperatorAdmin
    {
        feeSmallAddress = _address;
    }

    /**
     * @dev change medium fee addresses
     * @param _address new medium fee address
     */
    function changeMiddleFeeAddress(address payable _address)
        external
        onlyOperatorAdmin
    {
        feeMiddleAddress = _address;
    }
    
        /**
     * @dev change operator address
     * @param _address new operator address
     */
    function changeOperatorAddress(address payable _address)
        external
        onlyOperatorAdmin
    {
        operator = _address;
    }

   
}