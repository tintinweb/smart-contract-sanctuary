/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity 0.5.17;

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
    address msgSender = 0x54CB357f8b221BaC33B325d5FE78Fd0f906c1872;//_msgSender();
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

contract TokenICO is Ownable{
    
    address public tokenA;
    address public tokenB;
    uint256 public priceETH;
    uint256 public priceUSDT;
    uint256 public tokensSold;
    Token a ;
    Token b ;
    Token usdt;

    
    constructor(address TokenContractA, address TokenContractB,address USDTcontract) public{
        a = Token(TokenContractA);
        b = Token(TokenContractB);
        usdt = Token(USDTcontract);        

        tokenA=TokenContractA;
        tokenB=TokenContractB;
    }
    
    function() payable external {
        purchaseTokens();
    }
    

    //**************************ETH*********************
    function purchaseTokens() payable public{       
        uint256 weiAmount = msg.value;
        address buyer = msg.sender;
        uint256 tokenAmount;

        if(tokensSold < 30000*1e18){
            require(msg.value >= 37*1e15, "Minimum buy is 1 token"); 
            priceETH = 37*1e15;
        }
        else if(tokensSold >= 30000*1e18){
            require(msg.value >= 43*1e15, "Minimum buy is 1 token"); 
            priceETH = 43*1e15;
        }
        else  if(tokensSold >= 45000*1e18){
            require(msg.value >= 49*1e15, "Minimum buy is 1 token"); 
            priceETH = 49*1e15;
        }

        tokenAmount = (weiAmount*1e18/priceETH); 
        tokensSold = tokensSold + tokenAmount;

        require(a.balanceOf(address(this)) >=tokenAmount , "Tokens Not Available in contract, contact Admin!");
        require(b.balanceOf(address(this)) >= tokenAmount*5000 , " Free Tokens Not Available in contract, contact Admin!" );

        a.transfer(buyer, tokenAmount); 
        b.transfer(buyer, tokenAmount*5000);

        forwardETH(); // to ICO admin        
    }

    function forwardETH() internal {
        address payable ICOadmin = address(uint160(owner()));
        ICOadmin.transfer(address(this).balance);
    }

    function withdrawFunds() public{
        require(msg.sender==owner(),"Only owner can Withdraw!");
        forwardETH();
    }

    //********************** USDT*******************
    function purchaseTokensWithUSDT(uint256 amount) public{   
        uint256 tokenAmount;
        
        if(tokensSold<30000*1e18){  
            require(amount >= 150*1e6,"Minimum buy is 1 token");     
            priceUSDT = 150*1e18;
        }

        else if(tokensSold>=30000*1e18){  
            require(amount >= 175*1e6,"Minimum buy is 1 token");     
            priceUSDT = 175*1e18;
        }

        else  if(tokensSold>=45000*1e18){
            require(amount >= 200*1e6,"Minimum buy is 1 token");     
            priceUSDT = 200*1e18;
        }
        
        tokenAmount = (amount*1e30/priceUSDT);          
        tokensSold = tokensSold + tokenAmount;  

        require(a.balanceOf(address(this)) >=tokenAmount , "Tokens Not Available in contract, contact Admin!");
        require(b.balanceOf(address(this)) >= tokenAmount*5000 , " Free Tokens Not Available in contract, contact Admin!" );

        a.transfer(msg.sender, tokenAmount); 
        b.transfer(msg.sender, tokenAmount*5000);

        usdt.transferFrom(msg.sender,address(this),amount);
        forwardUSDT();
    }

    function forwardUSDT() internal{
        usdt.transfer(owner(),usdt.balanceOf(address(this)));
    }

    function withdrawUSDTFunds() public{
        require(msg.sender==owner(),"Only owner can update contract!");
        require(usdt.balanceOf(address(this)) >=0 , "USDT Not Available in contract, contact Admin!");        
        usdt.transfer(msg.sender,usdt.balanceOf(address(this)));
    }
    //***********************************************
    
    function updatePrice(uint256 tokenPrice) public {
        require(msg.sender==owner(),"Only owner can update contract!");
        priceETH=tokenPrice;
    }
        
    function withdrawRemainingTokens() public{
         require(msg.sender==owner(),"Only owner can update contract!");
         a.transfer(msg.sender,a.balanceOf(address(this)));
         b.transfer(msg.sender,b.balanceOf(address(this)));
    }
        
    function calculateTokenAmount(uint256 amount) external view returns (uint256){
        uint tokens = SafeMath.mul(amount,priceETH);
        return tokens;
    }
    
    function tokenPrice() external view returns (uint256){
        return priceETH;
    }
      
    function Round() external view returns (uint256){
         if(tokensSold<30000*1e18){  
            return 1;
        }
        else if(tokensSold>=30000*1e18){  
            return 2;
        }
        else  if(tokensSold>=45000*1e18){
            return 3;
        }
    }
    
    
}

contract Token {
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function balanceOf(address account) external view returns (uint256)  ;

}