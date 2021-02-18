// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IQredoWalletImplementation.sol";
import "../interfaces/IWalletFactory.sol";
import "../libraries/Create2.sol";

contract WalletFactory is IWalletFactory {

    mapping(address => address) private walletOwner;
    address immutable private _template;

    constructor(address _template_) public {
        require(_template_ != address(0), "WF::constructor:_template_ address cannot be 0");
        _template = _template_;
    }

    function computeFutureWalletAddress(address _walletOwner) external override view returns(address _walletAddress) {
        return Create2.computeAddress(
                    keccak256(abi.encodePacked(_walletOwner)),
                    keccak256(getBytecode())
                );
    }
   
    function createWallet(address _walletOwner) external override returns (address _walletAddress) {
        require(_walletOwner != address(0), "WF::createWallet:owner address cannot be 0");
        require(walletOwner[_walletOwner] == address(0), "WF::createWallet:owner already has wallet");
        address wallet = Create2.deploy(
                0,
                keccak256(abi.encodePacked(_walletOwner)),
                getBytecode()
            );
        IQredoWalletImplementation(wallet).init(_walletOwner);
        walletOwner[_walletOwner] = address(wallet);
        emit WalletCreated(msg.sender, address(wallet), _walletOwner);
        return wallet;
    }

    /**
      * @dev Returns template address of the current {owner};
    */
    function getWalletByOwner(address owner) external override view returns (address _wallet) {
        return walletOwner[owner];
    }

    function verifyWallet(address wallet) external override view returns (bool _validWallet) {
        return walletOwner[IQredoWalletImplementation(wallet).getWalletOwnerAddress()] != address(0);
    }

    /**
      * @dev Returns template address;
    */
    function getTemplate() external override view returns (address template){
        return _template;
    }

    /**
      * @dev EIP-1167 Minimal Proxy Bytecode with included Creation code.
      * More information on EIP-1167 Minimal Proxy and the full bytecode 
      * read more here: 
      * (https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract)
    */
    function getBytecode() private view returns (bytes memory) {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 runtimePrefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(_template);
        bytes15 runtimeSuffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, runtimePrefix, targetBytes, runtimeSuffix);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IQredoWalletImplementation {
    function init(address _walletOwner) external;
    function invoke(bytes memory signature, address _to, uint256 _value, bytes calldata _data) external returns (bytes memory _result);
    function getBalance(address tokenAddress) external view returns(uint256 _balance);
    function getNonce() external view returns(uint256 nonce);
    function getWalletOwnerAddress() external view returns(address _walletOwner);
    
    event Invoked(address indexed sender, address indexed target, uint256 value, uint256 indexed nonce, bytes data);
    event Received(address indexed sender, uint indexed value, bytes data);
    event Fallback(address indexed sender, uint indexed value, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IWalletFactory {
    function computeFutureWalletAddress(address _walletOwner) external view returns(address _walletAddress);
    function createWallet(address owner) external returns (address _walletAddress);
    function getTemplate() external view returns (address template);
    function getWalletByOwner(address owner) external view returns (address _wallet);
    function verifyWallet(address wallet) external  view returns (bool _validWallet);
    
    event WalletCreated(address indexed caller, address indexed wallet, address indexed owner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol";

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
        return address(uint160(uint256(_data)));
    }
}