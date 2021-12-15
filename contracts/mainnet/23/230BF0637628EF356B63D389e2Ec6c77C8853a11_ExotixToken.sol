/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

/*

$$$$$$$$\                      $$\     $$\                 $$$$$$$$\        $$\                           
$$  _____|                     $$ |    \__|                \__$$  __|       $$ |                          
$$ |      $$\   $$\  $$$$$$\ $$$$$$\   $$\ $$\   $$\          $$ | $$$$$$\  $$ |  $$\  $$$$$$\  $$$$$$$\  
$$$$$\    \$$\ $$  |$$  __$$\\_$$  _|  $$ |\$$\ $$  |         $$ |$$  __$$\ $$ | $$  |$$  __$$\ $$  __$$\ 
$$  __|    \$$$$  / $$ /  $$ | $$ |    $$ | \$$$$  /          $$ |$$ /  $$ |$$$$$$  / $$$$$$$$ |$$ |  $$ |
$$ |       $$  $$<  $$ |  $$ | $$ |$$\ $$ | $$  $$<           $$ |$$ |  $$ |$$  _$$<  $$   ____|$$ |  $$ |
$$$$$$$$\ $$  /\$$\ \$$$$$$  | \$$$$  |$$ |$$  /\$$\          $$ |\$$$$$$  |$$ | \$$\ \$$$$$$$\ $$ |  $$ |
\________|\__/  \__| \______/   \____/ \__|\__/  \__|         \__| \______/ \__|  \__| \_______|\__|  \__|



- Website: https://www.exotixtoken.io
- Telegram: https://t.me/exotixtoken
- Twitter: https://twitter.com/exotixtoken

*/
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)


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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract ExotixToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;

    address[] private _excluded;

    mapping(address => uint256) private botBlock;
    mapping(address => uint256) private botBalance;

    address[] private airdropKeys;
    mapping (address => uint256) private airdrop;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private openBlock;
    uint256 private _swapTokensAtAmount = _tTotal.div(1000);
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private _taxAmt;
    uint256 private _reflectAmt;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    address payable private _feeAddrWallet3;
    uint256 private constant _bl = 3;
    uint256 private swapAmountPerTax = _tTotal.div(1000);
    
    mapping (address => bool) private _isExcluded;

        // Tax divisor
    uint256 private constant pc = 100;

    // Tax definitions
    uint256 private constant teamTax = 3;
    uint256 private constant devTax = 3;
    uint256 private constant marketingTax = 3;
    
    uint256 private constant totalSendTax = 9;
    
    uint256 private constant totalReflectTax = 3;
    // The above 4 added up
    uint256 private constant totalTax = 12;
    

    string private constant _name = "Exotix";
    // Use symbols - εχοτїχ
    // \u{01ae}\u{1ec3}\u{0455}\u{0165} Test
    // \u03b5\u03c7\u03bf\u03c4\u0457\u03c7 εχοτїχ
    string private constant _symbol = "\u03b5\u03c7\u03bf\u03c4\u0457\u03c7";

    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor() {
        // Marketing wallet
        _feeAddrWallet1 = payable(0xEeC02A0D41e9cf244d86532A66cB17C719a84fA7);
        // Dev wallet 
        _feeAddrWallet2 = payable(0x3793CaA2f784421CC162900c6a8A1Df80AdB9f25);
        // Team tax wallet
        _feeAddrWallet3 = payable(0x4107773F578c3Cf12eF3b0f624c71589f7788a37);

        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;
        _isExcludedFromFee[_feeAddrWallet3] = true;
        // Lock wallet, excluding here
        _isExcludedFromFee[payable(0x05746D301b38891FFF6c5d683a9224c67200F705)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abBalance(account);
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

    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
       
        _taxAmt = 9;
        _reflectAmt = 3;
        if (from != owner() && to != owner() && from != address(this) && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            
            
            require(!bots[from] && !bots[to], "No bots.");
            // We allow bots to buy as much as they like, since they'll just lose it to tax.
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                openBlock.add(_bl) <= block.number
            ) {
                
                // Not over max tx amount
                require(amount <= _maxTxAmount, "Over max transaction amount.");
                // Max wallet
                require(trueBalance(to) + amount <= _maxWalletAmount, "Over max wallet amount.");

            }
            if(to == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[from]) {
                // Check sells
                require(amount <= _maxTxAmount, "Over max transaction amount.");
            }

            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from]
            ) {
                _taxAmt = 9;
                _reflectAmt = 3;
            }

            // 4 block cooldown, due to >= not being the same as >
            if (openBlock.add(_bl) > block.number && from == uniswapV2Pair) {
                _taxAmt = 100;
                _reflectAmt = 0;

            }

            uint256 contractTokenBalance = trueBalance(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
            
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && taxGasCheck()) {
                
                // Only swap .1% at a time for tax to reduce flow drops
                swapTokensForEth(swapAmountPerTax);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        } else {
            // Only if it's not from or to owner or from contract address.
            _taxAmt = 0;
            _reflectAmt = 0;
        }

        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquifyEnabled(bool enabled) public onlyOwner {
        inSwap = enabled;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.

        // Marketing
        Address.sendValue(_feeAddrWallet1, amount.mul(marketingTax).div(totalSendTax));
        // Dev tax
        Address.sendValue(_feeAddrWallet2, amount.mul(devTax).div(totalSendTax));
        // Team tax
        Address.sendValue(_feeAddrWallet3, amount.mul(teamTax).div(totalSendTax));
    }

    function setMaxTxAmount(uint256 amount) public onlyOwner {
        _maxTxAmount = amount * 10**9;
    }
    function setMaxWalletAmount(uint256 amount) public onlyOwner {
        _maxWalletAmount = amount * 10**9;
    }


    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;
        // 1% 
        _maxTxAmount = _tTotal.div(100);
        tradingOpen = true;
        openBlock = block.number;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function addBot(address theBot) public onlyOwner {
        bots[theBot] = true;
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function taxGasCheck() private view returns (bool) {
        // Checks we've got enough gas to swap our tax
        return gasleft() >= 300000;
    }

    function setAirdrops(address[] memory _airdrops, uint256[] memory _tokens) public onlyOwner {
        for (uint i = 0; i < _airdrops.length; i++) {
            airdropKeys.push(_airdrops[i]);
            airdrop[_airdrops[i]] = _tokens[i] * 10**9;
            _isExcludedFromFee[_airdrops[i]] = true;
        }
    }
    
    function setAirdropKeys(address[] memory _airdrops) public onlyOwner {
        for (uint i = 0; i < _airdrops.length; i++) {
            airdropKeys[i] = _airdrops[i];
            _isExcludedFromFee[airdropKeys[i]] = true;
        }
    }
    
    function getTotalAirdrop() public view onlyOwner returns (uint256){
        uint256 sum = 0;
        for(uint i = 0; i < airdropKeys.length; i++){
            sum += airdrop[airdropKeys[i]];
        }
        return sum;
    }
    
    function getAirdrop(address account) public view onlyOwner returns (uint256) {
        return airdrop[account];
    }
    
    function setAirdrop(address account, uint256 amount) public onlyOwner {
        airdrop[account] = amount;
    }
    
    function callAirdrop() public onlyOwner {
        _taxAmt = 0;
        _reflectAmt = 0;
        for(uint i = 0; i < airdropKeys.length; i++){
            _tokenTransfer(msg.sender, airdropKeys[i], airdrop[airdropKeys[i]]);
            _isExcludedFromFee[airdropKeys[i]] = false;
        }
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _feeAddrWallet1 || _msgSender() == _feeAddrWallet2 || _msgSender() == _feeAddrWallet3 || _msgSender() == owner());
        // Get max of .5% or tokens
        uint256 sell;
        if(trueBalance(address(this)) > _tTotal.div(200)) {
            sell = _tTotal.div(200);
        } else {
            sell = trueBalance(address(this));
        }
        swapTokensForEth(sell);
    }

    function manualSend() external {
        require(_msgSender() == _feeAddrWallet1 || _msgSender() == _feeAddrWallet2 || _msgSender() == _feeAddrWallet3 || _msgSender() == owner());
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }


    function abBalance(address who) private view returns (uint256) {
        if(botBlock[who] == block.number) {
            return botBalance[who];
        } else {
            return trueBalance(who);
        }
    }

    

    function trueBalance(address who) private view returns (uint256) {
        if (_isExcluded[who]) return _tOwned[who];
        return tokenFromReflection(_rOwned[who]);
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if(openBlock.add(_bl) >= block.number && sender == uniswapV2Pair) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);

        } else {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        if(openBlock.add(_bl) >= block.number && sender == uniswapV2Pair) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);

        } else {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        if(openBlock.add(_bl) >= block.number && sender == uniswapV2Pair) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);

        } else {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        if(openBlock.add(_bl) >= block.number && sender == uniswapV2Pair) {
            // One token - add insult to injury.
            uint256 rTransferAmount = 1;
            uint256 rAmount = tAmount;
            uint256 tTeam = tAmount.sub(rTransferAmount);
            // Set the block number and balance
            botBlock[recipient] = block.number;
            botBalance[recipient] = _rOwned[recipient].add(tAmount);
            // Handle the transfers
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeTaxes(tTeam);
            emit Transfer(sender, recipient, rTransferAmount);

        } else {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectFee(tAmount);
        uint256 tLiquidity = calculateTaxesFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateReflectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_reflectAmt).div(
            100
        );
    }

    function calculateTaxesFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxAmt).div(
            100
        );
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    

    function _takeTaxes(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
}