/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

// token contract interface
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
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
        this;
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


contract ADAMANTIUM is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromMaxTx;

    string private _name = "ADAMANTIUM";
    string private _symbol = "ADAMANTIUM";
    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1 * 1e18 * 1e9; // 1 quintillion

    IDexRouter public dexRouter;
    address public dexPair;
    address public feeAddress1;
    address public feeAddress2;

    uint256 public maxTxAmount = _totalSupply.mul(2).div(100); // should be 2% percent per transaction
    uint256 public percentDivider = 1000;
    uint256 public launchTime; // can be set only once

    bool public feesStatus; // disable by default
    bool public _tradingOpen; //once switched on, can never be switched off.

    uint256 public taxFee1 = 0; // 0% will be added to the feeAddress1
    uint256 public taxFee2 = 0; // 0% will be added to the feeAddress2

    constructor(address _feeAddress1, address _feeAddress2) {
        _balances[owner()] = _totalSupply;

        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;

        IDexRouter _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a dex pair for this new ADAMANTIUM
        dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        // set the rest of the contract variables
        dexRouter = _dexRouter;

        //exclude owner and this contract from fee
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[_feeAddress1] = true;
        isExcludedFromFee[_feeAddress2] = true;

        // exclude from max tx
        isExcludedFromMaxTx[owner()] = true;
        isExcludedFromMaxTx[address(this)] = true;

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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
                "ADAMANTIUM: transfer amount exceeds allowance"
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
                "ADAMANTIUM: decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxTx(address _address, bool value)
        external
        onlyOwner
    {
        isExcludedFromMaxTx[_address] = value;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner {
        maxTxAmount = _amount;
    }

    function setFeePercent(uint256 _taxFee1, uint256 _taxFee2)
        external
        onlyOwner
    {
        taxFee1 = _taxFee1;
        taxFee2 = _taxFee2;
    }

    function enableOrDisableFees(bool _value) external onlyOwner {
        feesStatus = _value;
    }

    function updateAddresses(
        address payable _feeAddress1,
        address payable _feeAddress2
    ) external onlyOwner {
        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;
    }

    function setRoute(IDexRouter _router, address _pair) external onlyOwner {
        dexRouter = _router;
        dexPair = _pair;
    }

    function launch() external onlyOwner {
        require(!_tradingOpen, "ADAMANTIUM: Already enabled");
        _tradingOpen = true;
        launchTime = block.timestamp;
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

    function totalFeePerTx(uint256 amount) public view returns (uint256) {
        uint256 fee = amount.mul(taxFee1.add(taxFee2)).div(percentDivider);
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(
            owner != address(0),
            "ADAMANTIUM: approve from the zero address"
        );
        require(
            spender != address(0),
            "ADAMANTIUM: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(
            from != address(0),
            "ADAMANTIUM: transfer from the zero address"
        );
        require(to != address(0), "ADAMANTIUM: transfer to the zero address");
        require(amount > 0, "ADAMANTIUM: Amount must be greater than zero");

        if (
            isExcludedFromMaxTx[from] == false &&
            isExcludedFromMaxTx[to] == false // by default false
        ) {
            require(
                amount <= maxTxAmount,
                "ADAMANTIUM: amount exceeded max limit"
            );

            if (!_tradingOpen) {
                require(
                    from != dexPair && to != dexPair,
                    "ADAMANTIUM: Trading is not enabled yet"
                );
            }
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to isExcludedFromFee account then remove the fee
        if (isExcludedFromFee[from] || isExcludedFromFee[to] || !feesStatus) {
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
        if (!takeFee) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(sender, recipient, amount);
        } else {
            uint256 allFee = totalFeePerTx(amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            emit Transfer(sender, recipient, tTransferAmount);

            if (taxFee1 > 0) _takeFee1(sender, amount);
            if (taxFee2 > 0) _takeFee2(sender, amount);
        }
    }

    function _takeFee1(address sender, uint256 amount) private {
        uint256 fee = amount.mul(taxFee1).div(percentDivider);
        _balances[feeAddress1] = _balances[feeAddress1].add(fee);

        emit Transfer(sender, feeAddress1, fee);
    }

    function _takeFee2(address sender, uint256 amount) private {
        uint256 fee = amount.mul(taxFee2).div(percentDivider);
        _balances[feeAddress2] = _balances[feeAddress2].add(fee);

        emit Transfer(sender, feeAddress2, fee);
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