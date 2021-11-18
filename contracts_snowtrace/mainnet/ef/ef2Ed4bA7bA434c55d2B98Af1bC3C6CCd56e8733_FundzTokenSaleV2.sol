/**
 *Submitted for verification at snowtrace.io on 2021-11-18
*/

//SPDX-License-Identifier: Garbage, innit?
pragma solidity 0.8.7;

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
    constructor ()  {
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
    
    function balanceOf(address who) external view returns (uint256);

}


contract FundzTokenSaleV2 is Ownable{
    
    using SafeMath for uint;

    address public fundzAddr;
    uint256 private avaxAmount;
    uint256 public tokenPriceAvax; 
    uint256 public tokenDecimal = 18;
    uint256 public avaxDecimal = 18;
    uint256 public startedAt;
    uint256 public endAt;
    


    event TokenTransfer(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _fundzAddr, uint256 _startDate, uint256 _endDate, uint256 _tokenPriceAvax)  {
        startedAt = _startDate;
        endAt = _endDate;
        fundzAddr = _fundzAddr;
        tokenPriceAvax = _tokenPriceAvax;
    }
    
    
    
    receive() payable external {
        ExchangeAVAXforToken(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    

    
    function ExchangeAVAXforToken(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;
        require(block.timestamp >= startedAt, "Sale not yet started, come back later!");
        require(block.timestamp < endAt, "Sale Ended :(");
        
        
        avaxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceAvax)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(fundzAddr).balanceOf(address(this)) >= avaxAmount, "Contract has low token balance :(");
        
        require(Token(fundzAddr).transfer(userAdd, avaxAmount));
        emit TokenTransfer(userAdd, avaxAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(avaxAmount);
        _owner.transfer(amount);
    }
    
    function ExchangeAVAXforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        require(block.timestamp >= startedAt, "Sale not yet started");
        require(block.timestamp < endAt, "Sale Ended");
        
       
        avaxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceAvax)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(fundzAddr).balanceOf(address(this)) >= avaxAmount, "Contract has low token balance :(");
        
        require(Token(fundzAddr).transfer(userAdd, avaxAmount));
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, avaxAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(avaxAmount);
        _owner.transfer(amount);
        
    }
    

    function updateTokenDecimal(uint256 newDecimal) public onlyOwner {
        tokenDecimal = newDecimal;
    }
    
    function updateTokenPrice(uint256 _tokenPriceAvax) public onlyOwner {
        tokenPriceAvax = _tokenPriceAvax;
    }
    
    function updateFundzAddress(address newFundzAddr) public onlyOwner {
        fundzAddr = newFundzAddr;
    }

    function withdrawTokens(address beneficiary) public onlyOwner {
        require(Token(fundzAddr).transfer(beneficiary, Token(fundzAddr).balanceOf(address(this))));
    }
    
    function changeStartDate(uint256 _startedAt) public onlyOwner {
        startedAt = _startedAt;
    }
     
    function changeEndDate(uint256 _endAt) public onlyOwner {
        endAt = _endAt;
    }


    function withdrawAvax(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
    function tokenBalance() public view returns (uint256){
        return Token(fundzAddr).balanceOf(address(this));
    }
    function avaxBalance() public view returns (uint256){
        return address(this).balance;
    }
}