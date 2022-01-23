/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

/*
         M                                                 M
       M   M                                             M   M
      M  M  M                                           M  M  M
     M  M  M  M                                       M  M  M  M
    M  M  M  M  M                                    M  M  M  M  M
   M  M M  M  M  M                                 M  M  M  M  M  M
   M  M   M  M  M  M                              M  M     M  M  M  M
   M  M     M  M  M  M                           M  M      M  M   M  M
   M  M       M  M  M  M                        M  M       M  M   M  M       
   M  M         M  M  M  M                     M  M        M  M   M  M
   M  M           M  M  M  M                  M  M         M  M   M  M
   M  M             M  M  M  M               M  M          M  M   M  M   M  M  M  M  M  M  M
   M  M               M  M  M  M            M  M        M  M  M   M  M   M  M  M  M  M  M  M
   M  M                 M  M  M  M         M  M      M  M  M  M   M  M                  M  M
   M  M                   M  M  M  M      M  M    M  M  M  M  M   M  M                     M
   M  M                     M  M  M  M   M  M  M  M  M  M  M  M   M  M
   M  M                       M  M  M  M  M   M  M  M  M   M  M   M  M
   M  M                         M  M  M  M   M  M  M  M    M  M   M  M
   M  M                           M  M  M   M  M  M  M     M  M   M  M
   M  M                             M  M   M  M  M  M      M  M   M  M
M  M  M  M  M  M                         M   M  M  M  M   M  M  M  M  M  M  M  
                                          M  M  M  M
                                          M  M  M  M
                                          M  M  M  M
                                           M  M  M  M                        M  M  M  M  M  M
                                            M  M  M  M                          M  M  M  M
                                             M  M  M  M                         M  M  M  M
                                               M  M  M  M                       M  M  M  M
                                                 M  M  M  M                     M  M  M  M
                                                   M  M  M  M                   M  M  M  M
                                                      M  M  M  M                M  M  M  M
                                                         M  M  M  M             M  M  M  M
                                                             M  M  M  M   M  M  M  M  M  M
                                                                 M  M  M  M  M  M  M  M  M
                                                                                                                                                    
*/
 
// based off of the beautiful work done by Erick Calderon with the smart contracts for Artblocks.
 
pragma solidity ^0.5.0;
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
library SafeMath {
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
}
// File contracts/libs/Strings.sol
// File: contracts/Strings.sol
pragma solidity ^0.5.0;
//https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
library Strings {
  function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
      return strConcat(_a, _b, "", "", "");
  }
  function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
      return strConcat(_a, _b, _c, "", "");
  }
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
      return strConcat(_a, _b, _c, _d, "");
  }
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      uint i = 0;
      for (i = 0; i < _ba.length; i++) {
          babcde[k++] = _ba[i];
      }
      for (i = 0; i < _bb.length; i++) {
          babcde[k++] = _bb[i];
      }
      for (i = 0; i < _bc.length; i++) {
          babcde[k++] = _bc[i];
      }
      for (i = 0; i < _bd.length; i++) {
          babcde[k++] = _bd[i];
      }
      for (i = 0; i < _be.length; i++) {
          babcde[k++] = _be[i];
      }
      return string(babcde);
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
      uint k = len - 1;
      while (_i != 0) {
          bstr[k--] = byte(uint8(48 + _i % 10));
          _i /= 10;
      }
      return string(bstr);
  }
}
pragma solidity ^0.5.0;
interface GenArt721CoreContract {
function projectIdToCurrencySymbol(uint256 _projectId) external view returns (string memory);
function projectIdToCurrencyAddress(uint256 _projectId) external view returns (address);
function projectIdToArtistAddress(uint256 _projectId) external view returns (address payable);
function projectIdToPricePerTokenInWei(uint256 _projectId) external view returns (uint256);
function projectIdToAdditionalPayee(uint256 _projectId) external view returns (address payable);
function projectIdToAdditionalPayeePercentage(uint256 _projectId) external view returns (uint256);
function mirageAddress() external view returns (address payable);
function miragePercentage() external view returns (uint256);
function mint(address _to, uint256 _projectId, address _by) external returns (uint256 tokenId);
function earlyMint(address _to, uint256 _projectId, address _by) external returns (uint256 _tokenId);
function balanceOf(address owner) external view returns (uint256);
}
interface ERC20 {
function balanceOf(address _owner) external view returns (uint balance);
function transferFrom(address _from, address _to, uint _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint remaining);
}
interface mirageContracts {
function balanceOf(address owner, uint256 _id) external view returns (uint256);
}
contract mirageMinter {
using SafeMath for uint256;
GenArt721CoreContract public mirageContract;
mirageContracts public membershipContract;
constructor(address _mirageAddress, address _membershipAddress) public {
  mirageContract = GenArt721CoreContract(_mirageAddress);
  membershipContract = mirageContracts(_membershipAddress);
}
function getYourBalanceOfProjectERC20(uint256 _projectId) public view returns (uint256){
  uint256 balance = ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).balanceOf(msg.sender);
  return balance;
}
function checkYourAllowanceOfProjectERC20(uint256 _projectId) public view returns (uint256){
  uint256 remaining = ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).allowance(msg.sender, address(this));
  return remaining;
}
 
function purchase(uint256 _projectId, uint256 numberOfTokens) public payable {
    require(numberOfTokens <= 10, "Can only mint 10 per transaction");
  if (keccak256(abi.encodePacked(mirageContract.projectIdToCurrencySymbol(_projectId))) != keccak256(abi.encodePacked("ETH"))){
    require(msg.value==0, "this project accepts a different currency and cannot accept ETH, or this project does not exist");
    require(ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).allowance(msg.sender, address(this)) >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Insufficient Funds Approved for TX");
    require(ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).balanceOf(msg.sender) >= mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens), "Insufficient balance.");
    _splitFundsERC20(_projectId, numberOfTokens);
  } else {
    require(msg.value>=mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens), "Must send minimum value to mint!");
    _splitFundsETH(_projectId, numberOfTokens);
  }
  for(uint i = 0; i < numberOfTokens; i++) {
    mirageContract.mint(msg.sender, _projectId, msg.sender);  
  }
}

 function earlyPurchase(uint256 _projectId, uint256 _membershipId, uint256 numberOfTokens) public payable {
   require(membershipContract.balanceOf(msg.sender,_membershipId) > 0, "No membership tokens in this wallet");
   require(numberOfTokens <= 3, "Can only mint 3 per transaction for presale minting");
  if (keccak256(abi.encodePacked(mirageContract.projectIdToCurrencySymbol(_projectId))) != keccak256(abi.encodePacked("ETH"))){
    require(msg.value==0, "this project accepts a different currency and cannot accept ETH, or this project does not exist");
    require(ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).allowance(msg.sender, address(this)) >= mirageContract.projectIdToPricePerTokenInWei(_projectId), "Insufficient Funds Approved for TX");
    require(ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).balanceOf(msg.sender) >= mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens), "Insufficient balance.");
    _splitFundsERC20(_projectId, numberOfTokens);
  } else {
    require(msg.value>=mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens), "Must send minimum value to mint!");
  
    _splitFundsETH(_projectId, numberOfTokens);
  }
  for(uint i = 0; i < numberOfTokens; i++) {
    mirageContract.earlyMint(msg.sender, _projectId, msg.sender);
  }
}
function _splitFundsETH(uint256 _projectId, uint256 numberOfTokens) internal {
  if (msg.value > 0) {
    uint256 mintCost = mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens);
    uint256 refund = msg.value.sub(mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens));
    if (refund > 0) {
      msg.sender.transfer(refund);
    }
    uint256 foundationAmount = mintCost.div(100).mul(mirageContract.miragePercentage());
    if (foundationAmount > 0) {
      mirageContract.mirageAddress().transfer(foundationAmount);
    }
    uint256 projectFunds = mintCost.sub(foundationAmount);
    uint256 additionalPayeeAmount;
    if (mirageContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
      additionalPayeeAmount = projectFunds.div(100).mul(mirageContract.projectIdToAdditionalPayeePercentage(_projectId));
      if (additionalPayeeAmount > 0) {
        mirageContract.projectIdToAdditionalPayee(_projectId).transfer(additionalPayeeAmount);
      }
    }
    uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
    if (creatorFunds > 0) {
      mirageContract.projectIdToArtistAddress(_projectId).transfer(creatorFunds);
    }
  }
}
function _splitFundsERC20(uint256 _projectId, uint256 numberOfTokens) internal {
  uint256 mintCost = mirageContract.projectIdToPricePerTokenInWei(_projectId).mul(numberOfTokens);
  uint256 foundationAmount = mintCost.div(100).mul(mirageContract.miragePercentage());
  if (foundationAmount > 0) {
    ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, mirageContract.mirageAddress(), foundationAmount);
  }
  uint256 projectFunds = mintCost.sub(foundationAmount);
  uint256 additionalPayeeAmount;
  if (mirageContract.projectIdToAdditionalPayeePercentage(_projectId) > 0) {
    additionalPayeeAmount = projectFunds.div(100).mul(mirageContract.projectIdToAdditionalPayeePercentage(_projectId));
    if (additionalPayeeAmount > 0) {
      ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, mirageContract.projectIdToAdditionalPayee(_projectId), additionalPayeeAmount);
    }
  }
  uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
  if (creatorFunds > 0) {
    ERC20(mirageContract.projectIdToCurrencyAddress(_projectId)).transferFrom(msg.sender, mirageContract.projectIdToArtistAddress(_projectId), creatorFunds);
  }
}
}