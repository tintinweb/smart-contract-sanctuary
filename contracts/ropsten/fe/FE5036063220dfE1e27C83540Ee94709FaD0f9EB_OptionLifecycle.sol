// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Utils.sol";
import "./StructureData.sol";
//import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

library OptionLifecycle {
    using SafeERC20 for IERC20;
    using Utils for uint128;
    using Utils for uint256;
    using SafeMath for uint256;
    using SafeCast for uint256;
    using StructureData for StructureData.UserState;

    function deriveVirtualLocked(
        StructureData.UserState memory userState,
        uint16 premiumRate
    ) internal pure returns (uint256) {
        uint256 onGoing = uint256(userState.ongoingAsset);
        if (onGoing == 0) {
            return uint256(userState.tempLocked);
        }
        onGoing = (onGoing.sub(userState.assetToTerminate)).withPremium(
            premiumRate
        );
        if (userState.tempLocked == 0) {
            return onGoing;
        }
        return uint256(userState.tempLocked).add(onGoing);
    }

    function getAvailableBalance(address _asset, address _source)
        external
        view
        returns (uint256)
    {
        if (_asset != address(0)) {
            return IERC20(_asset).balanceOf(_source);
        } else {
            return _source.balance;
        }
    }

    function withdraw(
        address _target,
        uint256 _amount,
        address _contractAddress
    ) external {
        require(_amount > 0);
        if (_contractAddress == address(0)) {
            payable(_target).transfer(_amount);
        } else {
            IERC20(_contractAddress).safeTransfer(_target, _amount);
        }
    }

    function calculateMaturity(
        bool _execute,
        StructureData.OptionState memory _optionState,
        bool _callOrPut,
        uint8 _depositAssetAmountDecimals,
        uint8 _counterPartyAssetAmountDecimals
    ) public pure returns (StructureData.MaturedState memory) {
        StructureData.MaturedState memory state = StructureData.MaturedState({
            releasedDepositAssetAmount: 0,
            releasedDepositAssetPremiumAmount: 0,
            releasedDepositAssetAmountWithPremium: 0,
            autoRollDepositAssetAmount: 0,
            autoRollDepositAssetPremiumAmount: 0,
            autoRollDepositAssetAmountWithPremium: 0,
            releasedCounterPartyAssetAmount: 0,
            releasedCounterPartyAssetPremiumAmount: 0,
            releasedCounterPartyAssetAmountWithPremium: 0,
            autoRollCounterPartyAssetAmount: 0,
            autoRollCounterPartyAssetPremiumAmount: 0,
            autoRollCounterPartyAssetAmountWithPremium: 0
        });
        if (_execute) {
            uint256 maturedCounterPartyAssetAmount = 
                _callOrPut
                    ? uint256(_optionState.totalAmount)
                        .mul(_optionState.strikePrice)
                        .mul(10**_counterPartyAssetAmountDecimals)
                        .div(
                            10 **
                                (StructureData.PRICE_PRECISION +
                                    _depositAssetAmountDecimals)
                        )
                    : uint256(_optionState.totalAmount)
                        .mul(
                            10 **
                                (StructureData.PRICE_PRECISION +
                                    _counterPartyAssetAmountDecimals)
                        )
                        .div(_optionState.strikePrice)
                        .div(10**_depositAssetAmountDecimals);

            uint256 maturedCounterPartyAssetPremiumAmount = maturedCounterPartyAssetAmount
                    .premium(_optionState.premiumRate);
            if (_optionState.totalTerminate > 0) {
                state
                    .releasedCounterPartyAssetAmount = maturedCounterPartyAssetAmount
                    .getAmountToTerminate(
                        _optionState.totalTerminate,
                        _optionState.totalAmount
                    );
                state
                    .releasedCounterPartyAssetPremiumAmount = maturedCounterPartyAssetPremiumAmount
                    .getAmountToTerminate(
                        _optionState.totalTerminate,
                        _optionState.totalAmount
                    );
                state.releasedCounterPartyAssetAmountWithPremium =
                    state.releasedCounterPartyAssetAmount.add(
                    state.releasedCounterPartyAssetPremiumAmount);
            }
            state.autoRollCounterPartyAssetAmount =
                maturedCounterPartyAssetAmount.sub(
                state.releasedCounterPartyAssetAmount);
            state.autoRollCounterPartyAssetPremiumAmount =
                maturedCounterPartyAssetPremiumAmount.sub(
                state.releasedCounterPartyAssetPremiumAmount);
            state.autoRollCounterPartyAssetAmountWithPremium =
                state.autoRollCounterPartyAssetAmount.add(
                state.autoRollCounterPartyAssetPremiumAmount);
        } else {
            uint256 maturedDepositAssetAmount = uint256(_optionState.totalAmount);
            uint256 maturedDepositAssetPremiumAmount = maturedDepositAssetAmount
                .premium(_optionState.premiumRate);
            if (_optionState.totalTerminate > 0) {
                state.releasedDepositAssetAmount = maturedDepositAssetAmount
                    .getAmountToTerminate(
                        _optionState.totalTerminate,
                        _optionState.totalAmount
                    );
                state
                    .releasedDepositAssetPremiumAmount = maturedDepositAssetPremiumAmount
                    .getAmountToTerminate(
                        _optionState.totalTerminate,
                        _optionState.totalAmount
                    );
                state.releasedDepositAssetAmountWithPremium =
                    state.releasedDepositAssetAmount.add(
                    state.releasedDepositAssetPremiumAmount);
            }
            state.autoRollDepositAssetAmount =
                maturedDepositAssetAmount.sub(
                state.releasedDepositAssetAmount);
            state.autoRollDepositAssetPremiumAmount =
                maturedDepositAssetPremiumAmount.sub(
                state.releasedDepositAssetPremiumAmount);
            state.autoRollDepositAssetAmountWithPremium =
                state.autoRollDepositAssetAmount.add(
                state.autoRollDepositAssetPremiumAmount);
        }
        return state;
    }

    function commitByOption(
        StructureData.OptionData storage _option,
        uint16 _roundToCommit
    ) external {
        uint256 userCount = _option.usersInvolved.length;
        for (uint256 i = 0; i < userCount; i++) {
            StructureData.UserState storage userState = _option.userStates[
                _option.usersInvolved[i]
            ];
            if (userState.assetToTerminateForNextRound != 0) {
                userState.assetToTerminate = userState
                    .assetToTerminateForNextRound;
                userState.assetToTerminateForNextRound = 0;
            } else if (userState.assetToTerminate != 0) {
                userState.assetToTerminate = 0;
            }
            if (userState.tempLocked == 0) {
                userState.ongoingAsset = 0;
                continue;
            }
            userState.ongoingAsset = userState.tempLocked;
            userState.tempLocked = 0;
        } 
        _option.optionStates[_roundToCommit].totalTerminate = uint256(_option
            .optionStates[_roundToCommit]
            .totalTerminate)
            .add(_option.assetToTerminateForNextRound).toUint128();
        _option.assetToTerminateForNextRound = 0;
    }

    function rollToNextByOption(
        StructureData.OptionData storage _option,
        uint16 _currentRound,
        bool _callOrPut
    ) external returns (uint128 _pendingAmount) { 
        StructureData.OptionState memory currentOption = StructureData
            .OptionState({
                round: _currentRound,
                totalAmount: 0,
                totalTerminate: 0,
                premiumRate: 0,
                strikePrice: 0,
                executed: false,
                callOrPut: _callOrPut
            });
        _option.optionStates[_currentRound] = currentOption;
        if (_currentRound > 1) {
            uint256 userCount = _option.usersInvolved.length;
            for (uint256 i = 0; i < userCount; i++) {
                StructureData.UserState storage userState = _option.userStates[
                    _option.usersInvolved[i]
                ];
                if (userState.pendingAsset != 0) {
                    userState.tempLocked = userState.pendingAsset;
                }
                userState.pendingAsset = 0;
            }
        } 
        return
            _currentRound > 1
                ? _option.optionStates[_currentRound - 1].totalAmount
                : 0;
    }

    function dryRunSettlementByOption(
        StructureData.OptionData storage _option,
        bool _isCall,
        uint8 _depositAssetAmountDecimals,
        uint8 _counterPartyAssetAmountDecimals,
        uint16 _currentRound,
        bool _execute
    )
        external
        view
        returns (StructureData.SettlementAccountingResult memory _result)
    {
        StructureData.SettlementAccountingResult memory result = StructureData
            .SettlementAccountingResult({ 
                depositAmount: _option
                    .optionStates[_currentRound - 1]
                    .totalAmount,
                executed: _execute,
                autoRollAmount: 0,
                autoRollPremium: 0,
                releasedAmount: 0,
                releasedPremium: 0,
                autoRollCounterPartyAmount: 0,
                autoRollCounterPartyPremium: 0,
                releasedCounterPartyAmount: 0,
                releasedCounterPartyPremium: 0
            });
        if (_currentRound > 2) {
            StructureData.OptionState storage previousOptionState = _option
                .optionStates[_currentRound - 2];
            if (previousOptionState.totalAmount == 0) {
                return result;
            }
            StructureData.MaturedState memory maturedState = calculateMaturity(
                _execute,
                previousOptionState,
                _isCall,
                _depositAssetAmountDecimals,
                _counterPartyAssetAmountDecimals
            );
            if (_execute) {
                result.autoRollCounterPartyAmount = maturedState
                    .autoRollCounterPartyAssetAmount.toUint128();
                result.autoRollCounterPartyPremium = maturedState
                    .autoRollCounterPartyAssetPremiumAmount.toUint128();
                result.releasedCounterPartyAmount = maturedState
                    .releasedCounterPartyAssetAmount.toUint128();
                result.releasedCounterPartyPremium = maturedState
                    .releasedCounterPartyAssetPremiumAmount.toUint128();
            } else {
                result.autoRollAmount = maturedState.autoRollDepositAssetAmount.toUint128();
                result.autoRollPremium = maturedState
                    .autoRollDepositAssetPremiumAmount.toUint128();
                result.releasedAmount = maturedState.releasedDepositAssetAmount.toUint128();
                result.releasedPremium = maturedState
                    .releasedDepositAssetPremiumAmount.toUint128();
            }
        }
        return result;
    }

    function closePreviousByOption(
        StructureData.OptionData storage _option,
        StructureData.OptionState storage previousOptionState,
        bool _isCall,
        uint8 _depositAssetAmountDecimals,
        uint8 _counterPartyAssetAmountDecimals,
        bool _execute
    ) external returns (StructureData.MaturedState memory _maturedState) {
        //uint16 maturedRound = currentRound - 2;
        StructureData.MaturedState memory maturedState = calculateMaturity(
            _execute,
            previousOptionState,
            _isCall,
            _depositAssetAmountDecimals,
            _counterPartyAssetAmountDecimals
        );
        previousOptionState.executed = _execute;

        if (_execute) {
            _option.totalReleasedCounterPartyAssetAmount =uint256(_option
                .totalReleasedCounterPartyAssetAmount)
                .add(maturedState.releasedCounterPartyAssetAmountWithPremium).toUint128();
        } else {
            _option.totalReleasedDepositAssetAmount = uint256(_option
                .totalReleasedDepositAssetAmount)
                .add(maturedState.releasedDepositAssetAmountWithPremium).toUint128();
        }
        return maturedState;
    }
    /*
        struct OptionParameters { 
        uint128 strikePrice; // strike price if executed
        uint16 premiumRate; //take, 0.01% is represented as 1, precision is 4
    }
*/
    function setOptionParameters(uint256 _parameters, StructureData.OptionState storage _optionState) external {
 
        require(_optionState.strikePrice == 0); 
        _optionState.strikePrice = uint128(_parameters >> 16);
        _optionState.premiumRate = uint16(_parameters & 0xffff);     
    }
    function getAccountBalance(
        StructureData.OptionData storage _option,
        address _user,
        bool _underSettlement,
        uint16 _currentRound
    ) external view returns (StructureData.UserBalance memory) {
        StructureData.UserState storage userState = _option.userStates[_user];

        StructureData.UserBalance memory result = StructureData.UserBalance({
            pendingDepositAssetAmount: userState.pendingAsset,
            releasedDepositAssetAmount: userState.releasedDepositAssetAmount,
            releasedCounterPartyAssetAmount: userState
                .releasedCounterPartyAssetAmount,
            lockedDepositAssetAmount: 0,
            terminatingDepositAssetAmount: 0,
            toTerminateDepositAssetAmount: 0
        });
        if (_underSettlement) {
            if (_currentRound > 2) {
                //when there are maturing round waiting for settlement, it becomes complex
                uint16 premiumRate = _option
                    .optionStates[_currentRound - 2]
                    .premiumRate;
                result.lockedDepositAssetAmount = deriveVirtualLocked(
                    userState,
                    premiumRate
                ).toUint128();
                result.terminatingDepositAssetAmount = uint256(userState
                    .assetToTerminate)
                    .withPremium(premiumRate).toUint128();
            } else {
                result.lockedDepositAssetAmount = userState.tempLocked;
            }
            result.toTerminateDepositAssetAmount = userState
                    .assetToTerminateForNextRound;
        } else {
            result.lockedDepositAssetAmount = userState.ongoingAsset;
            result.toTerminateDepositAssetAmount = userState.assetToTerminate;
        }
        return result;
    }

    function getOptionSnapShot(
        StructureData.OptionData storage _option,
        bool _underSettlement,
        uint16 _currentRound
    ) external view returns (StructureData.OptionSnapshot memory) {
        StructureData.OptionState memory lockedOption;
        StructureData.OptionState memory onGoingOption;
        StructureData.OptionSnapshot memory result = StructureData
            .OptionSnapshot({
                totalPending: _option.optionStates[_currentRound].totalAmount,
                totalReleasedDeposit: _option.totalReleasedDepositAssetAmount,
                totalReleasedCounterParty: _option
                    .totalReleasedCounterPartyAssetAmount,
                totalLocked: 0,
                totalTerminating: 0,
                totalToTerminate: 0
            });
        if (_underSettlement) {
            lockedOption = _option.optionStates[_currentRound - 1];
            result.totalToTerminate = _option.assetToTerminateForNextRound;
            if (_currentRound > 2) {
                //when there are maturing round waiting for settlement, it becomes complex
                onGoingOption = _option.optionStates[_currentRound - 2];
                result.totalTerminating = uint256(onGoingOption
                    .totalTerminate)
                    .withPremium(onGoingOption.premiumRate).toUint128();
                result.totalLocked = uint256(lockedOption
                    .totalAmount)
                    .add(
                        onGoingOption.totalAmount.withPremium(
                            onGoingOption.premiumRate
                        )
                    )
                    .sub(result.totalTerminating).toUint128();
            } else {
                result.totalLocked = lockedOption.totalAmount;
            }
        } else if (_currentRound > 1) {
            onGoingOption = _option.optionStates[_currentRound - 1];
            result.totalLocked = onGoingOption.totalAmount;
            result.totalToTerminate = onGoingOption.totalTerminate;
        }
        return result;
    }

    function initiateWithrawStorage(
        StructureData.OptionData storage _option,
        address _user,
        uint256 _assetToTerminate,
        bool _underSettlement,
        uint16 _currentRound
    ) external {
        StructureData.UserState storage userState = _option.userStates[_user];
        if (_underSettlement) {
            uint256 newAssetToTerminate = uint256(userState
                .assetToTerminateForNextRound)
                .add(_assetToTerminate);
            if (_currentRound == 2) {
                require(newAssetToTerminate <= userState.tempLocked);
                StructureData.OptionState storage previousOption = _option
                    .optionStates[_currentRound - 1];
                previousOption.totalTerminate = uint256(previousOption
                    .totalTerminate)
                    .add(_assetToTerminate).toUint128();
            } else {
                StructureData.OptionState storage onGoingOption = _option
                    .optionStates[_currentRound - 2];
                uint256 totalLocked = deriveVirtualLocked(
                    userState,
                    onGoingOption.premiumRate
                );
                require(newAssetToTerminate <= totalLocked);
                //store temporarily
                _option.assetToTerminateForNextRound = uint256(_option
                    .assetToTerminateForNextRound)
                    .add(_assetToTerminate).toUint128();
            }
            userState.assetToTerminateForNextRound = newAssetToTerminate.toUint128();
        } else {
            uint256 newAssetToTerminate = uint256(userState.assetToTerminate).add(
                _assetToTerminate
            );
            require(newAssetToTerminate <= userState.ongoingAsset);
            userState.assetToTerminate = newAssetToTerminate.toUint128();
            StructureData.OptionState storage previousOption = _option
                .optionStates[_currentRound - 1];
            previousOption.totalTerminate = uint256(previousOption.totalTerminate).add(
                _assetToTerminate
            ).toUint128();
        }
    }

    function cancelWithdrawStorage(
        StructureData.OptionData storage _option,
        address _user,
        uint256 _assetToTerminate,
        bool _underSettlement,
        uint16 _currentRound
    ) external {
        StructureData.UserState storage userState = _option.userStates[_user];
        if (_underSettlement) {
            userState.assetToTerminateForNextRound = uint256(userState
                .assetToTerminateForNextRound)
                .sub(_assetToTerminate).toUint128();
            if (_currentRound == 2) {
                StructureData.OptionState storage previousOption = _option
                    .optionStates[_currentRound - 1];
                previousOption.totalTerminate = uint256(previousOption
                    .totalTerminate)
                    .sub(_assetToTerminate).toUint128();
            } else {
                //store temporarily
                _option.assetToTerminateForNextRound = uint256(_option
                    .assetToTerminateForNextRound)
                    .sub(_assetToTerminate).toUint128();
            }
        } else {
            userState.assetToTerminate = uint256(userState.assetToTerminate).sub(
                _assetToTerminate
            ).toUint128();
            StructureData.OptionState storage previousOption = _option
                .optionStates[_currentRound - 1];
            previousOption.totalTerminate = uint256(previousOption.totalTerminate).sub(
                _assetToTerminate
            ).toUint128();
        }
    }

    function withdrawStorage(
        StructureData.OptionData storage _option,
        address _user,
        uint256 _amount,
        uint16 _currentRound,
        bool _isDeposit
    ) external {
        //require(_amount > 0, "!amount");
        StructureData.UserState storage userState = _option.userStates[_user];
        if (_isDeposit) {
            //todo: 0 out released amount if missing balance from trader
            uint256 releasedAmount = uint256(userState.releasedDepositAssetAmount);
            if (releasedAmount <= _amount) {
                uint256 redeemAmount = _amount.sub(releasedAmount);
                userState.pendingAsset = uint256(userState.pendingAsset).sub(
                    redeemAmount
                ).toUint128();
                userState.releasedDepositAssetAmount = 0;
                _option.totalReleasedDepositAssetAmount = uint256(_option
                    .totalReleasedDepositAssetAmount)
                    .sub(releasedAmount).toUint128();
                StructureData.OptionState storage optionState = _option
                    .optionStates[_currentRound];
                optionState.totalAmount = uint256(optionState.totalAmount).sub(
                    redeemAmount
                ).toUint128();
            } else {
                userState.releasedDepositAssetAmount = releasedAmount.sub(
                    _amount
                ).toUint128();
                _option.totalReleasedDepositAssetAmount = uint256(_option
                    .totalReleasedDepositAssetAmount)
                    .sub(_amount).toUint128();
            }
        } else {
            //same result as completeWithdraw
            userState.releasedCounterPartyAssetAmount = uint256(userState
                .releasedCounterPartyAssetAmount)
                .sub(_amount).toUint128();
            _option.totalReleasedCounterPartyAssetAmount = uint256(_option
                .totalReleasedCounterPartyAssetAmount)
                .sub(_amount).toUint128();
        }
    }

    function depositFor(
        StructureData.OptionData storage _option,
        address _userAddress,
        uint256 _amount,
        uint256 _toTerminate,
        uint16 _round,
        bool _isOpenRound
    ) external {
        //require(optionState.totalAmount + (_amount) <= quota[_optionId], "Not enough quota");

        StructureData.OptionState storage optionState = _option.optionStates[
            _round
        ];
        StructureData.UserState storage userState = _option.userStates[
            _userAddress
        ];
        //first time added
        if (!userState.hasState) {
            userState.hasState = true;
            _option.usersInvolved.push(_userAddress);
        }
        if (!_isOpenRound) {
            userState.tempLocked = uint256(userState.tempLocked).add(_amount).toUint128();
            if (_toTerminate > 0) {
                userState.assetToTerminateForNextRound = uint256(userState
                    .assetToTerminateForNextRound)
                    .add(_toTerminate).toUint128();
                _option.assetToTerminateForNextRound = uint256(_option
                    .assetToTerminateForNextRound)
                    .add(_toTerminate).toUint128();
            }
        } else {
            userState.pendingAsset = uint256(userState.pendingAsset).add(_amount).toUint128();
        }
        optionState.totalAmount = uint256(optionState.totalAmount).add(_amount).toUint128();
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
library Utils { 
     
    uint256 public constant RATIOMULTIPLIER = 10000;
 
     using SafeMath for uint256;
      function StringConcat(bytes memory _base, bytes memory _value) internal pure returns (string memory) {
        string memory _tmpValue = new string(_base.length + _value.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_base.length; i++) {
            _newValue[j++] = _base[i];
        }

        for(i=0; i<_value.length; i++) {
            _newValue[j++] = _value[i++];
        }

        return string(_newValue);
    }

    function Uint8Sub(uint8 a, uint8 b) internal pure returns (uint8) {
        require(b <= a);
        return a - b;
    }
    
 
    function getAmountToTerminate(uint256 _maturedAmount, uint256 _assetToTerminate, uint256 _assetAmount) 
    internal pure returns(uint256) {
       if (_assetToTerminate == 0 || _assetAmount == 0 || _maturedAmount == 0) return 0;
       return _assetToTerminate >= _assetAmount ?  _maturedAmount  : _maturedAmount.mul(_assetToTerminate).div(_assetAmount);
   }

   function withPremium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return  _baseAmount.mul(RATIOMULTIPLIER + _premimumRate).div(RATIOMULTIPLIER);
   }
   
   function premium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return   _baseAmount.mul(_premimumRate).div(RATIOMULTIPLIER);
   }
   
   function subOrZero(uint256 _base, uint256 _substractor) internal pure returns (uint256) {
       return _base >= _substractor ? _base - _substractor : 0;
   }
  
    /*function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }*/

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library StructureData {
    bytes32 public constant OPTION_ROLE = keccak256("OPTION_ROLE");
    bytes32 public constant SETTLER_ROLE = keccak256("SETTLER_ROLE");
    uint8 public constant MATUREROUND = 1; //7 for daily settlement, 1 for daily settlement
    uint8 public constant PRICE_PRECISION = 4;
    struct OptionParameters { 
        uint128 strikePrice; // strike price if executed
        uint16 premiumRate; //take, 0.01% is represented as 1, precision is 4
    }

    struct OptionState {
        uint128 totalAmount;
        uint128 totalTerminate;
        uint128 strikePrice;
        uint16 round;
        uint16 premiumRate; //take, 0.01% is represented as 1, precision is 4
        bool executed;
        bool callOrPut; //call for collateral -> stablecoin; put for stablecoin->collateral;
    }

    struct MaturedState {
        uint256 releasedDepositAssetAmount;
        uint256 releasedDepositAssetPremiumAmount;
        uint256 releasedDepositAssetAmountWithPremium;
        uint256 releasedCounterPartyAssetAmount;
        uint256 releasedCounterPartyAssetPremiumAmount;
        uint256 releasedCounterPartyAssetAmountWithPremium;
        uint256 autoRollDepositAssetAmount;
        uint256 autoRollDepositAssetPremiumAmount;
        uint256 autoRollDepositAssetAmountWithPremium;
        uint256 autoRollCounterPartyAssetAmount;
        uint256 autoRollCounterPartyAssetPremiumAmount;
        uint256 autoRollCounterPartyAssetAmountWithPremium;
    }

    struct AssetData {
        uint128 releasedAmount; //debit
        uint128 depositAmount; //credit
        int128 leftOverAmount; //history balance
        /*
         *  actual balance perspective
         *  withdrawable = redeemable + released
         *  balance = withdrawable + leftOver
         */
        uint128 balanceAfterSettle;
        uint128 withdrawableAfterSettle;
        uint128 traderWithdrawn;
    }

    struct OptionData {
        uint128 totalReleasedDepositAssetAmount;
        uint128 totalReleasedCounterPartyAssetAmount;
        uint128 assetToTerminateForNextRound;
        mapping(uint16 => StructureData.OptionState) optionStates;
        address[] usersInvolved;
        mapping(address => StructureData.UserState) userStates;
    }

    struct UserState {
        uint128 pendingAsset; //for current round
        uint128 tempLocked; //asset not sent to trader yet, but closed for deposit
        uint128 ongoingAsset;
        uint128 assetToTerminate;
        uint128 assetToTerminateForNextRound;
        uint128 releasedDepositAssetAmount;
        uint128 releasedCounterPartyAssetAmount;
        bool hasState;
    }

    struct OptionSnapshot {
        uint128 totalPending;
        //total tvl = totalLocked + totalTerminating
        uint128 totalLocked;
        //only set during settlement
        uint128 totalTerminating;
        //amount to terminate in next round,  totalToTerminate <= totalLocked
        uint128 totalToTerminate;
        uint128 totalReleasedDeposit;
        uint128 totalReleasedCounterParty;
    }

    struct UserBalance {
        uint128 pendingDepositAssetAmount;
        //tvl = lockedDepositAssetAmount + terminatingDepositAssetAmount
        uint128 lockedDepositAssetAmount;
        //only set during settlement
        uint128 terminatingDepositAssetAmount;
        //amount to terminate in next round, toTerminateDepositAssetAmount <= lockedDepositAssetAmount
        uint128 toTerminateDepositAssetAmount;
        uint128 releasedDepositAssetAmount;
        uint128 releasedCounterPartyAssetAmount;
    }
    struct OptionPairDefinition {
        uint8 callOptionId;
        uint8 putOptionId;
        uint8 depositAssetAmountDecimals;
        uint8 counterPartyAssetAmountDecimals;
        address depositAsset;
        address counterPartyAsset;
    }
    struct SettlementAccountingResult {
        uint128 depositAmount;
        uint128 autoRollAmount; //T-1 Carried (filled only when not executed)
        uint128 autoRollPremium; //Premium (filled only when not executed)
        //maturedAmount+maturedPremium = requested withdrawal for deposit asset(filled only when not executed and with withdraw request)
        uint128 releasedAmount;
        uint128 releasedPremium;
        //autoRollCounterPartyAmount + autoRollCounterPartyPremium = Execution rolled-out for deposit asset (Execution roll-in for counter party option)
        //filled only when executed
        uint128 autoRollCounterPartyAmount;
        uint128 autoRollCounterPartyPremium;
        //maturedCounterPartyAmount+maturedCounterPartyPremium= requested withdrawal for couter party asset(filled only when executed and with withdraw request)
        uint128 releasedCounterPartyAmount;
        uint128 releasedCounterPartyPremium;  
        bool executed;
    }

    enum OptionExecution {
        NoExecution,
        ExecuteCall,
        ExecutePut
    }

    struct OptionPairExecutionAccountingResult {
        SettlementAccountingResult callOptionResult;
        SettlementAccountingResult putOptionResult;
        OptionExecution execute;
    }

    struct SettlementCashflowResult {
        uint128 newDepositAmount;
        uint128 newReleasedAmount;
        int128 leftOverAmount; //positive, if trader didn't withdraw last time; negative, if trader failed to send back last time;
        address contractAddress; //0 for eth
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}