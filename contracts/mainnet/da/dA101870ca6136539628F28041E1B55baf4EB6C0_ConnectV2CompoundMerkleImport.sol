pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../../common/interfaces.sol";
import { CTokenInterface } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { Variables } from "./variables.sol";


contract CompoundResolver is Helpers, Events {
    function _borrow(CTokenInterface[] memory ctokenContracts, uint[] memory amts, uint _length) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                require(ctokenContracts[i].borrow(amts[i]) == 0, "borrow-failed-collateral?");
            }
        }
    }

    function _paybackOnBehalf(
        address userAddress,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                if (address(ctokenContracts[i]) == address(ceth)) {
                    ceth.repayBorrowBehalf{value: amts[i]}(userAddress);
                } else {
                    require(ctokenContracts[i].repayBorrowBehalf(userAddress, amts[i]) == 0, "repayOnBehalf-failed");
                }
            }
        }
    }

    function _transferCtokens(
        address userAccount,
        CTokenInterface[] memory ctokenContracts,
        uint[] memory amts,
        uint _length
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                // console.log("_transferCtokens", ctokenContracts[i].allowance(userAccount, address(this)), amts[i], ctokenContracts[i].balanceOf(userAccount));
                require(ctokenContracts[i].transferFrom(userAccount, address(this), amts[i]), "ctoken-transfer-failed-allowance?");
            }
        }
    }
}

contract CompoundHelpers is CompoundResolver, Variables {
    constructor(address _instaCompoundMerkle) Variables(_instaCompoundMerkle) {}
    struct ImportData {
        uint[] supplyAmts;
        uint[] borrowAmts;
        uint[] supplySplitAmts;
        uint[] borrowSplitAmts;
        uint[] supplyFinalAmts;
        uint[] borrowFinalAmts;
        address[] ctokens;
        CTokenInterface[] supplyCtokens;
        CTokenInterface[] borrowCtokens;
        address[] supplyCtokensAddr;
        address[] borrowCtokensAddr;
    }

    struct ImportInputData {
        uint256 index;
        address userAccount;
        string[] supplyIds;
        string[] borrowIds;
        uint256 times;
        bool isFlash;
        uint256 rewardAmount;
        uint256 networthAmount;
        bytes32[] merkleProof;
    }

    function getBorrowAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (importInputData.borrowIds.length > 0) {
            data.borrowAmts = new uint[](importInputData.borrowIds.length);
            data.borrowCtokens = new CTokenInterface[](importInputData.borrowIds.length);
            data.borrowSplitAmts = new uint[](importInputData.borrowIds.length);
            data.borrowFinalAmts = new uint[](importInputData.borrowIds.length);
            data.borrowCtokensAddr = new address[](importInputData.borrowIds.length);

            for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                bytes32 i_hash = keccak256(abi.encode(importInputData.borrowIds[i]));
                for (uint j = i; j < importInputData.borrowIds.length; j++) {
                    bytes32 j_hash = keccak256(abi.encode(importInputData.borrowIds[j]));
                    if (j != i) {
                        require(i_hash != j_hash, "token-repeated");
                    }
                }
            }

            if (importInputData.times > 0) {
                for (uint i = 0; i < importInputData.borrowIds.length; i++) {
                    (address _token, address _ctoken) = compMapping.getMapping(importInputData.borrowIds[i]);
                    require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

                    data.ctokens[i] = _ctoken;

                    data.borrowCtokens[i] = CTokenInterface(_ctoken);
                    data.borrowCtokensAddr[i] = (_ctoken);
                    data.borrowAmts[i] = data.borrowCtokens[i].borrowBalanceCurrent(importInputData.userAccount);

                    if (_token != ethAddr && data.borrowAmts[i] > 0) {
                        TokenInterface(_token).approve(_ctoken, data.borrowAmts[i]);
                    }

                    if (importInputData.times == 1) {
                        data.borrowFinalAmts = data.borrowAmts;
                    } else {
                        for (uint256 j = 0; j < data.borrowAmts.length; j++) {
                            data.borrowSplitAmts[j] = data.borrowAmts[j] / importInputData.times;
                            data.borrowFinalAmts[j] = sub(data.borrowAmts[j], mul(data.borrowSplitAmts[j], sub(importInputData.times, 1)));
                        }
                    }
                }
            }
        }
        return data;
    }
    
    function getSupplyAmounts (
        ImportInputData memory importInputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        data.supplyAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokens = new CTokenInterface[](importInputData.supplyIds.length);
        data.supplySplitAmts = new uint[](importInputData.supplyIds.length);
        data.supplyFinalAmts = new uint[](importInputData.supplyIds.length);
        data.supplyCtokensAddr = new address[](importInputData.supplyIds.length);

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            bytes32 i_hash = keccak256(abi.encode(importInputData.supplyIds[i]));
            for (uint j = i; j < importInputData.supplyIds.length; j++) {
                bytes32 j_hash = keccak256(abi.encode(importInputData.supplyIds[j]));
                if (j != i) {
                    require(i_hash != j_hash, "token-repeated");
                }
            }
        }

        for (uint i = 0; i < importInputData.supplyIds.length; i++) {
            (address _token, address _ctoken) = compMapping.getMapping(importInputData.supplyIds[i]);
            require(_token != address(0) && _ctoken != address(0), "ctoken mapping not found");

            uint _supplyIndex = add(i, importInputData.borrowIds.length);

            data.ctokens[_supplyIndex] = _ctoken;

            data.supplyCtokens[i] = CTokenInterface(_ctoken);
            data.supplyCtokensAddr[i] = (_ctoken);
            data.supplyAmts[i] = data.supplyCtokens[i].balanceOf(importInputData.userAccount);

            if ((importInputData.times == 1 && importInputData.isFlash) || importInputData.times == 0) {
                data.supplyFinalAmts = data.supplyAmts;
            } else {
                for (uint j = 0; j < data.supplyAmts.length; j++) {
                    uint _times = importInputData.isFlash ? importInputData.times : importInputData.times + 1;
                    data.supplySplitAmts[j] = data.supplyAmts[j] / _times;
                    data.supplyFinalAmts[j] = sub(data.supplyAmts[j], mul(data.supplySplitAmts[j], sub(_times, 1)));
                }

            }
        }
        return data;
    }

}

contract CompoundImportResolver is CompoundHelpers {
    constructor(address _instaCompoundMerkle) CompoundHelpers(_instaCompoundMerkle) {}

    function _importCompound(
        ImportInputData memory importInputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(importInputData.userAccount), "user-account-not-auth");

        require(importInputData.supplyIds.length > 0, "0-length-not-allowed");

        ImportData memory data;

        uint _length = add(importInputData.supplyIds.length, importInputData.borrowIds.length);
        data.ctokens = new address[](_length);
    
        data = getBorrowAmounts(importInputData, data);
        data = getSupplyAmounts(importInputData, data);

        enterMarkets(data.ctokens);

        if (!importInputData.isFlash && importInputData.times > 0) {
            _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplySplitAmts, importInputData.supplyIds.length);
        } else if (importInputData.times == 0) {
            _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplyFinalAmts, importInputData.supplyIds.length);
        }
        
        for (uint i = 0; i < importInputData.times; i++) {
            if (i == sub(importInputData.times, 1)) {
                _borrow(data.borrowCtokens, data.borrowFinalAmts, importInputData.borrowIds.length);
                _paybackOnBehalf(importInputData.userAccount, data.borrowCtokens, data.borrowFinalAmts, importInputData.borrowIds.length);
                _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplyFinalAmts, importInputData.supplyIds.length);
            } else {
                _borrow(data.borrowCtokens, data.borrowSplitAmts, importInputData.borrowIds.length);
                _paybackOnBehalf(importInputData.userAccount, data.borrowCtokens, data.borrowSplitAmts, importInputData.borrowIds.length);
                _transferCtokens(importInputData.userAccount, data.supplyCtokens, data.supplySplitAmts, importInputData.supplyIds.length);
            }
        }

        if (importInputData.index != 0) {
            instaCompoundMerkle.claim(
                importInputData.index,
                importInputData.userAccount,
                importInputData.rewardAmount,
                importInputData.networthAmount,
                importInputData.merkleProof,
                data.supplyCtokensAddr,
                data.borrowCtokensAddr,
                data.supplyAmts,
                data.borrowAmts
            );
        }

        _eventName = "LogCompoundImport(address,address[],string[],string[],uint256[],uint256[])";
        _eventParam = abi.encode(
            importInputData.userAccount,
            data.ctokens,
            importInputData.supplyIds,
            importInputData.borrowIds,
            data.supplyAmts,
            data.borrowAmts
        );
    }

    function importCompound(
        uint256 index,
        address userAccount,
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint256 times,
        bool isFlash,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] memory merkleProof
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            index: index,
            userAccount: userAccount,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            rewardAmount: rewardAmount,
            networthAmount: networthAmount,
            merkleProof: merkleProof
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }

    function migrateCompound(
        uint256 index,
        string[] memory supplyIds,
        string[] memory borrowIds,
        uint256 times,
        bool isFlash,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] memory merkleProof
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        ImportInputData memory inputData = ImportInputData({
            index: index,
            userAccount: msg.sender,
            supplyIds: supplyIds,
            borrowIds: borrowIds,
            times: times,
            isFlash: isFlash,
            rewardAmount: rewardAmount,
            networthAmount: networthAmount,
            merkleProof: merkleProof
        });

        (_eventName, _eventParam) = _importCompound(inputData);
    }
}

contract ConnectV2CompoundMerkleImport is CompoundImportResolver {
    constructor(address _instaCompoundMerkle) public CompoundImportResolver(_instaCompoundMerkle) {}

    string public constant name = "Compound-Merkle-Import-v1";
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
    function cast(
        string[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint); // For ERC20
    function liquidateBorrow(address borrower, uint repayAmount, address cTokenCollateral) external returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external returns (uint);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address, address, uint) external returns (bool);
    function allowance(address, address) external view returns (uint);

}

interface CETHInterface {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function liquidateBorrow(address borrower, address cTokenCollateral) external payable;
}

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cTokenAddress) external returns (uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

interface CompoundMappingInterface {
    function cTokenMapping(string calldata tokenId) external view returns (address);
    function getMapping(string calldata tokenId) external view returns (address, address);
}

interface InstaCompoundMerkleInterface {
    function claim(
        uint256 index,
        address account,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof,
        address[] memory supplyCtokens,
        address[] memory borrowCtokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) external;
}

pragma solidity ^0.7.0;

import { DSMath } from "../../../../common/math.sol";
import { Stores } from "../../../../common/stores.sol";

import { ComptrollerInterface, CETHInterface, CompoundMappingInterface } from "./interfaces.sol";

abstract contract Helpers is DSMath, Stores {
    /**
     * @dev CETH Interface
     */
    CETHInterface constant internal ceth = CETHInterface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);

    /**
     * @dev Compound Comptroller
     */
    ComptrollerInterface constant internal troller = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    /**
     * @dev Compound Mapping
     */
    CompoundMappingInterface internal constant compMapping = CompoundMappingInterface(0xA8F9D4aA7319C54C04404765117ddBf9448E2082); // Update the address

    /**
     * @dev enter compound market
     */
    function enterMarkets(address[] memory cErc20) internal {
        troller.enterMarkets(cErc20);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
    event LogCompoundImport(
        address indexed user,
        address[] ctokens,
        string[] supplyIds,
        string[] borrowIds,
        uint[] supplyAmts,
        uint[] borrowAmts
    );
}

pragma solidity ^0.7.0;

import { InstaCompoundMerkleInterface } from "./interfaces.sol";

abstract contract Variables {
    /**
     * @dev Insta Compound Merkle
     */
    InstaCompoundMerkleInterface immutable internal instaCompoundMerkle;

    constructor(address _instaCompoundMerkle) {
        instaCompoundMerkle = InstaCompoundMerkleInterface(_instaCompoundMerkle);
    }
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}