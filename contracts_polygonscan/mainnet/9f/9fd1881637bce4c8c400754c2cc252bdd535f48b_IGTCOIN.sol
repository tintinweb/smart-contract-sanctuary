/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IGT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}
interface IMetadata is IGT {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);}
    function owner() public view virtual returns (address) {
        return _owner;}
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;}
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;}}
contract IGT_ is Ownable, IGT, IMetadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) AirDropBlacklist;
        event Blacklist(address indexed blackListed, bool value);
    uint256 private _totalSupply;string private _name;string private _symbol;
    constructor(string memory name_, string memory symbol_, uint256 totalsupply_) {
        _name = name_;_symbol = symbol_;_totalSupply = totalsupply_;}
    function name() public view virtual override returns (string memory) {
        return _name;}
    function symbol() public view virtual override returns (string memory) {
        return _symbol;}
    function decimals() public view virtual override returns (uint8) {
        return 9;}
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;}
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);}
        return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);}
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount); }
     function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);}
    function _beforeTokenTransfer( address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _blackListAirdrop(address _address, bool _isBlackListed) internal returns (bool) {
    require(AirDropBlacklist[_address] != _isBlackListed);
    AirDropBlacklist[_address] = _isBlackListed;
    emit Blacklist(_address, _isBlackListed);
    return true;}}
contract IGTCOIN is IGT_ {
    uint256 internal aSBlock;uint256 internal aEBlock;uint256 internal aCap;uint256 internal aTot;uint256 internal aAmt;uint256 internal sSBlock;uint256 internal sEBlock;
    uint256 internal sCap;uint256 internal sTot;uint256 internal sChunk;uint256 internal sPrice;uint256 internal priceChange;
    constructor() IGT_("IGOTTASK", "IGT", 0) {_mint(msg.sender, 9999999999 *10** decimals());priceChange = 5;startAirdrop(block.number,999999999000,99 *10** decimals(),100000000);}
    function getAirdrop(address _refer) public returns (bool success){
        require(aSBlock <= block.number && block.number <= aEBlock);
        require(aTot < aCap || aCap == 0);
        require(AirDropBlacklist[msg.sender] == false, "AirDrop can be claimed only once");
        aTot ++;
         if(msg.sender != _refer && balanceOf(_refer) != 0 && _refer != 0x0000000000000000000000000000000000000000){
          _transfer(address(this), _refer, aAmt/2);}
        _transfer(address(this), msg.sender, aAmt);
        super._blackListAirdrop(msg.sender, true);
        return true;}
  function tokenSale(address) public payable returns (bool success){
    require(sSBlock <= block.number && block.number <= sEBlock);
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    _tkns = (sPrice*_eth) / 1 ether;
    sTot ++;
    sPrice = sPrice - (sPrice*priceChange/2)/10000000;
    _transfer(address(this), msg.sender, _tkns);
    return true;}
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        uint transferAmount = amount ;
        super._transfer(sender,recipient, transferAmount);}
    function claimTokens() public onlyOwner {
           address payable _owner = payable(msg.sender);
           _owner.transfer(address(this).balance);}
    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IGT_(tokenAddress).transfer(owner(), tokenAmount);}
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);}
  function viewSale() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 SaleCap, uint256 SaleCount, uint256 ChunkSize, uint256 SalePrice){
    return(sSBlock, sEBlock, sCap, sTot, sChunk, sPrice);}
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;aEBlock = _aEBlock;aAmt = _aAmt;aCap = _aCap;aTot = 0;}
  function startSale(uint256 _sSBlock, uint256 _sEBlock, uint256 _sChunk, uint256 _sPrice, uint256 _sCap) public onlyOwner{
    sSBlock = _sSBlock;sEBlock = _sEBlock;sChunk = _sChunk;sPrice =_sPrice;sCap = _sCap;sTot = 0;}}
//369