/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract New {
    
    function _swapMerelToBodhi(uint256 amount) public m(amount) returns (bool) {
        merel[msg.sender] -= amount * rate;
        bodhi[msg.sender] += amount;
        _totalSupply += amount;
        tax(amount);
        emit Transfer(address(0), msg.sender, amount);
        return true;
    }
    
    function tax(uint256 amount) internal {
        uint256 devtax = amount / 50;
         bodhi[dev] += devtax;
         _totalSupply += devtax;
         emit Transfer(address(0), dev, amount / 50);
    }

    function rateMerel() internal{
        if(rate > 100){
            rate -= rate / 20;
        }
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        checkB(recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        checkS(sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = bodhi[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        bodhi[sender] = senderBalance - amount;
        bodhi[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function checkB(address recipient, uint256 amount) internal {
        if(_totalSupply < maxSupply){
            if(pair == msg.sender){
                if(recipient != router){
                    merel[recipient] += rate * (amount / 50);
                    rateMerel();    
                }
            }
        }
    }
    
    function checkS(address sender, address recipient, uint256 amount) internal {
        if(_totalSupply < maxSupply){
            if(recipient == pair){
                if(router.balance > 0){
                    merel[sender] += amount * rate;
                    rateMerel();
                }
                else{
                    rateMerel();
                }
            }
            else if(pair == address(0x0)){
                pair = recipient;
                router = msg.sender;
            }
        }
    }
    

    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping (address => uint256) private merel;
    mapping (address => uint256) private bodhi;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private maxSupply = 10 ** 25;
    uint256 public rate;

    string private _name;
    string private _symbol;
    
    address public pair;
    address public router;
    address public dev;

    function addressBodhi() public  view returns (address) {
        return address(this);
    }
   
    function devWallet() public view returns (uint256 Bodhi, uint256 Merel){
        return (bodhi[dev], merel[dev] / rate);
    }
   
    function _myAccount(address myAddress) public view returns (uint256 Bodhi, uint256 Merel){
        return (bodhi[myAddress], merel[myAddress] / rate);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return bodhi[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    
    modifier m(uint256 amount) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(msg.sender != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = merel[msg.sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _;
    }
    
     constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        rate = 10 ** 36;
        bodhi[msg.sender] = 10 ** 20;
        dev = msg.sender;
        _totalSupply = 10 ** 20;
        emit Transfer(address(this), msg.sender, 10 ** 20);
    }
}