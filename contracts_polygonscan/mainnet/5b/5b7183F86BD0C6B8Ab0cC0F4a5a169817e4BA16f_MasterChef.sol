// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract CandyToken is IERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    uint256 public _rTotalExcluded;
    uint256 public _tTotalExcluded;

    uint256 private constant MAX = ~uint224(0);
    uint256 private _tTotal = (10**(21))*5;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Candy Token";
    string private _symbol = "CANDY";
    uint8 private _decimals = 18;

    uint256 public _taxFee = 4;
    uint256 public _liquidityFee = 0;
    uint256 public _burnFee = 0;
    uint256 public _referralPoints = 0;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxPercent = 4;
    uint256 private numTokensSellToAddToLiquidity = (5 * _tTotal) / 1e4;

    mapping(address => address) referrers;

    address public candyFarm;
    address public immutable operatorTimelock;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event ReferrerSet(address referrer, address referee);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyFarm {
        require(msg.sender == candyFarm, "only farm");
        _;
    }

    modifier onlyOperatorTimelock {
        require(msg.sender == operatorTimelock, "only operator timelock");
        _;
    }

    constructor(address _router, address _operatorTimelock) public {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        operatorTimelock = _operatorTimelock;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , ) = _getValues(tAmount, _getRate(), false);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
        emit Transfer(_msgSender(), address(0), 0);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , ) = _getValues(tAmount, _getRate(), false);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, ) = _getValues(
                tAmount,
                _getRate(),
                true
            );
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) private {
        require(!_isExcluded[account], "Account is already excluded");
        uint256 rOwned = _rOwned[account];
        if (rOwned > 0) {
            uint256 tOwned = tokenFromReflection(rOwned);
            _tOwned[account] = tOwned;
            _tTotalExcluded = _tTotalExcluded.add(tOwned);
            _rTotalExcluded = _rTotalExcluded.add(rOwned);
        }
        _isExcluded[account] = true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee <= 4, "Too high fee");
        _taxFee = taxFee;
    }

    // set _maxTxAmount in permille, not percent
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent >= 2, "Wrong amount");
        _maxTxPercent = maxTxPercent;
        require(
            maxTxAmount() > numTokensSellToAddToLiquidity,
            "must be greater than liquify threshold"
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 _newValue)
        external
        onlyOwner
    {
        require(_newValue < maxTxAmount(), "must be less that max tx amount");
        numTokensSellToAddToLiquidity = _newValue;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setRouter(address _router) external onlyOperatorTimelock {
        require(_router != address(0), "Zero address");
        uniswapV2Router = IUniswapV2Router02(_router);
        address newPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(this),
            uniswapV2Router.WETH()
        );
        require(newPair != address(0), "Pair not exist");
        uniswapV2Pair = newPair;
    }

    //referrals
    // function setReferrer(address referrerAddress) external {
    //     referrers[msg.sender] = referrerAddress;
    //     emit ReferrerSet(referrerAddress, msg.sender);
    // }

    //to receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _getValues(
        uint256 tAmount,
        uint256 currentRate,
        bool takeFee
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTransferAmount = _getTValues(tAmount, takeFee);
        (uint256 rAmount, uint256 rTransferAmount) = _getRValues(
            tAmount,
            tTransferAmount,
            currentRate
        );
        return (rAmount, rTransferAmount, tTransferAmount);
    }

    function _getTValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (uint256)
    {
        (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tReferral
        ) = _getFeeValues(tAmount, takeFee);
        uint256 tTransferAmount = tAmount.sub(
            tFee.add(tLiquidity).add(tBurn).add(tReferral)
        );
        return tTransferAmount;
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tTransferAmount,
        uint256 currentRate
    ) private pure returns (uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTransferAmount = tTransferAmount.mul(currentRate);
        return (rAmount, rTransferAmount);
    }

    function _getFeeValues(uint256 tAmount, bool takeFee)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 tReferral;
        if (takeFee) {
            tFee = tAmount.mul(_taxFee).div(1e3);
            tLiquidity = tAmount.mul(_liquidityFee).div(1e3);
            tBurn = tAmount.mul(_burnFee).div(1e3);
            tReferral = tAmount.mul(_referralPoints).div(1e3);
        }

        return (tFee, tLiquidity, tBurn, tReferral);
    }

    function _getRate() private view returns (uint256) {
        uint256 totalSupply_ = _tTotal;
        uint256 totalExcludedBalance_ = _tTotalExcluded;
        if (totalSupply_ <= totalExcludedBalance_) {
            return (_rTotal / totalSupply_);
        }
        if (_rTotal <= _rTotalExcluded) {
            return (_rTotal / totalSupply_);
        }
        uint256 rSupply = _rTotal - _rTotalExcluded; //overflow checked in the L315
        if (rSupply < _rTotal / totalSupply_) {
            return (_rTotal / totalSupply_);
        }
        return rSupply / (totalSupply_ - totalExcludedBalance_); //overflow checked in the L312
    }

    function _takeLiquidity(uint256 tLiquidity, uint256 currentRate) private {
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            _tTotalExcluded = _tTotalExcluded.add(tLiquidity);
            _rTotalExcluded = _rTotalExcluded.add(rLiquidity);
        }
    }

    function _reflectFee(
        uint256 tFee,
        uint256 tBurn,
        uint256 tReferral,
        uint256 currentRate
    ) private {
        _rTotal = _rTotal.sub(tFee.mul(currentRate));
        _tFeeTotal = _tFeeTotal.add(tFee);
        address referrer = referrers[msg.sender];
        uint256 tBurnTotal;
        if (referrer == address(0)) {
            tBurnTotal = tBurn.add(tReferral);
        } else {
            tBurnTotal = tBurn;
            _takeFee(msg.sender, tReferral.div(2), currentRate);
            _takeFee(referrer, tReferral.sub(tReferral.div(2)), currentRate);
        }

        uint256 rBurnTotal = tBurnTotal.mul(currentRate);
        _rTotal = _rTotal.sub(rBurnTotal);
        _tTotal = _tTotal.sub(tBurnTotal);
    }

    function _takeFee(
        address recipient,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
            _tTotalExcluded = _tTotalExcluded.add(tAmount);
            _rTotalExcluded = _rTotalExcluded.add(rAmount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (
            from != owner() &&
            to != owner() &&
            from != candyFarm &&
            to != candyFarm
        )
            require(
                amount <= maxTxAmount(),
                "Transfer amount exceeds the maxTxAmount."
            );

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function maxTxAmount() public view returns (uint256) {
        return _tTotal.mul(_maxTxPercent).div(10**3);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        if (tokenAmount > 1000) {
            //safety check for not calling swap with zero amount
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapV2Router.WETH();

            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // make the swap
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        if (ethAmount > 1000) {
            //safety check for not adding liquidity with a zero value
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(uniswapV2Router), tokenAmount);

            // add the liquidity
            uniswapV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 tTransferAmount
        ) = _getValues(tAmount, currentRate, takeFee);
        (
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn,
            uint256 tReferral
        ) = _getFeeValues(tAmount, takeFee);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _tTotalExcluded = _tTotalExcluded.sub(tAmount);
            _rTotalExcluded = _rTotalExcluded.sub(rAmount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _tTotalExcluded = _tTotalExcluded.add(tTransferAmount);
            _rTotalExcluded = _rTotalExcluded.add(rTransferAmount);
        }

        _takeLiquidity(tLiquidity, currentRate);
        _reflectFee(tFee, tBurn, tReferral, currentRate);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function recoverLockedTokens(address receiver, address token)
        external
        onlyOwner
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
            payable(receiver).transfer(balance);
            return balance;
        }
        require(address(this) != token, "only locked");
        balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver, balance);
    }

    function mint(address account, uint256 amount) external onlyFarm {
        require(account != address(0), "BEP20: mint to the zero address");

        uint256 currentRate = _getRate();
        uint256 rAmount = amount.mul(currentRate);

        _tTotal = _tTotal.add(amount);
        _rTotal = _rTotal.add(rAmount);

        _rOwned[account] = _rOwned[account].add(rAmount);
        require(
            _rOwned[account] <= _rTotal,
            "user reflection token amount should be small than total reflection tokens"
        );
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 tBurn) external returns (bool) {
        address account = _msgSender();
        require(balanceOf(account) >= tBurn, "Balance less than burn");
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[account] = _rOwned[account].sub(rBurn);
        _rTotal = _rTotal.sub(rBurn);
        _tTotal = _tTotal.sub(tBurn);
        emit Transfer(account, address(0), tBurn);
        return true;
    }

    function setCandyFarm(address _farmAddress) external onlyOwner {
        require(candyFarm == address(0), "already set");
        candyFarm = _farmAddress;
        excludeFromFee(candyFarm);
        excludeFromReward(candyFarm);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IReferral {
  /**
    * @dev Record referral.
    */
  function recordReferral(address user, address referrer) external;

  /**
    * @dev Get the referrer address that referred the user.
    */
  function getReferrer(address user) external view returns (address);
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './SafeMath.sol';
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IReferral.sol";

import "./CandyToken.sol";

contract MasterChef is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 public constant TOKEN_CAP = 175_000 ether;

	// Info of each user.
	struct UserInfo {
		uint256 amount;           // How many LP tokens the user has provided.
		uint256 rewardDebt;       // Reward debt. See explanation below.
		//
		// We do some fancy math here. Basically, any point in time, the amount of CANDYs
		// entitled to a user but is pending to be distributed is:
		//
		//   pending reward = (user.amount * pool.accCandyPerShare) - user.rewardDebt
		//
		// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
		//   1. The pool's `accCandyPerShare` (and `lastRewardBlock`) gets updated.
		//   2. User receives the pending reward sent to his/her address.
		//   3. User's `amount` gets updated.
		//   4. User's `rewardDebt` gets updated.
	}

	// Info of each pool.
	struct PoolInfo {
			IERC20 lpToken;           // Address of LP token contract.
			uint256 allocPoint;       // How many allocation points assigned to this pool. CANDYs to distribute per block.
			uint256 lastRewardBlock;  // Last block number that CANDYs distribution occurs.
			uint256 accCandyPerShare;   // Accumulated CANDYs per share, times 1e18. See below.
			uint16 depositFeeBP;      // Deposit fee in basis points
	}

	// The CANDY TOKEN!
	CandyToken public candy;
	// Dev address.
	address public devaddr;
	// CANDY tokens created per block.
	uint256 public candyPerBlock;
	// Bonus muliplier for early candy makers.
	uint256 public constant BONUS_MULTIPLIER = 1;
	// Deposit Fee address
	address public feeAddress;
	// Maximun emission
	uint256 constant public MAX_EMISSION_RATE = 20_000 szabo;

	// Info of each pool.
	PoolInfo[] public poolInfo;
	// Info of each user that stakes LP tokens.
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;
	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint = 0;
	// The block number when CANDY mining starts.
	uint256 public startBlock;
	// Candy referral contract address.
	IReferral public referral;
	// Referral commission rate in basis points.
	uint16 public referralCommissionRate = 200;
	// Max referral commission rate: 5%.
	uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;

	event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event SetFeeAddress(address indexed user, address indexed newAddress);
	event SetDevAddress(address indexed user, address indexed newAddress);
	event UpdateEmissionRate(address indexed user, uint256 candyPerBlock);
	event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
	event SetReferralAddress(address indexed user, IReferral indexed newAddress);

	constructor(
			CandyToken _candy,
			address _devaddr,
			address _feeAddress,
			uint256 _candyPerBlock,
			uint256 _startBlock
	) public {
			candy = _candy;
			devaddr = _devaddr;
			feeAddress = _feeAddress;
			candyPerBlock = _candyPerBlock;
			startBlock = _startBlock;
	}

	function poolLength() external view returns (uint256) {
			return poolInfo.length;
	}

	mapping(IERC20 => bool) public poolExistence;
	modifier nonDuplicated(IERC20 _lpToken) {
			require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
			_;
	}

	// Add a new lp to the pool. Can only be called by the owner.
	function add(
		uint256 _allocPoint,
		IERC20 _lpToken,
		uint16 _depositFeeBP,
		bool _withUpdate
	) public onlyOwner nonDuplicated(_lpToken) {
		require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");

		if (_withUpdate) {
			massUpdatePools();
		}

		uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
		totalAllocPoint         = totalAllocPoint.add(_allocPoint);
		poolExistence[_lpToken] = true;

		poolInfo.push(
			PoolInfo(
				{
					lpToken:         _lpToken,
					allocPoint:      _allocPoint,
					lastRewardBlock: lastRewardBlock,
					accCandyPerShare:  0,
					depositFeeBP:    _depositFeeBP
				}
			)
		);
	}

	// Update the given pool's CANDY allocation point and deposit fee. Can only be called by the owner.

	// Removed the possibility to change the Harvest Interval once setted for users saffety.
	function set(
		uint256 _pid,
		uint256 _allocPoint,
		uint16 _depositFeeBP,
		bool _withUpdate
	) public onlyOwner {
		require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");

		if (_withUpdate) {
				massUpdatePools();
		}

		totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
		poolInfo[_pid].allocPoint = _allocPoint;
		poolInfo[_pid].depositFeeBP = _depositFeeBP;
	}

	// Return reward multiplier over the given _from to _to block.
	function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
		uint256 totalSupply = candy.totalSupply();

		if(totalSupply > TOKEN_CAP)
            return 0;
		return _to.sub(_from).mul(BONUS_MULTIPLIER);
	}

	// View function to see pending CANDYs on frontend.
	function pendingCandy(uint256 _pid, address _user) external view returns (uint256) {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_user];
		uint256 accCandyPerShare = pool.accCandyPerShare;
		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (block.number > pool.lastRewardBlock && lpSupply != 0) {
			uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
			uint256 candyReward = multiplier.mul(candyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
			accCandyPerShare = accCandyPerShare.add(candyReward.mul(1e18).div(lpSupply));
		}

		uint256 pending = user.amount.mul(accCandyPerShare).div(1e18).sub(user.rewardDebt);

		return pending;
	}

	// Update reward variables for all pools. Be careful of gas spending!
	function massUpdatePools() public {
		uint256 length = poolInfo.length;

		for (uint256 pid = 0; pid < length; ++pid) {
			updatePool(pid);
		}
	}

	// Update reward variables of the given pool to be up-to-date.
	function updatePool(uint256 _pid) public {
		PoolInfo storage pool = poolInfo[_pid];

		if (block.number <= pool.lastRewardBlock) {
			return;
		}

		uint256 lpSupply = pool.lpToken.balanceOf(address(this));

		if (lpSupply == 0 || pool.allocPoint == 0) {
			pool.lastRewardBlock = block.number;
			return;
		}

		uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
		uint256 candyReward = multiplier.mul(candyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

		candy.mint(devaddr, candyReward.div(100));
		candy.mint(address(this), candyReward);

		pool.accCandyPerShare = pool.accCandyPerShare.add(candyReward.mul(1e18).div(lpSupply));
		pool.lastRewardBlock = block.number;
	}

	// Deposit LP tokens to MasterChef for CANDY allocation.
	function deposit(uint256 _pid, uint256 _amount, address _referrer) external nonReentrant {
		PoolInfo storage pool = poolInfo[_pid];

		if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
			referral.recordReferral(msg.sender, _referrer);
		}

		UserInfo storage user = userInfo[_pid][msg.sender];

		updatePool(_pid);

		if (user.amount > 0) {
			uint256 pending = user.amount.mul(pool.accCandyPerShare).div(1e18).sub(user.rewardDebt);

			if (pending > 0) {
				safeCandyTransfer(msg.sender, pending);
				payReferralCommission(msg.sender, pending);
			}
		}

		if (_amount > 0) {
			uint256 balanceBefore = pool.lpToken.balanceOf(address(this));

			pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

			_amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore); //update _amount if any transfer fees were applied

			if (pool.depositFeeBP > 0) {
				uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);

				// deposit dev share of fee
				pool.lpToken.safeTransfer(feeAddress, depositFee);

				user.amount = user.amount.add(_amount).sub(depositFee);
			} else {
				user.amount = user.amount.add(_amount);
			}
		}

		user.rewardDebt = user.amount.mul(pool.accCandyPerShare).div(1e18);

		emit Deposit(msg.sender, _pid, _amount);
	}

	// Withdraw LP tokens from MasterChef.
	function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];

		require(user.amount >= _amount, "withdraw: not good");

		updatePool(_pid);

		uint256 pending = user.amount.mul(pool.accCandyPerShare).div(1e18).sub(user.rewardDebt);

		if (pending > 0) {
			safeCandyTransfer(msg.sender, pending);
			payReferralCommission(msg.sender, pending);
		}

		if (_amount > 0) {
			user.amount = user.amount.sub(_amount);
			pool.lpToken.safeTransfer(address(msg.sender), _amount);
		}

		user.rewardDebt = user.amount.mul(pool.accCandyPerShare).div(1e18);

		emit Withdraw(msg.sender, _pid, _amount);
	}

	// Withdraw without caring about rewards. EMERGENCY ONLY.
	function emergencyWithdraw(uint256 _pid) public nonReentrant {
		PoolInfo storage pool = poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];
		uint256 amount = user.amount;
		user.amount = 0;
		user.rewardDebt = 0;

		pool.lpToken.safeTransfer(address(msg.sender), amount);

		emit EmergencyWithdraw(msg.sender, _pid, amount);
	}

	// Safe CANDY transfer function, just in case if rounding error causes pool to not have enough CANDYs.
	function safeCandyTransfer(address _to, uint256 _amount) internal {
		uint256 candyBal = candy.balanceOf(address(this));
		bool transferSuccess = false;

		if (_amount > candyBal) {
			transferSuccess = candy.transfer(_to, candyBal);
		} else {
			transferSuccess = candy.transfer(_to, _amount);
		}

		require(transferSuccess, "safeCandyTransfer: transfer failed");
	}

	// Update dev address by the previous dev.
	function dev(address _devaddr) public {
		require(msg.sender == devaddr, "dev: wut?");
		devaddr = _devaddr;

		emit SetDevAddress(msg.sender, _devaddr);
	}

	function setFeeAddress(address _feeAddress) public {
		require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
		feeAddress = _feeAddress;

		emit SetFeeAddress(msg.sender, _feeAddress);
	}

	// Update the referral contract address by the owner
	function setReferralAddress(IReferral _referral) external onlyOwner {
		referral = _referral;
		emit SetReferralAddress(msg.sender, _referral);
	}

	// Update referral commission rate by the owner
	function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
		require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
		referralCommissionRate = _referralCommissionRate;
	}

	// Pay referral commission to the referrer who referred this user.
	function payReferralCommission(address _user, uint256 _pending) internal {
		if (address(referral) != address(0) && referralCommissionRate > 0) {
			address referrer = referral.getReferrer(_user);
			uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);
			uint256 totalSupply = candy.totalSupply();

			if (referrer != address(0) && commissionAmount > 0 && totalSupply < TOKEN_CAP) {
				candy.mint(referrer, commissionAmount);
				emit ReferralCommissionPaid(_user, referrer, commissionAmount);
			}
		}
	}

	function updateEmissionRate(uint256 _candyPerBlock) public onlyOwner {
		require(_candyPerBlock <= MAX_EMISSION_RATE, "emission: too high");
		massUpdatePools();

		candyPerBlock = _candyPerBlock;

		emit UpdateEmissionRate(msg.sender, _candyPerBlock);
	}

	// Only update before start of pool
	function updateStartBlock(uint256 _startBlock) external onlyOwner {
		require(startBlock > block.number, "Pool already started");

		uint256 length = poolInfo.length;

		for (uint256 pid = 0; pid < length; ++pid) {
				PoolInfo storage pool = poolInfo[pid];
				pool.lastRewardBlock = _startBlock;
		}

		startBlock = _startBlock;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Context.sol';

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
    constructor() internal {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

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
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}