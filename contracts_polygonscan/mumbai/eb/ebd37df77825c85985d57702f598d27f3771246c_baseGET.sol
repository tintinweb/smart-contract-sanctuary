/**
 *Submitted for verification at polygonscan.com on 2021-09-03
*/

// Sources flattened with hardhat v2.6.2 https://hardhat.org

// File contracts/utils/Initializable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// File contracts/utils/ContextUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File contracts/utils/SafeMathUpgradeable.sol

pragma solidity >=0.5.0 <0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/interfaces/IGETAccessControl.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}


// File contracts/interfaces/IbaseGET.sol

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface IbaseGET {

    enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

    struct TicketData {
        address event_address;
        bytes32[6] ticket_metadata;
        uint256[2] prices_sold;
        TicketStates state;
    }

    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        string calldata ticketURI, 
        bytes32[] calldata ticketMetadata
    ) external returns (uint256 nftIndex);

    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) external returns(uint256);


    function editTokenURIbyAddress(
        address originAddress,
        string calldata _newTokenURI
        ) external;

    function scanNFT(
        address originAddress,
        uint256 orderTime
        ) external returns(bool);

    function invalidateAddressNFT(
        address originAddress,
        uint256 orderTime
        ) external;

    function claimgetNFT(
        address originAddress, 
        address externalAddress) external;
    
    /// VIEW FUNCTIONS

    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) external view returns(bool);

    function returnStruct(
        uint256 nftIndex
    ) external view returns (TicketData memory);

    function ticketMetadata(address originAddress)
      external  
      view 
      returns (
          address _eventAddress,
          bool _scanned,
          bool _valid,
          bytes32[] memory _ticketMetadata,
          bool _setAsideNFT,
          uint256[] memory _prices_sold
      );

}


// File contracts/interfaces/IEventMetadataStorage.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEventMetadataStorage {

    function registerEvent(
      address eventAddress,
      address integratorAccountPublicKeyHash,
      string calldata eventName, 
      string calldata shopUrl,
      string calldata imageUrl,
      bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
      uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
      bool setAside, // -> false = default
      // bytes[] memory extraData
      bytes32[] calldata extraData,
      bool isPrivate
      ) external;

    function getUnderwriterAddress(
        address eventAddress
    ) external view returns(address);

    function doesEventExist(
      address eventAddress
    ) external view returns(bool);

    event newEventRegistered(
      address indexed eventAddress, 
      string indexed eventName,
      uint256 indexed timestamp
    );

    event UnderWriterSet(
      address eventAddress,
      address underWriterAddress,
      address requester
    );

}


// File contracts/interfaces/IEventFinancing.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEventFinancing {

}


// File contracts/interfaces/INFT_ERC721.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGET_ERC721 {
    
    function mintERC721(
        address destinationAddress,
        string calldata ticketURI
    ) external returns(uint256);
    
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
        ) external view returns(uint256);
    
    function balanceOf(
        address owner
        ) external view returns(uint256);
    
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
        ) external;
    
    function ownerOf(
        uint256 tokenId) external view returns (address owner);
    
    function editTokenURI(
        uint256 nftIndex,
        string calldata _newTokenURI
        ) external;
    
    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);
}


// File contracts/interfaces/IEconomicsGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEconomicsGET {

    struct dynamicRateStruct {
        uint16 mint_rate; // 1
        uint16 resell_rate; // 2
        uint16 claim_rate; // 3
        uint16 crowd_rate; // 4
        uint16 scalper_fee; // 5
        uint16 extra_rate; // 6
        uint16 share_rate; // 7
        uint16 edit_rate; // 8
        uint16 max_base_price; // 9
        uint16 min_base_price; // 10
        uint16 reserve_slot_1; // 11
        uint16 reserve_slot_2; // 12
    }

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns (uint256);  

    function emptyBackpackBasic(
        uint256 nftIndex
    ) external returns (uint256);

    function chargeTaxRateBasic(
        uint256 nftIndex
    ) external;

    function swipeDepotBalance() external returns(uint256);

    function emergencyWithdrawFuel() external;


    /// VIEW FUNCTIONS

    function balanceOfRelayer(
        address relayerAddress
    ) external view returns (uint256);

    function valueRelayerSilo(
        address _relayerAddress
    ) external view returns(uint256);

    function estimateNFTMints(
        address _relayerAddress
    ) external view returns(uint256);

}


// File contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0 <0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IfoundationContract.sol

pragma solidity >=0.5.0 <0.7.0;

interface IfoundationContract {

    // TODO add interface for the foundation base contract 


}


// File contracts/interfaces/IGETProtocolConfiguration.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETProtocolConfiguration {

    // function setAccessControlGETProx(
    //     address _access_control_proxy) external onlyOwner;

    function GETgovernanceAddress() external view returns(address);
    function feeCollectorAddress() external view returns(address);
    function treasuryDAOAddress() external view returns(address);
    function stakingContractAddress() external view returns(address);
    function emergencyAddress() external view returns(address);

    function AccessControlGET_proxy_address() external view returns(address);
    function baseGETNFT_proxy_address() external view returns(address);
    function getNFT_ERC721_proxy_address() external view returns(address);
    function eventMetadataStorage_proxy_address() external view returns(address);
    function getEventFinancing_proxy_address() external view returns(address);
    function economicsGET_proxy_address() external view returns(address);
    function fueltoken_get_address() external view returns(address);

    function basicTaxRate() external view returns(uint256);
    
    function priceGETUSD() external view returns(uint256);

    function setAllContractsStorageProxies(
        address _access_control_proxy,
        address _base_proxy,
        address _erc721_proxy,
        address _metadata_proxy,
        address _financing_proxy,
        address _economics_proxy
    ) external;

}


// File contracts/foundationContract.sol

pragma solidity >=0.5.0 <0.7.0;








contract foundationContract is Initializable, ContextUpgradeable {
    
    // TODO is this possible in a single line
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;
    using SafeMathUpgradeable for uint16;

    bytes32 internal GET_GOVERNANCE;
    bytes32 internal GET_ADMIN; 
    bytes32 internal RELAYER_ROLE;
    bytes32 internal FACTORY_ROLE;

    IGETProtocolConfiguration public CONFIGURATION;

    IGETAccessControl internal GET_BOUNCER;
    IbaseGET internal BASE;
    IGET_ERC721 internal GET_ERC721;
    IEventMetadataStorage internal METADATA;
    IEventFinancing internal FINANCE;
    IEconomicsGET internal ECONOMICS;
    IERC20 internal FUELTOKEN;

    function __foundationContract_init_unchained(
        address configuration_address
    ) internal initializer {
        CONFIGURATION = IGETProtocolConfiguration(configuration_address);
        GET_GOVERNANCE = 0x8f56080c0d86264195811790c4a1d310776ff2c3a02bf8a3c20af9f01a045218;
        GET_ADMIN = 0xc78a2ac81d1427bc228e4daa9ddf3163091b3dfd17f74bdd75ef0b9166a23a7e;
        RELAYER_ROLE = 0xe2b7fb3b832174769106daebcfd6d1970523240dda11281102db9363b83b0dc4;
        FACTORY_ROLE = 0xc78a2ac81d1427bc228e4daa9ddf3163091b3dfd17f74bdd75ef0b9166a23a7e;
    }

    function __foundationContract_init(
        address configuration_address
    ) public initializer {
        __Context_init();
        __foundationContract_init_unchained(
            configuration_address
        );
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(GET_BOUNCER.hasRole(GET_ADMIN, msg.sender),
        "NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender),
        "NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender),
            "NOT_GOVERNANCE"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender),
        "NOT_FACTORY");
        _;
    }

    /**
    @dev calling this function will sync the global contract variables and instantiations with the DAO controlled configuration contract
    @notice can only be called by configurationGET contract
    TODO we could make this virtual, and then override the function in the contracts that inherit the foundation to instantiate the contracts that are relevant that particular contract
     */
    function syncConfiguration() external returns(bool) {

        // check if caller is configurationGETProxyAddress 
        require(msg.sender == address(CONFIGURATION), "CALLER_NOT_CONFIG");

        GET_BOUNCER = IGETAccessControl(
            CONFIGURATION.AccessControlGET_proxy_address()
        );

        BASE = IbaseGET(
            CONFIGURATION.baseGETNFT_proxy_address()
        );

        GET_ERC721 = IGET_ERC721(
            CONFIGURATION.getNFT_ERC721_proxy_address()
        );

        METADATA = IEventMetadataStorage(
            CONFIGURATION.eventMetadataStorage_proxy_address()
        );    

        FINANCE = IEventFinancing(
            CONFIGURATION.getNFT_ERC721_proxy_address()
        );            

        ECONOMICS = IEconomicsGET(
            CONFIGURATION.economicsGET_proxy_address()
        );        

        FUELTOKEN = IERC20(
            CONFIGURATION.economicsGET_proxy_address()
        );        
    
        return true;
    }


    // /**
    //  * @dev Throws if called by a relayer/ticketeer that has not been registered.
    //  */
    // modifier onlyKnownRelayer() {
    //     require(allConfigs[msg.sender].isConfigured == true,
    //     "NOT_REGISTERED");
    //     _;
    // }

    // // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    // // also added to recover any transfer mistakes by anyone (so mistakingly sending an ERC20 to a proxy or even the implementation contract)
    // function recoverERC20(address tokenAddress, uint256 tokenAmount)
    //     external
    //     onlyOwner
    // {
    //     require(
    //         tokenAddress != address(stakingToken),
    //         "Cannot withdraw the staking token"
    //     );
    //     IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
    //     emit Recovered(tokenAddress, tokenAmount);
    // }

    // // TODO function that transfers all ETH or native token sent to the proxy and or implementaiton contract
    // function withdrawMoney() public onlyOwner {
    //     address payable to = payable(msg.sender);
    //     to.transfer(getBalance());
    // }
}


// File contracts/baseGET.sol

pragma solidity >=0.5.0 <0.7.0;

contract baseGET is foundationContract {

    function __baseGETNFT_init_unchained() internal initializer {}

    function __baseGETNFT_init(
        address configuration_address
    ) public initializer {
        __Context_init();
        __foundationContract_init(
            configuration_address);
        __baseGETNFT_init_unchained();
    }

    // UNSCANNED is the state the ticket assumes upon creation before it is ever scanned. Only UNSCANNED mytickets can be resold.
    // SCANNED is the state the ticket assumes when scanned; this can happen infinite number of times.
    // CLAIMABLE is the state the ticket can assume that allows it to be claimed, this happens after the finalScan
    // INVALIDATED is the state the ticket can assume when the ticket is flagged as invalid by the ticket issuer.
    enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

    struct TicketData {
        address event_address;
        bytes32[] ticket_metadata;
        uint32[2] sale_prices;
        TicketStates state;
    }

    mapping (uint256 => TicketData) private _ticket_data;

    event primarySaleMint(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event secondarySale(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event ticketInvalidated(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    ); 

    event nftClaimed(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event nftMinted(
        uint256 indexed nftIndex,
        address indexed destinationAddress
    );

    event nftTokenURIEdited(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        string netTokenURI
    );

    event illegalScan(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event ticketScanned(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

    event NFTCheckedIn(
        uint256 indexed nftIndex,
        uint64 indexed getUsed,
        uint64 indexed orderTime
    );

   // OPERATIONAL TICKETING FUNCTIONS //

    /**
    * @dev primary sale function, transfers or mints NFT to EOA of a primary market ticket buyer
    * @param destinationAddress EOA address of the ticket buyer (GETcustody)
    * @param eventAddress EOA address of the event - primary key assinged by GETcustody
    * @param primaryPrice price paid by primary ticket buyer in the local/event currenct
    * @param basePrice price as charged to the ticketeer in USD 
    * @param orderTime timestamp the statechange was triggered in the system of the integrator
    * @param ticketURI string stored in metadata of NFT
    * @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function primarySale(
        address destinationAddress, 
        address eventAddress, 
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        string memory ticketURI, 
        bytes32[] memory ticketMetadata
    ) public onlyRelayer returns (uint256 nftIndexP) {

        // Event NFT is created for is not colleterized, getNFT minted to user 
        nftIndexP = _mintGETNFT( 
            destinationAddress,
            eventAddress,
            primaryPrice,
            ticketURI,
            ticketMetadata
        );

        uint256 _fueled = ECONOMICS.fuelBackpackTicket(nftIndexP, msg.sender, basePrice);

        emit primarySaleMint(
            nftIndexP,
            uint64(_fueled),
            uint64(orderTime)
        );

        return nftIndexP;
    }

    /** transfers a getNFT from EOA to EOA
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param destinationAddress EOA address of the event that will receive getNFT for colleterization
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    @param secondaryPrice price paid for the getNFT on the secondary market
     */
    function secondaryTransfer(
        address originAddress, 
        address destinationAddress,
        uint256 orderTime,
        uint256 secondaryPrice) public onlyRelayer returns(uint256) {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        // require(isNftIndex(nftIndex), "INDEX_NOT_FOUND");
        require(nftIndex > 0, "NO_INDEX");

        // require(isNFTSellable(nftIndex, originAddress), "RE/SALE_ERROR");

        _ticket_data[nftIndex].sale_prices[1] = uint32(secondaryPrice);
        
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            destinationAddress, 
            nftIndex
        );

        emit secondarySale(
            nftIndex,
            0,
            uint64(orderTime)
        );
        
        return nftIndex;
    
    }

    /** scans a getNFT by validates it, but DOES NOT MAKE NFT CLAIMABLE
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function checkIn(
        address originAddress, 
        uint256 orderTime
        ) public onlyRelayer {

        _checkIn(originAddress, orderTime);

    }

    /** internal function for check ins, emits
    @param originAddress address that own the NFT
    @param orderTime timestamp of engine of request
     */
    function _checkIn(
        address originAddress,
        uint256 orderTime
    ) internal {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(nftIndex > 0, "NO_INDEX");

        require((_ticket_data[nftIndex].state != TicketStates.INVALIDATED) || (_ticket_data[nftIndex].state != TicketStates.CLAIMABLE), "CHECKIN_ERROR");

        _ticket_data[nftIndex].state = TicketStates.SCANNED;

        emit NFTCheckedIn(
            nftIndex,
            0,
            uint64(orderTime)
        );
    }

    /** finalScan / permanent scan function
    @param originAddress address that own the NFT
    @param orderTime timestamp of engine of request
    @notice this function makes the nftIndex claimable
     */
    function scanNFT(
        address originAddress,
        uint256 orderTime
    ) public onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        require(nftIndex > 0, "NO_INDEX");

        // TicketData storage _ticket = _ticket_data[nftIndex]; TODO uncommented for gas reason

        require(_ticket_data[nftIndex].state != TicketStates.INVALIDATED, "SCAN_INVALIDATED");

        if(_ticket_data[nftIndex].state == TicketStates.CLAIMABLE) {
            // nft has been scanned before
            emit illegalScan(
                nftIndex,
                0,
                uint64(orderTime)
            );
        } else { // nft has never been scanned
            
            // transfer all the GET in the backpack to the feeCollector
            uint256 _fueled = ECONOMICS.emptyBackpackBasic(nftIndex);

            _ticket_data[nftIndex].state = TicketStates.CLAIMABLE;

            emit ticketScanned(
                nftIndex,
                uint64(_fueled),
                uint64(orderTime)
            );
        }

    }

    /** invalidates a getNFT, making it unusable and untransferrable
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
    */
    function invalidateAddressNFT(
        address originAddress, 
        uint256 orderTime) public onlyRelayer {
        
        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

        // require(isNftIndex(nftIndex), "INDEX_NOT_FOUND");
        require(nftIndex > 0, "NO_INDEX");

        require(_ticket_data[nftIndex].state != TicketStates.INVALIDATED, "DOUBLE_INVALIDATION");
        
        _ticket_data[nftIndex].state = TicketStates.INVALIDATED;

        emit ticketInvalidated(
            nftIndex, 
            0,
            uint64(orderTime)
        );
    } 

    /** Claims a scanned and valid NFT to an external EOA address
    @param originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param externalAddress EOA address of user that is claiming the gtNFT
    @param orderTime timestamp the statechange was triggered in the system of the integrator
     */
    function claimgetNFT(
        address originAddress, 
        address externalAddress,
        uint256 orderTime) public onlyRelayer {

        uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0); // fetch the index of the NFT

        // require(isNftIndex(nftIndex), "INDEX_NOT_FOUND");
        require(nftIndex > 0, "NO_INDEX");

        require(isNFTClaimable(nftIndex, originAddress), "CLAIM_ERROR");

        /// Transfer the NFT to destinationAddress
        GET_ERC721.relayerTransferFrom(
            originAddress, 
            externalAddress, 
            nftIndex
        );

        emit nftClaimed(
            nftIndex,
            0,
            uint64(orderTime)
        );

    }

    /**
    @dev internal getNFT minting function 
    @notice this function can be called internally, as well as externally (in case of event financing)
    @notice should only mint to EOA addresses managed by GETCustody
    @param destinationAddress EOA address that is the 'future owner' of a getNFT
    @param eventAddress EOA address of the event - primary key assinged by GETcustody
    @param issuePrice the price the getNFT will be offered or collaterized at
    @param ticketURI string stored in metadata of NFT
    @param ticketMetadata additional meta data about a sale or ticket (like seating, notes, or reslae rukes) stored in unstructed list 
    */
    function _mintGETNFT(
        address destinationAddress, 
        address eventAddress, 
        uint256 issuePrice,
        string memory ticketURI,
        bytes32[] memory ticketMetadata
        ) internal returns(uint256 nftIndexM) {

        nftIndexM = GET_ERC721.mintERC721(
            destinationAddress,
            ticketURI
        );

        // require(isNftIndex(nftIndex), "INDEX_NOT_FOUND");
        require(nftIndexM > 0, "NO_INDEX");


        TicketData storage tdata = _ticket_data[nftIndexM];
        tdata.ticket_metadata = ticketMetadata;
        tdata.event_address = eventAddress;
        tdata.sale_prices[0] = uint32(issuePrice);
        tdata.state = TicketStates.UNSCANNED;

        return nftIndexM;
    }


    /** edits URI of getNFT
    @notice select getNFT by address TODO POSSIBLY REMOVE/RETIRE
    @param originAddress originAddress EOA address of GETCustody that is the known owner of the getNFT
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyAddress(
        address originAddress,
        string memory newTokenURI
        ) public onlyRelayer {
            
            uint256 nftIndex = GET_ERC721.tokenOfOwnerByIndex(originAddress, 0);

            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                0,
                newTokenURI
            );
        }

    /** edits metadataURI stored in the getNFT
    @dev unused function can be commented
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param newTokenURI new string stored in metadata of the getNFT
    */
    function editTokenURIbyIndex(
        uint256 nftIndex,
        string memory newTokenURI
        ) public onlyRelayer {
            
            GET_ERC721.editTokenURI(nftIndex, newTokenURI);
            
            emit nftTokenURIEdited(
                nftIndex,
                0,
                newTokenURI
            );
        }

    // VIEW FUNCTIONS 

    /** Returns if an getNFT can be claimed by an external EOA
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTClaimable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].state == TicketStates.CLAIMABLE) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns if an getNFT can be resold
    @param nftIndex uint256 unique identifier of getNFT assigned by contract at mint
    @param ownerAddress EOA address of GETCustody that is the known owner of the getNFT
    */
    function isNFTSellable(
        uint256 nftIndex,
        address ownerAddress
    ) public view returns(bool) {

        if (_ticket_data[nftIndex].state == TicketStates.UNSCANNED) {
            if (GET_ERC721.ownerOf(nftIndex) == ownerAddress) {
                return true;
            }
        } else {
            return false;
        }
    }

    /** Returns getNFT metadata by current owner (EOA address)
    @param ownerAddress EOA address of the address that currently owns the getNFT
    @dev this function assumes the NFT is still owned by an address controlled by GETCustody. 
    TODO change this function as to work with the new TicketData struct
     */
    function ticketMetadataAddress(
        address ownerAddress)
      public virtual view returns (
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _sale_prices,
          TicketStates _state
      )
      {
          
          // could have a `require` clause here
          TicketData storage tdata = _ticket_data[GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0)];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _sale_prices = tdata.sale_prices;
          _state = tdata.state;
      }

    /**
    @param nftIndex index of the nft
    TODO change this function as to work with the new TicketData struct
     */ 
    function ticketMetadataIndex(
        uint256 nftIndex
    ) public view returns(
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _sale_prices,
          TicketStates _state
    ) 
    {
          TicketData storage tdata = _ticket_data[nftIndex];
          _eventAddress = tdata.event_address;
          _ticketMetadata = tdata.ticket_metadata;
          _sale_prices = tdata.sale_prices;
          _state = tdata.state;
    }

    /**
    @param ownerAddress address of the owner of the getNFT
    @notice the ownerAddress of an active ticket is generally held by GETCustody
     */
    function addressToIndex(
        address ownerAddress
    ) public virtual view returns(uint256)
    {
        return GET_ERC721.tokenOfOwnerByIndex(ownerAddress, 0);
    }

    /** returns the metadata struct of the ticket (base data)
    @param nftIndex unique indentifier of getNFT
     */
    function returnStructTicket(
        uint256 nftIndex
    ) public view returns (TicketData memory)
    {
        return _ticket_data[nftIndex];
    }

}