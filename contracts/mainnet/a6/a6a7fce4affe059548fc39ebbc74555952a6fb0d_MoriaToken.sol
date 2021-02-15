pragma solidity ^0.4.24;

import './DividendTokenStore.sol';
import './Administratable.sol';
import './StandardToken.sol';

contract MoriaToken is StandardToken, Administratable {
  
  string public constant name = "MoriaToken";
  string public constant symbol = "MOR";
  uint8 public constant decimals = 18;

  DividendTokenStore public store;
  bool public canDestroy = true;
  bool public minting = true;

  modifier isDestroyable() {
    require(canDestroy);
    _;
  }

  modifier canMint() {
    require(minting);
    _;
  }

  constructor() public {
  }

  function () public payable {
    require(store.payIn.value(msg.value)());
  }

  function totalSupply() public view returns (uint256) {
    return store.totalSupply();
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return store.balanceOf(_owner);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    store.transfer(msg.sender, _to, _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= allowed[_from][msg.sender]);
    store.transfer(_from, _to, _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function pause() public onlyOwner {
    store.pause();
  }

  function unpause() public onlyOwner {
    store.unpause();
  }

  function addLock(address _address) onlyAdmin public returns (bool) {
    return store.addLock(_address);
  }

  function revokeLock(address _address) onlyAdmin public returns (bool) {
    return store.revokeLock(_address);
  }

  function claimDividends() public returns (uint256 amount) {
    return store.claimDividendsFor(msg.sender);
  }

  function claimDividendsFor(address _address) public onlyAdmin returns (uint256 amount) {
    return store.claimDividendsFor(_address);
  }

  function buyBack() public onlyAdmin payable returns (bool) {
    require(store.buyBack.value(msg.value)());
    return true;
  }

  function claimBuyBack() public returns (bool) {
    return claimBuyBackFor(msg.sender);
  }

  function claimBuyBackFor(address _address) public onlyAdmin returns (bool) {
    return claimBuyBackFor(_address);
  }
 
  // admin

  function mint(address _from, address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    store.mint(_to, _amount);
    emit Transfer(_from, _to, _amount);
  }

  function endMinting() public onlyOwner canMint returns (bool) {
    minting = false;
  }

  function upgradeEvent(address _from, address _to) public onlyAdmin {
    emit Transfer(_from, _to,  store.balanceOf(_to));
  }

  function changeStore(DividendTokenStore _store) public onlyOwner returns (bool) {
    store = _store;
    emit StoreChanged(address(store));
    return true;
  }

  function transferStoreOwnership() public onlyOwner {
    store.transferOwnership(owner);
  }

  function destroyToken() public onlyOwner isDestroyable {
    transferStoreOwnership();
    selfdestruct(owner);
  }

  function disableSelfDestruct() public onlyOwner isDestroyable {
    canDestroy = false;
  } 

  event StoreChanged(address indexed _newStore);
  
}