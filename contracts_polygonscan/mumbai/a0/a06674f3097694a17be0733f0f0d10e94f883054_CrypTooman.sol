// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.0;
pragma experimental ABIEncoderV2;

import "IAaveIncentivesController.sol";
import "ILendingPoolAddressesProvider.sol";
import "ILendingPool.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "CrypToomanInternalWallet.sol";

contract CrypTooman is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct StableCoin {
        address tokenAddress;
        address aTokenAddress;
        uint8 decimals;
    }

    /* 1 crypTooman = 100 crypQeran = 1,000 crypAbbasi = 10,000 crypDinar (all balances are stored in crypDinar) */
    uint8 constant _decimals = 4;
    uint8 constant _maxDepositPriceDiscrepancyTolerancePerThousand = 30;
    uint8 constant _maxWithdrawalFeePerThousand = 1;

    uint8 constant ADMIN_PERMISSION_OWN = 1;
    uint8 constant ADMIN_PERMISSION_SET_USD_PRICE = 2;
    uint8 constant ADMIN_PERMISSION_WITHDRAW = 4;
    uint8 constant ADMIN_PERMISSION_MANAGE_TRADE_PARAMS = 8;
    uint8 constant ADMIN_PERMISSION_MANAGE_ADMINS = 16;
    uint8 constant ADMIN_PERMISSION_ADD_STABLE_COIN = 32;
    
    // stablecoin addresses
    address public constant ADDRESS_USDT = 0xBD21A10F619BE90d6066c941b04e340841F1F989;// 6 decimals
    address public constant ADDRESS_USDC = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;// 6 decimals
    address public constant ADDRESS_DAI = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;// 18 decimals

    // lending pool address provider
    address public constant ADDRESS_AAVE_LENDING_POOL_ADDR_PROVIDER = 0x178113104fEcbcD7fF8669a0150721e231F0FD4B;
    address public constant ADDRESS_AAVE_INCENTIVES_CONTROLLER = address(0);

    // retrieve LendingPool address
    ILendingPoolAddressesProvider constant _provider = ILendingPoolAddressesProvider(address(ADDRESS_AAVE_LENDING_POOL_ADDR_PROVIDER));

    mapping (uint256 => StableCoin) private _stableCoins;
    mapping (address => address) private _userInternalWallets;
    mapping (address => uint256) private _lockedUSDBalances;
    mapping (address => uint8) private _admins;
    uint16 private _AAVEReferralCode;
    uint256 private _USDPrice;
    // bool private _autoUpdateUSDPrice;
    uint8 private _depositPriceDiscrepancyTolerancePerThousand;
    uint8 private _withdrawalFeePerThousand;
    uint256 private _USDDepositStatus;
    bool private _enabledAutoClaimProtocolRewards;

    bool private _isEntered = false;
    modifier nonReentrant() {
        require(!_isEntered, "CTMN: reentrancy is not allowed");
        _isEntered = true;
        _;
        _isEntered = false;
    }

    modifier onlyAdmin(uint8 requiredPermission) {
        require((_admins[_msgSender()] & requiredPermission) != 0, "CTMN: permission is denied");
        _;
    }

    event USDTransfer(address indexed from, address indexed to, address indexed stableCoin, uint256 USDValue, uint256 USDPrice, uint256 transferAmountCrypDinar);

    constructor() ERC20("CrypTooman", "CTMN") public {
        _setupDecimals(_decimals);

        _admins[_msgSender()] = ADMIN_PERMISSION_OWN | ADMIN_PERMISSION_SET_USD_PRICE | ADMIN_PERMISSION_WITHDRAW |
                                ADMIN_PERMISSION_MANAGE_TRADE_PARAMS | ADMIN_PERMISSION_MANAGE_ADMINS | ADMIN_PERMISSION_ADD_STABLE_COIN;

        setUSDPrice(280000);
        setDepositPriceDiscrepancyTolerancePerThousand(1);
        setWithdrawalFeePerThousand(0);
        // setAutoUpdateUSDPrice(false);
        setEnabledAutoClaimProtocolRewards(true);

        setUSDDepositingStatus(
            addStableCoin(ADDRESS_USDT, aTokenAddressOf(ADDRESS_USDT)) |
            addStableCoin(ADDRESS_USDC, aTokenAddressOf(ADDRESS_USDC)) |
            addStableCoin(ADDRESS_DAI, aTokenAddressOf(ADDRESS_DAI))
        );
    }

    function manageAdmin(address adminAddress, uint8 permissions) external onlyAdmin(ADMIN_PERMISSION_MANAGE_ADMINS)
    {
        require((_admins[adminAddress] & ADMIN_PERMISSION_OWN) == 0, "CTMN: owner permissions are not modifiable");
        require((permissions & ADMIN_PERMISSION_OWN) == 0, "CTMN: owning permission is not assignable");
        _admins[adminAddress] = permissions;
    }

    function addStableCoin(address stableCoinAddress, address aTokenAddress) public onlyAdmin(ADMIN_PERMISSION_ADD_STABLE_COIN) returns (uint256)
    {
        for (uint8 i=0; i<256; i++)
        {
            uint256 scId = uint256(1) << i;
            if (_stableCoins[scId].tokenAddress == address(0))
            {
                require(aTokenAddress == address(0) || ERC20(stableCoinAddress).decimals() == ERC20(aTokenAddress).decimals(), "CTMN: inconsistent aToken decimals");
                _stableCoins[scId] = StableCoin(stableCoinAddress, aTokenAddress, ERC20(stableCoinAddress).decimals());
                return scId;
            }
            else if(_stableCoins[scId].tokenAddress == stableCoinAddress)
            {
                if (_stableCoins[scId].aTokenAddress == address(0) && aTokenAddress != address(0))
                {
                    require(_stableCoins[scId].decimals == ERC20(aTokenAddress).decimals(), "CTMN: inconsistent aToken decimals");
                    _stableCoins[scId].aTokenAddress = aTokenAddress;
                    return scId;
                }
                return 0;
            }
        }
        return 0;
    }

    function scIdOf(address tokenAddress) internal view returns (uint256)
    {
        for (uint8 i=0; i<256; i++)
        {
            uint256 scId = uint256(1) << i;
            if(_stableCoins[scId].tokenAddress == tokenAddress)
            {
                return scId;
            }
            if(_stableCoins[scId].tokenAddress == address(0))
            {
                return 0;
            }
        }
        return 0;
    }

    function lockedUSDBalance() external view returns (uint256 totalBalance) {
        // returned amount has 18 decimals
        totalBalance = 0;
        for (uint8 i=0; i<256; i++)
        {
            uint256 scId = uint256(1) << i;
            if (_stableCoins[scId].tokenAddress == address(0))
            {
                break;
            }
            totalBalance = totalBalance.add(_lockedUSDBalances[_stableCoins[scId].tokenAddress].mul(10**(uint256(18).sub(_stableCoins[scId].decimals))));
        }
    }

    function withdraw(address tokenAddress, address recipient, uint256 amountUSD) external onlyAdmin(ADMIN_PERMISSION_WITHDRAW) {
        IERC20(tokenAddress).safeTransfer(recipient, amountUSD);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || balanceOf(from) >= amount, "CTMN: transfer amount exceeds balance");
        require(from != to, "CTMN: source and destination accounts can't be the same");
    }

    /*function setAutoUpdateUSDPrice(bool autoUpdateUSDPrice_) public onlyOwner {
        _autoUpdateUSDPrice = autoUpdateUSDPrice_;
    }

    function getAutoUpdateUSDPrice() external view {
        return _autoUpdateUSDPrice;
    }*/

    function setUSDPrice(uint256 USDPrice_) public onlyAdmin(ADMIN_PERMISSION_SET_USD_PRICE) {
        _USDPrice = USDPrice_;
    }

    function setAAVEReferralCode(uint16 AAVEReferralCode_) public onlyAdmin(ADMIN_PERMISSION_WITHDRAW) {
        _AAVEReferralCode = AAVEReferralCode_;
    }

    function setEnabledAutoClaimProtocolRewards(bool enabledAutoClaimProtocolRewards_) public onlyAdmin(ADMIN_PERMISSION_WITHDRAW) {
        _enabledAutoClaimProtocolRewards = enabledAutoClaimProtocolRewards_;
    }

    function claimProtocolRewards(address[] calldata aTokenAddresses, address recipient) external onlyAdmin(ADMIN_PERMISSION_WITHDRAW) returns (uint256) {
       return 0;
    }

    function claimWalletProtocolRewards(address userAddress, address aTokenAddress) public returns (uint256) {
        return 0;
    }

    function setUSDDepositingStatus(uint256 USDDepositStatus_) public onlyAdmin(ADMIN_PERMISSION_MANAGE_TRADE_PARAMS) {
        _USDDepositStatus = USDDepositStatus_;
    }

    function setDepositPriceDiscrepancyTolerancePerThousand(uint8 depositPriceDiscrepancyTolerancePerThousand_) public onlyAdmin(ADMIN_PERMISSION_MANAGE_TRADE_PARAMS) {
        require(depositPriceDiscrepancyTolerancePerThousand_ <= _maxDepositPriceDiscrepancyTolerancePerThousand, "CTMN: depositPriceDiscrepancyTolerance is out of range");
        _depositPriceDiscrepancyTolerancePerThousand = depositPriceDiscrepancyTolerancePerThousand_;
    }

    function setWithdrawalFeePerThousand(uint8 withdrawalFeePerThousand_) public onlyAdmin(ADMIN_PERMISSION_MANAGE_TRADE_PARAMS) {
        require(withdrawalFeePerThousand_ <= _maxWithdrawalFeePerThousand, "CTMN: withdrawalFee is out of range");
        _withdrawalFeePerThousand = withdrawalFeePerThousand_;
    }

    function getTradeParams() external view returns(uint256, uint8, uint8, uint256) {
        return (_USDPrice, _depositPriceDiscrepancyTolerancePerThousand, _withdrawalFeePerThousand, _USDDepositStatus);
    }

    function aTokenAddressOf(address stableCoinAddress) view internal returns (address) {
        return ILendingPool(_provider.getLendingPool()).getReserveData(stableCoinAddress).aTokenAddress;
    }

    function depositUSD(address tokenAddress, uint256 amountUSD, uint256 USDPrice, bool depositIntoAAVE) external nonReentrant returns (uint256) {
        StableCoin memory sc = _stableCoins[scIdOf(tokenAddress)];
        require(sc.tokenAddress != address(0) && sc.decimals > 0, "CTMN: invalid SC ID");

        require(amountUSD >= uint256(10)**sc.decimals /*&& amountUSD.mod(10**scDecimals) == 0*/, "CTMN: amountUSD must be at least 1");

        require(USDPrice >= _USDPrice.mul(uint256(1000).sub(_depositPriceDiscrepancyTolerancePerThousand)).div(1000) &&
            USDPrice <= _USDPrice.mul(uint256(1000).add(_depositPriceDiscrepancyTolerancePerThousand)).div(1000), "CTMN: USDPrice is out of allowed range");

        address depositor = _msgSender();
        if(_userInternalWallets[depositor] == address(0))
        {
            _userInternalWallets[depositor] = address(new CrypToomanInternalWallet());
        }

        // uint256 USDPrice = getUSDPrice();
        uint256 amountCrypDinar = USDPrice.mul(amountUSD).div(uint256(10)**sc.decimals);
        _mint(depositor, amountCrypDinar);

        CrypToomanInternalWallet(_userInternalWallets[depositor]).depositUSD(sc.tokenAddress, amountUSD, USDPrice);

        IERC20 depositingStableCoin = IERC20(sc.tokenAddress);
        if (sc.aTokenAddress != address(0) && depositIntoAAVE)
        {
            depositingStableCoin.safeTransferFrom(depositor, address(this), amountUSD);
            
            // depositing asset on AAVE on behalf of depositor
            address lendingPoolAddress = _provider.getLendingPool();
            depositingStableCoin.approve(lendingPoolAddress, amountUSD);
            ILendingPool(lendingPoolAddress).deposit(sc.tokenAddress, amountUSD, _userInternalWallets[depositor], _AAVEReferralCode);
        }
        else
        {
            depositingStableCoin.safeTransferFrom(depositor, _userInternalWallets[depositor], amountUSD);
        }

        /*if (_autoUpdateUSDPrice)
        {// updating USDPrice
            uint256 totalLockedUSDBalance = lockedUSDBalance();
            uint256 scaledAmountUSD = amountUSD.mul(10**(uint256(18).sub(sc.decimals)));
            _USDPrice = _USDPrice.mul(totalLockedUSDBalance).add(USDPrice.mul(scaledAmountUSD)).div(totalLockedUSDBalance.add(scaledAmountUSD));
        }*/
            
        // updating lockedUSDBalance
        _lockedUSDBalances[tokenAddress] = _lockedUSDBalances[tokenAddress].add(amountUSD);

        return amountCrypDinar;
    }

    function detailedBalanceOf(address account, address[] calldata tokenAddresses) external view returns (uint256[][] memory result) {
        address userInternalWalletAddress = _userInternalWallets[account];

        result = new uint256[][](tokenAddresses.length);
        for (uint256 i=0; i<tokenAddresses.length; i++)
        {
            StableCoin memory sc = _stableCoins[scIdOf(tokenAddresses[i])];
            result[i] = new uint256[](6);
            result[i][0] = userInternalWalletAddress == address(0) || sc.tokenAddress == address(0) ? 0 : CrypToomanInternalWallet(userInternalWalletAddress).getDepositBalance(sc.tokenAddress);
            result[i][1] = userInternalWalletAddress == address(0) || sc.tokenAddress == address(0) ? 0 : CrypToomanInternalWallet(userInternalWalletAddress).getAvgDepositPrice(sc.tokenAddress);
            result[i][2] = userInternalWalletAddress == address(0) || sc.aTokenAddress == address(0) ? 0 : IERC20(sc.aTokenAddress).balanceOf(userInternalWalletAddress);
            result[i][3] = IERC20(tokenAddresses[i]).balanceOf(account);
            result[i][4] = IERC20(tokenAddresses[i]).allowance(account, address(this));
            result[i][5] = sc.aTokenAddress == address(0) ? 0 : ILendingPool(_provider.getLendingPool()).getReserveData(tokenAddresses[i]).currentLiquidityRate;
        }
    }

    function withdrawUSD(address tokenAddress,  uint256 amountUSD) external nonReentrant returns (uint256) {
        StableCoin memory sc = _stableCoins[scIdOf(tokenAddress)];
        require(sc.tokenAddress != address(0) && sc.decimals > 0, "CTMN: invalid SC ID");

        address withdrawer = _msgSender();
        CrypToomanInternalWallet wallet = CrypToomanInternalWallet(_userInternalWallets[withdrawer]);
        require(address(wallet) != address(0), "CTMN: unknown user wallet");
        require(amountUSD > 0 && amountUSD <= wallet.getDepositBalance(sc.tokenAddress), "CTMN: USD balance is not enough for requested SC");

        uint256 withdrawerBalanceCrypDinar = balanceOf(withdrawer);
        uint256 avgDepositUSDPrice = wallet.getAvgDepositPrice(sc.tokenAddress);
        uint256 withdrawalAmountCrypDinar = amountUSD.mul(avgDepositUSDPrice).div(uint256(10)**sc.decimals);
        require(withdrawerBalanceCrypDinar >= withdrawalAmountCrypDinar && withdrawalAmountCrypDinar > 0 && withdrawalAmountCrypDinar <= totalSupply(), "CTMN: account balance is not enough or withdrawal amount is too low");
        
		_burn(withdrawer, withdrawalAmountCrypDinar);

        // it should never happens, only for re-assurance
        require(_lockedUSDBalances[sc.tokenAddress] >= amountUSD, "CTMN: insufficient balance of requested SC at this time");
        _lockedUSDBalances[sc.tokenAddress] = _lockedUSDBalances[sc.tokenAddress].sub(amountUSD);

        if (_enabledAutoClaimProtocolRewards && sc.aTokenAddress != address(0))
        {
            claimWalletProtocolRewards(withdrawer, sc.aTokenAddress);
        }
        (uint256 payableTokenAmount, uint256 payableATokenAmount, /*uint256 withdrawalFeeUSD*/) = wallet.withdrawUSD(sc.tokenAddress, sc.aTokenAddress, amountUSD, uint256(_withdrawalFeePerThousand));
        if (payableTokenAmount > 0)
        {
            IERC20(sc.tokenAddress).safeTransfer(withdrawer, payableTokenAmount);
        }
        if (payableATokenAmount > 0)
        {
            require(ILendingPool(_provider.getLendingPool()).withdraw(sc.tokenAddress, payableATokenAmount, withdrawer) == payableATokenAmount, "CTMN: AAVE withdraw failed");
        }
        return payableTokenAmount.add(payableATokenAmount);
    }

    /**
     * only deposited amount (and not its profit) can be transferred
     **/
    function transferUSD(address tokenAddress, address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) external nonReentrant {
        StableCoin memory sc = _stableCoins[scIdOf(tokenAddress)];
        require(sc.tokenAddress != address(0) && sc.decimals > 0, "CTMN: invalid SC ID");

        address sender = _msgSender();
        CrypToomanInternalWallet senderWallet = CrypToomanInternalWallet(_userInternalWallets[sender]);
        require(address(senderWallet) != address(0) && amountUSD > 0 && amountUSD <= senderWallet.getDepositBalance(sc.tokenAddress), "CTMN: USD balance is not enough for requested SC");

        if(_userInternalWallets[recipient] == address(0))
        {
            _userInternalWallets[recipient] = address(new CrypToomanInternalWallet());
        }
        if (_enabledAutoClaimProtocolRewards && sc.aTokenAddress != address(0))
        {
            claimWalletProtocolRewards(sender, sc.aTokenAddress);
        }
        uint256 senderAvgDepositPrice = senderWallet.transferUSD(sc.tokenAddress, sc.aTokenAddress, _userInternalWallets[recipient], amountUSD);
        uint256 transferAmountCrypDinar = 0;
        if(transferEquivalentCrypTooman)
        {
            transferAmountCrypDinar = senderAvgDepositPrice.mul(amountUSD).div(uint256(10)**sc.decimals);
            require(balanceOf(sender) >= transferAmountCrypDinar, "CTMN: CrypTooman balance is not sufficient");
            _transfer(sender, recipient, transferAmountCrypDinar);
        }

        CrypToomanInternalWallet(_userInternalWallets[recipient]).mintUSD(sc.tokenAddress, amountUSD, senderAvgDepositPrice);

        emit USDTransfer(sender, recipient, sc.tokenAddress, amountUSD, senderAvgDepositPrice, transferAmountCrypDinar);
    }

    function compoundUSD(address tokenAddress) external nonReentrant returns (uint256, uint256) {
        StableCoin memory sc = _stableCoins[scIdOf(tokenAddress)];
        require(sc.tokenAddress != address(0) && sc.decimals > 0, "CTMN: invalid SC ID");
        require(sc.aTokenAddress != address(0), "CTMN: selected SC is not compoundable");

        address userAddress = _msgSender();
        CrypToomanInternalWallet wallet = CrypToomanInternalWallet(_userInternalWallets[userAddress]);
        require(address(wallet) != address(0), "CTMN: unknown user wallet");

        uint256 depositAmount = wallet.getDepositBalance(sc.tokenAddress);
        uint256 aTokenBalance = IERC20(sc.aTokenAddress).balanceOf(address(wallet));
        require(aTokenBalance > depositAmount, "CTMN: no balance to compound");

        uint256 compoundAmountUSD = aTokenBalance.sub(depositAmount);
        uint256 mintAmountCrypDinar = compoundAmountUSD.mul(_USDPrice).div(uint256(10)**sc.decimals);

        require(mintAmountCrypDinar > 0, "CTMN: compoundable amount is too low");

        if (_enabledAutoClaimProtocolRewards)
        {
            claimWalletProtocolRewards(userAddress, sc.aTokenAddress);
        }

        _mint(userAddress, mintAmountCrypDinar);
        wallet.mintUSD(sc.tokenAddress, compoundAmountUSD, _USDPrice);
        _lockedUSDBalances[sc.tokenAddress] = _lockedUSDBalances[sc.tokenAddress].add(compoundAmountUSD);

        return (mintAmountCrypDinar, compoundAmountUSD);
    }

}