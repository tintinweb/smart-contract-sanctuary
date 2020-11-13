// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

interface iERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface iBASE {
    function secondsPerEra() external view returns (uint);
    // function DAO() external view returns (iDAO);
}
interface iUTILS {
    function calcPart(uint bp, uint total) external pure returns (uint part);
    function calcShare(uint part, uint total, uint amount) external pure returns (uint share);
    function calcSwapOutput(uint x, uint X, uint Y) external pure returns (uint output);
    function calcSwapFee(uint x, uint X, uint Y) external pure returns (uint output);
    function calcStakeUnits(uint a, uint A, uint v, uint S) external pure returns (uint units);
    // function calcAsymmetricShare(uint s, uint T, uint A) external pure returns (uint share);
    // function getPoolAge(address token) external view returns(uint age);
    function getPoolShare(address token, uint units) external view returns(uint baseAmt, uint tokenAmt);
    function getPoolShareAssym(address token, uint units, bool toBase) external view returns(uint baseAmt, uint tokenAmt, uint outputAmt);
    function calcValueInBase(address token, uint amount) external view returns (uint value);
    function calcValueInToken(address token, uint amount) external view returns (uint value);
    function calcValueInBaseWithPool(address payable pool, uint amount) external view returns (uint value);
}
interface iDAO {
    function ROUTER() external view returns(address);
    function UTILS() external view returns(iUTILS);
    function FUNDS_CAP() external view returns(uint);
}

// SafeMath
library SafeMath {

    function add(uint a, uint b) internal pure returns (uint)   {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Pool_Vether is iERC20 {
    using SafeMath for uint;

    address public BASE;
    address public TOKEN;
    iDAO public DAO;

    uint public one = 10**18;

    // ERC-20 Parameters
    string _name; string _symbol;
    uint public override decimals; uint public override totalSupply;
    // ERC-20 Mappings
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    uint public genesis;
    uint public baseAmt;
    uint public tokenAmt;
    uint public baseAmtStaked;
    uint public tokenAmtStaked;
    uint public fees;
    uint public volume;
    uint public txCount;
    
    // Only Router can execute
    modifier onlyRouter() {
        _isRouter();
        _;
    }

    function _isRouter() internal view {
        require(msg.sender == _DAO().ROUTER(), "RouterErr");
    }

    function _DAO() internal view returns(iDAO) {
        return DAO;
    }

    constructor (address _base, address _token, iDAO _dao) public payable {

        BASE = _base;
        TOKEN = _token;
        DAO = _dao;

        string memory poolName = "VetherPoolV1-";
        string memory poolSymbol = "VPT1-";

        if(_token == address(0)){
            _name = string(abi.encodePacked(poolName, "Ethereum"));
            _symbol = string(abi.encodePacked(poolSymbol, "ETH"));
        } else {
            _name = string(abi.encodePacked(poolName, iERC20(_token).name()));
            _symbol = string(abi.encodePacked(poolSymbol, iERC20(_token).symbol()));
        }
        
        decimals = 18;
        genesis = now;
    }

    function _checkApprovals() external onlyRouter{
        if(iERC20(BASE).allowance(address(this), _DAO().ROUTER()) == 0){
            if(TOKEN != address(0)){
                iERC20(TOKEN).approve(_DAO().ROUTER(), (2**256)-1);
            }
        iERC20(BASE).approve(_DAO().ROUTER(), (2**256)-1);
        }
    }

    receive() external payable {}

    //========================================iERC20=========================================//
    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    // iERC20 Transfer function
    function transfer(address to, uint value) public override returns (bool success) {
        __transfer(msg.sender, to, value);
        return true;
    }
    // iERC20 Approve function
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        __approve(msg.sender, spender, amount);
        return true;
    }
    function __approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    // iERC20 TransferFrom function
    function transferFrom(address from, address to, uint value) public override returns (bool success) {
        require(value <= _allowances[from][msg.sender], 'AllowanceErr');
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        __transfer(from, to, value);
        return true;
    }

    // Internal transfer function
    function __transfer(address _from, address _to, uint _value) private {
        require(_balances[_from] >= _value, 'BalanceErr');
        require(_balances[_to] + _value >= _balances[_to], 'BalanceErr');
        _balances[_from] =_balances[_from].sub(_value);
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Router can mint
    function _mint(address account, uint256 amount) external onlyRouter {
        totalSupply = totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _allowances[account][DAO.ROUTER()] += amount;
        emit Transfer(address(0), account, amount);
    }
    // Burn supply
    function burn(uint256 amount) public virtual {
        __burn(msg.sender, amount);
    }
    function burnFrom(address from, uint256 value) public virtual {
        require(value <= _allowances[from][msg.sender], 'AllowanceErr');
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        __burn(from, value);
    }
    function __burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount, "BalanceErr");
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    //==================================================================================//
    // Extended Asset Functions

    // TransferTo function
    function transferTo(address recipient, uint256 amount) public returns (bool) {
        __transfer(tx.origin, recipient, amount);
        return true;
    }

    // ETH Transfer function
    function transferETH(address payable to, uint value) public payable onlyRouter returns (bool success) {
        to.call{value:value}(""); 
        return true;
    }

    function sync() public {
        if (TOKEN == address(0)) {
            tokenAmt = address(this).balance;
        } else {
            tokenAmt = iERC20(TOKEN).balanceOf(address(this));
        }
    }

    function add(address token, uint amount) public payable returns (bool success) {
        if(token == BASE){
            iERC20(BASE).transferFrom(msg.sender, address(this), amount);
            baseAmt = baseAmt.add(amount);
            return true;
        } else if (token == TOKEN){
            iERC20(TOKEN).transferFrom(msg.sender, address(this), amount);
            tokenAmt = tokenAmt.add(amount); 
            return true;
        } else if (token == address(0)){
            require((amount == msg.value), "InputErr");
            tokenAmt = tokenAmt.add(amount); 
        } else {
            return false;
        }
    } 

    //==================================================================================//
    // Data Model
    function _incrementPoolBalances(uint _baseAmt, uint _tokenAmt)  external onlyRouter  {
        baseAmt += _baseAmt;
        tokenAmt += _tokenAmt;
        baseAmtStaked += _baseAmt;
        tokenAmtStaked += _tokenAmt; 
    }
    function _setPoolBalances(uint _baseAmt, uint _tokenAmt, uint _baseAmtStaked, uint _tokenAmtStaked)  external onlyRouter  {
        baseAmtStaked = _baseAmtStaked;
        tokenAmtStaked = _tokenAmtStaked; 
        __setPool(_baseAmt, _tokenAmt);
    }
    function _setPoolAmounts(uint _baseAmt, uint _tokenAmt)  external onlyRouter  {
        __setPool(_baseAmt, _tokenAmt); 
    }
    function __setPool(uint _baseAmt, uint _tokenAmt) internal  {
        baseAmt = _baseAmt;
        tokenAmt = _tokenAmt; 
    }

    function _decrementPoolBalances(uint _baseAmt, uint _tokenAmt)  external onlyRouter  {
        uint _unstakedBase = _DAO().UTILS().calcShare(_baseAmt, baseAmt, baseAmtStaked);
        uint _unstakedToken = _DAO().UTILS().calcShare(_tokenAmt, tokenAmt, tokenAmtStaked);
        baseAmtStaked = baseAmtStaked.sub(_unstakedBase);
        tokenAmtStaked = tokenAmtStaked.sub(_unstakedToken); 
        __decrementPool(_baseAmt, _tokenAmt); 
    }
 
    function __decrementPool(uint _baseAmt, uint _tokenAmt) internal  {
        baseAmt = baseAmt.sub(_baseAmt);
        tokenAmt = tokenAmt.sub(_tokenAmt); 
    }

    function _addPoolMetrics(uint _volume, uint _fee) external onlyRouter  {
        txCount += 1;
        volume += _volume;
        fees += _fee;
    }

}

contract Router_Vether {

    using SafeMath for uint;

    address public BASE;
    address public DEPLOYER;
    iDAO public DAO;

    // uint256 public currentEra;
    // uint256 public nextEraTime;
    // uint256 public reserve;

    uint public totalStaked; 
    uint public totalVolume;
    uint public totalFees;
    uint public unstakeTx;
    uint public stakeTx;
    uint public swapTx;

    address[] public arrayTokens;
    mapping(address=>address payable) private mapToken_Pool;
    mapping(address=>bool) public isPool;

    event NewPool(address token, address pool, uint genesis);
    event Staked(address member, uint inputBase, uint inputToken, uint unitsIssued);
    event Unstaked(address member, uint outputBase, uint outputToken, uint unitsClaimed);
    event Swapped(address tokenFrom, address tokenTo, uint inputAmount, uint transferAmount, uint outputAmount, uint fee, address recipient);
    // event NewEra(uint256 currentEra, uint256 nextEraTime, uint256 reserve);

// Only Deployer can execute
    modifier onlyDeployer() {
        require(msg.sender == DEPLOYER, "DeployerErr");
        _;
    }

    constructor () public payable {
        BASE = 0x4Ba6dDd7b89ed838FEd25d208D4f644106E34279;
        DEPLOYER = msg.sender;
    }

    receive() external payable {
        buyTo(msg.value, address(0), msg.sender);
    }

    function setGenesisDao(address dao) public onlyDeployer {
        DAO = iDAO(dao);
    }

    function _DAO() internal view returns(iDAO) {
        return DAO;
    }

    function migrateRouterData(address payable oldRouter) public onlyDeployer {
        totalStaked = Router_Vether(oldRouter).totalStaked();
        totalVolume = Router_Vether(oldRouter).totalVolume();
        totalFees = Router_Vether(oldRouter).totalFees();
        unstakeTx = Router_Vether(oldRouter).unstakeTx();
        stakeTx = Router_Vether(oldRouter).stakeTx();
        swapTx = Router_Vether(oldRouter).swapTx();
    }

    function migrateTokenData(address payable oldRouter) public onlyDeployer {
        uint tokenCount = Router_Vether(oldRouter).tokenCount();
        for(uint i = 0; i<tokenCount; i++){
            address token = Router_Vether(oldRouter).getToken(i);
            address payable pool = Router_Vether(oldRouter).getPool(token);
            isPool[pool] = true;
            arrayTokens.push(token);
            mapToken_Pool[token] = pool;
        }
    }

    function purgeDeployer() public onlyDeployer {
        DEPLOYER = address(0);
    }

    function createPool(uint inputBase, uint inputToken, address token) public payable returns(address payable pool){
        require(getPool(token) == address(0), "CreateErr");
        require(token != BASE, "Must not be Base");
        require((inputToken > 0 && inputBase > 0), "Must get tokens for both");
        Pool_Vether newPool = new Pool_Vether(BASE, token, DAO);
        pool = payable(address(newPool));
        uint _actualInputToken = _handleTransferIn(token, inputToken, pool);
        uint _actualInputBase = _handleTransferIn(BASE, inputBase, pool);
        mapToken_Pool[token] = pool;
        arrayTokens.push(token);
        isPool[pool] = true;
        totalStaked += _actualInputBase;
        stakeTx += 1;
        uint units = _handleStake(pool, _actualInputBase, _actualInputToken, msg.sender);
        emit NewPool(token, pool, now);
        emit Staked(msg.sender, _actualInputBase, _actualInputToken, units);
        return pool;
    }

    //==================================================================================//
    // Staking functions

    function stake(uint inputBase, uint inputToken, address token) public payable returns (uint units) {
        units = stakeForMember(inputBase, inputToken, token, msg.sender);
        return units;
    }

    function stakeForMember(uint inputBase, uint inputToken, address token, address member) public payable returns (uint units) {
        address payable pool = getPool(token);
        uint _actualInputToken = _handleTransferIn(token, inputToken, pool);
        uint _actualInputBase = _handleTransferIn(BASE, inputBase, pool);
        totalStaked += _actualInputBase;
        stakeTx += 1;
        require(totalStaked <= DAO.FUNDS_CAP(), "Must be less than Funds Cap");
        units = _handleStake(pool, _actualInputBase, _actualInputToken, member);
        emit Staked(member, _actualInputBase, _actualInputToken, units);
        return units;
    }


    function _handleStake(address payable pool, uint _baseAmt, uint _tokenAmt, address _member) internal returns (uint _units) {
        Pool_Vether(pool)._checkApprovals();
        uint _S = Pool_Vether(pool).baseAmt().add(_baseAmt);
        uint _A = Pool_Vether(pool).tokenAmt().add(_tokenAmt);
        Pool_Vether(pool)._incrementPoolBalances(_baseAmt, _tokenAmt);                                                  
        _units = _DAO().UTILS().calcStakeUnits(_tokenAmt, _A, _baseAmt, _S);  
        Pool_Vether(pool)._mint(_member, _units);
        return _units;
    }

    //==================================================================================//
    // Unstaking functions

    // Unstake % for self
    function unstake(uint basisPoints, address token) public returns (bool success) {
        require((basisPoints > 0 && basisPoints <= 10000), "InputErr");
        uint _units = _DAO().UTILS().calcPart(basisPoints, iERC20(getPool(token)).balanceOf(msg.sender));
        unstakeExact(_units, token);
        return true;
    }

    // Unstake an exact qty of units
    function unstakeExact(uint units, address token) public returns (bool success) {
        address payable pool = getPool(token);
        address payable member = msg.sender;
        (uint _outputBase, uint _outputToken) = _DAO().UTILS().getPoolShare(token, units);
        totalStaked = totalStaked.sub(_outputBase);
        unstakeTx += 1;
        _handleUnstake(pool, units, _outputBase, _outputToken, member);
        emit Unstaked(member, _outputBase, _outputToken, units);
        _handleTransferOut(token, _outputToken, pool, member);
        _handleTransferOut(BASE, _outputBase, pool, member);
        return true;
    }

    // // Unstake % Asymmetrically
    function unstakeAsymmetric(uint basisPoints, bool toBase, address token) public returns (uint outputAmount){
        uint _units = _DAO().UTILS().calcPart(basisPoints, iERC20(getPool(token)).balanceOf(msg.sender));
        outputAmount = unstakeExactAsymmetric(_units, toBase, token);
        return outputAmount;
    }
    // Unstake Exact Asymmetrically
    function unstakeExactAsymmetric(uint units, bool toBase, address token) public returns (uint outputAmount){
        address payable pool = getPool(token);
        require(units < iERC20(pool).totalSupply(), "InputErr");
        (uint _outputBase, uint _outputToken, uint _outputAmount) = _DAO().UTILS().getPoolShareAssym(token, units, toBase);
        totalStaked = totalStaked.sub(_outputBase);
        unstakeTx += 1;
        _handleUnstake(pool, units, _outputBase, _outputToken, msg.sender);
        emit Unstaked(msg.sender, _outputBase, _outputToken, units);
        _handleTransferOut(token, _outputToken, pool, msg.sender);
        _handleTransferOut(BASE, _outputBase, pool, msg.sender);
        return _outputAmount;
    }

    function _handleUnstake(address payable pool, uint _units, uint _outputBase, uint _outputToken, address _member) internal returns (bool success) {
        Pool_Vether(pool)._checkApprovals();
        Pool_Vether(pool)._decrementPoolBalances(_outputBase, _outputToken);
        Pool_Vether(pool).burnFrom(_member, _units);
        return true;
    } 

    //==================================================================================//
    // Universal Swapping Functions

    function buy(uint amount, address token) public payable returns (uint outputAmount, uint fee){
        (outputAmount, fee) = buyTo(amount, token, msg.sender);
        return (outputAmount, fee);
    }
    function buyTo(uint amount, address token, address payable member) public payable returns (uint outputAmount, uint fee) {
        address payable pool = getPool(token);
        Pool_Vether(pool)._checkApprovals();
        uint _actualAmount = _handleTransferIn(BASE, amount, pool);
        // uint _minusFee = _getFee(_actualAmount);
        (outputAmount, fee) = _swapBaseToToken(pool, _actualAmount);
        // addDividend(pool, outputAmount, fee);
        totalStaked += _actualAmount;
        totalVolume += _actualAmount;
        totalFees += _DAO().UTILS().calcValueInBase(token, fee);
        swapTx += 1;
        _handleTransferOut(token, outputAmount, pool, member);
        emit Swapped(BASE, token, _actualAmount, 0, outputAmount, fee, member);
        return (outputAmount, fee);
    }

    // function _getFee(uint amount) private view returns(uint){
    //     return amount
    // }

    function sell(uint amount, address token) public payable returns (uint outputAmount, uint fee){
        (outputAmount, fee) = sellTo(amount, token, msg.sender);
        return (outputAmount, fee);
    }
    function sellTo(uint amount, address token, address payable member) public payable returns (uint outputAmount, uint fee) {
        address payable pool = getPool(token);
        Pool_Vether(pool)._checkApprovals();
        uint _actualAmount = _handleTransferIn(token, amount, pool);
        (outputAmount, fee) = _swapTokenToBase(pool, _actualAmount);
        // addDividend(pool, outputAmount, fee);
        totalStaked = totalStaked.sub(outputAmount);
        totalVolume += outputAmount;
        totalFees += fee;
        swapTx += 1;
        _handleTransferOut(BASE, outputAmount, pool, member);
        emit Swapped(token, BASE, _actualAmount, 0, outputAmount, fee, member);
        return (outputAmount, fee);
    }

    function swap(uint inputAmount, address fromToken, address toToken) public payable returns (uint outputAmount, uint fee) {
        require(fromToken != toToken, "InputErr");
        address payable poolFrom = getPool(fromToken); address payable poolTo = getPool(toToken);
        Pool_Vether(poolFrom)._checkApprovals();
        Pool_Vether(poolTo)._checkApprovals();
        uint _actualAmount = _handleTransferIn(fromToken, inputAmount, poolFrom);
        uint _transferAmount = 0;
        if(fromToken == BASE){
            (outputAmount, fee) = _swapBaseToToken(poolFrom, _actualAmount);      // Buy to token
            totalStaked += _actualAmount;
            totalVolume += _actualAmount;
            // addDividend(poolFrom, outputAmount, fee);
        } else if(toToken == BASE) {
            (outputAmount, fee) = _swapTokenToBase(poolFrom,_actualAmount);   // Sell to token
            totalStaked = totalStaked.sub(outputAmount);
            totalVolume += outputAmount;
            // addDividend(poolFrom, outputAmount, fee);
        } else {
            (uint _yy, uint _feey) = _swapTokenToBase(poolFrom, _actualAmount);             // Sell to BASE
            uint _actualYY = _handleTransferOver(BASE, poolFrom, poolTo, _yy);
            totalStaked = totalStaked.add(_actualYY).sub(_actualAmount);
            totalVolume += _yy; totalFees += _feey;
            // addDividend(poolFrom, _yy, _feey);
            (uint _zz, uint _feez) = _swapBaseToToken(poolTo, _actualYY);              // Buy to token
            totalFees += _DAO().UTILS().calcValueInBase(toToken, _feez);
            // addDividend(poolTo, _zz, _feez);
            _transferAmount = _actualYY; outputAmount = _zz; 
            fee = _feez + _DAO().UTILS().calcValueInToken(toToken, _feey);
        }
        swapTx += 1;
        _handleTransferOut(toToken, outputAmount, poolTo, msg.sender);
        emit Swapped(fromToken, toToken, _actualAmount, _transferAmount, outputAmount, fee, msg.sender);
        return (outputAmount, fee);
    }

    function _swapBaseToToken(address payable pool, uint _x) internal returns (uint _y, uint _fee){
        uint _X = Pool_Vether(pool).baseAmt();
        uint _Y = Pool_Vether(pool).tokenAmt();
        _y =  _DAO().UTILS().calcSwapOutput(_x, _X, _Y);
        _fee = _DAO().UTILS().calcSwapFee(_x, _X, _Y);
        Pool_Vether(pool)._setPoolAmounts(_X.add(_x), _Y.sub(_y));
        _updatePoolMetrics(pool, _y+_fee, _fee, false);
        // _checkEmission();
        return (_y, _fee);
    }

    function _swapTokenToBase(address payable pool, uint _x) internal returns (uint _y, uint _fee){
        uint _X = Pool_Vether(pool).tokenAmt();
        uint _Y = Pool_Vether(pool).baseAmt();
        _y =  _DAO().UTILS().calcSwapOutput(_x, _X, _Y);
        _fee = _DAO().UTILS().calcSwapFee(_x, _X, _Y);
        Pool_Vether(pool)._setPoolAmounts(_Y.sub(_y), _X.add(_x));
        _updatePoolMetrics(pool, _y+_fee, _fee, true);
        // _checkEmission();
        return (_y, _fee);
    }

    function _updatePoolMetrics(address payable pool, uint _txSize, uint _fee, bool _toBase) internal {
        if(_toBase){
            Pool_Vether(pool)._addPoolMetrics(_txSize, _fee);
        } else {
            uint _txBase = _DAO().UTILS().calcValueInBaseWithPool(pool, _txSize);
            uint _feeBase = _DAO().UTILS().calcValueInBaseWithPool(pool, _fee);
            Pool_Vether(pool)._addPoolMetrics(_txBase, _feeBase);
        }
    }


    //==================================================================================//
    // Revenue Functions

    // Every swap, calculate fee, add to reserve
    // Every era, send reserve to DAO

    // function _checkEmission() private {
    //     if (now >= nextEraTime) {                                                           // If new Era and allowed to emit
    //         currentEra += 1;                                                               // Increment Era
    //         nextEraTime = now + iBASE(BASE).secondsPerEra() + 100;                     // Set next Era time
    //         uint reserve = iERC20(BASE).balanceOf(address(this));
    //         iERC20(BASE).transfer(address(_DAO()), reserve);
    //         emit NewEra(currentEra, nextEraTime, reserve);                               // Emit Event
    //     }
    // }

    //==================================================================================//
    // Token Transfer Functions

    function _handleTransferIn(address _token, uint _amount, address _pool) internal returns(uint actual){
        if(_amount > 0) {
            if(_token == address(0)){
                require((_amount == msg.value), "InputErr");
                payable(_pool).call{value:_amount}(""); 
                actual = _amount;
            } else {
                uint startBal = iERC20(_token).balanceOf(_pool); 
                iERC20(_token).transferFrom(msg.sender, _pool, _amount); 
                actual = iERC20(_token).balanceOf(_pool).sub(startBal);
            }
        }
    }

    function _handleTransferOut(address _token, uint _amount, address _pool, address payable _recipient) internal {
        if(_amount > 0) {
            if (_token == address(0)) {
                Pool_Vether(payable(_pool)).transferETH(_recipient, _amount);
            } else {
                iERC20(_token).transferFrom(_pool, _recipient, _amount);
            }
        }
    }

    function _handleTransferOver(address _token, address _from, address _to, uint _amount) internal returns(uint actual){
        if(_amount > 0) {
            uint startBal = iERC20(_token).balanceOf(_to); 
            iERC20(_token).transferFrom(_from, _to, _amount); 
            actual = iERC20(_token).balanceOf(_to).sub(startBal);
        }
    }

    //======================================HELPERS========================================//
    // Helper Functions

    function getPool(address token) public view returns(address payable pool){
        return mapToken_Pool[token];
    }

    function tokenCount() public view returns(uint){
        return arrayTokens.length;
    }

    function getToken(uint i) public view returns(address){
        return arrayTokens[i];
    }

}