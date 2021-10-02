/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

// SPDX-License-Identifier: MIT

/*
KishuPlanet
https://t.me/KishuPlanet
you are on the kishu plane, let me take you on a tour around the planet,
KishuPlanet will launch at around 07:30-08:00 pm UTC
We took off with small initial LP
Maximum token purchase is 2.5%
Maximum wallet 5%

Hope you enjoy your journey on this planet!
*/

/*
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface InterfaceLP {
    function sync() external;
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
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
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface IMaster {
    function rebase() external;
}

contract KishuPlanet is ERC20Detailed, Ownable {
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    address public master;

    InterfaceLP public pairContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }

    bool public initialDistributionFinished;

    mapping(address => bool) allowTransfer;
    mapping(address => bool) _isFeeExempt;
    mapping(address => bool) _isMaxWalletExempt;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                allowTransfer[msg.sender]
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;
    uint256 public gonMaxWallet = (TOTAL_GONS / 100) * 5;
    uint256 public gonMaxTx = (TOTAL_GONS / 400);
    mapping (address => uint256) lastTransaction;
    uint256 public rateLimit = 10 seconds;

    uint256 public devFee = 3;
    uint256 public buyBackFee = 1;
    uint256 public marketingFee = 4;
    uint256 public totalFee = devFee + marketingFee + buyBackFee;
    uint256 public feeDenominator = 100;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address payable public marketingFeeReceiver;
    address payable public devFeeReceiver;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 private gonSwapThreshold = (TOTAL_GONS  / 10000) * 10;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = type(uint128).max;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping(address => mapping(address => uint256)) private _allowedFragments;

    bool public start;
    
    bool autoRebase = false;

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        require(!inSwap, "Try again");
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply -= uint256(-supplyDelta);
        } else {
            _totalSupply += uint256(supplyDelta);
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor() ERC20Detailed("KishuPlanet", "KishuPlane", uint8(DECIMALS)) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PCS 0x10ED43C718714eb63d5aA57B78B54704E256024E // Test 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        
        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[msg.sender][address(router)] = type(uint256).max;
        pairContract = InterfaceLP(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;

        initialDistributionFinished = false;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;

        _isMaxWalletExempt[pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[msg.sender] = true;

        marketingFeeReceiver = payable(0x1B0b537C6d993a7a4F2F99E580F82C4E538d8d82);
        devFeeReceiver = payable(msg.sender);
        
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function setMaster(address _master) external onlyOwner {
        master = _master;
    }
    
    function setAutoRebase(bool _auto) external onlyOwner {
        autoRebase = _auto;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        _isFeeExempt[_address];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
            _allowedFragments[from][msg.sender] -= value;
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount * _gonsPerFragment;

        if (sender != owner() && !_isMaxWalletExempt[recipient]) {
            uint256 heldGonBalance = _gonBalances[recipient];
            require(
                gonAmount <= gonMaxTx,
                "Max purchase is currently limited, you can not buy that much."
            );
            require(
                (heldGonBalance + gonAmount) <= gonMaxWallet,
                "Total Holding is currently limited, you can not hold that much."
            );
            require(lastTransaction[recipient] + rateLimit <= block.timestamp, "Purchase rate limit exceeded.");
            lastTransaction[recipient] = block.timestamp;
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] -= gonAmount;

        uint256 gonAmountReceived = shouldTakeFee(sender)
            ? takeFee(sender, gonAmount)
            : gonAmount;
        _gonBalances[recipient] += gonAmountReceived;

        if (autoRebase && !_isMaxWalletExempt[recipient]) {
            IMaster rb = IMaster(master);
            try rb.rebase() {} catch {}
        }
    
        emit Transfer(
            sender,
            recipient,
            gonAmountReceived / _gonsPerFragment
        );
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount * _gonsPerFragment;
        _gonBalances[from] -= gonAmount;
        _gonBalances[to] += gonAmount;
        return true;
    }
    
    function begin() external onlyOwner {
        start = true;
    }

    function takeFee(address sender, uint256 gonAmount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = (!start ? feeDenominator - 1 : gonAmount * totalFee) / feeDenominator;

        _gonBalances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount / _gonsPerFragment);

        return gonAmount - feeAmount;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = _gonBalances[address(this)] / _gonsPerFragment;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 amountETHMarketing = amountETH * marketingFee / totalFee;
        uint256 amountETHDev = amountETH * devFee / totalFee;

        marketingFeeReceiver.transfer(amountETHMarketing);
        devFeeReceiver.transfer(amountETHDev);
    }

    function approve(address spender, uint256 value)
        external
        override
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] += addedValue;
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        if (subtractedValue >= _allowedFragments[msg.sender][spender]) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] -= subtractedValue;
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    function enableTransfer(address _addr) external onlyOwner {
        allowTransfer[_addr] = true;
    }

    function setFeeExempt(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }

    function checkMaxWalletExempt(address _addr) external view returns (bool) {
        return _isMaxWalletExempt[_addr];
    }

    function setMaxWalletToken(uint256 _num, uint256 _denom)
        external
        onlyOwner
    {
        gonMaxWallet = (TOTAL_GONS / _denom) * _num;
    }
    
    function setMaxTx(uint256 _num, uint256 _denom)
        external
        onlyOwner
    {
        gonMaxTx = (TOTAL_GONS / _denom) * _num;
    }
    
    function setRateLimit(uint256 _rate)
        external
        onlyOwner
    {
        rateLimit = _rate;
    }

    function checkMaxWalletToken() external view returns (uint256) {
        return gonMaxWallet / _gonsPerFragment;
    }
    
    function checkMaxTx() external view returns (uint256) {
        return gonMaxTx / _gonsPerFragment;
    }

    function shouldTakeFee(address from) internal view returns (bool) {
        return !_isFeeExempt[from];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = (TOTAL_GONS / _denom) * _num;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold / _gonsPerFragment;
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }

    function setFees(
        uint256 _devFee,
        uint256 _buyBackFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external onlyOwner {
        devFee = _devFee;
        buyBackFee = _buyBackFee;
        marketingFee = _marketingFee;
        totalFee = devFee + marketingFee + buyBackFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }

    function setFeeReceivers(
        address _devFeeReceiver,
        address _marketingFeeReceiver
    ) external onlyOwner {
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function rescueToken(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }
    
    function buyBack(uint256 amountPercentage) external onlyOwner {
        uint256 amountETH = (address(this).balance * amountPercentage) / 100;
        
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETH}(
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer((amountETH * amountPercentage) / 100);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS - (_gonBalances[DEAD] + _gonBalances[ZERO])) / _gonsPerFragment;
    }

    function sendPresale(address[] calldata recipients, uint256[] calldata values)
        external
        onlyOwner
    {
      for (uint256 i = 0; i < recipients.length; i++) {
        _transferFrom(msg.sender, recipients[i], values[i]);
      }
    }

    receive() external payable {}
}