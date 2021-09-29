/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

pragma solidity ^0.5.0;
// SPDX-License-Identifier: MIT
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes memory) {
        return msg.data;
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public {
        _transferOwnership(_msgSender());
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
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
   

  
}
// Solidity Interface

contract IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_tokens, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() public view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

// Solidity Interface

contract IUniswapFactory {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}


contract IDutchExchange {


    mapping(address => mapping(address => uint)) public balances;

    // Token => Token => auctionIndex => amount
    mapping(address => mapping(address => mapping(uint => uint))) public extraTokens;

    // Token => Token =>  auctionIndex => user => amount
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public sellerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public buyerBalances;
    mapping(address => mapping(address => mapping(uint => mapping(address => uint)))) public claimedAmounts;

    
    function ethToken() public view returns(address);
    function claimBuyerFunds(address, address, address, uint) public returns(uint, uint);
    function deposit(address tokenAddress, uint amount) public returns (uint);
    function withdraw(address tokenAddress, uint amount) public returns (uint);
    function getAuctionIndex(address token1, address token2) public returns(uint256);
    function postBuyOrder(address token1, address token2, uint256 auctionIndex, uint256 amount) public returns(uint256);
    function postSellOrder(address token1, address token2, uint256 auctionIndex, uint256 tokensBought) public returns(uint256, uint256);
    function getCurrentAuctionPrice(address token1, address token2, uint256 auctionIndex) public view returns(uint256, uint256);
    function claimAndWithdrawTokensFromSeveralAuctionsAsBuyer(address[] calldata, address[] calldata, uint[] calldata) external view returns(uint[] memory, uint);
}

contract ITokenMinimal {
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function deposit() public payable;
    function withdraw(uint value) public;
}


library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract(), "ERC20 is not a contract");

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
        // call return false when something wrong
        require(success, "safeTransfer must succeed");
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)), "safeTransfer must return nothing or true");
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract(), "ERC20 is not a contract");

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
        // call return false when something wrong
        require(success, "safeTransferFrom must succeed");
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)), "safeTransferFrom must return nothing or true");
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

        // Must be a contract addr first!
        require(_erc20Addr.isContract(), "ERC20 is not a contract");
        
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero.
        require((_value == 0) || (IERC20(_erc20Addr).allowance(address(this), _spender) == 0), "safeApprove should only be called when setting an initial allowance, or when resetting it to zero.");

        (bool success, bytes memory returnValue) =
        // solhint-disable-next-line avoid-low-level-calls
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
        // call return false when something wrong
        require(success, "safeApprove must succeed");
        //check return value
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)),  "safeApprove must return nothing or true");
    }
}
/// @title Uniswap Arbitrage - Executes arbitrage transactions between Uniswap and DutchX.
/// @author Billy Rennekamp - <[email protected]>
contract Arbitrage is Ownable {

    uint constant max = uint(-1);

    IUniswapFactory public uniFactory;
    IDutchExchange public dutchXProxy;

    event Profit(uint profit, bool wasDutchOpportunity);

    /// @dev Payable fallback function has nothing inside so it won't run out of gas with gas limited transfers
    function() external payable {}

    /// @dev Only owner can deposit contract Ether into the DutchX as WETH
    function depositEther() public payable onlyOwner {

        require(address(this).balance > 0, "Balance must be greater than 0 to deposit");
        uint balance = address(this).balance;

        // // Deposit balance to WETH
        address weth = dutchXProxy.ethToken();
        ITokenMinimal(weth).deposit.value(balance)();

        uint wethBalance = ITokenMinimal(weth).balanceOf(address(this));
        uint allowance = ITokenMinimal(weth).allowance(address(this), address(dutchXProxy));

        if (allowance < wethBalance) {
            if (allowance != 0) {
                SafeERC20.safeApprove(weth, address(dutchXProxy), 0);
            }
            // Approve max amount of WETH to be transferred by dutchX
            // Keeping it max will have same or similar costs to making it exact over and over again
            SafeERC20.safeApprove(weth, address(dutchXProxy), max);
        }

        // Deposit new amount on dutchX, confirm there's at least the amount we just deposited
        uint newBalance = dutchXProxy.deposit(weth, balance);
        require(newBalance >= balance, "Deposit WETH to DutchX didn't work.");
    }

    /// @dev Only owner can withdraw WETH from DutchX, convert to Ether and transfer to owner
    /// @param amount The amount of Ether to withdraw
    function withdrawEtherThenTransfer(uint amount) external onlyOwner {
        _withdrawEther(amount);
        address(uint160(owner())).transfer(amount);
    }

    /// @dev Only owner can transfer any Ether currently in the contract to the owner address.
    /// @param amount The amount of Ether to withdraw
    function transferEther(uint amount) external onlyOwner {
        // If amount is zero, deposit the entire contract balance.
        address(uint160(owner())).transfer(amount == 0 ? address(this).balance : amount);
    }

    /// @dev Only owner function to withdraw WETH from the DutchX, convert it to Ether and keep it in contract
    /// @param amount The amount of WETH to withdraw and convert.
    function withdrawEther(uint amount) external onlyOwner {
        _withdrawEther(amount);
    }

    /// @dev Internal function to withdraw WETH from the DutchX, convert it to Ether and keep it in contract
    /// @param amount The amount of WETH to withdraw and convert.
    function _withdrawEther(uint amount) internal {
        address weth = dutchXProxy.ethToken();
        dutchXProxy.withdraw(weth, amount);
        ITokenMinimal(weth).withdraw(amount);
    }

    /// @dev Only owner can withdraw a token from the DutchX
    /// @param token The token address that is being withdrawn.
    /// @param amount The amount of token to withdraw. Can be larger than available balance and maximum will be withdrawn.
    /// @return Returns the amount actually withdrawn from the DutchX
    function withdrawToken(address token, uint amount) external onlyOwner returns (uint) {
        return dutchXProxy.withdraw(token, amount);
    }

    /// @dev Only owner can transfer tokens to the owner that belong to this contract
    /// @param token The token address that is being transferred.
    /// @param amount The amount of token to transfer.
    function transferToken(address token, uint amount) external onlyOwner {
        SafeERC20.safeTransfer(token, owner(), amount);
    }

    /// @dev Only owner can approve tokens to be used by the DutchX
    /// @param token The token address to be approved for use
    /// @param spender The address that should be approved
    /// @param allowance The amount of tokens that should be approved
    function approveToken(address token, address spender, uint allowance) external onlyOwner {
        SafeERC20.safeApprove(token, spender, allowance);
    }

    /// @dev Only owner can deposit token to the DutchX
    /// @param token The token address that is being deposited.
    /// @param amount The amount of token to deposit.
    function depositToken(address token, uint amount) external onlyOwner {
        _depositToken(token, amount);
    }

    /// @dev Internal function to deposit token to the DutchX
    /// @param token The token address that is being deposited.
    /// @param amount The amount of token to deposit.
    function _depositToken(address token, uint amount) internal returns(uint deposited) {
        uint balance = ITokenMinimal(token).balanceOf(address(this));
        uint min = balance < amount ? balance : amount;
        require(min > 0, "Balance of token insufficient");

        uint allowance = ITokenMinimal(token).allowance(address(this), address(dutchXProxy));
        if (allowance < min) {
            if (allowance != 0) {
                SafeERC20.safeApprove(token, address(dutchXProxy), 0);
            }
            SafeERC20.safeApprove(token, address(dutchXProxy), max);
        }

        // Confirm that the balance of the token on the DutchX is at least how much was deposited
        uint newBalance = dutchXProxy.deposit(token, min);
        require(newBalance >= min, "deposit didn't work");
        return min;
    }

    /// @dev Executes a trade opportunity on dutchX. Assumes that there is a balance of WETH already on the dutchX
    /// @param arbToken Address of the token that should be arbitraged.
    /// @param amount Amount of Ether to use in arbitrage.
    /// @return Returns if transaction can be executed.
    function dutchOpportunity(address arbToken, uint256 amount) external onlyOwner {

        address etherToken = dutchXProxy.ethToken();

        // The order of parameters for getAuctionIndex don't matter
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(arbToken, etherToken);

        // postBuyOrder(sellToken, buyToken, amount)
        // results in a decrease of the amount the user owns of the second token
        // which means the buyToken is what the buyer wants to get rid of.
        // "The buy token is what the buyer provides, the seller token is what the seller provides."
        dutchXProxy.postBuyOrder(arbToken, etherToken, dutchAuctionIndex, amount);

        (uint tokensBought, ) = dutchXProxy.claimBuyerFunds(arbToken, etherToken, address(this), dutchAuctionIndex);
        dutchXProxy.withdraw(arbToken, tokensBought);

        address uniswapExchange = uniFactory.getExchange(arbToken);

        uint allowance = ITokenMinimal(arbToken).allowance(address(this), address(uniswapExchange));
        if (allowance < tokensBought) {
            if (allowance != 0) {
                SafeERC20.safeApprove(arbToken, address(uniswapExchange), 0);
            }
            // Approve Uniswap to transfer arbToken on contract's behalf
            // Keeping it max will have same or similar costs to making it exact over and over again
            SafeERC20.safeApprove(arbToken, address(uniswapExchange), max);
        }

        // tokenToEthSwapInput(inputToken, minimumReturn, timeToLive)
        // minimumReturn is enough to make a profit (excluding gas)
        // timeToLive is now because transaction is atomic
        uint256 etherReturned = IUniswapExchange(uniswapExchange).tokenToEthSwapInput(tokensBought, 1, block.timestamp);

        // gas costs were excluded because worse case scenario the tx fails and gas costs were spent up to here anyway
        // best worst case scenario the profit from the trade alleviates part of the gas costs even if still no total profit
        require(etherReturned >= amount, "no profit");
        emit Profit(etherReturned, true);

        // Ether is deposited as WETH
        depositEther();
    }

    /// @dev Executes a trade opportunity on uniswap.
    /// @param arbToken Address of the token that should be arbitraged.
    /// @param amount Amount of Ether to use in arbitrage.
    /// @return Returns if transaction can be executed.
    function uniswapOpportunity(address arbToken, uint256 amount) external onlyOwner {

        // WETH must be converted to Eth for Uniswap trade
        // (Uniswap allows ERC20:ERC20 but most liquidity is on ETH:ERC20 markets)
        _withdrawEther(amount);
        require(address(this).balance >= amount, "buying from uniswap takes real Ether");

        // ethToTokenSwapInput(minTokens, deadline)
        // minTokens is 1 because it will revert without a profit regardless
        // deadline is now since trade is atomic
        // solium-disable-next-line security/no-block-members
        uint256 tokensBought = IUniswapExchange(uniFactory.getExchange(arbToken)).ethToTokenSwapInput.value(amount)(1, block.timestamp);

        // tokens need to be approved for the dutchX before they are deposited
        tokensBought = _depositToken(arbToken, tokensBought);

        address etherToken = dutchXProxy.ethToken();

        // The order of parameters for getAuctionIndex don't matter
        uint256 dutchAuctionIndex = dutchXProxy.getAuctionIndex(arbToken, etherToken);

        // spend max amount of tokens currently on the dutch x (might be combined from previous remainders)
        // max is automatically reduced to maximum available tokens because there may be
        // token remainders from previous auctions which closed after previous arbitrage opportunities
        dutchXProxy.postBuyOrder(etherToken, arbToken, dutchAuctionIndex, max);
        // solium-disable-next-line no-unused-vars
        (uint etherReturned, ) = dutchXProxy.claimBuyerFunds(etherToken, arbToken, address(this), dutchAuctionIndex);

        // gas costs were excluded because worse case scenario the tx fails and gas costs were spent up to here anyway
        // best worst case scenario the profit from the trade alleviates part of the gas costs even if still no total profit
        require(etherReturned >= amount, "no profit");
        emit Profit(etherReturned, false);
        // Ether returned is already in dutchX balance where Ether is assumed to be stored when not being used.
    }

}