// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event TransferFrom(address indexed from, address indexed to, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//SAFE MATH
library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);
    
    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Codes is Ownable, Pausable {
    event QrCodeCreated(uint256 code, address created);
    event QrCodeDeleted(uint256 code, address created);
    event BarCodeCreated(uint256 code, address created);
    event BarCodeDeleted(uint256 code, address created);

    mapping (uint256 => uint256) private _qrcodes;
    mapping (uint256 => uint256) private _barcodes;

    function verifyQrCode(uint256 code) public view virtual whenNotPaused  returns (uint256) {
        return _qrcodes[code];
    }

    function createQrCode(uint256 code) public virtual whenNotPaused onlyOwner {
        _qrcodes[code] = 1;
        emit QrCodeCreated(code, _msgSender());
    }

    function deleteQrCode(uint256 code) public virtual whenPaused onlyOwner {
        _qrcodes[code] = 0;
        emit QrCodeDeleted(code, _msgSender());
    }
    
    function verifyBarCode(uint256 code) public view virtual whenNotPaused  returns (uint256) {
        return _barcodes[code];
    }

    function _createBarCode(uint256 code) internal virtual whenNotPaused {
        _barcodes[code] = 1;
        emit BarCodeCreated(code, _msgSender());
    }

    function deleteBarCode(uint256 code) public virtual whenPaused onlyOwner {
        _barcodes[code] = 0;
        emit BarCodeDeleted(code, _msgSender());
    }
}

abstract contract DonationAddress is Context, Ownable {
    using SafeMath for uint256;
    
    address private _addressDonation;

    event AddressDonationTransferred(address indexed previousAddressDonation, address indexed newAddressDonation);

    constructor () {
        address msgSender = _msgSender();
        _addressDonation = msgSender;
        emit AddressDonationTransferred(address(0), msgSender);
    }

    function addressDonation() public view virtual returns (address) {
        return _addressDonation;
    }
    

    function transferAddressDonation(address newAddressDonation) public virtual onlyOwner {
        require(newAddressDonation != address(0), "addressDonation: new address donation is the zero address");
        emit AddressDonationTransferred(_addressDonation, newAddressDonation);
        _addressDonation = newAddressDonation;
    }
    
    function _calcTranferValues(uint256 amount) internal pure returns (uint256 valueDonation, uint256 valueTransfer)
    { 
        uint256 onePercent = amount.div(100);
        
        uint256 _valueDonation = onePercent.mul(1);

        uint256 cost = _valueDonation;
        uint256 _valueTransfer = amount.sub(cost);
        
        return ( _valueDonation, _valueTransfer); 
    } 
}

contract BEP20 is Context, IBEP20, Pausable, DonationAddress, Codes {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _maxTotalSupply;

    string private _name;
    string private _symbol;
    
    constructor () {
        _name = "BATERY"; 
        _symbol = "BTY";
        
        _maxTotalSupply = 3000000000000000000000000000;
        
        _totalSupply = 0;
    }
    
    function pay() public payable {}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function getToken(uint256 qrCode, uint256 barCode) public whenNotPaused {
        require(verifyBarCode(barCode) == 0, "BEP20: Bar code id used");
        require(verifyQrCode(qrCode) == 1, "BEP20: QRCode not exist");
        
        _createBarCode(barCode);
        _mint(_msgSender(), 1000000000000000000);
    }

    function approve(address spender, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        
        currentAllowance = currentAllowance.sub(amount);
        
        _approve(sender, _msgSender(), currentAllowance);
        
        emit TransferFrom(sender, recipient, amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        currentAllowance = currentAllowance.sub(subtractedValue);
        _approve(_msgSender(), spender, currentAllowance);

        return true;
    }
    
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        
        uint256 valueDonation = 0;
        uint256 valueTransfer = 0;
        
        senderBalance = senderBalance.sub(amount);
        _balances[sender] = senderBalance;
        
        (valueDonation, valueTransfer) = _calcTranferValues(amount);
        _balances[addressDonation()] =  _balances[addressDonation()].add(valueDonation);

        _balances[recipient] = _balances[recipient].add(valueTransfer);
        
        emit Transfer(sender, addressDonation(), valueDonation);
        emit Transfer(sender, recipient, valueTransfer);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}