/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {

            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20 is Context, IBEP20 {

  address private _owner;

  function contractowner() public view virtual returns (address) {
      return _owner;
  }

  modifier onlyOwner() {
      require(contractowner() == _msgSender(), "Ownable: caller is not the owner");
      _;
  }
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bool public takeFee;
    bool whaleProtection = true;

    uint256 public _maxTxAmount = 500000000 * 10**9;

    address public _taxAddress;
    address public _charityAddress;
    address public _marketingAddress;
    address public FutureProjectsAddress;

    uint256 public _taxFee = 3;
    uint256 public _charityFee = 4;
    uint256 public _marketingFee = 2;
    uint256 public FutureProjectsFee = 2; // FutureProjectsFee 
    
    mapping (address => bool) private _isExcludedFromFee;

    event TaxFeeUpdated(uint256 lastFee, uint256 newFee);
    event MarketingFeeUpdated(uint256 lastFee, uint256 newFee);
    event FutureProjectsFeeUpdated(uint256 lastFee, uint256 newFee);
    event CharityFeeUpdated(uint256 lastFee, uint256 newFee);

    event TaxAddressUpdated(address oldAdd, address newAdd);
    event MarketingAddressUpdated(address oldAdd, address newAdd);
    event FutureProjectsAddressUpdated(address oldAdd, address newAdd);
    event CharityAddressUpdated(address oldAdd, address newAdd);

    event ExcludedFromFee(address userAddress);
    event IncludedInFee(address userAddress);

    event MaxTxAmountUpdated(uint256 lastAmount, uint256 newAmount);
    event RevokeLimits(bool txLimit);

    constructor(string memory name_, string memory symbol_, address taxAddress, address charityAddress, address marketingAddress, address _FutureProjectsAddress) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
        _taxAddress = taxAddress;
        _charityAddress = charityAddress;
        _marketingAddress = marketingAddress;
        FutureProjectsAddress = _FutureProjectsAddress;

        _isExcludedFromFee[contractowner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxAddress] = true;
        _isExcludedFromFee[_charityAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedFromFee[FutureProjectsAddress] = true;

        emit ExcludedFromFee(contractowner());
        emit ExcludedFromFee(address(this));
        emit ExcludedFromFee(_taxAddress);
        emit ExcludedFromFee(_charityAddress);
        emit ExcludedFromFee(_marketingAddress);
        emit ExcludedFromFee(FutureProjectsAddress);

        takeFee = true;

        address msgSender = _msgSender();
        _owner = msgSender;
    }


    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getOwner() public view override returns (address) {
        return contractowner();
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {

        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        FutureProjectsFeeTokenTransfer(sender, recipient, amount);

        if(whaleProtection && sender != contractowner() && recipient != contractowner()){
           require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 senderBalance = _balances[sender];

        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

        _balances[sender] = senderBalance.sub(amount);

        if(!_isExcludedFromFee[recipient] && takeFee ){

            uint256 tax_Fee = amount.mul(_taxFee).div(100);
            uint256 charity_Fee = amount.mul(_charityFee).div(100);
            uint256 marketing_Fee = amount.mul(_marketingFee).div(100);
            uint256 FutureProjects_Fee = amount.mul(FutureProjectsFee).div(100);

            uint256 totalFee = tax_Fee.add(charity_Fee).add(marketing_Fee).add(FutureProjects_Fee);

            _balances[recipient] = _balances[recipient].add(amount.sub(totalFee));
            _balances[_taxAddress] = _balances[_taxAddress].add(tax_Fee);
            _balances[_charityAddress] = _balances[_charityAddress].add(charity_Fee);
            _balances[_marketingAddress] = _balances[_marketingAddress].add(marketing_Fee);
            _balances[FutureProjectsAddress] = _balances[FutureProjectsAddress].add(FutureProjects_Fee);

             emit Transfer(sender, recipient, amount.sub(totalFee));
             emit Transfer(sender, _taxAddress, tax_Fee);
             emit Transfer(sender, _charityAddress, charity_Fee);
             emit Transfer(sender, _marketingAddress, marketing_Fee);
             emit Transfer(sender, FutureProjectsAddress, FutureProjects_Fee);
        }
        else{
             _balances[recipient] = _balances[recipient].add(amount);
             emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        FutureProjectsFeeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        FutureProjectsFeeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function FutureProjectsFeeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setMaxTxAmount(uint256 newAmount) external onlyOwner returns (bool){
        emit MaxTxAmountUpdated(_maxTxAmount, newAmount);
        _maxTxAmount = newAmount;
        return true;
    }

    function txLimitEnabled() external view returns (bool){
        return whaleProtection;
    }

    function RevokeLimit() external onlyOwner returns (bool){
        whaleProtection = false;
        emit RevokeLimits(true);
        return true;
    }

    function updateTaxFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _taxFee;
        _taxFee = newFee;
        emit TaxFeeUpdated(oldFee, _taxFee);
        return true;
    }

    function updateCharityFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _charityFee;
        _charityFee = newFee;
        emit CharityFeeUpdated(oldFee, _charityFee);
        return true;
    }

    function updateMarketingFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = _marketingFee;
        _marketingFee = newFee;
        emit MarketingFeeUpdated(oldFee, _marketingFee);
        return true;
    }

    function updateFutureProjectsFee(uint256 newFee) external onlyOwner returns(bool){
        uint256 oldFee = FutureProjectsFee;
        FutureProjectsFee = newFee;
        emit FutureProjectsFeeUpdated(oldFee, FutureProjectsFee);
        return true;
    }

    function updateTaxAddress(address newAdd) external onlyOwner returns(bool){
        address oldAdd = _taxAddress;
        _taxAddress = newAdd;
        _isExcludedFromFee[_taxAddress] = true;
        emit ExcludedFromFee(_taxAddress);
        emit TaxAddressUpdated(oldAdd, _taxAddress);
        return true;
    }

    function updateCharityAddress(address newAdd) external onlyOwner returns(bool){
        address oldAdd = _charityAddress;
        _charityAddress = newAdd;
        _isExcludedFromFee[_charityAddress] = true;
        emit ExcludedFromFee(_charityAddress);
        emit CharityAddressUpdated(oldAdd, _charityAddress);
        return true;
    }

    function updateMarketingAddress(address newAdd) external onlyOwner returns(bool){
        address  oldAdd = _marketingAddress;
        _marketingAddress = newAdd;
        _isExcludedFromFee[_marketingAddress] = true;
        emit ExcludedFromFee(_marketingAddress);
        emit MarketingAddressUpdated(oldAdd, _marketingAddress);
        return true;
    }

    function updateFutureProjectsAddress(address  newAdd) external onlyOwner returns(bool){
        address oldAdd = FutureProjectsAddress;
        FutureProjectsAddress = newAdd;
        _isExcludedFromFee[FutureProjectsAddress] = true;
        emit ExcludedFromFee(FutureProjectsAddress);
        emit FutureProjectsAddressUpdated(oldAdd, FutureProjectsAddress);
        return true;
    }

    function excludeFromFee(address userAddress) external onlyOwner returns(bool){
        _isExcludedFromFee[userAddress] = true;
        emit ExcludedFromFee(userAddress);
        return true;
    }

    function isExcludeFromFee(address userAddress) external view returns(bool){
        return _isExcludedFromFee[userAddress];
    }

    function includedInFee(address userAddress) external onlyOwner returns(bool){
        _isExcludedFromFee[userAddress] = false;
        emit IncludedInFee(userAddress);
        return true;
    }

    function toggleFee(bool _switch) external onlyOwner returns(bool){
        takeFee = _switch;
        return true;
    }

}


abstract contract BEP20Capped is BEP20 {

    using SafeMath for uint256;

    uint256 private _cap;

    constructor(uint256 cap_) {
        require(cap_ > 0, "BEP20Capped: cap is 0");
        _cap = cap_;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(totalSupply().add(amount) <= cap(), "BEP20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

abstract contract BEP20Mintable is BEP20 {

    // indicates if minting is finished
    bool private _mintingFinished = false;

    event MintFinished();

    modifier canMint() {
        require(!_mintingFinished, "BEP20Mintable: minting is finished");
        _;
    }

    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    function mint(address account, uint256 amount) public canMint {
        _mint(account, amount);
    }

    function finishMinting() public canMint {
        _finishMinting();
    }

    function _finishMinting() internal virtual {
        _mintingFinished = true;

        emit MintFinished();
    }
}

abstract contract BEP20Burnable is BEP20 {

    using SafeMath for uint256;

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "BEP20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance.sub(amount));
        _burn(account, amount);
    }
}

contract Meriti is BEP20Capped, BEP20Mintable, BEP20Burnable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 cap_,
        uint256 initialBalance_,
        address taxAddress,
        address charityAddress,
        address marketingAddress,
        address _FutureProjectsAddress
    ) BEP20(name_, symbol_, taxAddress, charityAddress, marketingAddress, _FutureProjectsAddress) BEP20Capped(cap_) {
        _setupDecimals(decimals_);
        _mint(_msgSender(), initialBalance_);
    }

    function _mint(address account, uint256 amount) internal override(BEP20, BEP20Capped) onlyOwner {
        super._mint(account, amount);
    }

    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }
}