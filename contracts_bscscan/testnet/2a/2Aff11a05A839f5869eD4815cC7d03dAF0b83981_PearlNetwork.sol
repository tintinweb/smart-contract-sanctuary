/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 _value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 _value
    );
}

// Dex Factory contract interface
interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Dex Router contract interface
interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PearlNetwork is Context, IBEP20, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isSniper;

    string private _name = "PEARL-Network";
    string private _symbol = "PEARL";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1 * 1e9 * 1e18;

    IDexRouter public dexRouter;
    address public dexPair;
    address faucetPool;
    address burnAddress;
    address devWallet;

    uint256 public _launchTime; // can be set only once

    bool public feesStatus = true; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public faucetFee = 80; // 8% will be added to the Faucet Pool address
    uint256 public burnFee = 910; // 91% will be added to the burn address
    uint256 public devFee = 10; // 1% will be added to the development address
    uint256 public totalFeePerTx = 10; // 10% tax fee will be deducted on each Tx

    constructor(
        address _faucetPool,
        address _burnAddress,
        address _devWallet
    ) {
        _balances[owner()] = _totalSupply;

        faucetPool = _faucetPool;
        burnAddress = _burnAddress;
        devWallet = _devWallet;

        IDexRouter _dexRouter = IDexRouter(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        // Create a dex pair for this new token
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "PEARL: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "PEARL: decreased allowance below zero"
            )
        );
        return true;
    }

    function mint(uint256 _amount) external onlyOwner {
        _balances[_msgSender()] = _balances[_msgSender()].add(_amount);
        _totalSupply = _totalSupply.add(_amount);

        emit Transfer(address(0), _msgSender(), _amount);
    }

    function burn(uint256 _amount) external onlyOwner {
        _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);

        emit Transfer(_msgSender(), address(0), _amount);
    }

    function includeOrExcludeFromFee(address _account, bool _value)
        external
        onlyOwner
    {
        _isExcludedFromFee[_account] = _value;
    }

    function setFeePercent(
        uint256 _faucetFee,
        uint256 _BurnFee,
        uint256 _devFee,
        uint256 _totalFee
    ) external onlyOwner {
        faucetFee = _faucetFee;
        burnFee = _BurnFee;
        devFee = _devFee;
        totalFeePerTx = _totalFee;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address _faucetPool,
        address _burnAddress,
        address _devWallet
    ) external onlyOwner {
        faucetPool = _faucetPool;
        burnAddress = _burnAddress;
        devWallet = _devWallet;
    }

    function setPancakeRouter(IDexRouter _router, address _pair)
        external
        onlyOwner
    {
        dexRouter = _router;
        dexPair = _pair;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "PEARL: Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
    }

    function addSniperInList(address _account) external onlyOwner {
        require(
            _account != address(dexRouter),
            "PEARL: We can not blacklist dexRouter"
        );
        require(!_isSniper[_account], "PEARL: sniper already exist");
        _isSniper[_account] = true;
    }

    function removeSniperFromList(address _account) external onlyOwner {
        require(_isSniper[_account], "PEARL: Not a sniper");
        _isSniper[_account] = false;
    }

    function removeStuckBnb(address payable _account, uint256 _amount)
        external
        onlyOwner
    {
        _account.transfer(_amount);
    }

    function removeStuckToken(
        IBEP20 _token,
        address _account,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_account, _amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "PEARL: approve from the zero address");
        require(spender != address(0), "PEARL: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "PEARL: transfer from the zero address");
        require(to != address(0), "PEARL: transfer to the zero address");
        require(amount > 0, "PEARL: Amount must be greater than zero");
        require(!_isSniper[to], "PEARL: Sniper detected");
        require(!_isSniper[from], "PEARL: Sniper detected");

        if (!_tradingOpen && (from != owner() || to != owner())) {
            require(
                from != dexPair && to != dexPair,
                "PEARL: Trading is not enabled yet"
            );
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any _account belongs to _isExcludedFromFee _account then remove the fee
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            !feesStatus
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            uint256 tFee = amount.mul(totalFeePerTx).div(1e3);
            uint256 transferAmount = amount.sub(tFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(transferAmount);
            _takeFaucetFee(tFee);
            _takeBurnFee(tFee);
            _takeDevFee(tFee);

            emit Transfer(_msgSender(), recipient, transferAmount);
        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(_msgSender(), recipient, amount);
        }
    }

    function _takeFaucetFee(uint256 _tFee) private {
        uint256 tFee = _tFee.mul(faucetFee).div(1e3);
        _balances[faucetPool] = _balances[faucetPool].add(tFee);

        emit Transfer(_msgSender(), faucetPool, tFee);
    }

    function _takeBurnFee(uint256 _tFee) private {
        uint256 tFee = _tFee.mul(burnFee).div(1e3);
        _balances[burnAddress] = _balances[burnAddress].add(tFee);

        emit Transfer(_msgSender(), burnAddress, tFee);
    }

    function _takeDevFee(uint256 _tFee) private {
        uint256 tFee = _tFee.mul(devFee).div(1e3);
        _balances[devWallet] = _balances[devWallet].add(tFee);

        emit Transfer(_msgSender(), devWallet, tFee);
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}