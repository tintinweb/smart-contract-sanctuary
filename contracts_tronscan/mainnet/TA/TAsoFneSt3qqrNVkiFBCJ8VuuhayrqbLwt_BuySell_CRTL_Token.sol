//SourceUnit: buySellMelaleucaa.sol

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

}


contract BuySell_CRTL_Token is Ownable{
    
    using SafeMath for uint;

    struct User {
        uint256 trx_paid;
        uint40 deposit_time;
        uint256 total_deposits;
    }
    
    uint8[] public ref_bonuses;

    address public tokenAddr;
    uint256 private trxAmount; 
    uint256 public tokenPriceTrx = 5000; 
    uint256 public tokenPriceTrxSell = 5000;
    uint256 public minBuy = 1e7; // 10 TRX Min Buy
    uint256 public maxBuy = 5e8; // 500 TRX Max Buy
    uint256 public tokenDecimal = 6;
    uint256 public trxDecimal = 6;

    mapping(address => User) public users;

    event TokenTransfer(address beneficiary, uint amount);
    event TrxTransfer(address beneficiary, uint amount);
    event Upline(address indexed addr, address indexed upline);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAddr) {
        tokenAddr = _tokenAddr;

    }
    

    
    
    receive() payable external {

    }

    
    function ExchangeTRXforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        require(amount >= minBuy,"Minimum Buy Price is 0.05 TRX");
        require(users[msg.sender].total_deposits < maxBuy,"Maximum buy is 10 TRX");
        
        trxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceTrx)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= trxAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, trxAmount));
        users[userAdd].deposit_time = uint40(block.timestamp);

        users[msg.sender].total_deposits += msg.value;
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, trxAmount);
        users[msg.sender].total_deposits += trxAmount;
        users[msg.sender].deposit_time = uint40(block.timestamp);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(trxAmount);
        
    }
    
    function ExchangeTokenforTRXMannual(uint256 _amount) public {
        uint256 amount = _amount;
        address payable userAdd = payable(msg.sender);
        require(Token(tokenAddr).transferFrom(userAdd,address(this), _amount),"Transfers Token From User Address to Contract");
        
        trxAmount = (((amount.mul(10 ** uint256(trxDecimal)).mul(tokenPriceTrxSell)).mul(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal))).div(10 ** uint256(trxDecimal*2));
        require(Token(tokenAddr).balanceOf(userAdd) >= _amount, "User Dont have Balance");
        
        userAdd.transfer(trxAmount);
        users[msg.sender].trx_paid += trxAmount;
        emit TrxTransfer(userAdd, trxAmount);
    }
    
    function updateTokenPrice(uint256 newTokenValue) public onlyOwner {
        tokenPriceTrx = newTokenValue;
    }
    
    function updateTokenPriceSell(uint256 newTokenValue) public onlyOwner {
        tokenPriceTrxSell = newTokenValue;
    }
    
    function updateTokenDecimal(uint256 newDecimal) public onlyOwner {
        tokenDecimal = newDecimal;
    }
    
    
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
    }
    
    function depositCrypto() public payable {
        
    }



    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(tokenAddr).transfer(beneficiary, Token(tokenAddr).balanceOf(address(this))));
    }

    function withdrawCrypto(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function tokenBalance() public view returns (uint256){
        return Token(tokenAddr).balanceOf(address(this));
    }
    function trxBalance() public view returns (uint256){
        return address(this).balance;
    }
}