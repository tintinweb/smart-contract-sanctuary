pragma solidity 0.4.25;
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
    require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
interface ERC20Interface {
   
      /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) view external returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
    function approve(address _spender, uint256 _value) external returns (bool success);
    function disApprove(address _spender)  external returns (bool success);
   function increaseApproval(address _spender, uint _addedValue) external returns (bool success);
   function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool success);
     /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant external returns (uint256 remaining);
     function name() external view returns (string _name);

    /* Get the contract constant _symbol */
    function symbol() external view returns (string _symbol);

    /* Get the contract constant _decimals */
    function decimals() external view returns (uint8 _decimals); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library SafeERC20{

  function safeTransfer(ERC20Interface token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }    
    
  

  function safeTransferFrom(ERC20Interface token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20Interface token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract TansalICOTokenVault is owned{
    
     using SafeERC20 for ERC20Interface;
     ERC20Interface TansalCoin;
      struct Investor {
        string fName;
        string lName;
        uint256 totalTokenWithdrawn;
        bool exists;
    }
    
    mapping (address => Investor) public investors;
    address[] public investorAccts;
    uint256 public numberOFApprovedInvestorAccounts;

     constructor() public
     {
         
         TansalCoin = ERC20Interface(0xe4a93eC88EaB28Fa25F03d066b6f94135722a120);
     }
    
     function() public {
         //not payable fallback function
          revert();
    }
    
     function sendApprovedTokensToInvestor(address _benificiary,uint256 _approvedamount,string _fName, string _lName) public onlyOwner
    {
        uint256 totalwithdrawnamount;
        require(TansalCoin.balanceOf(address(this)) > _approvedamount);
        if(investors[_benificiary].exists)
        {
            uint256 alreadywithdrawn = investors[_benificiary].totalTokenWithdrawn;
            totalwithdrawnamount = alreadywithdrawn + _approvedamount;
            
        }
        else
         totalwithdrawnamount = _approvedamount;
         investors[_benificiary] = Investor({
                                            fName: _fName,
                                            lName: _lName,
                                            totalTokenWithdrawn: totalwithdrawnamount,
                                            exists: true
            
        });
        require(investors[_benificiary].exists,"benificiary not added");
         investorAccts.push(_benificiary) -1;
        numberOFApprovedInvestorAccounts = investorAccts.length;
        TansalCoin.safeTransfer(_benificiary , _approvedamount);
    }
    
     function onlyPayForFuel() public payable onlyOwner{
        // Owner will pay in contract to bear the gas price if transactions made from contract
        
    }
    function withdrawEtherFromcontract(uint _amountInwei) public onlyOwner{
        require(address(this).balance > _amountInwei);
      require(msg.sender == owner);
      owner.transfer(_amountInwei);
     
    }
    function withdrawTokenFromcontract(ERC20Interface _token, uint256 _tamount) public onlyOwner{
        require(_token.balanceOf(address(this)) > _tamount);
         _token.safeTransfer(owner, _tamount);
     
    }
}