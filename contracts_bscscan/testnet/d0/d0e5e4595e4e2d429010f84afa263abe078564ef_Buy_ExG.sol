/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

pragma solidity >=0.5.0 <0.6.0;


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
    constructor () internal {
        _owner = msg.sender;
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


contract Buy_ExG is Ownable{
    
    using SafeMath for uint;

    address public tokenAddr;
    uint256 private bnbAmount;
    uint256 public tokenPriceBnb = 168551951; 
    uint256 public tokenDecimal = 18;
    uint256 public bnbDecimal = 18;
    uint256 public totalTransaction;
    uint256 public minContribution = 1e12 ;
    uint256 public maxContribution = 1e18 ;

    event TokenTransfer(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAddr) public {
        tokenAddr = _tokenAddr;
    }
    
    
    
    function() payable external {
        ExchangeBNBforToken(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    
    function ExchangeBNBforToken(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;

        require(amount >= minContribution && amount <= maxContribution,"Contribution should satisfy min max case");
        totalTransaction.add(1);
        bnbAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceBnb)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= bnbAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, bnbAmount));
        emit TokenTransfer(userAdd, bnbAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(bnbAmount);
        _owner.transfer(amount);
    }
    
    function ExchangeBNBforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        
        require(amount >= minContribution && amount <= maxContribution,"Contribution should satisfy min max case");
        totalTransaction.add(1);
        bnbAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceBnb)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= bnbAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, bnbAmount));
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        emit TokenTransfer(userAdd, bnbAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(bnbAmount);
        _owner.transfer(amount);
        
    }
    
    function updateTokenPrice(uint256 newTokenValue) public onlyOwner {
        tokenPriceBnb = newTokenValue;
    }

    function updateTokenContribution(uint256 min, uint256 max) public onlyOwner {
        minContribution = min;
        maxContribution = max;
    }
    
    function updateTokenDecimal(uint256 newDecimal) public onlyOwner {
        tokenDecimal = newDecimal;
    }
    
    function updateTokenAddress(address newTokenAddr) public onlyOwner {
        tokenAddr = newTokenAddr;
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