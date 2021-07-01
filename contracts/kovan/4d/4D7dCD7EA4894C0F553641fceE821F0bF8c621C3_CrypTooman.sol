// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.0;

import "ILendingPoolAddressesProvider.sol";
import "ILendingPool.sol";
import "IAToken.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "CrypToomanInternalWallet.sol";

contract CrypTooman is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* 1 crypTooman = 100 crypQeran = 1,000 crypAbbasi = 10,000 crypDinar (all balances are stored in crypDinar) */
    uint8 constant _decimals = 4;
    uint8 constant _maxDepositPriceDiscrepancyTolerancePerThousand = 30;
    uint8 constant _maxWithdrawalFeePerThousand = 5;

    byte constant FLAG_USDT_DEPOSIT = 0x01;
    byte constant FLAG_USDC_DEPOSIT = 0x02;
    byte constant FLAG_DAI_DEPOSIT = 0x04;
    byte constant FLAG_BUSD_DEPOSIT = 0x08;
    byte constant FLAG_TUSD_DEPOSIT = 0x10;

    ////////////////////////////// Ethereum Kovan addresses ////////////////////////////////////////

    // stablecoin addresses (from https://aave.github.io/aave-addresses/kovan.json)
    address public constant ADDRESS_USDT = 0x13512979ADE267AB5100878E2e0f485B568328a4;// 6 decimals
    address public constant ADDRESS_USDC = 0xe22da380ee6B445bb8273C81944ADEB6E8450422;// 6 decimals
    address public constant ADDRESS_BUSD = 0x4c6E1EFC12FDfD568186b7BAEc0A43fFfb4bCcCf;// 18 decimals
    address public constant ADDRESS_DAI = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;// 18 decimals
    address public constant ADDRESS_TUSD = 0x016750AC630F711882812f24Dba6c95b9D35856d;// 18 decimals

    // aToken addresses
    address public constant ADDRESS_AAVE_USDT = 0xFF3c8bc103682FA918c954E84F5056aB4DD5189d;
    address public constant ADDRESS_AAVE_USDC = 0xe12AFeC5aa12Cf614678f9bFeeB98cA9Bb95b5B0;
    address public constant ADDRESS_AAVE_BUSD = 0xfe3E41Db9071458e39104711eF1Fa668bae44e85;
    address public constant ADDRESS_AAVE_DAI = 0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8;
    address public constant ADDRESS_AAVE_TUSD = 0x39914AdBe5fDbC2b9ADeedE8Bcd444b20B039204;

    // lending pool address provider
    address public constant ADDRESS_LENDING_POOL_ADDR_PROVIDER = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;

    ////////////////////////////////////////////////////////////////////////////////////////////////////

    // retrieve LendingPool address
    ILendingPoolAddressesProvider constant _provider = ILendingPoolAddressesProvider(address(ADDRESS_LENDING_POOL_ADDR_PROVIDER));

    mapping (address => address) private _userInternalWallets;
    mapping (address => bool) private _userMutex;
    mapping (address => uint256) private _lockedUSDBalances;
    uint16 private _AAVEReferralCode;
    uint256 private _USDPrice = 250000;
    uint8 private _depositPriceDiscrepancyTolerancePerThousand = 1;
    uint8 private _withdrawalFeePerThousand = 5;
    byte private _USDDepositStatus = FLAG_USDT_DEPOSIT | FLAG_USDC_DEPOSIT | FLAG_DAI_DEPOSIT | FLAG_BUSD_DEPOSIT | FLAG_TUSD_DEPOSIT;

    modifier lockable(address userAddress) {
        require(!_userMutex[userAddress], "CrypTooman: mutex is locked");
        _userMutex[userAddress] = true;
        _;
        _userMutex[userAddress] = false;
    }

    event USDTransfer(address indexed from, address indexed to, address indexed stableCoin, uint256 USDValue, uint256 USDPrice, uint256 transferAmountCrypDinar);

    constructor() ERC20("CrypTooman", "CTMN") public {
        _setupDecimals(_decimals);
    }

    function lockedUSDBalance() public view returns (uint256) {
        // returned amount has 18 decimals
        return _lockedUSDBalances[ADDRESS_USDT].mul(10**12)//12: 18-6
                .add(_lockedUSDBalances[ADDRESS_USDC].mul(10**12))//12: 18-6
                .add(_lockedUSDBalances[ADDRESS_BUSD])
                .add(_lockedUSDBalances[ADDRESS_TUSD])
                .add(_lockedUSDBalances[ADDRESS_DAI]);
    }

    function lockedUSDBalance(address stableCoinAddress) public view returns (uint256) {
        return _lockedUSDBalances[stableCoinAddress];
    }

    function developmentWithdraw(address recipient, uint256 amountUSD, address stableOrAToken) public onlyOwner {
        address aToken = aTokenAddressOf(stableOrAToken);
        if(aToken == address(0))
        {// aToken address is given, so transfer it
            IAToken(stableOrAToken).transfer(recipient, amountUSD);
        }
        else
        {// stableCoin address is given, so withdraw it
            ILendingPool(_provider.getLendingPool()).withdraw(stableOrAToken, amountUSD, recipient);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || balanceOf(from) >= amount, "CrypTooman: transfer amount exceeds balance");
        require(from != to, "CrypTooman: source and destination accounts can't be the same");
    }

    function setUSDPrice(uint256 USDPrice_) public onlyOwner {
        _USDPrice = USDPrice_;
    }

    function getUSDPrice() public view returns (uint256) {
        return _USDPrice;
    }

    function setAAVEReferralCode(uint16 AAVEReferralCode_) public onlyOwner {
        _AAVEReferralCode = AAVEReferralCode_;
    }

    function getAAVEReferralCode() public view onlyOwner returns (uint16) {
        return _AAVEReferralCode;
    }

    function setUSDDepositingStatus(byte USDDepositStatus_) public onlyOwner {
        _USDDepositStatus = USDDepositStatus_;
    }

    function getUSDDepositingStatus() public view returns (byte) {
        return _USDDepositStatus;
    }

    function setDepositPriceDiscrepancyTolerancePerThousand(uint8 depositPriceDiscrepancyTolerancePerThousand_) public onlyOwner {
        require(depositPriceDiscrepancyTolerancePerThousand_ <= _maxDepositPriceDiscrepancyTolerancePerThousand, "CrypTooman: depositPriceDiscrepancyTolerance is out of range");
        _depositPriceDiscrepancyTolerancePerThousand = depositPriceDiscrepancyTolerancePerThousand_;
    }

    function getDepositPriceDiscrepancyTolerancePerThousand() public view returns(uint8) {
        return _depositPriceDiscrepancyTolerancePerThousand;
    }

    function setWithdrawalFeePerThousand(uint8 withdrawalFeePerThousand_) public onlyOwner {
        require(withdrawalFeePerThousand_ <= _maxWithdrawalFeePerThousand, "CrypTooman: withdrawalFee is out of range");
        _withdrawalFeePerThousand = withdrawalFeePerThousand_;
    }

    function getWithdrawalFeePerThousand() public view returns(uint8) {
        return _withdrawalFeePerThousand;
    }

    function getTradeParams() public view returns(uint256, uint8, uint8, byte) {
        return (_USDPrice, _depositPriceDiscrepancyTolerancePerThousand, _withdrawalFeePerThousand, _USDDepositStatus);
    }

    function aTokenAddressOf(address stableCoinAddress) pure internal returns (address) {
        if(stableCoinAddress == ADDRESS_USDT) {
            return ADDRESS_AAVE_USDT;
        }
        if(stableCoinAddress == ADDRESS_USDC) {
            return ADDRESS_AAVE_USDC;
        }
        if(stableCoinAddress == ADDRESS_DAI) {
            return ADDRESS_AAVE_DAI;
        }
        if(stableCoinAddress == ADDRESS_BUSD) {
            return ADDRESS_AAVE_BUSD;
        }
        if(stableCoinAddress == ADDRESS_TUSD) {
            return ADDRESS_AAVE_TUSD;
        }
        return address(0);
    }

    function depositUSDT(uint256 amountUSD, uint256 USDPrice) public returns (uint256) {
        require((_USDDepositStatus & FLAG_USDT_DEPOSIT) == FLAG_USDT_DEPOSIT, "CrypTooman: dipositing is disabled");
        return depositUSD(ADDRESS_USDT, 6, _msgSender(), amountUSD, USDPrice);
    }

    function depositUSDC(uint256 amountUSD, uint256 USDPrice) public returns (uint256) {
        require((_USDDepositStatus & FLAG_USDC_DEPOSIT) == FLAG_USDC_DEPOSIT, "CrypTooman: dipositing is disabled");
        return depositUSD(ADDRESS_USDC, 6, _msgSender(), amountUSD, USDPrice);
    }

    function depositDAI(uint256 amountUSD, uint256 USDPrice) public returns (uint256) {
        require((_USDDepositStatus & FLAG_DAI_DEPOSIT) == FLAG_DAI_DEPOSIT, "CrypTooman: dipositing is disabled");
        return depositUSD(ADDRESS_DAI, 18, _msgSender(), amountUSD, USDPrice);
    }

    function depositBUSD(uint256 amountUSD, uint256 USDPrice) public returns (uint256) {
        require((_USDDepositStatus & FLAG_BUSD_DEPOSIT) == FLAG_BUSD_DEPOSIT, "CrypTooman: dipositing is disabled");
        return depositUSD(ADDRESS_BUSD, 18, _msgSender(), amountUSD, USDPrice);
    }

    function depositTUSD(uint256 amountUSD, uint256 USDPrice) public returns (uint256) {
        require((_USDDepositStatus & FLAG_TUSD_DEPOSIT) == FLAG_TUSD_DEPOSIT, "CrypTooman: dipositing is disabled");
        return depositUSD(ADDRESS_TUSD, 18, _msgSender(), amountUSD, USDPrice);
    }

    function depositUSD(address stableCoin, uint256 scDecimals, address depositor, uint256 amountUSD, uint256 USDPrice) internal lockable(depositor) returns (uint256) {
        require(amountUSD >= 10**scDecimals /*&& amountUSD.mod(10**scDecimals) == 0*/, "CrypTooman: amountUSD must be at least 1");

        require(USDPrice >= _USDPrice.mul(uint256(1000).sub(_depositPriceDiscrepancyTolerancePerThousand)).div(1000) &&
            USDPrice <= _USDPrice.mul(uint256(1000).add(_depositPriceDiscrepancyTolerancePerThousand)).div(1000), "CrypTooman: USDPrice is out of allowed range");

        if(_userInternalWallets[depositor] == address(0))
        {
            _userInternalWallets[depositor] = address(new CrypToomanInternalWallet());
        }

        // uint256 USDPrice = getUSDPrice();
        uint256 amountCrypDinar = USDPrice.mul(amountUSD).div(10**scDecimals);
        _mint(depositor, amountCrypDinar);

        CrypToomanInternalWallet(_userInternalWallets[depositor]).depositUSD(stableCoin, amountUSD, USDPrice);

        IERC20 depositingStableCoin = IERC20(stableCoin);
        depositingStableCoin.safeTransferFrom(depositor, address(this), amountUSD);

        // depositing asset on AAVE on behalf of depositor
        address lendingPoolAddress = _provider.getLendingPool();
        depositingStableCoin.approve(lendingPoolAddress, amountUSD);
        ILendingPool(lendingPoolAddress).deposit(stableCoin, amountUSD, _userInternalWallets[depositor], _AAVEReferralCode);

        // updating USDPrice
        uint256 totalLockedUSDBalance = lockedUSDBalance();
        uint256 scaledAmountUSD = amountUSD.mul(10**(uint256(18).sub(scDecimals)));
        _USDPrice = _USDPrice.mul(totalLockedUSDBalance).add(USDPrice.mul(scaledAmountUSD)).div(totalLockedUSDBalance.add(scaledAmountUSD));

        // updating lockedUSDBalance
        _lockedUSDBalances[stableCoin] = _lockedUSDBalances[stableCoin].add(amountUSD);

        return amountCrypDinar;
    }

    function avgDepositPriceOf(address account, address stableCoin) public view returns (uint256) {
        if(_userInternalWallets[account] == address(0))
        {
            return 0;
        }
        return CrypToomanInternalWallet(_userInternalWallets[account]).getAvgDepositPrice(stableCoin);
    }

    function depositBalanceOf(address account, address stableCoin) public view returns (uint256) {
        if(_userInternalWallets[account] == address(0))
        {
            return 0;
        }
        return CrypToomanInternalWallet(_userInternalWallets[account]).getDepositBalance(stableCoin);
    }

    function currentBalanceOf(address account, address stableCoin) public view returns (uint256) {
        address userInternalWalletAddress = _userInternalWallets[account];
        if(userInternalWalletAddress == address(0))
        {
            return 0;
        }
        address aToken = aTokenAddressOf(stableCoin);
        if(aToken == address(0))
        {
            return 0;
        }
        return IAToken(aToken).balanceOf(userInternalWalletAddress);//.add(IERC20(stableCoin).balanceOf(userInternalWalletAddress));
    }

    function detailedBalanceOf(address account, address stableCoin) public view returns (uint256, uint256, uint256, uint256, uint256) {
        address userInternalWalletAddress = _userInternalWallets[account];
        address aToken = aTokenAddressOf(stableCoin);

        return (
            userInternalWalletAddress == address(0) ? 0 : CrypToomanInternalWallet(userInternalWalletAddress).getDepositBalance(stableCoin),
            userInternalWalletAddress == address(0) ? 0 : CrypToomanInternalWallet(userInternalWalletAddress).getAvgDepositPrice(stableCoin),
            aToken == address(0) || userInternalWalletAddress == address(0) ? 0 : IAToken(aToken).balanceOf(userInternalWalletAddress),
            IERC20(stableCoin).balanceOf(account),
            IERC20(stableCoin).allowance(account, address(this))
        );
    }

    function withdrawUSDT(uint256 amountUSD) public returns(uint256) {
        return withdrawUSD(ADDRESS_USDT, 6, _msgSender(), amountUSD);
    }

    function withdrawUSDC(uint256 amountUSD) public returns(uint256) {
        return withdrawUSD(ADDRESS_USDC, 6, _msgSender(), amountUSD);
    }

    function withdrawDAI(uint256 amountUSD) public returns(uint256) {
        return withdrawUSD(ADDRESS_DAI, 18, _msgSender(), amountUSD);
    }

    function withdrawBUSD(uint256 amountUSD) public returns(uint256) {
        return withdrawUSD(ADDRESS_BUSD, 18, _msgSender(), amountUSD);
    }

    function withdrawTUSD(uint256 amountUSD) public returns(uint256) {
        return withdrawUSD(ADDRESS_TUSD, 18, _msgSender(), amountUSD);
    }

    function withdrawUSD(address stableCoin, uint256 scDecimals, address withdrawer, uint256 amountUSD) internal lockable(withdrawer) returns (uint256){
        require(_userInternalWallets[withdrawer] != address(0), "CrypTooman: internal wallet not initialized");
        CrypToomanInternalWallet wallet = CrypToomanInternalWallet(_userInternalWallets[withdrawer]);
        require(amountUSD > 0 && amountUSD <= wallet.getDepositBalance(stableCoin), "CrypTooman: USD balance is not enough for requested stable coin");

        uint256 withdrawerBalanceCrypDinar = balanceOf(withdrawer);
        uint256 avgDepositUSDPrice = wallet.getAvgDepositPrice(stableCoin);
        uint256 withdrawalAmountCrypDinar = amountUSD.mul(avgDepositUSDPrice).div(10**scDecimals);
        require(withdrawerBalanceCrypDinar >= withdrawalAmountCrypDinar && withdrawalAmountCrypDinar > 0 && withdrawalAmountCrypDinar <= totalSupply(), "CrypTooman: account balance is not enough or withdrawal amount is too low");
        /*if(withdrawalAmountCrypDinar > totalSupply())
        {// to cover possible tiny division data losses
            withdrawalAmountCrypDinar = totalSupply();
        }*/
        _burn(withdrawer, withdrawalAmountCrypDinar);

        // it should never happens, only for re-assurance
        require(_lockedUSDBalances[stableCoin] >= amountUSD, "CrypTooman: insufficient balance of requested stable coin at this time");
        _lockedUSDBalances[stableCoin] = _lockedUSDBalances[stableCoin].sub(amountUSD);

        (uint256 payableAmountUSD, /*uint256 withdrawalFeeUSD*/) = wallet.withdrawUSD(stableCoin, aTokenAddressOf(stableCoin), amountUSD, uint256(_withdrawalFeePerThousand));
        ILendingPool(_provider.getLendingPool()).withdraw(stableCoin, payableAmountUSD, withdrawer);

        return payableAmountUSD;
    }

    function transferUSDT(address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) public {
        transferUSD(ADDRESS_USDT, 6, _msgSender(), recipient, amountUSD, transferEquivalentCrypTooman);
    }

    function transferUSDC(address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) public {
        transferUSD(ADDRESS_USDC, 6, _msgSender(), recipient, amountUSD, transferEquivalentCrypTooman);
    }

    function transferDAI(address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) public {
        transferUSD(ADDRESS_DAI, 18, _msgSender(), recipient, amountUSD, transferEquivalentCrypTooman);
    }

    function transferBUSD(address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) public {
        transferUSD(ADDRESS_BUSD, 18, _msgSender(), recipient, amountUSD, transferEquivalentCrypTooman);
    }

    function transferTUSD(address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) public {
        transferUSD(ADDRESS_TUSD, 18, _msgSender(), recipient, amountUSD, transferEquivalentCrypTooman);
    }

    /**
     * only deposited amount (and not its profit) can be transferred
     **/
    function transferUSD(address stableCoin, uint256 scDecimals, address sender, address recipient, uint256 amountUSD, bool transferEquivalentCrypTooman) internal lockable(sender) {
        CrypToomanInternalWallet senderWallet = CrypToomanInternalWallet(_userInternalWallets[sender]);
        require(address(senderWallet) != address(0) && amountUSD > 0 && amountUSD <= senderWallet.getDepositBalance(stableCoin), "CrypTooman: USD balance is not enough for requested stable coin");

        if(_userInternalWallets[recipient] == address(0))
        {
            _userInternalWallets[recipient] = address(new CrypToomanInternalWallet());
        }

        uint256 senderAvgDepositPrice = senderWallet.burnUSD(stableCoin, aTokenAddressOf(stableCoin), _userInternalWallets[recipient], amountUSD);
        uint256 transferAmountCrypDinar = 0;
        if(transferEquivalentCrypTooman)
        {
            transferAmountCrypDinar = senderAvgDepositPrice.mul(amountUSD).div(10**scDecimals);
            require(balanceOf(sender) >= transferAmountCrypDinar, "CrypTooman: crypTooman balance is not sufficient");
            _transfer(sender, recipient, transferAmountCrypDinar);
        }

        CrypToomanInternalWallet(_userInternalWallets[recipient]).mintUSD(stableCoin, amountUSD, senderAvgDepositPrice);

        emit USDTransfer(sender, recipient, stableCoin, amountUSD, senderAvgDepositPrice, transferAmountCrypDinar);
    }

    function compoundUSDT() public returns (uint256, uint256) {
        return compoundUSD(ADDRESS_USDT, 6, _msgSender());
    }

    function compoundUSDC() public returns (uint256, uint256) {
        return compoundUSD(ADDRESS_USDC, 6, _msgSender());
    }

    function compoundDAI() public returns (uint256, uint256) {
        return compoundUSD(ADDRESS_DAI, 18, _msgSender());
    }

    function compoundBUSD() public returns (uint256, uint256) {
        return compoundUSD(ADDRESS_BUSD, 18, _msgSender());
    }

    function compoundTUSD() public returns (uint256, uint256) {
        return compoundUSD(ADDRESS_TUSD, 18, _msgSender());
    }

    function compoundUSD(address stableCoin, uint256 scDecimals, address userAddress) internal lockable(userAddress) returns (uint256, uint256) {
        CrypToomanInternalWallet wallet = CrypToomanInternalWallet(_userInternalWallets[userAddress]);
        require(address(wallet) != address(0), "CrypTooman: unknown user wallet");

        IAToken aToken = IAToken(aTokenAddressOf(stableCoin));
        require(address(aToken) != address(0), "CrypTooman: invalid stable coin");

        uint256 depositAmount = wallet.getDepositBalance(stableCoin);
        uint256 aTokenBalance = aToken.balanceOf(address(wallet));
        require(aTokenBalance > depositAmount, "CrypTooman: no balance to compound");

        uint256 compoundAmountUSD = aTokenBalance.sub(depositAmount);
        uint256 mintAmountCrypDinar = compoundAmountUSD.mul(_USDPrice).div(10**scDecimals);

        require(mintAmountCrypDinar > 0, "CrypTooman: compoundable amount is too low");
        _mint(userAddress, mintAmountCrypDinar);
        wallet.mintUSD(stableCoin, compoundAmountUSD, _USDPrice);

        return (mintAmountCrypDinar, compoundAmountUSD);
    }

}