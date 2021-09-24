/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.7;
pragma experimental ABIEncoderV2;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// Part: smartcontractkit/[email protected]/SafeMathChainlink

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
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
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
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
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
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
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// File: FundMe.sol

// import "@ethereum-libraries-string-utils/solidity-stringutils/blob/master/src/strings.sol";


contract FundMe {
    
    // use only the SafeMathChainlink function for all uint256 type in this contract
    using SafeMathChainlink for uint256;
    // using strings for *;
    
    mapping(address => uint256) public addressToAmountFunded;
    address owner;
    
    address[] public addressArray;
    
    constructor() public  {
        owner = msg.sender;

    }

    // payable keyword is the "value" of the transaction
    function fund() public payable {
        
        // msg is the keyword containing information of the transaction
        // msg.sender : who send to you in the payable
        // msg.value : value included in the message
        
        // set a threshold USD 10
        uint256 minimumUSD = 10 * 10 ** 8 ; // 18 zeroes of wei for 1 eth
        
        (uint256 usdAmt, uint8 decimals) = convertWeiToUSD(msg.value);
        require(usdAmt >= minimumUSD, string(abi.encodePacked("Not enough eth, at least USD10.0, but you send : ", 
            addDecimal(uint2str(usdAmt),decimals))));
        
        addressToAmountFunded[msg.sender] += msg.value;
        for (uint i = 0 ; i < addressArray.length; i++){
            if (addressArray[i] == msg.sender)
                return;
        }
        
        addressArray.push(msg.sender);

        // now, set "value" to call the "fund" function
        // copy the address who clicked the fund function to check the amount paid
        
    }
    
    // function joinStrings(string memory s1, string memory s2) view  returns (string memory){
    //     return s1.toSlice().concat(s2.toSlice());
    // }
    
    function whoPaidMe() public view returns(address[] memory, uint){
        // for (uint i = 0; i < addressArray.length; i++ ){
            
        // }
        return (addressArray, addressArray.length);
        
    }
    
    struct WhoAmount{
        address who;
        uint256 amount;
    } 
    
    function whoPaidMeWithAmt() public view returns (WhoAmount[] memory) {
        WhoAmount[] memory res = new WhoAmount[] (addressArray.length);
        
        for (uint i = 0; i < addressArray.length; i++){
            res[i] = (WhoAmount(addressArray[i], addressToAmountFunded[addressArray[i]]));
        }
        return  res;
    }
    
    function getVersion() public view returns (uint256) {
        address usdAddr = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        
        // use ABI notation to call the contract by the address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usdAddr);
        
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256, uint8) {
        address usdAddr = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        
        // use ABI notation to call the contract by the address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usdAddr);
        
        (,int256 answer, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        
        return (uint256( answer ), decimals);
    }
    
    // 1 eth = 100000000 gwei, 1 gwei = 100000000 wei 
    function convertWeiToUSD(uint256 weiAmount) public view returns(uint256 , uint8) {
        (uint256 ethPrice, uint8 decimals) = getPrice();
        
        // console.log("ethPrice=", ethPrice);
        // console.log("decimals=", decimals);
        // console.log("weiAmount=", weiAmount);
        
        // be careful about overflow, number will wrap around for uint8 
        uint256 equivUSD = (ethPrice * weiAmount)/ (10 ** 8);
        // console.log("equivUSD=", equivUSD);
        
        return (equivUSD, decimals);
        
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    //  a bug here when equivUSD < 1, it will through error
    function addDecimal(string memory _unparsed, uint8  _decimals) internal pure returns (string memory) {
        uint256 numberLength = bytes(_unparsed).length;
        
        string memory intPart = getSlice(1, (numberLength - _decimals), _unparsed);
        string memory decPart = getSlice(numberLength - _decimals, numberLength, _unparsed);
        return string(abi.encodePacked(intPart, ".", decPart));
    }
    
    // begin from 1 
    function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }

    function getBal() public view returns(uint256) {
        return address(this).balance;
        
    }
    
    // modifier syntax, calls the modifier code before or after "_;" which is the modified function 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;        
    }
    function withdraw() payable onlyOwner public {
        // only for the contract/admin
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < addressArray.length; i++ ){
            addressToAmountFunded[addressArray[i]] = 0;
        }
        addressArray = new address[](0);
    }
}