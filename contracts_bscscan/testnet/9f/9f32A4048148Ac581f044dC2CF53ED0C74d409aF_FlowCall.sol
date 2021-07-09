pragma solidity ^0.8.6;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../node_modules/solidity-bytes-utils/contracts/BytesLib.sol";
import "./utils/Equation.sol";

contract FlowCall is Ownable, Pausable {
    using BytesLib for bytes;
    using Equation for Equation.Node[];

    uint256 public constant MAX_CALL_SEQ = 100;
    uint256 public constant PARAMETER_ID_FOR_TARGET_CONTRACT = 9999999999;
    uint256 public constant PARAMETER_ID_FOR_SEND_ETH_VALUE = 9999999998;

    struct CallInfo {
        address targetContract;
        bytes callData;
        uint256 sendEthValue;
        uint256 seq;
        ParameterFromVariable[] variableParameters;
        uint256 returnValuesCount;
        uint256[] callCondition;
    }

    struct ParameterFromVariable {
        uint256 parameterId; //refer to target contract if it equals PARAMETER_ID_FOR_TARGET_CONTRACT or PARAMETER_ID_FOR_SEND_ETH_VALUE
        uint256 variableId;
    }

    struct DataValue {
        //only support bytes32 fixed length variable type
        bool isValueSet;
        bytes32 value;
    }

    enum TriggerType {
        afterCall,
        afterSetVariableOperation
    }

    struct SetVariableOperation {
        uint256 variableIdToSet;
        TriggerType triggerType;
        uint256 triggerId; //callId or operationId according to the trigger type
        uint256[] valueExpression;
    }

    event ExternalCall(
        address indexed targetContract,
        uint256 sendValue,
        bytes callData,
        bytes returnData
    );

    event SetVariable(uint256 indexed variableId, bytes32 value);

    constructor() {}

    receive() external payable {}

    function flowCall(
        CallInfo[] calldata callList,
        uint256 variableCount,
        SetVariableOperation[] calldata setVariableOperationList
    ) external payable whenNotPaused {
        require(callList.length > 0, "FlowCall: at least one call needed");

        DataValue[] memory variableList = new DataValue[](variableCount);

        for (uint256 i = 0; i <= MAX_CALL_SEQ; i++) {
            for (uint256 j = 0; j < callList.length; j++) {
                if (callList[j].seq == i) {
                    (
                        bytes memory callData,
                        address target,
                        uint256 sendEthValue
                    ) = buildCallData(callList[j], variableList);
                    (bool success, bytes memory returnData) = target.call{
                        value: sendEthValue
                    }(callData);
                    require(success, "FlowCall: external call failed");
                    emit ExternalCall(
                        target,
                        sendEthValue,
                        callData,
                        returnData
                    );
                    //set after call
                    for (
                        uint256 k = 0;
                        k < setVariableOperationList.length;
                        k++
                    ) {
                        if (
                            setVariableOperationList[k].triggerType ==
                            TriggerType.afterCall &&
                            j == setVariableOperationList[k].triggerId
                        ) {
                            //build return values
                            require(
                                setVariableOperationList[k]
                                .valueExpression
                                .length > 0,
                                "FlowCall: invalid value expression"
                            );
                            require(
                                returnData.length >=
                                    callList[j].returnValuesCount * 32,
                                "FlowCall: invalid return values count"
                            );
                            require(
                                setVariableOperationList[k].variableIdToSet <
                                    variableCount,
                                "FlowCall: invalid variableIdToSet"
                            );
                            uint256[] memory returnValues = new uint256[](
                                callList[j].returnValuesCount
                            );
                            for (
                                uint256 ridx = 0;
                                ridx < callList[j].returnValuesCount;
                                ridx++
                            ) {
                                returnValues[ridx] = returnData.toUint256(
                                    ridx * 32
                                );
                            }
                            Equation.Node[] memory equation = Equation.init(
                                setVariableOperationList[k].valueExpression
                            );
                            variableList[
                                setVariableOperationList[k].variableIdToSet
                            ] = DataValue(
                                true,
                                bytes32(equation.calculate(returnValues))
                            );
                            emit SetVariable(
                                setVariableOperationList[k].variableIdToSet,
                                variableList[
                                    setVariableOperationList[k].variableIdToSet
                                ]
                                    .value
                            );
                            variableList = afterSetVariable(
                                k,
                                variableList,
                                setVariableOperationList
                            );
                        }
                    }
                }
            }
        }
    }

    function afterSetVariable(
        uint256 operationId,
        DataValue[] memory variableList,
        SetVariableOperation[] calldata setVariableOperationList
    ) private returns (DataValue[] memory) {
        //set after opertion
        for (uint256 i = 0; i < setVariableOperationList.length; i++) {
            if (
                setVariableOperationList[i].triggerType ==
                TriggerType.afterSetVariableOperation &&
                setVariableOperationList[i].triggerId == operationId
            ) {
                Equation.Node[] memory equation = Equation.init(
                    setVariableOperationList[i].valueExpression
                );
                uint256[] memory xValues = new uint256[](variableList.length);
                for (uint256 j = 0; j < variableList.length; j++) {
                    xValues[j] = uint256(variableList[j].value);
                }
                variableList[
                    setVariableOperationList[i].variableIdToSet
                ] = DataValue(true, bytes32(equation.calculate(xValues)));
                emit SetVariable(
                    setVariableOperationList[i].variableIdToSet,
                    variableList[setVariableOperationList[i].variableIdToSet]
                        .value
                );
                variableList = afterSetVariable(
                    i,
                    variableList,
                    setVariableOperationList
                );
            }
        }
        return variableList;
    }

    function buildCallData(
        CallInfo calldata call,
        DataValue[] memory variableList
    )
        private
        pure
        returns (
            bytes memory,
            address,
            uint256
        )
    {
        bytes memory callData = call.callData;
        address targetContract = call.targetContract;
        uint256 sendEthValue = call.sendEthValue;
        if (call.variableParameters.length == 0) {
            return (callData, targetContract, sendEthValue);
        }

        for (uint256 i = 0; i < call.variableParameters.length; i++) {
            require(
                call.variableParameters[i].variableId >= 0 &&
                    call.variableParameters[i].variableId < variableList.length,
                "FlowCall: variableId illegal"
            );
            DataValue memory v = variableList[
                call.variableParameters[i].variableId
            ];
            require(
                v.isValueSet,
                "FlowCall: this variable value hasn't be set"
            );
            if (
                call.variableParameters[i].parameterId ==
                PARAMETER_ID_FOR_TARGET_CONTRACT
            ) {
                targetContract = address(uint160(uint256(v.value)));
            } else if (
                call.variableParameters[i].parameterId ==
                PARAMETER_ID_FOR_SEND_ETH_VALUE
            ) {
                sendEthValue = uint256(v.value);
            } else {
                uint256 start = call.variableParameters[i].parameterId * 32 + 4;
                uint256 length = callData.length;
                require(
                    length - start - 32 >= 0,
                    "FlowCall: parameterId illegal"
                );
                bytes32 value = v.value;
                assembly {
                    mstore(add(add(callData, 32), start), value)
                }
            }
        }
        return (callData, targetContract, sendEthValue);
    }
}

pragma solidity ^0.8.6;
//SPDX-License-Identifier: MIT

import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
/**
 * @title BancorPower, modified from the original "BancorFomula.sol"
 *        written by Bancor https://github.com/bancorprotocol/contracts
 *
 * @dev Changes include:
 *  1. Remove Bancor's specific functions and replace SafeMath with OpenZeppelin's.
 *  2. Change code from Contract to Library and change maxExpArray from being array
 *     with binary search inside `findPositionInMaxExpArray` to a simple linear search.
 *  3. Add requirement check that baseN >= baseD (this is always true for Bancor).
 * Licensed under Apache Lisense, Version 2.0.
 */
library BancorPower {
    using SafeMath for uint256;
    string internal constant version = '0.3';
    uint256 private constant ONE = 1;
    uint32 private constant MAX_WEIGHT = 1000000;
    uint8 private constant MIN_PRECISION = 32;
    uint8 private constant MAX_PRECISION = 127;

    /**
        Auto-generated via 'PrintIntScalingFactors.py'
    */
    uint256 private constant FIXED_1 = 0x080000000000000000000000000000000;
    uint256 private constant FIXED_2 = 0x100000000000000000000000000000000;
    uint256 private constant MAX_NUM = 0x200000000000000000000000000000000;

    /**
        Auto-generated via 'PrintLn2ScalingFactors.py'
    */
    uint256 private constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 private constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    /**
        Auto-generated via 'PrintFunctionOptimalLog.py' and 'PrintFunctionOptimalExp.py'
    */
    uint256 private constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e3;
    uint256 private constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    /**
        General Description:
            Determine a value of precision.
            Calculate an integer approximation of (_baseN / _baseD) ^ (_expN / _expD) * 2 ^ precision.
            Return the result along with the precision used.

        Detailed Description:
            Instead of calculating "base ^ exp", we calculate "e ^ (log(base) * exp)".
            The value of "log(base)" is represented with an integer slightly smaller than "log(base) * 2 ^ precision".
            The larger "precision" is, the more accurately this value represents the real value.
            However, the larger "precision" is, the more bits are required in order to store this value.
            And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (maximum value of "x").
            This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
            Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
            This allows us to compute "base ^ exp" with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
            This functions assumes that "_expN < 2 ^ 256 / log(MAX_NUM - 1)", otherwise the multiplication should be replaced with a "safeMul".
    */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) internal pure returns (uint256, uint8) {
        require(_baseN < MAX_NUM);
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        }
        else {
            baseLog = generalLog(base);
        }

        uint256 baseLogTimesExp = baseLog * _expN / _expD;
        if (baseLogTimesExp < OPT_EXP_MAX_VAL) {
            return (optimalExp(baseLogTimesExp), MAX_PRECISION);
        }
        else {
            uint8 precision = findPositionInMaxExpArray(baseLogTimesExp);
            return (generalExp(baseLogTimesExp >> (MAX_PRECISION - precision), precision), precision);
        }
    }

    /**
    *   c >= 10^18
    *
     */
    function log(uint256 _c, uint256 _baseN, uint256 _baseD) internal pure returns (uint256) {
        // require(_baseN < MAX_NUM)
        require(_baseN >= _baseD);

        uint256 baseLog;
        uint256 base = _baseN * FIXED_1 / _baseD;
        if (base < OPT_LOG_MAX_VAL) {
            baseLog = optimalLog(base);
        } else {
            baseLog = generalLog(base);
        }

        return (baseLog * _c) / FIXED_1;
    }

    /**
        Compute log(x / FIXED_1) * FIXED_1.
        This functions assumes that "x >= FIXED_1", because the output would be negative otherwise.
    */
    function generalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        // If x >= 2, then we compute the integer part of log2(x), which is larger than 0.
        if (x >= FIXED_2) {
            uint8 count = floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // If x > 1, then we compute the fraction part of log2(x), which is larger than 0.
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += ONE << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }

    /**
        Compute the largest integer smaller than or equal to the binary logarithm of the input.
    */
    function floorLog2(uint256 _n) internal pure returns (uint8) {
        uint8 res = 0;

        if (_n < 256) {
            // At most 8 iterations
            while (_n > 1) {
                _n >>= 1;
                res += 1;
            }
        }
        else {
            // Exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (_n >= (ONE << s)) {
                    _n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }

    /**
        The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
        - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
        - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
    */
    function findPositionInMaxExpArray(uint256 _x) internal pure returns (uint8) {
        if (0x1c35fedd14ffffffffffffffffffffffff >= _x) return  32;
        if (0x1b0ce43b323fffffffffffffffffffffff >= _x) return  33;
        if (0x19f0028ec1ffffffffffffffffffffffff >= _x) return  34;
        if (0x18ded91f0e7fffffffffffffffffffffff >= _x) return  35;
        if (0x17d8ec7f0417ffffffffffffffffffffff >= _x) return  36;
        if (0x16ddc6556cdbffffffffffffffffffffff >= _x) return  37;
        if (0x15ecf52776a1ffffffffffffffffffffff >= _x) return  38;
        if (0x15060c256cb2ffffffffffffffffffffff >= _x) return  39;
        if (0x1428a2f98d72ffffffffffffffffffffff >= _x) return  40;
        if (0x13545598e5c23fffffffffffffffffffff >= _x) return  41;
        if (0x1288c4161ce1dfffffffffffffffffffff >= _x) return  42;
        if (0x11c592761c666fffffffffffffffffffff >= _x) return  43;
        if (0x110a688680a757ffffffffffffffffffff >= _x) return  44;
        if (0x1056f1b5bedf77ffffffffffffffffffff >= _x) return  45;
        if (0x0faadceceeff8bffffffffffffffffffff >= _x) return  46;
        if (0x0f05dc6b27edadffffffffffffffffffff >= _x) return  47;
        if (0x0e67a5a25da4107fffffffffffffffffff >= _x) return  48;
        if (0x0dcff115b14eedffffffffffffffffffff >= _x) return  49;
        if (0x0d3e7a392431239fffffffffffffffffff >= _x) return  50;
        if (0x0cb2ff529eb71e4fffffffffffffffffff >= _x) return  51;
        if (0x0c2d415c3db974afffffffffffffffffff >= _x) return  52;
        if (0x0bad03e7d883f69bffffffffffffffffff >= _x) return  53;
        if (0x0b320d03b2c343d5ffffffffffffffffff >= _x) return  54;
        if (0x0abc25204e02828dffffffffffffffffff >= _x) return  55;
        if (0x0a4b16f74ee4bb207fffffffffffffffff >= _x) return  56;
        if (0x09deaf736ac1f569ffffffffffffffffff >= _x) return  57;
        if (0x0976bd9952c7aa957fffffffffffffffff >= _x) return  58;
        if (0x09131271922eaa606fffffffffffffffff >= _x) return  59;
        if (0x08b380f3558668c46fffffffffffffffff >= _x) return  60;
        if (0x0857ddf0117efa215bffffffffffffffff >= _x) return  61;
        if (0x07ffffffffffffffffffffffffffffffff >= _x) return  62;
        if (0x07abbf6f6abb9d087fffffffffffffffff >= _x) return  63;
        if (0x075af62cbac95f7dfa7fffffffffffffff >= _x) return  64;
        if (0x070d7fb7452e187ac13fffffffffffffff >= _x) return  65;
        if (0x06c3390ecc8af379295fffffffffffffff >= _x) return  66;
        if (0x067c00a3b07ffc01fd6fffffffffffffff >= _x) return  67;
        if (0x0637b647c39cbb9d3d27ffffffffffffff >= _x) return  68;
        if (0x05f63b1fc104dbd39587ffffffffffffff >= _x) return  69;
        if (0x05b771955b36e12f7235ffffffffffffff >= _x) return  70;
        if (0x057b3d49dda84556d6f6ffffffffffffff >= _x) return  71;
        if (0x054183095b2c8ececf30ffffffffffffff >= _x) return  72;
        if (0x050a28be635ca2b888f77fffffffffffff >= _x) return  73;
        if (0x04d5156639708c9db33c3fffffffffffff >= _x) return  74;
        if (0x04a23105873875bd52dfdfffffffffffff >= _x) return  75;
        if (0x0471649d87199aa990756fffffffffffff >= _x) return  76;
        if (0x04429a21a029d4c1457cfbffffffffffff >= _x) return  77;
        if (0x0415bc6d6fb7dd71af2cb3ffffffffffff >= _x) return  78;
        if (0x03eab73b3bbfe282243ce1ffffffffffff >= _x) return  79;
        if (0x03c1771ac9fb6b4c18e229ffffffffffff >= _x) return  80;
        if (0x0399e96897690418f785257fffffffffff >= _x) return  81;
        if (0x0373fc456c53bb779bf0ea9fffffffffff >= _x) return  82;
        if (0x034f9e8e490c48e67e6ab8bfffffffffff >= _x) return  83;
        if (0x032cbfd4a7adc790560b3337ffffffffff >= _x) return  84;
        if (0x030b50570f6e5d2acca94613ffffffffff >= _x) return  85;
        if (0x02eb40f9f620fda6b56c2861ffffffffff >= _x) return  86;
        if (0x02cc8340ecb0d0f520a6af58ffffffffff >= _x) return  87;
        if (0x02af09481380a0a35cf1ba02ffffffffff >= _x) return  88;
        if (0x0292c5bdd3b92ec810287b1b3fffffffff >= _x) return  89;
        if (0x0277abdcdab07d5a77ac6d6b9fffffffff >= _x) return  90;
        if (0x025daf6654b1eaa55fd64df5efffffffff >= _x) return  91;
        if (0x0244c49c648baa98192dce88b7ffffffff >= _x) return  92;
        if (0x022ce03cd5619a311b2471268bffffffff >= _x) return  93;
        if (0x0215f77c045fbe885654a44a0fffffffff >= _x) return  94;
        if (0x01ffffffffffffffffffffffffffffffff >= _x) return  95;
        if (0x01eaefdbdaaee7421fc4d3ede5ffffffff >= _x) return  96;
        if (0x01d6bd8b2eb257df7e8ca57b09bfffffff >= _x) return  97;
        if (0x01c35fedd14b861eb0443f7f133fffffff >= _x) return  98;
        if (0x01b0ce43b322bcde4a56e8ada5afffffff >= _x) return  99;
        if (0x019f0028ec1fff007f5a195a39dfffffff >= _x) return 100;
        if (0x018ded91f0e72ee74f49b15ba527ffffff >= _x) return 101;
        if (0x017d8ec7f04136f4e5615fd41a63ffffff >= _x) return 102;
        if (0x016ddc6556cdb84bdc8d12d22e6fffffff >= _x) return 103;
        if (0x015ecf52776a1155b5bd8395814f7fffff >= _x) return 104;
        if (0x015060c256cb23b3b3cc3754cf40ffffff >= _x) return 105;
        if (0x01428a2f98d728ae223ddab715be3fffff >= _x) return 106;
        if (0x013545598e5c23276ccf0ede68034fffff >= _x) return 107;
        if (0x01288c4161ce1d6f54b7f61081194fffff >= _x) return 108;
        if (0x011c592761c666aa641d5a01a40f17ffff >= _x) return 109;
        if (0x0110a688680a7530515f3e6e6cfdcdffff >= _x) return 110;
        if (0x01056f1b5bedf75c6bcb2ce8aed428ffff >= _x) return 111;
        if (0x00faadceceeff8a0890f3875f008277fff >= _x) return 112;
        if (0x00f05dc6b27edad306388a600f6ba0bfff >= _x) return 113;
        if (0x00e67a5a25da41063de1495d5b18cdbfff >= _x) return 114;
        if (0x00dcff115b14eedde6fc3aa5353f2e4fff >= _x) return 115;
        if (0x00d3e7a3924312399f9aae2e0f868f8fff >= _x) return 116;
        if (0x00cb2ff529eb71e41582cccd5a1ee26fff >= _x) return 117;
        if (0x00c2d415c3db974ab32a51840c0b67edff >= _x) return 118;
        if (0x00bad03e7d883f69ad5b0a186184e06bff >= _x) return 119;
        if (0x00b320d03b2c343d4829abd6075f0cc5ff >= _x) return 120;
        if (0x00abc25204e02828d73c6e80bcdb1a95bf >= _x) return 121;
        if (0x00a4b16f74ee4bb2040a1ec6c15fbbf2df >= _x) return 122;
        if (0x009deaf736ac1f569deb1b5ae3f36c130f >= _x) return 123;
        if (0x00976bd9952c7aa957f5937d790ef65037 >= _x) return 124;
        if (0x009131271922eaa6064b73a22d0bd4f2bf >= _x) return 125;
        if (0x008b380f3558668c46c91c49a2f8e967b9 >= _x) return 126;
        if (0x00857ddf0117efa215952912839f6473e6 >= _x) return 127;
        require(false);
        return 0;
    }

    /**
        This function can be auto-generated by the script 'PrintFunctionGeneralExp.py'.
        It approximates "e ^ x" via maclaurin summation: "(x^0)/0! + (x^1)/1! + ... + (x^n)/n!".
        It returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy.
        The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1".
        The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
    */
    function generalExp(uint256 _x, uint8 _precision) internal pure returns (uint256) {
        uint256 xi = _x;
        uint256 res = 0;

        xi = (xi * _x) >> _precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * _x) >> _precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * _x) >> _precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * _x) >> _precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * _x) >> _precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * _x) >> _precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * _x) >> _precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * _x) >> _precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * _x) >> _precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * _x) >> _precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * _x) >> _precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + _x + (ONE << _precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }

    /**
        Return log(x / FIXED_1) * FIXED_1
        Input range: FIXED_1 <= x <= LOG_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalLog.py'
        Detailed description:
        - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
        - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
        - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
        - The natural logarithm of the input is calculated by summing up the intermediate results above
        - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
    */
    function optimalLog(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd8) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd8;} // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a7) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a7;} // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a1) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a1;} // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a8) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a8;} // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd3) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd3;} // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a2) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a2;} // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e99) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e99;} // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f733) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f733;} // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16

        return res;
    }

    /**
        Return e ^ (x / FIXED_1) * FIXED_1
        Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
        Auto-generated via 'PrintFunctionOptimalExp.py'
        Detailed description:
        - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
        - The exponentiation of each binary exponent is given (pre-calculated)
        - The exponentiation of r is calculated via Taylor series for e^x, where x = r
        - The exponentiation of the input is calculated by multiplying the intermediate results above
        - For example: e^5.021692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
    */
    function optimalExp(uint256 x) internal pure returns (uint256) {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }
}

pragma solidity ^0.8.6;
//SPDX-License-Identifier: MIT
import "./BancorPower.sol";
import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

library Equation {
    using SafeMath for uint256;
  /// An expression tree is encoded as a set of nodes, with root node having index zero. Each node has 3 values:
  ///  1. opcode: the expression that the node represents. See table below.
  /// +--------+----------------------------------------+------+------------+
  /// | Opcode |              Description               | i.e. | # children |
  /// +--------+----------------------------------------+------+------------+
  /// |   00   | Integer Constant                       |   c  |      0     |
  /// |   01   | Variable                               |   X  |      0     |
  /// |   02   | Arithmetic Square Root                 |   √  |      1     |
  /// |   03   | Boolean Not Condition                  |   !  |      1     |
  /// |   04   | Arithmetic Addition                    |   +  |      2     |
  /// |   05   | Arithmetic Subtraction                 |   -  |      2     |
  /// |   06   | Arithmetic Multiplication              |   *  |      2     |
  /// |   07   | Arithmetic Division                    |   /  |      2     |
  /// |   08   | Arithmetic Exponentiation              |  **  |      2     |
  /// |   09   | Arithmetic Percentage* (see below)     |   %  |      2     |
  /// |   10   | Arithmetic Equal Comparison            |  ==  |      2     |
  /// |   11   | Arithmetic Non-Equal Comparison        |  !=  |      2     |
  /// |   12   | Arithmetic Less-Than Comparison        |  <   |      2     |
  /// |   13   | Arithmetic Greater-Than Comparison     |  >   |      2     |
  /// |   14   | Arithmetic Non-Greater-Than Comparison |  <=  |      2     |
  /// |   15   | Arithmetic Non-Less-Than Comparison    |  >=  |      2     |
  /// |   16   | Boolean And Condition                  |  &&  |      2     |
  /// |   17   | Boolean Or Condition                   |  ||  |      2     |
  /// |   18   | Ternary Operation                      |  ?:  |      3     |
  /// |   19   | Bancor's log** (see below)             |      |      3     |
  /// |   20   | Bancor's power*** (see below)          |      |      4     |
  /// +--------+----------------------------------------+------+------------+
  ///  2. children: the list of node indices of this node's sub-expressions. Different opcode nodes will have different
  ///     number of children.
  ///  3. value: the value inside the node. Currently this is only relevant for Integer Constant (Opcode 00).
  /// (*) Arithmetic percentage is computed by multiplying the left-hand side value with the right-hand side,
  ///     and divide the result by 10^18, rounded down to uint256 integer.
  /// (**) Using BancorFormula, the opcode computes log of fractional numbers. However, this fraction's value must
  ///     be more than 1. (baseN / baseD >= 1). The opcode takes 3 childrens(c, baseN, baseD), and computes
  ///     (c * log(baseN / baseD)) limitation is in range of 1 <= baseN / baseD <= 58774717541114375398436826861112283890
  ///     (= 1e76/FIXED_1), where FIXED_1 defined in BancorPower.sol
  /// (***) Using BancorFomula, the opcode computes exponential of fractional numbers. The opcode takes 4 children
  ///     (c,baseN,baseD,expV), and computes (c * ((baseN / baseD) ^ (expV / 1e6))). See implementation for the
  ///     limitation of the each value's domain. The end result must be in uint256 range.
  struct Node {
    uint8 opcode;
    uint8 child0;
    uint8 child1;
    uint8 child2;
    uint8 child3;
    uint256 value;
  }

  enum ExprType { Invalid, Math, Boolean }

  uint8 constant OPCODE_CONST = 0;
  uint8 constant OPCODE_VAR = 1;
  uint8 constant OPCODE_SQRT = 2;
  uint8 constant OPCODE_NOT = 3;
  uint8 constant OPCODE_ADD = 4;
  uint8 constant OPCODE_SUB = 5;
  uint8 constant OPCODE_MUL = 6;
  uint8 constant OPCODE_DIV = 7;
  uint8 constant OPCODE_EXP = 8;
  uint8 constant OPCODE_PCT = 9;
  uint8 constant OPCODE_EQ = 10;
  uint8 constant OPCODE_NE = 11;
  uint8 constant OPCODE_LT = 12;
  uint8 constant OPCODE_GT = 13;
  uint8 constant OPCODE_LE = 14;
  uint8 constant OPCODE_GE = 15;
  uint8 constant OPCODE_AND = 16;
  uint8 constant OPCODE_OR = 17;
  uint8 constant OPCODE_IF = 18;
  uint8 constant OPCODE_BANCOR_LOG = 19;
  uint8 constant OPCODE_BANCOR_POWER = 20;
  uint8 constant OPCODE_INVALID = 21;

  /// @dev Initialize equation by array of opcodes/values in prefix order. Array
  /// is read as if it is the *pre-order* traversal of the expression tree.
  function init(uint256[] calldata _expressions) internal returns(Node[] memory){

    /// Limit expression length to < 256 to make sure gas cost is managable.
    require(_expressions.length < 256);

    Node[] memory temp=new Node[](_expressions.length);
    uint nodeCount=0;
    for (uint8 idx = 0; idx < _expressions.length; ++idx) {
      uint256 opcode = _expressions[idx];
      require(opcode < OPCODE_INVALID);
      Node memory node;
      node.opcode = uint8(opcode);
      /// Get the node's value. Only applicable on Integer Constant case.
      if (opcode == OPCODE_CONST || opcode == OPCODE_VAR) {
        node.value = _expressions[++idx];
      }
      temp[nodeCount++]=node;
    }

    require(nodeCount>0);

    Node[] memory equation=new Node[](nodeCount);
    for(uint i=0;i<nodeCount;i++){
        equation[i]=temp[i];
    }
    
    (uint8 lastNodeIndex,,Node[] memory result) = populateTree(equation, 0);
    require(lastNodeIndex == equation.length - 1);
    return result;
  }

  /// Calculate the Y position from the X position for this equation.
  function calculate(Node[] memory self, uint256[] memory xValues) internal view returns (uint256) {
    return solveMath(self, 0, xValues);
  }

  /// Return the number of children the given opcode node has.
  function getChildrenCount(uint8 opcode) private pure returns (uint8) {
    if (opcode <= OPCODE_VAR) {
      return 0;
    } else if (opcode <= OPCODE_NOT) {
      return 1;
    } else if (opcode <= OPCODE_OR) {
      return 2;
    } else if (opcode <= OPCODE_BANCOR_LOG) {
      return 3;
    } else if (opcode <= OPCODE_BANCOR_POWER) {
      return 4;
    } 
    revert();
  }

  /// Check whether the given opcode and list of expression types match. Revert on failure.
  function checkExprType(uint8 opcode, ExprType[] memory types)
    private pure returns (ExprType)
  {
    if (opcode <= OPCODE_VAR) {
      return ExprType.Math;
    } else if (opcode == OPCODE_SQRT) {
      require(types[0] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode == OPCODE_NOT) {
      require(types[0] == ExprType.Boolean);
      return ExprType.Boolean;
    } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      return ExprType.Boolean;
    } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
      require(types[0] == ExprType.Boolean);
      require(types[1] == ExprType.Boolean);
      return ExprType.Boolean;
    } else if (opcode == OPCODE_IF) {
      require(types[0] == ExprType.Boolean);
      require(types[1] != ExprType.Invalid);
      require(types[1] == types[2]);
      return types[1];
    } else if (opcode == OPCODE_BANCOR_LOG) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      require(types[2] == ExprType.Math);
      return ExprType.Math;
    } else if (opcode == OPCODE_BANCOR_POWER) {
      require(types[0] == ExprType.Math);
      require(types[1] == ExprType.Math);
      require(types[2] == ExprType.Math);
      require(types[3] == ExprType.Math);
      return ExprType.Math;
    } 
    revert();
  }

  /// Helper function to recursively populate node infoMaprmation following the given pre-order
  /// node list. It inspects the opcode and recursively call populateTree(s) accordingly.
  /// @param self memory pointer to equation data to build tree.
  /// @param currentNodeIndex the index of the current node to populate infoMap.
  /// @return An (uint8, bool). The first value represents the last  (highest/rightmost) node
  /// index of the current subtree. The second value indicates the type of this subtree.
  function populateTree(Node[] memory self, uint8 currentNodeIndex)
    private returns (uint8, ExprType,Node[] memory)
  {
    require(currentNodeIndex < self.length);
    Node memory node = self[currentNodeIndex];
    uint8 opcode = node.opcode;
    uint8 childrenCount = getChildrenCount(opcode);
    ExprType[] memory childrenTypes = new ExprType[](childrenCount);
    uint8 lastNodeIdx = currentNodeIndex;
    for (uint8 idx = 0; idx < childrenCount; ++idx) {
      if (idx == 0) node.child0 = lastNodeIdx + 1;
      else if (idx == 1) node.child1 = lastNodeIdx + 1;
      else if (idx == 2) node.child2 = lastNodeIdx + 1;
      else if (idx == 3) node.child3 = lastNodeIdx + 1;
      else revert();
      (lastNodeIdx, childrenTypes[idx],self) = populateTree(self, lastNodeIdx + 1);
    }
    self[currentNodeIndex]=node;
    ExprType exprType = checkExprType(opcode, childrenTypes);
    return (lastNodeIdx, exprType, self);
  }


  function solveMath(Node[] memory self, uint8 nodeIdx, uint256[] memory xValues)
    private view returns (uint256)
  {
    Node memory node = self[nodeIdx];
    uint8 opcode = node.opcode;
    if (opcode == OPCODE_CONST) {
      return node.value;
    } else if (opcode == OPCODE_VAR) {
      require(node.value<xValues.length,"Equation: opcode of var illegal");
      return xValues[node.value];
    } else if (opcode == OPCODE_SQRT) {
      uint256 childValue = solveMath(self, node.child0, xValues);
      uint256 temp = childValue.add(1).div(2);
      uint256 result = childValue;
      while (temp < result) {
        result = temp;
        temp = childValue.div(temp).add(temp).div(2);
      }
      return result;
    } else if (opcode >= OPCODE_ADD && opcode <= OPCODE_PCT) {
      uint256 leftValue = solveMath(self, node.child0, xValues);
      uint256 rightValue = solveMath(self, node.child1, xValues);
      if (opcode == OPCODE_ADD) {
        return leftValue.add(rightValue);
      } else if (opcode == OPCODE_SUB) {
        return leftValue.sub(rightValue);
      } else if (opcode == OPCODE_MUL) {
        return leftValue.mul(rightValue);
      } else if (opcode == OPCODE_DIV) {
        return leftValue.div(rightValue);
      } else if (opcode == OPCODE_EXP) {
        uint256 power = rightValue;
        uint256 expResult = 1;
        for (uint256 idx = 0; idx < power; ++idx) {
          expResult = expResult.mul(leftValue);
        }
        return expResult;
      } else if (opcode == OPCODE_PCT) {
        return leftValue.mul(rightValue).div(1e18);
      }
    } else if (opcode == OPCODE_IF) {
      bool condValue = solveBool(self, node.child0, xValues);
      if (condValue) return solveMath(self, node.child1, xValues);
      else return solveMath(self, node.child2, xValues);
    } else if (opcode == OPCODE_BANCOR_LOG) {
      uint256 multiplier = solveMath(self, node.child0, xValues);
      uint256 baseN = solveMath(self, node.child1, xValues);
      uint256 baseD = solveMath(self, node.child2, xValues);
      return BancorPower.log(multiplier, baseN, baseD);
    } else if (opcode == OPCODE_BANCOR_POWER) {
      uint256 multiplier = solveMath(self, node.child0, xValues);
      uint256 baseN = solveMath(self, node.child1, xValues);
      uint256 baseD = solveMath(self, node.child2, xValues);
      uint256 expV = solveMath(self, node.child3, xValues);
      require(expV < 1 << 32);
      (uint256 expResult, uint8 precision) = BancorPower.power(baseN, baseD, uint32(expV), 1e6);
      return expResult.mul(multiplier) >> precision;
    }
    revert();
  }

  function solveBool(Node[] memory self, uint8 nodeIdx, uint256[] memory xValues)
    private view returns (bool)
  {
    Node memory node = self[nodeIdx];
    uint8 opcode = node.opcode;
    if (opcode == OPCODE_NOT) {
      return !solveBool(self, node.child0, xValues);
    } else if (opcode >= OPCODE_EQ && opcode <= OPCODE_GE) {
      uint256 leftValue = solveMath(self, node.child0, xValues);
      uint256 rightValue = solveMath(self, node.child1, xValues);
      if (opcode == OPCODE_EQ) {
        return leftValue == rightValue;
      } else if (opcode == OPCODE_NE) {
        return leftValue != rightValue;
      } else if (opcode == OPCODE_LT) {
        return leftValue < rightValue;
      } else if (opcode == OPCODE_GT) {
        return leftValue > rightValue;
      } else if (opcode == OPCODE_LE) {
        return leftValue <= rightValue;
      } else if (opcode == OPCODE_GE) {
        return leftValue >= rightValue;
      }
    } else if (opcode >= OPCODE_AND && opcode <= OPCODE_OR) {
      bool leftBoolValue = solveBool(self, node.child0, xValues);
      if (opcode == OPCODE_AND) {
        if (leftBoolValue) return solveBool(self, node.child1, xValues);
        else return false;
      } else if (opcode == OPCODE_OR) {
        if (leftBoolValue) return true;
        else return solveBool(self, node.child1, xValues);
      }
    } else if (opcode == OPCODE_IF) {
      bool condValue = solveBool(self, node.child0, xValues);
      if (condValue) return solveBool(self, node.child1, xValues);
      else return solveBool(self, node.child2, xValues);
    }
    revert();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
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
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
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
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}