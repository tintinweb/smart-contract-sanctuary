pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

//openzeppelin contracts
import "./openzeppelin/contracts/token/IToken.sol";
import "./openzeppelin/contracts/token/IERC20.sol";
import "./openzeppelin/contracts/libraries/SafeMath.sol";
import "./openzeppelin/contracts/libraries/Ownable.sol";

//uniswap contracts
import "./pancakeswap/interfaces/IPancakeFactory.sol";
import "./pancakeswap/interfaces/IPancakePair.sol";
import "./pancakeswap/interfaces/IPancakeRouter01.sol";
import "./pancakeswap/interfaces/IPancakeRouter02.sol";

//minter contract
import "./minter/IPulseManager.sol";


//    #PULSE features:
//    5% Revive Basket: 
//    The owner will be able to define an arbitrary number of tokens, each with a corresponding weight. 
//    Each time a transfer is done, the 5% commission that is meant for the Revive basket will be used to buy these tokens 
//    from Pancake Swap according to their corresponding weight. After the contract buys the revive basket tokens, it will hold
//    the resulting LP. 

// 	A function will be implemented, and callable by the owner, which will redeem a specific LP, sell the obtained tokens for BNB, 
//     then use the BNB to acquire PULSE from Pancake Swap and distribute the resulting PULSE to all the PULSE holders proportional 
//     to their holdings.

//     2% Revive Launchdome:
//     There will be a revive launchdome wallet, changeable by the owner, which will receive 2% of the transferred token.

//     3% Pancake Swap Liquidity:
//     2% of the transferred amount will be used to add liquidity to the BNB <> PULSE pair in pancake swap. In this process, 
//     the contract will buy the proper amount of BNB (~equiv. with 1% of the transaction amount) and place them as liquidity in the 
//     Pancake Swap Pair, together with the remaining amount of the allocated 2%. The resulting LP will be held by the contract.
//     We will add a function which redeems the liquidity, sells the BNB for Pulse and burns the resulting pulse.


//     1% Distribution:
//     1% will be distributed among all the token holders

 


contract Pulse is Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isExcluded;
    mapping(address => bool) public isExcludedFromFee;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10**9; 
    //maximum supply starts with 10^9 and can grow to 10*18 
    uint256 private _rTotal = (MAX - (MAX % 10**18)) / 10**9;
    uint256 private _tFeeTotal;

    string private constant _name = "Pulse";
    string private constant _symbol = "PULSE";
    uint8 private constant _decimals = 9;

    address private pancakeSwapRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    //declaring fee percentages 
    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _reviveLaunchDomeFee = 2;
    uint256 private _previousReviveLaunchDomeFee = _reviveLaunchDomeFee;
    address private reviveLaunchDomeAddress;

    uint256 public _reviveBasketFee = 5;
    uint256 private _previousReviveBasketFee = _reviveBasketFee;

    IPancakeRouter02 public immutable pancakeSwapRouter;
    address public pancakeSwapPair;

    address public immutable minterAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 10**30;
    uint256 reviveBasketFeeToHandle=0;
    bool shouldTransfer = false;

    uint256 creationTime;

    struct Values {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rReviveLaunchDomeFee;
        uint256 rReviveBasketFee;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tReviveLaunchDomeFee;
        uint256 tReviveBasketFee;
    }

    //used to block all transactions while public sale is taking place
    modifier isTransfer {
        require(
            shouldTransfer,
            "Public sale: Transactions are stopped until the end of public sale"
        );
        _;
    }

    //checks if the address that called the function is the contract who handles the minting
    modifier onlyMinter {
        require(_msgSender() == minterAddress, "Mint: you are not the minter!");
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier checkFeeSum {
        _;
        require(_taxFee.add(_liquidityFee.add(_reviveBasketFee).add(_reviveLaunchDomeFee)) <= 10, "Pulse: the sum of fees should be less or equal to ten");
    }

    //declaring events that are occuring in this contract
    event Mint(address to, uint256 amount);
    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address sender, address recipient, uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );
    event SetReviveLaunchDomeAddress(address indexed user, address _reviveLaunchDomeAddress);
    // event SetTaxFeePercent(address indexed user, uint256 taxFee);
    // event SetLiquidityFeePercent(address indexed user, uint256 liquidityFee);
    // event SetReviveLaunchDomeFeePercent(address indexed user, uint256 reviveLaunchDomeFee);
    // event SetReviveBasketFeePercent(address indexed user, uint256 reviveBasketFee);
    event SetMaxTxPercent(address indexed user, uint256 maxTxPercent);
    //event ResumeTransactions(address indexed user);

    constructor(address _minterAddress, address _pancakeSwapRouterAddress) public {
        pancakeSwapRouterAddress = _pancakeSwapRouterAddress;

        IPancakeRouter02 _pancakeSwapRouter = IPancakeRouter02(
            _pancakeSwapRouterAddress
        );

        // Create a uniswap pair for this new token
        pancakeSwapPair = IPancakeFactory(_pancakeSwapRouter.factory())
        .createPair(address(this), _pancakeSwapRouter.WETH());
        // set the rest of the contract variables
        pancakeSwapRouter = _pancakeSwapRouter;

        minterAddress = _minterAddress;
        reviveLaunchDomeAddress = owner();

        //exclude owner, this contract, router and pair
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[_minterAddress] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[pancakeSwapRouterAddress] = true;

        _rOwned[owner()]=_rTotal;
        _tOwned[owner()]=_tTotal;

        creationTime = block.timestamp;
    }

    function getPair() public view returns(address) {
        return pancakeSwapPair;
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setReviveLaunchDomeAddress(address _reviveLaunchDomeAddress)
        public
        onlyOwner
    {
        reviveLaunchDomeAddress = _reviveLaunchDomeAddress;
        emit SetReviveLaunchDomeAddress(_msgSender(), _reviveLaunchDomeAddress);
    }

    function balanceOf(address account) public view returns (uint256) {
        if (isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        isTransfer
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public isTransfer returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount)
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
            _allowances[_msgSender()][spender].sub(subtractedValue)
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public  {
        require(!isExcluded[_msgSender()], "Sender is excluded!");
        address sender = _msgSender();
        uint256 currentRate = _getRate();
        _rOwned[sender] = _rOwned[sender].sub(tAmount.mul(currentRate));
        _rTotal = _rTotal.sub(tAmount.mul(currentRate));
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        Values memory values = _getValues(tAmount);
        if (!deductTransferFee) {
            return values.rAmount;
        } else {
            return values.rTransferAmount;
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

    function excludeFromReward(address _account) external onlyOwner {
        // require(account != 0xD99D1c33F9fC3444f8101754aBC46c52416550D1, 'We can not exclude Uniswap router.');
        require(!isExcluded[_account], "Account is already excluded");
        if (_rOwned[_account] > 0) {
            _tOwned[_account] = tokenFromReflection(_rOwned[_account]);
        }
        isExcluded[_account] = true;
        _excluded.push(_account);
    }

    function includeInReward(address _account) external onlyOwner {
        require(isExcluded[_account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == _account) {
                _excluded[i] = _excluded[_excluded.length.sub(1)];
                _tOwned[_account] = 0;
                isExcluded[_account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address _account) external onlyOwner {
        // require(account != 0xD99D1c33F9fC3444f8101754aBC46c52416550D1, 'We can not exclude Uniswap router.');        
        isExcludedFromFee[_account] = true;
    }

    function includeInFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external checkFeeSum onlyOwner {
        _taxFee = taxFee;
        //emit SetTaxFeePercent(_msgSender(), taxFee);
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external checkFeeSum onlyOwner {
        _liquidityFee = liquidityFee;
        //emit SetLiquidityFeePercent(_msgSender(), liquidityFee);
    }

    function setReviveLaunchDomeFeePercent(uint256 reviveLaunchDomeFee) external checkFeeSum onlyOwner {
        _reviveLaunchDomeFee = reviveLaunchDomeFee;
        //emit SetReviveLaunchDomeFeePercent(_msgSender(), reviveLaunchDomeFee);
    }

    function setReviveBasketFeePercent(uint256 reviveBasketFee) external checkFeeSum onlyOwner {
        _reviveBasketFee = reviveBasketFee;
        //emit SetReviveBasketFeePercent(_msgSender(), reviveBasketFee);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent) / 10**2;
        emit SetMaxTxPercent(_msgSender(), maxTxPercent);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (Values memory) {
        Values memory values;
        (
            values.tTransferAmount,
            values.tFee,
            values.tReviveLaunchDomeFee,
            values.tLiquidity,
            values.tReviveBasketFee
        ) = _getTValues(tAmount);
        (
            values.rAmount,
            values.rTransferAmount,
            values.rFee,
            values.rReviveLaunchDomeFee,
            values.rReviveBasketFee
        ) = _getRValues(
            tAmount,
            values.tFee,
            values.tReviveLaunchDomeFee,
            values.tReviveBasketFee,
            values.tLiquidity,
            _getRate()
        );
        return (values);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tTransferAmount = tAmount.sub(_calculateFee(tAmount, _taxFee));
        tTransferAmount = tTransferAmount.sub(
            _calculateFee(tAmount, _liquidityFee)
        );
        tTransferAmount = tTransferAmount.sub(
            _calculateFee(tAmount, _reviveLaunchDomeFee)
        );
        tTransferAmount = tTransferAmount.sub(
            _calculateFee(tAmount, _reviveBasketFee)
        );
        return (
            tTransferAmount,
            _calculateFee(tAmount, _taxFee),
            _calculateFee(tAmount, _reviveLaunchDomeFee),
            _calculateFee(tAmount, _liquidityFee),
            _calculateFee(tAmount, _reviveBasketFee)
        );
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tReviveLaunchDomeFee,
        uint256 tReviveBasketFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rTransferAmount = tAmount.mul(currentRate);
        rTransferAmount = rTransferAmount.sub(tFee.mul(currentRate));
        rTransferAmount = rTransferAmount.sub(tLiquidity.mul(currentRate));
        rTransferAmount = rTransferAmount.sub(
            tReviveLaunchDomeFee.mul(currentRate)
        );
        rTransferAmount = rTransferAmount.sub(
            tReviveBasketFee.mul(currentRate)
        );
        return (
            tAmount.mul(currentRate),
            rTransferAmount,
            tFee.mul(currentRate),
            tReviveLaunchDomeFee.mul(currentRate),
            tReviveBasketFee.mul(currentRate)
        );
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if ( 
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) {
                
                return (_rTotal, _tTotal);
            } 
            
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        
        if (rSupply < _rTotal.div(_tTotal)){
            return (_rTotal, _tTotal);
        }  
        return (rSupply, tSupply);
    }

    
    // Used to deposit "tLiquidity" amount of Pulse in the balance of this contract where
    // "tLiquidity" is "_liquidityFee" percentage of the amount that is being transfered 
    
    function _takeLiquidity(uint256 tLiquidity) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(tLiquidity.mul(_getRate()));
        if (isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    
    // Used to deposit "tReviveLaunchDomeFee" amount of Pulse in the balance of this contract where
    // "tReviveLaunchDomeFee" is "_reviveLaunchDomeFee" percentage of the amount that is being transfered
    
    function _takeReviveLaunchDomeFee(
        uint256 tReviveLaunchDomeFee
    ) private {
        _rOwned[reviveLaunchDomeAddress] = _rOwned[reviveLaunchDomeAddress].add(
            tReviveLaunchDomeFee.mul(_getRate())
        );
        if (isExcluded[reviveLaunchDomeAddress]) {
            _tOwned[reviveLaunchDomeAddress] = _tOwned[reviveLaunchDomeAddress]
            .add(tReviveLaunchDomeFee);
        }
    }

    // Used to deposit "tReviveBasketFee" amount of Pulse in the balance of this contract where
    // "tReviveBasketFee" is "_reviveBasketFee" percentage of the amount that is being transfered 
    // and revive basket functionality is called if "tReviveBasketFee" is greater than 0
    
    function _takeReviveBasketFee(
        uint256 tReviveBasketFee
    ) private {
        _rOwned[minterAddress] = _rOwned[minterAddress].add(tReviveBasketFee.mul(_getRate()));
        if(isExcluded[minterAddress]){
             _tOwned[minterAddress] = _tOwned[minterAddress].add(tReviveBasketFee);
        }
        if(tReviveBasketFee > 0) {
            reviveBasketFeeToHandle=reviveBasketFeeToHandle.add(tReviveBasketFee);
        }
    }

    //returns "_tax" percentage of "_amount"
    function _calculateFee(uint256 _amount, uint256 _tax)
        private
        pure
        returns (uint256)
    {
        return _amount.mul(_tax) / 10**2;
    }

    //used to remove all the fees that are being charged when a transfer is taking place
    function _removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousReviveLaunchDomeFee = _reviveLaunchDomeFee;
        _previousReviveBasketFee = _reviveBasketFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _reviveLaunchDomeFee = 0;
        _reviveBasketFee = 0;
    }

    //used to restore all the fees after a transfer that didn't charged any fee had occured
    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _reviveLaunchDomeFee = _previousReviveLaunchDomeFee;
        _reviveBasketFee = _previousReviveBasketFee;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) private {
        require(to != address(0), "Mint: mint to the zero address.");
        require(amount > 0, "Mint: mint amount must be greater than zero.");
        if (isExcluded[to]) {        
            _rOwned[to] = _rOwned[to].add(amount.mul(_getRate()));
            _tOwned[to] = _tOwned[to].add(amount);  
        } else {
            _rOwned[to] = _rOwned[to].add(amount.mul(_getRate()));
        }
        _rTotal = _rTotal.add(amount.mul(_getRate()));
        _tTotal = _tTotal.add(amount);

        emit Mint(to, amount);
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
        if (from != owner() && to != owner())
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender and receiver is excluded.
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            from != pancakeSwapPair &&
            to != pancakeSwapPair &&
            from != minterAddress &&
            to != minterAddress &&
            contractTokenBalance > 0
        ) {            
            _swapAndLiquify(contractTokenBalance); 
            IPulseManager minter = IPulseManager(minterAddress);
            minter.handleReviveBasket(reviveBasketFeeToHandle);    
            reviveBasketFeeToHandle=0;      
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcluded account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            takeFee = false;
        }
        //transfer amount, it will take tax, burn, liquidity, revive launch dome, revive basket fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        _rOwned[minterAddress] = _rOwned[minterAddress].add(contractTokenBalance.mul(_getRate()));
        if(isExcluded[minterAddress]){
             _tOwned[minterAddress] = _tOwned[minterAddress].add(contractTokenBalance);
        }

        _rOwned[address(this)] = _rOwned[address(this)].sub(contractTokenBalance.mul(_getRate()));
        if(isExcluded[address(this)]){
             _tOwned[address(this)] = _tOwned[address(this)].sub(contractTokenBalance);
        }


        IPulseManager minter = IPulseManager(minterAddress);
        minter.swapAndLiquify(contractTokenBalance);
        
    }

    //burn the resulted amount from the total supplies
    function burn(uint256 tokensToBeBurned)
        public
    {
        uint256 currentRate = _getRate();
        _rOwned[_msgSender()] = _rOwned[_msgSender()].sub(
            tokensToBeBurned * currentRate
        );
        if(isExcluded[_msgSender()]){
            _tOwned[_msgSender()] = _tOwned[_msgSender()].sub(tokensToBeBurned);
        }
        _rTotal = _rTotal.sub(tokensToBeBurned * currentRate);
        _tTotal = _tTotal.sub(tokensToBeBurned);
    }

    function resumeTransactions() public onlyOwner {
        shouldTransfer = true;
        //emit ResumeTransactions(_msgSender());
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) _removeAllFee();
        Values memory values = _getValues(amount);

        _rOwned[sender] = _rOwned[sender].sub(values.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(values.rTransferAmount);
        if(isExcluded[sender]){
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if(isExcluded[recipient]){
            _tOwned[recipient] = _tOwned[recipient].add(values.tTransferAmount);
        }
        
        //handle fees
        _takeLiquidity(values.tLiquidity);
        _takeReviveLaunchDomeFee(
            values.tReviveLaunchDomeFee
        );
        _takeReviveBasketFee(
            values.tReviveBasketFee
        );
        _reflectFee(values.rFee, values.tFee);
        emit Transfer(sender, recipient, values.tTransferAmount);
        if (!takeFee) _restoreAllFee();
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IToken {

    //used to deliver a specific amount of tokens to the all balance holders
    function deliver(uint256 tAmount) external;

    //returns the number of decimals that the token has
    function decimals() external view returns(uint8);

    function burn(uint256 tokenAmount) external;
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

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

    function mint(address to, uint256 amount) external;
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

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: substraction overflow");
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

    function mod(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division with 0");
        return a % b;
    }

    function div(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by 0");
        return a / b;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./Context.sol";

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
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

interface IPancakePair {
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

interface IPancakeRouter01 {
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

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IPulseManager {

    function handleReviveBasket(uint256 pulseAmount) external returns(bool);
    function swapAndLiquify(uint256 pulseAmount) external;

}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

