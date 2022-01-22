/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

/// @notice 1-of-1 NFT.
/// adapted from https://gist.github.com/z0r0z/ea0b752aa9537070b0d61f8a74d5c10c
contract SingleNFT {
    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function balanceOf(address) external pure returns (uint256) {
        return 1;
    }

    function ownerOf(uint256) external view returns (address) {
        return owner;
    }

    /// @notice Returns a string from a null terminated bytes array in memory
    /// @dev Works backwards from the end of the byte array so that it only needs one for loop
    function _nullTerminatedString(bytes memory input) public pure returns (string memory) {
        bytes memory output;
        for (uint256 i = input.length; i > 0; i--) {
            // Find the first non null byte
            if (uint8(input[i - 1]) != 0) {
                // Initialize the output byte array
                if (output.length == 0) {
                    output = new bytes(i);
                }

                output[i - 1] = input[i - 1];
            }
        }

        return string(output);
    }

    function name() external pure returns (string memory) {
        uint256 offset = _getImmutableArgsOffset();
        bytes32 nameBytes;
        assembly {
            nameBytes := calldataload(offset)
        }
        return _nullTerminatedString(abi.encodePacked(nameBytes));
    }

    function symbol() external pure returns (string memory) {
        uint256 offset = _getImmutableArgsOffset();
        bytes16 symbolBytes;
        assembly {
            symbolBytes := calldataload(add(offset, 0x20))
        }
        return _nullTerminatedString(abi.encodePacked(symbolBytes));
    }

    function tokenURI(uint256) external pure returns (string memory) {
        uint256 offset = _getImmutableArgsOffset();
        bytes32 uriBytes1;
        bytes16 uriBytes2;
        assembly {
            uriBytes1 := calldataload(add(offset, 0x30))
            uriBytes2 := calldataload(add(offset, 0x50))
        }
        return _nullTerminatedString(abi.encodePacked("ipfs://", uriBytes1, uriBytes2));
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(calldatasize(), add(shr(240, calldataload(sub(calldatasize(), 2))), 2))
        }
    }

    /// @notice Random function name to save gas. Thanks to @_apedev for early access.
    /// https://twitter.com/_apedev/status/1483827473930407936
    /// Also payable to save even more gas
    function mint_d22vi9okr4w(address to) external payable {
        require(owner == address(0), "Already minted");
        owner = to;

        emit Transfer(address(0), to, 0);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
}
library ClonesWithCallData {
    function cloneWithCallDataProvision(
        address implementation,
        bytes memory data
    ) internal returns (address instance) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x43 + extraLength;
            uint256 runSize = creationSize - 11;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (11 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 61 runtime  | PUSH2 runtime (r)     | r 0                     | –
                mstore(
                    ptr,
                    0x3d61000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x02), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0b
                // 80          | DUP1                  | r r 0                   | –
                // 60 creation | PUSH1 creation (c)    | c r r 0                 | –
                // 3d          | RETURNDATASIZE        | 0 c r r 0               | –
                // 39          | CODECOPY              | r 0                     | [0-2d]: runtime code
                // 81          | DUP2                  | 0 c  0                  | [0-2d]: runtime code
                // f3          | RETURN                | 0                       | [0-2d]: runtime code
                mstore(
                    add(ptr, 0x04),
                    0x80600b3d3981f300000000000000000000000000000000000000000000000000
                )

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME
                // -------------------------------------------------------------------------------------------------------------

                // 36          | CALLDATASIZE          | cds                     | –
                // 3d          | RETURNDATASIZE        | 0 cds                   | –
                // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
                // 37          | CALLDATACOPY          | –                       | [0, cds] = calldata
                // 61          | PUSH2 extra           | extra                   | [0, cds] = calldata
                mstore(
                    add(ptr, 0x0b),
                    0x363d3d3761000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x10), shl(240, extraLength))

                // 60 0x38     | PUSH1 0x38            | 0x38 extra              | [0, cds] = calldata // 0x38 (56) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x38 extra          | [0, cds] = calldata
                // 39          | CODECOPY              | _                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0                       | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0                     | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 0 0                   | [0, cds] = calldata
                // 36          | CALLDATASIZE          | cds 0 0 0               | [0, cds] = calldata
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0         | [0, cds] = calldata
                mstore(
                    add(ptr, 0x12),
                    0x603836393d3d3d36610000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0         | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0             | [0, cds] = calldata
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0        | [0, cds] = calldata
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0    | [0, cds] = calldata
                // f4          | DELEGATECALL          | success 0               | [0, cds] = calldata
                // 3d          | RETURNDATASIZE        | rds success 0           | [0, cds] = calldata
                // 82          | DUP3                  | 0 rds success 0         | [0, cds] = calldata
                // 80          | DUP1                  | 0 0 rds success 0       | [0, cds] = calldata
                // 3e          | RETURNDATACOPY        | success 0               | [0, rds] = return data (there might be some irrelevant leftovers in memory [rds, cds] when rds < cds)
                // 90          | SWAP1                 | 0 success               | [0, rds] = return data
                // 3d          | RETURNDATASIZE        | rds 0 success           | [0, rds] = return data
                // 91          | SWAP2                 | success 0 rds           | [0, rds] = return data
                // 60 0x36     | PUSH1 0x36            | 0x36 sucess 0 rds       | [0, rds] = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds] = return data
                // fd          | REVERT                | –                       | [0, rds] = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds] = return data
                // f3          | RETURN                | –                       | [0, rds] = return data

                mstore(
                    add(ptr, 0x34),
                    0x5af43d82803e903d91603657fd5bf30000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x43;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            require(instance != address(0), "create failed");
        }
    }
}

/// @title SingleNFTFactory
/// @author https://twitter.com/devan_non https://github.com/devanonon
/// @notice Factory for deploying ERC721 contracts cheaply
/// @dev Based on https://github.com/ZeframLou/vested-erc20
/// and inspiried by this thread: https://twitter.com/alcuadrado/status/1484333520071708672
contract SingleNFTFactory {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using ClonesWithCallData for address;

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The ERC721 used as the template for all clones created
    SingleNFT public immutable implementation;

    constructor(SingleNFT implementation_) {
        implementation = implementation_;
    }

    /// @notice Creates a SingleNFT contract
    /// @dev Uses a modified minimal proxy contract that stores immutable parameters in code and
    /// passes them in through calldata. See ClonesWithCallData. Make 96 byte token URI
    /// @param _name The name of the ERC721 token (restricted to 32 bytes)
    /// @param _symbol The symbol of the ERC721 token (restricted to 16 bytes)
    /// @param _URI1 First part of the IPFS hash, requires client to split up URI for gas savings
    /// @param _URI2 Second part of the IPFS hash, requires client to split up URI for gas savings
    /// @return erc721 The created SingleNFT contract
    function createERC721(
        bytes32 _name,
        bytes16 _symbol,
        bytes32 _URI1,
        bytes16 _URI2
    ) external returns (SingleNFT erc721) {
        bytes memory ptr = new bytes(96);
        assembly {
            mstore(add(ptr, 0x20), _name)
            mstore(add(ptr, 0x40), _symbol)
            mstore(add(ptr, 0x50), _URI1)
            mstore(add(ptr, 0x70), _URI2)
        }

        erc721 = SingleNFT(
            address(implementation).cloneWithCallDataProvision(ptr)
        );
        // Random function name to save gas, see comments in function for explanation
        erc721.mint_d22vi9okr4w(msg.sender);
    }
}