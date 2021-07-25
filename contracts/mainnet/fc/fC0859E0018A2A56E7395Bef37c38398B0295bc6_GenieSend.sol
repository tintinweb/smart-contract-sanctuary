// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../../../interfaces/markets/tokens/IERC20.sol";
import "../../../interfaces/markets/tokens/IERC721.sol";
import "../../../interfaces/markets/tokens/IERC1155.sol";
import "../SpecialTransferHelper.sol";

contract GenieSend is SpecialTransferHelper {

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721SendDetails {
        address tokenAddr;
        uint256[] ids;
    }

    struct ERC1155SendDetails {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    function transferERC20(
        ERC20Details memory erc20Details,
        address recipient
    ) public {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            require(
                IERC20(erc20Details.tokenAddrs[i]).transferFrom(
                    _msgSender(),
                    recipient,
                    erc20Details.amounts[i]
                ),
                "transferERC20: transfer failed"
            );
        }
    }

    function transferERC721(
        ERC721SendDetails[] memory erc721Details,
        address recipient
    ) public {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunks
            if (erc721Details[i].tokenAddr == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
                address[] memory _to = new address[](1);
                _to[0] = recipient;
                
                _acceptCryptoPunk(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
                
                _transferCryptoPunk(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
            }
            // accept Mooncat
            else if (erc721Details[i].tokenAddr == 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6) {
                address[] memory _to = new address[](1);
                _to[0] = recipient;

                _acceptMoonCat(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
                
                _transferMoonCat(
                    ERC721Details(
                        erc721Details[i].tokenAddr,
                        _to,
                        erc721Details[i].ids
                    )
                );
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721(erc721Details[i].tokenAddr).transferFrom(
                        msg.sender,
                        recipient,
                        erc721Details[i].ids[j]
                    );
                }
            }
        }
    }

    function transferERC1155(
        ERC1155SendDetails[] memory erc1155Details, 
        address recipient
    ) public {
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                msg.sender,
                recipient,
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }

    function transferNft(
        ERC20Details memory erc20Details,
        ERC721SendDetails[] memory erc721Details,
        ERC1155SendDetails[] memory erc1155Details,
        address recipient
    ) external {
        transferERC20(erc20Details, recipient);
        transferERC721(erc721Details, recipient);
        transferERC1155(erc1155Details, recipient);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC20 {
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../interfaces/punks/ICryptoPunks.sol";
import "../../interfaces/punks/IWrappedPunk.sol";
import "../../interfaces/mooncats/IMoonCatsRescue.sol";

contract SpecialTransferHelper is Context {

    struct ERC721Details {
        address tokenAddr;
        address[] to;
        uint256[] ids;
    }

    function _uintToBytes5(uint256 id)
        internal
        pure
        returns (bytes5 slicedDataBytes5)
    {
        bytes memory _bytes = new bytes(32);
        assembly {
            mstore(add(_bytes, 32), id)
        }

        bytes memory tempBytes;

        assembly {
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
            let lengthmod := and(5, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
            let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
            let end := add(mc, 5)

            for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), 27)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(tempBytes, 5)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        assembly {
            slicedDataBytes5 := mload(add(tempBytes, 32))
        }
    }


    function _acceptMoonCat(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            bytes5 catId = _uintToBytes5(erc721Details.ids[i]);
            address owner = IMoonCatsRescue(erc721Details.tokenAddr).catOwners(catId);
            require(owner == _msgSender(), "_acceptMoonCat: invalid mooncat owner");
            IMoonCatsRescue(erc721Details.tokenAddr).acceptAdoptionOffer(catId);
        }
    }

    function _transferMoonCat(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            IMoonCatsRescue(erc721Details.tokenAddr).giveCat(_uintToBytes5(erc721Details.ids[i]), erc721Details.to[i]);
        }
    }

    function _acceptCryptoPunk(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {    
            address owner = ICryptoPunks(erc721Details.tokenAddr).punkIndexToAddress(erc721Details.ids[i]);
            require(owner == _msgSender(), "_acceptCryptoPunk: invalid punk owner");
            ICryptoPunks(erc721Details.tokenAddr).buyPunk(erc721Details.ids[i]);
        }
    }

    function _transferCryptoPunk(ERC721Details memory erc721Details) internal {
        for (uint256 i = 0; i < erc721Details.ids.length; i++) {
            ICryptoPunks(erc721Details.tokenAddr).transferPunk(erc721Details.to[i], erc721Details.ids[i]);
        }
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface ICryptoPunks {
    function punkIndexToAddress(uint index) external view returns(address owner);
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) external;
    
    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IMoonCatsRescue {
    function acceptAdoptionOffer(bytes5 catId) payable external;
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;
    function giveCat(bytes5 catId, address to) external;
    function catOwners(bytes5 catId) external view returns(address);
    function rescueOrder(uint256 rescueIndex) external view returns(bytes5 catId);
}

{
  "evmVersion": "berlin",
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}