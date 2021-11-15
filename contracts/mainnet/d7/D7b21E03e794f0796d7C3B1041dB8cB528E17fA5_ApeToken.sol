// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.1.0/contracts/utils/Address.sol";

contract ApeToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // erc20
    mapping (address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    // total supply = 1 trillion
    uint256 private constant _tTotal = 10**12 * 10**_decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    // gets changed to APE ASTAX later
    string private _name = 'ABC';
    // gets changed to ASTAX \xF0\x9F\xA6\x8D later
    string private _symbol = 'ABC';
    uint8 private constant _decimals = 9;

    // uniswap
    address public constant uniswapV2RouterAddr = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddr);
    address public constant uniswapV2FactoryAddr = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public liquidityPoolAddr =  UniswapV2Library.pairFor(uniswapV2FactoryAddr, uniswapV2Router.WETH(), address(this));

    // cooldown and numsells
    struct Holder {
        uint256 timeTransfer;
        uint256 numSells;
        uint256 timeSell;
    }
    mapping (address => Holder) public holder;
    // first 10 minutes there is a buy limit of 0.3% of liquidity pool
    uint256 private constant _buyLimit =  27 * 10**8 * 10**_decimals;
    // first 10 minutes there is a holding limit for each address of 1% of the liquidity pool
    uint256 private constant _holderLimit = 90 * 10**8 * 10**_decimals;
    uint256 private constant _resetTime = 24 hours;

    // taxes
    mapping (address => bool) public whitelist;
    mapping (address => bool) public blacklist;
    struct Taxes {
        uint256 marketing;
        uint256 redistribution;
        uint256 lottery;
        uint256 buybackBurn;
    }
    Taxes private _buyTaxrates = Taxes(50, 25, 25, 0);
    Taxes private _firstSellTaxrates = Taxes(50, 0, 20, 30);
    Taxes private _secondSellTaxrates = Taxes(125, 0, 50, 75);
    Taxes private _thirdSellTaxrates = Taxes(175, 0, 70, 105);
    Taxes private _fourthSellTaxrates = Taxes(225, 0, 90, 135);
    address public constant burnAddr = address(0x000000000000000000000000000000000000dEaD);
    address payable public marketingAddr = payable(0x7B7B7c8A9cd0922E5894B3d3166f313Cf200A363);
    address payable public marketingInitialAddr = payable(0xdcBBcAA8fD8e610017D6922517Ff3f4ed2611e71);
    address public lotteryAddr = address(0x284c1D4Fb47e6548bde1e63A47198419Ec678449);

    // gets set to true after openTrading is called
    bool public tradingEnabled = false;
    uint256 public launchTime;

    // preventing circular calls of swapping
    bool public inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // every time the contract has 0.000005% of the total supply in tokens it will swap
    // them to eth in the next sell, keeping the buyback taxes whilst sending the rest to marketing
    uint256 public minimumTokensBeforeSwap = _tTotal.mul(5).div(1000000);

    // every time the contract has 1 eth it will use that for the buyback burn
    uint256 public minimumETHBeforeBurn = 1 ether;

    // the counter for how much of the token balance of the contract is allocated to buyback.
    // get reset every time the contract balance is swapped to eth.
    uint256 public rBuybackBurn;
    
    // initial token allocations
    uint256 private _ownerTokenAmount = _rTotal.div(100).mul(90);
    uint256 private _marketingInitialTokenAmount = _rTotal.div(100).mul(5);
    uint256 private _lotteryTokenAmount = _rTotal.div(100).mul(5);

    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor () {
        
        // 90% of tsupply to owner
        _rOwned[_msgSender()] = _ownerTokenAmount;
        emit Transfer(address(0), _msgSender(), _ownerTokenAmount);
        // 5% of tsupply to marketingInitial
        _rOwned[marketingInitialAddr] = _marketingInitialTokenAmount;
        emit Transfer(address(0), marketingInitialAddr, _marketingInitialTokenAmount);
        // 5% of tsupply to lottery
        _rOwned[lotteryAddr] = _lotteryTokenAmount;
        emit Transfer(address(0), lotteryAddr, _lotteryTokenAmount);

        whitelist[address(this)] = true;
        whitelist[_msgSender()] = true;
        whitelist[lotteryAddr] = true;
        whitelist[marketingInitialAddr] = true;
        whitelist[marketingAddr] = true;
    }
    receive() external payable {}


// ==========  ERC20
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


// ==========  TRANSFER
    function _transfer(address sender, address recipient, uint256 tAmount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || whitelist[sender] || whitelist[recipient], "Trading is not live yet. ");
        require(!blacklist[sender] && !blacklist[recipient], "Address is blacklisted. ");

        Taxes memory taxRates = Taxes(0,0,0,0);

        // getting appropiate tax rates and swapping of tokens/ sending of eth when threshhold passed
        if (!whitelist[sender] && !whitelist[recipient]) {

            // buy tax
            if (sender == liquidityPoolAddr && recipient != uniswapV2RouterAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        balanceOf(recipient).add(tAmount) <= _holderLimit,
                        "The sale is limited to 1% of LP per address for the first 10 minutes. "
                    );
                    require(
                        tAmount <= _buyLimit,
                        "No buy greater than 0.3% of LP can be made for the first 10 minutes. "
                    );
                    require(
                        holder[recipient].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[recipient].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }

                // set standard buy taxrates
                taxRates = _buyTaxrates;
            }

            // sell tax
            if (recipient == liquidityPoolAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        holder[sender].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }

                // reset number of sells after 24 hours
                if (holder[sender].numSells > 0 && holder[sender].timeSell.add(_resetTime) < block.timestamp) {
                    holder[sender].numSells = 0;
                    holder[sender].timeSell = block.timestamp;
                }

                // set tax according to price impact or number of sells
                uint256 priceImpact = tAmount.mul(100).div(balanceOf(liquidityPoolAddr));

                // default sell taxrate, gets changed if numsells or priceimpact indicates that it should
                taxRates = _firstSellTaxrates;

                if (priceImpact > 1 || holder[sender].numSells == 1) {
                    taxRates = _secondSellTaxrates;
                }
                if (priceImpact > 2 || holder[sender].numSells == 2) {
                    taxRates = _thirdSellTaxrates;
                }
                if (priceImpact > 3 || holder[sender].numSells >= 3) {
                    taxRates = _fourthSellTaxrates;
                }

                // increment number of sells for holder
                if (holder[sender].numSells < 3) {
                    holder[sender].numSells = holder[sender].numSells.add(1);
                }
            }

            // wallet 2 wallet tax (or nonuniswap)
            if (sender != liquidityPoolAddr && recipient != liquidityPoolAddr) {

                if (launchTime.add(10 minutes) >= block.timestamp) {
                    require(
                        holder[sender].timeTransfer.add(45 seconds) < block.timestamp,
                        "Need to wait 45 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                } else {
                    require(
                        holder[sender].timeTransfer.add(30 seconds) < block.timestamp,
                        "Need to wait 30 seconds until next transfer. "
                    );
                    holder[sender].timeTransfer = block.timestamp;
                }
                // same tax rates as a third sell
                taxRates = _thirdSellTaxrates;
            }

            // if not already swapping then tokens and eth can be swapped now
            if (!inSwap && sender != liquidityPoolAddr) {

                // swap tokens and send some to marketing, whilst keeping the eth for buyback burn
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= minimumTokensBeforeSwap) {
                    if (rBuybackBurn != 0) {
                        uint256 toBeBurned = tokenFromReflection(rBuybackBurn);
                        rBuybackBurn = 0;
                        uint256 toBeSentToMarketing = contractTokenBalance.sub(toBeBurned);
                        swapTokensForETHTo(toBeSentToMarketing, marketingAddr);
                        swapTokensForETHTo(toBeBurned, payable(this));
                    } else {
                        swapTokensForETHTo(contractTokenBalance, marketingAddr);
                    }
                }

                // swap eth for buyback burn if above minimum
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance >= minimumETHBeforeBurn) {
                    swapETHForTokensTo(contractETHBalance, burnAddr);
                }
            }
        }

        // make sure taxes are not applied when swapping internal balances
        if(inSwap) {
            taxRates = Taxes(0,0,0,0);
        }

        // check taxrates and use simpler transfer if appropiate
        if (taxRates.marketing == 0 && taxRates.buybackBurn == 0 && taxRates.redistribution == 0 && taxRates.lottery == 0) {
            _tokenTransferWithoutFees(sender, recipient, tAmount);
        } else {
            _tokenTransferWithFees(sender, recipient, tAmount, taxRates);
        }
    }

    function _tokenTransferWithoutFees(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _tokenTransferWithFees(address sender, address recipient, uint256 tAmount, Taxes memory taxRates) private {

        // translating amount to reflected amount
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        // getting tax values
        Taxes memory tTaxValues = _getTTaxValues(tAmount, taxRates);
        Taxes memory rTaxValues = _getRTaxValues(tTaxValues);

        // removing tax values from the total amount
        uint256 rTransferAmount = _getTransferAmount(rAmount, rTaxValues);
        uint256 tTransferAmount = _getTransferAmount(tAmount, tTaxValues);

        // reflecting sender and recipient balances
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        // reflecting redistribution fees
        _rTotal = _rTotal.sub(rTaxValues.redistribution);

        // reflecting lottery fees
        _rOwned[lotteryAddr] = _rOwned[lotteryAddr].add(rTaxValues.lottery);

        // reflecting buybackburn and marketing fees
        _rOwned[address(this)] = _rOwned[address(this)].add(rTaxValues.marketing).add(rTaxValues.buybackBurn);
        rBuybackBurn = rBuybackBurn.add(rTaxValues.buybackBurn);

        // standard erc20 event
        emit Transfer(sender, recipient, tTransferAmount);
    }



// ==========  SWAP
    function swapTokensForETHTo(uint256 tokenAmount, address payable recipient) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), uniswapV2RouterAddr, tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            recipient,
            block.timestamp.add(300)
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapETHForTokensTo(uint256 amount, address recipient) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            recipient,
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }


// ==========  REFLECT
    function _getRate() private view returns(uint256) {
        return _rTotal.div(_tTotal);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less or equal than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getTTaxValues(uint256 amount, Taxes memory taxRates) private pure returns (Taxes memory) {
        Taxes memory taxValues;
        taxValues.redistribution = amount.div(1000).mul(taxRates.redistribution);
        taxValues.buybackBurn = amount.div(1000).mul(taxRates.buybackBurn);
        taxValues.marketing = amount.div(1000).mul(taxRates.marketing);
        taxValues.lottery = amount.div(1000).mul(taxRates.lottery);
        return taxValues;
    }

    function _getRTaxValues(Taxes memory tTaxValues) private view returns (Taxes memory) {
        Taxes memory taxValues;
        uint256 currentRate = _getRate();
        taxValues.redistribution = tTaxValues.redistribution.mul(currentRate);
        taxValues.buybackBurn = tTaxValues.buybackBurn.mul(currentRate);
        taxValues.marketing = tTaxValues.marketing.mul(currentRate);
        taxValues.lottery = tTaxValues.lottery.mul(currentRate);
        return taxValues;
    }

    function _getTransferAmount(uint256 amount, Taxes memory taxValues) private pure returns (uint256) {
        return amount.sub(taxValues.marketing).sub(taxValues.lottery).sub(taxValues.buybackBurn).sub(taxValues.redistribution);
    }


// ==========  ADMIN
    function openTrading() external onlyOwner() {
        require(!tradingEnabled, "Trading is already enabled. ");
        tradingEnabled = true;
        launchTime = block.timestamp;
    }

    function manualTaxConv() external onlyOwner() returns (bool) {
        // swap tokens and send some to marketing, whilst keeping the eth for buyback burn
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (rBuybackBurn != 0) {
                uint256 toBeBurned = tokenFromReflection(rBuybackBurn);
                rBuybackBurn = 0;
                uint256 toBeSentToMarketing = contractTokenBalance.sub(toBeBurned);
                swapTokensForETHTo(toBeSentToMarketing, marketingAddr);
                swapTokensForETHTo(toBeBurned, payable(this));
            } else {
                swapTokensForETHTo(contractTokenBalance, marketingAddr);
            }
        }
        return true;
    }

    function manualBuybackBurn() external onlyOwner() returns (bool) {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            swapETHForTokensTo(contractETHBalance, burnAddr);
        }
        return true;
    }

    function setWhitelist(address addr, bool onoff) external onlyOwner() {
        whitelist[addr] = onoff;
    }
    
    function setBlacklist(address addr, bool onoff) external onlyOwner() {
        blacklist[addr] = onoff;
    }
    
    function setMarketingWallet(address payable marketing) external onlyOwner() {
        marketingAddr = marketing;
    }

    function setMarketingLottery(address lottery) external onlyOwner() {
        lotteryAddr = lottery;
    }

    function restoreNameAndSymbol() external onlyOwner() {
        _name = "APE ASTAX";
        _symbol = "ASTAX \xF0\x9F\xA6\x8D";
    }

    function setMinimumTokensBeforeSwap(uint256 val) external onlyOwner() {
        minimumTokensBeforeSwap = val;
    }

    function setMinimumETHBeforeBurn(uint256 val) external onlyOwner() {
        minimumETHBeforeBurn = val;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}


// ==========  LIBS
library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }
}

interface IUniswapV2Router02  {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

