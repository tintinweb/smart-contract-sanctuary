//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


//SourceUnit: globalinsurance.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./token.sol";

contract Global_Insurance_VSC {

    constructor(address tethertoken) public{
        token = TetherToken(tethertoken);
        deployTime = now;
        tokenAdd = tethertoken;
        sAd = msg.sender;
        releaseTime = deployTime;
        mAd = msg.sender;
    }
     
    using SafeMath for uint256;
    
    TetherToken token;
    address public sAd;
    address public tokenAdd;
    address public mAd;
    
    address public insurance1;
    address public insurance2;
    address public insurance3;
    address public insurance4;
    address public insurance5;
    address public insurance6;
    address public insurance7;
    address public insurance8;
    
    
    uint256 public insurance14Bal;              
    uint256 public insurance25Bal;       
    uint256 public insurance36Bal;         
    uint256 public insurance78Bal;

    uint256 public deployTime;
    uint256 public releaseTime;
   

    event PoolAddressAdded(
        string pool, 
        address seAdd);

    event Insurance1FundsUpdated(uint256 insurance14Bal);
    event Insurance2FundsUpdated(uint256 insurance25Bal);
    event Insurance3FundsUpdated(uint256 insurance36Bal);
    event Insurance4FundsUpdated(uint256 insurance14Bal);
    event Insurance5FundsUpdated(uint256 insurance25Bal);
    event Insurance6FundsUpdated(uint256 insurance36Bal);
    event Insurance7FundsUpdated(uint256 insurance78Bal);
    event Insurance8FundsUpdated(uint256 insurance78Bal);


    modifier onSAd() {
        require(msg.sender == sAd, "onSad");
        _;
    }
    
     modifier onMan() {
        require(msg.sender == mAd || msg.sender == sAd, "onMan");
        _;
    }
    
    function adMan(address _manAd) public onSAd {
        mAd = _manAd;
    
    }
    
    function remMan() public onSAd {
        mAd = sAd;
    }
    

    function jackAd(address address1,address address2,address address3,address address4,address address5,address address6,address address7,address address8) external onSAd  returns(bool){

          insurance1 = address1;
          emit PoolAddressAdded("jackpot1", insurance1);
    
          insurance2 = address2;
          emit PoolAddressAdded("jackpot2", insurance2);
        
          insurance3 = address3;
          emit PoolAddressAdded("jackpot3", insurance3);
        
          insurance4 = address4;
          emit PoolAddressAdded("jackpot4", insurance4);
        
          insurance5 = address5;
          emit PoolAddressAdded("jackpot5", insurance5);
        
          insurance6 = address6;
          emit PoolAddressAdded("jackpot6", insurance6);
        
          insurance7 = address7;
          emit PoolAddressAdded("jackpot7", insurance7);
          
          insurance8 = address8;
          emit PoolAddressAdded("jackpot8", insurance8);
    
        return true;
      }

    function witAd(uint256 amount1,uint256 amount2,uint256 amount3,uint256 amount4,uint256 amount5,uint256 amount6,uint256 amount7,uint256 amount8) external onMan returns(bool){
      
        token.transfer(insurance1, amount1);
        token.transfer(insurance2, amount2);
        token.transfer(insurance3, amount3);
        token.transfer(insurance4, amount4);
        token.transfer(insurance5, amount5);
        token.transfer(insurance6, amount6);
        token.transfer(insurance7, amount7);
        token.transfer(insurance8, amount8);
        
        insurance14Bal = insurance14Bal+amount1+amount4;
        insurance25Bal = insurance25Bal+amount2+amount5;
        insurance36Bal = insurance36Bal+amount3+amount6;
        insurance78Bal = insurance78Bal+amount7+amount8;
        
        emit Insurance1FundsUpdated(amount1);
        emit Insurance2FundsUpdated(amount2);
        emit Insurance3FundsUpdated(amount3);
        emit Insurance4FundsUpdated(amount4);
        emit Insurance5FundsUpdated(amount5);
        emit Insurance6FundsUpdated(amount6);
        emit Insurance7FundsUpdated(amount7);
        emit Insurance8FundsUpdated(amount8);
    
        releaseTime = now;
        return true;
        
    }


    
    function feeC() public view returns (uint256) {
        return address(this).balance;
    }
    
    function witE() public onMan{
        msg.sender.transfer(address(this).balance);
    }
    
    function tokC() public view returns (uint256){
        return token.balanceOf(address(this));
    }

  
}

//SourceUnit: token.sol

/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.5.10;
import "./SafeMath.sol";



contract Ownable {
    address public owner;


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    uint public basisPointsRate = 0;
    uint public maximumFee = 0;


    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }


    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}


contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;


    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint256 _allowance = allowed[_from][msg.sender];


        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }


    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }


    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;



  modifier whenNotPaused() {
    require(!paused);
    _;
  }


  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }


  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract UpgradedStandardToken is StandardToken{

    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}

contract TetherToken is Pausable, StandardToken, BlackList {

    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;


    constructor (uint _initialSupply, string memory _name, string memory _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function balanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function totalSupply() public view returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }


    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    event Issue(uint amount);

    event Redeem(uint amount);

    event Deprecate(address newAddress);

    event Params(uint feeBasisPoints, uint maxFee);
}