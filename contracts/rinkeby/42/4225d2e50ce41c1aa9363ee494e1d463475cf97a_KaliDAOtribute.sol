/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from RariCapital (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // transfer the ETH and store if it succeeded or not
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 36), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 68 because the calldata length is 4 + 32 * 2
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "from" argument
            
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 68), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 100 because the calldata length is 4 + 32 * 3
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) internal pure returns (bool success) {
        assembly {
            // get how many bytes the call returned
            let returnDataSize := returndatasize()

            // if the call reverted:
            if iszero(callStatus) {
                // copy the revert message into memory
                returndatacopy(0, 0, returnDataSize)

                // revert with the same message
                revert(0, returnDataSize)
            }

            switch returnDataSize
            
            case 32 {
                // copy the return data into memory
                returndatacopy(0, 0, returnDataSize)

                // set success to whether it returned true
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // there was no return data
                success := 1
            }
            default {
                // it returned some malformed input
                success := 0
            }
        }
    }
}

/// @notice KaliDAO tribute escrow interface.
interface IKaliDAOtribute {
    enum ProposalType {
        MINT, 
        BURN, 
        CALL, 
        PERIOD, 
        QUORUM, 
        SUPERMAJORITY, 
        TYPE, 
        PAUSE, 
        EXTENSION,
        ESCAPE
    }

    function passed(uint256 proposal) external returns (bool);

    function propose(
        ProposalType proposalType,
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads
    ) external returns (uint256 proposal);

    function cancelProposal(uint256 proposal) external;
}

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        require(status != ENTERED, 'REENTRANCY');

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

/// @notice Tribute contract that escrows ETH or tokens for DAO proposals.
contract KaliDAOtribute is ReentrancyGuard {
    event NewTributeProposal(
        IKaliDAOtribute indexed dao,
        address indexed proposer, 
        uint256 indexed proposal, 
        address asset, 
        uint256 assetAmount
    );

    event TributeProposalCancelled(IKaliDAOtribute indexed dao, uint256 indexed proposal);

    event TributeProposalReleased(IKaliDAOtribute indexed dao, uint256 indexed proposal);

    mapping(IKaliDAOtribute => mapping(uint256 => Tribute)) public tributes;

    struct Tribute {
        IKaliDAOtribute dao;
        address proposer;
        address asset;
        uint256 amount;
    }

    function submitTributeProposal(
        IKaliDAOtribute dao,
        IKaliDAOtribute.ProposalType proposalType, 
        string calldata description,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        address asset, 
        uint256 assetAmount
    ) public payable nonReentrant virtual {
        // escrow tribute
        if (msg.value > 0) {
            asset = address(0);
            assetAmount = msg.value;
        } else {
            SafeTransferLib.safeTransferFrom(asset, msg.sender, address(this), assetAmount);
        }

        uint256 proposal = dao.propose(
            proposalType,
            description,
            accounts,
            amounts,
            payloads
        );

        tributes[dao][proposal] = Tribute({
            dao: dao,
            proposer: msg.sender,
            asset: asset,
            amount: assetAmount
        });

        emit NewTributeProposal(dao, msg.sender, proposal, asset, assetAmount);
    }

    function cancelTributeProposal(IKaliDAOtribute dao, uint256 proposal) public nonReentrant virtual {
        Tribute storage trib = tributes[dao][proposal];

        require(msg.sender == trib.proposer, 'NOT_PROPOSER');

        dao.cancelProposal(proposal);

        // return tribute from escrow
        if (trib.asset == address(0)) {
            SafeTransferLib.safeTransferETH(trib.proposer, trib.amount);
        } else {
            SafeTransferLib.safeTransfer(trib.asset, trib.proposer, trib.amount);
        }

        delete tributes[dao][proposal];

        emit TributeProposalCancelled(dao, proposal);
    }

    function releaseTributeProposal(IKaliDAOtribute dao, uint256 proposal) public nonReentrant virtual {
        Tribute storage trib = tributes[dao][proposal];
        // TO DO - confirm proposal has processed
        require(address(trib.dao) != address(0), 'NOT_PROPOSAL');

        // release tribute from escrow based on proposal outcome
        if (dao.passed(proposal)) {
            if (trib.asset == address(0)) {
                SafeTransferLib.safeTransferETH(address(trib.dao), trib.amount);
            } else {
                SafeTransferLib.safeTransfer(trib.asset, address(trib.dao), trib.amount);
            }
        } else {
            if (trib.asset == address(0)) {
                SafeTransferLib.safeTransferETH(trib.proposer, trib.amount);
            } else {
                SafeTransferLib.safeTransfer(trib.asset, trib.proposer, trib.amount);
            }
        }

        delete tributes[dao][proposal];

        emit TributeProposalReleased(dao, proposal);
    }
}