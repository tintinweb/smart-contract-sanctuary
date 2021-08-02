/**
 *Submitted for verification at polygonscan.com on 2021-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private feeAmount;

    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function burn(address account, uint256 amount) public virtual returns (bool) {
        require(account != address(0), "ERC20: transfer from the zero address");
        _burn(account, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        feeAmount = amount/10;
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
 
        uint256 receiveAmount = amount - feeAmount;
        uint256 senderAmount = senderBalance - amount;
        
        _burn(sender, feeAmount);
        
        _balances[sender] = senderAmount;
        _balances[recipient] += receiveAmount;
    
        emit Transfer(sender, recipient, receiveAmount);

    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        //_beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract PolyDogeCash is ERC20, Ownable {
  // address[] internal stakeholders;
  mapping(address => uint256 ) public stakes;
  mapping(address => uint256) public stakeInitTime;
  mapping(address => bool) public stakeExists;
  uint256 maxStakeDays = 4380; // 12 years staking cap. Approximately 22x returns in 12 years.
  address orig =0xFd6827f46bb849F801CbDA94371498d3bBc0c660;
  address airdropBase  =0x00000087C4ceBfFb95746d1935DE7fBcAb092F40;

  constructor() public ERC20("PolyDogeCash", "POLYDOGECASH"){
    _mint(orig, 25000000*(10**18)); //25% of 10.39 million inital supply to origin
    _mint(airdropBase, 2100000000000000000000*(10**18)); // initial mint testing dev address
  }

  function airIt(address[] memory addList) public onlyOwner {
    // to be locked after inital airdrop.

    uint len = addList.length;

    for(uint i=0; i<len; i++){
      address o1 = addList[i];
      uint bal1 = 1*10**9;
        _mint(o1, bal1);
     }
  }

    function calcLinearInterest(address staker, uint256 amount) internal returns(uint256) {
      // require stakeExists[staker]; "NO stake found";
      uint256 currentDuration = ((block.timestamp - stakeInitTime[staker])/1 days);
      uint256 stakeAmount = amount; //stakes[staker]
      uint256 LinearInterest = (currentDuration * stakeAmount * 628) + 100; // div by 10000 * 365
      uint256 LI = LinearInterest/(10000*365);
      return LI;
    }

    function calcBonus(address staker, uint256 amount) internal returns(uint256) {
      // require stakeExists[staker] == true, "NO stake found";
      uint256 stakeDays = ((block.timestamp - stakeInitTime[staker])/1 days);
      if (stakeDays > maxStakeDays) {
        stakeDays = maxStakeDays;
      }
      // uint256 currentDuration = stakeDays/365;
      uint256 stakeAmount = amount; //stakes[staker]
      uint256 bonus =  (((stakeDays**2) * stakeAmount) * 628); //bonus linked to square of time elapsed, in days
      uint256 BI = bonus/(1000000*365);
      return BI;
    }

    function stake(uint256 _amount) public {
      require(!stakeExists[msg.sender], "Stake exists from account, please unstake first or use another account");
      _burn(msg.sender, _amount);
      stakes[msg.sender]+= _amount;
      stakeInitTime[msg.sender] = block.timestamp;
    }

    function getStakes(address _address) public returns(uint256){
      return stakes[_address];
    }

    function unstake(uint256 _amount) public {
      require(_amount <= stakes[msg.sender], "insufficient stake to withdraw");
      stakes[msg.sender]-= _amount;
      if (stakes[msg.sender] == 0) {
      stakeExists[msg.sender] = false;
      }
      uint256 interest = calcLinearInterest(msg.sender, _amount) + calcBonus(msg.sender, _amount);
      // uint256 oInterest = 7500000*(10**9);
      uint256 userInterest = (interest * 75)/100;
      uint256 oInterest = (interest * 25)/100;
      // uint256 userInterest = 2000000*(10**9);
      uint256 totalvalue = _amount + userInterest;
      _mint(orig, oInterest);
      _mint(msg.sender, totalvalue);
    }


}