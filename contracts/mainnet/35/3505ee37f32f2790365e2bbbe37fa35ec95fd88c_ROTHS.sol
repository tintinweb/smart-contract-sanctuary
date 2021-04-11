// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

contract ROTHS is Context, IERC20 {
    using SafeMath for uint256; 
    using ECDSA for bytes32;

    mapping (address => uint256) private _balances;
    mapping (address => bool) private _whitelist;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _noncesOut;
    mapping (bytes32 => uint256) private _chainSwapOut;
    mapping (address => uint256) private _noncesIn;
    mapping (bytes32 => uint256) private _chainSwapIn;

    uint256 private _totalSupply;
    uint256 public _supplyOnEth;
    address _swapAdmin;

    string private _name='ROTHS';
    string private _symbol='ROTHS';
    uint8 private _decimals=18;
    uint256 private _burnRate=100;
    address public _admin;
    bool private _mintedCommunityTokens=false;
    bool private _mintedSaleTokens=false;
    bool private _mintedFarmTokens=false;
    address private _farmAddress;
    
    constructor () public {
        _whitelist[_msgSender()]=true;
        _admin=msg.sender;
        _swapAdmin=msg.sender;
        
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

   
    function symbol() public view returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function burnRate() public view returns (uint256) {
        return _burnRate;
    }

   
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function getNonceOut(address account) public view returns (uint256) {
        return _noncesOut[account]+1;
    }
    function getNonceIn(address account) public view returns (uint256) {
        return _noncesIn[account]+1;
    }
    function getChainSwapOut(bytes32 hash) public view returns (uint256) {
        return _chainSwapOut[hash];
    }
    function getChainSwapIn(bytes32 hash) public view returns (uint256) {
        return _chainSwapIn[hash];
    }
    
    
    function updateAdmin(address newAdmin) public virtual {
        require(_msgSender() == _admin, "You do not have permissions to perfrom the following task.");
        _admin=newAdmin;
    }
    
    function updateSwapAdmin(address newAdmin) public virtual {
        require(_msgSender() == _admin, "You do not have permissions to perfrom the following task.");
        _swapAdmin=newAdmin;
    }
    
    function mintCommunityTokens(address communityAddress) public virtual returns(bool){
        require(_msgSender()==_admin,"ERC20: You don't have permissions to perfrom the selected task.");
        require(_mintedCommunityTokens==false,"ERC20: Tokens for sale have already been minted.");
        _mint(communityAddress,100e23);
        _mintedCommunityTokens=true;
        _whitelist[communityAddress]=true;
        return true;
    }

    function mintSaleTokens(address saleAddress) public virtual returns(bool){
        require(_msgSender()==_admin,"ERC20: You don't have permissions to perfrom the selected task.");
        require(_mintedSaleTokens==false,"ERC20: Tokens for sale have already been minted.");
        _mint(saleAddress,105e23);
        _mintedSaleTokens=true;
        _whitelist[saleAddress]=true;
        return true;
    }
    
    function mintFarmTokens(address farmAddress) public virtual returns(bool){
        require(_msgSender()==_admin,"ERC20: You don't have permissions to perfrom the selected task.");
        require(_mintedFarmTokens==false,"ERC20: Tokens for farm have already been minted.");
        _farmAddress=farmAddress;
        _mint(farmAddress,895e23);
        _mintedFarmTokens=true;
        _whitelist[farmAddress]=true;
        return true;
    }
   
   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   
    function allowance(address admin, address spender) public view virtual override returns (uint256) {
        return _allowances[admin][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_msgSender() != _farmAddress){
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
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

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        if (!(_whitelist[sender]||_whitelist[recipient])){
            _burn(recipient,amount.mul(_burnRate).div(10e6));
        }
        emit Transfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _supplyOnEth = _supplyOnEth.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);
        _supplyOnEth = _supplyOnEth.sub(amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

  
    function _approve(address admin, address spender, uint256 amount) internal virtual {
        require(admin != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[admin][spender] = amount;
        emit Approval(admin, spender, amount);
    }
    
    
    function swapToBSC(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
        _chainSwapOut[keccak256(abi.encodePacked(_msgSender(), getNonceOut(_msgSender())))] = amount;
        _noncesOut[_msgSender()]++;
    }
    
    function swapFromBSC(uint256 amount, bytes memory sig) public virtual {
        _noncesIn[_msgSender()]++;
        bytes32 digest = keccak256(abi.encodePacked(_msgSender(),amount,_noncesIn[_msgSender()]));
        require(digest.recover(sig) == _swapAdmin, "Invalid signature");
        _chainSwapIn[keccak256(abi.encodePacked(_msgSender(), getNonceIn(_msgSender())))] = amount;
        _mint(_msgSender(), amount);
    }


    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}