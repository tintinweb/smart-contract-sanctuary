pragma solidity ^0.8.0;

import "./Roles.sol";
import "./ERC721.sol";
import "./ERC1155.sol";
import "./IERC20.sol";
import "./DIERC20.sol";
import "./IBEP20.sol";


/// @notice ERC721 and ERC1155 transfer proxy.
contract TransferProxy is OwnableOperatorRole {

    /// @notice Calls safeTransferFrom for ERC721.
    /// @notice Can be called only by operator.
    function erc721safeTransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.safeTransferFrom(from, to, tokenId);
    }

    /// @notice Calls safeTransferFrom for ERC1155.
    /// @notice Can be called only by operator.
    function erc1155safeTransferFrom(IERC1155 token, address from, address to, uint256 id, uint256 value, bytes calldata data) external onlyOperator {
        token.safeTransferFrom(from, to, id, value, data);
    }
}

/// @notice Transfer proxy for ERC721 tokens whithout safe transfer support.
contract TransferProxyForDeprecated is OwnableOperatorRole {

    /// @notice Calls transferFrom for ERC721.
    /// @notice Can be called only by operator.
    function erc721TransferFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyOperator {
        token.transferFrom(from, to, tokenId);
    }
}

/// @notice ERC20 transfer proxy.
contract ERC20TransferProxy is OwnableOperatorRole {

    /// @notice Calls transferFrom for ERC20 and fails on error.
    /// @notice Can be called only by operator.
    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

contract ERC20TransferProxyForDeprecated is OwnableOperatorRole {
    /// @notice Calls transferFrom for ERC20 and fails on error.
    /// @notice Can be called only by operator.
    function erc20TransferFrom(DIERC20 token, address from, address to, uint256 value) external onlyOperator {
       token.transferFrom(from, to, value);
    }
}

contract BEP20TransferProxy is OwnableOperatorRole {
    /// @notice Calls transferFrom for BEP20 and fails on error.
    /// @notice Can be called only by operator.
    function bep20TransferFrom(IBEP20 token, address from, address to, uint256 value) external onlyOperator {
       token.transferFrom(from, to, value);
    }
}