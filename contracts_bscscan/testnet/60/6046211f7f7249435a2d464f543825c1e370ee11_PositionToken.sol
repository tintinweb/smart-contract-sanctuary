pragma solidity ^0.8.0;

import "Context.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "Address.sol";
import "Ownable.sol";

contract PositionToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _addressLevel;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    bool private _isRegisterAirdropDistribution;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name = 'Position';
    string private _symbol = 'POSI';
    uint8 private _decimals = 18;

    uint256 public genesisReward;
    uint256 public constant AIRDROP_AMOUNT = 10**6*10**18; //1,000,000
    uint256 public constant WHITELIST_SALE_AMOUNT = 5*10**6*10**18; //5,000,000
    uint256 public aidropDistributed;
    uint256 public whitelistSaleDistributed;
    // bot keeper helps watch the price drop then pause the transfer function
    address public botKeeper;
    address public whitelistSaleContract;
    address public positionStakingManager;
    address public insuranceFund;

    bool public isTransferPaused;
    uint16 public transferTaxRate = 100;

    event Donate(address indexed sender, uint256 indexed amount);
    event GenesisRewardChanged(uint256 indexed previousAmount, uint256 indexed newAmount);
    event BotKeeperChanged(address indexed previousKeeper, address indexed newKeeper);
    event TransferStatusChanged(bool indexed isPaused);

    constructor () public {
        address sender = _msgSender();
        uint256 amount =  5 * 10**6 * 10**18;
        _tTotal = amount;
        uint256 _max = MAX.div(1e36);
        _rTotal = ((_max - (_max % _tTotal)));
        _rOwned[sender] =  _rTotal;
        emit Transfer(address(0), sender, amount);
        _registerWhitelistSaleDistribution();
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

    function isGenesisAddress(address account) public view returns (bool) {
        return _addressLevel[account] == 0;
    }

    function genesisBalance(address account) public view returns (uint256) {
        if(isGenesisAddress(account)) return genesisReward;
        return 0;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]).add(genesisBalance(account));
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function mint(uint amount) public {
        require(msg.sender == positionStakingManager || msg.sender == insuranceFund, "not authorized");
        _mint(amount);
    }

    function burn(uint amount) public {
        _burn(amount);
    }

    function notifyGenesisAddresses(address[] memory _receivers, uint _value) public {
        for(uint i = 0; i < _receivers.length; i++){
            emit Transfer(address(0), _receivers[i], _value);
        }
    }

    function distributeWhitelistSale(address _receiver, uint _value) public {
        // only owner and whitelistsale contract can call
        require(msg.sender == owner() || msg.sender == whitelistSaleContract, "not authorized");
        whitelistSaleDistributed = whitelistSaleDistributed.add(_value);
        require(whitelistSaleDistributed <= WHITELIST_SALE_AMOUNT, "exceeds max");
        _rOwned[_receiver] =  _rOwned[_receiver].add(_value.mul(_getRate()));
        emit Transfer(address(0), _receiver, _value);
    }

    function distributeAirdrop(address[] memory _receivers, uint _value) public onlyOwner {
        require(_isRegisterAirdropDistribution, "not registered ");
        aidropDistributed = aidropDistributed.add(_receivers.length.mul(_value));
        require(aidropDistributed <= AIRDROP_AMOUNT, "exceeds max");
        uint256 _currentRate = _getRate();
        for(uint i = 0; i < _receivers.length; i++){
            _rOwned[_receivers[i]] =  _rOwned[_receivers[i]].add(_value.mul(_currentRate));
            emit Transfer(address(0), _receivers[i], _value);
        }
    }

    // increase total supply by the airdrop amount
    function registerAirdropDistribution() public onlyOwner {
        require(!_isRegisterAirdropDistribution, "Already registered");
        uint256 _currentRate = _getRate();
        _tTotal = _tTotal.add(AIRDROP_AMOUNT);
        // rTotal should increase as well
        _rTotal = _currentRate.mul(_tTotal);
        _isRegisterAirdropDistribution = true;
    }

    function setGenesisReward(uint256 _amount) public onlyOwner {
        // Genesis reward cannot be greater than 1e-11% (0.00000000001) of the total supply
        require(_amount <= totalSupply().div(1e11), "set genesis reward: bad");
        emit GenesisRewardChanged(genesisReward, _amount);
        genesisReward = _amount;
    }

    function setBotKeeper(address _newKeeper) public onlyOwner {
        emit BotKeeperChanged(botKeeper, _newKeeper);
        botKeeper = _newKeeper;
    }

    function setWhitelistSaleContract(address _newAddress) public onlyOwner {
        whitelistSaleContract = _newAddress;
    }

    function setPositionStakingManager(address _newAddress) public onlyOwner {
        positionStakingManager = _newAddress;
    }

    function setInsuranceFund(address _newAddress) public onlyOwner {
        insuranceFund = _newAddress;
    }



    function setTransferStatus(bool _isPaused) public {
        require(msg.sender == botKeeper, "Caller is not bot keeper");
        isTransferPaused = _isPaused;
        emit TransferStatusChanged(_isPaused);
    }

    // Donate to all holders
    function donate(uint256 amount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(amount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(amount);
        emit Donate(sender, amount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(uint amount) private {
        address sender = _msgSender();
        uint256 _currentRate = _getRate();
        _tTotal = _tTotal.add(amount);
        // rTotal should increase as well
        _rTotal = _currentRate.mul(_tTotal);
        uint256 _newRate = _getRate();
        _rOwned[sender] =  _rOwned[sender].add(amount.mul(_newRate));
        emit Transfer(address(0), sender, amount);
    }

    function _burn(uint amount) private {
        address sender = _msgSender();
        uint256 _currentRate = _getRate();
        _tTotal = _tTotal.sub(amount);
        // rTotal should increase as well
        _rTotal = _currentRate.mul(_tTotal);
        uint256 _newRate = _getRate();
        _rOwned[sender] =  _rOwned[sender].sub(amount.mul(_newRate));
        emit Transfer(sender, address(0), amount);

    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isTransferPaused, "Transfer is paused");
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 _bonusAmount;
        if(isGenesisAddress(recipient)){
            _bonusAmount = genesisReward.mul(_getRate());
            _upgradeAddressLevel(recipient);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount.add(_bonusAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        uint256 _bonusAmount;
        if(isGenesisAddress(recipient)){
            _bonusAmount = genesisReward.mul(_getRate());
            _upgradeAddressLevel(recipient);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount.add(_bonusAmount));
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _registerWhitelistSaleDistribution() private {
        uint256 _currentRate = _getRate();
        _tTotal = _tTotal.add(WHITELIST_SALE_AMOUNT);
        // rTotal should increase as well
        _rTotal = _currentRate.mul(_tTotal);
    }

    function _upgradeAddressLevel(address _account) private {
        _addressLevel[_account] = 1;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
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
}