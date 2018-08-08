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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// TEAM Token is an index token of TokenStars platform
// Copyright (c) 2017 TokenStars
// Made by Aler Denisov
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.






contract StarTokenInterface is MintableToken {
    // Cheatsheet of inherit methods and events
    // function transferOwnership(address newOwner);
    // function allowance(address owner, address spender) constant returns (uint256);
    // function transfer(address _to, uint256 _value) returns (bool);
    // function transferFrom(address from, address to, uint256 value) returns (bool);
    // function approve(address spender, uint256 value) returns (bool);
    // function increaseApproval (address _spender, uint _addedValue) returns (bool success);
    // function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success);
    // function finishMinting() returns (bool);
    // function mint(address _to, uint256 _amount) returns (bool);
    // event Approval(address indexed owner, address indexed spender, uint256 value);
    // event Mint(address indexed to, uint256 amount);
    // event MintFinished();

    // Custom methods and events
    function openTransfer() public returns (bool);
    function toggleTransferFor(address _for) public returns (bool);
    function extraMint() public returns (bool);

    event TransferAllowed();
    event TransferAllowanceFor(address indexed who, bool indexed state);


}

// TEAM Token is an index token of TokenStars platform
// Copyright (c) 2017 TokenStars
// Made by Aler Denisov
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.







contract TeamToken is StarTokenInterface {
    using SafeMath for uint256;
    
    // ERC20 constants
    string public constant name = "TEAM";
    string public constant symbol = "TEAM";
    uint public constant decimals = 4;

    // Minting constants
    uint256 public constant MAXSOLD_SUPPLY = 450000000000;
    uint256 public constant HARDCAPPED_SUPPLY = 750000000000;

    uint256 public investorSupply = 0;
    uint256 public extraSupply = 0;
    uint256 public freeToExtraMinting = 0;

    uint256 public constant DISTRIBUTION_INVESTORS = 60;
    uint256 public constant DISTRIBUTION_TEAM      = 20;
    uint256 public constant DISTRIBUTION_COMMUNITY = 20;

    address public teamTokensHolder;
    address public communityTokensHolder;

    // Transfer rules
    bool public transferAllowed = false;
    mapping (address=>bool) public specialAllowed;

    // Transfer rules events
    // event TransferAllowed();
    // event TransferAllowanceFor(address indexed who, bool indexed state);

    // Holders events
    event ChangeCommunityHolder(address indexed from, address indexed to);
    event ChangeTeamHolder(address indexed from, address indexed to);

    /**
    * @dev check transfer is allowed
    */
    modifier allowTransfer() {
        require(transferAllowed || specialAllowed[msg.sender]);
        _;
    }

    function TeamToken() public {
      teamTokensHolder = msg.sender;
      communityTokensHolder = msg.sender;

      ChangeTeamHolder(0x0, teamTokensHolder);
      ChangeCommunityHolder(0x0, communityTokensHolder);
    }

    /**
    * @dev change team tokens holder
    * @param _tokenHolder The address of next team tokens holder
    */
    function setTeamTokensHolder(address _tokenHolder) onlyOwner public returns (bool) {
      require(_tokenHolder != 0);
      address temporaryEventAddress = teamTokensHolder;
      teamTokensHolder = _tokenHolder;
      ChangeTeamHolder(temporaryEventAddress, teamTokensHolder);
      return true;
    }

    /**
    * @dev change community tokens holder
    * @param _tokenHolder The address of next community tokens holder
    */
    function setCommunityTokensHolder(address _tokenHolder) onlyOwner public returns (bool) {
      require(_tokenHolder != 0);
      address temporaryEventAddress = communityTokensHolder;
      communityTokensHolder = _tokenHolder;
      ChangeCommunityHolder(temporaryEventAddress, communityTokensHolder);
      return true;
    }

    /**
    * @dev Doesn&#39;t allow to send funds on contract!
    */
    function () payable public {
        require(false);
    }

    /**
    * @dev transfer token for a specified address if transfer is open
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) allowTransfer public returns (bool) {
        return super.transfer(_to, _value);
    }

    
    /**
    * @dev Transfer tokens from one address to another if transfer is open
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) allowTransfer public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Open transfer for everyone or throws
     */
    function openTransfer() onlyOwner public returns (bool) {
        require(!transferAllowed);
        transferAllowed = true;
        TransferAllowed();
        return true;
    }

    /**
    * @dev allow transfer for the given address against global rules
    * @param _for addres The address of special allowed transfer (required for smart contracts)
     */
    function toggleTransferFor(address _for) onlyOwner public returns (bool) {
        specialAllowed[_for] = !specialAllowed[_for];
        TransferAllowanceFor(_for, specialAllowed[_for]);
        return specialAllowed[_for];
    }

    /**
    * @dev Function to mint tokens for investor
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to emit.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(_amount > 0);
        totalSupply_ = totalSupply_.add(_amount);
        investorSupply = investorSupply.add(_amount);
        freeToExtraMinting = freeToExtraMinting.add(_amount);

        // Prevent to emit more than sale hardcap!
        assert(investorSupply <= MAXSOLD_SUPPLY);
        assert(totalSupply_ <= HARDCAPPED_SUPPLY);

        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(this), _to, _amount);
        return true;
    }


    /**
    * @dev Mint extra token to corresponding token and community holders
    */
    function extraMint() onlyOwner canMint public returns (bool) {
      require(freeToExtraMinting > 0);

      uint256 onePercent = freeToExtraMinting / DISTRIBUTION_INVESTORS;
      uint256 teamPart = onePercent * DISTRIBUTION_TEAM;
      uint256 communityPart = onePercent * DISTRIBUTION_COMMUNITY;
      uint256 extraTokens = teamPart.add(communityPart);

      totalSupply_ = totalSupply_.add(extraTokens);
      extraSupply = extraSupply.add(extraTokens);

      uint256 leftToNextMinting = freeToExtraMinting % DISTRIBUTION_INVESTORS;
      freeToExtraMinting = leftToNextMinting;

      assert(totalSupply_ <= HARDCAPPED_SUPPLY);
      assert(extraSupply <= HARDCAPPED_SUPPLY.sub(MAXSOLD_SUPPLY));

      balances[teamTokensHolder] = balances[teamTokensHolder].add(teamPart);
      balances[communityTokensHolder] = balances[communityTokensHolder].add(communityPart);

      Mint(teamTokensHolder, teamPart);
      Transfer(address(this), teamTokensHolder, teamPart);
      Mint(communityTokensHolder, communityPart);
      Transfer(address(this), communityTokensHolder, communityPart);

      return true;
    }

    /**
    * @dev Increase approved amount to spend 
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase already approved amount. 
     */
    function increaseApproval (address _spender, uint _addedValue)  public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease approved amount to spend 
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease already approved amount. 
     */
    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


    function finilize() onlyOwner public returns (bool) {
        require(mintingFinished);
        require(transferAllowed);

        owner = 0x0;
        return true;
    }
}