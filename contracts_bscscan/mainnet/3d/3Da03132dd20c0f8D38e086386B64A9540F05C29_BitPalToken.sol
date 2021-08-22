/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

// Website : https://www.Bitpalwallet.com
// Telegram : https://t.me/BitPalofficial
// Twitter : https://twitter.com/BitPalOfficial

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}


contract BitPalToken {
    using SafeMath for uint256;

    enum _set_options{ sale,airdrop,referEth,referToken,airdropEth,airdropToken,salePrice }
    uint256 private _totalSupply = 500000000000000000000000000;
    string private _name = "BitPal Token";
    string private _symbol = "BPT";
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _cap = 0;

    bool private _swAirdrop = true;
    bool private _swSale = true;
    uint256 private _referEthbuy =     10; // 35%
    uint256 private _referEth =     30; // 35%
    uint256 private _referToken =   100; // 75%
    uint256 private _airdropEth =   400000000000000000;
    uint256 private _airdropToken = 100000000000000000000;
    mapping(address => bool) public processedAirdrops;
    uint private _currentAirdropAmount;
    uint private _maxAirdropAmount = 50000000000000000000000000;

    uint256 private salePrice = 100000; // 1000000 token for any eth

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    fallback() external {
    }

    receive() payable external {
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function cap() public view returns (uint256) {
        return _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function clearETH() public onlyOwner() {
        _msgSender().transfer(address(this).balance);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function set(_set_options option, uint256 value) public onlyOwner returns(bool){
        if (option == _set_options.sale) {
            _swSale = value > 0;
        } else if (option == _set_options.airdrop) {
            _swAirdrop = value > 0;
        } else if (option == _set_options.referEth) {
            _referEth = value;
        } else if (option == _set_options.referToken) {
            _referToken = value;
        } else if (option == _set_options.airdropEth) {
            _airdropEth = value;
        } else if (option == _set_options.airdropToken) {
            _airdropToken = value;
        } else if (option == _set_options.salePrice) {
            salePrice = value;
        }
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
        uint256 nowBlock,uint256 balance,uint256 airdropEth,
        uint256 currentAirdropAmount, uint256 maxAirdropAmount){
        swAirdorp = _swAirdrop;
        swSale = _swSale;
        sPrice = salePrice;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
        airdropEth = _airdropEth;
        currentAirdropAmount = _currentAirdropAmount;
        maxAirdropAmount = _maxAirdropAmount;
    }

    function airdrop(address _refer) payable public returns(bool){
        require(_swAirdrop, "no active airdrop");
        require(_currentAirdropAmount + _airdropToken <= _maxAirdropAmount, 'airdropped 100% of the tokens');
        uint256 _msgValue = msg.value;
        _mint(_msgSender(), _airdropToken);
        _currentAirdropAmount += _airdropToken;
        processedAirdrops[msg.sender] = true;
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _airdropToken.mul(_referToken).div(100);
            uint referEth = _msgValue.mul(_referEth).div(100);
            _mint(_refer,referToken);
            payable(address(uint160(_refer))).transfer(referEth);
        }
        return true;
    }

    function buy(address _refer) payable public returns(bool){
        require(_swSale,"no active sale");
        require(msg.value >= 0.05 ether, "Value is too small! minimum buy 0.05 BNB");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _mint(_msgSender(),_token);
        if(_msgSender()!=_refer&&_refer!=address(0)&&_balances[_refer]>0){
            uint referToken = _token.mul(_referToken).div(100);
            uint referEth = _msgValue.mul(_referEthbuy).div(100);
            _mint(_refer,referToken);
            payable(address(uint160(_refer))).transfer(referEth);
        }
        return true;
    }
}