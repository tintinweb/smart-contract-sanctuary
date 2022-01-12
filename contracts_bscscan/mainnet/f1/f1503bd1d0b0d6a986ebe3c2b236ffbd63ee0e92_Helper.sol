/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org


// SPDX-License-Identifier: BUSL-1.1

// File contracts/lib/Error.sol


pragma solidity 0.8.10;

library Error {
    
    enum Code {
        ValidationError,
        NoBasicSetup,
        UnApprovedConfig,
        InvalidCurrency,
        AlreadySubscribed,
        AlreadyCalledFinishUp,
        AlreadyCreated,
        AlreadyClaimed,
        AlreadyExist,
        InvalidIndex,
        InvalidAmount,
        InvalidAddress,
        InvalidArray,
        InvalidFee,
        InvalidRange,
        CannotInitialize,
        CannotConfigure,
        CannotCreateLp,
        CannotBuyToken,
        CannotRefundExcess,
        CannotReturnFund,
        NoRights,
        IdoNotEndedYet,
        SoftCapNotMet,
        SingleItemRequired,
        ClaimFailed,
        WrongValue,
        NotReady,
        NotEnabled,
        NotWhitelisted,
        ValueExceeded,
        LpNotCreated,
        Aborted,
        SwapExceededMaxSlippage
    }

    
    function str(Code err) internal pure returns (string memory) {
        uint value = uint(err);
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


// File contracts/Helper.sol


pragma solidity 0.8.10;

contract Helper {
    
    // Data1 : Bit 0: Guaranteed | Bit 1 onwards: Amount in Currency
    // Data2 : 120 bits: OverSub Amt, 120 bits: EggBurnAmt, 16 bits: Priority 
    // uint pack1 = (amtBasic << 1) | (isGuaranteed ? 1 : 0);
    // uint pack2 = (amtOverSub) | (eggTotalQty << 120) | (priority << 240);
    
    function pack(bool isGuaranteed, uint amtBasic, uint amtOverSub, uint eggTotalQty, uint priority) external pure returns (uint, uint) {
        require(amtBasic <= type(uint256).max >> 1 && amtOverSub <= type(uint120).max && priority <= type(uint16).max && eggTotalQty <= type(uint120).max, Error.str(Error.Code.ValidationError));
   
        uint pack1 = (amtBasic << 1) | (isGuaranteed ? 1 : 0);
        uint pack2 = (amtOverSub) | (eggTotalQty << 120) | (priority << 240);
        return (pack1, pack2);
    }
         
    function unPack(uint data1, uint data2) external pure returns(bool, uint, uint, uint, uint) {

        bool isGuaranteed = (data1 & 1) > 0 ? true : false;
        uint amtBasic = (data1 >> 1);
        uint amtOverSub = uint120(data2);
        uint eggTotalQty = uint120(data2 >> 120);
        uint priority = uint16(data2 >> 240);
        return (isGuaranteed, amtBasic, amtOverSub, eggTotalQty, priority);
    }

}