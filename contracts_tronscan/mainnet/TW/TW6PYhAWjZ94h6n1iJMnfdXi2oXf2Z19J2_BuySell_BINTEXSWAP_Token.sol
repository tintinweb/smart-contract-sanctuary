//SourceUnit: buysell_bintexswap.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable  {
    address payable public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns (uint256);

}


contract BuySell_BINTEXSWAP_Token is Ownable{
    
    using SafeMath for uint;

    struct User {
        uint256 trx_paid;
        uint40 deposit_time;
        uint256 total_deposits;

        uint256 usdt_paid;
        uint40 usdt_deposit_time;
        uint256 usdt_total_deposit;
    }
    
    uint8[] public ref_bonuses;

    address public tokenAddr;
    address public usdttokenAddr;
    uint256 private trxAmount; 
    uint256 public tokenPricetrx = 5000000; 
    uint256 public tokenPricetrxSell = 5000000;
    uint256 public tokenPriceUsdt = 1000000;
    uint256 public tokenPriceUsdtSell = 1000000;
    uint256 public minBuy = 1e6; // TRX min buy
    uint256 public minBuyUsdt = 1e6;
    uint256 public tokenDecimal = 18;
    uint256 public trxDecimal = 6;
    uint256 public usdtDecimal = 6;

    mapping(address => User) public users;

    event TokenTransfer(address beneficiary, uint amount);
    event trxTransfer(address beneficiary, uint amount);
    event usdtTransfer(address beneficiary, uint amount);

    event Upline(address indexed addr, address indexed upline);
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) public usdtbalances;

    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAddr, address _usdtTokenAddress) {
        tokenAddr = _tokenAddr;
        usdttokenAddr = _usdtTokenAddress;
        tokenDecimal = Token(tokenAddr).decimals();
        usdtDecimal = Token(_usdtTokenAddress).decimals();
    }
    

    
    
    receive() payable external {

    }

    
    function ExchangeTrxforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        require(amount >= minBuy,"Less than Min buy");
        
        trxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPricetrx)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= trxAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, trxAmount));
        users[userAdd].deposit_time = uint40(block.timestamp);

        users[msg.sender].total_deposits += msg.value;
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, trxAmount);
        users[msg.sender].deposit_time = uint40(block.timestamp);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(trxAmount);
        
    }
    
    function ExchangeTokenforTrxMannual(uint256 _amount) public {
        uint256 newtrxDecimal = tokenDecimal-trxDecimal;
        uint256 amount = _amount/10**newtrxDecimal;
        address payable userAdd = payable(msg.sender);
        require(Token(tokenAddr).balanceOf(userAdd) >= _amount, "User Dont have Balance");
        require(Token(tokenAddr).transferFrom(userAdd,address(this), _amount),"Transfers Token From User Address to Contract");
        
        trxAmount = (((amount.mul(10 ** uint256(trxDecimal)).mul(tokenPricetrxSell)).mul(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal*2));
        
        userAdd.transfer(trxAmount);
        users[msg.sender].trx_paid += trxAmount;
        emit trxTransfer(userAdd, trxAmount);
    }





    function ExchangeUsdtforTokenMannual(uint256 _amount) public {
        uint256 amount = _amount;
        address userAdd = msg.sender;
        require(amount >= minBuyUsdt,"Less than Min buy");
        require(Token(usdttokenAddr).transferFrom(userAdd,address(this), _amount),"Transfers Token From User Address to Contract");

        trxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceUsdt)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= trxAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, trxAmount));
        users[userAdd].usdt_deposit_time = uint40(block.timestamp);

        users[msg.sender].usdt_total_deposit += amount;
        balances[msg.sender] = balances[msg.sender].add(amount);
        emit TokenTransfer(userAdd, trxAmount);
        users[msg.sender].usdt_deposit_time = uint40(block.timestamp);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(trxAmount);
        
    }
    
    function ExchangeTokenforUsdtMannual(uint256 _amount) public {
        uint256 newtrxDecimal = tokenDecimal-trxDecimal;
        uint256 amount = _amount/10**newtrxDecimal;
        address userAdd = (msg.sender);
        require(Token(tokenAddr).balanceOf(userAdd) >= _amount, "User Dont have Balance");
        require(Token(tokenAddr).transferFrom(userAdd,address(this), _amount),"Transfers Token From User Address to Contract");
        
        trxAmount = (((amount.mul(10 ** uint256(usdtDecimal)).mul(tokenPriceUsdtSell)).mul(10 ** uint256(usdtDecimal))).div(10 ** uint256(usdtDecimal))).div(10 ** uint256(usdtDecimal*2));
        
        require(Token(usdttokenAddr).transfer(userAdd, trxAmount));
        users[msg.sender].usdt_paid += trxAmount;
        emit usdtTransfer(userAdd, trxAmount);
    }


    function calculateTrxToToken(uint256 amount) public view returns(uint256){
        return ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPricetrx)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
    }

    function calculateTokenToTrx(uint256 amount) public view returns(uint256){
        uint256 newtrxDecimal = tokenDecimal-trxDecimal;
        amount = amount/10**newtrxDecimal;
        return (((amount.mul(10 ** uint256(trxDecimal)).mul(tokenPricetrxSell)).mul(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal*2));
    }

    function calculateUsdtToToken(uint256 amount) public view returns(uint256){
        return ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceUsdt)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
    }

    function calculateTokenToUsdt(uint256 amount) public view returns(uint256){
        uint256 newtrxDecimal = tokenDecimal-trxDecimal;
        amount = amount/10**newtrxDecimal;
        return (((amount.mul(10 ** uint256(usdtDecimal)).mul(tokenPriceUsdtSell)).mul(10 ** uint256(usdtDecimal))).div(10 ** uint256(usdtDecimal))).div(10 ** uint256(usdtDecimal*2));
    }
    
    function updateTokenPriceTrx(uint256 newTokenValue) public onlyOwner {
        tokenPricetrx = newTokenValue;
    }
    
    function updateTokenPriceSellTrx(uint256 newTokenValue) public onlyOwner {
        tokenPricetrxSell = newTokenValue;
    }

    function updateTokenPriceUsdt(uint256 newTokenValue) public onlyOwner {
        tokenPriceUsdt = newTokenValue;
    }
    
    function updateTokenPriceSellUsdt(uint256 newTokenValue) public onlyOwner {
        tokenPriceUsdtSell = newTokenValue;
    }

    function updateMinBuyTrx(uint256 newValue) public onlyOwner {
        minBuy = newValue;
    }

    function updateMinBuyUsdt(uint256 newValue) public onlyOwner {
        minBuyUsdt = newValue;
    }
    
    
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
    }

    function updateTokenAddressUsdt(address newTokenAddr) public onlyOwner {
        usdttokenAddr = newTokenAddr;
    }
    
    function depositCrypto() public payable {
        
    }

    function withdrawTokens(address _tokenAdd, address beneficiary) public onlyOwner {
        require(Token(_tokenAdd).transfer(beneficiary, Token(_tokenAdd).balanceOf(address(this))));
    }

    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function tokenBalance(address _tokenAdd) public view returns (uint256){
        return Token(_tokenAdd).balanceOf(address(this));
    }
    function trxBalance() public view returns (uint256){
        return address(this).balance;
    }
}