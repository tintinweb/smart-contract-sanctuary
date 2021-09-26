/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;


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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int answer,
        uint startedAt,
        uint updatedAt,
        uint80 answeredInRound
    );
}

interface IMarket {

    function deposit(uint amount) external payable returns (uint);

    function redeemCToken(address userAddress, uint cTokenAmount) external returns (uint);

    function redeemAsset(address userAddress, uint assetAmount) external returns (uint);

    function borrow(uint amount) external returns (uint);

    function repay(uint amount) external payable returns (uint);

    function repayOthers(address borrowerAddress, uint amount) external payable returns (uint);

    function liquidate(address payerAddress,
        address borrowerAddress, address cTokenToSeizeAddress, uint amount)
    external payable returns (uint cAmountToSeize);

    function seize(address payerAddress, address borrowerAddress, uint cAmountToSeize) external;




    function getMarketInfo()
    external view returns (address marketAddress, address marketTokenAddress, address oraclePriceAddress, uint collateralFactor);

    function getMarketTokenPrice() external view returns (uint);

    function getTotalDeposit() external view returns (uint);

    function getUserDeposit(address userAddress) external view returns (uint);

    function getTotalBorrow() external view returns (uint);

    function getUserBorrow(address userAddress) external view returns (uint);

    function getUserInterestIndex(address userAddress) external view returns (uint);

    function getMarketTokenAddress() external view returns (address);

    function getCollateralFactor() external view returns (uint);

    function getParameterByUser(address userAddress)
    external view returns (address token, uint collateralFactor, uint exRate, uint userDeposit, uint userBorrow);

    function getUsageRate() external view returns (uint);

    function getBorrowRate() external view returns (uint);

    function getSupplyRate() external view returns (uint);

    function exchangeRate() external view returns (uint);

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

contract MarketsProvider is Ownable {

    using SafeMath for uint;

    /* ========== event part ========== */
    event marketAdded(address contractAddress);
    event marketRemoved(address contractAddress);
    event SetCloseFactor(uint closeFactor);
    event SetLiquidationIncentive(uint liquidationIncentive);

    /* ========== base part ========== */

    uint private _ORACLE_PRICE_DECIMALS = 1e8;
    uint private _PRICE_DECIMALS = 1e4;
    //Market contract addresses
    address[] private markets;

    function addMarket(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "contractAddress error");
        for (uint i = 0; i < markets.length; i++) {
            require(markets[i] != contractAddress, " market already exist");
        }
        markets.push(contractAddress);
        emit marketAdded(contractAddress);
    }

    function removeMarket(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "contractAddress error");
        uint length = markets.length;
        for (uint i = 0; i < length; i++) {
            if (markets[i] == contractAddress) {
                markets[i] = markets[length - 1];
                markets.pop();
                emit marketRemoved(contractAddress);
                break;
            }
        }
    }

    function getMarkets() public view returns (address[] memory) {
        return markets;
    }

    function isMarketListed(address contractAddress) public view returns (bool) {
        for (uint i = 0; i < markets.length; i++) {
            if (markets[i] == contractAddress) {
                return true;
            }
        }
        return false;
    }

    /* ========== price part ========== */

    function getAssetPrice(address marketContractAddress) internal view returns (uint marketTokenPrice) {
        require(marketContractAddress != address(0), "marketContractAddress error");
        require(isMarketListed(marketContractAddress), "market not listed");
        (,, address oraclePriceAddress,) = IMarket(marketContractAddress).getMarketInfo();

        if (oraclePriceAddress != address(0)) {
            (, int price, , ,) = AggregatorV3Interface(oraclePriceAddress).latestRoundData();
            marketTokenPrice = uint(price).mul(_PRICE_DECIMALS).div(_ORACLE_PRICE_DECIMALS);
        } else {
            marketTokenPrice = IMarket(marketContractAddress).getMarketTokenPrice();
        }
        require(marketTokenPrice > 0, "marketTokenPrice error");
    }

    function getValueInUSD(address tokenAddress, uint price, uint amount) internal view returns (uint) {
        require(tokenAddress != address(0), "tokenAddress error");
        require(price != 0, "price error");
        return price.mul(amount).div(10 ** IERC20(tokenAddress).decimals());
    }

    function getAmount(address tokenAddress, uint price, uint valueInUSD) internal view returns (uint) {
        require(tokenAddress != address(0), "tokenAddress error");
        require(price != 0, "price error");
        require(valueInUSD != 0, "valueInUSD error");
        return valueInUSD.mul(10 ** IERC20(tokenAddress).decimals()).div(price);
    }

    /* ========== user part ========== */

    mapping(address => mapping(address => bool)) private _userInBorrowMarket;//record the users who borrowed from which market
    address[] private _borrowUsers;//record the users who borrowed

    function addUserInBorrowMarket(address userAddress, address marketAddress) external returns (bool) {
        require(isMarketListed(msg.sender) && isMarketListed(marketAddress), "sender or marketAddress not listed in markets");
        if(!_userInBorrowMarket[userAddress][marketAddress]){
            _userInBorrowMarket[userAddress][marketAddress] = true;
            for(uint i = 0; i < _borrowUsers.length; i++){
                if(_borrowUsers[i] == userAddress){
                    return true;
                }
            }
            _borrowUsers.push(userAddress);
        }
        return true;
    }

    function removeUserInBorrowMarket(address userAddress, address marketAddress) external {
        require(isMarketListed(msg.sender) && isMarketListed(marketAddress), "sender or marketAddress not listed in markets");
        if(_userInBorrowMarket[userAddress][marketAddress]){
            _userInBorrowMarket[userAddress][marketAddress] = false;
        }
    }

    function getUserLiquidity(address userAddress, address cTokenAddress, uint redeemAmount, uint borrowAmount)
    public view returns (uint liquidity, uint shortfall) {
        require(userAddress != address(0), "userAddress error");
        uint collateralValueInUSD;
        uint borrowValueInUSD;

        for (uint i = 0; i < markets.length; i++) {

            (uint userCollateralValueInUSD,
            uint price,
            uint userBorrowValueInUSD,
            uint cPrice,
            address tokenAddress) = _getUserLiquidity(markets[i], userAddress);

            collateralValueInUSD = collateralValueInUSD.add(userCollateralValueInUSD);
            borrowValueInUSD = borrowValueInUSD.add(userBorrowValueInUSD);

            if (markets[i] == cTokenAddress) {
                borrowValueInUSD = borrowValueInUSD.add(getValueInUSD(cTokenAddress, cPrice, redeemAmount));
                borrowValueInUSD = borrowValueInUSD.add(getValueInUSD(tokenAddress, price, borrowAmount));
            }
        }

        liquidity = collateralValueInUSD > borrowValueInUSD
        ? collateralValueInUSD.sub(borrowValueInUSD)
        : 0;
        shortfall = collateralValueInUSD > borrowValueInUSD
        ? 0
        : borrowValueInUSD.sub(collateralValueInUSD);
    }

    function _getUserLiquidity(address marketContractAddress, address userAddress)
    private view returns (uint userCollateralValueInUSD, uint price, uint userBorrowValueInUSD, uint cPrice, address tokenAddress) {
        IMarket imarket = IMarket(marketContractAddress);
        price = getAssetPrice(marketContractAddress);
        (address token, uint collateralFactor, uint exRate, uint userDeposit, uint userBorrow) = imarket.getParameterByUser(userAddress);
        tokenAddress = token;
        cPrice = price.mul(exRate).mul(collateralFactor).div(1e22);

        userCollateralValueInUSD = userCollateralValueInUSD.add(getValueInUSD(marketContractAddress, cPrice, userDeposit));
        userBorrowValueInUSD = userBorrowValueInUSD.add(getValueInUSD(tokenAddress, price, userBorrow));
    }

    function getUserStat(address userAddress)
    public view returns (uint collateralUSD, uint borrowUSD) {
        require(userAddress != address(0), "userAddress error");
        collateralUSD = 0;
        borrowUSD = 0;
        for (uint i = 0; i < markets.length; i++) {
            (uint userCollateralValueInUSD, , uint userBorrowValueInUSD, ,) = _getUserLiquidity(markets[i], userAddress);

            collateralUSD = collateralUSD.add(userCollateralValueInUSD);
            borrowUSD = borrowUSD.add(userBorrowValueInUSD);
        }
    }

    //calculate the max amount of CToken user can redeem
    function maxRedeemAllowed(address cTokenAddress, address userAddress)
    external view returns (uint maxRedeemAllowedInUSD, uint maxRedeemAllowedAmount) {
        require(cTokenAddress != address(0), "cTokenAddress error");
        require(userAddress != address(0), "userAddress error");
        require(isMarketListed(cTokenAddress), "market not listed");
        maxRedeemAllowedInUSD = 0;
        maxRedeemAllowedAmount = 0;
        (uint collateralUSD, uint borrowUSD) = getUserStat(userAddress);
        if (collateralUSD > borrowUSD) {
            uint price = getAssetPrice(cTokenAddress);
            // 			uint collateralFactor = IMarket(cTokenAddress).getCollateralFactor();
            uint cPrice = price.mul(IMarket(cTokenAddress).exchangeRate()).div(1e18);
            maxRedeemAllowedInUSD = collateralUSD.sub(borrowUSD);
            maxRedeemAllowedAmount = getAmount(cTokenAddress, cPrice, maxRedeemAllowedInUSD);
        }
    }

    //calculate the max amount of asset user can borrow
    function maxBorrowAllowed(address marketContractAddress, address userAddress)
    external view returns (uint maxBorrowAllowedInUSD, uint maxBorrowAllowedAmount) {
        require(marketContractAddress != address(0), "marketContractAddress error");
        require(userAddress != address(0), "userAddress error");
        require(isMarketListed(marketContractAddress), "market not listed");
        maxBorrowAllowedInUSD = 0;
        maxBorrowAllowedAmount = 0;
        (uint collateralUSD, uint borrowUSD) = getUserStat(userAddress);
        if (collateralUSD > borrowUSD) {
            address tokenAddress = IMarket(marketContractAddress).getMarketTokenAddress();
            uint price = getAssetPrice(marketContractAddress);
            maxBorrowAllowedInUSD = collateralUSD.sub(borrowUSD);
            maxBorrowAllowedAmount = getAmount(tokenAddress, price, maxBorrowAllowedInUSD);
        }
    }

    //calculate the max amount of asset can be liquidated
    function maxLiquidateAllowed(address marketContractAddress, address borrowerAddress)
    external view returns (uint) {
        require(marketContractAddress != address(0), "marketContractAddress error");
        require(borrowerAddress != address(0), "borrowerAddress error");
        require(isMarketListed(marketContractAddress), "market not listed");
        (, uint shortfall) = getUserLiquidity(borrowerAddress, address(0), 0, 0);
        if (shortfall == 0) return 0;
        uint userBorrowAmount = IMarket(marketContractAddress).getUserBorrow(borrowerAddress);
        uint maxCloseAmount = userBorrowAmount.mul(_closeFactor).div(1e4);
        return maxCloseAmount;
    }

    function getUserUsageRate(address userAddress) public view returns (uint) {
        require(userAddress != address(0), "userAddress error");
        (uint collateralUSD, uint borrowUSD) = getUserStat(userAddress);
        return borrowUSD.mul(1e18).div(collateralUSD);
        //U=TotalUserBorrows/TotalUserLiquidity
    }

    /* ========== market part ========== */

    function getUsageRate(address marketContractAddress) public view returns (uint) {
        require(marketContractAddress != address(0), "marketContractAddress error");
        require(isMarketListed(marketContractAddress), "market not listed");
        return IMarket(marketContractAddress).getUsageRate();
        //U=TotalBorrows/TotalLiquidity
    }

    function getMarketRate(address marketContractAddress) public view returns (uint borrowRate, uint supplyRate) {
        require(marketContractAddress != address(0), "marketContractAddress error");
        require(isMarketListed(marketContractAddress), "market not listed");
        borrowRate = IMarket(marketContractAddress).getBorrowRate();
        supplyRate = IMarket(marketContractAddress).getSupplyRate();
    }

    function getTotalStatInUSD() public view returns (uint totalBorrowInUSD, uint totalSupplyInUSD) {
        totalSupplyInUSD = 0;
        totalBorrowInUSD = 0;
        for (uint i = 0; i < markets.length; i++) {
            IMarket imarket = IMarket(markets[i]);
            uint price = getAssetPrice(markets[i]);
            address tokenAddress = imarket.getMarketTokenAddress();
            uint cPrice = price.mul(imarket.exchangeRate()).div(1e18);

            totalSupplyInUSD = totalSupplyInUSD.add(getValueInUSD(markets[i], cPrice, imarket.getTotalDeposit()));
            totalBorrowInUSD = totalBorrowInUSD.add(getValueInUSD(tokenAddress, price, imarket.getTotalBorrow()));
        }
    }


    /* ========== liquidation part ========== */
    uint public _closeFactor;
    uint public _liquidationIncentive;


    function setLiquidationParameter(uint closeFactor, uint liquidationIncentive) external onlyOwner {
        _closeFactor = closeFactor;
        _liquidationIncentive = liquidationIncentive;
        emit SetCloseFactor(closeFactor);
        emit SetLiquidationIncentive(liquidationIncentive);
    }

    //calculate the ctoken amount to seize if liquidate the amount of debt asset
    function cTokenAmountToSeize(address cTokenToSeizeAddress, address cTokenAddress, uint amount)
    external view returns (uint) {
        require(cTokenToSeizeAddress != address(0), "cTokenToSeizeAddress error");
        require(cTokenAddress != address(0), "cTokenAddress error");
        require(isMarketListed(cTokenToSeizeAddress), "cTokenToSeizeAddress market not listed");
        require(isMarketListed(cTokenAddress), "cTokenAddress market not listed");
        uint price = getAssetPrice(cTokenAddress);
        require(price != 0, "price error");
        uint cexChangeRate = IMarket(cTokenToSeizeAddress).exchangeRate();
        require(cexChangeRate != 0, "cexChangeRate error");
        uint cPrice = getAssetPrice(cTokenToSeizeAddress).mul(cexChangeRate).div(1e18);
        //
        return amount.mul(price).mul(_liquidationIncentive).div(1e4).div(cPrice);
    }

    function liquidate(address borrowerAddress, address collateralMarket, address borrowMarket, uint amount)
    external payable {
        require(borrowerAddress != msg.sender, "cannot liquidate yourself");
        require(isMarketListed(collateralMarket) && isMarketListed(borrowMarket), "collateralMarket or borrowMarket not listed");

        uint cAmountToSeize = IMarket(borrowMarket).liquidate{ value: msg.value }(
            msg.sender,
            borrowerAddress,
            collateralMarket,
            amount
        );
        IMarket(collateralMarket).seize(msg.sender, borrowerAddress, cAmountToSeize);
    }

    function monitor() external view returns (address[10] memory usersNeedLiquidate) {
        uint i = 0;
        for(uint k = 0; k < _borrowUsers.length && i < 9; k++){
            (uint collateralUSD, uint borrowUSD) = getUserStat(_borrowUsers[k]);
            if(collateralUSD < borrowUSD) {
                if(usersNeedLiquidate[i] == address(0)){
                    usersNeedLiquidate[i] = _borrowUsers[k];
                    i++;
                }
            }
        }
    }

}