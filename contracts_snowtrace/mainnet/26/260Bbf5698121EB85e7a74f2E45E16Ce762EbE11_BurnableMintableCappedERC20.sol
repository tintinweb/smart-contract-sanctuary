// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import { ERC20 } from './ERC20.sol';
import { Ownable } from './Ownable.sol';
import { Burner } from './Burner.sol';
import { EternalStorage } from './EternalStorage.sol';

contract BurnableMintableCappedERC20 is ERC20, Ownable {
    uint256 public cap;

    bytes32 private constant PREFIX_TOKEN_FROZEN = keccak256('token-frozen');
    bytes32 private constant KEY_ALL_TOKENS_FROZEN = keccak256('all-tokens-frozen');

    event Frozen(address indexed owner);
    event Unfrozen(address indexed owner);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 capacity
    ) ERC20(name, symbol, decimals) Ownable() {
        cap = capacity;
    }

    function depositAddress(bytes32 salt) public view returns (address) {
        // This would be easier, cheaper, simpler, and result in  globally consistent deposit addresses for any salt (all chains, all tokens).
        // return address(uint160(uint256(keccak256(abi.encodePacked(bytes32(0x000000000000000000000000000000000000000000000000000000000000dead), salt)))));

        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.1/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                owner,
                                salt,
                                keccak256(abi.encodePacked(type(Burner).creationCode, abi.encode(address(this)), salt))
                            )
                        )
                    )
                )
            );
    }

    function mint(address account, uint256 amount) public onlyOwner {
        uint256 capacity = cap;
        require(capacity == 0 || totalSupply + amount <= capacity, 'CAP_EXCEEDED');

        _mint(account, amount);
    }

    function burn(bytes32 salt) public onlyOwner {
        address account = depositAddress(salt);
        _burn(account, balanceOf[account]);
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal view override {
        require(!EternalStorage(owner).getBool(KEY_ALL_TOKENS_FROZEN), 'IS_FROZEN');
        require(!EternalStorage(owner).getBool(keccak256(abi.encodePacked(PREFIX_TOKEN_FROZEN, symbol))), 'IS_FROZEN');
    }
}