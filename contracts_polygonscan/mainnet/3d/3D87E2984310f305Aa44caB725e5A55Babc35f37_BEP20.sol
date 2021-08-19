/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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

abstract contract FeeAddress is Context, Ownable {
    using SafeMath for uint256;
    
    address private _addressMarketing;
    address private _addressExpenses;
    address private _addressLiquidity;

    event AddressMarketingTransferred(address indexed previousAddressMarketing, address indexed newAddressMarketing);
    event AddressExpensesTransferred(address indexed previousAddressExpenses, address indexed newAddressExpenses);
    event AddressLiquidityTransferred(address indexed previousAddressLiquidity, address indexed newAddressLiquidity);

    constructor () {
        
        _addressMarketing = 0x076F27E74dC2a705eC48D2695359Ce580F93E604;
        _addressExpenses = 0xB98b54FC091FFf9887B1456107055875B94D05c6;
        _addressLiquidity = 0x34387f200A4287E4531A392bbf140276b9a2C8DA;
        emit AddressMarketingTransferred(address(0), _addressMarketing);
        emit AddressExpensesTransferred(address(0), _addressExpenses);
        emit AddressLiquidityTransferred(address(0), _addressLiquidity);
    }

    function addressMarketing() public view virtual returns (address) {
        return _addressMarketing;
    }
    
    function addressExpenses() public view virtual returns (address) {
        return _addressExpenses;
    }
    
    function addressLiquidity() public view virtual returns  (address) {
        return _addressLiquidity;
    }

    function transferAddressMarketing(address newAddressMarketing) public virtual onlyOwner {
        require(newAddressMarketing != address(0), "addressMarketing: new address marketing is the zero address");
        emit AddressMarketingTransferred(_addressMarketing, newAddressMarketing);
        _addressMarketing = newAddressMarketing;
    }
    
    function transferAddressExpenses(address newAddressExpenses) public virtual onlyOwner {
        require(newAddressExpenses != address(0), "AddressExpenses: new address liquidity is the zero address");
        emit AddressExpensesTransferred(_addressExpenses, newAddressExpenses);
        _addressExpenses = newAddressExpenses;
    }
    
    function transferAddressLiquidity(address newAddressLiquidity) public virtual onlyOwner {
        require(newAddressLiquidity != address(0), "AddressLiquidity: new address liquidity is the zero address");
        emit AddressLiquidityTransferred(_addressLiquidity, newAddressLiquidity);
        _addressLiquidity = newAddressLiquidity;
    }
    
    function _calcTranferValues(uint256 amount) internal pure returns (uint256 valueMarketing, uint256 valueExpenses, uint256 valueLiquidity, uint256 valueDistribute, uint256 valueBurn, uint256 valueTransfer)
    { 
        uint256 _totalAmount = amount;
        uint256 onePercent = amount.div(100);
        
        
        
        uint256 _valueMarketing = onePercent.mul(1);
        uint256 _valueExpenses = onePercent.mul(1);
        uint256 _valueLiquidity = onePercent.mul(3);
        uint256 _valueDistribute = onePercent.mul(3);
        uint256 _valueBurn = onePercent.mul(1);
        uint256 _valueTransfer = 0;
        
        uint256 cost = _valueMarketing.add(_valueExpenses);
        cost = cost.add(_valueLiquidity);
        cost = cost.add(_valueDistribute);
        cost = cost.add(_valueBurn);
        
        _valueTransfer = _totalAmount.sub(cost);
        
        return ( _valueMarketing,  _valueExpenses, _valueLiquidity, _valueDistribute, _valueBurn, _valueTransfer); 
    } 
}

contract BEP20 is Context, IBEP20, Pausable, FeeAddress {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    //DEFINE OS HOLDERS - TODOS POIS IRA ENVIAR A MOEDA
    address[] internal _stakeholders;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    constructor () {
        _name = "Marstack"; 
        _symbol = "MST";

        _totalSupply = 1000000000000000000000000000000;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        
        //ADD _stakeholders
        _addStakeholder(addressMarketing());
        _addStakeholder(addressExpenses());
        _addStakeholder(addressLiquidity());
        _addStakeholder(msg.sender);
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
    
    function burn(uint amount) external whenNotPaused returns (bool) {
        require(amount > 0, "ERC20: Amount maior que 0");
        _burn(_msgSender(), amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }
    
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        
        uint256 valueMarketing = 0;
        uint256 valueExpenses = 0;
        uint256 valueLiquidity = 0;
        uint256 valueDistribute = 0;
        uint256 valueBurn = 0;
        uint256 valueTransfer = 0;
        uint256 valueDistributeUnit = 0; // VALOR A SER TRANSFERIDO PARA CADA UM
        
        senderBalance = senderBalance.sub(amount);
        _balances[sender] = senderBalance;
        
        //SE FOR 0 ele é removido do stakeholder para nao ocupar memoria
        if(_balances[sender] == 0) {
            _removeStakeholder(sender);
        }
        
        ( valueMarketing,  valueExpenses, valueLiquidity, valueDistribute, valueBurn, valueTransfer) = _calcTranferValues(amount);
        
        _balances[recipient] = _balances[recipient].add(valueTransfer);
        
        //adiciona o stakeholder
        _addStakeholder(recipient);
        
        if(valueMarketing > 0) {
             _balances[addressMarketing()] =  _balances[addressMarketing()].add(valueMarketing);
             emit Transfer(sender, addressMarketing(), valueMarketing);
             //ALTERA O HOLDER
        }
        
        if(valueExpenses > 0) {
             _balances[addressExpenses()] =  _balances[addressExpenses()].add(valueExpenses);
             emit Transfer(sender, addressExpenses(), valueExpenses);
        }
        
        if(valueLiquidity > 0) {
             _balances[addressLiquidity()] =  _balances[addressLiquidity()].add(valueLiquidity);
             emit Transfer(sender, addressLiquidity(), valueLiquidity);
        }
        
         if(valueDistribute > 0) {
            for (uint256 s = 0; s < _stakeholders.length; s += 1){
                valueDistributeUnit = _calcValueSendUser(valueDistribute, _stakeholders[s] );
                if(valueDistributeUnit > 0) {
                    _balances[_stakeholders[s]] = _balances[_stakeholders[s]].add(valueDistributeUnit);
                    valueDistribute = valueDistribute.sub(valueDistributeUnit);
                }
                
            }
        }
        
        //OQUE SOBRAR VAI PARA O FUNDO DE LIQUIDEZ
        if(valueDistribute > 0) {
            _balances[addressLiquidity()] =  _balances[addressLiquidity()].add(valueDistribute);
        }
        
        if(valueBurn > 0) {
            _burn(sender, valueBurn);
        }
        
        
        emit Transfer(sender, recipient, valueTransfer);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
    //verifica se ja existe o stakeholder
    function _isStakeholder(address _address) internal  view returns(bool, uint256) {
       for (uint256 s = 0; s < _stakeholders.length; s += 1){
           if (_address == _stakeholders[s]) return (true, s);
       }
       return (false, 0);
    }
    
    //adiciona um stakeholder
    function _addStakeholder(address stakeholderAddress) internal {
       (bool isStakeholder, ) = _isStakeholder(stakeholderAddress);
       if(!isStakeholder) _stakeholders.push(stakeholderAddress);
   }
   
   //remove o stakeholder
   function _removeStakeholder(address stakeholderAddress) internal {
       (bool isStakeholder, uint256 s) = _isStakeholder(stakeholderAddress);
       if(isStakeholder){
           _stakeholders[s] = _stakeholders[_stakeholders.length - 1];
           _stakeholders.pop();
       }
   }
   
   //DESCOBRE O QUANTO TEM QUE ENVIAR PARA O USER
   function _calcValueSendUser (uint256 amountTotalDistribute, address _address) internal view returns(uint256) {
       uint256 balance = _balances[_address];
       return (amountTotalDistribute * balance) / _totalSupply;
   }
   
}