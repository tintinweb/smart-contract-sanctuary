/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;


interface IReferralFeeReceiver {
    function freezeEpoch(address mooniswap) external;
    function trade(address mooniswap, address[] memory path) external;
}

contract RewardsClaimer {

    struct FeeItem {
        address mooniswap;
        address[] pathToken0;
        address[] pathToken1;
    }

    IReferralFeeReceiver private constant referralFeeReceiver = IReferralFeeReceiver(0x29BC86Ad68bB3BD3d54841a8522e0020C1882C22);

    function unwrapReferralFeeReceiverNoFreeze(FeeItem[] memory items) external {
        for (uint i = 0; i < items.length; i++) {
            try referralFeeReceiver.trade(items[i].mooniswap, items[i].pathToken0) {
            } catch {}
            try referralFeeReceiver.trade(items[i].mooniswap, items[i].pathToken1) {
            } catch {}
        }
    }

    function unwrapReferralFeeReceiver(FeeItem[] memory items) external {
        for (uint i = 0; i < items.length; i++) {
            referralFeeReceiver.freezeEpoch(items[i].mooniswap);
            try referralFeeReceiver.trade(items[i].mooniswap, items[i].pathToken0) {
            } catch {}
            try referralFeeReceiver.trade(items[i].mooniswap, items[i].pathToken1) {
            } catch {}
        }
    }

    function freezeEpoch(address[] memory mooniswaps) external {
        for (uint i = 0; i < mooniswaps.length; i++) {
            referralFeeReceiver.freezeEpoch(mooniswaps[i]);
        }
    }

}