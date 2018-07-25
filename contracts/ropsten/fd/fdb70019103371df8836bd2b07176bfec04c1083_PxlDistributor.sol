pragma solidity ^0.4.24;

// File: contracts/contents/ContentInterface.sol

contract ContentInterface {
    function updateContent(string _record, uint256 _marketerRate) external;
    function addEpisode(string _record, uint256 _price) external;
    function getRecord() public view returns (string);
    function getWriter() public view returns (address);
    function getMarketerRate() public view returns (uint256);
    function getEpisodes() public view returns (address[]);
    event RegisterContents(address _sender, string _name);
    event CreateEpisode(address _sender, address _contractAddr);
}

// File: contracts/contents/EpisodeInterface.sol

contract EpisodeInterface {
    function updateEpisode(string _record, uint256 _price) external;
    function getPurchasedAmount() public view returns (uint256);
    function getIsPurchased(address _buyer) public view returns (bool);
    function getRecord() public view returns (string);
    function getWriter() public view returns (address);
    function getPrice() public view returns (uint256);
    function getBuyCount() public view returns (uint256);
    function getContentAddress() public view returns (address);
    function episodePurchase(address _buyer, uint256 _amount) external;
    event RegisterContents(address _addr, string _name);
    event EpisodePurchase(address _sender, address _buyer);
}

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: contracts/utils/ValidValue.sol

contract ValidValue {
  modifier validRange(uint256 _value) {
      require(_value > 0);
      _;
  }

  modifier validAddress(address _account) {
      require(_account != address(0));
      require(_account != address(this));
      _;
  }

  modifier validString(string _str) {
      require(bytes(_str).length > 0);
      _;
  }
}

// File: contracts/council/Council.sol

/**
 * @title Council contract
 *
 * @author Junghoon Seo - <jh.seo@battleent.com>
 */
contract Council is ExtendsOwnable, ValidValue {
    uint256 public cdRate;
    uint256 public depositRate;
    uint256 public initialDeposit;
    uint256 public userPaybackRate;
    uint256 public reportRegistrationFee;
    address public userPaybackPool;
    address public depositPool;
    address public token;
    address public roleManager;
    address public contentsManager;
    address public pixelDistributor;
    address public marketer;

    constructor(
        uint256 _cdRate,
        uint256 _depositRate,
        uint256 _initialDeposit,
        uint256 _userPaybackRate,
        uint256 _reportRegistrationFee,
        address _token)
        public
        validRange(_cdRate)
        validRange(_depositRate)
        validRange(_initialDeposit)
        validRange(_userPaybackRate)
        validRange(_reportRegistrationFee)
        validAddress(_token)
    {
        cdRate = _cdRate;
        depositRate = _depositRate;
        initialDeposit = _initialDeposit;
        userPaybackRate = _userPaybackRate;
        reportRegistrationFee = _reportRegistrationFee;
        token = _token;

        emit RegisterCouncil(msg.sender, _cdRate, _depositRate, _initialDeposit, _userPaybackRate, _reportRegistrationFee, _token);
    }

    function setCdRate(uint256 _cdRate) external onlyOwner validRange(_cdRate) {
        cdRate = _cdRate;

        emit ChangeDistributionRate(msg.sender, &quot;cd rate&quot;, _cdRate);
    }

    function setDepositRate(uint256 _depositRate) external onlyOwner validRange(_depositRate) {
        depositRate = _depositRate;

        emit ChangeDistributionRate(msg.sender, &quot;deposit rate&quot;, _depositRate);
    }

    function setInitialDeposit(uint256 _initialDeposit) external onlyOwner validRange(_initialDeposit) {
        initialDeposit = _initialDeposit;

        emit ChangeDistributionRate(msg.sender, &quot;initial deposit&quot;, _initialDeposit);
    }

    function setUserPaybackRate(uint256 _userPaybackRate) external onlyOwner validRange(_userPaybackRate) {
        userPaybackRate = _userPaybackRate;

        emit ChangeDistributionRate(msg.sender, &quot;user payback rate&quot;, _userPaybackRate);
    }

    function setReportRegistrationFee(uint256 _reportRegistrationFee) external onlyOwner validRange(_reportRegistrationFee) {
        reportRegistrationFee = _reportRegistrationFee;

        emit ChangeDistributionRate(msg.sender, &quot;report registration fee&quot;, _reportRegistrationFee);
    }

    function setUserPaybackPool(address _userPaybackPool) external onlyOwner validAddress(_userPaybackPool) {
        userPaybackPool = _userPaybackPool;

        emit ChangeAddress(msg.sender, &quot;user payback pool&quot;, _userPaybackPool);
    }

    function setRoleManager(address _roleManager) external onlyOwner validAddress(_roleManager) {
        roleManager = _roleManager;

        emit ChangeAddress(msg.sender, &quot;role manager&quot;, _roleManager);
    }

    function setContentsManager(address _contentsManager) external onlyOwner validAddress(_contentsManager) {
        contentsManager = _contentsManager;

        emit ChangeAddress(msg.sender, &quot;contents manager&quot;, _contentsManager);
    }

    function setPixelDistributor(address _pixelDistributor) external onlyOwner validAddress(_pixelDistributor) {
        pixelDistributor = _pixelDistributor;

        emit ChangeAddress(msg.sender, &quot;pixel distributor&quot;, _pixelDistributor);
    }

    function setMarketer(address _marketer) external onlyOwner validAddress(_marketer) {
        marketer = _marketer;

        emit ChangeAddress(msg.sender, &quot;marketer&quot;, _marketer);
    }

    event RegisterCouncil(address _sender, uint256 _cdRate, uint256 _deposit, uint256 _initialDeposit, uint256 _userPaybackRate, uint256 _reportRegistrationFee, address _token);
    event ChangeDistributionRate(address _sender, string _name, uint256 _value);
    event ChangeAddress(address _sender, string addressName, address _addr);
}

// File: contracts/marketer/Marketer.sol

/**
 * @title Marketer contract
 *
 * @author Junghoon Seo - <jh.seo@battleent.com>
 */
contract Marketer is ValidValue {
  mapping (bytes32 => address) marketerInfo;

  function getMarketerKey() public validAddress(msg.sender) returns(bytes32) {
      bytes32 key = bytes32(keccak256(abi.encodePacked(msg.sender)));
      marketerInfo[key] = msg.sender;

      return key;
  }

  function getMarketerAddress(bytes32 _key) public validAddress(msg.sender) view returns(address) {
      return marketerInfo[_key];
  }
}

// File: contracts/token/ContractReceiver.sol

contract ContractReceiver {
    function receiveApproval(address _from, uint256 _value, address _token, string _jsonData) public;
}

// File: contracts/token/CustomToken.sol

contract CustomToken {
    function approveAndCall(address _to, uint256 _value, string _jsonData) public returns (bool);
    event ApproveAndCall(address indexed _from, address indexed _to, uint256 _value, string _jsonData);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

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
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/token/PXL.sol

/**
 * @title PXL implementation based on StandardToken ERC-20 contract.
 *
 * @author Charls Kim - <cs.kim@battleent.com>
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract PXL is StandardToken, CustomToken, ExtendsOwnable {
    using SafeMath for uint256;

    // Token basic information
    string public constant name = &quot;Pixel&quot;;
    string public constant symbol = &quot;PXL&quot;;
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    // Token is non-transferable until owner calls unlock()
    // (to prevent OTC before the token to be listed on exchanges)
    bool isTransferable = false;

    /**
     * @dev PXL constrcutor
     *
     * @param initialSupply Initial PXL token supply to issue.
     */
    constructor(uint256 initialSupply) public {
        require(initialSupply > 0);

        totalSupply = initialSupply;
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function() public payable {
        revert();
    }

    /**
     * @dev unlock PXL transfer
     *
     * @notice token contract is initially locked.
     * @notice contract owner should unlock to enable transaction.
     */
    function unlock() external onlyOwner {
        isTransferable = true;
    }

    function getTokenTransferable() external view returns (bool) {
        return isTransferable;
    }

    /**
     * @dev Transfer tokens from one address to another
     *
     * @notice override transferFrom to block transaction when contract was locked.
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return A boolean that indicates if transfer was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Transfer token for a specified address
     *
     * @notice override transfer to block transaction when contract was locked.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     * @return A boolean that indicates if transfer was successful.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transfer(_to, _value);
    }

    function approveAndCall(address _to, uint256 _value, string _jsonData) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        require(_to != address(0) && _to != address(this));
        require(balances[msg.sender] >= _value);

        if(approve(_to, _value) && isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.receiveApproval(msg.sender, _value, address(this), _jsonData);
            emit ApproveAndCall(msg.sender, _to, _value, _jsonData);

            return true;
        }
    }

    /**
     * @dev Function to mint tokens
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(uint256 _amount) onlyOwner public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);

        emit Mint(msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
        return true;
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param _amount The amount of token to be burned.
     */
    function burn(uint256 _amount) onlyOwner public {
        require(_amount <= balances[msg.sender]);

        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        emit Burn(msg.sender, _amount);
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
        length := extcodesize(_addr)
        }
        return (length > 0);
    }

    event Mint(address indexed _to, uint256 _amount);
    event Burn(address indexed _from, uint256 _amount);
}

// File: contracts/utils/JsmnSolLib.sol

/*
Copyright (c) 2017 Christoph Niemann
Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the &quot;Software&quot;), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.4.24;

library JsmnSolLib {

  enum JsmnType {UNDEFINED, OBJECT, ARRAY, STRING, PRIMITIVE}

  uint constant RETURN_SUCCESS = 0;
  uint constant RETURN_ERROR_INVALID_JSON = 1;
  uint constant RETURN_ERROR_PART = 2;
  uint constant RETURN_ERROR_NO_MEM = 3;

  struct Token {
    JsmnType jsmnType;
    uint start;
    bool startSet;
    uint end;
    bool endSet;
    uint8 size;
  }

  struct Parser {
    uint pos;
    uint toknext;
    int toksuper;
  }

  function init(uint length) pure internal returns (Parser, Token[]) {
    Parser memory p = Parser(0, 0, - 1);
    Token[] memory t = new Token[](length);
    return (p, t);
  }

  function allocateToken(Parser parser, Token[] tokens) pure internal returns (bool, Token) {
    if (parser.toknext >= tokens.length) {
      // no more space in tokens
      return (false, tokens[tokens.length - 1]);
    }
    Token memory token = Token(JsmnType.UNDEFINED, 0, false, 0, false, 0);
    tokens[parser.toknext] = token;
    parser.toknext++;
    return (true, token);
  }

  function fillToken(Token token, JsmnType jsmnType, uint start, uint end) pure internal {
    token.jsmnType = jsmnType;
    token.start = start;
    token.startSet = true;
    token.end = end;
    token.endSet = true;
    token.size = 0;
  }

  function parseString(Parser parser, Token[] tokens, bytes s) pure internal returns (uint) {
    uint start = parser.pos;
    bool success;
    Token memory token;
    parser.pos++;

    for (; parser.pos < s.length; parser.pos++) {
      bytes1 c = s[parser.pos];

      // Quote -> end of string
      if (c == &#39;&quot;&#39;) {
        (success, token) = allocateToken(parser, tokens);
        if (!success) {
          parser.pos = start;
          return RETURN_ERROR_NO_MEM;
        }
        fillToken(token, JsmnType.STRING, start + 1, parser.pos);
        return RETURN_SUCCESS;
      }

      if (c == 92 && parser.pos + 1 < s.length) {
        // handle escaped characters: skip over it
        parser.pos++;
        if (s[parser.pos] == &#39;\&quot;&#39; || s[parser.pos] == &#39;/&#39; || s[parser.pos] == &#39;\\&#39;
        || s[parser.pos] == &#39;f&#39; || s[parser.pos] == &#39;r&#39; || s[parser.pos] == &#39;n&#39;
        || s[parser.pos] == &#39;b&#39; || s[parser.pos] == &#39;t&#39;) {
          continue;
        } else {
          // all other values are INVALID
          parser.pos = start;
          return (RETURN_ERROR_INVALID_JSON);
        }
      }
    }
    parser.pos = start;
    return RETURN_ERROR_PART;
  }

  function parsePrimitive(Parser parser, Token[] tokens, bytes s) pure internal returns (uint) {
    bool found = false;
    uint start = parser.pos;
    byte c;
    bool success;
    Token memory token;

    for (; parser.pos < s.length; parser.pos++) {
      c = s[parser.pos];
      if (c == &#39; &#39; || c == &#39;\t&#39; || c == &#39;\n&#39; || c == &#39;\r&#39; || c == &#39;,&#39;
      || c == 0x7d || c == 0x5d) {
        found = true;
        break;
      }
      if (c < 32 || c > 127) {
        parser.pos = start;
        return RETURN_ERROR_INVALID_JSON;
      }
    }
    if (!found) {
      parser.pos = start;
      return RETURN_ERROR_PART;
    }

    // found the end
    (success, token) = allocateToken(parser, tokens);
    if (!success) {
      parser.pos = start;
      return RETURN_ERROR_NO_MEM;
    }
    fillToken(token, JsmnType.PRIMITIVE, start, parser.pos);
    parser.pos--;
    return RETURN_SUCCESS;
  }

  function parse(string json, uint numberElements) pure internal returns (uint, Token[], uint) {
    bytes memory s = bytes(json);
    Parser memory parser;
    bool success;
    (parser, tokens) = init(numberElements);
    JsmnSolLib.Token[] memory tokens;
    Token memory token;

    // Token memory token;
    uint r;
    uint count = parser.toknext;
    uint i;

    for (; parser.pos < s.length; parser.pos++) {
      bytes1 c = s[parser.pos];

      // 0x7b, 0x5b opening curly parentheses or brackets
      if (c == 0x7b || c == 0x5b) {
        count++;
        (success, token) = allocateToken(parser, tokens);
        if (!success) {
          return (RETURN_ERROR_NO_MEM, tokens, 0);
        }
        if (parser.toksuper != - 1) {
          tokens[uint(parser.toksuper)].size++;
        }
        token.jsmnType = (c == 0x7b ? JsmnType.OBJECT : JsmnType.ARRAY);
        token.start = parser.pos;
        token.startSet = true;
        parser.toksuper = int(parser.toknext - 1);
        continue;
      }

      // closing curly parentheses or brackets
      if (c == 0x7d || c == 0x5d) {
        JsmnType tokenType = (c == 0x7d ? JsmnType.OBJECT : JsmnType.ARRAY);
        bool isUpdated = false;
        for (i = parser.toknext - 1; i >= 0; i--) {
          token = tokens[i];
          if (token.startSet && !token.endSet) {
            if (token.jsmnType != tokenType) {
              // found a token that hasn&#39;t been closed but from a different type
              return (RETURN_ERROR_INVALID_JSON, tokens, 0);
            }
            parser.toksuper = - 1;
            tokens[i].end = parser.pos + 1;
            tokens[i].endSet = true;
            isUpdated = true;
            break;
          }
        }
        if (!isUpdated) {
          return (RETURN_ERROR_INVALID_JSON, tokens, 0);
        }
        for (; i > 0; i--) {
          token = tokens[i];
          if (token.startSet && !token.endSet) {
            parser.toksuper = int(i);
            break;
          }
        }

        if (i == 0) {
          token = tokens[i];
          if (token.startSet && !token.endSet) {
            parser.toksuper = uint128(i);
          }
        }
        continue;
      }

      // 0x42
      if (c == &#39;&quot;&#39;) {
        r = parseString(parser, tokens, s);

        if (r != RETURN_SUCCESS) {
          return (r, tokens, 0);
        }
        //JsmnError.INVALID;
        count++;
        if (parser.toksuper != - 1)
          tokens[uint(parser.toksuper)].size++;
        continue;
      }

      // &#39; &#39;, \r, \t, \n
      if (c == &#39; &#39; || c == 0x11 || c == 0x12 || c == 0x14) {
        continue;
      }

      // 0x3a
      if (c == &#39;:&#39;) {
        parser.toksuper = int(parser.toknext - 1);
        continue;
      }

      if (c == &#39;,&#39;) {
        if (parser.toksuper != - 1
        && tokens[uint(parser.toksuper)].jsmnType != JsmnType.ARRAY
        && tokens[uint(parser.toksuper)].jsmnType != JsmnType.OBJECT) {
          for (i = parser.toknext - 1; i >= 0; i--) {
            if (tokens[i].jsmnType == JsmnType.ARRAY || tokens[i].jsmnType == JsmnType.OBJECT) {
              if (tokens[i].startSet && !tokens[i].endSet) {
                parser.toksuper = int(i);
                break;
              }
            }
          }
        }
        continue;
      }

      // Primitive
      if ((c >= &#39;0&#39; && c <= &#39;9&#39;) || c == &#39;-&#39; || c == &#39;f&#39; || c == &#39;t&#39; || c == &#39;n&#39;) {
        if (parser.toksuper != - 1) {
          token = tokens[uint(parser.toksuper)];
          if (token.jsmnType == JsmnType.OBJECT
          || (token.jsmnType == JsmnType.STRING && token.size != 0)) {
            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
          }
        }

        r = parsePrimitive(parser, tokens, s);
        if (r != RETURN_SUCCESS) {
          return (r, tokens, 0);
        }
        count++;
        if (parser.toksuper != - 1) {
          tokens[uint(parser.toksuper)].size++;
        }
        continue;
      }

      // printable char
      if (c >= 0x20 && c <= 0x7e) {
        return (RETURN_ERROR_INVALID_JSON, tokens, 0);
      }
    }

    return (RETURN_SUCCESS, tokens, parser.toknext);
  }

  function getBytes(string json, uint start, uint end) pure internal returns (string) {
    bytes memory s = bytes(json);
    bytes memory result = new bytes(end - start);
    for (uint i = start; i < end; i++) {
      result[i - start] = s[i];
    }
    return string(result);
  }

  // parseInt
  function parseInt(string _a) pure internal returns (int) {
    return parseInt(_a, 0);
  }

  // parseInt(parseFloat*10^_b)
  function parseInt(string _a, uint _b) pure internal returns (int) {
    bytes memory bresult = bytes(_a);
    int mint = 0;
    bool decimals = false;
    bool negative = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((i == 0) && (bresult[i] == &#39;-&#39;)) {
        negative = true;
      }
      if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
        if (decimals) {
          if (_b == 0) break;
          else _b--;
        }
        mint *= 10;
        mint += int(bresult[i]) - 48;
      } else if (bresult[i] == 46) decimals = true;
    }
    if (_b > 0) mint *= int(10 ** _b);
    if (negative) mint *= - 1;
    return mint;
  }

  function uint2str(uint i) pure internal returns (string){
    if (i == 0) return &quot;0&quot;;
    uint j = i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (i != 0) {
      bstr[k--] = byte(48 + i % 10);
      i /= 10;
    }
    return string(bstr);
  }

  function parseBool(string _a) pure public returns (bool) {
    if (strCompare(_a, &#39;true&#39;) == 0) {
      return true;
    } else {
      return false;
    }
  }

  function strCompare(string _a, string _b) pure internal returns (int) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    uint minLength = a.length;
    if (b.length < minLength) minLength = b.length;
    for (uint i = 0; i < minLength; i ++)
      if (a[i] < b[i])
        return - 1;
      else if (a[i] > b[i])
        return 1;
    if (a.length < b.length)
      return - 1;
    else if (a.length > b.length)
      return 1;
    else
      return 0;
  }
}

// File: contracts/utils/ParseLib.sol

library ParseLib {

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, &quot;&quot;);
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, &quot;&quot;, &quot;&quot;);
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, &quot;&quot;, &quot;&quot;, &quot;&quot;);
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts/distributor/PxlDistributor.sol

contract PxlDistributor is Ownable, ContractReceiver, ValidValue {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct DistributionDetail {
        address transferAddress;
        uint256 tokenAmount;
        bool isCustomToken;
    }

    ERC20 token;
    Council council;
    DistributionDetail[] distribution;
    uint256 public purchaseParamCount = 11;

    constructor(address _councilAddr)
        public
        validAddress(_councilAddr)
    {
        council = Council(_councilAddr);
        token = ERC20(council.token());
    }

    function setPurchaseParamCount(uint256 _count)
        external
        onlyOwner
    {
        purchaseParamCount = _count;
    }

    function receiveApproval(address _to, uint256 _value, address _token, string  _jsonData)
        public
    {
        require(address(this) == _to);
        require(address(token) == _token);

        uint256 returnValue;
        JsmnSolLib.Token[] memory tokens;

        (returnValue, tokens) = getJsonToTokens(_jsonData, purchaseParamCount);

        if(returnValue > 0) {
            emit InvalidJsonParameter(msg.sender, _value);
            return;
        }

        // clear DistributionDetail array
        clearDistributionDetail();

        //address buyer = ParseLib.parseAddr(getTokenToValue(tokens, _jsonData, 2));
        //uint256 pxlAmount = uint256(ParseLib.parseInt(getTokenToValue(tokens, _jsonData, 4)));
        //address episodeAddr = ParseLib.parseAddr(getTokenToValue(tokens, _jsonData, 6));
        //address cdAddr = ParseLib.parseAddr(getTokenToValue(tokens, _jsonData, 8));
        //address marketerAddr = getMarketerAddress(ParseLib.stringToBytes32(getTokenToValue(tokens, _jsonData, 10)));

        require(getJsonToPxlAmount(tokens, _jsonData) == _value);
        require(getJsonToEpisodeAddr(tokens, _jsonData) != address(this) && getJsonToEpisodeAddr(tokens, _jsonData) != address(0));
        require(getJsonToCdAddr(tokens, _jsonData) != address(this) && getJsonToCdAddr(tokens, _jsonData) != address(0));
        require(getJsonToMarketerAddr(tokens, _jsonData) != address(this) && getJsonToMarketerAddr(tokens, _jsonData) != address(0));

        if(getJsonToPxlAmount(tokens, _jsonData) > 0) {
            require(token.balanceOf(getJsonToBuyer(tokens, _jsonData)) >= _value);
            transferDistributePxl(address(this), _value, false, _jsonData);


            uint256 tempVar;
            uint256 compareAmount = getJsonToPxlAmount(tokens, _jsonData);

            //cd amount
            tempVar = getRateToPxlAmount(compareAmount, council.cdRate());
            compareAmount = compareAmount.sub(tempVar);
            distribution.push(DistributionDetail(getJsonToCdAddr(tokens, _jsonData), tempVar, false));

            //user payback pool amount
            tempVar = getRateToPxlAmount(compareAmount, council.userPaybackRate());
            compareAmount = compareAmount.sub(tempVar);
            distribution.push(DistributionDetail(council.userPaybackPool(), tempVar, true));

            //deposit amount
            tempVar = getRateToPxlAmount(compareAmount, council.depositRate());
            compareAmount = compareAmount.sub(tempVar);
            distribution.push(DistributionDetail(council.depositPool(), tempVar, true));

            // marketer amount
            if(getJsonToMarketerAddr(tokens, _jsonData) != address(0)) {
                tempVar = getRateToPxlAmount(compareAmount, getContent(getJsonToEpisodeAddr(tokens, _jsonData)).getMarketerRate());
                compareAmount = compareAmount.sub(tempVar);
                distribution.push(DistributionDetail(getJsonToMarketerAddr(tokens, _jsonData), tempVar, false));
            }

            // supporter amount
            /* tempVar = getContent(getJsonToEpisodeAddr(tokens, _jsonData)).getFundDistributeLength();
            address[] memory supporterAddr = new address[](tempVar);
            uint256[] memory supporterPxlAmount = new uint256[](tempVar);

            (supporterAddr, supporterPxlAmount) = getContent(getJsonToEpisodeAddr(tokens, _jsonData)).getFundDistributeAmount(compareAmount);

            for(uint i = 0 ; i < supporterAddr.length ; i ++) {
                if(supporterPxlAmount[i] > 0) {
                    compareAmount = compareAmount.sub(supporterPxlAmount[i]);
                    distribution.push(DistributionDetail(supporterAddr[i], supporterPxlAmount[i], false));
                }
            } */

            // cp amount
            if(compareAmount > 0) {
                distribution.push(DistributionDetail(getContent(getJsonToEpisodeAddr(tokens, _jsonData)).getWriter(), compareAmount, false));
                compareAmount = 0;
            }

            // transfer
            for(uint256 j = 0 ; j < distribution.length ; j ++) {
                transferDistributePxl(distribution[j].transferAddress, distribution[j].tokenAmount, distribution[j].isCustomToken, _jsonData);
            }
        }

        // update episode purchase
        EpisodeInterface(getJsonToEpisodeAddr(tokens, _jsonData)).episodePurchase(getJsonToBuyer(tokens, _jsonData), getJsonToPxlAmount(tokens, _jsonData));
    }

    function getJsonToBuyer(JsmnSolLib.Token[] _tokens, string _jsonData)
        private
        pure
        returns (address)
    {
        return ParseLib.parseAddr(getTokenToValue(_tokens, _jsonData, 2));
    }

    function getJsonToPxlAmount(JsmnSolLib.Token[] _tokens, string _jsonData)
        private
        pure
        returns (uint256)
    {
        return uint256(ParseLib.parseInt(getTokenToValue(_tokens, _jsonData, 4)));
    }

    function getJsonToEpisodeAddr(JsmnSolLib.Token[] _tokens, string _jsonData)
        private
        pure
        returns (address)
    {
        return ParseLib.parseAddr(getTokenToValue(_tokens, _jsonData, 6));
    }

    function getJsonToCdAddr(JsmnSolLib.Token[] _tokens, string _jsonData)
        private
        pure
        returns (address)
    {
        return ParseLib.parseAddr(getTokenToValue(_tokens, _jsonData, 8));
    }

    function getJsonToMarketerAddr(JsmnSolLib.Token[] _tokens, string _jsonData)
        private
        view
        returns (address)
    {
        return getMarketerAddress(ParseLib.stringToBytes32(getTokenToValue(_tokens, _jsonData, 10)));
    }

    function clearDistributionDetail()
        private
    {
        delete distribution;
    }

    function getRateToPxlAmount(uint256 _amount, uint256 _rate)
        private
        pure
        returns (uint256)
    {
        return _amount.mul(_rate).div(100);
    }

    function getContent(address _episodeAddr)
        private
        view
        returns (ContentInterface iContent)
    {
        iContent = ContentInterface(EpisodeInterface(_episodeAddr).getContentAddress());
    }

    function getMarketerAddress(bytes32 _key)
        private
        view
        returns (address)
    {
        return Marketer(council.marketer()).getMarketerAddress(_key);
    }

    function getJsonToValue(string  _jsonData, uint256 _arrayLength, uint256 _valueIndex)
        private
        pure
        returns (string)
    {
        uint256 returnValue;
        JsmnSolLib.Token[] memory tokens;

        (returnValue, tokens) = getJsonToTokens(_jsonData, _arrayLength);

        return getTokenToValue(tokens, _jsonData, _valueIndex);
    }

    function getJsonToTokens(string _jsonData, uint256 _arrayLength)
        private
        pure
        returns (uint256, JsmnSolLib.Token[])
    {
        uint256 returnValue;
        uint256 actualNum;
        JsmnSolLib.Token[] memory tokens;

        (returnValue, tokens, actualNum) = JsmnSolLib.parse(_jsonData, _arrayLength);

        return (returnValue, tokens);
    }

    function getTokenToValue(JsmnSolLib.Token[] _tokens, string  _jsonData, uint256 _index)
        private
        pure
        returns (string)
    {
        JsmnSolLib.Token memory t = _tokens[_index];

        return JsmnSolLib.getBytes(_jsonData, t.start, t.end);
    }

    function transferDistributePxl(address _to, uint256 _amount, bool _isCustom, string _jsonData)
        private
    {
        if(_isCustom) {
            CustomToken(address(token)).approveAndCall(_to, _amount, _jsonData);
        } else {
            token.safeTransfer(_to, _amount);
        }

        emit TransferDistributePxl(_to, _amount);
    }

    event InvalidJsonParameter(address _sender, uint256 _pxl);
    event ChangeExternalAddress(address _sender, string _name);
    event ChangePurchaseParameterCount(address _sender, uint256 _count);
    event TransferDistributePxl(address indexed _to, uint256 _pxlAmount);
}