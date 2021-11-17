/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity 0.5.16;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = 0x808E95185ab79bA31684778A5F2c929367BF1321;//_msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns ( address ) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract privateSale is Ownable{
    
    
    address public token;
    uint256 internal price=2878; 
    uint256 public minPrice=8*1e16;
    uint256 public maxPrice=16*1e17;
    uint256 public minInvestment=8*1e16;
    uint256 public maxInvestment=16*1e17;
    uint256 public totalInvestment = 0;
    Token c ;
    
    struct userStruct{
        bool isExist;
        uint256 investment;
        uint256 nextClaimTime;
        uint256 nextClaimAmount;
        uint256 lockedAmount;
    }
    mapping(address => userStruct) public user;
    
    constructor(address TokenContract) public{
        c = Token(TokenContract);
        token=TokenContract;
    }
    
    function() payable external {
        purchaseTokens();
    }
    
    function checkUserLImit() internal{
        if(!user[msg.sender].isExist){
            user[msg.sender].isExist = true;
            user[msg.sender].investment = user[msg.sender].investment + msg.value;
        }
        else{
            require((user[msg.sender].investment + msg.value) <= maxInvestment , "User Trying to cross maxInvestment Limit!");
            user[msg.sender].investment = user[msg.sender].investment + msg.value;
        }
    }
    
    
    function purchaseTokens() payable public{
        //require(totalInvestment <= 480*1e18,"preSale Limit Reached!");
        require(msg.value<=maxInvestment ,"Investment Limit Crossed by User!");
        require(msg.value>=minPrice && msg.value<=maxPrice ,"Check min buy and sell price!");
        checkUserLImit();
        uint256 weiAmount = msg.value;
        uint256 tokenAmount;
        uint256 fiftyPercentUnlocked;
        
        tokenAmount = SafeMath.mul(weiAmount,price); 
        
        //50% unlocked at start
        fiftyPercentUnlocked = SafeMath.div(tokenAmount,2);
        c.transfer(msg.sender,fiftyPercentUnlocked);
        tokenAmount = tokenAmount - fiftyPercentUnlocked;
        //*********************
        
        user[msg.sender].lockedAmount = user[msg.sender].lockedAmount + tokenAmount;
        user[msg.sender].nextClaimTime = now + 120 days;
        user[msg.sender].nextClaimAmount = user[msg.sender].lockedAmount;
        
        totalInvestment = totalInvestment + msg.value;
        
        forwardFunds(); // to ICO admin
        
    }
    
    function claimTokens() public{
        require(user[msg.sender].nextClaimTime < now,"Claim time not reached!");
        require(user[msg.sender].nextClaimAmount <= user[msg.sender].lockedAmount,"No Amount to Claim");
        c.transfer(msg.sender,user[msg.sender].nextClaimAmount);
        user[msg.sender].lockedAmount = user[msg.sender].lockedAmount - user[msg.sender].nextClaimAmount;
        user[msg.sender].nextClaimTime = now + 120 days;
    }
    
    function updatePrice(uint256 tokenPrice) public {
        require(msg.sender==owner(),"Only owner can update contract!");
        price=tokenPrice;
    }
    
    function setMinMax(uint256 min , uint256 max) public{
        require(msg.sender==owner(),"Only owner can update contract!");
        minPrice=min;
        maxPrice=max;
    }
    
    
    function withdrawRemainingTokensAfterICO() public{
         require(msg.sender==owner(),"Only owner can update contract!");
         require(c.balanceOf(address(this)) >=0 , "Tokens Not Available in contract, contact Admin!");
         c.transfer(msg.sender,c.balanceOf(address(this)));
    }
    
    function forwardFunds() internal {
        address payable ICOadmin = address(uint160(owner()));
        ICOadmin.transfer(address(this).balance);
    }
    
    function withdrawFunds() public{
        require(msg.sender==owner(),"Only owner can Withdraw!");
        forwardFunds();
    }
    
    function calculateTokenAmount(uint256 amount) external view returns (uint256){
        uint tokens = SafeMath.div(amount,price);
        return tokens;
    }
    
    function tokenPrice() external view returns (uint256){
        return price;
    }
    
    
    
}

contract Token {
    //function transferFrom(address sender, address recipient, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256)  ;

}