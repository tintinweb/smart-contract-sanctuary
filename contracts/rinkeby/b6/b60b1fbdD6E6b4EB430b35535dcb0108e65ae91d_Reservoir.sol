/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

/**
 * @title Reservoir Contract
 * @notice Distributes a token to different contracts at a defined rate.
 * @dev This contract must be poked via the `drip()` function every so often.
 * @author Planet Finance
 */

contract Context {
    function _msgSender() internal view  returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view  returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view  returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint);


    function balanceOf(address owner) external view returns (uint balance);


    function transfer(address dst, uint amount) external returns (bool success);


    function transferFrom(address src, address dst, uint amount) external returns (bool success);

    function approve(address spender, uint amount) external returns (bool success);

    function allowance(address owner, address spender) external view returns (uint remaining);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Reservoir is Ownable {
    
  using SafeMath for uint;
  
    /*
   * Distribution Logic:
   * we set only gammaDrippedPerBlock value
   *
   * 1. gammaTrollerDripRate% of 86.5% of this gammaDrippedPerBlock goes to gammatroller and
   *    farmDripRate% of 86.5% of this gammaDrippedPerBlock goes to farm
   * 2. foundationDripRate% of 86.5% of this gammaDrippedPerBlock goes to foundation
   * 3. treasuryDripRate% of 86.5% of this gammaDrippedPerBlock goes to treasury
   */

  /// @notice The block number when the Reservoir started (immutable)
  uint public dripStart;
  
  /// @notice number of GAMMA tokens that will drip per block
  uint public gammaDrippedPerBlock;


  /// @notice Reference to token to drip (immutable) i.e GAMMA
  EIP20Interface public token;

  /// @notice Target Addresses to drip GAMMA
  address public gammaTroller = 0x068cc7e399CFc538aB9404EEC0c65A48751F5e9c;     
  address public foundation = 0x7D2AA9D113e9c444967d79d7FB8DB39DFA5DB462;     
  address public treasury = 0x3b50F137FAF22919941068952C5DC3d24ba98e29;       
  address public farmAddress = 0xD8CC50B168a3f7f18A300BDBCd29Ee41d37aA21c; 
  
  
  /// @notice Percentage drip to targets
  uint public gammaTrollerPercentage; //changable
  uint public foundationPercentage;
  uint public treasuryPercentage; //changable 
  uint public farmPercentage; //changable
  
  uint public maxPercentage; //10000
  uint public percentageWithoutTreasuryAndFoundation;
  uint public percentageWithoutTreasuryAndFoundationMax = 9000; //at one time we will change treasury distribution to 0% foundation percentage remains same
  
  uint public constant maxGammaDrippedPerDay = 100000; // amount of gamma transferred from reservoir can never exceed 100,000 GAMMA
  
  
  /// @notice Tokens per block that to drip to targets
  uint public gammaTrollerDripRate;
  uint public foundationDripRate;
  uint public treasuryDripRate;
  uint public farmDripRate; 
   
  
  /// @notice Amount that has already been dripped
  uint public gammaTrollerDripped;
  uint public foundationDripped;
  uint public treasuryDripped;
  uint public farmDripped;
  
  
  event GammaTrollerPercentageChange(uint oldPercentage,uint newPercentage);
  event FarmPercentageChange(uint oldPercentage,uint newPercentage);
  
  event NewFoundation(address oldFoundation,address newFoundation);
  event NewTreasury(address oldTreasury,address newTreasury);

  event Dripped(uint totalAmount, uint timestamp);
  event FarmDripped(uint amount, uint timestamp);
  
  event GammaTrollerDripRateChange(uint oldDripRate,uint newDripRate);
  event FarmDripRateChange(uint oldDripRate,uint newDripRate);
  event FoundationDripRateChange(uint oldDripRate,uint newDripRate);
  event TreasuryDripRateChange(uint oldDripRate,uint newDripRate);

  modifier onlyFarm() {
      require(msg.sender == farmAddress, "sender is not farm");
      _;
  }
  
  constructor(EIP20Interface token_) public {
    
    dripStart = block.number;
    token = token_;
    
    //initial number of dripped to these addresses
    gammaTrollerDripped = 0;
    foundationDripped = 0;
    treasuryDripped = 0;
    farmDripped = 0;
    
    //initial distribution percentages
    gammaTrollerPercentage = 4500;
    foundationPercentage = 1000;
    treasuryPercentage = 350;
    farmPercentage = 4150;
    maxPercentage = 10000;
    percentageWithoutTreasuryAndFoundation = 8650;
    
    gammaDrippedPerBlock = 3472222222222222000;
    
    _updateGammaDrippedPerBlockInternal();
  }

  /**
    * @notice Drips the maximum amount of tokens to match the drip rate since inception
    * @dev Note: this will only drip up to the amount of tokens available.
    * @return The amount of tokens dripped in this call
    */
  function drip() public returns (uint) {
    // First, read storage into memory
    EIP20Interface token_ = token;

    uint blockNumber_ = block.number;

    // drip Calculations
    uint dripFoundation   = mul(foundationDripRate, blockNumber_ - dripStart, "foundation dripTotal overflow");
    uint dripTreasury     = mul(treasuryDripRate, blockNumber_ - dripStart, "treasury dripTotal overflow");
    uint dripGammaTroller = mul(gammaTrollerDripRate, blockNumber_ - dripStart, "gammatroller dripTotal overflow");

    uint deltaDripFoundation_   = sub(dripFoundation, foundationDripped, "foundation delta drip overflow");
    uint deltaDripTreasury_     = sub(dripTreasury, treasuryDripped, "treasury delta drip overflow");
    uint deltaDripGammaTroller_ = sub(dripGammaTroller, gammaTrollerDripped, "gammaTroller delta drip overflow");


    uint totalDrip = dripGammaTroller+ dripFoundation + dripTreasury;

    require(token_.balanceOf(address(this)) > totalDrip, "Insufficient balance");

    uint drippedNextFoundation   = add(foundationDripped, deltaDripFoundation_, "");
    uint drippedNextTreasury     = add(treasuryDripped, deltaDripTreasury_, "");
    uint drippedNextGammaTroller = add(gammaTrollerDripped, deltaDripGammaTroller_, "");

    foundationDripped   = drippedNextFoundation;
    treasuryDripped     = drippedNextTreasury;
    gammaTrollerDripped = drippedNextGammaTroller;

    token_.transfer(gammaTroller, deltaDripGammaTroller_);
    token_.transfer(foundation, deltaDripFoundation_);
    token_.transfer(treasury, deltaDripTreasury_);

    emit Dripped(totalDrip, block.timestamp);

    return totalDrip;
  }


  function dripOnFarm(uint _amount) external onlyFarm {

    farmDripped += _amount;

    token.transfer(farmAddress, _amount);

    emit FarmDripped(farmDripped, block.timestamp);

  }
  
  function changeFoundationAddress(address _newFoundation) external onlyOwner {
      
      address oldFoundation = foundation;

      foundation = _newFoundation;

      emit NewFoundation(oldFoundation,_newFoundation);

  }
  
  function changeTreasuryAddress(address _newTreasury) external onlyOwner {

      address oldTreasury = treasury;
      
      treasury = _newTreasury;
      
      emit NewTreasury(oldTreasury,_newTreasury);
  }
  
  function setPercentageWithoutTreasuryAndFoundation(uint _newPercentage,uint _newFarmPercentage) external onlyOwner {
      
      require(_newPercentage <= percentageWithoutTreasuryAndFoundationMax,"new percentage cannot exceed the max limit");
      
      percentageWithoutTreasuryAndFoundation = _newPercentage;
      
      treasuryPercentage = maxPercentage.sub(_newPercentage.add(foundationPercentage));
      
      require(_newFarmPercentage <= percentageWithoutTreasuryAndFoundation,"new percentage is above the max limit");
      
      uint oldGammaTrollerPercentage = gammaTrollerPercentage;
      uint oldFarmPercentage = farmPercentage;
      
      uint newGammaTrollerPercentage = percentageWithoutTreasuryAndFoundation.sub(_newFarmPercentage);
      uint newFarmPercentage = _newFarmPercentage;
      
      gammaTrollerPercentage = newGammaTrollerPercentage;
      farmPercentage = newFarmPercentage;
      
      emit GammaTrollerPercentageChange(oldGammaTrollerPercentage,newGammaTrollerPercentage);
      emit FarmPercentageChange(oldFarmPercentage,_newFarmPercentage);
      
      _updateGammaDrippedPerBlockInternal();
  
  }

  function setGammaDrippedPerDay(uint _tokensToDripPerDay) external onlyOwner {
      
      require(_tokensToDripPerDay <= maxGammaDrippedPerDay,"tokens to drip per day cannot exceed the max limit");
      
      uint _tokensToDripPerBlockInADay = _tokensToDripPerDay.mul(1e18).div(28800);
      
      gammaDrippedPerBlock = _tokensToDripPerBlockInADay;
      
      _updateGammaDrippedPerBlockInternal();
  
  }
  
  function _updateGammaDrippedPerBlockInternal() internal {
      
      uint oldGammaTrollerDripRate = gammaTrollerDripRate; 
      uint oldFoundationDripRate = foundationDripRate;   
      uint oldTreasuryDripRate = treasuryDripRate;     
      uint oldFarmDripRate = farmDripRate;
      
      gammaTrollerDripRate = gammaTrollerPercentage.mul(gammaDrippedPerBlock).div(maxPercentage);
      foundationDripRate   = foundationPercentage.mul(gammaDrippedPerBlock).div(maxPercentage);
      treasuryDripRate     = treasuryPercentage.mul(gammaDrippedPerBlock).div(maxPercentage);
      farmDripRate         = farmPercentage.mul(gammaDrippedPerBlock).div(maxPercentage); 
      
      emit GammaTrollerDripRateChange(oldGammaTrollerDripRate,gammaTrollerDripRate);
      emit FoundationDripRateChange(oldFoundationDripRate,foundationDripRate);
      emit TreasuryDripRateChange(oldTreasuryDripRate,treasuryDripRate);
      emit FarmDripRateChange(oldFarmDripRate,farmDripRate);
      
  }
  
  function setGammaTrollerDripPercentage(uint _newGammaTrollerPercentage) external onlyOwner {
      
      require(_newGammaTrollerPercentage <= percentageWithoutTreasuryAndFoundation,"new percentage is above the max limit");
      
      uint oldGammaTrollerPercentage = gammaTrollerPercentage;
      uint oldFarmPercentage = farmPercentage;
      
      uint newGammaTrollerPercentage = _newGammaTrollerPercentage;
      uint newFarmPercentage = percentageWithoutTreasuryAndFoundation.sub(_newGammaTrollerPercentage);
      
      gammaTrollerPercentage = newGammaTrollerPercentage;
      farmPercentage = newFarmPercentage;
      
      _updateGammaDrippedPerBlockInternal();
      
      emit GammaTrollerPercentageChange(oldGammaTrollerPercentage,_newGammaTrollerPercentage);
      emit FarmPercentageChange(oldFarmPercentage,newFarmPercentage);
  
  }
  
  function setFarmDripPercentage(uint _newFarmPercentage) external onlyOwner {
      
      require(_newFarmPercentage <= percentageWithoutTreasuryAndFoundation,"new percentage is above the max limit");
      
      uint oldGammaTrollerPercentage = gammaTrollerPercentage;
      uint oldFarmPercentage = farmPercentage;
      
      uint newGammaTrollerPercentage = percentageWithoutTreasuryAndFoundation.sub(_newFarmPercentage);
      uint newFarmPercentage = _newFarmPercentage;
      
      gammaTrollerPercentage = newGammaTrollerPercentage;
      farmPercentage = newFarmPercentage;
      
      _updateGammaDrippedPerBlockInternal();
      
      emit GammaTrollerPercentageChange(oldGammaTrollerPercentage,newGammaTrollerPercentage);
      emit FarmPercentageChange(oldFarmPercentage,_newFarmPercentage);
  
  }

  /* Internal helper functions for safe math */

  function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    require(b <= a, errorMessage);
    uint c = a - b;
    return c;
  }

  function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    require(c / a == b, errorMessage);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }
}