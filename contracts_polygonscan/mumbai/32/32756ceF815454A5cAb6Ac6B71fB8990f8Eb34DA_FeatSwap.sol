// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IFeatToken.sol";
import "./interfaces/IFeatArtistToken.sol";
import "./interfaces/IFeatCoreVault.sol";

import "./Libraries/FeatLibrary.sol";

/** @notice The contract used to buy available artist tokens to sales on our plateform */
contract FeatSwap is Initializable {
    /** @notice the factory address containing all artists created on Feat */
    address public featFactory;
    /** @notice the vault proccessing all received funds each months */
    address public coreVault;

    /** @notice the FEAT token */
    address public featToken;

    event ArtistTokensBought(string indexed _artistName, address _buyer, uint _amountArtistToken, uint _amountFeat, uint _timestamp);

    function init(address _featFactory, address _featToken, address _coreVault) external initializer {
        featFactory = _featFactory;
        featToken = _featToken;
        coreVault = _coreVault;
    }

    /**
      * @notice Swap a given amount of FEAT token against the token of the specified artist name
      *         all retrieved FEAT are send to the artist Vault.
      *
      * @param _artistName the name of the artist to buy his token
      * @param _amountFeat the amount of FEAT to spend
      */
    function swapFeatTokenForNewArtistToken(
        string memory _artistName,
        uint _amountFeat
    ) external {
        // retrieve how much artist token the user should receive
        uint amountAT = getArtistTokenForFEAT(_artistName, _amountFeat);
        (address tokenAddress, uint notSalesAmount) = FeatLibrary.getTokensNotSalesFor(featFactory, _artistName);
        address artistVault = FeatLibrary.getArtistVaultByName(featFactory, _artistName);
        // checking if there still enough artist token to buy
        require(amountAT <= notSalesAmount, "FeatSwap: not enough available token");
        // paying to the artist vault
        IFeatToken(featToken).transferFrom(msg.sender, artistVault, _amountFeat);
        // giving new artist token to user
        IFeatArtistToken(tokenAddress).mint(msg.sender, amountAT);
        emit ArtistTokensBought(_artistName, msg.sender, amountAT, _amountFeat, block.timestamp);
    }

    /**
      * @notice retrieve the FEAT cost for a specific amount of an artist token
      *
      * @param _artistName the name of the artist for the wanted token
      * @param _amount the wanted amount of artist token
      *
      * @return the cost in FEAT for buying the '_amount' artist tokens
      */
    function getFEATForArtistToken(string memory _artistName, uint _amount) public view returns(uint) {
        require(_amount > 0, "FeatSwap: amount input is 0");
        address tokenAddress = FeatLibrary.getArtistTokenByName(featFactory, _artistName);
        uint tokenPrice = IFeatArtistToken(tokenAddress).getTokenPrice();
        return (_amount * tokenPrice) / 10 ** 18;
    }

    /**
      * @notice retrieve the amount of an artist token for a specific FEAT amount
      *
      * @param _artistName the name of the artist for the wanted token
      * @param _amount the amount of FEAT to spend
      *
      * @return the amount of artist token for the '_amount' of FEAT
      */
    function getArtistTokenForFEAT(string memory _artistName, uint _amount) public view returns(uint) {
        require(_amount > 0, "FeatSwap: amount input is 0");
        address tokenAddress = FeatLibrary.getArtistTokenByName(featFactory, _artistName);
        uint tokenPrice = IFeatArtistToken(tokenAddress).getTokenPrice();
        return ((_amount * 10 ** 18) / tokenPrice);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatArtistToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function getTokenPrice() external view returns (uint);

    function cap() external view returns (uint256);
    function mint(address _to, uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatCoreVault {    
    function init(address _featToken, address _featVault, address _featFactory, address _swapper) external;
    function getAmounts() external view returns (uint balance);
    function execute() external;
    function updateVolumeFor(string memory _artistName, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IFeatArtistVault.sol";
import "../interfaces/IFeatFactory.sol";
import "../interfaces/IFeatArtistToken.sol";

/** @notice This library is used to help the interaction with the contracts of the FEAT plateform */
library FeatLibrary {

    /** 
      *  -- ADDRESS COMPUTING -- 
      * As we deployed all artists contracts with the CREATE2 schema, we can retrieve the address with 4 parameter:
      *     - A constant (0xff)
      *     - The address of the deployer
      *     - A salt, corresponding to a bytes32 choosed by the user in the create2() call
      *     - The keccak256 hashed bytecode of the deployed contract
      */

    /** 
      * @notice Compute the arist Token address for a given artistName and tokenName
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return the computed address
      */
    function getArtistTokenFor(
        address _featFactory,
        string memory _artistName,
        string memory _tokenName
        ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            hex'ff',
            _featFactory,
            keccak256(abi.encodePacked(_artistName, _tokenName)),
            hex'7c25a6839fd44853a6ad67f67f5560f51874f5b1cbab8e3883ec0f64a8aff326' // Artist Token bytecode hash
        ));
        return address(uint160(uint(hash)));
    }

    /** 
      * @notice Compute the arist Vault address for a given artistName and tokenName
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return the computed address
      */
    function getArtistVaultFor(
        address _featFactory,
        string memory _artistName,
        string memory _tokenName
        ) internal pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(
            hex'ff',
            _featFactory,
            keccak256(abi.encodePacked(_artistName, _tokenName)),
            hex'7039d327dde44f9f9b79d93aecf6b5d64be82a0a15adc732edb025918a58c813' // Artist Vault bytecode hash
        ));
        return address(uint160(uint(hash)));
    }

    function getArtistTokenByName(address _featFactory, string memory _artistName) internal view returns(address tokenAddress) {
        string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(_artistName);
        require(keccak256(abi.encode(tokenName)) != keccak256(abi.encode("")), "FeatLibrary: unknown artist");
        tokenAddress = getArtistTokenFor(_featFactory, _artistName, tokenName);
    }

    function getArtistVaultByName(address _featFactory, string memory _artistName) internal view returns(address vaultAddress) {
        string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(_artistName);
        require(keccak256(abi.encode(tokenName)) != keccak256(abi.encode("")), "FeatLibrary: unknown artist");
        vaultAddress = getArtistVaultFor(_featFactory, _artistName, tokenName);
    }

    /** 
      * @notice Get the balance of FEAT and artist token of an artist Vault
      *
      * @param _artistName the name of the artist
      * @param _tokenName the name of the artist token
      *
      * @return artistToken the balance of artist Token
      * @return featToken the balance of FEAT Token
      */
    function getArtistReserves(
        address _featFactory,
        string calldata _artistName,
        string calldata _tokenName
        ) internal view returns (uint artistToken, uint featToken) {
        address artistVault = getArtistVaultFor(_featFactory, _artistName, _tokenName);
        uint artistTokenAmount = IFeatArtistVault(artistVault).getArtistTokenReserves();
        uint featTokenAmount = IFeatArtistVault(artistVault).getFeatTokenReserves();
        return (artistTokenAmount, featTokenAmount);
    }

    /** 
      * @notice get all the artists created by the factory
      *
      * @param _featFactory the address of the factory
      *
      * @return an array containing all artists name
      */
    function getAllArtists(address _featFactory) internal view returns (string[] memory) {
        return IFeatFactory(_featFactory).getAllArtists();
    }
    
    /**
      * @notice Retrieve the datas of the artist equal to the address sender (if it exist)
      *
      * @return artistAddress the address obtained that correspond to a registered artist
      *         Will return the address-zero if there is no correspondance
      * @return artistName the name of the Artist
      * @return artistTokenName the name of the token ERC-20 of the artist
      * @return artistTokenSymbol the symbol of the token ERC-20 of the artist
      */
    function getArtistForAddress(address _featFactory) internal returns (
        address artistAddress,
        string memory artistName,
        string memory artistTokenName,
        string memory artistTokenSymbol
        ) {
        string[] memory allArtists = getAllArtists(_featFactory);
        for(uint i; i < allArtists.length; i++){
            address vault = getArtistVaultByName(_featFactory, allArtists[i]);
            address artist = IFeatArtistVault(vault).getArtistAddress();
            if(artist == msg.sender){
                artistAddress = artist;
                artistName = allArtists[i];
                artistTokenName = IFeatFactory(_featFactory).getArtistTokenName(artistName);
                artistTokenSymbol = IFeatArtistToken(getArtistTokenByName(_featFactory, artistName)).symbol();
                break;
            }
        }
        // return 0x000.... if no artist have the address of caller
    }

    /** 
      * @notice Get all the artists vault address for each artist in the factory
      * 
      * @param _featFactory the address of the factory
      *
      * @return an array containing all artists vault address
      */
    function retrieveAllVaults(address _featFactory) internal view returns (address[] memory) {
        string[] memory allArtists = getAllArtists(_featFactory);
        require(allArtists.length > 0, "FeatLibrary: no artist in factory");
        address[] memory vaultsArtists = new address[](allArtists.length);
        for(uint i; i < allArtists.length; i++) {
            string memory tokenName = IFeatFactory(_featFactory).getArtistTokenName(allArtists[i]);
            address artistVault = getArtistVaultFor(_featFactory, allArtists[i], tokenName);
            vaultsArtists[i] = artistVault;
        }
        return vaultsArtists;
    } 

    /** @notice retrieve the amount of artist token not sales for a specified artist */
    function getTokensNotSalesFor(address _featFactory, string memory _artistName) internal view returns (address tokenAddress, uint notSalesAmount) {
        tokenAddress = getArtistTokenByName(_featFactory, _artistName);
        uint circulating = IFeatArtistToken(tokenAddress).totalSupply();
        uint max = IFeatArtistToken(tokenAddress).cap();
        notSalesAmount = max - circulating;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatArtistVault {
    function init(address payable _artist, address _featToken) external;

    function getArtistAddress() external returns (address);

    function claimArtistTokens() external;
    function claimFeatTokens() external;
    
    function getArtistTokenReserves() external view returns (uint);
    function getFeatTokenReserves() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeatFactory {
    function createArtist(
        string memory _artistName,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _artistAddress
        ) external returns (
        address artistToken,
        address artistVault
        );

    function getAllArtists() external view returns (string[] memory);

    function getArtistTokenName(string memory _artistName) external view returns (string memory);
    

    function getArtistToken(string calldata _artistName, string calldata _tokenName) external view returns (address);
    function getArtistVault(string calldata _artistName, string calldata _tokenName) external view returns (address);
}