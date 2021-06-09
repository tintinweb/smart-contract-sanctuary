/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// File: contracts/utils/Address.sol

pragma solidity 0.5.17;

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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/utils/SafeMath.sol

pragma solidity 0.5.17;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/TokenPool.sol

pragma solidity 0.5.17;

/**
 * @title A simple holder of tokens.
 * This is a simple contract to hold tokens. It's useful in the case where a separate contract
 * needs to hold multiple distinct pools of the same token.
 */
contract TokenPool {
    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;
    address public rptContract;

    constructor() public {
      uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
      uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
      rptContract = 0xa0Bb0027C28ade4Ac628b7f81e7b93Ec71b4E020;
    }

    function balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function () external payable {}


    function swapETHForRPT() external {
        if(address(this).balance > 0) {
          address[] memory uniswapPairPath = new address[](2);
          uniswapPairPath[0] = rptContract; // RPT contract address
          uniswapPairPath[1] = uniswapRouterV2.WETH(); // weth address

          uniswapRouterV2.swapExactETHForTokensSupportingFeeOnTransferTokens.value(address(this).balance)(
                  0,
                  uniswapPairPath,
                  address(this),
                  block.timestamp
              );
        }
    }

}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )  external payable;
}

// File: contracts/RugProofMaster.sol

/*
Rug Proof Master Contract

Website: rugproof.io

The Rug Proof Master Contract is an experimental rug proof token sale platform.

This contract allows token sellers to predefine liquidity % amounts that are validated and trustless.
This allows buyers of the token sale to have confidence in what they are buying, as it ensures liquidity gets locked.

A 1% platform tax is applied which market buys RPT and locks it into the burn pool.

At the end of a successful sale, any remaining tokens are sent to the burn pool.

If a sale does not meet its softcap after the end time, users can get their ETH refund minus the 1% platform tax.
*/

pragma solidity 0.5.17;




contract RugProofMaster {
    using SafeMath for uint256;
    using Address for address;

    struct SaleInfo {
      address contractAddress; // address of the token
      address payable receiveAddress; // address to receive ETH
      uint256 tokenAmount; // amount of tokens to sell
      uint256 tokenRatio; // ratio of ETH to token
      uint256 totalEth; // total eth currently raised
      uint256 softcap; // amount of ETH we need to set this as a success
      uint32 counter; // amount of buyers
      uint32 timestampStartSec; // unix second start
      uint32 timestampEndSec; // unix second end
      uint8 liquidityLockPercent; // 20 = 20%, capped at 100%, intervals of 1%. % of ETH sold that will be locked up
      bool isEnded; // signals the end of this sale
      bool isSuccess; // if false, users can claim their eth back
      mapping(address => uint256) ethContributed; // amount of eth contributed per address
    }

    SaleInfo[] public tokenSales;

    IUniswapV2Router02 public uniswapRouterV2;
    IUniswapV2Factory public uniswapFactory;

    //inaccessible contract that stores funds
    //cannot use 0 address because some tokens prohibit it without a burn function
    TokenPool public burnPool;

    // address for the RPT token
    address public rptContract;

    // Amount of wei raised in this contracts lifetime
    uint256 public _weiRaised;

    uint256 public rptTax;

    address public owner;

    bool private _notEntered;

    mapping(address => bool) public contractVerified;

    uint256 verifiedAmount;

    event LogCreateNewSale(address _contract, uint256 _tokenAmount);
    event LogContractVerified(address _contract, bool _verified);

    modifier onlyOwner() {
        require(msg.sender == owner, "RugProofMaster::OnlyOwner: Not the owner");
        _;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;

        _;

        _notEntered = true;
    }

    function initialize() public {
        require(owner == address(0x0), "RugProofMaster::Initialize: Already initialized");

        uniswapRouterV2 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapFactory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        rptContract = 0xa0Bb0027C28ade4Ac628b7f81e7b93Ec71b4E020;

        burnPool = new TokenPool();
        rptTax = 1;
        owner = msg.sender;

        _notEntered = true;
    }

    function setContractVerified(address _verified, bool _isVerified) external onlyOwner {
        contractVerified[_verified] = _isVerified;
        emit LogContractVerified(_verified, _isVerified);
    }

    /**
     * @dev Sets the % tax for each purchase. This tax sends market buys and burns RPT
     *
     */
    function setTax(uint256 _rptTax) public onlyOwner {
        require(_rptTax <= 100, "RugProofMaster::setTax: tax is too high");
        rptTax = _rptTax;
    }

    function setVerifiedPayment(uint256 _amount) external onlyOwner {
      verifiedAmount = _amount; //2e18
    }


    /**
     * @dev Creates a token sale with a timer.
     *
     *      _contractAddress: contract of the token being sold
     *      _tokenAmount: amount of tokens being sold
     *      _tokenRatio: price of the token vs ETH i.e. 1e9 and a user buys 0.5 ETH worth => tokenRatio * ETHAmount / ETH Decimals = (1e9 * 0.5e18)/1e18
     *      _timestampStartSec: unix time in seconds when the sale starts
     *      _timestampStartSec: unix time in seconds when the sale ends
     *      _liquidityLockPercent: % of the sale that should go to locked ETH liquidity i.e. 50 => 50%. Capped at 100, increments of 1%
     *      _softcap: ETH amount that is needed for the sale to be a success
     */
    function createNewTokenSale(
      address _contractAddress, uint256 _tokenAmount,
      uint256 _tokenRatio, uint32 _timestampEndSec,
      uint8 _liquidityLockPercent, uint256 _softcap, bool wantVerified) external payable {

        require(_contractAddress != address(0), "CreateNewTokenSale: Cannot use the zero address");
        require(msg.sender != address(this), "CreateNewTokenSale: Cannot call from this contract");
        require(_tokenAmount != 0, "CreateNewTokenSale: Cannot sell zero tokens");
        require(_tokenRatio != 0, "CreateNewTokenSale: Cannot have a zero ratio");
        require(_timestampEndSec > now, "CreateNewTokenSale: Cannot start sale after end time");
        require(_liquidityLockPercent <= 100, "CreateNewTokenSale: Cannot have higher than 100% liquidity lock");
        // make sure we are not raising too much ETH
        uint256 totalValueOfTokens = _tokenAmount.mul(1e18).div(_tokenRatio);
        uint256 hardcapETH = totalValueOfTokens.div(100 + _liquidityLockPercent).mul(100);

        require(_softcap != 0 && _softcap <= hardcapETH, "CreateNewTokenSale: Cannot have a zero softcap or be more than the hardcap");

        if(wantVerified == true){
          require(msg.value == verifiedAmount, "createNewTokenSale::wantVerified: msg.value is must be verifiedAmount");
          address(owner).toPayable().transfer(verifiedAmount);
        }

        // check how many tokens we receive
        // this is an important step to ensure we log proper amounts if this is a deflationary token
        // approve must be called before this function is executed. Need to approve this contract address to send the token amount
        uint256 tokenBalanceBeforeTransfer = IERC20(_contractAddress).balanceOf(address(this));
        IERC20(_contractAddress).transferFrom(address(msg.sender), address(this), _tokenAmount);
        uint256 tokensReceived = IERC20(_contractAddress).balanceOf(address(this)).sub(tokenBalanceBeforeTransfer);


        SaleInfo memory saleInfo = SaleInfo(
          _contractAddress, msg.sender, tokensReceived, _tokenRatio, 0, _softcap,
          0, uint32(now), _timestampEndSec, _liquidityLockPercent, false, false
          );

        tokenSales.push(saleInfo);
        emit LogCreateNewSale(_contractAddress, _tokenAmount);
    }

    /**
     * @dev Enabled ability for tokens to be withdrawn by buyers after the sale has ended successfully.
                     On a successful sale (softcap reached by time, or hardcap reached), this function:
                     1. Creates uniswap pair if not created.
                     2. adds token liquidity to uniswap pair.
                     3. burns tokens if hardcap was not met
     *
     *      contractIndex: index of the token sale. See tokenSales variable
     *
     */
    function endTokenSale(uint256 contractIndex) external {
        SaleInfo storage tokenSaleInfo = tokenSales[contractIndex];

        // make sure we are not raising too much ETH
        uint256 totalValueOfTokens = tokenSaleInfo.tokenAmount.mul(1e18).div(tokenSaleInfo.tokenRatio);
        uint256 hardcapETH = totalValueOfTokens.div(100 + tokenSaleInfo.liquidityLockPercent).mul(100);

        //require(tokenSaleInfo.receiveAddress == msg.sender, "endTokenSale: can only be called by funding owner");
        require(tokenSaleInfo.isEnded == false, "endTokenSale: token sale has ended already");
        require(block.timestamp > tokenSaleInfo.timestampEndSec || tokenSaleInfo.totalEth >= hardcapETH , "endTokenSale: token sale is not over yet");
        require(IERC20(tokenSaleInfo.contractAddress).balanceOf(address(this)) >= tokenSaleInfo.tokenAmount,  "endTokenSale: contract does not have enough tokens");

        // flag that allows ends this funding round
        // also allows token withdrawals and refunds if failed
        tokenSaleInfo.isEnded = true;

        // sale was a success if we hit the softcap
        if(tokenSaleInfo.totalEth >= tokenSaleInfo.softcap || tokenSaleInfo.totalEth >= hardcapETH){
          tokenSaleInfo.isSuccess = true;

          uint256 saleEthToLock = tokenSaleInfo.totalEth.mul(tokenSaleInfo.liquidityLockPercent).div(100);
          uint256 saleEthToUnlock = tokenSaleInfo.totalEth.sub(saleEthToLock);

          uint256 tokenAmountToLock = saleEthToLock.mul(tokenSaleInfo.tokenRatio).div(1e18);
          uint256 tokenAmountToUnlock = saleEthToUnlock.mul(tokenSaleInfo.tokenRatio).div(1e18);

          // send the ETH to the owner of the sale so they can pay for the uniswap pair
          tokenSaleInfo.receiveAddress.transfer(saleEthToUnlock);

          // create uniswap pair
          createUniswapPairMainnet(tokenSaleInfo.contractAddress);

          // burn the rest of the tokens if there are any left
          uint256 tokenAmountToBurn = tokenSaleInfo.tokenAmount.sub(tokenAmountToLock).sub(tokenAmountToUnlock);

          if(tokenAmountToBurn > 0){
            IERC20(tokenSaleInfo.contractAddress).transfer(address(burnPool), tokenAmountToBurn);
          }

          // add liquidity to uniswap pair
          addLiquidity(tokenSaleInfo.contractAddress, tokenAmountToLock, saleEthToLock);

        } else {
          tokenSaleInfo.isSuccess = false;
          // transfer the token amount from this address back to the owner
          IERC20(tokenSaleInfo.contractAddress).transfer(tokenSaleInfo.receiveAddress, tokenSaleInfo.tokenAmount);
        }

        burnPool.swapETHForRPT();
    }

    function _overrideEndTokenSale(uint256 contractIndex) external onlyOwner {
        SaleInfo storage tokenSaleInfo = tokenSales[contractIndex];

        require(tokenSaleInfo.isEnded == false, "endTokenSale: token sale has ended already");
        tokenSaleInfo.isEnded = true;

        tokenSaleInfo.isSuccess = false;
        // transfer the token amount from this address back to the owner
        IERC20(tokenSaleInfo.contractAddress).transfer(tokenSaleInfo.receiveAddress, tokenSaleInfo.tokenAmount);
    }

    /**
     * @dev Buys tokens from the token sale from the function caller. A tax is applied here based on the rptTax.
     *               ETH tax is sent to the burn pool which can be used to market buy RPT. This is nonrefundable
     *
     *               Prevents users from buying in if the hardcap is met, or if the sale is expired.
     *
     *      contractIndex: index of the token sale. See tokenSales variable
     *
     */
    function buyTokens(uint256 contractIndex) external payable nonReentrant{
      require(msg.value != 0, "buyTokens: msg.value is 0");

      uint256 weiAmount = msg.value;
      uint256 weiAmountTax = weiAmount.mul(rptTax).div(100);

      SaleInfo storage tokenSaleInfo = tokenSales[contractIndex];

      // make sure this sale exists
      require(tokenSales.length > contractIndex, "buyTokens: no token sale for this index");

      // make sure we are not raising too much ETH
      uint256 totalValueOfTokens = tokenSaleInfo.tokenAmount.mul(1e18).div(tokenSaleInfo.tokenRatio);
      uint256 hardcapETH = totalValueOfTokens.div(100 + tokenSaleInfo.liquidityLockPercent).mul(100);


      require(hardcapETH > tokenSaleInfo.totalEth, "buyTokens: Sale has reached hardcap");
      // make sure this sale is not over
      require(tokenSaleInfo.timestampEndSec > block.timestamp && tokenSaleInfo.isEnded == false, "buyTokens: Token sale is over");

      //refund overflow
      if(tokenSaleInfo.totalEth.add(weiAmount) > hardcapETH){
        uint256 refundAmount = tokenSaleInfo.totalEth.add(weiAmount).sub(hardcapETH);
        address(msg.sender).transfer(refundAmount);
      }

      // log raised eth, only can buy what the final payment is (minus the rpt tax)
      tokenSaleInfo.ethContributed[msg.sender] = tokenSaleInfo.ethContributed[msg.sender].add(weiAmount.sub(weiAmountTax));
      tokenSaleInfo.totalEth = tokenSaleInfo.totalEth.add(weiAmount.sub(weiAmountTax));

      // increment buyer
      tokenSaleInfo.counter++;

      // log global raised amount
      _weiRaised = _weiRaised.add(weiAmount);

      // send eth to burn pool to marketbuy later
      address(burnPool).transfer(weiAmountTax);
    }

    /**
     * @dev Withdraws tokens the are bought from the sale if the message sender has any.
     *
     *
     *      contractIndex: index of the token sale. See tokenSales variable
     *
     */
    function claimTokens(uint256 contractIndex) external {
      require(tokenSales.length > contractIndex, "claimTokens: no available token sale");

      SaleInfo storage tokenSaleInfo = tokenSales[contractIndex];
      require(tokenSaleInfo.isEnded == true, "claimTokens: token sale has not ended");
      require(tokenSaleInfo.isSuccess == true, "claimTokens: token sale was not successful");
      require(tokenSaleInfo.ethContributed[msg.sender] > 0, "claimTokens: address contributed nothing");

      uint256 tokenAmountToSend = tokenSaleInfo.ethContributed[msg.sender].mul(tokenSaleInfo.tokenRatio).div(1e18);

      // prevent caller from re-entering
      tokenSaleInfo.ethContributed[msg.sender] = 0;

      IERC20(tokenSaleInfo.contractAddress).transfer(address(msg.sender), tokenAmountToSend);
    }

    /**
     * @dev If a sale was not successful, allows users to withdraw their ETH from the sale minus the tax amount
     *
     *
     *      contractIndex: index of the token sale. See tokenSales variable
     *
     */
    function withdrawRefundedETH(uint256 contractIndex) external {
      require(tokenSales.length > contractIndex, "withdrawRefundedETH: no available token sale");

      SaleInfo storage tokenSaleInfo = tokenSales[contractIndex];
      // allow refunds when sale is over and was not a success
      if(tokenSaleInfo.isEnded == true && tokenSaleInfo.isSuccess == false && tokenSaleInfo.ethContributed[msg.sender] > 0){
        //refund eth back to msgOwner
        address(msg.sender).transfer(tokenSaleInfo.ethContributed[msg.sender]);
        // set eth contributed to this sale as 0
        tokenSaleInfo.ethContributed[msg.sender] = 0;
      }
    }


    function getTokenSalesOne() public view returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory)
    {
      address[] memory contractAddresses = new address[](tokenSales.length);
      address[] memory receiveAddresses = new address[](tokenSales.length);
      uint256[] memory tokenAmounts = new uint256[](tokenSales.length);
      uint256[] memory tokenRatios = new uint256[](tokenSales.length);

      for (uint i = 0; i < tokenSales.length; i++) {
          SaleInfo storage saleInfo = tokenSales[i];
          contractAddresses[i] = saleInfo.contractAddress;
          receiveAddresses[i] = saleInfo.receiveAddress;
          tokenAmounts[i] = saleInfo.tokenAmount;
          tokenRatios[i] = saleInfo.tokenRatio;
      }

      return (contractAddresses, receiveAddresses, tokenAmounts, tokenRatios);
    }
    function getTokenSalesTwo() public view returns (uint32[] memory, uint32[] memory, uint8[] memory, uint256[] memory)
    {
      uint32[] memory timestampStartSec = new uint32[](tokenSales.length);
      uint32[] memory timestampEndSec = new uint32[](tokenSales.length);
      uint8[] memory liquidityLockPercents = new uint8[](tokenSales.length);
      uint256[] memory totalEths = new uint256[](tokenSales.length);

      for (uint i = 0; i < tokenSales.length; i++) {
          SaleInfo storage saleInfo = tokenSales[i];
          timestampStartSec[i] = saleInfo.timestampStartSec;
          timestampEndSec[i] = saleInfo.timestampEndSec;
          liquidityLockPercents[i] = saleInfo.liquidityLockPercent;
          totalEths[i] = saleInfo.totalEth;
      }

      return (timestampStartSec, timestampEndSec, liquidityLockPercents, totalEths);
    }
    function getTokenSalesThree() public view returns (bool[] memory, bool[] memory, uint256[] memory, uint32[] memory, uint256[] memory)
    {
      bool[] memory isEnded = new bool[](tokenSales.length);
      bool[] memory isSuccess = new bool[](tokenSales.length);
      uint256[] memory softcaps = new uint256[](tokenSales.length);
      uint32[] memory counters = new uint32[](tokenSales.length);
      uint256[] memory contributions = new uint256[](tokenSales.length);

      for (uint i = 0; i < tokenSales.length; i++) {
          SaleInfo storage saleInfo = tokenSales[i];
          isEnded[i] = saleInfo.isEnded;
          isSuccess[i] = saleInfo.isSuccess;
          softcaps[i] = saleInfo.softcap;
          counters[i] = saleInfo.counter;
          contributions[i] = saleInfo.ethContributed[msg.sender];
      }

      return (isEnded, isSuccess, softcaps, counters, contributions);
    }

    function getContribution(uint contractIndex) public view returns (uint256){
      require(tokenSales.length > contractIndex, "withdrawRefundedETH: no available token sale");

      uint256 ethContributed = tokenSales[contractIndex].ethContributed[msg.sender];

      return (ethContributed);
    }

    function createUniswapPairMainnet(address _contractAddress) internal returns (bool) {
        require(_contractAddress != address(0), "CreateUniswapPairMainnet: cannot create uniswap pair for zero address");
        address pairAddress = uniswapFactory.getPair(_contractAddress, address(uniswapRouterV2.WETH()));

        // zero address means this pair has not been created, we need to create it
        if(pairAddress == address(0)){
          address tokenUniswapPair = uniswapFactory.createPair( address(uniswapRouterV2.WETH()), _contractAddress);

          require(tokenUniswapPair != address(0), "createUniswapPairMainnet: issue creating pair");
        }

        return true;
    }

    function addLiquidity(address contractAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        // need to approve the token movement
        IERC20(contractAddress).approve(address(uniswapRouterV2), tokenAmount);

        // transfer lp tokens directly into burn pool
        uniswapRouterV2.addLiquidityETH.value(ethAmount)(
                contractAddress,
                tokenAmount,
                0,
                0,
                address(burnPool),
                block.timestamp
            );
    }
}