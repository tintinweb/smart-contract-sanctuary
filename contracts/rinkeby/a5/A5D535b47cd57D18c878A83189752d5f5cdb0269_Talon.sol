/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.8.0 <0.9.0;

//Use 0.8.3

library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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

    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);

}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);


}

contract Talon is IERC20, Context {
    using SafeMath for uint256;
    //using Address for address;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;



    uint256 private _totalSupply;

    string private _name = 'Talon';
    string private _symbol = 'TALON';
    uint8 private _decimals = 18;
    
    uint256 public _burnFee = 1; // 1% fee
    uint256 public _donationFee = 1;
    uint256 public _devFee = 1;
    
    uint256 private _previousBurnFee = 0;
    uint256 private _previousDonationFee = 0;
    uint256 private _previousDevFee = 0;
    
    address public _burnAddress = 0x4bB48A8C1D8eFeE68213F0Aa877DdDa3f32B493d;
    address private _tgeAddress;
    address public _holdingAddress = 0xa3ad767D3832109D7ca7e1baF0be95D29dB328E8;
    address public _donationAddress = 0x271eec17Efe6D377ec2026460E42A11D868ed249;
    address public _devAddress = 0xe15F35B04f416489CEB4F735C96EeBC2F07d0850;
    
    address[] private _excludedFromFees;
    uint256 public _centsRaisedFromTGE;
    
    address[] private _archimedesList;
    address[] private _sorenList;
    address[] private _buboList;
    
    mapping (address => bool) private bots;
    
    address public _admin;
    bool public _tgeComplete = false;
    
    
    bool public _blockArchimedes = true;
    bool public _blockSoren = true;
    bool public _blockBubo = true;
    
    IUniswapV2Router02 public immutable _uniswapRouter;
    address public _ethPair;
    

    constructor () public {

        uint256 initialSupply = 4000000000000000* 10**18;

        _mint(_holdingAddress,initialSupply); //4 quad

        _admin = _msgSender();
        
        //Exclude holding account and burn wallet from reflection
        
        
        _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        
        emit Transfer(address(0), _holdingAddress, initialSupply);
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override   returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override    returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual  returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual   returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _approve(address owner, address spender, uint256 amount) private postTGE() {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        if(_blockArchimedes) {
            require(!isArchimedes(owner), "Archimedes cannot approve yet");
        }
        if(_blockSoren) {
            require(!isSoren(owner), "Soren cannot approve yet");
        }
        if(_blockBubo) {
            require(!isBubo(owner), "Bubo cannot approve yet");
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private postTGE(){
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[sender] && !bots[recipient]);
        if(_blockArchimedes) {
            require(!isArchimedes(sender), "Archimedes cannot transfer yet");
        }
        if(_blockSoren) {
            require(!isSoren(sender), "Soren cannot transfer yet");
        }
        if(_blockBubo) {
            require(!isBubo(sender), "Bubo cannot transfer yet");
        }
        
        
        bool recipientExcludedFromFees = isExcludedFromFees(recipient);
        if(recipientExcludedFromFees){
            removeAllFee();
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 burnAmount = amount / 100 * _burnFee;
        uint256 donationAmount = amount / 100 * _donationFee;
        uint256 devAmount = amount / 100 * _devFee;

        _balances[_burnAddress] += burnAmount;
        _balances[_donationAddress] += donationAmount;
        _balances[_devAddress] += devAmount;

        _balances[recipient] += (amount - burnAmount - donationAmount - devAmount);

        emit Transfer(sender, recipient, amount);
        if(recipientExcludedFromFees) {
            restoreAllFee();
        }
        
    }


    

    
        function handleInvestment(address investor, uint256 tokens, uint256 centsRaised, bool isArchimedes, bool isSoren, bool isbubo) public returns(bool){
        require(_tgeAddress == _msgSender(), "Only the TGE contract can initiate investments");
        require(!_tgeComplete, "TGE is already over");
        if(isArchimedes){
            _archimedesList.push(investor);
        } else if(isSoren) {
            _sorenList.push(investor);
        } else {
            _buboList.push(investor);
        }
        _balances[_holdingAddress] -= tokens;
        _balances[investor] += tokens;
        _centsRaisedFromTGE = centsRaised;
        emit Transfer(_holdingAddress, investor, tokens);
        return true;
    }
    
    
    function isExcludedFromFees(address user) public view returns (bool) {
        for(uint256 i = 0; i < _excludedFromFees.length; i++){
            if(_excludedFromFees[i] == user) {
                return true;
            }
        }
        return false;
    }
    
    function excludeFromFees(address newUser) public onlyAdmin(){
        require(!isExcludedFromFees(newUser), "Account is already excluded from fees.");
        _excludedFromFees.push(newUser);
    }
    
    function removeFromExcludeFromFees(address account) external onlyAdmin() {
        require(isExcludedFromFees(account), "Account isn't excluded");
        for (uint256 i = 0; i < _excludedFromFees.length; i++) {
            if (_excludedFromFees[i] == account) {
                _excludedFromFees[i] = _excludedFromFees[_excludedFromFees.length - 1];
                _excludedFromFees.pop();
                break;
            }
        }
    }
    
    function isArchimedes(address personToCheck) private view returns (bool) {
        for(uint256 i = 0; i < _archimedesList.length; i++){
            if(_archimedesList[i] == personToCheck) {
                return true;
            }
        }
        return false;
    }
    
    function isBubo(address personToCheck) private view returns (bool) {
        for(uint256 i = 0; i < _buboList.length; i++){
            if(_buboList[i] == personToCheck) {
                return true;
            }
        }
        return false;
    }

    function isSoren(address personToCheck) private view returns (bool) {
        for(uint256 i = 0; i < _sorenList.length; i++){
            if(_sorenList[i] == personToCheck) {
                return true;
            }
        }
        return false;
    }


    function unblockArchimedes() public onlyAdmin() {
        _blockArchimedes = false;
    }

    function unblockSoren() public onlyAdmin() {
        _blockSoren = false;
    }

    function unblockBubo() public onlyAdmin() {
        _blockBubo = false;
    }
    
    function removeAllFee() private {
        if(_burnFee == 0 && _donationFee ==0 && _donationFee == 0) return;
        
        _previousBurnFee = _burnFee;
        _previousDonationFee = _donationFee;
        _previousDevFee = _devFee;
        
        _burnFee = 0;
        _donationFee = 0;
        _devFee = 0;
    }
    
    function restoreAllFee() private {
        _burnFee = _previousBurnFee;
        _donationFee = _previousDonationFee;
        _devFee = _previousDevFee;
    }
    
    function setDonationFee(uint256 newFee) public onlyAdmin() preTGE() {
        _donationFee = newFee;
    }
    
    function setBurnFee(uint256 newFee) public onlyAdmin() preTGE(){
        _burnFee = newFee;
    }
    
    function setDevFee(uint256 newFee) public onlyAdmin() preTGE(){
        _devFee = newFee;
    }
    

    
    function setTGEAddress(address newTGE) public onlyAdmin() {
        _tgeAddress = newTGE;
    }
    
    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Caller is not the admin");
        _;
    }
    
    modifier postTGE() {
        require(_tgeComplete || (_msgSender() == _admin) , "The TGE is not complete");
        _;
    }

    modifier preTGE() {
        require(!_tgeComplete , "The TGE is already over");
        _;
    }
    
    
    
    function completeTGE(uint256 tokenAmount) public payable onlyAdmin() preTGE() {
        
        
        //Burn anything over 70% of the total supply after TGE
        uint256 targetAmount = totalSupply() / 10 * 7;
        if(balanceOf(_holdingAddress) > targetAmount) {
            //_transfer(_holdingAddress, _burnAddress, balanceOf(_holdingAddress) - targetAmount);
            uint256 difference = balanceOf(_holdingAddress) - targetAmount;

            _balances[_holdingAddress] -= difference;
            _balances[_burnAddress] += difference;
        }
        _tgeComplete = true;
        
        //createPair
        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapRouter.factory());
        _ethPair = factory.createPair(address(this),_uniswapRouter.WETH());
        
        //Transfer to this contract to be ready to add liquidity
        _balances[_holdingAddress] -= tokenAmount;
        _balances[address(this)] += tokenAmount;
        
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH{value: msg.value}(address(this),tokenAmount,0,0,_msgSender(),block.timestamp);

        
        
        
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    
    function setBots(address[] memory bots_) public onlyAdmin {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyAdmin {
        bots[notbot] = false;
    }
    
    function changeAdmin(address newAdmin) public onlyAdmin() {
        _admin = newAdmin;
    }
    
    
    
}