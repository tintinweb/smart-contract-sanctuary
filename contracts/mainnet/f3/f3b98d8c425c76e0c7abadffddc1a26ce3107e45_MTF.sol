pragma solidity ^0.4.21;

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
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

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
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
  function mint(address _to, uint256 _amount) canMint internal returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() canMint internal returns (bool) {
    mintingFinished = true;
    emit MintFinished();
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MTF is MintableToken, Ownable {

    using SafeMath for uint256;
    //The name of the  token
    string public constant name = "MintFlint Token";
    //The token symbol
    string public constant symbol = "MTF";
    //The precision used in the balance calculations in contract
    uint8 public constant decimals = 18;

    //maximum cap to be sold on ICO
    uint256 public constant maxCap = 1500000000e18;
    //to save total number of ethers received
    uint256 public totalWeiReceived;

    //time when the sale starts
    uint256 public startTime;
    //time when the presale ends
    uint256 public endTime;
    //to check the sale status
    bool public paused;

    //events
    event StateChanged(bool);
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    function MTF(uint256 _startTime, uint256 _endTime) public {
        startTime = _startTime;
        endTime = _endTime;
        paused = false;
        totalSupply_ = 0;
    }

    modifier whenSaleEnded() {
        require(now >= endTime);
        _;
    }

    /**
     * @dev to determine the timeframe of sale
     */
    modifier validTimeframe() {
        require(!paused && now >=startTime && now < endTime);
        _;
    }

    /**
     * @dev Allocate tokens to team members
     */
    function teamAllocation(address _airdropAddress) public onlyOwner whenSaleEnded {
        uint256 toDistribute = totalSupply_.mul(2);
        // Receiver1 3.0%
        uint256 part1 = toDistribute.mul(3).div(400);
        mint(0x1117Db9F1bf18C91233Bff3BF2676137709463B3, part1);
        mint(0x6C137b489cEE58C32fd8Aec66EAdC4B959550198, part1);
        mint(0x450023b2D943498949f0A9cdb1DbBd827844EE78, part1);
        mint(0x89080db76A555c42D7b43556E40AcaAFeB786CDD, part1);

        // Receiver2 19.5%
        uint256 part2 = toDistribute.mul(195).div(4000);
        mint(0xcFc43257606C6a642d9438dCd82bf5b39A17dbAB, part2);
        mint(0x4a8C5Ea0619c40070f288c8aC289ef2f6Bb87cff, part2);
        mint(0x947251376EeAFb0B0CD1bD47cC6056A5162bEaF4, part2);
        mint(0x39A49403eFB1e85F835A9e5dc82706B970D112e4, part2);

        // Receiver3 2.0% 0x733bc7201261aC3c9508D20a811D99179304240a
        mint(0x733bc7201261aC3c9508D20a811D99179304240a, toDistribute.mul(2).div(100));

        // Receiver4 18.0% 0x4b6716bd349dC65d07152844ed4990C2077cF1a7
        mint(0x4b6716bd349dC65d07152844ed4990C2077cF1a7, toDistribute.mul(18).div(100));

        // Receiver5 6% 0xEf628A29668C00d5C7C4D915F07188dC96cF24eb
        uint256 part5 = toDistribute.mul(6).div(400);
        mint(0xEf628A29668C00d5C7C4D915F07188dC96cF24eb, part5);
        mint(0xF28a5e85316E0C950f8703e2d99F15A7c077014c, part5);
        mint(0x0c8C9Dcfa4ed27e02349D536fE30957a32b44a04, part5);
        mint(0x0A86174f18D145D3850501e2f4C160519207B829, part5);

        // Receiver6 1.50%
        // 0.75% in 0x35eeb3216E2Ff669F2c1Ff90A08A22F60e6c5728 and
        // 0.75% in 0x28dcC9Af670252A5f76296207cfcC29B4E3C68D5
        mint(0x35eeb3216E2Ff669F2c1Ff90A08A22F60e6c5728, toDistribute.mul(75).div(10000));
        mint(0x28dcC9Af670252A5f76296207cfcC29B4E3C68D5, toDistribute.mul(75).div(10000));

        mint(_airdropAddress, 175000000 ether);

        finishMinting();
    }

    function transfer(address _to, uint _value) whenSaleEnded public returns(bool _success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) whenSaleEnded public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Calculate number of tokens that will be received in one ether
    *
    */
    function getPrice() public pure returns(uint256) {
        return 100000;
    }

    /**
    * @dev to enable pause sale for break in ICO and Pre-ICO
    *
    */
    function pauseSale() public onlyOwner {
        require(!paused);
        paused = true;
    }

    /**
    * @dev to resume paused sale
    *
    */
    function resumeSale() public onlyOwner {
        require(paused);
        paused = false;
    }

    function buyTokens(address beneficiary) internal validTimeframe {
        uint256 tokensBought = msg.value.mul(getPrice());
        totalWeiReceived = totalWeiReceived.add(msg.value);
        emit TokenPurchase(beneficiary, msg.value, tokensBought);
        mint(beneficiary, tokensBought);
        require(totalSupply_ <= maxCap);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev Failsafe drain.
    */
    function drain() public onlyOwner whenSaleEnded {
        owner.transfer(address(this).balance);
    }
}