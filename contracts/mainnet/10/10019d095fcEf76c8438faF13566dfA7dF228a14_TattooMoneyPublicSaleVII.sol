/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

// TattooMoney.io Public Sale Contract - via StableCoins, ETH and wBTC
//
// USE ONLY OWN WALLET (Metamask, TrustWallet, Trezor, Ledger...)
// DO NOT SEND FROM EXCHANGES OR ANY SERVICES
//
// Use ONLY ETH network, ERC20 tokens (Not Binance/Tron/whatever!)
//
// Set approval to contract address or use USDC authorization first
//
// DO NOT SEND STABLE TOKENS DIRECTLY - IT WILL NOT COUNT THAT!
//
// Need 150k gas limit.
// Use proper pay* function

contract TattooMoneyPublicSaleVII {

    uint256 private constant DECIMALS_TAT2 = 18;
    uint256 private constant DECIMALS_DAI = 18;
    uint256 private constant DECIMALS_USD = 6;
    uint256 private constant DECIMALS_WBTC = 8;

    /// max tokens per user is 500000 as $15000 is AML limit
    uint256 public constant maxTokens = 500_000*(10**DECIMALS_TAT2);

    /// contract starts accepting transfers
    uint256 public  dateStart;

    /// hard time limit
    uint256 public  dateEnd;

    /// total collected USD
    uint256 public usdCollected;

    /// sale is limited by tokens count
    uint256 public tokensLimit;

    /// tokens sold in this sale
    uint256 public tokensSold;

    uint256 public tokensforadolar = 33_333_333_333_333_333_333;

    // addresses of tokens
    address public tat2 = 0xb487d0328b109e302b9d817b6f46Cbd738eA08C2;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public wbtcoracle = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address public ethoracle = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    address public owner;
    address public newOwner;

    bool public saleEnded;

    // deposited USD tokens per token address
    mapping(address => uint256) private _deposited;

    /// Tokens bought by user
    mapping(address => uint256) public tokensBoughtOf;

    mapping(address => bool) public KYCpassed;

    event AcceptedUSD(address indexed user, uint256 amount);
    event AcceptedWBTC(address indexed user, uint256 amount);
    event AcceptedETH(address indexed user, uint256 amount);

    string constant ERR_TRANSFER = "Token transfer failed";
    string constant ERR_SALE_LIMIT = "Token sale limit reached";
    string constant ERR_AML = "AML sale limit reached";
    string constant ERR_SOON = "TOO SOON";

    /**
    Contract constructor
    @param _owner adddress of contract owner
    @param _startDate sale start timestamp
    @param _endDate sale end timestamp
     */

    constructor(
        address _owner,
        uint256 _tokensLimit, // 39666666
        uint256 _startDate, // 15-09-2021 22:22:22 GMT (1631737342)
        uint256 _endDate //  9-11-2021  20:22:22 GMT (1636489342)
    ) {
        owner = _owner;
        tokensLimit = _tokensLimit * (10**DECIMALS_TAT2);
        dateStart = _startDate;
        dateEnd = _endDate;
    }

    /**
        Add address that passed KYC
        @param user address to mark as fee-free
     */
    function addKYCpassed(address user) external onlyOwner {
        KYCpassed[user] = true;
    }

    /**
        Remove address form KYC list
        @param user user to remove
     */
    function removeKYCpassed(address user) external onlyOwner {
        KYCpassed[user] = false;
    }

    /**
    Pay in using USDC, use approve/transferFrom
    @param amount number of USDC (with decimals)
    */
    function payUSDC(uint256 amount) external {
        require(
            INterfaces(usdc).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        _pay(msg.sender, amount );
        _deposited[usdc] += amount;
    }

    /**
    Pay in using USDT, need set approval first
    @param amount USDT amount (with decimals)
    */
    function payUSDT(uint256 amount) external {
        INterfacesNoR(usdt).transferFrom(msg.sender, address(this), amount);
        _pay(msg.sender, amount );
        _deposited[usdt] += amount;
    }

    /**
    Pay in using DAI, need set approval first
    @param amount number of DAI (with 6 decimals)
    */
    function payDAI(uint256 amount) external {
        require(
            INterfaces(dai).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        _pay(msg.sender, amount / (10**12));
        _deposited[dai] += amount;
    }

    /**
    Pay in using wBTC, need set approval first
    @param amount number of wBTC (with decimals)
    */
    function paywBTC(uint256 amount) external {
        require(
            INterfaces(wbtc).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        _paywBTC(msg.sender, amount );
        _deposited[wbtc] += amount;
    }

    //
    // accept ETH
    //

    receive() external payable {
        _payEth(msg.sender, msg.value);
    }

    function payETH() external payable {
        _payEth(msg.sender, msg.value);
    }

    /**
    Get ETH price from Chainlink.
    @return price for 1 ETH with 18 decimals
    */
    function tokensPerEth() public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = INterfaces(ethoracle).latestRoundData();
        // geting price with 18 decimals
        return uint256((uint256(answer) * tokensforadolar)/10**8);
    }

    /**
    Get BTC price from Chainlink.
    @return price for 1 BTC with 18 decimals
    */
    function tokensPerwBTC() public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = INterfaces(wbtcoracle).latestRoundData();
        // geting price with 18 decimals
        return uint256((uint256(answer) * tokensforadolar)/10**8);
    }

    /**
    How much tokens left to sale
    */
    function tokensLeft() external view returns (uint256) {
        return tokensLimit - tokensSold;
    }

    function _payEth(address user, uint256 amount) internal notEnded {
        uint256 sold = (amount * tokensPerEth()) / (10**18);
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        tokensBoughtOf[user] += sold;
        if(!KYCpassed[user]){
          require(tokensBoughtOf[user] <= maxTokens, ERR_AML);
        }
        _sendTokens(user, sold);
        emit AcceptedETH(user, amount);
    }

    function _paywBTC(address user, uint256 amount) internal notEnded {
        uint256 sold = (amount * tokensPerwBTC()) / (10**8);
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        tokensBoughtOf[user] += sold;
        if(!KYCpassed[user]){
          require(tokensBoughtOf[user] <= maxTokens, ERR_AML);
        }
        _sendTokens(user, sold);
        emit AcceptedWBTC(user, amount);
    }

    function _pay(address user, uint256 usd) internal notEnded {
        uint256 sold = (usd * tokensforadolar) / (10**6);
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        tokensBoughtOf[user] += sold;
        if(!KYCpassed[user]){
          require(tokensBoughtOf[user] <= maxTokens, ERR_AML);
        }
        _sendTokens(user, sold);
        emit AcceptedUSD(user, usd);
    }

    function _sendTokens(address user, uint256 amount) internal notEnded {
      require(
          INterfaces(tat2).transfer(user, amount),
          ERR_TRANSFER
      );
    }

    //
    // modifiers
    //

    modifier notEnded() {
        require(!saleEnded, "Sale ended");
        require(
            block.timestamp > dateStart && block.timestamp < dateEnd,
            "Too soon or too late"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for contract Owner");
        _;
    }

    /// Take out stables, wBTC  and ETH
    function takeAll() external onlyOwner {
        uint256 amt = INterfaces(usdt).balanceOf(address(this));
        if (amt > 0) {
            INterfacesNoR(usdt).transfer(owner, amt);
        }
        amt = INterfaces(usdc).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(usdc).transfer(owner, amt), ERR_TRANSFER);
        }
        amt = INterfaces(dai).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(dai).transfer(owner, amt), ERR_TRANSFER);
        }
        amt = INterfaces(wbtc).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(wbtc).transfer(owner, amt), ERR_TRANSFER);
        }
        amt = address(this).balance;
        if (amt > 0) {
            payable(owner).transfer(amt);
        }
    }

    /// we take unsold TAT2
    function TakeUnsoldTAT2() external onlyOwner {
        uint256 amt = INterfaces(tat2).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(tat2).transfer(owner, amt), ERR_TRANSFER);
        }
    }

    /// we can recover any ERC20!
    function recoverErc20(address token) external onlyOwner {
        uint256 amt = INterfaces(token).balanceOf(address(this));
        if (amt > 0) {
            INterfacesNoR(token).transfer(owner, amt); // use broken ERC20 to ignore return value
        }
    }

    /// just in case
    function recoverEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function EndSale() external onlyOwner {
        saleEnded = true;
    }

    function changeOwner(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(
            msg.sender != address(0) && msg.sender == newOwner,
            "Only NewOwner"
        );
        newOwner = address(0);
        owner = msg.sender;
    }
}

// Interfaces for contract interaction
interface INterfaces {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    // chainlink ETH/USD, ethoracle
    // answer|int256 :  304706968812 - 8 decimals

    // chainlink BTC/USD wbtcoracle
    // answer|int256 : 4419282000000 - 8 decimals

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// For tokens that do not return true on transfers eg. USDT
interface INterfacesNoR {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

// by Patrick