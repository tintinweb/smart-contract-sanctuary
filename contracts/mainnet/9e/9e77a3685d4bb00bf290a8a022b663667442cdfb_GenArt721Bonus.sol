/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

// Sources flattened with buidler v1.4.7 https://buidler.dev

// File contracts/libs/SafeMath.sol

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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


// File contracts/GenArt721Bonus.sol

pragma solidity ^0.5.0;






interface ERC20 {
  function balanceOf(address _owner) external view returns (uint balance);
  function transfer(address _to, uint _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint remaining);
}

contract GenArt721Bonus {
  using SafeMath for uint256;

  ERC20 erc20Contract;

  mapping(address => bool) public isWhitelisted;
  bool public bonusIsActive;
  address public owner;
  uint256 public bonusValueInWei;
  bool public contractOwnsTokens;

  constructor(address _erc20, address _minter, uint256 _bonusValueInWei) public {
    owner=msg.sender;
    erc20Contract=ERC20(_erc20);
    isWhitelisted[_minter]=true;
    bonusIsActive = true;
    bonusValueInWei=_bonusValueInWei;
  }

  function triggerBonus(address _to) external returns (bool){
    require(isWhitelisted[msg.sender]==true, "only whitelisted contracts can trigger bonus");
    if (contractOwnsTokens){
      require(erc20Contract.balanceOf(address(this))>=bonusValueInWei, "this contract does not have sufficient balance for reward");
      erc20Contract.transfer(_to, bonusValueInWei);
    } else {
      require(erc20Contract.allowance(owner, address(this))>=bonusValueInWei, "this contract does not have sufficient allowance set for reward");
      erc20Contract.transferFrom(owner, _to, bonusValueInWei);
    }
    return true;
  }

  function checkOwnerAllowance() public view returns (uint256){
    uint256 remaining = erc20Contract.allowance(owner, address(this));
    return remaining;
  }

  function checkContractTokenBalance() public view returns (uint256){
    return erc20Contract.balanceOf(address(this));
  }

  function toggleBonusIsActive() public {
    require(msg.sender==owner, "can only be set by owner");
    bonusIsActive=!bonusIsActive;
  }

  function toggleContractOwnsTokens() public {
    require(msg.sender==owner, "can only be set by owner");
    contractOwnsTokens=!contractOwnsTokens;
  }

  function addWhitelisted(address _whitelisted) public {
    require(msg.sender==owner, "only owner can add whitelisted contract");
    isWhitelisted[_whitelisted]=true;
  }

  function removeWhitelisted(address _whitelisted) public {
    require(msg.sender==owner, "only owner can remove whitelisted contract");
    isWhitelisted[_whitelisted]=false;
  }

  function changeBonusValueInWei(uint _bonusValueInWei) public {
    require(msg.sender==owner, "only owner can modify bonus reward");
    bonusValueInWei=_bonusValueInWei;
  }

  function returnTokensToOwner() public {
    require(msg.sender==owner, "only owner can modify bonus reward");
    erc20Contract.transfer(owner, erc20Contract.balanceOf(address(this)));
  }
}