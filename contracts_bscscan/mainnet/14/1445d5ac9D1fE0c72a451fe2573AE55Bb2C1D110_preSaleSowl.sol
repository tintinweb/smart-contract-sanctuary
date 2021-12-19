/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity ^0.8.9;
//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract preSaleSowl {
    IBEP20 public token;
    address payable public owner;
    address payable public marketWallet;

    uint256 public tokenPerBnb;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public hardCap;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    bool public isClaimable;

    mapping(address => uint256) public coinBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public claimed;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event ClaimToken(address indexed _user, uint256 indexed _amount);

    constructor( 
        uint256 _startTime,
        address payable _marketWallet,
        IBEP20 _token
    ) {
        owner = payable(msg.sender);
        marketWallet = _marketWallet;
        token = _token;
        tokenPerBnb = 22e6 * 1e12;
        minAmount = 0.01 ether;
        maxAmount = 4 ether;
        preSaleStartTime = _startTime;
        preSaleEndTime = preSaleStartTime + 24 hours;
        hardCap = 250 ether;
    }

    // to buy token during preSale time => for web3 use
    function buyToken() public payable {
        require(
            block.timestamp >= preSaleStartTime,
            "PRESALE: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PRESALE: PreSale over");
        require(
            coinBalance[msg.sender] + (msg.value) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );
        require(msg.value >= minAmount, "PRESALE: Amount less than min limit");
        require(
            amountRaised + (msg.value) <= hardCap,
            "PRESALE: Hard cap reached"
        );

        uint256 numberOfTokens = bnbToToken(msg.value);
        marketWallet.transfer(msg.value);
        token.transferFrom(owner, address(this), numberOfTokens);
        coinBalance[msg.sender] += msg.value;
        tokenBalance[msg.sender] += numberOfTokens;
        soldToken += numberOfTokens;
        amountRaised += msg.value;

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to claim token after launch => for web3 use
    function claim() public {
        require(isClaimable, "PRESALE: Can not claim before launch");
        require(claimed[msg.sender] == false, "PRESALE: Already claimed");
        require(
            tokenBalance[msg.sender] > 0,
            "PRESALE: Do not have any tokens"
        );

        uint256 userBalance = tokenBalance[msg.sender];
        token.transfer(msg.sender, userBalance);
        tokenBalance[msg.sender] = 0;
        claimed[msg.sender] = true;

        emit ClaimToken(msg.sender, userBalance);
    }

    // to check number of token for given bnb
    function bnbToToken(uint256 _amount)
        public
        view
        returns (uint256 _numberOfTokens)
    {
        _numberOfTokens = (_amount * tokenPerBnb) / 1e18;
    }

    // to change Price of the token
    function changePrice(uint256 _amount) external onlyOwner {
        tokenPerBnb = _amount;
    }

    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount, uint256 _hardCap)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        hardCap = _hardCap;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // to enable claim after presale
    function enableClaim(bool _status) external onlyOwner {
        isClaimable = _status;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // change market wallet
    function changeMarketWallet(address payable _marketWallet) external onlyOwner {
        marketWallet = _marketWallet;
    }

    // to change tokens
    function changeToken(address _token) external onlyOwner {
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(address payable _user, uint256 _value) external onlyOwner {
        _user.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(uint256 _value) external onlyOwner {
        token.transfer(owner, _value);
    }

    // to chech token approval
    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}