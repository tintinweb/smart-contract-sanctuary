/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// Interfaces for contract interaction
interface INterfaces {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function allowance(address, address) external returns (uint256);

    //usdc
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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

// BigShortBets.com presale contract - via StableCoins and ETH
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
// send ONLY round number of USD(c|t)/DAI!
// ie 20, 500, 2000 NOT 20.1, 500.5, 2000.3
// contract will ignore decimals
//
// Need 150k gas limit
// use proper pay* function
contract BigShortBetsPresale2 {
    // max USD per user
    uint256 private immutable _maxUsd;
    // soft limit USD total
    uint256 private immutable _limitUsd;
    // max ETH per user
    uint256 private immutable _maxEth;
    // soft limit ETH total
    uint256 private immutable _limitEth;
    // contract starts accepting transfers
    uint256 private immutable _dateStart;
    // hard time limit
    uint256 private immutable _dateEnd;

    // total collected USD
    uint256 private _usdCollected;

    uint256 private constant DECIMALS_DAI = 18;
    uint256 private constant DECIMALS_USDC = 6;
    uint256 private constant DECIMALS_USDT = 6;

    // addresses of tokens
    address private immutable usdt;
    address private immutable usdc;
    address private immutable dai;

    address public owner;
    address public newOwner;

    bool private _presaleEnded;

    // deposited per user
    mapping(address => uint256) private _usdBalance;
    mapping(address => uint256) private _ethBalance;

    // deposited per tokens
    mapping(address => uint256) private _deposited;

    // will be set after presale
    uint256 private _tokensPerEth;

    string private constant ERROR_ANS = "Approval not set!";

    event AcceptedUSD(address indexed user, uint256 amount);
    event AcceptedETH(address indexed user, uint256 amount);

    constructor(
        address _owner,
        uint256 maxUsd,
        uint256 limitUsd,
        uint256 maxEth,
        uint256 limitEth,
        uint256 startDate,
        uint256 endDate,
        address _usdt,
        address _usdc,
        address _dai
    ) {
        owner = _owner;
        _maxUsd = maxUsd;
        _limitUsd = limitUsd;
        _maxEth = maxEth;
        _limitEth = limitEth;
        _dateStart = startDate;
        _dateEnd = endDate;
        usdt = _usdt;
        usdc = _usdc;
        dai = _dai;

        /**
        mainnet:
        usdt=0xdAC17F958D2ee523a2206206994597C13D831ec7;
        usdc=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        dai=0x6B175474E89094C44Da98b954EedeAC495271d0F;
        */
    }

    //pay in using USDC
    //need prepare and sign approval first
    //not included in dapp
    function payUsdcByAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(to == address(this), "Wrong authorization address");
        // should throw on any error
        INterfaces(usdc).transferWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );
        // not msg.sender, approval can be sent by anyone
        _pay(from, value, DECIMALS_USDC);
        _deposited[usdc] += value;
    }

    //pay in using USDC
    //use approve/transferFrom
    function payUSDC(uint256 amount) external {
        require(
            INterfaces(usdc).allowance(msg.sender, address(this)) >= amount,
            ERROR_ANS
        );
        require(
            INterfaces(usdc).transferFrom(msg.sender, address(this), amount),
            "USDC transfer failed"
        );
        _pay(msg.sender, amount, DECIMALS_USDC);
        _deposited[usdc] += amount;
    }

    //pay in using USDT
    //need set approval first
    function payUSDT(uint256 amount) external {
        require(
            INterfaces(usdt).allowance(msg.sender, address(this)) >= amount,
            ERROR_ANS
        );
        IUsdt(usdt).transferFrom(msg.sender, address(this), amount);
        _pay(msg.sender, amount, DECIMALS_USDT);
        _deposited[usdt] += amount;
    }

    //pay in using DAI
    //need set approval first
    function payDAI(uint256 amount) external {
        require(
            INterfaces(dai).allowance(msg.sender, address(this)) >= amount,
            ERROR_ANS
        );
        require(
            INterfaces(dai).transferFrom(msg.sender, address(this), amount),
            "DAI transfer failed"
        );
        _pay(msg.sender, amount, DECIMALS_DAI);
        _deposited[dai] += amount;
    }

    //direct ETH send will not back
    //
    //accept ETH

    // takes about 50k gas
    receive() external payable {
        _payEth(msg.sender, msg.value);
    }

    // takes about 35k gas
    function payETH() external payable {
        _payEth(msg.sender, msg.value);
    }

    function _payEth(address user, uint256 amount) internal notEnded {
        uint256 amt = _ethBalance[user] + amount;
        require(amt <= _maxEth, "ETH per user reached");
        _ethBalance[user] += amt;
        emit AcceptedETH(user, amount);
    }

    function _pay(
        address user,
        uint256 amount,
        uint256 decimals
    ) internal notEnded {
        uint256 usd = amount / (10**decimals);
        _usdBalance[user] += usd;
        require(_usdBalance[user] <= _maxUsd, "USD amount too high");
        _usdCollected += usd;
        emit AcceptedUSD(user, usd);
    }

    //
    // external readers
    //
    function USDcollected() external view returns (uint256) {
        return _usdCollected;
    }

    function ETHcollected() external view returns (uint256) {
        return address(this).balance;
    }

    function USDmax() external view returns (uint256) {
        return _maxUsd;
    }

    function USDlimit() external view returns (uint256) {
        return _limitUsd;
    }

    function ETHmax() external view returns (uint256) {
        return _maxEth;
    }

    function ETHlimit() external view returns (uint256) {
        return _limitEth;
    }

    function dateStart() external view returns (uint256) {
        return _dateStart;
    }

    function dateEnd() external view returns (uint256) {
        return _dateEnd;
    }

    function tokensBoughtOf(address user) external view returns (uint256 amt) {
        require(_tokensPerEth > 0, "Tokens/ETH ratio not set yet");
        amt = (_usdBalance[user] * 95) / 100;
        amt += _ethBalance[user] * _tokensPerEth;
        return amt;
    }

    function usdDepositOf(address user) external view returns (uint256) {
        return _usdBalance[user];
    }

    function ethDepositOf(address user) external view returns (uint256) {
        return _ethBalance[user];
    }

    modifier notEnded() {
        require(!_presaleEnded, "Presale ended");
        require(
            block.timestamp > _dateStart && block.timestamp < _dateEnd,
            "Too soon or too late"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for contract Owner");
        _;
    }

    modifier timeIsUp() {
        require(block.timestamp > _dateEnd, "SOON");
        _;
    }

    function endPresale() external onlyOwner {
        require(
            _usdCollected > _limitUsd || address(this).balance > _limitEth,
            "Limit not reached"
        );
        _presaleEnded = true;
    }

    function setTokensPerEth(uint256 ratio) external onlyOwner {
        require(_tokensPerEth == 0, "Ratio already set");
        _tokensPerEth = ratio;
    }

    // take out all stables and ETH
    function takeAll() external onlyOwner timeIsUp {
        _presaleEnded = true; //just to save gas for ppl that want buy too late
        uint256 amt = INterfaces(usdt).balanceOf(address(this));
        if (amt > 0) {
            IUsdt(usdt).transfer(owner, amt);
        }
        amt = INterfaces(usdc).balanceOf(address(this));
        if (amt > 0) {
            INterfaces(usdc).transfer(owner, amt);
        }
        amt = INterfaces(dai).balanceOf(address(this));
        if (amt > 0) {
            INterfaces(dai).transfer(owner, amt);
        }
        amt = address(this).balance;
        if (amt > 0) {
            payable(owner).transfer(amt);
        }
    }

    // we can recover any ERC20 token send in wrong way... for price!
    function recoverErc20(address token) external onlyOwner {
        uint256 amt = INterfaces(token).balanceOf(address(this));
        // do not take deposits
        amt -= _deposited[token];
        if (amt > 0) {
            INterfaces(token).transfer(owner, amt);
        }
    }

    // should not be needed, but...
    function recoverEth() external onlyOwner timeIsUp {
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

// rav3n_pl was here