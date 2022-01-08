/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
// @author: 0age


interface FeeCollectorFactoryInterface {
    function getDeploymentAddress(
        FeeRecipient[] memory feeRecipients
    ) external view returns (address);

    function deployAndCollect(
        FeeRecipient[] calldata feeRecipients,
        address[] calldata tokens,
        uint256 gasPerTransfer // maximum gas submitter is willing to spend to process each transfer
    ) external;

    event Deployed(
        address feeCollector,
        FeeRecipient[] feeRecipients
    );
}


interface FeeCollectorInterface {
    function feeRecipients() external view returns (
        FeeRecipient[] memory feeRecipients
    );

    function initialize(FeeRecipient[] memory feeRecipients_) external; // only callable by factory

    function collect(
        address[] calldata tokens, // use 0xeeee...eeee for Ether
        uint256 gasPerTransfer     // maximum gas submitter is willing to spend to process each transfer
    ) external returns (
        CollectedTokenAmount[] memory amounts
    ); // arrays of recipient amounts nested in arrays of tokens

    event Collected(address token, uint256[] amounts); // emitted for each token collected

    error NotEnoughFeeRecipients();
    error TooManyFeeRecipients();
    error InvalidFeeBips();
    error NoBalance(address token);
    error GasPerTransferTooLow(uint256 gasPerTransferShortfall);
    error BadReturnValueFromTokenOnTransfer(address token, address to);
}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}


struct FeeRecipient {
    address payable account;
    uint16 feeBips;
}


struct CollectedTokenAmount {
    uint256[] amounts;
}


contract FeeCollectorFactory is FeeCollectorFactoryInterface {
    address immutable private _feeCollectorImplementation;

    constructor() {
        FeeCollectorImplementation implementation = new FeeCollectorImplementation();
        _feeCollectorImplementation = address(implementation);
    }

    function getDeploymentAddress(
        FeeRecipient[] memory feeRecipients
    ) external view returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            uint256(0),
            keccak256(abi.encodePacked(
                type(FeeCollectorProxy).creationCode,
                abi.encode(_feeCollectorImplementation, feeRecipients)
            ))
        )))));
    }

    function deployAndCollect(
        FeeRecipient[] memory feeRecipients,
        address[] memory tokens,
        uint256 gasPerTransfer
    ) public {
        FeeCollectorProxy feeCollector = new FeeCollectorProxy{salt: 0}(
            _feeCollectorImplementation,
            feeRecipients
        );

        emit Deployed(
            address(feeCollector),
            feeRecipients
        );

        FeeCollectorInterface(address(feeCollector)).collect(
            tokens, gasPerTransfer
        );
    }
}


contract FeeCollectorImplementation is FeeCollectorInterface {
    address private constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    FeeRecipient[] private _feeRecipients;

    function initialize(FeeRecipient[] memory feeRecipients_) external {
        // Ensure this function is only callable during contract construction.
        assembly { if extcodesize(address()) { revert(0, 0) } }

        if (feeRecipients_.length < 2) {
            revert NotEnoughFeeRecipients();
        }

        if (feeRecipients_.length > 10) {
            revert TooManyFeeRecipients();
        }

        uint256 totalFeeBips;
        for (uint256 i = 0; i < feeRecipients_.length; i++) {
            FeeRecipient memory feeRecipient = feeRecipients_[i];
            _feeRecipients.push(feeRecipient);
            totalFeeBips += uint256(feeRecipient.feeBips);
        }

        if (totalFeeBips != 10_000) {
            revert InvalidFeeBips();
        }
    }

    function collect(
        address[] memory tokens,
        uint256 gasPerTransfer
    ) public returns (
        CollectedTokenAmount[] memory amountsPerToken
    ) {
        if (gasPerTransfer < 100_000) {
            revert GasPerTransferTooLow(100_000 - gasPerTransfer);
        }

        uint256 totalFeeRecipients = _feeRecipients.length;

        amountsPerToken = new CollectedTokenAmount[](tokens.length);

        uint256[] memory amounts = new uint256[](totalFeeRecipients);

        for (uint256 t = 0; t < tokens.length; t++) {
            address token = tokens[t];

            if (token == _ETH) {
                amountsPerToken[t].amounts =  _collectEth(
                    gasPerTransfer, totalFeeRecipients
                );
                continue;
            }

            uint256 balance = IERC20(token).balanceOf(address(this));

            if (balance == 0) {
                revert NoBalance(token);
            }

            uint256 amount;
            bool transferSucceeded;
            for (uint256 i = 1; i < totalFeeRecipients; i++) {
                FeeRecipient memory feeRecipient = _feeRecipients[i];
                amount = (balance * uint256(feeRecipient.feeBips)) / 10_000;

                (bool ok, bytes memory data) = token.call{gas: gasPerTransfer}(
                    abi.encodeWithSelector(
                        IERC20.transfer.selector, feeRecipient.account, amount
                    )
                );

                transferSucceeded = ok && (
                    (data.length == 32 && abi.decode(data, (bool))) ||
                    data.length == 0
                );

                if (!transferSucceeded) {
                    amount = 0;
                }

                amounts[i] = amount;
            }

            amount = IERC20(token).balanceOf(address(this));
            if (amount != 0) {
                FeeRecipient memory primaryFeeRecipient = _feeRecipients[0];

                (bool primaryOk, bytes memory primaryData) = token.call(
                    abi.encodeWithSelector(
                        IERC20.transfer.selector,
                        primaryFeeRecipient.account,
                        amount
                    )
                );
                if (!primaryOk) {
                    assembly {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }

                transferSucceeded = (
                    (
                        primaryData.length == 32 &&
                        abi.decode(primaryData, (bool))
                    ) ||
                    primaryData.length == 0
                );

                if (!transferSucceeded) {
                    revert BadReturnValueFromTokenOnTransfer(
                        token, primaryFeeRecipient.account
                    );
                }

                amounts[0] = amount;
            }

            emit Collected(token, amounts);

            amountsPerToken[t].amounts = amounts;
        }

        return amountsPerToken;
    }

    function feeRecipients() external view returns (FeeRecipient[] memory) {
        return _feeRecipients;
    }

    function _collectEth(
        uint256 gasPerTransfer,
        uint256 totalFeeRecipients
    ) internal returns (
        uint256[] memory amounts
    ) {
        uint256 balance = address(this).balance;

        if (balance == 0) {
            revert NoBalance(_ETH);
        }

        amounts = new uint256[](totalFeeRecipients);

        uint256 amount;
        bool ok;
        for (uint256 i = 1; i < totalFeeRecipients; i++) {
            FeeRecipient memory feeRecipient = _feeRecipients[i];
            amount = (balance * uint256(feeRecipient.feeBips)) / 10_000;

            (ok,) = feeRecipient.account.call{
                value: amount,
                gas: gasPerTransfer
            }("");

            if (!ok) {
                amount = 0;
            }

            amounts[i] = amount;
        }

        amount = address(this).balance;
        if (amount == 0) {
            return amounts;
        }

        FeeRecipient memory primaryFeeRecipient = _feeRecipients[0];

        (ok,) = primaryFeeRecipient.account.call{value: amount}("");
            if (!ok) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

        amounts[0] = amount;

        emit Collected(_ETH, amounts);

        return amounts;
    }
}

contract FeeCollectorProxy {
    constructor(
        address feeCollectorImplementation,
        FeeRecipient[] memory feeRecipients
    ) {
        (bool ok,) = feeCollectorImplementation.delegatecall(
            abi.encodeWithSelector(
                FeeCollectorInterface.initialize.selector, feeRecipients
            )
        );
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place more-minimal proxy runtime code in memory.
        bytes memory runtimeCode = abi.encodePacked(
            bytes11(0x3d3d3d3d363d3d37363d73),
            feeCollectorImplementation,
            bytes13(0x5af43d3d93803e602a57fd5bf3)
        );

        // return more-minimal proxy code to write it to contract runtime.
        assembly {
            return(add(0x20, runtimeCode), 44) // runtime code, length
        }
    }
}