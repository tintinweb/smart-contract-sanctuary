/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

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
        uint256 bnb_paid;
        uint40 deposit_time;
        uint256 total_deposits;
    }
    
    uint8[] public ref_bonuses;

    address public tokenAddr;
    uint256 private bnbAmount; 
    uint256 public tokenPriceBnb = 50000000000000; 
    uint256 public tokenPriceBnbSell = 50000000000000;
    uint256 public minBuy = 5e16; // 0.05 BNB Min Buy
    uint256 public maxBuy = 10*1e18; // 10.00 BNB Max Buy
    uint256 public tokenDecimal = 18;
    uint256 public bnbDecimal = 18;

    mapping(address => User) public users;

    event TokenTransfer(address beneficiary, uint amount);
    event BnbTransfer(address beneficiary, uint amount);
    event Upline(address indexed addr, address indexed upline);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAddr) {
        tokenAddr = _tokenAddr;

    }
    

    
    
    receive() payable external {

    }

    
    function ExchangeBNBforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        require(amount >= minBuy,"Minimum Buy Price is 0.05 BNB");
        require(users[msg.sender].total_deposits < maxBuy,"Maximum buy is 10 BNB");
        
        bnbAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceBnb)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= bnbAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, bnbAmount));
        users[userAdd].deposit_time = uint40(block.timestamp);

        users[msg.sender].total_deposits += msg.value;
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, bnbAmount);
        users[msg.sender].total_deposits += bnbAmount;
        users[msg.sender].deposit_time = uint40(block.timestamp);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(bnbAmount);
        
    }
    
    function ExchangeTokenforBNBMannual(uint256 _amount) public {
        uint256 amount = _amount;
        address payable userAdd = payable(msg.sender);
        require(Token(tokenAddr).transferFrom(userAdd,address(this), _amount),"Transfers Token From User Address to Contract");
        
        bnbAmount = (((amount.mul(10 ** uint256(bnbDecimal)).mul(tokenPriceBnbSell)).mul(10 ** uint256(bnbDecimal))).div(10 ** uint256(bnbDecimal))).div(10 ** uint256(bnbDecimal*2));
        require(Token(tokenAddr).balanceOf(userAdd) >= _amount, "User Dont have Balance");
        
        userAdd.transfer(bnbAmount);
        users[msg.sender].bnb_paid += bnbAmount;
        emit BnbTransfer(userAdd, bnbAmount);
    }
    
    function updateTokenPrice(uint256 newTokenValue) public onlyOwner {
        tokenPriceBnb = newTokenValue;
    }
    
    function updateTokenPriceSell(uint256 newTokenValue) public onlyOwner {
        tokenPriceBnbSell = newTokenValue;
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
    function bnbBalance() public view returns (uint256){
        return address(this).balance;
    }
}