pragma solidity ^0.4.24;


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

contract TokenDistributor is Ownable {
    using SafeMath for uint;

    address public targetToken;
    address[] public stakeHolders;
    uint256 public maxStakeHolders;
    event InsufficientTokenBalance( address indexed _token, uint256 _time );
    event TokensDistributed( address indexed _token, uint256 _total, uint256 _time );

    constructor ( address _targetToken, uint256 _totalStakeHolders, address[] _stakeHolders) public Ownable() {
        setTargetToken(_targetToken);
        maxStakeHolders = _totalStakeHolders;
        if (_stakeHolders.length > 0) {
            for (uint256 count = 0; count < _stakeHolders.length && count < _totalStakeHolders; count++) {
                if (_stakeHolders[count] != 0x0) {
                    _setStakeHolder(_stakeHolders[count]);
                }
            }
        }
    }

    function isDistributionDue (address _token) public view returns (bool) {
        return getTokenBalance(_token) > 1;
    }

    function isDistributionDue () public view returns (bool) {
        return getTokenBalance(targetToken) > 1;
    }

    function countStakeHolders () public view returns (uint256) {
        return stakeHolders.length;
    }

    function getTokenBalance(address _token) public view returns (uint256) {
        ERC20Basic token = ERC20Basic(_token);
        return token.balanceOf(address(this));
    }

    function getPortion (uint256 _total) public view returns (uint256) {
        return _total.div(stakeHolders.length);
    }

    function setTargetToken (address _targetToken) public onlyOwner returns (bool) {
        if(_targetToken != 0x0 && targetToken == 0x0) {
          targetToken = _targetToken;
          return true;
        }
    }

    function _setStakeHolder (address _stakeHolder) internal onlyOwner returns (bool) {
        require(countStakeHolders() < maxStakeHolders, "Max StakeHolders set");
        stakeHolders.push(_stakeHolder);
        return true;
    }

    function _transfer (address _token, address _recipient, uint256 _value) internal {
        ERC20Basic token = ERC20Basic(_token);
        token.transfer(_recipient, _value);
    }

    function distribute (address _token) public returns (bool) {
        uint256 balance = getTokenBalance(_token);
        uint256 perStakeHolder = getPortion(balance);

        if (balance < 1) {
            emit InsufficientTokenBalance(_token, block.timestamp);
            return false;
        } else {
            for (uint256 count = 0; count < stakeHolders.length; count++) {
                _transfer(_token, stakeHolders[count], perStakeHolder);
            }

            uint256 newBalance = getTokenBalance(_token);
            if (newBalance > 0 && getPortion(newBalance) == 0) {
                _transfer(_token, owner, newBalance);
            }

            emit TokensDistributed(_token, balance, block.timestamp);
            return true;
        }
    }

    function () public {
        distribute(targetToken);
    }
}

contract WeightedTokenDistributor is TokenDistributor {
    using SafeMath for uint;

    mapping( address => uint256) public stakeHoldersWeight;

    constructor ( address _targetToken, uint256 _totalStakeHolders, address[] _stakeHolders, uint256[] _weights) public
    TokenDistributor(_targetToken, _totalStakeHolders, stakeHolders)
    {
        if (_stakeHolders.length > 0) {
            for (uint256 count = 0; count < _stakeHolders.length && count < _totalStakeHolders; count++) {
                if (_stakeHolders[count] != 0x0) {
                  _setStakeHolder( _stakeHolders[count], _weights[count] );
                }
            }
        }
    }

    function getTotalWeight () public view returns (uint256 _total) {
        for (uint256 count = 0; count < stakeHolders.length; count++) {
            _total = _total.add(stakeHoldersWeight[stakeHolders[count]]);
        }
    }

    function getPortion (uint256 _total, uint256 _totalWeight, address _stakeHolder) public view returns (uint256) {
        uint256 weight = stakeHoldersWeight[_stakeHolder];
        return (_total.mul(weight)).div(_totalWeight);
    }

    function getPortion (uint256 _total) public view returns (uint256) {
        revert("Kindly indicate stakeHolder and totalWeight");
    }

    function _setStakeHolder (address _stakeHolder, uint256 _weight) internal onlyOwner returns (bool) {
        stakeHoldersWeight[_stakeHolder] = _weight;
        require(super._setStakeHolder(_stakeHolder));
        return true;
    }

    function _setStakeHolder (address _stakeHolder) internal onlyOwner returns (bool) {
        revert("Kindly set Weights for stakeHolder");
    }

    function distribute (address _token) public returns (bool) {
        uint256 balance = getTokenBalance(_token);
        uint256 totalWeight = getTotalWeight();

        if (balance < 1) {
            emit InsufficientTokenBalance(_token, block.timestamp);
            return false;
        } else {
            for (uint256 count = 0; count < stakeHolders.length; count++) {
                uint256 perStakeHolder = getPortion(balance, totalWeight, stakeHolders[count]);
                _transfer(_token, stakeHolders[count], perStakeHolder);
            }

            uint256 newBalance = getTokenBalance(_token);
            if (newBalance > 0) {
                _transfer(_token, owner, newBalance);
            }

            emit TokensDistributed(_token, balance, block.timestamp);
            return true;
        }
    }
}