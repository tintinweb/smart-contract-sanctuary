/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier:MIT

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
    address private _previousOwner;
    uint256 private _lockTime;

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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(
            block.timestamp > _lockTime,
            "Contract is locked until defined days"
        );
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

interface IPancakeFactory {
    
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}

interface IPancakeRouter01 {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}

interface IPancakeRouter02 is IPancakeRouter01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        internal
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of Apollo11 -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

}

contract xmasCoin is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;
    mapping(address => bool) public _isExcludedFromMaxholding;
  

    string private _name = "XMAS token";
    string private _symbol = "$XMAS";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000 * 1e18;
    uint256 public maxHoldingAmount = 80000 * 1e18;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;
    
    address payable public WalletMT; // marketing and team wallet

    uint256 public percentDivider = 1000;
    uint256 public _launchTime; // can be set only once

    bool public distributionStatus; // should be true to turn on to liquidate the pool
    bool public reflectionFeesdiabled; // enable by default
    bool public _tradingOpen; //once switched on, can never be switched off.
 
    uint256 public buyfee = 100; // 10% buy fee
    uint256 public previousBuyfee = buyfee;
    uint256 public sellfee = 150; // 15% sell fee
    uint256 public previousSellfee = sellfee;

    constructor(address payable _MT)
    {
        _balances[owner()] = _totalSupply;
 
        WalletMT = _MT;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(
        // miannet >> 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // testnet >> 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1 
        );
        // Create a pancake pair for this new Apollo11
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(WalletMT)] = true;

        //exclude from max holding
        _isExcludedFromMaxholding[owner()] = true;
        _isExcludedFromMaxholding[address(this)] = true;
        _isExcludedFromMaxholding[address(pancakePair)] = true;
        _isExcludedFromMaxholding[address(WalletMT)] = true;
        //_isExcludedFromMaxholding[address(WalletM)] = true;
        //_isExcludedFromMaxholding[address(WalletR)] = true;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    //to receive BNB from pancakeRouter when swapping
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
                "transfer amount exceeds allowance"
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
                "decreased allowance below zero"
            )
        );
        return true;
    }

    function includeOrExcludeFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function includeOrExcludeFromMaxHolding(address _address, bool value)
        external
        onlyOwner
    {
        _isExcludedFromMaxholding[_address] = value;
    }

    function setMaxHoldingAmount(uint256 _amount) external onlyOwner {
        maxHoldingAmount = _amount;
    }

    function setWalletMT(address payable _MT) external onlyOwner {
        WalletMT = _MT;
    }

    function setFeePercent(
        uint256 _buyfee,
        uint256 _sellfee
    ) external onlyOwner {
        buyfee = _buyfee;
        previousBuyfee = _buyfee;
        sellfee = _sellfee;
        previousSellfee = _sellfee;
    }

    /*function setDistributionPercent(
        uint256 _bnbDPercent,
        uint256 _bnbMPercent,
        uint256 _bnbRPercent
    ) external onlyOwner {
        bnbDPercent = _bnbDPercent;
        bnbMPercent = _bnbMPercent;
        bnbRPercent = _bnbRPercent;
    }*/

    function setDistributionStatus(bool _value) public onlyOwner {
        distributionStatus = _value;
    }

    /*function setReflectionFees(bool _value) external onlyOwner {
        reflectionFeesdiabled = _value;
    }*/

 
    function setPancakeRouter(IPancakeRouter02 _router, address _pair)
        external
        onlyOwner
    {
        pancakeRouter = _router;
        pancakePair = _pair;
    }

    function startTrading() external onlyOwner {
        require(!_tradingOpen, "Already enabled");
        _tradingOpen = true;
        _launchTime = block.timestamp;
        distributionStatus = true;
    }

    function totalFeePerTx(address to, uint256 amount) public view returns (uint256) {
        uint256 fee = amount
                    .mul(buyfee)
                    .div(percentDivider);

        // get sell fee
        if (to == pancakePair) {
            fee = amount
                    .mul(sellfee)
                    .div(percentDivider);
        } 
        return fee;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Amount must be greater than zero");  

        if (!_tradingOpen) {
            require(
                from != pancakePair && to != pancakePair,
                "Trading is not enabled yet"
            );
        }
        if (
        _isExcludedFromMaxholding[from] == false &&
        _isExcludedFromMaxholding[to] == false // by default false
        ) {  
    require( balanceOf(to).add(amount)  <= maxHoldingAmount, "amount exceed max holding limit");
        }
        if(block.timestamp < _launchTime + 4 minutes && to == pancakePair){
            sellfee = 500;
        }

        // swap and liquify
        distributionToWallets(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = false;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            from == pancakePair ||
            to == pancakePair
        ) {
            takeFee = true;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
       buyfee=previousBuyfee;
       sellfee=previousSellfee;
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            uint256 allFee = totalFeePerTx(recipient, amount);
            uint256 tTransferAmount = amount.sub(allFee);
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            _balances[address(this)]= _balances[address(this)].add(allFee);
            emit Transfer(_msgSender(), recipient, tTransferAmount);
            emit Transfer(_msgSender(), address(this), allFee);
 
        }   else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);

            emit Transfer(_msgSender(), recipient, amount);
        }
    }

    function distributionToWallets(address from, address to) private {
        
        uint256 contractTokenBalance = balanceOf(address(this));

        if (
            from != pancakePair &&
            distributionStatus &&
            !(from == address(this) && to == address(pancakePair)) // swap 1 time
        ) {
            contractTokenBalance = balanceOf(address(this));

            // approve contract
            _approve(
                address(this),
                address(pancakeRouter),
                contractTokenBalance
            );

            // now is to lock Token into staking pool
            Utils.swapTokensForEth(
                address(pancakeRouter),
                contractTokenBalance
            );

            // how much BNB did we just swap into?

            uint256 totalBalance = address(this).balance;

            WalletMT.transfer(totalBalance);

        }
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