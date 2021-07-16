//SourceUnit: NEWIGEM.sol

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
    address private _owner;

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
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface Token {
    function transfer(address to, uint256 value) external returns (bool);


    function balanceOf(address who) external view returns (uint256);

}


contract Buy_NEWIGEM_Token is Ownable{
    
    using SafeMath for uint;

    address public tokenAddr;
    uint256 private trxAmount = 0;
    uint256 public tokenPriceTrx = 93400;
    uint256 public tokenDecimal = 6;
    uint256 public tokenSold = 0;

    event TokenTransfer(address beneficiary, uint amount);
    
    mapping (address => uint256) public balances;
    mapping(address => uint256) public tokenExchanged;

    constructor(address _tokenAdd) public {
        tokenAddr = _tokenAdd;
    }
    
    
    
    function() payable external {
        ExchangeTRXforToken(msg.sender, msg.value);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
    }
    
    function ExchangeTRXforToken(address _addr, uint256 _amount) private {
        uint256 amount = _amount;
        address userAdd = _addr;
        
        trxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceTrx)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= trxAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, trxAmount));
        tokenSold = tokenSold.add(trxAmount);
        emit TokenTransfer(userAdd, trxAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(trxAmount);
        
    }
    
    function ExchangeTRXforTokenMannual() public payable {
        uint256 amount = msg.value;
        address userAdd = msg.sender;
        
        trxAmount = ((amount.mul(10 ** uint256(tokenDecimal)).div(tokenPriceTrx)).mul(10 ** uint256(tokenDecimal))).div(10 ** uint256(tokenDecimal));
        require(Token(tokenAddr).balanceOf(address(this)) >= trxAmount, "There is low token balance in contract");
        
        require(Token(tokenAddr).transfer(userAdd, trxAmount));
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        tokenSold = tokenSold.add(trxAmount);
        emit TokenTransfer(userAdd, trxAmount);
        tokenExchanged[msg.sender] = tokenExchanged[msg.sender].add(trxAmount);
        
    }
    
    function updateTokenPrice(uint256 newTokenValue) public onlyOwner {
        tokenPriceTrx = newTokenValue;
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
    function trxBalance() public view returns (uint256){
        return address(this).balance;
    }
    function userTokenBalance(address userAddress) public view returns (uint256){
        return Token(tokenAddr).balanceOf(userAddress);
    }
}