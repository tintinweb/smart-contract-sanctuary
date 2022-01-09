/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract LordKnightTokenV2 is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _rewardclaim;
  mapping (address => uint256) private _rewardclaimcooldown;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _BurnFee;
  uint256 private _ContractFee;
  uint256 private _ClaimFee;
  uint256 private _ClaimFeePercentage;
  uint256 private _ClaimMinimumed;
  uint256 private _ClaimCooldown;
  uint256 private _mintingHeroFee;

  uint8 private _decimals;
  string private _symbol;
  string private _name;
  
  address private _deadAddress;
  address private _NFTAddress;

  constructor() {
    _name = "LordKnightTokenV2 TestNet";
    _symbol = "LKTV2";
    _decimals = 9;
    _totalSupply = 100000000 * (10 ** 9);
    _balances[msg.sender] = _totalSupply;
    _deadAddress = 0x000000000000000000000000000000000000dEaD;
    _NFTAddress = _deadAddress;
    _BurnFee = 10; //percentage burn fee per transection /1000
    _ContractFee = 30; //percentage return to game pool per transection /1000
    _ClaimFee = 0; //claim fee as intnitial *decimals
    _ClaimFeePercentage = 0; //claim fee as percentage /1000
    _ClaimMinimumed = 0; // minimal token claim each withdraw *decimals
    _ClaimCooldown = 30; // second of claim cooldown time
    _mintingHeroFee = 400 * (10 ** 9);

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function tokenburnfee() external view returns (uint256) {
    return _BurnFee;
  }

  function tokenpoolfee() external view returns (uint256) {
    return _ContractFee;
  }

  function rewardcliamfee() external view returns (uint256) {
    return _ClaimFee;
  }

  function rewardcliamfeepercentage() external view returns (uint256) {
    return _ClaimFeePercentage;
  }

  function minimalclaim() external view returns (uint256) {
    return _ClaimMinimumed;
  }

  function mintingHeroFee() external view returns (uint256) {
    return _mintingHeroFee;
  }

  function seeNFTAddress() external view returns (address) {
    return _NFTAddress;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function rewardclaimOf(address account) external view returns (uint256) {
    return _rewardclaim[account];
  }

  function rewardclaimcooldown() external view returns (uint256) {
    return _rewardclaimcooldown[msg.sender];
  }

  function rewarclaimtimer() external view returns (uint256) {
    if(_rewardclaimcooldown[msg.sender] > block.timestamp){
      return _rewardclaimcooldown[msg.sender] - block.timestamp;
    }else{
      return 0;
    }
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function rewardclaim(uint256 amount) external returns (bool) {
    require(msg.sender != address(0), "BEP20: transfer from the zero address");
    require(amount >= _ClaimMinimumed, "BEP20: revert by minimumed claim");
    require(_rewardclaim[msg.sender] >= amount, "BEP20: not enought claim token");
    require(_rewardclaimcooldown[msg.sender] <= block.timestamp, "BEP20: Claim is in cooldown");

    uint lessclaim = (amount * _ClaimFeePercentage / 1000) + _ClaimFee;
    uint claimin = amount - lessclaim;

    if( _rewardclaim[msg.sender] > lessclaim ) {

    _rewardclaim[msg.sender] = _rewardclaim[msg.sender].sub(amount);
    _balances[owner()] = _balances[owner()].sub(claimin);
    emit Transfer(owner(), msg.sender, claimin);

    _rewardclaimcooldown[msg.sender] = block.timestamp + _ClaimCooldown;

    }
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function updateBurnFee(uint256 amount) public onlyOwner returns (bool) {
    _BurnFee = amount;
    return true;
  }

  function updatePoolFee(uint256 amount) public onlyOwner returns (bool) {
    _ContractFee = amount;
    return true;
  }

  function updateClaimFee(uint256 amount) public onlyOwner returns (bool) {
    _ClaimFee = amount;
    return true;
  }

  function updateClaimFeePercentage(uint256 amount) public onlyOwner returns (bool) {
    _ClaimFeePercentage = amount;
    return true;
  }

  function updateMinimalClaim(uint256 amount) public onlyOwner returns (bool) {
    _ClaimMinimumed = amount;
    return true;
  }

  function updateClaimCooldown(uint256 amount) public onlyOwner returns (bool) {
    _ClaimCooldown = amount;
    return true;
  }

  function updateMintHeroFee(uint256 amount) public onlyOwner returns (bool) {
    _mintingHeroFee = amount;
    return true;
  }

  function updateNFTAddress(address inputadr) public onlyOwner returns (bool) {
    _NFTAddress = inputadr;
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    
    uint256 tBurnFee = amount * _BurnFee / 1000;
    uint256 tContractFee = amount * _ContractFee / 1000;
    uint256 totalFee = tBurnFee + tContractFee;
    uint256 totalSender = amount - totalFee;

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);   
    if( owner() == sender || owner() == recipient){

        emit Transfer(sender, recipient, amount);

    }else{
        _balances[recipient] = _balances[recipient].sub(totalFee);
        _balances[owner()] = _balances[owner()].add(tContractFee);
        _balances[_deadAddress] = _balances[_deadAddress].add(tBurnFee);
        
        emit Transfer(sender, recipient, totalSender);
        emit Transfer(sender, owner(), tContractFee);
        emit Transfer(sender, _deadAddress, tBurnFee);

    }

  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  function _mintHero(address account) public {
    require( msg.sender == _NFTAddress, "BEP20: only mint from contract");
    require( _NFTAddress != _deadAddress,"BEP20: nft address does not setup");
    
    _balances[account] = _balances[account].sub(_mintingHeroFee);
  }
}