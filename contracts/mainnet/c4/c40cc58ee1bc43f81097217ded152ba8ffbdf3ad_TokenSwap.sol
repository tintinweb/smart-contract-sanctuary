pragma solidity ^0.4.18;

pragma solidity ^0.4.18;

contract Token {

    /// @return total amount of tokens
    function totalSupply() public constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*
This implements ONLY the standard functions and NOTHING else.
For a token like you would want to deploy in something like Mist, see HumanStandardToken.sol.

If you deploy this, you won&#39;t have anything useful.

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/

contract HumanStandardToken is StandardToken {

    //What is this function?
    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }


}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

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

}

/// @title Token Swap Contract for Neverdie
/// @author Julia Altenried, Yuriy Kashnikov
contract TokenSwap is Ownable {

    /* neverdie token contract address and its instance, can be set by owner only */
    HumanStandardToken ndc;
    /* neverdie token contract address and its instance, can be set by owner only */
    HumanStandardToken tpt;
    /* signer address, verified in &#39;swap&#39; method, can be set by owner only */
    address neverdieSigner;
    /* minimal amount for swap, the amount passed to &#39;swap method can&#39;t be smaller
       than this value, can be set by owner only */
    uint256 minSwapAmount = 40;

    event Swap(
        address indexed to,
        address indexed PTaddress,
        uint256 rate,
        uint256 amount,
        uint256 ptAmount
    );

    event BuyNDC(
        address indexed to,
        uint256 NDCprice,
        uint256 value,
        uint256 amount
    );

    event BuyTPT(
        address indexed to,
        uint256 TPTprice,
        uint256 value,
        uint256 amount
    );

    /// @dev handy constructor to initialize TokenSwap with a set of proper parameters
    /// NOTE: min swap amount is left with default value, set it manually if needed
    /// @param _teleportContractAddress Teleport token address 
    /// @param _neverdieContractAddress Neverdie token address
    /// @param _signer signer address, verified further in swap functions
    function TokenSwap(address _teleportContractAddress, address _neverdieContractAddress, address _signer) public {
        tpt = HumanStandardToken(_teleportContractAddress);
        ndc = HumanStandardToken(_neverdieContractAddress);
        neverdieSigner = _signer;
    }

    function setTeleportContractAddress(address _to) external onlyOwner {
        tpt = HumanStandardToken(_to);
    }

    function setNeverdieContractAddress(address _to) external onlyOwner {
        ndc = HumanStandardToken(_to);
    }

    function setNeverdieSignerAddress(address _to) external onlyOwner {
        neverdieSigner = _to;
    }

    function setMinSwapAmount(uint256 _amount) external onlyOwner {
        minSwapAmount = _amount;
    }

    /// @dev receiveApproval calls function encoded as extra data
    /// @param _sender token sender
    /// @param _value value allowed to be spent
    /// @param _tokenContract callee, should be equal to neverdieContractAddress
    /// @param _extraData  this should be a well formed calldata with function signature preceding which is used to call, for example, &#39;swap&#39; method
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes _extraData) external {
        require(_tokenContract == address(ndc));
        assert(this.call(_extraData));
    }

    

    /// @dev One-way swapFor function, swaps NDC for purchasable token for a given spender
    /// @param _spender account that wants to swap NDC for purchasable token 
    /// @param _rate current NDC to purchasable token rate, i.e. that the returned amount 
    ///              of purchasable tokens equals to (_amount * _rate) / 1000
    /// @param _PTaddress the address of the purchasable token  
    /// @param _amount amount of NDC being offered
    /// @param _expiration expiration timestamp 
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function swapFor(address _spender,
                     uint256 _rate,
                     address _PTaddress,
                     uint256 _amount,
                     uint256 _expiration,
                     uint8 _v,
                     bytes32 _r,
                     bytes32 _s) public {

        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie signer address
        address signer = ecrecover(keccak256(_spender, _rate, _PTaddress, _amount, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        // Check if the amount of NDC is higher than the minimum amount 
        require(_amount >= minSwapAmount);
       
        // Check that we hold enough tokens
        HumanStandardToken ptoken = HumanStandardToken(_PTaddress);
        uint256 ptAmount;
        uint8 decimals = ptoken.decimals();
        if (decimals <= 18) {
          ptAmount = SafeMath.div(SafeMath.div(SafeMath.mul(_amount, _rate), 1000), 10**(uint256(18 - decimals)));
        } else {
          ptAmount = SafeMath.div(SafeMath.mul(SafeMath.mul(_amount, _rate), 10**(uint256(decimals - 18))), 1000);
        }

        assert(ndc.transferFrom(_spender, this, _amount) && ptoken.transfer(_spender, ptAmount));

        // Emit Swap event
        Swap(_spender, _PTaddress, _rate, _amount, ptAmount);
    }

    /// @dev One-way swap function, swaps NDC to purchasable tokens
    /// @param _rate current NDC to purchasable token rate, i.e. that the returned amount of purchasable tokens equals to _amount * _rate 
    /// @param _PTaddress the address of the purchasable token  
    /// @param _amount amount of NDC being offered
    /// @param _expiration expiration timestamp 
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function swap(uint256 _rate,
                  address _PTaddress,
                  uint256 _amount,
                  uint256 _expiration,
                  uint8 _v,
                  bytes32 _r,
                  bytes32 _s) external {
        swapFor(msg.sender, _rate, _PTaddress, _amount, _expiration, _v, _r, _s);
    }

    /// @dev buy NDC with ether
    /// @param _NDCprice NDC price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyNDC(uint256 _NDCprice,
                    uint256 _expiration,
                    uint8 _v,
                    bytes32 _r,
                    bytes32 _s
                   ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_NDCprice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        uint256 a = SafeMath.div(msg.value, _NDCprice);
        assert(ndc.transfer(msg.sender, a));

        // Emit BuyNDC event
        BuyNDC(msg.sender, _NDCprice, msg.value, a);
    }

    /// @dev buy TPT with ether
    /// @param _TPTprice TPT price in Wei
    /// @param _expiration expiration timestamp
    /// @param _v ECDCA signature
    /// @param _r ECDSA signature
    /// @param _s ECDSA signature
    function buyTPT(uint256 _TPTprice,
                    uint256 _expiration,
                    uint8 _v,
                    bytes32 _r,
                    bytes32 _s
                   ) payable external {
        // Check if the signature did not expire yet by inspecting the timestamp
        require(_expiration >= block.timestamp);

        // Check if the signature is coming from the neverdie address
        address signer = ecrecover(keccak256(_TPTprice, _expiration), _v, _r, _s);
        require(signer == neverdieSigner);

        uint256 a = SafeMath.div(msg.value, _TPTprice);
        assert(tpt.transfer(msg.sender, a));

        // Emit BuyNDC event
        BuyTPT(msg.sender, _TPTprice, msg.value, a);
    }

    /// @dev fallback function to reject any ether coming directly to the contract
    function () payable public { 
        revert(); 
    }

    /// @dev withdraw all ether
    function withdrawEther() external onlyOwner {
        owner.transfer(this.balance);
    }

    /// @dev withdraw token
    /// @param _tokenContract any kind of ERC20 token to withdraw from
    function withdraw(address _tokenContract) external onlyOwner {
        ERC20 token = ERC20(_tokenContract);
        uint256 balance = token.balanceOf(this);
        assert(token.transfer(owner, balance));
    }

    /// @dev kill contract, but before transfer all TPT, NDC tokens and ether to owner
    function kill() onlyOwner public {
        uint256 allNDC = ndc.balanceOf(this);
        uint256 allTPT = tpt.balanceOf(this);
        assert(ndc.transfer(owner, allNDC) && tpt.transfer(owner, allTPT));
        selfdestruct(owner);
    }

}