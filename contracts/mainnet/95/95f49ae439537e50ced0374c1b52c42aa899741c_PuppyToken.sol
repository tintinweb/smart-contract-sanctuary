pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./UsingSmartStateProtection.sol";

contract PuppyToken is IERC20, Ownable, UsingSmartStateProtection {

    address UniswapPair;
    IUniswapV2Router02 UniswapV2Router;
    address internal protection_service;

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 public constant _tTotal = 1e15 * 1e9; //1 quadrillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    bool public _feesEnabled = true;
    event FeesChanged(bool status);

    string private _name = 'Puppies Network';
    string private _symbol = 'PPN';
    uint8 private _decimals = 9;
    

    constructor () {
        _rOwned[_msgSender()] = _rTotal;
        UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        UniswapPair = IUniswapV2Factory(UniswapV2Router.factory())
            .createPair(address(this), UniswapV2Router.WETH());
        setPair(UniswapPair);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function disableFees() external onlyOwner {
        _feesEnabled = false;
        emit FeesChanged(false);
    }

    function enableFees() external onlyOwner {
        _feesEnabled = true;
        emit FeesChanged(true);
    }

    function reflect(uint256 tAmount) external {
        require(_feesEnabled, "Not allowed");
        address sender = _msgSender();
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_feesEnabled) {
            if (sender != address(this)) {
                _beforeTokenTransfer(sender, recipient, amount);
            }
            if (recipient == UniswapPair && sender != address(this)) {
                _transferWithFee(sender, recipient, amount);
            } else {
                 _transferWithoutFee(sender, recipient, amount);
            }
        } else {
            if (sender != address(this)) {
                _beforeTokenTransfer(sender, recipient, amount);
            }
            _transferWithoutFee(sender, recipient, amount);
        }
    }

    function _transferWithFee(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _liquify(rFee);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferWithoutFee(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount + rFee; 
        emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee * 2 / 5;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount * 5 / 100;
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        return (_rTotal, _tTotal);
    }
    
    function _liquify(uint256 rFee) private {
        _rOwned[address(this)] += rFee * 3 / 5;
        uint _tokenAmount = tokenFromReflection(rFee * 3 / 5);
        uint half = _tokenAmount / 2;
        uint anotherHalf = _tokenAmount - half;
        _approve(address(this), address(UniswapV2Router), half);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();
        uint balanceBefore = address(this).balance;
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            half,
            0, //accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint balanceAfter = address(this).balance;
        _approve(address(this), address(UniswapV2Router), anotherHalf);
        UniswapV2Router.addLiquidityETH{value: balanceAfter - balanceBefore}(
            address(this),
            anotherHalf,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function addLiquidityETH(
        uint _amountTokenDesired,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to,
        uint _deadline
    ) external onlyOwner {
        _approve(address(this), address(UniswapV2Router), _amountTokenDesired);
        UniswapV2Router.addLiquidityETH{value: _amountETHMin}(
            address(this),
            _amountTokenDesired,
            _amountTokenMin,
            _amountETHMin,
            _to,
            _deadline
        );
    }
    
    function addLiquidityETHAndEnableProtection(
        uint _amountTokenDesired,
        uint _amountTokenMin,
        uint _amountETHMin,
        address _to,
        uint _deadline,
        uint _IDONumber)
        external payable onlyOwner {
            _approve(address(this), address(UniswapV2Router), _amountTokenDesired);
            UniswapV2Router.addLiquidityETH{value: msg.value}(
                address(this),
                _amountTokenDesired,
                _amountTokenMin,
                _amountETHMin,
                _to,
                _deadline);
            ps().liquidityAdded(
                block.number,
                _amountTokenMin,
                IDOFactoryEnabled(),
                _IDONumber,
                IDOFactoryBlocks(),
                IDOFactoryParts(),
                firstBlockProtectionEnabled(),
                blockProtectionEnabled(),
                blocksToProtect(),
                address(this));
            enableProtection();
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal {
        protectionBeforeTokenTransfer(_from, _to, _amount);
    }

    function isAdmin() internal view override returns(bool) {
        return msg.sender == owner() || msg.sender == address(this); //replace with correct value
    }

    function setProtectionService(address _ps) external onlyOwner {
        protection_service = _ps;
    }

    function protectionService() internal view override returns(address) {
        return protection_service;
    }

    function firstBlockProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }

    function blockProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function blocksToProtect() internal pure override returns(uint) {
        return 69; //replace with correct value
    }
    
    function amountPercentProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function amountPercentProtection() internal pure override returns(uint) {
        return 5; //replace with correct value
    }
    
    function IDOFactoryEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }

    function priceChangeProtectionEnabled() internal pure override returns(bool) {
        return false; //set true or false
    }
    
    function priceProtectionPercent() internal pure override returns(uint) {
        return 5; //replace with correct value
    }
    
    function rateLimitProtectionEnabled() internal pure override returns(bool) {
        return true; //set true or false
    }
    
    function rateLimitProtection() internal pure override returns(uint) {
        return 60; //replace with correct value
    }
    
    function IDOFactoryBlocks() internal pure override returns(uint) {
        return 30; //replace with correct value
    }

    function IDOFactoryParts() internal pure override returns(uint) {
        return 3; //replace with correct value
    }
    
    function blockSuspiciousAddresses() internal pure override returns(bool) {
        return true; //set true or false
    }
}