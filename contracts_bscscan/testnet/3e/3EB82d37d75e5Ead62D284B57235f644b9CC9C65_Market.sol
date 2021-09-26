/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
pragma experimental ABIEncoderV2;

interface IProvider {

    function addUserInBorrowMarket(address userAddress, address marketAddress) external returns (bool);

    function removeUserInBorrowMarket(address userAddress, address marketAddress) external;

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

    function cTokenAmountToSeize(address cTokenToSeizeAddress, address cTokenAddress, uint amount)
    external view returns (uint);

}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
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


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
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


library SafeToken {

    function balanceOf(address token, address user) internal view returns (uint) {
        return IERC20(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}

contract Market is Ownable, IERC20, ReentrancyGuard {

    using SafeMath for uint;
    using SafeToken for address;


    address internal constant W_TOKEN = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    /* ========== event part ========== */

    event Deposit(address userAddress, uint amount);

    event Redeem(address userAddress, uint assetAmount, uint cTokenAmount);

    event Borrow(address userAddress, uint amount);

    event Repay(address payerAddress, address borrowerAddress, uint amount);

    event Liquidate(address payerAddress,
        address borrowerAddress, address cTokenToSeizeAddress, uint amount);

    event Seize(address payerAddress, address borrowerAddress, uint cAmountToSeize);

    event ParameterSetted(address owner);

    event SetPriceSource(uint marketTokenPrice, address oraclePriceAddress);

    /* ========== base part ========== */

    address private _providerAddress;

    constructor() public {
        _supplyTokenName = "INR Receiption Coins";
        _supplyTokenSymbol = "IRC-INRT";
        _decimals = 2;
        _providerAddress = address(0x99dF139a1d2410fA0BD30Aa7917c72307Fc2fA1a);
        _marketTokenAddress = address(0x7a423d8F29Ed14D37dBDDa19f21D712162d57CB2);
    }

    function getMarketInfo() external view
    returns (address marketAddress, address marketTokenAddress, address oraclePriceAddress, uint collateralFactor) {
        marketAddress = address(this);
        marketTokenAddress = _marketTokenAddress;
        oraclePriceAddress = _oraclePriceAddress;
        collateralFactor = _collateralFactor;
    }

    function setParameter(
        uint collateralFactor,
        uint baseRatePerYear,
        uint multiplierPerYear,
        uint slopePerYearFirst,
        uint slopePerYearSecond,
        uint optimal,
        uint reserveFactor
    ) external onlyOwner {
        _collateralFactor = collateralFactor;
        _baseRatePerYear = baseRatePerYear;
        _multiplierPerYear = multiplierPerYear;
        _slopePerYearFirst = slopePerYearFirst;
        _slopePerYearSecond = slopePerYearSecond;
        _optimal = optimal;
        _reserveFactor = reserveFactor;
        emit ParameterSetted(msg.sender);
    }

    function setProvider(address providerAddress) external onlyOwner {
        _providerAddress = providerAddress;
    }

    function setMarketTokenPrice(uint marketTokenPrice) external onlyOwner {
        _marketTokenPrice = marketTokenPrice;
        emit SetPriceSource(_marketTokenPrice, _oraclePriceAddress);
    }

    function setPriceSource(address oraclePriceAddress) external onlyOwner {
        _oraclePriceAddress = oraclePriceAddress;
        emit SetPriceSource(_marketTokenPrice, _oraclePriceAddress);
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
    address private _oraclePriceAddress;
    mapping(address => uint) private _userDepositMapping;
    mapping(address => uint) private _userBorrowMapping;
    mapping(address => uint) private _userInterestIndexMapping;
    uint private _totalDeposit;
    uint private _totalBorrow;
    uint private _totalReserves;

    function getTotalReserves() external view onlyOwner returns (uint) {
        return _totalReserves;
    }

    function transferReserves(address to) external onlyOwner{
        _doTransferOut(to, _totalReserves);
    }

    function getMarketTokenPrice() external view returns (uint) {
        return _marketTokenPrice;
    }

    function getTotalDeposit() external view returns (uint){
        return _totalDeposit;
    }

    function getUserDeposit(address userAddress) external view returns (uint){
        return _userDepositMapping[userAddress];
    }

    function getUserBorrow(address userAddress) external view returns (uint) {
        return _userBorrowMapping[userAddress];
    }

    function getUserInterestIndex(address userAddress) external view returns (uint) {
        return _userInterestIndexMapping[userAddress];
    }

    function getTotalBorrow() external view returns (uint){
        return _totalBorrow;
    }


    function getCash() public view returns (uint) {
        return _getCash();
    }

    function _getCash() internal view returns (uint) {
        return _marketTokenAddress == W_TOKEN
        ? address(this).balance.sub(msg.value)
        : IERC20(_marketTokenAddress).balanceOf(address(this));
    }

    function getMarketTokenAddress() external view returns (address) {
        return _marketTokenAddress;
    }

    function getCollateralFactor() external view returns (uint) {
        return _collateralFactor;
    }

    //equals asset token divides receiption token
    function exchangeRate() public view returns (uint) {
        if (_totalSupply == 0) return 1e18;
        (uint totalBorrow, uint totalReserves,) = calc();
        return getCash().add(totalBorrow).sub(totalReserves).mul(1e18).div(_totalSupply);
    }

    function getParameterByUser(address userAddress) public view
    returns (address token, uint collateralFactor, uint exRate, uint userDeposit, uint userBorrow) {
        token = _marketTokenAddress;
        collateralFactor = _collateralFactor;
        exRate = exchangeRate();
        userDeposit = _userDepositMapping[userAddress];
        if (_userInterestIndexMapping[userAddress] != 0) {
            userBorrow = _userBorrowMapping[userAddress].mul(_interestIndex).div(_userInterestIndexMapping[userAddress]);
        }
    }

    /* ========== interest part ========== */

    uint private _baseRatePerYear;
    uint private _multiplierPerYear;
    uint private _slopePerYearFirst;
    uint private _slopePerYearSecond;
    uint private _optimal;
    uint private _reserveFactor;
    uint private _lastCalTime = block.timestamp;
    uint private _interestIndex = 1e18;

    function getUsageRate() public view returns (uint) {
        return utilizationRate(getCash(), _totalBorrow, _totalReserves);
    }

    function getBorrowRate() public view returns (uint) {
        if (_optimal != 0) {
            return getSlopeBorrowRate(getCash(), _totalBorrow, _totalReserves, _baseRatePerYear, _slopePerYearFirst, _slopePerYearSecond, _optimal);
        } else {
            return getLinearBorrowRate(getCash(), _totalBorrow, _totalReserves, _baseRatePerYear, _multiplierPerYear);
        }
    }

    function getSupplyRate() public view returns (uint) {
        uint borrowRate = getBorrowRate();
        uint oneMinusReserveFactor = uint(1e4).sub(_reserveFactor);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e4);
        uint utilization = utilizationRate(getCash(), _totalBorrow, _totalReserves);
        return utilization.mul(rateToPool).div(1e18);
    }

    //U = TotalBorrows/TotalLiquidity
    function utilizationRate(
        uint cash,
        uint borrows,
        uint reserves
    ) private pure returns (uint) {
        if (reserves >= cash.add(borrows)) return 0;
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves)) < 1e18 ?
        borrows.mul(1e18).div(cash.add(borrows).sub(reserves)) : 1e18;
    }

    function getLinearBorrowRate(
        uint cash,
        uint borrows,
        uint reserves,
        uint baseRatePerYear,
        uint multiplierPerYear
    ) private pure returns (uint) {
        uint utilization = utilizationRate(cash, borrows, reserves);
        uint borrowRatePerYear = utilization.mul(multiplierPerYear).div(1e4).add(baseRatePerYear.mul(1e14));
        require(borrowRatePerYear >= baseRatePerYear.mul(1e14), "getLinearBorrowRate error");
        return borrowRatePerYear;
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
        if (optimal > 0 && utilization < optimal.mul(1e14)) {
            uint borrowRatePerYear = baseRatePerYear.mul(1e14).add(utilization.mul(slopePerYearFirst).div(optimal));
            require(borrowRatePerYear >= baseRatePerYear.mul(1e14), "getSlopeBorrowRate error");
            return borrowRatePerYear;
        } else {
            uint ratio = utilization.sub(optimal.mul(1e14)).mul(1e18).div(uint(1e4).sub(optimal).mul(1e14));
            uint borrowRatePerYear = baseRatePerYear.mul(1e14).add(slopePerYearFirst.mul(1e14)).add(ratio.mul(slopePerYearSecond.mul(1e14)).div(1e18));
            require(borrowRatePerYear >= baseRatePerYear.mul(1e14), "getSlopeBorrowRate error");
            return borrowRatePerYear;
        }
    }

    function getInterestIndex() public view returns (uint) {
        return _interestIndex;
    }

    modifier calable() {
        if (block.timestamp > _lastCalTime) {
            uint borrowRate = getBorrowRate();
            uint interestFactor = borrowRate.mul(block.timestamp.sub(_lastCalTime)).div(365 days);
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            _totalBorrow = _totalBorrow.add(pendingInterest);
            _totalReserves = _totalReserves.add(pendingInterest.mul(_reserveFactor).div(1e4));
            _interestIndex = _interestIndex.add(interestFactor.mul(_interestIndex).div(1e18));
            _lastCalTime = block.timestamp;
        }
        _;
    }

    function calc() internal view returns (uint totalBorrow, uint totalReserve, uint accInterestIndex) {
        totalBorrow = _totalBorrow;
        totalReserve = _totalReserves;
        accInterestIndex = _interestIndex;
        if (block.timestamp > _lastCalTime && _totalBorrow > 0) {
            uint borrowRate = getBorrowRate();
            uint interestFactor = borrowRate.mul(block.timestamp.sub(_lastCalTime)).div(365 days);
            uint pendingInterest = _totalBorrow.mul(interestFactor).div(1e18);

            totalBorrow = totalBorrow.add(pendingInterest);
            totalReserve = totalReserve.add(pendingInterest.mul(_reserveFactor).div(1e4));
            accInterestIndex = accInterestIndex.add(interestFactor.mul(accInterestIndex).div(1e18));
        }
    }


    /* ========== operate part ========== */

    //deposit
    function deposit(uint amount) external payable nonReentrant calable returns (uint) {
        amount = _marketTokenAddress == W_TOKEN ? msg.value : amount;

        uint excRate = exchangeRate();
        amount = _doTransferIn(msg.sender, amount);

        uint cAmout = amount.mul(1e18).div(excRate);
        _userDepositMapping[msg.sender] = _userDepositMapping[msg.sender].add(cAmout);
        _userInterestIndexMapping[msg.sender] = _interestIndex;
        _totalDeposit = _totalDeposit.add(cAmout);

        _mint(msg.sender, cAmout);
        emit Deposit(msg.sender, amount);
        return amount;
    }

    //redeem with cToken amount
    function redeemCToken(uint cTokenAmount) external nonReentrant returns (uint) {
        return _redeem(msg.sender, cTokenAmount, 0);
    }

    //redeem with asset amount
    function redeemAsset(uint assetAmount) external nonReentrant returns (uint) {
        return _redeem(msg.sender, 0, assetAmount);
    }

    //borrow
    function borrow(uint amount) external nonReentrant calable returns (uint) {
        require(getCash() >= amount, "Not enough cash");
        (, uint maxBorrowAllowedAmount) = IProvider(_providerAddress).maxBorrowAllowed(address(this), msg.sender);
        require(maxBorrowAllowedAmount >= amount, "Cannot borrow more");

        _updateUserBorrowInfo(msg.sender, amount, 0);

        _doTransferOut(msg.sender, amount);

        emit Borrow(msg.sender, amount);
        return amount;
    }

    //repay
    function repay(uint amount) external payable nonReentrant returns (uint) {
        return _repay(msg.sender, msg.sender, _marketTokenAddress == W_TOKEN ? msg.value : amount);
    }

    //repay others debt
    function repayOthers(address borrowerAddress, uint amount)
    external payable nonReentrant returns (uint) {
        require(borrowerAddress != address(0), "borrowerAddress error");
        require(_userBorrowMapping[borrowerAddress] != 0, "borrower has no debt");
        require(amount > 0, "amount error");
        return _repay(msg.sender, borrowerAddress, _marketTokenAddress == W_TOKEN ? msg.value : amount);
    }

    //liquidate
    function liquidate(address payerAddress,
        address borrowerAddress, address cTokenToSeizeAddress, uint amount)
    external payable nonReentrant calable returns (uint cAmountToSeize) {
        require(msg.sender == _providerAddress, "can not execute from outsider");
        amount = _marketTokenAddress == W_TOKEN ? msg.value : amount;

        uint maxLiquidateAllowed = IProvider(_providerAddress).maxLiquidateAllowed(address(this), borrowerAddress);
        require(amount <= maxLiquidateAllowed, "cannot liquidate so much asset");

        amount = _repay(payerAddress, borrowerAddress, amount);
        require(amount > 0 && amount < uint(- 1), "liquidate fail");

        cAmountToSeize = IProvider(_providerAddress).cTokenAmountToSeize(cTokenToSeizeAddress, address(this), amount);
        require(IERC20(cTokenToSeizeAddress).balanceOf(borrowerAddress) >= cAmountToSeize, "cannot seize borrower's asset");
        emit Liquidate(payerAddress, borrowerAddress, cTokenToSeizeAddress, amount);
    }

    function seize(address payerAddress, address borrowerAddress, uint cAmountToSeize) external nonReentrant calable {
        require(msg.sender == _providerAddress, "can not execute from outsider");
        _userDepositMapping[borrowerAddress] = _userDepositMapping[borrowerAddress].sub(cAmountToSeize);
        _userDepositMapping[payerAddress] = _userDepositMapping[msg.sender].add(cAmountToSeize);
        _burn(borrowerAddress, cAmountToSeize);
        _mint(payerAddress, cAmountToSeize);
        emit Seize(payerAddress, borrowerAddress, cAmountToSeize);
    }

    function _doTransferIn(address from, uint amount) private returns (uint) {
        if (_marketTokenAddress == W_TOKEN) {
            require(msg.value >= amount, "value mismatch");
            return msg.value < amount ? msg.value : amount;
        } else {
            uint balanceBefore = _marketTokenAddress.balanceOf(address(this));
            _marketTokenAddress.safeTransferFrom(from, address(this), amount);
            return _marketTokenAddress.balanceOf(address(this)).sub(balanceBefore);
        }
    }

    function _doTransferOut(address to, uint amount) private {
        if (_marketTokenAddress == W_TOKEN) {
            SafeToken.safeTransferETH(to, amount);
        } else {
            _marketTokenAddress.safeTransfer(to, amount);
        }
    }

    function _redeem(address userAddress, uint cTokenAmount, uint assetAmount) private calable returns (uint) {
        require(cTokenAmount == 0 || assetAmount == 0, "cTokenAmount or assetAmount must be zero");
        require(_totalSupply >= cTokenAmount, "not enough cToken");
        require(getCash() >= assetAmount || assetAmount == 0, "not enough cash");
        require(
            getCash() >= cTokenAmount.mul(exchangeRate().div(1e18)) || cTokenAmount == 0,
            "not enough cash"
        );

        uint cTokenAmountToRedeem = cTokenAmount > 0 ? cTokenAmount : assetAmount.mul(1e18).div(exchangeRate());
        uint assetAmountToRedeem = cTokenAmount > 0 ? cTokenAmount.mul(exchangeRate()).div(1e18) : assetAmount;

        (,uint maxRedeemAllowedAmount) = IProvider(_providerAddress).maxRedeemAllowed(address(this), userAddress);
        require(maxRedeemAllowedAmount >= cTokenAmountToRedeem, "not allowed redeem");

        _burn(userAddress, cTokenAmountToRedeem);
        _userDepositMapping[userAddress] = _userDepositMapping[userAddress].sub(cTokenAmountToRedeem);
        _totalDeposit = _totalDeposit.sub(cTokenAmountToRedeem);
        _doTransferOut(userAddress, assetAmountToRedeem);

        emit Redeem(userAddress, assetAmountToRedeem, cTokenAmountToRedeem);
        return assetAmountToRedeem;
    }

    function _repay(address payerAddress, address borrowerAddress, uint amount)
    private calable returns (uint) {
        uint userBorrow = _userBorrowMapping[borrowerAddress];
        uint repayAmount = userBorrow > amount ? amount : userBorrow;
        repayAmount = _doTransferIn(payerAddress, repayAmount);

        _updateUserBorrowInfo(borrowerAddress, 0, repayAmount);

        //if send more than borrow, then refund the part
        if (_marketTokenAddress == W_TOKEN) {
            uint refundAmount = amount > repayAmount ? amount.sub(repayAmount) : 0;
            if (refundAmount > 0) {
                _doTransferOut(payerAddress, refundAmount);
            }
        }
        emit Repay(borrowerAddress, borrowerAddress, amount);
        return amount;
    }

    function _updateUserBorrowInfo(address userAddress, uint addAmount, uint subAmount) private {

        if (_userInterestIndexMapping[userAddress] == 0) {
            _userInterestIndexMapping[userAddress] = _interestIndex;
        }
        uint currentBorrow = _userBorrowMapping[userAddress];
        _userBorrowMapping[userAddress] = currentBorrow.mul(_interestIndex).div(_userInterestIndexMapping[userAddress]).add(addAmount).sub(subAmount);
        _userInterestIndexMapping[userAddress] = _interestIndex;
        _totalBorrow = _totalBorrow.add(addAmount).sub(subAmount);

        if(addAmount > 0){
            IProvider(_providerAddress).addUserInBorrowMarket(userAddress, address(this));
        }

        if(subAmount > 0){//if debt is too small, then delete it
            _userBorrowMapping[userAddress] = _userBorrowMapping[userAddress] < 10 ** decimals().sub(2) ? 0 : _userBorrowMapping[userAddress];
            _totalBorrow = _totalBorrow < 10 ** decimals().sub(2) ? 0 : _totalBorrow;
            IProvider(_providerAddress).removeUserInBorrowMarket(userAddress, address(this));
        }
    }


}