/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

// BigShortBets.com sale contract - via StableCoins and ETH
//
// USE ONLY OWN WALLET (Metamask, Trezor, Ledger...)
// DO NOT SEND FROM EXCHANGES OR ANY SERVICES
//
// Use ONLY ETH network, ERC20 tokens (Not Binance/Tron/whatever!)
//
// Set approval to contract address or use USDC authorization first
//
// DO NOT SEND STABLE TOKENS DIRECTLY - IT WILL NOT COUNT THAT!
//
// send ONLY round number of USDT/USDC/DAI!
// ie 20, 500, 2000 NOT 20.1, 500.5, 2000.3
// contract will IGNORE decimals!
//
// Need 150k gas limit.
// Use proper pay* function
contract BigShortBetsSale {
    /// max tokens per user is 15000 as $15000 is AML limit
    uint256 public constant maxTokens = 15000 * 1 ether;

    /// contract starts accepting transfers
    uint256 public immutable dateStart;
    /// hard time limit
    uint256 public immutable dateEnd;

    /// total collected USD
    uint256 public usdCollected;

    /// sale is limited by tokens count
    uint256 public immutable tokensLimit;

    /// tokens sold in this sale
    uint256 public tokensSold;

    uint256 private constant DECIMALS_DAI = 18;
    uint256 private constant DECIMALS_USD = 6;

    // addresses of tokens
    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable oracle;

    address public owner;
    address public newOwner;

    bool public saleEnded;

    // deposited USD tokens per token address
    mapping(address => uint256) private _deposited;

    /// Tokens bought by user
    mapping(address => uint256) public tokensBoughtOf;

    event AcceptedUSD(address indexed user, uint256 amount);
    event AcceptedETH(address indexed user, uint256 amount);

    string constant ERR_TRANSFER = "Token transfer failed";
    string constant ERR_SALE_LIMIT = "Token sale limit reached";
    string constant ERR_AML = "AML sale limit reached";
    string constant ERR_SOON = "SOON";

    /**
    Contract constructor
    @param _owner adddress of contract owner
    @param _tokensLimit maximum tokens that can be sold (round, ie 320123)
    @param _startDate sale start timestamp
    @param _endDate sale end timestamp
    @param _usdt USDT token address
    @param _usdc USDC token address
    @param _dai DAI token address
    @param _oracle Chainlink USD/ETH oracle address
     */
    constructor(
        address _owner,
        uint256 _tokensLimit, // 3398743
        uint256 _startDate, // 15-07-2020 20:00 CEST (UTC +2)
        uint256 _endDate, // 15-08-2020 20:00 CEST (UTC +2)
        address _usdt,
        address _usdc,
        address _dai,
        address _oracle
    ) {
        owner = _owner;
        tokensLimit = _tokensLimit * 1 ether;
        dateStart = _startDate;
        dateEnd = _endDate;
        usdt = _usdt;
        usdc = _usdc;
        dai = _dai;
        oracle = _oracle;

        /**
        mainnet:
        usdt=0xdAC17F958D2ee523a2206206994597C13D831ec7;
        usdc=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        dai=0x6B175474E89094C44Da98b954EedeAC495271d0F;
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 chainlink ETH/USD oracle
        */
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
        _pay(msg.sender, amount / (10**DECIMALS_USD));
        _deposited[usdc] += amount;
    }

    /**
    Pay in using USDT, need set approval first
    @param amount USDT amount (with decimals)
    */
    function payUSDT(uint256 amount) external {
        IUsdt(usdt).transferFrom(msg.sender, address(this), amount);
        _pay(msg.sender, amount / (10**DECIMALS_USD));
        _deposited[usdt] += amount;
    }

    /**
    Pay in using DAI, need set approval first
    @param amount number of DAI (with decimals)
    */
    function payDAI(uint256 amount) external {
        require(
            INterfaces(dai).transferFrom(msg.sender, address(this), amount),
            ERR_TRANSFER
        );
        _pay(msg.sender, amount / (10**DECIMALS_DAI));
        _deposited[dai] += amount;
    }

    //
    // accept ETH
    //

    // takes about 50k gas
    receive() external payable {
        _payEth(msg.sender, msg.value);
    }

    function payETH() external payable {
        _payEth(msg.sender, msg.value);
    }

    /**
    Get ETH price from Chainlink.
    @return ETH price in USD with 18 decimals
    */
    function tokensPerEth() public view returns (uint256) {
        int256 answer;
        (, answer, , , ) = INterfaces(oracle).latestRoundData();
        // need 18 decimals
        return uint256(answer * (10**10));
    }

    /**
    How much tokens left to sale
    */
    function tokensLeft() external view returns (uint256) {
        return tokensLimit - tokensSold;
    }

    function _payEth(address user, uint256 amount) internal notEnded {
        uint256 sold = (amount * tokensPerEth()) / 1 ether;
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        tokensBoughtOf[user] += sold;
        require(tokensBoughtOf[user] <= maxTokens, ERR_AML);
        emit AcceptedETH(user, amount);
    }

    function _pay(address user, uint256 usd) internal notEnded {
        uint256 sold = usd * 1 ether; // price is $1
        tokensSold += sold;
        require(tokensSold <= tokensLimit, ERR_SALE_LIMIT);
        tokensBoughtOf[user] += sold;
        require(tokensBoughtOf[user] <= maxTokens, ERR_AML);
        emit AcceptedUSD(user, usd);
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

    //
    // Rick mode
    //

    /// Take out all stables and ETH
    /// Possible after timeout or after sell 90%
    /// Also closes sale
    function takeAll() external onlyOwner {
        require(
            tokensSold > ((tokensLimit / 10) * 9) || block.timestamp > dateEnd,
            ERR_SOON
        );
        saleEnded = true; //just to save gas for ppl that want buy too late
        uint256 amt = INterfaces(usdt).balanceOf(address(this));
        if (amt > 0) {
            IUsdt(usdt).transfer(owner, amt);
        }
        amt = INterfaces(usdc).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(usdc).transfer(owner, amt), ERR_TRANSFER);
        }
        amt = INterfaces(dai).balanceOf(address(this));
        if (amt > 0) {
            require(INterfaces(dai).transfer(owner, amt), ERR_TRANSFER);
        }
        amt = address(this).balance;
        if (amt > 0) {
            payable(owner).transfer(amt);
        }
    }

    /// we can recover any ERC20 token send in wrong way... for price!
    function recoverErc20(address token) external onlyOwner {
        uint256 amt = INterfaces(token).balanceOf(address(this));
        // do not take deposits
        amt -= _deposited[token];
        if (amt > 0) {
            IUsdt(token).transfer(owner, amt); // use broken ERC20 to ignore return value
        }
    }

    /// should not be needed, but...
    function recoverEth() external onlyOwner {
        require(block.timestamp > dateEnd, ERR_SOON);
        payable(owner).transfer(address(this).balance);
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

    // chainlink ETH/USD oracle
    // answer|int256 :  216182781556 - 8 decimals
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

// USDT is not ERC-20 compliant, not returning true on transfers
interface IUsdt {
    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

// rav3n_pl was here