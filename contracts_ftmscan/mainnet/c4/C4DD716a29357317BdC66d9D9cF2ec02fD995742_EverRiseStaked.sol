/**
 *Submitted for verification at FtmScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function latestRoundData() external view 
    returns (
        uint80 roundId, 
        int256 answer, 
        uint256 startedAt, 
        uint256 updatedAt, 
        uint80 answeredInRound
    );
}

interface IEverRise {
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalBuyVolume() external view returns (uint256);
    function totalSellVolume() external view returns (uint256);
    function totalVolume() external view returns (uint256);
    function getTotalAmountStaked() external view returns (uint256);
    function getTotalRewardsDistributed() external view returns (uint256);
    function holders() external view returns (uint256);
    function uniswapV2Pair() external view returns (address);
}
interface IEverStakeFactory is IERC20 {
    function getDepositorAddrss(address stakingAddress) external view returns (address);
}

interface IEverStake {
    function getStakeName() external view returns (string memory);
    function getAltOwner() external view returns (address payable);
    function getRemainingAmountStaked() external view returns (uint256);
    function getWithdrawAmount() external view returns (uint256);
    function getMaxAmountAllowedToWithdraw() external view returns (uint256);
    function getDepositorAddress() external view returns (address payable);
    function getDepositTokens() external view returns (uint256);
    function getLockTime() external view returns (uint256);
    function getDepositTime() external view returns (uint256);
    function getNumOfMonths() external view returns (uint256);
    function getStatus() external view returns (bool);
    function getCurrentBalance() external view returns (uint256);
    function getReflectionsBalance() external view returns (uint256);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract EverRiseStaked is Context, IERC20, Ownable {
    using SafeMath for uint256;

    event UsdOracleAddressUpdated(address prevValue, address newValue);
    event EverRiseAddressUpdated(address prevValue, address newValue);
    event EverBridgeVaultAddressUpdated(address prevValue, address newValue);
    event CoinStablePairAddressUpdated(address prevValue, address newValue);
    event EverStakeAddressUpdated(address prevValue, address newValue);

    mapping (address => address[]) public registeredContractList;
    mapping (address => mapping (address => bool)) public registeredContracts;
    address[] public allConfirmedContracts;
    mapping (address => bool) public confirmedContracts;

    uint256 public tokenDivisor;
    uint256 public coinDivisor;

    address public everRiseAddress = 0x0cD022ddE27169b20895e0e2B2B8A33B25e63579;
    IEverRise private everRise = IEverRise(everRiseAddress);

    address public everStakeAddress = 0x1490EaA0De0b2D4F9fE0E354A7D99d6C6532be84;
    IEverStakeFactory private everStake = IEverStakeFactory(everStakeAddress);

    address public everBridgeVaultAddress = 0x7D92730C33032e2770966C4912b3c9917995dC4E;

    address public pairAddress;
    IUniswapV2Pair private pair;
    address public usdOracleAddress;
    AggregatorV3Interface private usdOracle;

    address public coinStablePairAddress;
    IUniswapV2Pair private coinStablePair;
    address public wrappedCoinAddress;
    IERC20 private wrappedCoin;
    address public stableAddress;
    IERC20 private stableToken;
    uint8 private tokenDecimals;
    uint8 private coinDecimals;

    // BSC
    //     usdOracleAddress = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; Chainlink: BNB/USD Price Feed
    //     coinStablePairAddress = 0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16;  WBNB/BUSD
    // Eth
    //     usdOracleAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; Chainlink: ETH/USD Price Feed
    //     coinStablePairAddress = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;  WETH/USDC
    // Poly
    //     usdOracleAddress = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; Chainlink: MATIC/USD Price Feed
    //     coinStablePairAddress = 0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827;  WMATIC/USDC
    // AVAX
    //     usdOracleAddress = 0x0A77230d17318075983913bC2145DB16C7366156; Chainlink: AVAX/USD Price Feed
    //     coinStablePairAddress = 0xA389f9430876455C36478DeEa9769B7Ca4E3DDB1;  AVAX/USDC
    // FTM
    //     usdOracleAddress = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; Chainlink: FTM/USD Price Feed
    //     coinStablePairAddress = 0x2b4C76d0dc16BE1C31D4C1DC53bF9B45987Fc75c;  FTM/USDC

    constructor(address _usdOracleAddress, address _coinStablePairAddress) {
        require(
            _coinStablePairAddress != address(0),
            "_coinStablePairAddress should not be the zero address"
        );
        require(
            _usdOracleAddress != address(0),
            "_usdOracleAddress should not be the zero address"
        );

        usdOracleAddress = _usdOracleAddress;
        usdOracle = AggregatorV3Interface(_usdOracleAddress);

        coinStablePairAddress = _coinStablePairAddress;
        coinStablePair = IUniswapV2Pair(_coinStablePairAddress);

        init();
    }

    function init() private {
        pairAddress = everRise.uniswapV2Pair();
        pair = IUniswapV2Pair(pairAddress);
        wrappedCoinAddress = pair.token0();
        if (wrappedCoinAddress == everRiseAddress){
            wrappedCoinAddress = pair.token1();
        }

        wrappedCoin = IERC20(wrappedCoinAddress);

        stableAddress = coinStablePair.token0();
        if (stableAddress == wrappedCoinAddress){
            stableAddress = coinStablePair.token1();
        }
        
        stableToken = IERC20(stableAddress);

        tokenDecimals = everRise.decimals();
        tokenDivisor = 10 ** uint256(tokenDecimals);
        coinDecimals = wrappedCoin.decimals();
        coinDivisor = 10 ** uint256(coinDecimals);
    }

    function name() external pure returns (string memory) {
        return "EverRise Staked";
    }

    function symbol() external pure returns (string memory) {
        return "RISESTAKE";
    }

    function decimals() external view returns (uint8) {
        return tokenDecimals;
    }

    function totalSupply() external view override returns (uint256) {
        return everRise.totalSupply();
    }

    function allConfirmedContractsLength() external view returns (uint256){
        return allConfirmedContracts.length;
    }
    
    function transfer(address to, uint256 value) external pure returns (bool) {
        require(to != address(0), "to should not be the zero address");
        require(value != 0, "value should not be zero");
        
        require(false, "This is a virtual token and cannot be transferred");

        return false;
    }

    function stakingContractsRegister(address[] calldata contractAddresses) external {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            _stakingContractRegister(_msgSender(), contractAddress, false);
        }
    }

    function stakingContractsRegister(address[] calldata ownerAddresses, address[] calldata contractAddresses)
        external
        onlyOwner {
        require(ownerAddresses.length != contractAddresses.length, "ownerAddresses and contractAddresses should be same length");

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            address ownerAddress = ownerAddresses[i];
            _stakingContractRegister(ownerAddress, contractAddress, true);
        }
    }

    function stakingContractsUnregister(address[] calldata contractAddresses) external {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            address contractAddress = contractAddresses[i];
            stakingContractUnregister(contractAddress);
        }
    }

    function stakingContractRegister(address contractAddress) external {
        _stakingContractRegister(_msgSender(), contractAddress, false);
    }

    function setStakingContract(address ownerAddress, address contractAddress)
        external
        onlyOwner {
        _stakingContractRegister(ownerAddress, contractAddress, true);
    }
    
    function _stakingContractRegister(address ownerAddress, address contractAddress, bool isConfirmed) private {
        require(ownerAddress != address(0), "contractAddress should not be the zero address");
        require(contractAddress != address(0), "contractAddress should not be the zero address");
        require(contractAddress != address(this), "contractAddress not be this contract");
        
        address depositor = everStake.getDepositorAddrss(contractAddress);
        if (!registeredContracts[depositor][contractAddress]) {
            require(depositor == ownerAddress, "ownerAddress is not the depositor of this stake");

            registeredContracts[depositor][contractAddress] = true;
            registeredContractList[depositor].push(contractAddress);
        }

        if (isConfirmed && !confirmedContracts[contractAddress]) {
            allConfirmedContracts.push(contractAddress);
            confirmedContracts[contractAddress] = true;
        }
    }

    function stakingContractUnregister(address contractAddress) public {
        require(
            registeredContracts[_msgSender()][contractAddress],
            "contractAddress is not registered staking contract"
        );

        _stakingContractUnregister(_msgSender(), contractAddress, false);
    }

    function unsetStakingContract(address ownerAddress, address contractAddress)
        external
        onlyOwner {
        _stakingContractUnregister(ownerAddress, contractAddress, true);
    }
    
    function _stakingContractUnregister(address ownerAddress, address contractAddress, bool isUnconfirmed) private {
        if (registeredContracts[ownerAddress][contractAddress]){
            registeredContracts[ownerAddress][contractAddress] = false;
            address[] storage stakedList = registeredContractList[ownerAddress];

            for (uint256 i = 0; i < stakedList.length; i++) {
                if (stakedList[i] == contractAddress) {
                    stakedList[i] = stakedList[stakedList.length - 1];
                    stakedList.pop();
                    break;
                }
            }
        }

        if (isUnconfirmed && confirmedContracts[contractAddress]) {
            confirmedContracts[contractAddress] = false;
            for (uint256 i = 0; i < allConfirmedContracts.length; i++) {
                if (allConfirmedContracts[i] == contractAddress) {
                    allConfirmedContracts[i] = allConfirmedContracts[allConfirmedContracts.length - 1];
                    allConfirmedContracts.pop();
                    break;
                }
            }
        }
    }

    struct Stats {
        uint256 reservesBalance;
        uint256 liquidityToken;
        uint256 liquidityCoin;
        uint256 staked;
        uint256 aveMultiplier;
        uint256 rewards;
        uint256 volumeTransfers;
        uint256 volumeBuy;
        uint256 volumeSell;
        uint256 volumeTrade;
        uint256 bridgeVault;
        uint256 tokenPriceCoin;
        uint256 coinPriceStable;
        uint256 tokenPriceStable;
        uint256 marketCap;
        uint128 blockNumber;
        uint32 holders;
        uint8 tokenDecimals;
        uint8 coinDecimals;
        uint8 stableDecimals;
        uint8 multiplierDecimals;
    }

    function getStats() external view returns (Stats memory stats) {
        (uint256 liquidityToken,
        uint256 liquidityCoin,
        uint256 coinPriceStable,
        uint8 stableDecimals,
        uint256 tokenPriceCoin,
        uint256 tokenPriceStable) = getTokenPrices();

        uint256 buyVolume = everRise.totalBuyVolume();
        uint256 sellVolume = everRise.totalSellVolume();
        uint256 tradeVolume = buyVolume.add(sellVolume);

        uint256 totalAmountStaked = everRise.getTotalAmountStaked();
        uint256 aveMultiplier = everStake
            .totalSupply()
            .sub(everStake.balanceOf(everStakeAddress))
            .mul(10 ** 8)
            .div(totalAmountStaked);

        uint256 marketCap = tokenPriceStable.mul(everRise.totalSupply()).div(tokenDivisor);

        stats = Stats(
            everRiseAddress.balance,
            liquidityToken,
            liquidityCoin,
            totalAmountStaked,
            aveMultiplier,
            everRise.getTotalRewardsDistributed(),
            everRise.totalVolume(),
            buyVolume,
            sellVolume,
            tradeVolume,
            everRise.balanceOf(everBridgeVaultAddress),
            tokenPriceCoin,
            coinPriceStable,
            tokenPriceStable,
            marketCap,
            uint128(block.number),
            uint32(everRise.holders()),
            tokenDecimals,
            coinDecimals,
            stableDecimals,
            8
        );

        return stats;
    }

    function getTokenPrices() public view returns (
        uint256 liquidityToken,
        uint256 liquidityCoin,
        uint256 coinPriceStable,
        uint8 stableDecimals,
        uint256 tokenPriceCoin,
        uint256 tokenPriceStable) {
        liquidityToken = everRise.balanceOf(pairAddress);
        liquidityCoin = wrappedCoin.balanceOf(pairAddress);

        (coinPriceStable, stableDecimals) = getCoinPrice();
        tokenPriceCoin = liquidityCoin.mul(tokenDivisor).div(liquidityToken);

        tokenPriceStable = tokenPriceCoin.mul(coinPriceStable).div(coinDivisor);
    }
    
    function getListOfRegisteredStakes(address forAddress) external view returns (address[] memory) {
        return registeredContractList[forAddress];
    }

    struct StakeDetails {
        string stakeName;
        uint256 remainingAmountStaked;
        uint256 withdrawAmount;
        uint256 maxAmountAllowedToWithdraw;
        uint256 depositTokens;
        uint256 lockTime;
        uint256 depositTime;
        uint256 numOfMonths;
        uint256 currentBalance;
        uint256 currentBalanceStable;
        uint256 reflectionsBalance;
        address depositorAddress;
        address altOwner;
        uint8 stableDecimals;
        bool status;
        bool registration;
    }

    function getStakeDetails(address stakingAddress) external view returns (StakeDetails memory stakeDetails)
    {
        IEverStake stake = IEverStake(stakingAddress);

        (,,,uint8 stableDecimals,, uint256 tokenPriceStable) = getTokenPrices();
        uint256 currentBalance = stake.getCurrentBalance();
        uint256 currentBalanceStable = currentBalance.mul(tokenPriceStable).div(tokenDivisor);

        stakeDetails = StakeDetails(
            stake.getStakeName(),
            stake.getRemainingAmountStaked(),
            stake.getWithdrawAmount(),
            stake.getMaxAmountAllowedToWithdraw(),
            stake.getDepositTokens(),
            stake.getLockTime(),
            stake.getDepositTime(),
            stake.getNumOfMonths(),
            currentBalance,
            currentBalanceStable,
            stake.getReflectionsBalance(),
            stake.getDepositorAddress(),
            stake.getAltOwner(),
            stableDecimals,
            stake.getStatus(),
            isRegistered(_msgSender(), stakingAddress)
        );

        return stakeDetails;
    }

    function balanceOf(address account) external view returns (uint256){
        address[] storage stakedList = registeredContractList[account];
        
        uint256 balance = 0;
        for (uint256 i = 0; i < stakedList.length; i++) {
            balance = balance.add(IEverStake(stakedList[i]).getCurrentBalance());
        }

        return balance;
    }

    function isRegistered(address account, address contractAddress) public view returns (bool) {
        return registeredContracts[account][contractAddress];
    }

    function setEverBridgeVaultAddress(address _everBridgeVaultAddress)
        external
        onlyOwner
    {
        require(
            _everBridgeVaultAddress != address(0),
            "_everBridgeVaultAddress should not be the zero address"
        );
        
        emit EverBridgeVaultAddressUpdated(everBridgeVaultAddress, _everBridgeVaultAddress);

        everBridgeVaultAddress = _everBridgeVaultAddress;
    }

    function setEverRiseAddress(address _everRiseAddress)
        external
        onlyOwner
    {
        require(
            _everRiseAddress != address(0),
            "_everRiseAddress should not be the zero address"
        );

        emit EverRiseAddressUpdated(everRiseAddress, _everRiseAddress);

        everRiseAddress = _everRiseAddress;
        everRise = IEverRise(_everRiseAddress);
        
        init();
    }

    function setUsdOracleAddress(address _usdOracleAddress)
        external
        onlyOwner
    {
        require(
            _usdOracleAddress != address(0),
            "_usdOracleAddress should not be the zero address"
        );

        emit UsdOracleAddressUpdated(usdOracleAddress, _usdOracleAddress);

        usdOracleAddress = _usdOracleAddress;
        usdOracle = AggregatorV3Interface(_usdOracleAddress);
    }

    function setCoinStablePairAddress(address _coinStablePairAddress)
        external
        onlyOwner
    {
        require(
            _coinStablePairAddress != address(0),
            "_coinStablePairAddress should not be the zero address"
        );

        emit CoinStablePairAddressUpdated(coinStablePairAddress, _coinStablePairAddress);

        coinStablePairAddress = _coinStablePairAddress;
        coinStablePair = IUniswapV2Pair(_coinStablePairAddress);
        
        init();
    }

    function setEverStakeAddress(address _everStakeAddress)
        external
        onlyOwner
    {
        require(
            _everStakeAddress != address(0),
            "_everStakeAddress should not be the zero address"
        );

        emit EverStakeAddressUpdated(everStakeAddress, _everStakeAddress);

        everStakeAddress = _everStakeAddress;
        everStake = IEverStakeFactory(_everStakeAddress);
    }

    function getCoinPrice() public view returns (uint256 coinPrice, uint8 usdDecimals) {
        try usdOracle.latestRoundData() returns (
            uint80,         // roundID
            int256 price,   // price
            uint256,        // startedAt
            uint256,        // timestamp
            uint80          // answeredInRound
        ) {
            coinPrice = uint256(price);
            usdDecimals = usdOracle.decimals();
        } catch Error(string memory) {
            (coinPrice, usdDecimals) = getCoinPriceFallback();
        }
    }

    function getCoinPriceFallback() public view returns (uint256 coinPrice, uint8 usdDecimals) {
        coinPrice = stableToken
            .balanceOf(coinStablePairAddress)
            .mul(coinDivisor)
            .div(wrappedCoin.balanceOf(coinStablePairAddress));
        usdDecimals = stableToken.decimals();
    }

    // Function to receive ETH when msg.data is be empty
    // Receives ETH from uniswapV2Router when swapping
    receive() external payable {}

    // Fallback function to receive ETH when msg.data is not empty
    fallback() external payable {}
 
    function transferExternalTokens(address tokenAddress, address toAddress) external onlyOwner {
        require(tokenAddress != address(0), "Token Address can not be a zero address");
        require(toAddress != address(0), "To Address can not be a zero address");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "Balance is zero");
        IERC20(tokenAddress).transfer(toAddress, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function transferToAddressETH(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }
}