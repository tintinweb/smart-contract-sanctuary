/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IBEP20 {

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Meriti is Context, IBEP20 {
    
    address private _owner;

    function contractowner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(contractowner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    using SafeMath for uint256;

    string private constant _name = "Meriti";
    string private constant _symbol = "MERIT";

    uint8 private constant _decimals = 9;
    
    uint256 public lockPeriod = 365 days;
    uint256 public _maxTxAmount = 500000000 * 10**9;
    
    mapping(address => uint256) public _rOwned;
    mapping(address => uint256) public _tOwned;
    mapping(address => uint256) public _lockedTime;

    mapping(address => mapping(address => uint256)) public _allowances;

    mapping(address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcluded;
    address[] private _excluded;

    event TaxFeeUpdated(uint256 lastFee, uint256 newFee);
    event MarketingFeeUpdated(uint256 lastFee, uint256 newFee);
    event FutureProjectsFeeUpdated(uint256 lastFee, uint256 newFee);
    event CharityFeeUpdated(uint256 lastFee, uint256 newFee);

    event ExcludedFromFee(address userAddress);
    event IncludedInFee(address userAddress);
    
    event MarketingAddressUpdated(address oldAdd, address newAdd);
    event FutureProjectsAddressUpdated(address oldAdd, address newAdd);
    event CharityAddressUpdated(address oldAdd, address newAdd);
    event MaxTxAmountUpdated(uint256 lastAmount, uint256 newAmount);
    
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 5*10**12*10**9;
    uint256 public _rTotal = (MAX.sub( (MAX.mod(_tTotal)))); 

    uint256 private _tFeeTotal;

    uint256 private _taxFee = 3;
    uint256 private _marketingFee = 2;
    uint256 private _futureProjectsFee = 1;
    uint256 private _charityFee = 3;

    address public _marketingAddress;
        address public _futureProjectsAddress;
            address public _charityAddress;

    constructor(address marketing, address futureProjects, address charity) {
        _marketingAddress = marketing;
        _futureProjectsAddress = futureProjects;
        _charityAddress = charity;
        
        address msgSender = _msgSender();
        _owner = msgSender;
        
        emit MarketingAddressUpdated(address(0), _marketingAddress);
        emit FutureProjectsAddressUpdated(address(0), _futureProjectsAddress);
        emit CharityAddressUpdated(address(0), _charityAddress);

        _rOwned[_msgSender()] = _tTotal.mul(_getRate());

        _isExcludedFromFee[contractowner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_futureProjectsAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        emit ExcludedFromFee(contractowner());
        emit ExcludedFromFee(address(this));
        emit ExcludedFromFee(_futureProjectsAddress);
        emit ExcludedFromFee(_marketingAddress);
        emit ExcludedFromFee(_charityAddress);

    }

    function excludeFromFee(address userAddress) external onlyOwner returns(bool){
        _isExcludedFromFee[userAddress] = true;
        emit ExcludedFromFee(userAddress);
        return true;
    }

    function includedInFee(address userAddress) external onlyOwner returns(bool){
        _isExcludedFromFee[userAddress] = false;
        emit IncludedInFee(userAddress);
        return true;
    }

    function updateTaxFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _taxFee;
        _taxFee = newFee;
        emit TaxFeeUpdated(oldFee, _taxFee);
        return true;
    }

    function updateMarketingFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _marketingFee;
        _marketingFee = newFee;
        emit MarketingFeeUpdated(oldFee, _marketingFee);
        return true;
    }

    function updateFutureProjectsFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _futureProjectsFee;
        _futureProjectsFee = newFee;
        emit FutureProjectsFeeUpdated(oldFee, _futureProjectsFee);
        return true;
    }

    function updateCharityFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _charityFee;
        _charityFee = newFee;
        emit CharityFeeUpdated(oldFee, _charityFee);
        return true;
    }

    function updateMarketingAddress(address newAdd) external onlyOwner returns(bool){
        address oldAdd = _marketingAddress;
        _marketingAddress = newAdd;
        emit MarketingAddressUpdated(oldAdd, _marketingAddress);
        return true;
    }

    function updateFutureProjectsAddress(address  newAdd) external onlyOwner returns(bool){
        address oldAdd = _futureProjectsAddress;
        _futureProjectsAddress = newAdd;
        emit FutureProjectsAddressUpdated(oldAdd, _futureProjectsAddress);
        return true;
    }

    function updateCharityAddress(address newAdd) external onlyOwner returns(bool){
        address oldAdd = _charityAddress;
        _charityAddress = newAdd;
        emit CharityAddressUpdated(oldAdd, _charityAddress);
        return true;
    }

    function getAllFee() external view returns(uint256, uint256, uint256, uint256){
        return (_taxFee, _charityFee, _marketingFee, _futureProjectsFee );
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromReward(address account) public onlyOwner() {

        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rAmount)
        private
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

    function removeAllFee() private {
        if (_taxFee == 0 && _charityFee == 0 && _futureProjectsFee == 0 && _marketingFee == 0) return;
        _taxFee = 0;
        _charityFee = 0;
        _marketingFee = 0;
        _futureProjectsFee = 0;
    }

    function restoreAllFee(uint256 tax, uint256 charity, uint256 marketing, uint256 futureProjects) private {
        _taxFee = tax;
        _charityFee = charity;
        _marketingFee = marketing;
        _futureProjectsFee = futureProjects;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(_lockedTime[from] > 0){
            require(block.timestamp >= _lockedTime[from].add(lockPeriod), "Wait for Presale Lockup");
        }
        
        if(from != contractowner() && to != contractowner()){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }
        
        bool takeFee = true;

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 tax = _taxFee;
        uint256 charity =  _charityFee;
        uint256 marketing = _marketingFee;
        uint256 futureProjects = _futureProjectsFee;

        if (!takeFee) removeAllFee();

      

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

        if (!takeFee) restoreAllFee(tax, charity, marketing, futureProjects);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {

        (
            uint256 tFee,
            uint256 tCharity,
            uint256 tMarketing,
            uint256 tFutureProjects,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tCharity, tMarketing, tFutureProjects);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeCharity(tCharity);
        _takeMarketing(tMarketing);
        _takeFutureProjects(tFutureProjects);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
         (
            uint256 tFee,
            uint256 tCharity,
            uint256 tMarketing,
            uint256 tFutureProjects,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tCharity, tMarketing, tFutureProjects);


        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeCharity(tCharity);
        _takeMarketing(tMarketing);
        _takeFutureProjects(tFutureProjects);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
         (
            uint256 tFee,
            uint256 tCharity,
            uint256 tMarketing,
            uint256 tFutureProjects,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tCharity, tMarketing, tFutureProjects);


        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeCharity(tCharity);
        _takeMarketing(tMarketing);
        _takeFutureProjects(tFutureProjects);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 tFee,
            uint256 tCharity,
            uint256 tMarketing,
            uint256 tFutureProjects,
            uint256 tTransferAmount
        ) = _getTValues(tAmount);

        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee
        ) = _getRValues(tAmount, tFee, tCharity, tMarketing, tFutureProjects);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeCharity(tCharity);
        _takeMarketing(tMarketing);
        _takeFutureProjects(tFutureProjects);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
        
    function presaleTokenTransfer(address recipient, uint256 amount) public onlyOwner returns (bool) {

        require(recipient != address(0), "BEP20: transfer to the zero address");

        _lockedTime[recipient] = block.timestamp;
        
        _tokenTransfer(_msgSender(), recipient, amount, false);
    
        return true;
    }
    
    function setMaxTxAmount(uint256 newAmount) external onlyOwner returns (bool){
        emit MaxTxAmountUpdated(_maxTxAmount, newAmount);
        _maxTxAmount = newAmount;
        return true;
    }
    
    function updateLockPeriod(uint256 newPeriod) external onlyOwner returns(bool){
        lockPeriod = newPeriod;
        return true;
    }

    function manualLockUpdate(address recipient, uint256 newPeriod) external onlyOwner returns(bool){
        _lockedTime[recipient] = newPeriod;
        return true;
    }
    
    function _takeCharity(uint256 tCharity) private {
        uint256 currentRate = _getRate();
        uint256 rCharity = tCharity.mul(currentRate);
        _rOwned[_charityAddress] = _rOwned[_charityAddress].add(rCharity);
    }

    function _takeMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[_marketingAddress] = _rOwned[_marketingAddress].add(rMarketing);
    }

    function _takeFutureProjects(uint256 tFutureProjects) private {
        uint256 currentRate = _getRate();
        uint256 rFutureProjects = tFutureProjects.mul(currentRate);
        _rOwned[_futureProjectsAddress] = _rOwned[_futureProjectsAddress].add(rFutureProjects);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getTValues(
        uint256 tAmount
    )
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
        uint256 tFee = tAmount.mul(_taxFee).div(100);
        uint256 tCharity = tAmount.mul(_charityFee).div(100);
        uint256 tMarketing = tAmount.mul(_marketingFee).div(100);
        uint256 tFutureProjects = tAmount.mul(_futureProjectsFee).div(100);
        uint256 tTotalFees = tFee.add(tCharity).add(tMarketing).add(tFutureProjects);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        return (tFee, tCharity, tMarketing, tFutureProjects, tTransferAmount);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tCharity,
        uint256 tMarketing,
        uint256 tFutureProjects
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rCharity = tCharity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rFutureProjects = tFutureProjects.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rCharity).sub(rMarketing).sub(rFutureProjects);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

}