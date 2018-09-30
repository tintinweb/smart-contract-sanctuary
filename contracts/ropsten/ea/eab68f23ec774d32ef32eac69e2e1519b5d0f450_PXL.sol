pragma solidity ^0.4.24;

// File: contracts/token/ContractReceiver.sol

contract ContractReceiver {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _data) public;
}

// File: contracts/token/CustomToken.sol

contract CustomToken {
    function approveAndCall(address _to, uint256 _value, bytes _data) public returns (bool);
    event ApproveAndCall(address indexed _from, address indexed _to, uint256 _value, bytes _data);
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value)
    external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances_;

  mapping (address => mapping (address => uint256)) private allowed_;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances_[_owner];
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
    return allowed_[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances_[msg.sender]);
    require(_to != address(0));

    balances_[msg.sender] = balances_[msg.sender].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
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
    allowed_[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

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
    require(_value <= balances_[_from]);
    require(_value <= allowed_[_from][msg.sender]);
    require(_to != address(0));

    balances_[_from] = balances_[_from].sub(_value);
    balances_[_to] = balances_[_to].add(_value);
    allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
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
    allowed_[msg.sender][_spender] = (
      allowed_[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
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
    uint256 oldValue = allowed_[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed_[msg.sender][_spender] = 0;
    } else {
      allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances_[_account] = balances_[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances_[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances_[_account] = balances_[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed_[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(
      _amount);
    _burn(_account, _amount);
  }
}

// File: contracts/token/PXL.sol

/**
 * @title PXL implementation based on StandardToken ERC-20 contract.
 *
 * @author Charls Kim - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3556461b5e5c5875575441415950505b411b565a58">[email&#160;protected]</a>>
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract PXL is ERC20, CustomToken, ExtendsOwnable {
    using SafeMath for uint256;

    // PXL 토큰 기본 정보
    string public constant name = "Pixel";
    string public constant symbol = "PXL";
    uint256 public constant decimals = 18;

    // PXL 토큰 글로벌 락 변수
    bool isTransferable = false;

    /**
     * @dev PXL 글로벌 락 해제
     *
     * @notice 거래소 상장 후 락 해제
     */
    function unlock() external onlyOwner {
        isTransferable = true;
    }

    /**
     * @dev PXL 글로벌 락 상태 조회
     *
     * @return bool 잠금 여부
     */
    function getTokenTransferable() external view returns (bool) {
        return isTransferable;
    }

    /**
     * @dev fallback 이더리움이 전송될 경우 Revert
     *
     */
    function() public payable {
        revert();
    }

    /**
     * @dev 토큰 대리 전송을 위한 함수
     *
     * @notice 토큰 전송이 불가능 할 경우 전송 실패
     * @param _from 토큰을 가지고 있는 지갑 주소
     * @param _to 토큰을 전송받을 지갑 주소
     * @param _value 대리 전송할 토큰 수량
     * @return bool 타입의 토큰 대리 전송 권한 성공 여부
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev PXL 토큰 전송 함수
     *
     * @notice 토큰 전송이 불가능 할 경우 전송 실패
     * @param _to 토큰을 받을 지갑 주소
     * @param _value 전송할 토큰 수량
     * @return bool 타입의 전송 결과
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        return super.transfer(_to, _value);
    }

    /**
     * @dev PXL 전송과 데이터를 함께 사용하는 함수
     *
     * @notice CustomToken 인터페이스 활용
     * @notice _to 주소가 컨트랙트인 경우만 사용 가능
     * @notice 토큰과 데이터를 받으려면 해당 컨트랙트에 receiveApproval 함수 구현 필요
     * @param _to 토큰을 전송하고 함수를 실행할 컨트랙트 주소
     * @param _value 전송할 토큰 수량
     * @return bool 타입의 처리 결과
     */
    function approveAndCall(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(isTransferable || owners[msg.sender]);
        require(_to != address(0) && _to != address(this));
        require(balanceOf(msg.sender) >= _value);

        if(approve(_to, _value) && isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.receiveApproval(msg.sender, _value, address(this), _data);
            emit ApproveAndCall(msg.sender, _to, _value, _data);

            return true;
        }
    }

    /**
     * @dev 토큰 발행 함수
     * @param _amount 발행할 토큰 수량
     */
     function mint(uint256 _amount) onlyOwner external {
        super._mint(msg.sender, _amount);

        emit Mint(msg.sender, _amount);
    }

    /**
     * @dev 토큰 소멸 함수
     * @param _amount 소멸할 토큰 수량
     */
    function burn(uint256 _amount) onlyOwner external {
        super._burn(msg.sender, _amount);

        emit Burn(msg.sender, _amount);
    }

    /**
     * @dev 컨트랙트 확인 함수
     * @param _addr 컨트랙트 주소
     */
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