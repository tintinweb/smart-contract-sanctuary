/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

// File: openzeppelin-eth/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
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
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

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

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function initialize(address sender) public initializer {
    _owner = sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
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

// File: openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.4.24;

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

// File: uFragments/contracts/lib/SafeMathInt.sol

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.4.24;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// File: uFragments/contracts/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    function sync() external;
    function skim(address to) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// File: uFragments/contracts/UFragments.sol

pragma solidity 0.4.24;

/**
 * @title uFragments ERC20 token
 * @dev This is part of an implementation of the uFragments Ideal Money protocol.
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining value proportionally across all wallets.
 */
contract UFragments is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 private constant TOKEN_PRECISION = 1e6;
    uint256 private constant DECIMALS = 6;
    uint256 private constant MIN_SUPPLY = 240 * TOKEN_PRECISION;
    uint256 private constant INITIAL_SUPPLY = 12000 * TOKEN_PRECISION;
    uint256 private constant MAX_SUPPLY = 24000 * TOKEN_PRECISION;
    
	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		uint256 appliedTokenCirculation;
		uint256 executeTransferTimeOut;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
        uint256 coinWorkingTime;
        address uniswapV2PairAddress;
        bool initialSetup;
        address[] contractUsers;
        uint256 periodVolumenToken;
        uint256 round;
        uint256 divider;
        uint256 drainSystem;
        uint256 rewardBonus;
	}

	Info public info;
	
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	event AdjustSupply(uint256 value);
	event AdjustUniswapSupply(uint256 value);
    
    function initialize(address owner_)
        public
        initializer
    {
        ERC20Detailed.initialize("VolTime", "VolTime", uint8(DECIMALS));
        Ownable.initialize(owner_);

	    info.coinWorkingTime = now;
	    info.uniswapV2PairAddress = address(0);
	    
		info.totalSupply = INITIAL_SUPPLY;
		
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		info.users[msg.sender].appliedTokenCirculation = INITIAL_SUPPLY;
		
		info.initialSetup = false;
		
		info.round = 24 hours;
		info.divider = 1 hours;
		info.drainSystem = 60 seconds;
		info.rewardBonus = 10;

        emit Transfer(address(0x0), owner_, INITIAL_SUPPLY);
    }

     /**
     * @return The total number of fragments.
     */
	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}
	
	 /**
     * @dev Function to check the amount of value that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of value still available for the spender.
     */
	function allowance(address owner_, address spender) public view returns (uint256) {
		return info.users[owner_].allowance[spender];
	}
	
	 /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
	function balanceOf(address who) public view returns (uint256)	{
	    
	    bool isNewUser = info.users[who].balance == 0;
	    if(isNewUser)
        {
           	return 0;
        }
	    
        uint256 adjustedAddressBalance = ((info.users[who].balance * info.totalSupply) / info.users[who].appliedTokenCirculation);
        
        return (adjustedAddressBalance);
	}
	
	 /**
     * @dev Approve the passed address to spend the specified amount of value on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of value to be spent.
     */
	function approve(address spender, uint256 value) external returns (bool) {
		info.users[msg.sender].allowance[spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}
	
	 /**
     * @dev Transfer value to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
	function transfer(address to, uint256 value) external returns (bool) {
		_transfer(msg.sender, to, value);
		return true;
	}

    /**
     * @dev Transfer value from one address to another.
     * @param from The address you want to send value from.
     * @param to The address you want to transfer to.
     * @param value The amount of value to be transferred.
     */
	function transferFrom(address from, address to, uint256 value) external returns (bool) {
		require(info.users[from].allowance[msg.sender] >= value);
		info.users[from].allowance[msg.sender] -= value;
		_transfer(from, to, value);
		return true;
	}
	
	function _transfer(address from, address to, uint256 value) internal returns (uint256) {

        require(balanceOf(from) >= value);

	 	uint256 _transferred = 0;
	 	
        bool isNewUser = info.users[to].balance == 0;
        		
        if(isNewUser)
        {
            info.users[to].appliedTokenCirculation = info.totalSupply;
            info.users[to].executeTransferTimeOut = now;
            info.contractUsers.push(to);
        }
        
        if(to == info.uniswapV2PairAddress){
            require(info.users[from].executeTransferTimeOut + info.drainSystem < now);
            info.users[from].executeTransferTimeOut = now;
        }
        
        if(from == info.uniswapV2PairAddress){
            info.users[to].executeTransferTimeOut = now;
        }
        
        //Sync wallets
        if(info.uniswapV2PairAddress != from && info.users[from].appliedTokenCirculation != info.totalSupply){
            _adjRebase(from);
        }
        if(info.uniswapV2PairAddress != to && info.users[to].appliedTokenCirculation != info.totalSupply){
            _adjRebase(to);
        }
        
        bool whenAbleToTransfer = info.users[from].appliedTokenCirculation == info.users[to].appliedTokenCirculation;
        
        // Able to transfer on the same level only
        if(whenAbleToTransfer){
     	    info.users[from].balance -= value;
    		_transferred = value;
            info.users[to].balance += _transferred;
            emit Transfer(from, to, _transferred);
        }
        
        
        if(info.uniswapV2PairAddress == from || info.uniswapV2PairAddress == to){
           info.periodVolumenToken += value;
        }
        
        if(info.uniswapV2PairAddress != address(0) && !isNewUser){
            if(info.coinWorkingTime + info.round < now) 
            {
                uint256 countOfCoins = (((now - info.coinWorkingTime) / info.divider) * TOKEN_PRECISION) * info.rewardBonus;
                info.coinWorkingTime = now;
                
                if(info.periodVolumenToken >= info.totalSupply){
                    if(info.totalSupply + countOfCoins >= MAX_SUPPLY){
                        info.totalSupply = MAX_SUPPLY;
                    }else{
                        info.totalSupply += countOfCoins;
                    }
                }else{
                    if(info.totalSupply <= countOfCoins + MIN_SUPPLY){
                        info.totalSupply = MIN_SUPPLY;
                    }else{
                        info.totalSupply -= countOfCoins;
                    }
                }
                
                info.periodVolumenToken = 0;
            
                emit AdjustSupply(info.totalSupply);
            }
        }
        
        if(info.uniswapV2PairAddress != address(0)){
     
            // Rebalance uniswap wallet even user to user
            if(info.users[info.uniswapV2PairAddress].appliedTokenCirculation != info.totalSupply){
                 _adjRebase(info.uniswapV2PairAddress);
           
            }
            // Sync uniswap even user to user
            if(info.uniswapV2PairAddress != from && info.uniswapV2PairAddress != to){
                IUniswapV2Pair(info.uniswapV2PairAddress).sync();
            }
		}
		
		return _transferred;
	}
	
    function initRebase (address _uniswapV2PairAddress) onlyOwner public {
        require(!info.initialSetup);
        info.initialSetup = true; 
        
        info.coinWorkingTime = now;
		info.uniswapV2PairAddress = _uniswapV2PairAddress;
    }
    
    function rebaseTimeInfo() public view returns (bool _isTimeToRebase, uint256 _timeNow, uint256 _workingTime, uint256 _roundTime) {
        bool isTimeToRebase = info.coinWorkingTime + info.round < now;
        return(isTimeToRebase, now, info.coinWorkingTime, info.round);
    }
    
    function volTime() public view returns (uint256 volumenOnToken, uint256 _coinsToAddOrRemove, uint256 _totalSupply, uint256 _futureTotalSupply) {
        
        uint256 countOfCoins = (((now - info.coinWorkingTime) / info.divider) * TOKEN_PRECISION) * info.rewardBonus;
        uint256 futureTotalSupply = info.totalSupply;
        
         if(info.periodVolumenToken >= info.totalSupply){
            if(info.totalSupply + countOfCoins >= MAX_SUPPLY){
                futureTotalSupply = MAX_SUPPLY;
            }else{
                futureTotalSupply += countOfCoins;
            }
         }else{
            if(info.totalSupply <= countOfCoins + MIN_SUPPLY){
                futureTotalSupply = MIN_SUPPLY;
            }else{
                futureTotalSupply -= countOfCoins;
            }
         }
         
         if(futureTotalSupply == info.totalSupply){
             _coinsToAddOrRemove = 0;
         }
    
        return(info.periodVolumenToken, countOfCoins, info.totalSupply, futureTotalSupply);
    }
    
    function _adjRebase(address person) private {
        uint256 addressBalanceFrom = info.users[person].balance;
        uint256 adjustedAddressBalanceFrom = (addressBalanceFrom * info.totalSupply) / info.users[person].appliedTokenCirculation;
        info.users[person].balance = adjustedAddressBalanceFrom;
        info.users[person].appliedTokenCirculation = info.totalSupply;
        emit Transfer(person, person, adjustedAddressBalanceFrom);
	}
	
	
	function resetSeason() onlyOwner public {
        for (uint id = 0; id < info.contractUsers.length; id++) {
             address userAddress = info.contractUsers[id];
             
             if(userAddress == info.uniswapV2PairAddress || userAddress == owner()){
                 emit Transfer(userAddress, userAddress, 0);
             }else{
                uint256 value = info.users[userAddress].balance;
              
                info.users[userAddress].balance -= value;
                info.users[owner()].balance += value;
                
                emit Transfer(userAddress, owner(), value);
             }
         }
         
         delete info.contractUsers;
    }
          
    
}