pragma solidity ^0.4.21;

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  
  struct Purchase {
    uint256 buyAmount;
    uint256 transferredAmount;
    uint256 purchaseBlock;
  }

  mapping(address => uint256) balances;
  mapping(address => Purchase[]) public presaleInvestors;
  mapping(address => uint256) public mainSaleInvestors;
  
  uint256 totalSupply_;
  uint256 public secondsPerBlock = 147; // change to 14
  uint256 public startLockUpSec = 3888000; // 45 days => 3888000 secs
  uint256 public secondsPerMonth = 2592000; // 30 days => 2592000 secs
  uint256 public percentagePerMonth = 10;
  
    function _checkLockUp(address senderAdr) public view returns (uint) {
        uint canTransfer = 0;
        if (presaleInvestors[senderAdr].length == 0) {
            canTransfer = 0;
        } else if (presaleInvestors[senderAdr][0].purchaseBlock > block.number.sub(startLockUpSec.div(secondsPerBlock).mul(10))) {
            canTransfer = 0;
        } else {
            for (uint i = 0; i < presaleInvestors[senderAdr].length; i++) {
                if (presaleInvestors[senderAdr][i].purchaseBlock <= (block.number).sub(startLockUpSec.div(secondsPerBlock).mul(10))) {
                    uint months = (block.number.sub(presaleInvestors[senderAdr][i].purchaseBlock)).div(secondsPerMonth);
                    if (months > 10) {
                        months = 10;
                    }
                    uint actAmount = (presaleInvestors[senderAdr][i].buyAmount).mul(months).mul(percentagePerMonth).div(100);
                    uint realAmout = actAmount.sub(presaleInvestors[senderAdr][i].transferredAmount);
                    canTransfer = canTransfer.add(realAmout);
                } else {
                    break;
                }
            }
        }
        return canTransfer.add(mainSaleInvestors[senderAdr]);
    }
    
    function cleanTokensAmount(address senderAdr, uint256 currentTokens) public returns (bool) {
        if (presaleInvestors[senderAdr].length != 0) {
            for (uint i = 0; i < presaleInvestors[senderAdr].length; i++) {
                if (presaleInvestors[senderAdr][i].transferredAmount == presaleInvestors[senderAdr][i].buyAmount) {
                    continue;
                }
                if (presaleInvestors[senderAdr][i].purchaseBlock <= (block.number).sub(startLockUpSec.div(secondsPerBlock).mul(10))) {
                    uint months = (block.number.sub(presaleInvestors[senderAdr][i].purchaseBlock)).div(secondsPerMonth);
                    if (months > 10) {
                        months = 10;
                    }
                    if ((presaleInvestors[senderAdr][i].buyAmount.div(100).mul(months).mul(percentagePerMonth) - presaleInvestors[senderAdr][i].transferredAmount) >= currentTokens) {
                        presaleInvestors[senderAdr][i].transferredAmount = presaleInvestors[senderAdr][i].transferredAmount + currentTokens;
                        currentTokens = 0;
                    } 
                    if ((presaleInvestors[senderAdr][i].buyAmount.div(100).mul(months).mul(percentagePerMonth) - presaleInvestors[senderAdr][i].transferredAmount) < currentTokens) {
                        uint remainder = currentTokens - (presaleInvestors[senderAdr][i].buyAmount.div(100).mul(months).mul(percentagePerMonth) - presaleInvestors[senderAdr][i].transferredAmount);
                        presaleInvestors[senderAdr][i].transferredAmount = presaleInvestors[senderAdr][i].buyAmount.div(100).mul(months).mul(percentagePerMonth);
                        currentTokens = remainder;
                    }
                } else {
                    continue;
                }
            }
            
            if (currentTokens <= mainSaleInvestors[senderAdr]) {
                mainSaleInvestors[senderAdr] = mainSaleInvestors[senderAdr] - currentTokens;
                currentTokens = 0;
            } else {
                revert();
            }
        } else {
            if (currentTokens <= mainSaleInvestors[senderAdr]) {
                mainSaleInvestors[senderAdr] = mainSaleInvestors[senderAdr] - currentTokens;
                currentTokens = 0;
            } else {
                revert();
            }
        }
        
        if (currentTokens != 0) {
            revert();
        }
    }

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
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    require(_checkLockUp(msg.sender) >= _value);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    cleanTokensAmount(msg.sender, _value);
    mainSaleInvestors[_to] = mainSaleInvestors[_to].add(_value);

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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
    require(_checkLockUp(_who) >= _value);

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
    cleanTokensAmount(_who, _value);
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BurnableToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value > 0);
    require(_value <= allowed[_from][msg.sender]);
    require(_checkLockUp(_from) >= _value);


    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    cleanTokensAmount(_from, _value);
    mainSaleInvestors[_to] = mainSaleInvestors[_to].add(_value);
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
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
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
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
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    mainSaleInvestors[_to] = mainSaleInvestors[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract WiredToken is MintableToken {
    
    string public constant name = "Wired Token";
    string public constant symbol = "WRD";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 410000000000000000000; // 10^28
    
    address public agent;
    uint256 public distributeAmount = 41000000000000000000;
    uint256 public mulbonus = 1000;
    uint256 public divbonus = 10000000000;
    bool public presalePart = true;

    modifier onlyAgent() {
        require(msg.sender == owner || msg.sender == agent);
        _;
    }

    function WiredToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[address(this)] = INITIAL_SUPPLY;
        mainSaleInvestors[address(this)] = INITIAL_SUPPLY;
        agent = msg.sender;
    }

    /**
     * @dev Function to distribute tokens to the list of addresses by the provided amount
     */
    function distributeAirdrop(address[] addresses, uint256 amount) external onlyAgent {
        require(amount > 0 && addresses.length > 0);

        uint256 amounts = amount.mul(100000000);
        uint256 totalAmount = amounts.mul(addresses.length);
        require(balances[address(this)] >= totalAmount);
        
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != 0x0);

            balances[addresses[i]] = balances[addresses[i]].add(amounts);
            emit Transfer(address(this), addresses[i], amounts);
            mainSaleInvestors[addresses[i]] = mainSaleInvestors[addresses[i]].add(amounts);
        }
        balances[address(this)] = balances[address(this)].sub(totalAmount);
        mainSaleInvestors[address(this)] = mainSaleInvestors[address(this)].sub(totalAmount);
    }

    function distributeAirdropMulti(address[] addresses, uint256[] amount) external onlyAgent {
        require(addresses.length > 0 && addresses.length == amount.length);
        
        uint256 totalAmount = 0;
        
        for(uint i = 0; i < addresses.length; i++) {
            require(amount[i] > 0 && addresses[i] != 0x0);
                    
            uint256 amounts = amount[i].mul(100000000);
            totalAmount = totalAmount.add(amounts);

            require(balances[address(this)] >= totalAmount);
        
            balances[addresses[i]] = balances[addresses[i]].add(amounts);
            emit Transfer(address(this), addresses[i], amounts);
            mainSaleInvestors[addresses[i]] = mainSaleInvestors[addresses[i]].add(amounts);
        }
        balances[address(this)] = balances[address(this)].sub(totalAmount);
        mainSaleInvestors[address(this)] = mainSaleInvestors[address(this)].sub(totalAmount);

    }
    
    function distributeAirdropMultiPresale(address[] addresses, uint256[] amount, uint256[] blocks) external onlyAgent {
        require(addresses.length > 0 && addresses.length == amount.length);
        
        uint256 totalAmount = 0;
        
        for(uint i = 0; i < addresses.length; i++) {
            require(amount[i] > 0 && addresses[i] != 0x0);
                    
            uint256 amounts = amount[i].mul(100000000);
            totalAmount = totalAmount.add(amounts);

            require(balances[address(this)] >= totalAmount);
        
            presaleInvestors[addresses[i]].push(Purchase(amounts, 0, blocks[i]));
            balances[addresses[i]] = balances[addresses[i]].add(amounts);
            emit Transfer(address(this), addresses[i], amounts);
        }
        balances[address(this)] = balances[address(this)].sub(totalAmount);
        mainSaleInvestors[address(this)] = mainSaleInvestors[address(this)].sub(totalAmount);

    }

    function setDistributeAmount(uint256 _unitAmount) onlyOwner external {
        distributeAmount = _unitAmount;
    }
    
    function setMulBonus(uint256 _mulbonus) onlyOwner external {
        mulbonus = _mulbonus;
    }
    
    function setDivBonus(uint256 _divbonus) onlyOwner external {
        divbonus = _divbonus;
    }

    function setNewAgent(address _agent) external onlyOwner {
        require(agent != address(0));
        agent = _agent;
    }
    
    function changeTime(uint256 _time) external onlyOwner {
        secondsPerBlock = _time;
    }
    
    function transferFund() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function transferTokens(uint256 amount) external onlyOwner {
        require(balances[address(this)] > 0);
        

        balances[msg.sender] = balances[msg.sender].add(amount.mul(100000000));
        balances[address(this)] = balances[address(this)].sub(amount.mul(100000000));
        emit Transfer(address(this), msg.sender, balances[address(this)]);
        mainSaleInvestors[msg.sender] = mainSaleInvestors[msg.sender].add(amount.mul(100000000));
        mainSaleInvestors[address(this)] = mainSaleInvestors[address(this)].sub(amount.mul(100000000));
    }

    /**
     * @dev Function to distribute tokens to the msg.sender automatically
     *      If distributeAmount is 0, this function doesn&#39;t work
     */
    function buy(address buyer) payable public {
        require(msg.value > 10000000000000 && distributeAmount > 0 && balances[address(this)] > distributeAmount);
        
        uint256 amount = msg.value.mul(mulbonus).div(divbonus);
        balances[buyer] = balances[buyer].add(amount);
        emit Transfer(address(this), buyer, amount);
        
        if (presalePart) {
            presaleInvestors[buyer].push(Purchase(amount, 0, block.number)); 
        } else {
            mainSaleInvestors[buyer] = mainSaleInvestors[buyer].add(amount);
        }

        mainSaleInvestors[address(this)] = mainSaleInvestors[address(this)].sub(amount);
        balances[address(this)] = balances[address(this)].sub(amount);
        distributeAmount = distributeAmount.sub(amount);
    }

    /**
     * @dev fallback function
     */
    function() payable public {
        buy(msg.sender);
    }   
}