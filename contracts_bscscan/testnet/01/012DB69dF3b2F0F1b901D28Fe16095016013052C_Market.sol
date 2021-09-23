/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
pragma experimental ABIEncoderV2;

interface IProvider {

    function getUserLiquidity(address userAddress, address cTokenAddress, uint redeemAmount, uint borrowAmount)
    external view returns (uint liquidity, uint shortfall);

    function getUserStat(address userAddress)
    external view returns (uint collateralUSD, uint borrowUSD);

    function maxRedeemAllowed(address cTokenAddress, address userAddress)
    external view returns (uint maxRedeemAllowedInUSD, uint maxRedeemAllowedAmount);

    function maxBorrowAllowed(address marketContractAddress, address userAddress)
    external view returns (uint maxBorrowAllowedInUSD, uint maxBorrowAllowedAmount);

    function maxLiquidateAllowed(address marketContractAddress, address borrowerAddress)
    external view returns (uint);

    function cTokenAmountToSeize(address cTokenAddress, address assetAddress, uint amount)
    external view returns (uint cAmountToSeize);

}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IMarket {

    function deposit(uint amount) external payable returns (uint);

    function redeemCToken(address userAddress, uint cTokenAmount) external returns (uint);

    function redeemAsset(address userAddress, uint assetAmount) external returns (uint);

    function borrow(uint amount) external returns (uint);

    function repay(uint amount) external payable returns (uint);

    function repayOthers(address borrowerAddress, uint amount) external payable returns (uint);

    function liquidate(address borrowerAddress, uint amount)
    external payable returns (uint cAmountToSeize);


    function getMarketInfo()
    external view returns (address marketAddress, address marketTokenAddress, address oraclePriceAddress, uint collateralFactor);

    function getMarketTokenPrice() external view returns (uint);

    function getTotalDeposit() external view returns (uint);

    function getUserDeposit(address userAddress) external view returns (uint);

    function getTotalBorrow() external view returns (uint);

    function getUserBorrow(address userAddress) external view returns (uint);

    function getMarketTokenAddress() external view returns (address);

    function getCollateralFactor() external view returns (uint);

    function getUsageRate() external view returns (uint);

    function getBorrowRate() external view returns (uint);

    function getSupplyRate() external view returns (uint);

    function exchangeRate() external view returns (uint);


    event Deposit(address userAddress, uint amount);

    event Redeem(address userAddress, uint assetAmount, uint cTokenAmount);

    event Borrow(address userAddress, uint amount);

    event Repay(address payerAddress, address borrowerAddress, uint amount);

    event Liquidate(address borrowerAddress, uint amount);

    event ParameterSetted(address owner);

    event SetPriceSource(uint marketTokenAddress, address oraclePriceAddress);

}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

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

library SafeERC20 {
    using SafeMath for uint256;


    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, 'SafeERC20: low-level call failed');

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
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

contract Market is Ownable, IMarket, IERC20, ReentrancyGuard {

    using SafeMath for uint;

    using SafeERC20 for IERC20;

    address internal constant WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    /* ========== base part ========== */

    address private _providerAddress;

    constructor() {
        _supplyTokenName = "INR BNB";
        _supplyTokenSymbol = "iBNB";
        _decimals = 18;
    }

    function getMarketInfo()
    external override view returns (address marketAddress, address marketTokenAddress, address oraclePriceAddress, uint collateralFactor) {
        marketAddress = address(this);
        marketTokenAddress = _marketTokenAddress;
        oraclePriceAddress = _oraclePriceAddress;
        collateralFactor = _collateralFactor;
    }

    function setParameter(
        address providerAddress,
        address marketTokenAddress,
        uint collateralFactor,
        uint baseRatePerYear,
        uint multiplierPerYear,
        uint slopePerYearFirst,
        uint slopePerYearSecond,
        uint optimal,
        uint reserveFactor
    ) external onlyOwner {
        _providerAddress = providerAddress;
        _marketTokenAddress = marketTokenAddress;
        _collateralFactor = collateralFactor;
        _baseRatePerYear = baseRatePerYear;
        _multiplierPerYear = multiplierPerYear;
        _slopePerYearFirst = slopePerYearFirst;
        _slopePerYearSecond = slopePerYearSecond;
        _optimal = optimal;
        _reserveFactor = reserveFactor;
        emit ParameterSetted(msg.sender);
    }

    function setPriceSource(uint marketTokenAddress, address oraclePriceAddress) external onlyOwner {
        _oraclePriceAddress = oraclePriceAddress;
        _marketTokenPrice = marketTokenAddress;
        emit SetPriceSource(marketTokenAddress, oraclePriceAddress);
    }

    /* ========== token part ========== */

    string private _supplyTokenName;
    string private _supplyTokenSymbol;
    uint private _decimals;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint private _totalSupply;


    function name() public view returns (string memory) {
        return _supplyTokenName;
    }

    function symbol() public view returns (string memory) {
        return _supplyTokenSymbol;
    }

    function decimals() public view override returns (uint) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
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
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, 'transfer amount exceeds allowance')
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'approve from the zero address');
        require(spender != address(0), 'approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), 'transfer from the zero address');
        require(recipient != address(0), 'transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal {}

    function _mint(address account, uint amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    /* ========== market part ========== */

    uint private _collateralFactor;
    uint private _marketTokenPrice;
    address public _marketTokenAddress;
    address public _interstTokenAddress;
    address private _oraclePriceAddress;
    mapping(address => uint) private _userDepositMapping;
    mapping(address => uint) private _userBorrowMapping;
    mapping(address => uint) private _userInterestIndexMapping;
    uint private _totalDeposit;
    uint private _totalBorrow;
    uint private _totalReserves;

    function getMarketTokenPrice() external override view returns (uint) {
        return _marketTokenPrice;
    }

    function getTotalDeposit() external override view returns (uint){
        return _totalDeposit;
    }

    function getUserDeposit(address userAddress) external override view returns (uint){
        return _userDepositMapping[userAddress];
    }

    function getTotalBorrow() external override view returns (uint){
        return _totalBorrow;
    }

    function getUserBorrow(address userAddress) external override view returns (uint){
        return _userBorrowMapping[userAddress];
    }

    function getCash() public view returns (uint) {
        return _getCash();
    }

    function _getCash() internal view returns (uint) {
        return _marketTokenAddress == WBNB
        ? address(this).balance.sub(msg.value)
        : IERC20(_marketTokenAddress).balanceOf(address(this));
    }

    function getMarketTokenAddress() external override view returns (address) {
        return _marketTokenAddress;
    }

    function getCollateralFactor() external override view returns (uint) {
        return _collateralFactor;
    }

    //equals asset token divides receiption token
    function exchangeRate() public override view returns (uint) {
        if (_totalSupply == 0) return 1e4;
        return getCash().add(_totalBorrow).sub(_totalReserves).mul(1e4).div(_totalSupply);
    }

    /* ========== interest part ========== */

    uint private _baseRatePerYear;
    uint private _multiplierPerYear;
    uint private _slopePerYearFirst;
    uint private _slopePerYearSecond;
    uint private _optimal;
    uint private _reserveFactor;
    uint private _lastCalTime = block.timestamp;
    uint private _interestIndex = 1e4;

    function getUsageRate() public override view returns (uint) {
        return utilizationRate(getCash(), _totalBorrow, _totalReserves);
    }

    function getBorrowRate() public override view returns (uint) {
        if (_optimal != 0) {
            return getSlopeBorrowRate(getCash(), _totalBorrow, _totalReserves, _baseRatePerYear, _slopePerYearFirst, _slopePerYearSecond, _optimal);
        } else {
            return getLinearBorrowRate(getCash(), _totalBorrow, _totalReserves, _baseRatePerYear, _multiplierPerYear);
        }
    }

    function getSupplyRate() public override view returns (uint) {
        if (_optimal != 0) {
            return getSlopeSupplyRate(getCash(), _totalBorrow, _totalReserves, _reserveFactor, _baseRatePerYear, _slopePerYearFirst, _slopePerYearSecond, _optimal);
        } else {
            return getLinearSupplyRate(getCash(), _totalBorrow, _totalReserves, _reserveFactor, _baseRatePerYear, _multiplierPerYear);
        }
    }

    //U = TotalBorrows/TotalLiquidity
    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) private pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return borrows.mul(1e4).div(cash.add(borrows).sub(reserves)) < 1e4 ? borrows.mul(1e4).div(cash.add(borrows).sub(reserves)) : 1e4;
    }

    function getLinearBorrowRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint baseRatePerYear,
        uint multiplierPerYear
    ) private pure returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        return (utilization.mul(multiplierPerYear).div(1e4).add(baseRatePerYear)).div(365 days);
    }

    function getLinearSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor,
        uint baseRatePerYear,
        uint multiplierPerYear
    ) private pure returns (uint) {
        uint oneMinusReserveFactor = uint(1e4).sub(reserveFactor);
        uint borrowRate = getLinearBorrowRate(cash, borrows, reserves, baseRatePerYear, multiplierPerYear);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e4);
        uint utilization = utilizationRate(cash, borrows, reserves);
        return utilization.mul(rateToPool).div(1e4);
    }

    function getSlopeBorrowRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint baseRatePerYear,
        uint slopePerYearFirst,
        uint slopePerYearSecond,
        uint optimal
    ) private pure returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        if (optimal > 0 && utilization < optimal) {
            return baseRatePerYear.add(utilization.mul(slopePerYearFirst).div(optimal)).div(365 days);
        } else {
            uint ratio = utilization.sub(optimal).mul(1e18).div(uint(1e18).sub(optimal));
            return baseRatePerYear.add(slopePerYearFirst).add(ratio.mul(slopePerYearSecond).div(1e18)).div(365 days);
        }
    }

    function getSlopeSupplyRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint reserveFactor,
        uint baseRatePerYear,
        uint slopePerYearFirst,
        uint slopePerYearSecond,
        uint optimal
    ) private pure returns (uint) {
        uint oneMinusReserveFactor = uint(1e4).sub(reserveFactor);
        uint borrowRate = getSlopeBorrowRate(cash, borrows, reserves, baseRatePerYear, slopePerYearFirst, slopePerYearSecond, optimal);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e4);
        uint utilization = utilizationRate(cash, borrows, reserves);
        return utilization.mul(rateToPool).div(1e4);
    }

    function getInterestIndex() public view returns (uint) {
        return _interestIndex;
    }

    modifier calable() {
        if (block.timestamp > _lastCalTime) {
            uint borrowRate = getBorrowRate();
            uint interestFactor = borrowRate.mul(block.timestamp.sub(_lastCalTime));
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e4);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            _totalReserves = _totalReserves.add(pendingInterest.mul(_reserveFactor).div(1e4));
            _interestIndex = _interestIndex.add(interestFactor.mul(_interestIndex).div(1e4));
            _lastCalTime = block.timestamp;
        }
        _;
    }


    /* ========== operate part ========== */

    //deposit
    function deposit(uint amount) external payable override nonReentrant calable returns (uint) {
        require(amount > 0, "amount error");
        amount = _marketTokenAddress == WBNB ? msg.value : amount;
        amount = _doTransferIn(msg.sender, amount);

        uint cAmout = amount.mul(1e4).div(exchangeRate());

        _userDepositMapping[msg.sender] = _userDepositMapping[msg.sender].add(cAmout);
        _userInterestIndexMapping[msg.sender] = _interestIndex;
        _totalDeposit = _totalDeposit.add(cAmout);

        _mint(msg.sender, cAmout);
        emit Deposit(msg.sender, amount);
        return amount;
    }

    //redeem with cToken amount
    function redeemCToken(address userAddress, uint cTokenAmount) external override nonReentrant returns (uint) {
        return _redeem(userAddress, cTokenAmount, 0);
    }

    //redeem with asset amount
    function redeemAsset(address userAddress, uint assetAmount) external override nonReentrant returns (uint) {
        return _redeem(userAddress, 0, assetAmount);
    }

    //borrow
    function borrow(uint amount) external override nonReentrant calable returns (uint) {
        require(amount > 0, "amount error");
        require(getCash() >= amount, "Not enough cash");
        (, uint maxBorrowAllowedAmount) = IProvider(_providerAddress).maxBorrowAllowed(address(this), msg.sender);
        require(maxBorrowAllowedAmount >= amount, "Cannot borrow more");

        uint currentBorrow = _userBorrowMapping[msg.sender];
        _userBorrowMapping[msg.sender] = currentBorrow.mul(_interestIndex).div(_userInterestIndexMapping[msg.sender]).add(amount);
        _userInterestIndexMapping[msg.sender] = _interestIndex;
        _totalBorrow = _totalBorrow.add(amount);

        _userBorrowMapping[msg.sender] = _userBorrowMapping[msg.sender] < uint(1).mul(10 ** decimals().sub(2)) ? 0 : _userBorrowMapping[msg.sender];
        _totalBorrow = _totalBorrow < uint(1).mul(10 ** decimals().sub(2)) ? 0 : _totalBorrow;

        _doTransferOut(msg.sender, amount);
        emit Borrow(msg.sender, amount);
        return amount;
    }

    //repay
    function repay(uint amount) external payable override nonReentrant returns (uint) {
        require(amount > 0, "amount error");
        return _repay(msg.sender, msg.sender, amount);
    }

    //repay others debt
    function repayOthers(address borrowerAddress, uint amount)
    external payable override nonReentrant returns (uint) {
        require(borrowerAddress != address(0), "borrowerAddress error");
        require(_userBorrowMapping[borrowerAddress] != 0, "borrower has no debt");
        require(amount > 0, "amount error");
        return _repay(msg.sender, borrowerAddress, amount);
    }

    //liquidate
    function liquidate(address borrowerAddress, uint amount)
    external payable override nonReentrant calable returns (uint cAmountToSeize) {
        require(borrowerAddress != msg.sender, "cannot liquidate yourself");
        require(amount > 0, "amount error");
        amount = _marketTokenAddress == WBNB ? msg.value : amount;

        uint maxLiquidateAllowed = IProvider(_providerAddress).maxLiquidateAllowed(address(this), borrowerAddress);
        require(amount <= maxLiquidateAllowed, "cannot liquidate so much asset");

        amount = _repay(msg.sender, borrowerAddress, amount);
        require(amount > 0 && amount < uint(- 1), "liquidate fail");

        cAmountToSeize = IProvider(_providerAddress).cTokenAmountToSeize(address(this), _marketTokenAddress, amount);
        require(balanceOf(borrowerAddress) >= cAmountToSeize, "cannot seize borrower's asset");

        _userDepositMapping[borrowerAddress] = _userDepositMapping[borrowerAddress].sub(cAmountToSeize);
        _userDepositMapping[msg.sender] = _userDepositMapping[msg.sender].add(cAmountToSeize);
        _burn(borrowerAddress, cAmountToSeize);
        _mint(msg.sender, cAmountToSeize);

        emit Liquidate(borrowerAddress, amount);
    }

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (_marketTokenAddress == WBNB) {
            require(msg.value >= amount, "QToken: value mismatch");
            return msg.value < amount ? msg.value : amount;
        } else {
            uint balanceBefore = IERC20(_marketTokenAddress).balanceOf(address(this));
            IERC20(_marketTokenAddress).safeTransferFrom(from, address(this), amount);
            return IERC20(_marketTokenAddress).balanceOf(address(this)).sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (_marketTokenAddress == WBNB) {
            SafeERC20.safeTransferETH(to, amount);
        } else {
            IERC20(_marketTokenAddress).safeTransfer(to, amount);
        }
    }

    function _redeem(address userAddress, uint cTokenAmount, uint assetAmount) private calable returns (uint) {
        require(cTokenAmount == 0 || assetAmount == 0, "cTokenAmount or assetAmount must be zero");
        require(_totalSupply >= cTokenAmount, "not enough cToken");
        require(getCash() >= assetAmount || assetAmount == 0, "not enough cash");
        require(
            getCash() >= cTokenAmount.mul(exchangeRate()) || cTokenAmount == 0,
            "not enough cash"
        );

        uint cTokenAmountToRedeem = cTokenAmount > 0 ? cTokenAmount : assetAmount.div(exchangeRate());
        uint assetAmountToRedeem = cTokenAmount > 0 ? cTokenAmount.mul(exchangeRate()) : assetAmount;

        (,uint maxRedeemAllowedAmount) = IProvider(_providerAddress).maxRedeemAllowed(address(this), userAddress);
        require(maxRedeemAllowedAmount > 0, "not allowed redeem");

        _burn(userAddress, cTokenAmountToRedeem);
        _userDepositMapping[userAddress] = _userDepositMapping[userAddress].sub(cTokenAmount);
        _doTransferOut(userAddress, assetAmountToRedeem);

        emit Redeem(userAddress, assetAmountToRedeem, cTokenAmountToRedeem);
        return assetAmountToRedeem;
    }

    function _repay(address payerAddress, address borrowerAddress, uint amount)
    private calable returns (uint) {
        uint userBorrow = _userBorrowMapping[borrowerAddress];
        require(userBorrow >= amount, "Cannot repay more");

        amount = _doTransferIn(payerAddress, amount);
        _userBorrowMapping[borrowerAddress] = _userBorrowMapping[borrowerAddress].sub(amount);
        _totalBorrow = _totalBorrow.sub(amount);

        _userBorrowMapping[borrowerAddress] = _userBorrowMapping[borrowerAddress] < uint(1).mul(10 ** decimals().sub(2)) ? 0 : _userBorrowMapping[borrowerAddress];
        _totalBorrow = _totalBorrow < uint(1).mul(10 ** decimals().sub(2)) ? 0 : _totalBorrow;

        emit Repay(borrowerAddress, borrowerAddress, amount);
        return amount;
    }


}