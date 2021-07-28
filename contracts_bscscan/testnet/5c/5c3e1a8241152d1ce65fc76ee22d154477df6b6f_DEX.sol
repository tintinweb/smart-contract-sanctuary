/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity ^0.6.0;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "iTrust Token";
    string public constant symbol = "iTrust";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 1000000000000;

    using SafeMath for uint256;

   constructor() public {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
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

contract DEX is Ownable{

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    address public LP_Wallet = 0x542021028cc4078d4B42A9c75E8BeF26Df5E6250;
    address public Marketing_Wallet = 0xcCF9343De89FFed11b8CfD259050f78FEBFbdeD1;
    address public Holder_Wallet = 0x9CEE00358Da45Eb0F8E47a8fA0dcf275D8E031B9;

    IERC20 public token;

    constructor() public {
        token = new ERC20Basic();
    }

    function buy(uint256 tokenAmount) payable public {
      uint TwelfthPercentage = (msg.value*12)/100;
      uint FourPercentage = TwelfthPercentage/3;
      uint256 tokenBalance = token.balanceOf(address(this));
      require(tokenAmount <= tokenBalance, "Not enough tokens in the reserve");

      sendETHDividends( Marketing_Wallet, FourPercentage );
      sendETHDividends( LP_Wallet,FourPercentage );
      sendETHDividends( Holder_Wallet,FourPercentage );
      token.transfer(msg.sender, tokenAmount);


    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        msg.sender.transfer(amount);
        emit Sold(amount);
    }



  function sendETHDividends(address receiver,uint amount ) private {
          if (!address(uint160(receiver)).send(amount)) {
              return address(uint160(receiver)).transfer(address(this).balance);
          }
  }
  
  function deposit() external payable returns(uint) {
      return address(this).balance;
  }
  function withdraw() onlyOwner public {
      msg.sender.transfer(address(this).balance);
  }
  function getBalance() public view returns (uint256) {
      return address(this).balance;
  }

}