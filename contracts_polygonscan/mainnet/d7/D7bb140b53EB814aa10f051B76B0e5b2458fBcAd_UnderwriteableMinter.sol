// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IGateway {
    function mint(
        bytes32 _pHash,
        uint256 _amount,
        bytes32 _nHash,
        bytes calldata _sig
    ) external returns (uint256);

    function burn(bytes calldata _to, uint256 _amount)
        external
        returns (uint256);
}

interface IGatewayRegistry {
    function getGatewayBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IGateway);

    function getTokenBySymbol(string calldata _tokenSymbol)
        external
        view
        returns (IERC20);
}

// This is an evolving contract starting with just a simple mint.
// eventually we want to get to this flow:
//    user registers their lockAndMint on this contract
//    underwriter waits for a single confirmation of the deposit
//    underwriter underwrites the mint for a fee (0.3% ?) (maybe set by the user?)
//    underwriter watches the deposit and once it's confirmed, can come here and
//    claim the full amount

contract UnderwriteableMinter {
    IGatewayRegistry public registry;

    constructor(IGatewayRegistry _registry) {
        registry = _registry;
    }

    function temporaryMint(
        // Parameters from users
       address to,
       bytes32 nonce,
       string calldata symbol,
        // Parameters from Darknodes
        uint256        _amount,
        bytes32        _nHash,
        bytes calldata _sig
    ) external {
        bytes32 pHash = keccak256(abi.encode(to, nonce));
        uint256 mintedAmount = registry.getGatewayBySymbol(symbol).mint(pHash, _amount, _nHash, _sig);
        require(registry.getTokenBySymbol(symbol).transfer(to, mintedAmount), 'failed to transfer token');
    }
}