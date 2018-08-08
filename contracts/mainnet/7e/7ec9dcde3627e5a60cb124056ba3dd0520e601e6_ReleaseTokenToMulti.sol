pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


interface iContract {
    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address);
}

contract OwnerContract is Ownable {
    iContract public ownedContract;
    address origOwner;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function setContract(address _contract) public onlyOwner {
        require(_contract != address(0));
        ownedContract = iContract(_contract);
        origOwner = ownedContract.owner();
    }

    /**
     * @dev change the owner of the contract from this contract address to the original one. 
     *
     */
    function transferOwnershipBack() public onlyOwner {
        ownedContract.transferOwnership(origOwner);
        ownedContract = iContract(address(0));
        origOwner = address(0);
    }
}

interface iReleaseTokenContract {
    function releaseWithStage(address _target, address _dest) external returns (bool);
    function releaseAccount(address _target) external returns (bool);
    function transferAndFreeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) external returns (bool);
    function freeze(address _target, uint256 _value, uint256 _frozenEndTime, uint256 _releasePeriod) external returns (bool);
    function releaseOldBalanceOf(address _target) external returns (bool);
    function releaseByStage(address _target) external returns (bool);
}

contract ReleaseTokenToMulti is OwnerContract {
    using SafeMath for uint256;
    
    iReleaseTokenContract iReleaseContract;

    /**
     * @dev bind a contract as its owner
     *
     * @param _contract the contract address that will be binded by this Owner Contract
     */
    function setContract(address _contract) onlyOwner public {
        super.setContract(_contract);
        iReleaseContract = iReleaseTokenContract(_contract);
    }

    /**
     * @dev release the locked tokens owned by a number of accounts
     *
     * @param _targets the accounts list that hold an amount of locked tokens 
     */
    function releaseMultiAccounts(address[] _targets) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_targets.length != 0);

        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            res = iReleaseContract.releaseAccount(_targets[i]) || res;
            i = i.add(1);
        }

        return res;
    }

    /**
     * @dev release the locked tokens owned by an account
     *
     * @param _targets the account addresses list that hold amounts of locked tokens
     * @param _dests the secondary addresses list that will hold the released tokens for each target account
     */
    function releaseMultiWithStage(address[] _targets, address[] _dests) onlyOwner public returns (bool) {
        //require(_tokenAddr != address(0));
        require(_targets.length != 0);
        require(_dests.length != 0);
        assert(_targets.length == _dests.length);
        
        bool res = false;
        uint256 i = 0;
        while (i < _targets.length) {
            require(_targets[i] != address(0));
            require(_dests[i] != address(0));

            res = iReleaseContract.releaseWithStage(_targets[i], _dests[i]) || res; // as long as there is one true transaction, then the result will be true
            i = i.add(1);
        }

        return res;
    }

     /**
     * @dev freeze multiple of the accounts
     *
     * @param _targets the owners of some amount of tokens
     * @param _values the amounts of the tokens
     * @param _frozenEndTimes the list of the end time of the lock period, unit is second
     * @param _releasePeriods the list of the locking period, unit is second
     */
    function freezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = iReleaseContract.freeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res; 
        }

        return res;
    }

    /**
     * @dev transfer a list of amounts of tokens to a list of accounts, and then freeze the tokens
     *
     * @param _targets the account addresses that will hold a list of amounts of the tokens
     * @param _values the amounts of the tokens which have been transferred
     * @param _frozenEndTimes the end time list of the locked periods, unit is second
     * @param _releasePeriods the list of locking periods, unit is second
     */
    function transferAndFreezeMulti(address[] _targets, uint256[] _values, uint256[] _frozenEndTimes, uint256[] _releasePeriods) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        require(_values.length != 0);
        require(_frozenEndTimes.length != 0);
        require(_releasePeriods.length != 0);
        require(_targets.length == _values.length && _values.length == _frozenEndTimes.length && _frozenEndTimes.length == _releasePeriods.length);

        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = iReleaseContract.transferAndFreeze(_targets[i], _values[i], _frozenEndTimes[i], _releasePeriods[i]) && res; 
        }

        return res;
    }

    /**
     * @dev release the locked tokens owned by multi-accounts, which are the tokens
     * that belong to these accounts before being locked.
     * this need the releasing-to address has already been set.
     *
     * @param _targets the serial of account addresses that hold an amount of locked tokens
     */
    function releaseAllOldBalanceOf(address[] _targets) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        
        bool res = true;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = iReleaseContract.releaseOldBalanceOf(_targets[i]) && res;
        }

        return res;
    }

    /**
     * @dev release the locked tokens owned by an account with several stages
     * this need the contract get approval from the account by call approve() in the token contract
     * and also need the releasing-to address has already been set.
     *
     * @param _targets the account address that hold an amount of locked tokens
     */
    function releaseMultiByStage(address[] _targets) onlyOwner public returns (bool) {
        require(_targets.length != 0);
        
        bool res = false;
        for (uint256 i = 0; i < _targets.length; i = i.add(1)) {
            require(_targets[i] != address(0));
            res = iReleaseContract.releaseByStage(_targets[i]) || res;
        }

        return res;
    }
}