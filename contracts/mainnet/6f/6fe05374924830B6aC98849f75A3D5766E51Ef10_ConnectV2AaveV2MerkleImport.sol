pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { TokenInterface, AccountInterface } from "../../../../../common/interfaces.sol";
import { AaveInterface, ATokenInterface } from "./interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { Variables } from "./variables.sol";

abstract contract AaveResolver is Helpers, Events {
    function _TransferAtokens(
        uint _length,
        AaveInterface aave,
        ATokenInterface[] memory atokenContracts,
        uint[] memory amts,
        address[] memory tokens,
        address userAccount
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                uint256 _amt = amts[i];
                require(atokenContracts[i].transferFrom(userAccount, address(this), _amt), "allowance?");
                
                if (!getIsColl(tokens[i], address(this))) {
                    aave.setUserUseReserveAsCollateral(tokens[i], true);
                }
            }
        }
    }

    function _borrowOne(AaveInterface aave, address token, uint amt, uint rateMode) private {
        aave.borrow(token, amt, rateMode, referalCode, address(this));
    }

    function _paybackBehalfOne(AaveInterface aave, address token, uint amt, uint rateMode, address user) private {
        aave.repay(token, amt, rateMode, user);
    }

    function _BorrowStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 1);
            }
        }
    }

    function _BorrowVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _borrowOne(aave, tokens[i], amts[i], 2);
            }
        }
    }

    function _PaybackStable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
            }
        }
    }

    function _PaybackVariable(
        uint _length,
        AaveInterface aave,
        address[] memory tokens,
        uint256[] memory amts,
        address user
    ) internal {
        for (uint i = 0; i < _length; i++) {
            if (amts[i] > 0) {
                _paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
            }
        }
    }

    function getBorrowAmount(address _token, address userAccount) 
        internal
        view
        returns
    (
        uint256 stableBorrow,
        uint256 variableBorrow
    ) {
        (
            ,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        ) = aaveData.getReserveTokensAddresses(_token);

        stableBorrow = ATokenInterface(stableDebtTokenAddress).balanceOf(userAccount);
        variableBorrow = ATokenInterface(variableDebtTokenAddress).balanceOf(userAccount);
    }
}

contract AaveImportHelpers is AaveResolver {
    struct ImportData {
        uint[] supplyAmts;
        uint[] totalBorrowAmts;
        uint[] variableBorrowAmts;
        uint[] stableBorrowAmts;
        address[] _supplyTokens;
        address[] _borrowTokens;
        ATokenInterface[] aTokens;
        uint[] supplySplitAmts;
        uint[] variableBorrowSplitAmts;
        uint[] stableBorrowSplitAmts;
        uint[] supplyFinalAmts;
        uint[] variableBorrowFinalAmts;
        uint[] stableBorrowFinalAmts;
        uint[] totalBorrowAmtsFinalAmts;
        uint[] totalBorrowAmtsSplitAmts;
    }

    struct ImportInputData {
        address[] supplyTokens;
        address[] borrowTokens;
        bool convertStable;
        uint256 times;
        bool isFlash;
        uint256 index;
        uint256 rewardAmount;
        uint256 networthAmount;
        bytes32[] merkleProof;
    }

    function getBorrowAmounts (
        address userAccount,
        AaveInterface aave,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal returns(ImportData memory) {
        if (inputData.borrowTokens.length > 0) {
            data._borrowTokens = new address[](inputData.borrowTokens.length);
            data.variableBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.stableBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.totalBorrowAmts = new uint[](inputData.borrowTokens.length);
            data.variableBorrowSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.variableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            data.stableBorrowSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.stableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            data.totalBorrowAmtsSplitAmts = new uint256[](inputData.borrowTokens.length);
            data.totalBorrowAmtsFinalAmts = new uint256[](inputData.borrowTokens.length);

            if (inputData.times > 0) {
                for (uint i = 0; i < inputData.borrowTokens.length; i++) {
                    for (uint j = i; j < inputData.borrowTokens.length; j++) {
                        if (j != i) {
                            require(inputData.borrowTokens[i] != inputData.borrowTokens[j], "token-repeated");
                        }
                    }
                }


                for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
                    address _token = inputData.borrowTokens[i] == ethAddr ? wethAddr : inputData.borrowTokens[i];
                    data._borrowTokens[i] = _token;

                    (
                        data.stableBorrowAmts[i],
                        data.variableBorrowAmts[i]
                    ) = getBorrowAmount(_token, userAccount);

                    data.totalBorrowAmts[i] = add(data.stableBorrowAmts[i], data.variableBorrowAmts[i]);

                    if (data.totalBorrowAmts[i] > 0) {
                        uint256 _amt = inputData.times == 1 ? data.totalBorrowAmts[i] : uint256(-1);
                        TokenInterface(_token).approve(address(aave), _amt);
                    }
                }

                if (inputData.times == 1) {
                    data.variableBorrowFinalAmts = data.variableBorrowAmts;
                    data.stableBorrowFinalAmts = data.stableBorrowAmts;
                    data.totalBorrowAmtsFinalAmts = data.totalBorrowAmts;
                } else {
                    for (uint i = 0; i < data.totalBorrowAmts.length; i++) {
                        data.variableBorrowSplitAmts[i] = data.variableBorrowAmts[i] / inputData.times;
                        data.variableBorrowFinalAmts[i] = sub(data.variableBorrowAmts[i], mul(data.variableBorrowSplitAmts[i], sub(inputData.times, 1)));
                        data.stableBorrowSplitAmts[i] = data.stableBorrowAmts[i] / inputData.times;
                        data.stableBorrowFinalAmts[i] = sub(data.stableBorrowAmts[i], mul(data.stableBorrowSplitAmts[i], sub(inputData.times, 1)));
                        data.totalBorrowAmtsSplitAmts[i] = data.totalBorrowAmts[i] / inputData.times;
                        data.totalBorrowAmtsFinalAmts[i] = sub(data.totalBorrowAmts[i], mul(data.totalBorrowAmtsSplitAmts[i], sub(inputData.times, 1)));
                    }
                }
            }
        }
        return data;
    }

    function getBorrowFinalAmounts (
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(
        uint[] memory variableBorrowFinalAmts,
        uint[] memory stableBorrowFinalAmts,
        uint[] memory totalBorrowAmtsFinalAmts
    ) {    
        if (inputData.borrowTokens.length > 0) {
            variableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            stableBorrowFinalAmts = new uint256[](inputData.borrowTokens.length);
            totalBorrowAmtsFinalAmts = new uint[](inputData.borrowTokens.length);

            if (inputData.times > 0) {
                for (uint i = 0; i < data._borrowTokens.length; i++) {
                    address _token = data._borrowTokens[i];
                    (
                        stableBorrowFinalAmts[i],
                        variableBorrowFinalAmts[i]
                    ) = getBorrowAmount(_token, userAccount);

                    totalBorrowAmtsFinalAmts[i] = add(stableBorrowFinalAmts[i], variableBorrowFinalAmts[i]);
                }
            }
        }
    }

    function getSupplyAmounts (
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(ImportData memory) {
        data.supplyAmts = new uint[](inputData.supplyTokens.length);
        data._supplyTokens = new address[](inputData.supplyTokens.length);
        data.aTokens = new ATokenInterface[](inputData.supplyTokens.length);
        data.supplySplitAmts = new uint[](inputData.supplyTokens.length);
        data.supplyFinalAmts = new uint[](inputData.supplyTokens.length);

        for (uint i = 0; i < inputData.supplyTokens.length; i++) {
            for (uint j = i; j < inputData.supplyTokens.length; j++) {
                if (j != i) {
                    require(inputData.supplyTokens[i] != inputData.supplyTokens[j], "token-repeated");
                }
            }
        }

        for (uint i = 0; i < inputData.supplyTokens.length; i++) {
            address _token = inputData.supplyTokens[i] == ethAddr ? wethAddr : inputData.supplyTokens[i];
            (address _aToken, ,) = aaveData.getReserveTokensAddresses(_token);
            data._supplyTokens[i] = _token;
            data.aTokens[i] = ATokenInterface(_aToken);
            data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }

        if ((inputData.times == 1 && inputData.isFlash) || inputData.times == 0) {
            data.supplyFinalAmts = data.supplyAmts;
        } else {
            for (uint i = 0; i < data.supplyAmts.length; i++) {
                uint _times = inputData.isFlash ? inputData.times : inputData.times + 1;
                data.supplySplitAmts[i] = data.supplyAmts[i] / _times;
                data.supplyFinalAmts[i] = sub(data.supplyAmts[i], mul(data.supplySplitAmts[i], sub(_times, 1)));
            }
        }

        return data;
    }

    function getSupplyFinalAmounts(
        address userAccount,
        ImportInputData memory inputData,
        ImportData memory data
    ) internal view returns(uint[] memory supplyFinalAmts) {
        supplyFinalAmts = new uint[](inputData.supplyTokens.length);

        for (uint i = 0; i < data.aTokens.length; i++) {
            supplyFinalAmts[i] = data.aTokens[i].balanceOf(userAccount);
        }
    }
}

contract AaveImportResolver is AaveImportHelpers, Variables {
    constructor(address _instaAaveV2Merkle) Variables(_instaAaveV2Merkle) {}

    function _importAave(
        address userAccount,
        ImportInputData memory inputData
    ) internal returns (string memory _eventName, bytes memory _eventParam) {
        require(AccountInterface(address(this)).isAuth(userAccount), "user-account-not-auth");

        require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

        ImportData memory data;

        AaveInterface aave = AaveInterface(aaveProvider.getLendingPool());

        data = getBorrowAmounts(userAccount, aave, inputData, data);
        data = getSupplyAmounts(userAccount, inputData, data);

        if (!inputData.isFlash && inputData.times > 0) {
            _TransferAtokens(
                inputData.supplyTokens.length,
                aave,
                data.aTokens,
                data.supplySplitAmts,
                data._supplyTokens,
                userAccount
            );
        } else if (inputData.times == 0) {
            _TransferAtokens(
                inputData.supplyTokens.length,
                aave,
                data.aTokens,
                data.supplyFinalAmts,
                data._supplyTokens,
                userAccount
            );
        }

        for (uint i = 0; i < inputData.times; i++) {
            if (i == sub(inputData.times, 1)) {

                if (!inputData.isFlash && inputData.times == 1) {
                    data.supplyFinalAmts = getSupplyFinalAmounts(userAccount, inputData, data);
                }

                if (inputData.times > 1) {
                    (
                        data.variableBorrowFinalAmts,
                        data.stableBorrowFinalAmts,
                        data.totalBorrowAmtsFinalAmts
                    ) = getBorrowFinalAmounts(userAccount, inputData, data);
                    
                    data.supplyFinalAmts = getSupplyFinalAmounts(userAccount, inputData, data);
                }

                if (inputData.convertStable) {
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.totalBorrowAmtsFinalAmts);
                } else {
                    _BorrowStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowFinalAmts);
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowFinalAmts);
                }

                _PaybackStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowFinalAmts, userAccount);
                _PaybackVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowFinalAmts, userAccount);
                _TransferAtokens(inputData.supplyTokens.length, aave, data.aTokens, data.supplyFinalAmts, data._supplyTokens, userAccount);
            } else {
                if (inputData.convertStable) {
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.totalBorrowAmtsSplitAmts);
                } else {
                    _BorrowStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowSplitAmts);
                    _BorrowVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowSplitAmts);
                }

                _PaybackStable(inputData.borrowTokens.length, aave, data._borrowTokens, data.stableBorrowSplitAmts, userAccount);
                _PaybackVariable(inputData.borrowTokens.length, aave, data._borrowTokens, data.variableBorrowSplitAmts, userAccount);
                _TransferAtokens(inputData.supplyTokens.length, aave, data.aTokens, data.supplySplitAmts, data._supplyTokens, userAccount);
            }
        }

        if (inputData.index != 0) {
            instaAaveV2Merkle.claim(
                inputData.index,
                userAccount,
                inputData.rewardAmount,
                inputData.networthAmount,
                inputData.merkleProof,
                inputData.supplyTokens,
                inputData.borrowTokens,
                data.supplyAmts,
                data.totalBorrowAmts
            );
        }

        _eventName = "LogAaveV2Import(address,bool,address[],address[],uint256[],uint256[],uint256[])";
        _eventParam = abi.encode(
            userAccount,
            inputData.convertStable,
            inputData.supplyTokens,
            inputData.borrowTokens,
            data.supplyAmts,
            data.stableBorrowAmts,
            data.variableBorrowAmts
        );
    }

    // function importAave(
    //     uint256 index,
    //     address userAccount,
    //     address[] calldata supplyTokens,
    //     address[] calldata borrowTokens,
    //     bool convertStable,
    //     uint256 times,
    //     bool isFlash,
    //     uint256 rewardAmount,
    //     uint256 networthAmount,
    //     bytes32[] calldata merkleProof
    // ) external payable returns (string memory _eventName, bytes memory _eventParam) {
    function importAave(
        address userAccount,
        ImportInputData memory inputData
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {

        (_eventName, _eventParam) = _importAave(userAccount, inputData);
    }


    function migrateAave(
        ImportInputData memory inputData
    ) external payable returns (string memory _eventName, bytes memory _eventParam) {
        (_eventName, _eventParam) = _importAave(msg.sender, inputData);
    }
}

contract ConnectV2AaveV2MerkleImport is AaveImportResolver {
    constructor(address _instaAaveV2Merkle) public AaveImportResolver(_instaAaveV2Merkle) {}

    string public constant name = "AaveV2-Merkle-Import-v1";
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
pragma experimental ABIEncoderV2;

interface AaveInterface {
    function deposit(address _asset, uint256 _amount, address _onBehalfOf, uint16 _referralCode) external;
    function withdraw(address _asset, uint256 _amount, address _to) external;
    function borrow(
        address _asset,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode,
        address _onBehalfOf
    ) external;
    function repay(address _asset, uint256 _amount, uint256 _rateMode, address _onBehalfOf) external;
    function setUserUseReserveAsCollateral(address _asset, bool _useAsCollateral) external;
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
}

interface AaveLendingPoolProviderInterface {
    function getLendingPool() external view returns (address);
}

// Aave Protocol Data Provider
interface AaveDataProviderInterface {
    function getUserReserveData(address _asset, address _user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );

    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
}

interface AaveAddressProviderRegistryInterface {
    function getAddressesProvidersList() external view returns (address[] memory);
}

interface ATokenInterface {
    function scaledBalanceOf(address _user) external view returns (uint256);
    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);
    function balanceOf(address _user) external view returns(uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function allowance(address, address) external returns (uint256);
}

interface InstaAaveV2MerkleInterface {
    function claim(
        uint256 index,
        address account,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof,
        address[] memory supplytokens,
        address[] memory borrowtokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) external;
}

pragma solidity ^0.7.0;

import { DSMath } from "../../../../../common/math.sol";
import { Stores } from "../../../../../common/stores.sol";
import { AaveLendingPoolProviderInterface, AaveDataProviderInterface } from "./interfaces.sol";

abstract contract Helpers is DSMath, Stores {
    /**
     * @dev Aave referal code
     */
    uint16 constant internal referalCode = 3228;

    /**
     * @dev Aave Provider
     */
    AaveLendingPoolProviderInterface constant internal aaveProvider = AaveLendingPoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    /**
     * @dev Aave Data Provider
     */
    AaveDataProviderInterface constant internal aaveData = AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    function getIsColl(address token, address user) internal view returns (bool isCol) {
        (, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
    }
}

pragma solidity ^0.7.0;

contract Events {
    event LogAaveV2Import(
        address indexed user,
        bool convertStable,
        address[] supplyTokens,
        address[] borrowTokens,
        uint[] supplyAmts,
        uint[] stableBorrowAmts,
        uint[] variableBorrowAmts
    );
}

pragma solidity ^0.7.0;

import { InstaAaveV2MerkleInterface } from "./interfaces.sol";

abstract contract Variables {
    /**
     * @dev Insta AaveV2 Merkle
     */
    InstaAaveV2MerkleInterface immutable internal instaAaveV2Merkle;

    constructor(address _instaAaveV2Merkle) {
        instaAaveV2Merkle = InstaAaveV2MerkleInterface(_instaAaveV2Merkle);
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