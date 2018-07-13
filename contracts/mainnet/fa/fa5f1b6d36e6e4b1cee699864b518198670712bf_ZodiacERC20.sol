pragma solidity ^0.4.24;


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */

contract Ownable {
    address public owner;

    constructor()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}


/**
 * @title BytesToTypes
 * @dev The BytesToTypes contract converts the memory byte arrays to the standard solidity types
 * @author pouladzade@gmail.com
 */

contract BytesToTypes {
    

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
    function bytesToBool(uint _offst, bytes memory _input) internal pure returns (bool _output) {
        
        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x==0 ? _output = false : _output = true;
    }   
        
    function getStringSize(uint _offst, bytes memory _input) internal pure returns(uint size){
        
        assembly{
            
            size := mload(add(_input,_offst))
            let chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {// if size%32 > 0
                chunk_count := add(chunk_count,1)
            } 
            
             size := mul(chunk_count,32)// first 32 bytes reseves for size in strings
        }
    }

    function bytesToString(uint _offst, bytes memory _input, bytes memory _output) internal  {

        uint size = 32;
        assembly {
            let loop_index:= 0
                  
            let chunk_count
            
            size := mload(add(_input,_offst))
            chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1
            
            if gt(mod(size,32),0) {
                chunk_count := add(chunk_count,1)  // chunk_count++
            }
                
            
            loop:
                mstore(add(_output,mul(loop_index,32)),mload(add(_input,_offst)))
                _offst := sub(_offst,32)           // _offst -= 32
                loop_index := add(loop_index,1)
                
            jumpi(loop , lt(loop_index , chunk_count))
            
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don&#39;t care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we&#39;re done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin&#39;s length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let&#39;s just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }


    function bytesToBytes32(uint _offst, bytes memory  _input) internal pure returns (bytes32 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    /*function bytesToBytes32(uint _offst, bytes memory  _input, bytes32 _output) internal pure {
        
        assembly {
            mstore(_output , add(_input, _offst))
            mstore(add(_output,32) , add(add(_input, _offst),32))
        }
    }*/
    
    function bytesToInt8(uint _offst, bytes memory  _input) internal pure returns (int8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
    
    function bytesToInt16(uint _offst, bytes memory _input) internal pure returns (int16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt24(uint _offst, bytes memory _input) internal pure returns (int24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt32(uint _offst, bytes memory _input) internal pure returns (int32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt40(uint _offst, bytes memory _input) internal pure returns (int40 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt48(uint _offst, bytes memory _input) internal pure returns (int48 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt56(uint _offst, bytes memory _input) internal pure returns (int56 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt64(uint _offst, bytes memory _input) internal pure returns (int64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt72(uint _offst, bytes memory _input) internal pure returns (int72 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt80(uint _offst, bytes memory _input) internal pure returns (int80 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt88(uint _offst, bytes memory _input) internal pure returns (int88 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt96(uint _offst, bytes memory _input) internal pure returns (int96 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
	
	function bytesToInt104(uint _offst, bytes memory _input) internal pure returns (int104 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
    
    function bytesToInt112(uint _offst, bytes memory _input) internal pure returns (int112 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt120(uint _offst, bytes memory _input) internal pure returns (int120 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt128(uint _offst, bytes memory _input) internal pure returns (int128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt136(uint _offst, bytes memory _input) internal pure returns (int136 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt144(uint _offst, bytes memory _input) internal pure returns (int144 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt152(uint _offst, bytes memory _input) internal pure returns (int152 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt160(uint _offst, bytes memory _input) internal pure returns (int160 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt168(uint _offst, bytes memory _input) internal pure returns (int168 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt176(uint _offst, bytes memory _input) internal pure returns (int176 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt184(uint _offst, bytes memory _input) internal pure returns (int184 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt192(uint _offst, bytes memory _input) internal pure returns (int192 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt200(uint _offst, bytes memory _input) internal pure returns (int200 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt208(uint _offst, bytes memory _input) internal pure returns (int208 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt216(uint _offst, bytes memory _input) internal pure returns (int216 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt224(uint _offst, bytes memory _input) internal pure returns (int224 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt232(uint _offst, bytes memory _input) internal pure returns (int232 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt240(uint _offst, bytes memory _input) internal pure returns (int240 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt248(uint _offst, bytes memory _input) internal pure returns (int248 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt256(uint _offst, bytes memory _input) internal pure returns (int256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint24(uint _offst, bytes memory _input) internal pure returns (uint24 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint32(uint _offst, bytes memory _input) internal pure returns (uint32 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint40(uint _offst, bytes memory _input) internal pure returns (uint40 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint48(uint _offst, bytes memory _input) internal pure returns (uint48 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint56(uint _offst, bytes memory _input) internal pure returns (uint56 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint72(uint _offst, bytes memory _input) internal pure returns (uint72 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint80(uint _offst, bytes memory _input) internal pure returns (uint80 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint88(uint _offst, bytes memory _input) internal pure returns (uint88 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

	function bytesToUint96(uint _offst, bytes memory _input) internal pure returns (uint96 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
	
	function bytesToUint104(uint _offst, bytes memory _input) internal pure returns (uint104 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint112(uint _offst, bytes memory _input) internal pure returns (uint112 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint120(uint _offst, bytes memory _input) internal pure returns (uint120 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint128(uint _offst, bytes memory _input) internal pure returns (uint128 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint136(uint _offst, bytes memory _input) internal pure returns (uint136 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint144(uint _offst, bytes memory _input) internal pure returns (uint144 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint152(uint _offst, bytes memory _input) internal pure returns (uint152 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint160(uint _offst, bytes memory _input) internal pure returns (uint160 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint168(uint _offst, bytes memory _input) internal pure returns (uint168 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint176(uint _offst, bytes memory _input) internal pure returns (uint176 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint184(uint _offst, bytes memory _input) internal pure returns (uint184 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint192(uint _offst, bytes memory _input) internal pure returns (uint192 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint200(uint _offst, bytes memory _input) internal pure returns (uint200 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint208(uint _offst, bytes memory _input) internal pure returns (uint208 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint216(uint _offst, bytes memory _input) internal pure returns (uint216 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint224(uint _offst, bytes memory _input) internal pure returns (uint224 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint232(uint _offst, bytes memory _input) internal pure returns (uint232 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint240(uint _offst, bytes memory _input) internal pure returns (uint240 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint248(uint _offst, bytes memory _input) internal pure returns (uint248 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        
        assembly {
            _output := mload(add(_input, _offst))
        }
    } 
    
}


interface ITradeable {
    
    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) external view returns (uint balance);
    
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) external returns (bool success);

    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) external returns (bool success);
    
    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}



contract ITrader {

  function getDataLength(
  ) public pure returns (uint256);

  function getProtocol(
  ) public pure returns (uint8);

  function getAvailableVolume(
    bytes orderData
  ) public view returns(uint);

  function isExpired(
    bytes orderData
  ) public view returns (bool); 

  function trade(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public;
  
  function getFillVolumes(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public view returns(uint, uint);

}

contract ITraders {

  /// @dev Add a valid trader address. Only owner.
  function addTrader(uint8 id, ITrader trader) public;

  /// @dev Remove a trader address. Only owner.
  function removeTrader(uint8 id) public;

  /// @dev Get trader by id.
  function getTrader(uint8 id) public view returns(ITrader);

  /// @dev Check if an address is a valid trader.
  function isValidTraderAddress(address addr) public view returns(bool);

}

contract Members is Ownable {

  mapping(address => bool) public members; // Mappings of addresses of allowed addresses

  modifier onlyMembers() {
    require(isValidMember(msg.sender));
    _;
  }

  /// @dev Check if an address is a valid member.
  function isValidMember(address _member) public view returns(bool) {
    return members[_member];
  }

  /// @dev Add a valid member address. Only owner.
  function addMember(address _member) public onlyOwner {
    members[_member] = true;
  }

  /// @dev Remove a member address. Only owner.
  function removeMember(address _member) public onlyOwner {
    delete members[_member];
  }
}


contract IFeeWallet {

  function getFee(
    uint amount) public view returns(uint);

  function collect(
    address _affiliate) public payable;
}


contract FeeWallet is IFeeWallet, Ownable, Members {

  address public serviceAccount; // Address of service account
  uint public servicePercentage; // Percentage times (1 ether)
  uint public affiliatePercentage; // Percentage times (1 ether)

  mapping (address => uint) public pendingWithdrawals; // Balances

  constructor(
    address _serviceAccount,
    uint _servicePercentage,
    uint _affiliatePercentage) public
  {
    serviceAccount = _serviceAccount;
    servicePercentage = _servicePercentage;
    affiliatePercentage = _affiliatePercentage;
  }

  /// @dev Set the new service account. Only owner.
  function changeServiceAccount(address _serviceAccount) public onlyOwner {
    serviceAccount = _serviceAccount;
  }

  /// @dev Set the service percentage. Only owner.
  function changeServicePercentage(uint _servicePercentage) public onlyOwner {
    servicePercentage = _servicePercentage;
  }

  /// @dev Set the affiliate percentage. Only owner.
  function changeAffiliatePercentage(uint _affiliatePercentage) public onlyOwner {
    affiliatePercentage = _affiliatePercentage;
  }

  /// @dev Calculates the service fee for a specific amount. Only owner.
  function getFee(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, servicePercentage) / (1 ether);
  }

  /// @dev Calculates the affiliate amount for a specific amount. Only owner.
  function getAffiliateAmount(uint amount) public view returns(uint)  {
    return SafeMath.safeMul(amount, affiliatePercentage) / (1 ether);
  }

  /// @dev Collects fees according to last payment receivedi. Only valid smart contracts.
  function collect(
    address _affiliate) public payable onlyMembers
  {
    if(_affiliate == address(0))
      pendingWithdrawals[serviceAccount] += msg.value;
    else {
      uint affiliateAmount = getAffiliateAmount(msg.value);
      pendingWithdrawals[_affiliate] += affiliateAmount;
      pendingWithdrawals[serviceAccount] += SafeMath.safeSub(msg.value, affiliateAmount);
    }
  }

  /// @dev Withdraw.
  function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}
contract ZodiacERC20 is Ownable, BytesToTypes {
  string constant public VERSION = &#39;2.0.0&#39;;

  ITraders public traders; // Smart contract that hold the list of valid traders
  IFeeWallet public feeWallet; // Smart contract that hold the fees collected
  bool public tradingEnabled; // Switch to enable or disable the contract

  event Sell(
    address account,
    address destinationAddr,
    address traedeable,
    uint volume,
    uint volumeEth,
    uint volumeEffective,
    uint volumeEthEffective
  );
  event Buy(
    address account,
    address destinationAddr,
    address traedeable,
    uint volume,
    uint volumeEth,
    uint volumeEffective,
    uint volumeEthEffective
  );


  constructor(ITraders _traders, IFeeWallet _feeWallet) public {
    traders = _traders;
    feeWallet = _feeWallet;
    tradingEnabled = true;
  }

  /// @dev Only accepts payment from smart contract traders.
  function() public payable {
  //  require(traders.isValidTraderAddress(msg.sender));
  }

  /// @dev Setter for feeWallet smart contract (Only owner)
  function changeFeeWallet(IFeeWallet _feeWallet) public onlyOwner {
    feeWallet = _feeWallet;
  }

  /// @dev Setter for traders smart contract (Only owner)
  function changeTraders(ITraders _traders) public onlyOwner {
    traders = _traders;
  }

  /// @dev Enable/Disable trading with smart contract (Only owner)
  function changeTradingEnabled(bool enabled) public onlyOwner {
    tradingEnabled = enabled;
  }

  /// @dev Buy a token.
  function buy(
    ITradeable tradeable,
    uint volume,
    bytes ordersData,
    address destinationAddr,
    address affiliate
  ) external payable
  {

    require(tradingEnabled);

    // Execute the trade (at most fullfilling volume)
    trade(
      false,
      tradeable,
      volume,
      ordersData,
      affiliate
    );

    // Since our balance before trade was 0. What we bought is our current balance.
    uint volumeEffective = tradeable.balanceOf(this);

    // We make sure that something was traded
    require(volumeEffective > 0);

    // Used ethers are: balance_before - balance_after.
    // And since before call balance=0; then balance_before = msg.value
    uint volumeEthEffective = SafeMath.safeSub(msg.value, address(this).balance);

    // IMPORTANT: Check that: effective_price <= agreed_price (guarantee a good deal for the buyer)
    require(
      SafeMath.safeDiv(volumeEthEffective, volumeEffective) <=
      SafeMath.safeDiv(msg.value, volume)
    );

    // Return remaining ethers
    if(address(this).balance > 0) {
      destinationAddr.transfer(address(this).balance);
    }

    // Send the tokens
    transferTradeable(tradeable, destinationAddr, volumeEffective);

    emit Buy(msg.sender, destinationAddr, tradeable, volume, msg.value, volumeEffective, volumeEthEffective);
  }

  /// @dev sell a token.
  function sell(
    ITradeable tradeable,
    uint volume,
    uint volumeEth,
    bytes ordersData,
    address destinationAddr,
    address affiliate
  ) external
  {
    require(tradingEnabled);

    // We transfer to ouselves the user&#39;s trading volume, to operate on it
    // note: Our balance is 0 before this
    require(tradeable.transferFrom(msg.sender, this, volume));

    // Execute the trade (at most fullfilling volume)
    trade(
      true,
      tradeable,
      volume,
      ordersData,
      affiliate
    );

    // Check how much we traded. Our balance = volume - tradedVolume
    // then: tradedVolume = volume - balance
    uint volumeEffective = SafeMath.safeSub(volume, tradeable.balanceOf(this));

    // We make sure that something was traded
    require(volumeEffective > 0);

    // Collects service fee
    uint volumeEthEffective = collectSellFee(affiliate);

    // IMPORTANT: Check that: effective_price >= agreed_price (guarantee a good deal for the seller)
    require(
      SafeMath.safeDiv(volumeEthEffective, volumeEffective) >=
      SafeMath.safeDiv(volumeEth, volume)
    );

    // Return remaining volume
    if (volumeEffective < volume) {
     transferTradeable(tradeable, destinationAddr, SafeMath.safeSub(volume, volumeEffective));
    }

    // Send ethers obtained
    destinationAddr.transfer(volumeEthEffective);

    emit Sell(msg.sender, destinationAddr, tradeable, volume, volumeEth, volumeEffective, volumeEthEffective);
  }


  /// @dev Trade buy or sell orders.
  function trade(
    bool isSell,
    ITradeable tradeable,
    uint volume,
    bytes ordersData,
    address affiliate
  ) internal
  {
    uint remainingVolume = volume;
    uint offset = ordersData.length;

    while(offset > 0 && remainingVolume > 0) {
      //Get the trader
      uint8 protocolId = bytesToUint8(offset, ordersData);
      ITrader trader = traders.getTrader(protocolId);
      require(trader != address(0));

      //Get the order data
      uint dataLength = trader.getDataLength();
      offset = SafeMath.safeSub(offset, dataLength);
      bytes memory orderData = slice(ordersData, offset, dataLength);

      //Fill order
      remainingVolume = fillOrder(
         isSell,
         tradeable,
         trader,
         remainingVolume,
         orderData,
         affiliate
      );
    }
  }

  /// @dev Fills a buy order.
  function fillOrder(
    bool isSell,
    ITradeable tradeable,
    ITrader trader,
    uint remaining,
    bytes memory orderData,
    address affiliate
    ) internal returns(uint)
  {

    //Checks that there is enoughh amount to execute the trade
    uint volume;
    uint volumeEth;
    (volume, volumeEth) = trader.getFillVolumes(
      isSell,
      orderData,
      remaining,
      address(this).balance
    );

    if(volume > 0) {

      if(isSell) {
        //Approve available amount of token to trader
        require(tradeable.approve(trader, volume));
      } else {
        //Collects service fee
        //TODO: transfer fees after all iteration
        volumeEth = collectBuyFee(volumeEth, affiliate);
        address(trader).transfer(volumeEth);
      }

      //Call trader to trade orders
      trader.trade(
        isSell,
        orderData,
        volume,
        volumeEth
      );

    }

    return SafeMath.safeSub(remaining, volume);
  }

  /// @dev Transfer tradeables to user account.
  function transferTradeable(ITradeable tradeable, address account, uint amount) internal {
    require(tradeable.transfer(account, amount));
  }

  // @dev Collect service/affiliate fee for a buy
  function collectBuyFee(uint ethers, address affiliate) internal returns(uint) {
    uint remaining;
    uint fee = feeWallet.getFee(ethers);
    //If there is enough remaining to pay fee, it substract from the balance
    if(SafeMath.safeSub(address(this).balance, ethers) >= fee)
      remaining = ethers;
    else
      remaining = SafeMath.safeSub(SafeMath.safeSub(ethers, address(this).balance), fee);
    feeWallet.collect.value(fee)(affiliate);
    return remaining;
  }

  // @dev Collect service/affiliate fee for a sell
  function collectSellFee(address affiliate) internal returns(uint) {
    uint fee = feeWallet.getFee(address(this).balance);
    feeWallet.collect.value(fee)(affiliate);
    return address(this).balance;
  }

}