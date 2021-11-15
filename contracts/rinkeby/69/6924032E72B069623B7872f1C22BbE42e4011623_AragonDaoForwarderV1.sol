// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./Utils.sol";
import "./interfaces/IEscrow.sol";

contract AragonDaoForwarderV1 is Utils {
    /**
     * @dev Batched operation which calls approve for payment token and
     * signAndFundMilestone for escrow contract.
     *
     * None of the operations in batch can hard-fail, which is required
     * for successful approval voting in Aragon v1 DAO engine.
     *
     * @param _escrowContract Address of escrow contract.
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _termsCid Contract IPFS cid signed by payee.
     * @param _amountToFund Amount to fund.
     * @param _payeeSignature Signed digest of terms cid by payee.
     * @param _payerSignature Signed digest of terms cid by payer, can be bytes32(0) if caller is payer.
     */
    function approveSignAndFundBatch(
        address _escrowContract,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        uint256 _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        bytes32 _mid = _genMid(_cid, _index);

        (address _token,,,,,,,,,,,) = IEscrow(_escrowContract).milestones(_mid);
        
        (bool _success1,) = _token.delegatecall(
            abi.encodeWithSignature("approve(address,uint256)", _escrowContract, _amountToFund)
        );
        if (!_success1) revert();

        (bool _success2,) = _escrowContract.delegatecall(
            abi.encodeWithSignature(
                "signAndFundMilestone(bytes32,uint16,bytes32,uint256,bytes,bytes)",
                _cid,
                _index,
                _termsCid,
                _amountToFund,
                _payeeSignature,
                _payerSignature
            )
        );
        if (!_success2) revert();
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

contract Utils {
    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function _genMid(bytes32 _cid, uint16 _index) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index));
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface IEscrow {
    function milestones(bytes32 _mid) external returns(
        address,
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint8
    );
}

