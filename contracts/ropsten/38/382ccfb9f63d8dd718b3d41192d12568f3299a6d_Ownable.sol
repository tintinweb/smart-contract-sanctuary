/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity ^0.4.21; 

// File: zepplin-solidity/contracts/ownership/Ownable.sol

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner,
    address indexed newOwner);
    
// @dev The Ownable constructor sets the original 'owner' of the contract to the sender
// account.

function Ownable() public {
    owner = msg.sender;
}

// if any other account besides owner

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

// to transfer ownership in case of event 

function transferOwnership(address newOwner) public onlyOwner 
{
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
}

}
// Safemath protocol

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns 
    (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c; 
    }
    function div(uint256 a, uint256 b) internal pure returns
    (uint256) {
        // assrt(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b; 
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns 
    (uint256) {
        assert(b <= a);
        return a - b; 
    }
    function add(uint256 a, uint256 b) internal pure returns
    (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// Smart contract title (ERC20)

contract ERC20 {
    uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);

  function transfer (address to, uint256 value) public returns (bool);
  
  function allowance(address owner, address spender) public view returns (uint256);
  
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  
  function approve(address spender, uint256 value) public returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}
contract HepburnA is ERC20, Ownable {
     using SafeMath for uint256; 
     
     // the controller of minting and destroying tokens
     address public hepburnDevmoon = 
     0x471E918a75A99038856eF9754368Eb1b5D15f9D5;
     
     // the controller of approving of minting and withdraw tokens 
     address public hepburnCommunitymoon = 
     0x0554c3CF2315FB98181d1FEBfaf083cDf68Fa145;
     
     struct TokensWithLock{
         uint256 value;
         uint256 blockNumber;
         
     }
     //Balances (shared with ERC20Basic replicant)
     mapping(address => uint256) balances;
     //When token numbers is less than incoming block
     mapping(address => TokensWithLock) lockTokens;
     
     mapping(address => mapping (address => uint256)) allowed; 
     // Token Cap
     uint256 public totalSupplyCap = 1e11;
     // Token Info
     string public name = "Hepburn A";
     string public symbol = "AUYHA";
     uint8 public decimals = 18;
     
     bool public mintingFinished = false;
     // the block number when deploy
     uint256 public deployBlockNumber = getCurrentBlockNumber();
     // the min threshold of lock time 
     uint256 public constant TIMETHRESHOLD = 9720;
     // the time when mintTokensWithinTime can be called 
     uint256 public constant MINTTIME = 291600;
     // the lock time of minted tokens 
     uint256 public durationOfLock = 9720;
     // True if transfers are allowed 
     bool public transferable = false; 
     // True if the transferable can be change 
     bool public canSetTransferable = true;
     
     modifier canMint() {
         require(!mintingFinished);
         _;
     }
     
     modifier only(address _address) {
         require(msg.sender == _address);
         _;
     }
     
     modifier nonZeroAddress(address _address) {
         require(_address != address(0));
         _;
     }
     
     modifier canTransfer() {
         require(transferable == true);
         _;
     }
     
     event SetDurationOfLock(address indexed _caller);
     event ApproveMintTokens(address indexed _owner, uint256 _amount);
     event WithdrawMintTokens(address indexed _owner, uint256 _amount);
     event MintTokens(address indexed _owner, uint256 _amount);
     event BurnTokens(address indexed _owner, uint256 _amount);
     event MintFinished(address indexed _caller);
     event SetTransferable(address indexed _address, bool _transferable);
     event SethepburnDevmoon(address indexed _old, address indexed _new);
     event SethepburnCommunitymoon(address indexed _old, address indexed _new);
     event DisableSetTransferable(address indexed _address, bool _canSetTransferable);
     
     function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) 
  {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint256 _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) canTransfer public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  /**
   * @dev Enables token holders to transfer their tokens freely if true
   * @param _transferable True if transfers are allowed
   */
  function setTransferable(bool _transferable) only(hepburnDevmoon) public {
    require(canSetTransferable == true);
    transferable = _transferable;
    emit SetTransferable(msg.sender, _transferable);
  }

  /**
   * @dev disable the canSetTransferable
   */
  function disableSetTransferable() only(hepburnDevmoon) public {
    transferable = true;
    canSetTransferable = false;
    emit DisableSetTransferable(msg.sender, false);
  }

  /**
   * @dev Set the hepburnDevmoon
   * @param _hepburnDevmoon The new hepburnDevmoon
   */
  function sethepburnDevmoon(address _hepburnDevmoon) only(hepburnDevmoon) nonZeroAddress(_hepburnDevmoon) public {
   hepburnDevmoon = _hepburnDevmoon;
    emit SethepburnDevmoon(msg.sender, _hepburnDevmoon);
  }
  /**
   * @dev Set the hepburnCommunitymoon
   * @param _hepburnCommunitymoon The new hepburnCommunitymoon
   */
  function sethepburnCommunitymoon(address _hepburnCommunitymoon) only(hepburnCommunitymoon) 
  nonZeroAddress(_hepburnCommunitymoon) public {
   hepburnCommunitymoon = _hepburnCommunitymoon;
     emit SethepburnCommunitymoon(msg.sender, _hepburnCommunitymoon);
  }
  /**
   * @dev Set the duration of lock of tokens approved of minting
   * @param _durationOfLock the new duration of lock
   */
  function setDurationOfLock(uint256 _durationOfLock) canMint only(hepburnCommunitymoon) public {
    require(_durationOfLock >= TIMETHRESHOLD);
    durationOfLock = _durationOfLock;
    emit SetDurationOfLock(msg.sender);
  }
  /**
   * @dev Get the quantity of locked tokens
   * @param _owner The address of locked tokens
   * @return the quantity and the lock time of locked tokens
   */
   function getLockTokens(address _owner) nonZeroAddress(_owner) view public returns (uint256 value, uint256 blockNumber) {
     return (lockTokens[_owner].value, lockTokens[_owner].blockNumber);
   }

  /**
   * @dev Approve of minting `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be assigned the new tokens
   * @param _amount The quantity of tokens approved of mintting
   * @return True if the tokens are approved of mintting correctly
   */
  function approveMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(hepburnCommunitymoon) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens + _amount >= previousLockTokens);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    lockTokens[_owner].value = previousLockTokens.add(_amount);
    uint256 curBlockNumber = getCurrentBlockNumber();
    lockTokens[_owner].blockNumber = curBlockNumber.add(durationOfLock);
    emit ApproveMintTokens(_owner, _amount);
    return true;
  }
  /**
   * @dev Withdraw approval of minting `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be withdrawn the tokens
   * @param _amount The quantity of tokens withdrawn approval of mintting
   * @return True if the tokens are withdrawn correctly
   */
  function withdrawMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(hepburnCommunitymoon) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens - _amount >= 0);
    lockTokens[_owner].value = previousLockTokens.sub(_amount);
    if (previousLockTokens - _amount == 0) {
      lockTokens[_owner].blockNumber = 0;
    }
    emit WithdrawMintTokens(_owner, _amount);
    return true;
  }
  /**
   * @dev Mints `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be assigned the new tokens
   * @return True if the tokens are minted correctly
   */
  function mintTokens(address _owner) canMint only(hepburnDevmoon) nonZeroAddress(_owner) public returns (bool) {
    require(lockTokens[_owner].blockNumber <= getCurrentBlockNumber());
    uint256 _amount = lockTokens[_owner].value;
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    lockTokens[_owner].value = 0;
    lockTokens[_owner].blockNumber = 0;
    emit MintTokens(_owner, _amount);
    emit Transfer(0, _owner, _amount);
    return true;
  }
  /**
   * @dev Mints `_amount` tokens that are assigned to `_owner` within one day after deployment
   * the tokens minted will be added to balance immediately
   * @param _owner The address that will be assigned the new tokens
   * @param _amount The quantity of tokens withdrawn minted
   * @return True if the tokens are minted correctly
   */
  function mintTokensWithinTime(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(hepburnDevmoon) public returns (bool) {
    require(_amount > 0);
    require(getCurrentBlockNumber() < (deployBlockNumber + MINTTIME));
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    emit MintTokens(_owner, _amount);
    emit Transfer(0, _owner, _amount);
    return true;
  }
  /**
   * @dev Transfer tokens to multiple addresses
   * @param _addresses The addresses that will receieve tokens
   * @param _amounts The quantity of tokens that will be transferred
   * @return True if the tokens are transferred correctly
   */
  function transferForMultiAddresses(address[] _addresses, uint256[] _amounts) canTransfer public returns (bool) {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_amounts[i] <= balances[msg.sender]);
      require(_amounts[i] > 0);

      // SafeMath.sub will throw if there is not enough balance.
      balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
      emit Transfer(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }

  /**
   * @dev Burns `_amount` tokens from `_owner`
   * @param _amount The quantity of tokens being burned
   * @return True if the tokens are burned correctly
   */
  function burnTokens(uint256 _amount) public returns (bool) {
    require(_amount > 0);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply >= _amount);
    uint256 previousBalanceTo = balanceOf(msg.sender);
    require(previousBalanceTo >= _amount);
    totalSupply = curTotalSupply.sub(_amount);
    balances[msg.sender] = previousBalanceTo.sub(_amount);
    emit BurnTokens(msg.sender, _amount);
    emit Transfer(msg.sender, 0, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() only(hepburnDevmoon) canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished(msg.sender);
    return true;
  }

  function getCurrentBlockNumber() private view returns (uint256) {
    return block.number;
  }
}