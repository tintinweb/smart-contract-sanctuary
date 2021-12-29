// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {OpCast, Spell} from "./OpCast.sol";
import {OperationCenterInterface} from "../interfaces/IOperationCenter.sol";
import {AccountCenterInterface} from "../interfaces/IAccountCenter.sol";
import {ProtocolAaveV2Interface} from "../protocol/interface/IProtocolAaveV2.sol";
import {ProtocolERC20Interface} from "../protocol/interface/IProtocolERC20.sol";
import {ProtocolUniswapV2Interface} from "../protocol/interface/IProtocolUniswapV2.sol";
import {EventCenterLeveragePositionInterface} from "../event/interface/IEventCenterLeveragePosition.sol";

interface ProtocolCenterInterface {
    function getProtocol(string memory protocolName)
        external
        view
        returns (address protocol);
}

interface ConnectorCenterInterface {
    function getConnector(string calldata connectorNames)
        external
        view
        returns (bool, address);
}

interface IERC3156FlashLender {
    function flashFee(address token, uint256 amount)
        external
        view
        returns (uint256);
}

interface IERC20 {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract OpOnFlashLoan is OpCast {
    address public immutable lender;
    address public immutable opCenterAddress;

    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;

    constructor(
        address _connectorCenter,
        address _opCenterAddress,
        address _lender
    ) OpCast(_connectorCenter) {
        lender = _lender;
        opCenterAddress = _opCenterAddress;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external payable returns (bytes32) {
        require(msg.sender == address(lender), "onFlashLoan: Untrusted lender");

        require(
            initiator == address(this),
            "onFlashLoan: Untrusted loan initiator"
        );

        uint8 operation;
        bytes memory arguments;

        flashInitiator = initiator;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;

        (operation, arguments) = abi.decode(data, (uint8, bytes));

        if (operation == uint8(0)) {
            handleFlash(arguments);
        } else if (operation == uint8(1)) {
            handleOpenLong(arguments);
        } else if (operation == uint8(2)) {
            handleCloseLong(arguments);
        } else if (operation == uint8(3)) {
            handleOpenShort(arguments);
        } else if (operation == uint8(4)) {
            handleCloseShort(arguments);
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitUseFlashLoanForLeverageEvent(token, amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function handleOpenLong(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 pay;

        bool success;
        bytes memory data;

        (
            address leverageToken,
            address targetToken,
            uint256 amountLeverageToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256)
            );

        (notOverflow, pay) = SafeMath.tryAdd(
            amountLeverageToken,
            amountFlashLoan
        );

        require(notOverflow == true, "CHFRY: overflow 1");

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (notOverflow, _temp) = SafeMath.trySub(pay, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 2");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    targetToken,
                    leverageToken,
                    _temp,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 sellToken fail");

        uint256 buyAmount = abi.decode(data, (uint256));

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    targetToken,
                    buyAmount
                )
            );

        require(success == true, "CHFRY: call AAVEV2 depositToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "borrowToken(address,uint256,uint256)",
                    leverageToken,
                    amountFlashLoan,
                    rateMode
                )
            );
        require(success == true, "CHFRY: call AAVEV2 borrowToken fail");

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitOpenLongLeverageEvent(
                leverageToken,
                targetToken,
                pay,
                buyAmount,
                amountLeverageToken,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleCloseLong(bytes memory arguments) internal {
        uint256 _temp;
        uint256 gain;
        bool notOverflow;
        bool success;
        bytes memory data;

        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256)
            );

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "paybackToken(address,uint256,uint256)",
                    leverageToken,
                    amountFlashLoan,
                    rateMode
                )
            );

        require(success == true, "CHFRY: call AAVEV2 paybackToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "withdrawToken(address,uint256)",
                    targetToken,
                    amountTargetToken
                )
            );

        require(success == true, "CHFRY: call AAVEV2 withdrawToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    leverageToken,
                    targetToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(success == true, "CHFRY: call UniswapV2 protocol fail");

        gain = abi.decode(data, (uint256));

        (notOverflow, gain) = SafeMath.trySub(gain, flashLoanFee);

        require(notOverflow == true, "CHFRY: gain not cover flashLoanFee");

        (notOverflow, _temp) = SafeMath.trySub(gain, amountFlashLoan);

        require(notOverflow == true, "CHFRY: gain not cover flashloan");

        if (_temp > uint256(0)) {
            address EOA = AccountCenterInterface(accountCenter).getEOA(
                address(this)
            );
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        EOA
                    )
                );
            require(success == true, "CHFRY: pull back coin fail");
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitCloseLongLeverageEvent(
                leverageToken,
                targetToken,
                gain,
                amountTargetToken,
                amountFlashLoan,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleOpenShort(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 pay;
        bool success;
        bytes memory data;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountLeverageToken,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256, uint256)
            );

        (notOverflow, pay) = SafeMath.tryAdd(
            amountLeverageToken,
            amountFlashLoan
        );
        require(notOverflow == true, "CHFRY: overflow 1");

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (notOverflow, _temp) = SafeMath.trySub(pay, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 2");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "depositToken(address,uint256)",
                    leverageToken,
                    _temp
                )
            );
        require(
            success == true,
            "CHFRY: call AAVEV2 protocol depositToken fail"
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "borrowToken(address,uint256,uint256)",
                    targetToken,
                    amountTargetToken,
                    rateMode
                )
            );

        require(
            success == true,
            "CHFRY: call AAVEV2 protocol handleOpenShort borrowToken fail"
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "sellToken(address,address,uint256,uint256)",
                    leverageToken,
                    targetToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(
            success == true,
            "CHFRY: call UniswapV2 protocol fail sellToken"
        );

        (notOverflow, _temp) = SafeMath.trySub(
            abi.decode(data, (uint256)),
            _temp
        );

        require(notOverflow == true, "CHFRY: overflow 3");

        if (_temp > uint256(0)) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        AccountCenterInterface(accountCenter).getEOA(
                            address(this)
                        )
                    )
                );
            require(success == true, "CHFRY: pull back coin fail");
        }

        (notOverflow, pay) = SafeMath.trySub(pay, _temp);

        require(notOverflow == true, "CHFRY: overflow 3");

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitOpenShortLeverageEvent(
                leverageToken,
                targetToken,
                pay,
                amountTargetToken,
                amountLeverageToken,
                amountFlashLoan,
                unitAmt,
                rateMode
            );
    }

    function handleCloseShort(bytes memory arguments) internal {
        bool notOverflow;
        uint256 _temp;
        uint256 gain;
        bool success;
        bytes memory data;
        (
            address leverageToken,
            address targetToken,
            uint256 amountTargetToken,
            uint256 amountWithdraw,
            uint256 amountFlashLoan,
            uint256 unitAmt,
            uint256 rateMode
        ) = abi.decode(
                arguments,
                (address, address, uint256, uint256, uint256, uint256, uint256)
            );

        uint256 flashLoanFee = IERC3156FlashLender(lender).flashFee(
            leverageToken,
            amountFlashLoan
        );

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("UniswapV2").delegatecall(
                abi.encodeWithSignature(
                    "buyToken(address,address,uint256,uint256)",
                    targetToken,
                    leverageToken,
                    amountTargetToken,
                    unitAmt
                )
            );

        require(
            success == true,
            "CHFRY: call UniswapV2 handleCloseShort buyToken fail"
        );

        uint256 sellAmount = abi.decode(data, (uint256));

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "paybackToken(address,uint256,uint256)",
                    targetToken,
                    amountTargetToken,
                    rateMode
                )
            );

        require(success == true, "CHFRY: call AAVEV2 paybackToken fail");

        (success, data) = ProtocolCenterInterface(
            OperationCenterInterface(opCenterAddress).protocolCenterAddress()
        ).getProtocol("AAVEV2").delegatecall(
                abi.encodeWithSignature(
                    "withdrawToken(address,uint256)",
                    leverageToken,
                    amountWithdraw
                )
            );

        require(success == true, "CHFRY: call AAVEV2 withdrawToken fail");

        (notOverflow, _temp) = SafeMath.trySub(amountWithdraw, flashLoanFee);

        require(notOverflow == true, "CHFRY: overflow 1");

        gain = _temp;

        (notOverflow, _temp) = SafeMath.trySub(_temp, sellAmount);

        require(notOverflow == true, "CHFRY: overflow 2");

        if (_temp > uint256(0)) {
            (success, data) = ProtocolCenterInterface(
                OperationCenterInterface(opCenterAddress)
                    .protocolCenterAddress()
            ).getProtocol("ERC20").delegatecall(
                    abi.encodeWithSignature(
                        "pull(address,uint256,address)",
                        leverageToken,
                        _temp,
                        AccountCenterInterface(accountCenter).getEOA(
                            address(this)
                        )
                    )
                );

            require(success == true, "CHFRY: pull back coin fail");
        }

        EventCenterLeveragePositionInterface(
            OperationCenterInterface(opCenterAddress).eventCenterAddress()
        ).emitCloseShortLeverageEvent(
                leverageToken,
                targetToken,
                gain,
                amountTargetToken,
                amountFlashLoan,
                amountWithdraw,
                unitAmt,
                rateMode
            );
    }

    function handleFlash(bytes memory arguments) internal {
        Spell[] memory spells;
        spells = abi.decode(arguments, (Spell[]));
        _cast(spells);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpCommon.sol";

import {ConnectorCenterInterface} from "../connector/interface/IConnectorCenter.sol";

struct Spell {
    string name;
    bytes data;
}

contract OpCast is OpCommon {
    
    address public immutable connectorCenter;

    event SetConnectorCenter(address indexed connectorCenter);

    event LogCast(
        address indexed sender,
        uint256 value,
        string targetsName,
        address target,
        string eventName,
        bytes eventParam
    );

    constructor(address _connectorCenter) {
        connectorCenter = _connectorCenter;
    }


    function cast(Spell[] calldata spells) external payable {
        require(_auth[msg.sender], "CHFRY: Permission Denied");
        _cast(spells);
    }

    function _cast(Spell[] memory _spells) internal {
        uint256 _length = _spells.length;
        string memory eventName;
        bytes memory eventParam;
        for (uint256 i = 0; i < _length; i++) {
            (bool isOk, address _target) = ConnectorCenterInterface(
                connectorCenter
            ).getConnector(_spells[i].name);
            require(isOk, "CHFRY: Connector not fund");
            bytes memory response = spell(_target, _spells[i].data);
            (eventName, eventParam) = decodeEvent(response);
            emit LogCast(
                msg.sender,
                msg.value,
                _spells[i].name,
                _target,
                eventName,
                eventParam
            );
        }
    }

    function decodeEvent(bytes memory response)
        internal
        pure
        returns (string memory _eventCode, bytes memory _eventParams)
    {
        if (response.length > 0) {
            (_eventCode, _eventParams) = abi.decode(response, (string, bytes));
        }
    }

    function spell(address _target, bytes memory _data)
        internal
        returns (bytes memory response)
    {
        require(_target != address(0), "target-invalid");
        assembly {
            let succeeded := delegatecall(
                gas(),
                _target,
                add(_data, 0x20),
                mload(_data),
                0,
                0
            )

            let size := returndatasize()

            response := mload(0x40)
            mstore(
                0x40,
                add(response, and(add(add(size, 0x20), 0x1f), not(0x1f)))
            )
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OperationCenterInterface {
    function eventCenterAddress() external view returns (address);
    function connectorCenterAddress() external view returns (address);
    function tokenCenterAddress() external view returns (address);
    function protocolCenterAddress() external view returns (address);
    function getOpCodeAddress(bytes4 _sig) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccountCenterInterface {
    function accountCount() external view returns (uint256);

    function accountTypeCount() external view returns (uint256);

    function createAccount(uint256 accountTypeID)
        external
        returns (address _account);

    function getAccount(uint256 accountTypeID)
        external
        view
        returns (address _account);

    function getEOA(address account) external view returns (address payable _eoa);

    function isSmartAccount(address _address)
        external
        view
        returns (bool _isAccount);

    function isSmartAccountofTypeN(address _address, uint256 accountTypeID)
        external
        view
        returns (bool _isAccount);

    function getAccountCountOfTypeN(uint256 accountTypeID)
        external
        view
        returns (uint256 count);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolAaveV2Interface {
    function depositToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function withdrawToken(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function borrowToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function paybackToken(
        address token,
        uint256 amt,
        uint256 rateMode
    ) external payable returns (uint256 _amt);

    function enableTokenCollateral(address[] calldata tokens) external payable;

    function swapTokenBorrowRateMode(address token, uint256 rateMode)
        external
        payable;

    function getPaybackBalance(address token, uint256 rateMode)
        external
        view
        returns (uint256);

    function getCollateralBalance(address token)
        external
        view
        returns (uint256 bal);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolERC20Interface {
    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external payable returns (uint256 _amt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ProtocolUniswapV2Interface {
    function buyToken(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 unitAmt
    ) external payable returns (uint256 _sellAmt);

    function sellToken(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 unitAmt
    ) external payable returns (uint256 _buyAmt);

    function addTokenLiquidity(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 unitAmt,
        uint256 slippage
    )
        external
        payable
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        );

    function removeTokenLiquidity(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        external
        payable
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




interface EventCenterLeveragePositionInterface {
    function emitCreateAccountEvent(address EOA, address account) external;

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external;

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth;
    address internal accountCenter;
    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ConnectorCenterInterface {
    function setAccountIndex(address _accountIndex) external;
    function addConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external;
    function updateConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external;
    function removeConnectors(string[] calldata _connectorNames) external;
    function getConnectors(string[] calldata _connectorNames) external view returns (bool isOk, address[] memory _connectors);
    function getConnector(string memory _connectorName) external view returns (bool isOk, address _connectors);
}