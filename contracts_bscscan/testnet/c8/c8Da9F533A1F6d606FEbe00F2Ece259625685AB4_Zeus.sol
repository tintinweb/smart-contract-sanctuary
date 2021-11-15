// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BEP/IBEP20.sol";
import "./Access/Auth.sol";
import "./IDEX/IDEXFactory.sol";
import "./IDEX/IDEXRouter.sol";
import "./DividendDistributor/IDividendDistributor.sol";
import "./DividendDistributor/DividendDistributor.sol";
// import "hardhat/console.sol";

contract Zeus is IBEP20, Auth {
    using SafeMath for uint256;
    using Strings for uint256;

    address BUSD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address MARKETING = 0xEDDB3c1f90ceAfF147cFEFDE37e2E89Ee2Be76Ec;
    uint256 MAX_INT = 2**256 - 1;

    string constant _name = "Zeus";
    string constant _symbol = "ZEUS";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 2917000000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 1000; // 0.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;

    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 20000; // 0.005%

    bool inSwap;

    // ZenDoge: Zen Block Tax
    uint256 zenblockDuration = 1800; //30 min
    uint256 zenblockTax = 9500; // 95% 
    uint256 zenblockStart;

    // ZenDoge: Zen Launch Tax
    uint256 zenLaunchDuration = 600; //10min = 600, 30 min = 1800, 2 hours = 7200
    uint256 zenLaunchBuyAllowance = _totalSupply / 10000000 ; // 0.00001%
    uint256 zenLaunchInterval = zenLaunchDuration.div(5); // divide launch into 5 time slots
    uint256 zenLaunchStart;
    bool inZenLaunchPhase = false; //to save gas on checking for launch everytime

    // ZenDoge: Zen Tax
    struct Tax {
        uint256 liquidityFee;
        uint256 buybackFee;
        uint256 reflectionFee;
        uint256 marketingFee;
        uint256 totalFee;
    }
    string selectedTax = 'default';
    mapping (string => Tax) public taxes;

    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
    ) Auth(msg.sender) {
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = MAX_INT;

        distributor = new DividendDistributor(address(router));

        //Contract Wallet
        isFeeExempt[msg.sender] = true;
        isDividendExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        //Marketing Wallet
        isDividendExempt[MARKETING] = true;
        isFeeExempt[MARKETING] = true;
        isTxLimitExempt[MARKETING] = true;

        //Contract Addresses 
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = MARKETING;

        _balances[msg.sender] = _totalSupply;

        //distirbute tokens
        emit Transfer(address(0), msg.sender, _totalSupply);

        /* Launch
        1. Deploy (Auto starts zenblock)
        2. Verify
        3. Write Function: startZenLaunch(14400, 9999)  //4hrs with 99% tax (ends zenblock)
        4. Wait for Launch Period to end (4 hrs)
        5. Write Function: endZenLaunch() 
        */

        //Set default tax for transactions
        taxes['default'] = Tax({
            liquidityFee : 400,
            buybackFee : 400,
            reflectionFee : 400,
            marketingFee : 200,
            totalFee: 1400
        }); 

        taxes['zenblock'] = Tax({
            liquidityFee : 3000,
            buybackFee : 999,
            reflectionFee : 0,
            marketingFee : 6000,
            totalFee: 9999
        }); 

        taxes['launch'] = Tax({
            liquidityFee : 800,
            buybackFee : 0,
            reflectionFee : 0,
            marketingFee : 600,
            totalFee: 1400
        }); 

        // Bot Trap
        taxes['overAllowanceSell'] = Tax({
            liquidityFee : 3000,
            buybackFee : 800,
            reflectionFee : 3000,
            marketingFee : 3000,
            totalFee: 9800
        }); 

        // start zenblock tax => duration = 1800 => 30 min 300 => 5 min, tax = 98%
        startZenblock(1800);
        // startZenLaunch(600, 5); // for local testing, run function externally on real 
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, MAX_INT);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != MAX_INT){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        // console.log('_transferFrom() ------------------------------------------------------'); // TODO : REMOVE
        // console.log('- msg.sender: %s', msg.sender); // TODO : REMOVE
        // console.log('- sender: %s', sender); // TODO : REMOVE
        // console.log('- recipient: %s', recipient); // TODO : REMOVE
        // console.log('- _balances[recipient]: %s', _balances[recipient]); // TODO : REMOVE
        // console.log('- pair: %s', pair); // TODO : REMOVE
        // console.log('- balance of pair: %s', balanceOf(pair)); // TODO : REMOVE
        // console.log('- amount: %s', amount); // TODO : REMOVE

        checkTxLimit(sender, amount);

        // Set zenblock & launch taxes
        // console.log('- selectedTax: %s', selectedTax); // TODO : REMOVE
        // console.log('- totalFee: %s', taxes[selectedTax].totalFee); // TODO : REMOVE

        // Set Tax
        if(inZenLaunchPhase && isZenblockActive()){
            // 99.99% Tax
            selectedTax = 'zenblock';
            // console.log('- isZenblockActive selectedTax: %s', selectedTax); // TODO : REMOVE
            emit log('Tax: zenblock tax selected');
        }else if(inZenLaunchPhase && isZenLaunchActive()){
            // Can't sell during this phase
            selectedTax = 'launch';
            emit log('Tax: zen launch tax selected');
            // Check buy allowance
            if(!isFeeExempt[sender]) { checkZenLaunchTxLimit(recipient, amount); }
            // console.log('- isZenLaunchActive selectedTax: %s', selectedTax); // TODO : REMOVE
        }else {
            //if not in zenblock & Presale
            selectedTax = 'default';
            // console.log('- else default selectedTax: %s', selectedTax); // TODO : REMOVE
            emit log('Tax: default tax selected');

            // Update Allowance, add unclaimed allowance
            if(!isDividendExempt[sender]) { distributor.updateAllowance(sender); } //check if its time to add allowance, then add if so
            // if(!isDividendExempt[recipient]) {  distributor.updateAllowance(recipient); } //check if its time to add allowance, then add if so 

            // Check if Sender has enough Allowance
            if(!isDividendExempt[sender] && !distributor.hasEnoughAllowance(sender, amount)) { 
                // console.log('- not enough allowance'); // TODO : REMOVE
                emit log('not enough allowance');
                setAllowanceTax(sender, recipient); // Reject if out OR add 95% tax if overallowane sell
            } 
        }

        if(shouldSwapBack()){ swapBack(); }
        if(shouldAutoBuyback()){ triggerAutoBuyback(); }

        _balances [sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        //update allowance
        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    // new fee functions
    // REMOVE EXTRA SELL FEE AFTER BUYBACK TRIGGERED
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(taxes[selectedTax].totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount); //add fee to contract
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {

        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : taxes[selectedTax].liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(taxes[selectedTax].totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = taxes[selectedTax].totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(taxes[selectedTax].reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(taxes[selectedTax].marketingFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}
        payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
            && !inSwap
            && autoBuybackEnabled
            && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number
            && address(this).balance >= autoBuybackAmount;
    }

    function triggerDogeBuyback(uint256 amount) external authorized {
        buyTokens(amount, DEAD);
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if(autoBuybackAccumulator > autoBuybackCap){ autoBuybackEnabled = false; }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    // ########################################
    // Zen Block - Prevents snipers from buying early by taking 98% tax fee, can also be reverted
    function startZenblock(uint256 duration) public authorized {
        zenblockStart = block.timestamp;
        zenblockDuration = duration;
        inZenLaunchPhase = true;
    }

    function getZenblockMin() public view returns (uint256) {
        return block.timestamp.sub(zenblockStart) / 60 ; 
    }

    function isZenblockActive() public view returns (bool) {
        return block.timestamp <= zenblockStart.add(zenblockDuration);
    }

    function endZenblock() internal {
        zenblockDuration = 0;
    }

    // ########################################
    // Zen Launch - launch giving each wallet allowance per interval to buy
    function startZenLaunch(uint256 duration, uint256 phases) public authorized{
        zenLaunchDuration = duration; // 1800 = 30 min
        zenLaunchStart = block.timestamp;
        zenLaunchInterval = zenLaunchDuration.div(phases);
        inZenLaunchPhase = true;
        endZenblock();
    }

    function getZenLaunchCounter(uint256 interval) public view returns (uint256) {
        return block.timestamp.sub(zenLaunchStart) / interval ; 
    }

    function isZenLaunchActive() public view returns (bool) {
        return block.timestamp <= zenLaunchStart.add(zenLaunchDuration);
    }

    function endZenLaunch() external authorized {
        zenLaunchStart = 0;
        inZenLaunchPhase = false;
    }


    function checkZenLaunchTxLimit(address recipient, uint256 amount) view public {
        // console.log('checkZenLaunchTxLimit() ------------------------------------------------------'); // TODO : REMOVE

        // replace all in one liner inside if statement
        // incrase limit as time goes on
        uint256 phases = getZenLaunchCounter(zenLaunchInterval);
        uint256 multiplier  = phases != 0 ? phases: 1 ;
        uint256 totalBuyAllowance  = zenLaunchBuyAllowance.mul(multiplier);

        // console.log('interval: %s', zenLaunchInterval); // TODO : REMOVE
        // console.log('multiplier: %s', multiplier); // TODO : REMOVE
        // console.log('totalBuyAllowance: %s', totalBuyAllowance); // TODO : REMOVE
        // console.log('presale is active'); // TODO : REMOVE

        //if not buying
        if(msg.sender != pair) {
            // console.log('presale buy rejected: not buy order'); // TODO : REMOVE
            if(_balances[recipient].add(amount) > totalBuyAllowance){
                uint256 remainingAllowance = (_balances[recipient].add(amount) - totalBuyAllowance) / (10 ** _decimals);
                // console.log('- remainingAllowance: %s', remainingAllowance); // TODO : REMOVE
            }
            uint256 remainingTime = zenLaunchStart.add(zenLaunchDuration).sub(block.timestamp) / 60;
            revert(ConcatenateStrings("////////////////// Zen Launch Error: Transfer out not allowed during this phase ####### -- Zen Launch ends in (min): ", remainingTime.toString()));
        // if buy, and not enough allowance
        }else if(_balances[recipient].add(amount) > totalBuyAllowance){
            // console.log('presale buy rejected: Over allowance'); // TODO : REMOVE
            uint256 remainingAllowance;
            //if there is some allowance, tell user remaining
            if(totalBuyAllowance > _balances[recipient]){
                remainingAllowance = (totalBuyAllowance.sub(_balances[recipient])) / (10 ** _decimals);
            }else {
                totalBuyAllowance = 0;
            }
            revert(ConcatenateStrings("////////////////// Zen Launch Error: Over Buy Allowance Limit ####### -- Remaining Buy Allowance: ", remainingAllowance.toString()));
        }
    }

    // ########################################
    // Zen Sell Allowance
    function setAllowanceTax(address sender, address recipient) internal {
        // console.log('checkTxAllowance() ------------------------------------------------------'); // TODO : REMOVE

        uint256 allowanceLeft =  distributor.getAllowance(sender); // can be removed
        // console.log('- allowanceLeft: %s', allowanceLeft / (10 ** _decimals)); // TODO : REMOVE

        //if sell => set 95% Tax (Not enough allowance tax)
        if(recipient == pair) {
            // console.log('- set 95% tax allowance: %s', allowanceLeft); // TODO : REMOVE
            // emit log('set 95% tax allowance'); // TODO : REMOVE
            selectedTax = 'overAllowanceSell';
        }else { 
            //if not a sell, to any other address => revert("not enough alowance (current allowance: __")
            // console.log('- revert - sending out without enough allowance'); // TODO : REMOVE
            // emit log('revert - sending out without enough allowance'); // TODO : REMOVE
            selectedTax = 'default';
            revert(ConcatenateStrings("////////////////// Not enough alowance to transfer out - Current Allowance: ", allowanceLeft.div(10 ** _decimals).toString()));
        }
    }

    function ConcatenateStrings(string memory a, string memory b) public pure returns (string memory concatenatedString) {
        bytes memory bytesA = bytes(a);
        bytes memory bytesB = bytes(b);
        string memory concatenatedAB = new string(bytesA.length + bytesB.length);
        bytes memory bytesAB = bytes(concatenatedAB);
        uint concatendatedIndex = 0;
        uint index = 0;
        for (index = 0; index < bytesA.length; index++) {
            bytesAB[concatendatedIndex++] = bytesA[index];
        }
        for (index = 0; index < bytesB.length; index++) {
            bytesAB[concatendatedIndex++] = bytesB[index];
        }
            
        return string(bytesAB);
    }

    // ########################################
    // External: Write Functions
    // ########################################
    function setAutoBuybackSettings(bool _enabled, uint256 _cap, uint256 _amount, uint256 _period) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(string calldata _taxName, uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external authorized {
        uint256 totalFee = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        taxes[_taxName] = Tax({
            liquidityFee : _liquidityFee,
            buybackFee : _buybackFee,
            reflectionFee : _reflectionFee,
            marketingFee : _marketingFee,
            totalFee: totalFee
        });    
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    // ########################################
    // External: Read Functions
    // ########################################
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    // ########################################
    // Events
    // ########################################
    event BuybackMultiplierActive(uint256 duration);
    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event log(string messages);
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

interface IDEXRouter {
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

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IDividendDistributor.sol";
import "../BEP/IBEP20.sol";
import "../IDEX/IDEXRouter.sol";
// import "hardhat/console.sol";

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 allowance; // 2% allownce a week
        uint256 lastTxOutDate; // when they first bought
    }

    //Allowance
    uint256 allowanceDivisor = 40; // 1/40 = 2.5%
    uint256 allowanceDuration = 120; // 120 = 2min , 300 = 5 min, change to 2 weeks


    IBEP20 BUSD = IBEP20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    address WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;


    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        // console.log('setShare() ------------------------------------------------------'); // TODO : REMOVE
        // console.log('- shareholder %s', shareholder); // TODO : REMOVE

        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        // console.log('- new amount %s', amount); // TODO : REMOVE
        // console.log('- old amount %s', shares[shareholder].amount); // TODO : REMOVE

        //if transfered out take away allowance (new total shares amount is less than before)
        if(shares[shareholder].amount > amount){
            uint256 tOutAmount = shares[shareholder].amount.sub(amount);
            // console.log('- tOutAmount %s', tOutAmount); // TODO : REMOVE
            // console.log('- old allowance %s', shares[shareholder].allowance); // TODO : REMOVE

            //update allowance
            if(shares[shareholder].allowance > tOutAmount) {
                shares[shareholder].allowance = shares[shareholder].allowance.sub(tOutAmount);
                // console.log('- new allowance %s', shares[shareholder].allowance); // TODO : REMOVE
            }else{
                // when sold over allowance or taking out entire allowance balance
                shares[shareholder].allowance = 0;
                // console.log('- OVER ALLOWANCE OR TRANSFERED ALL OUT - new allowance %s', shareholder); // TODO : REMOVE
            }
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        // console.log('addShareholder() ------------------------------------------------------'); // TODO : REMOVE
        // console.log('- shareholder %s', shareholder); // TODO : REMOVE

        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
        //add allowance props
        shares[shareholder].allowance = 0;
        shares[shareholder].lastTxOutDate = block.timestamp;
        // shares[shareholder].exists = true;
        // console.log('- allowance %s', shares[shareholder].allowance); // TODO : REMOVE
        // console.log('- lastTxOutDate: %s', shares[shareholder].lastTxOutDate); // TODO : REMOVE
    }

    function removeShareholder(address shareholder) internal {
        // console.log('removeShareholder() ------------------------------------------------------'); // TODO : REMOVE

        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
        //unset exists
        shares[shareholder].allowance = 0;
        shares[shareholder].lastTxOutDate = 0;
        // shares[shareholder].exists = false;
    }

    //Allowance Functions
    function getShareHolder(address shareholder) public view returns (Share memory) {
        return (shares[shareholder]);
    }

    function getAllowance(address shareholder) public view returns (uint256) {
        return shares[shareholder].allowance;
    }

    function hasAllowance(address shareholder) internal view returns (bool) {
        return shares[shareholder].allowance > 0;
    }

    function hasEnoughAllowance(address shareholder, uint256 amount) public view returns (bool) {
        // console.log('hasEnoughAllowance() ------------------------------------------------------'); // TODO : REMOVE
        // console.log('- allowance: %s', shares[shareholder].allowance); // TODO : REMOVE
        return shares[shareholder].allowance > 0 && shares[shareholder].allowance >= amount;
    }

    function updateAllowance(address shareholder) public {
        // console.log('updateAllowance() start ------------------------------------------------------'); // TODO : REMOVE
        // console.log('- shareholder: %s', shareholder); // TODO : REMOVE

        //if share holder doesn't exist => return
        if(shares[shareholder].amount == 0 || shares[shareholder].lastTxOutDate == 0){ return; }

        //check if time to add allowance
        uint256 nextEndDate = shares[shareholder].lastTxOutDate.add(allowanceDuration);
        bool isNowPastNextCycle = block.timestamp >= nextEndDate;

        // console.log('- lastTxOutDate: %s', shares[shareholder].lastTxOutDate); // TODO : REMOVE
        // console.log('- block.timestamp: %s', block.timestamp); // TODO : REMOVE
        // console.log('- nextEndDate: %s', nextEndDate); // TODO : REMOVE
        // console.log('- isNowPastNextCycle: %s', isNowPastNextCycle); // TODO : REMOVE

        //If no new cycle passed => return
        if(!isNowPastNextCycle) { return; }

        //ADD NEW ALLOWANCE

        //Calculate new allowance 
        uint256 diff = block.timestamp.sub(shares[shareholder].lastTxOutDate);
        uint256 sliceCountsToClaim = diff.div(allowanceDuration);
        uint256 oneSliceAmount = shares[shareholder].amount.div(allowanceDivisor);
        uint256 toBeAddAllowance = oneSliceAmount.mul(sliceCountsToClaim);  //based on todays balance give all allowance amounts
        uint256 newTotalAllowance = shares[shareholder].allowance.add(toBeAddAllowance);
        uint256 newLastStartDate = shares[shareholder].lastTxOutDate.add(allowanceDuration.mul(sliceCountsToClaim));

        // console.log('- diff: %s', diff); // TODO : REMOVE
        // console.log('- sliceCountsToClaim: %s', sliceCountsToClaim); // TODO : REMOVE
        // console.log('- oneSliceAmount: %s', oneSliceAmount / 1000000000); // TODO : REMOVE
        // console.log('- toBeAddAllowance: %s', toBeAddAllowance / 1000000000); // TODO : REMOVE
        // console.log('- current allowance: %s', shares[shareholder].allowance / 1000000000); // TODO : REMOVE
        // console.log('- newTotalAllowance: %s', newTotalAllowance / 1000000000); // TODO : REMOVE
        // console.log('- newLastStartDate: %s', newLastStartDate); // TODO : REMOVE

        // If allowance is more than balance, set allowance to balance amount
        if(newTotalAllowance >= shares[shareholder].amount){
            newTotalAllowance = shares[shareholder].amount;
            // console.log('OVER MAX ALLOWANCE newAllowance: %s', newTotalAllowance / 1000000000); // TODO : REMOVE
        }

        //update values
        shares[shareholder].allowance = newTotalAllowance;
        shares[shareholder].lastTxOutDate = newLastStartDate;
        
        // console.log('after allowance: %s', shares[shareholder].allowance / 1000000000); // TODO : REMOVE
        // console.log('after lastTxOutDate: %s', shares[shareholder].lastTxOutDate); // TODO : REMOVE
        // console.log('updateAllowance() end ------------------------------------------------------'); // TODO : REMOVE
    }
 
}

