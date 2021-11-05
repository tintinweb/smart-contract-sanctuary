/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

// File: contracts/upgradeability/Proxy.sol

pragma solidity 0.7.5;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        // solhint-disable-previous-line no-complex-fallback
        address _impl = implementation();
        require(_impl != address(0));
        assembly {
            /*
                0x40 is the "free memory slot", meaning a pointer to next slot of empty memory. mload(0x40)
                loads the data in the free memory slot, so `ptr` is a pointer to the next slot of empty
                memory. It's needed because we're going to write the return data of delegatecall to the
                free memory slot.
            */
            let ptr := mload(0x40)
            /*
                `calldatacopy` is copy calldatasize bytes from calldata
                First argument is the destination to which data is copied(ptr)
                Second argument specifies the start position of the copied data.
                    Since calldata is sort of its own unique location in memory,
                    0 doesn't refer to 0 in memory or 0 in storage - it just refers to the zeroth byte of calldata.
                    That's always going to be the zeroth byte of the function selector.
                Third argument, calldatasize, specifies how much data will be copied.
                    calldata is naturally calldatasize bytes long (same thing as msg.data.length)
            */
            calldatacopy(ptr, 0, calldatasize())
            /*
                delegatecall params explained:
                gas: the amount of gas to provide for the call. `gas` is an Opcode that gives
                    us the amount of gas still available to execution

                _impl: address of the contract to delegate to

                ptr: to pass copied data

                calldatasize: loads the size of `bytes memory data`, same as msg.data.length

                0, 0: These are for the `out` and `outsize` params. Because the output could be dynamic,
                        these are set to 0, 0 so the output data will not be written to memory. The output
                        data will be read using `returndatasize` and `returdatacopy` instead.

                result: This will be 0 if the call fails and 1 if it succeeds
            */
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            /*

            */
            /*
                ptr current points to the value stored at 0x40,
                because we assigned it like ptr := mload(0x40).
                Because we use 0x40 as a free memory pointer,
                we want to make sure that the next time we want to allocate memory,
                we aren't overwriting anything important.
                So, by adding ptr and returndatasize,
                we get a memory location beyond the end of the data we will be copying to ptr.
                We place this in at 0x40, and any reads from 0x40 will now read from free memory
            */
            mstore(0x40, add(ptr, returndatasize()))
            /*
                `returndatacopy` is an Opcode that copies the last return data to a slot. `ptr` is the
                    slot it will copy to, 0 means copy from the beginning of the return data, and size is
                    the amount of data to copy.
                `returndatasize` is an Opcode that gives us the size of the last return data. In this case, that is the size of the data returned from delegatecall
            */
            returndatacopy(ptr, 0, returndatasize())

            /*
                if `result` is 0, revert.
                if `result` is 1, return `size` amount of data from `ptr`. This is the data that was
                copied to `ptr` from the delegatecall return data
            */
            switch result
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
    }
}

// File: contracts/upgradeable_contracts/modules/factory/TokenProxy.sol

pragma solidity 0.7.5;

interface IPermittableTokenVersion {
    function version() external pure returns (string memory);
}

/**
 * @title TokenProxy
 * @dev Helps to reduces the size of the deployed bytecode for automatically created tokens, by using a proxy contract.
 */
contract TokenProxy is Proxy {
    // storage layout is copied from PermittableToken.sol
    string internal name;
    string internal symbol;
    uint8 internal decimals;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply;
    mapping(address => mapping(address => uint256)) internal allowed;
    address internal owner;
    bool internal mintingFinished;
    address internal bridgeContractAddr;
    // string public constant version = "1";
    bytes32 internal DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping(address => uint256) internal nonces;
    mapping(address => mapping(address => uint256)) internal expirations;

    /**
     * @dev Creates a non-upgradeable token proxy for PermitableToken.sol, initializes its eternalStorage.
     * @param _tokenImage address of the token image used for mirroring all functions.
     * @param _name token name.
     * @param _symbol token symbol.
     * @param _decimals token decimals.
     * @param _chainId chain id for current network.
     * @param _owner address of the owner for this contract.
     */
    constructor(
        address _tokenImage,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _chainId,
        address _owner
    ) {
        string memory version = IPermittableTokenVersion(_tokenImage).version();

        assembly {
            // EIP 1967
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _tokenImage)
        }
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = _owner; // _owner == HomeOmnibridge/ForeignOmnibridge mediator
        bridgeContractAddr = _owner;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(version)),
                _chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Retrieves the implementation contract address, mirrored token image.
     * @return impl token image address.
     */
    function implementation() public view override returns (address impl) {
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /**
     * @dev Tells the current version of the token proxy interfaces.
     */
    function getTokenProxyInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/upgradeable_contracts/modules/OwnableModule.sol

pragma solidity 0.7.5;

/**
 * @title OwnableModule
 * @dev Common functionality for multi-token extension non-upgradeable module.
 */
contract OwnableModule {
    address public owner;

    /**
     * @dev Initializes this contract.
     * @param _owner address of the owner that is allowed to perform additional actions on the particular module.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * @dev Throws if sender is not the owner of this contract.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Changes the owner of this contract.
     * @param _newOwner address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
}

// File: contracts/upgradeable_contracts/modules/factory/TokenFactory.sol

pragma solidity 0.7.5;

/**
 * @title TokenFactory
 * @dev Factory contract for deployment of new TokenProxy contracts.
 */
contract TokenFactory is OwnableModule {
    address public tokenImage;

    /**
     * @dev Initializes this contract
     * @param _owner of this factory contract.
     * @param _tokenImage address of the token image contract that should be used for creation of new tokens.
     */
    constructor(address _owner, address _tokenImage) OwnableModule(_owner) {
        tokenImage = _tokenImage;
    }

    /**
     * @dev Tells the module interface version that this contract supports.
     * @return major value of the version
     * @return minor value of the version
     * @return patch value of the version
     */
    function getModuleInterfacesVersion()
        external
        pure
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        )
    {
        return (1, 0, 0);
    }

    /**
     * @dev Updates the address of the used token image contract.
     * Only owner can call this method.
     * @param _tokenImage address of the new token image used for further deployments.
     */
    function setTokenImage(address _tokenImage) external onlyOwner {
        require(Address.isContract(_tokenImage));
        tokenImage = _tokenImage;
    }

    /**
     * @dev Deploys a new TokenProxy contract, using saved token image contract as a template.
     * @param _name deployed token name.
     * @param _symbol deployed token symbol.
     * @param _decimals deployed token decimals.
     * @param _chainId chain id of the current environment.
     * @return address of a newly created contract.
     */
    function deploy(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _chainId
    ) external returns (address) {
        return address(new TokenProxy(tokenImage, _name, _symbol, _decimals, _chainId, msg.sender));
    }
}