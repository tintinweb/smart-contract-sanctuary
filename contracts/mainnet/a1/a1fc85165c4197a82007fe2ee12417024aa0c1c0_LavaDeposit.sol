pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LavaWalletInterface {

  function depositTokens(address from, address token, uint256 tokens ) public returns (bool success);
  function withdrawTokens(address token, uint256 tokens) public returns (bool success);
  function withdrawTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success);
  function balanceOf(address token,address user) public constant returns (uint);
  function approveTokens(address spender, address token, uint tokens) public returns (bool success);
  function transferTokens(address to, address token, uint tokens) public returns (bool success);
  function transferTokensFrom( address from, address to,address token,  uint tokens) public returns (bool success);
  function getLavaTypedDataHash(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                    uint256 expires, uint256 nonce) public constant returns (bytes32);
  function approveTokensWithSignature(address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success);
  function transferTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success);
  function withdrawTokensFromWithSignature(address from, address to,  address token, uint256 tokens,  uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature) public returns (bool success);
  function tokenAllowance(address token, address tokenOwner, address spender) public constant returns (uint remaining);
  function burnSignature(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                    uint256 expires, uint256 nonce,  bytes signature) public returns (bool success);
  function signatureBurnStatus(bytes32 digest) public view returns (uint);
  function approveAndCall(bytes methodname, address from, address to, address token, uint256 tokens, uint256 relayerReward,
                                    uint256 expires, uint256 nonce, bytes signature ) public returns (bool success);

  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);
  event Transfer(address indexed from, address indexed to,address token, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender,address token, uint tokens);

}

contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}



contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    function Owned() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}





contract LavaDeposit is Owned {


  using SafeMath for uint;

  // balances[tokenContractAddress][EthereumAccountAddress] = 0
   mapping(address => mapping (address => uint256)) balances;


   address public walletContract;

  event Deposit(address token, address from, address to, uint amount);

  function LavaDeposit(address wContract) public  {
    walletContract = wContract;
  }


  //do not allow ether to enter
  function() public payable {
      revert();
  }


   //Remember you need pre-approval for this - nice with ApproveAndCall
  function depositTokensForAccount(address from, address to, address token, uint256 tokens ) public returns (bool success)
  {
      //we already have approval so lets do a transferFrom - transfer the tokens into this contract

       if(!ERC20Interface(token).transferFrom(from, this, tokens)) revert();

      //now deposit the tokens into lavawallet and they are still assigned to this contract
       if(!ERC20Interface(token).approve(walletContract, tokens)) revert();

       if(!LavaWalletInterface(walletContract).depositTokens(this, token, tokens)) revert();

      //transfer the tokens into the lava balance of the &#39;to&#39; account
       if(!LavaWalletInterface(walletContract).transferTokens(to, token, tokens)) revert();

       Deposit(token, from, to, tokens);

      return true;
  }

       /*
         Receive approval to spend tokens and perform any action all in one transaction
       */
     function receiveApproval(address from, uint256 tokens, address token, bytes data) public returns (bool success) {

       require(data.length == 20);

       //find the address from the data
       address to = bytesToAddr(data);

       return depositTokensForAccount(from, to, token, tokens );

     }

     function bytesToAddr (bytes b) constant returns (address) {
      uint result = 0;
      for (uint i = b.length-1; i+1 > 0; i--) {
        uint c = uint(b[i]);
        uint to_inc = c * ( 16 ** ((b.length - i-1) * 2));
        result += to_inc;
      }
      return address(result);
    }


 // ------------------------------------------------------------------------

 // Owner can transfer out any accidentally sent ERC20 tokens 

 // ------------------------------------------------------------------------

 function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

    //find actual balance of the contract
     uint tokenBalance = ERC20Interface(tokenAddress).balanceOf(this);


     if(!ERC20Interface(tokenAddress).transfer(owner, tokens)) revert();


     return true;

 }




}