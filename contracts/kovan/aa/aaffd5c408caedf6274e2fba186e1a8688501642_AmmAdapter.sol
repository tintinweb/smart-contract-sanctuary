/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

// File: contracts/adapters/IAmmAdapter.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.2;
pragma experimental ABIEncoderV2;

interface IAmmAdapter {
    function protocolName() external pure returns (string memory);

    function nonFungible() external pure returns (bool);

    function expectedWbtcOut(uint256 ethAmt) external view returns (uint256);

    function expectedDiggOut(uint256 wbtcAmt)
        external
        view
        returns (uint256 diggOut, uint256 tradeAmt);

    function buyLp(
        uint256 amt,
        uint256 tradeAmt,
        uint256 minWbtcAmtOut,
        uint256 minDiggAmtOut
    ) external payable;
}

// File: contracts/adapters/AmmAdapter.sol


pragma solidity >=0.7.2;


/**
 * @notice ProtocolAdapter is used to shadow IProtocolAdapter
 * to provide functions that delegatecall's the underlying IProtocolAdapter functions.
 */
library AmmAdapter {
    function delegateBuyLp(
        IAmmAdapter adapter,
        uint256 amt,
        uint256 tradeAmt,
        uint256 minWbtcAmtOut,
        uint256 minDiggAmtOut
    ) external {
        (bool success, bytes memory result) =
            address(adapter).delegatecall(
                abi.encodeWithSignature(
                    "buyLp(uint256,uint256,uint256,uint256)",
                    amt,
                    tradeAmt,
                    minWbtcAmtOut,
                    minDiggAmtOut
                )
            );
        revertWhenFail(success, result);
    }

    function revertWhenFail(bool success, bytes memory returnData)
        private
        pure
    {
        if (success) return;
        revert(getRevertMsg(returnData));
    }

    function getRevertMsg(bytes memory _returnData)
        private
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "ProtocolAdapter: reverted";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}