/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// File: contracts/utils/Initializable.sol

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

// File: contracts/utils/ContextUpgradeable.sol

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

// File: contracts/interfaces/IERC20.sol

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

// File: contracts/interfaces/IGETAccessControl.sol

pragma solidity >=0.5.0 <0.7.0;

interface IGETAccessControl {
    function hasRole(bytes32, address) external view returns (bool);
}

// File: contracts/interfaces/IEconomicsGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IEconomicsGET {
    function editCoreAddresses(
        address newBouncerAddress,
        address newFuelAddress,
        address newDepotAddress
    ) external;

    function getGETPrice() 
    external view returns(uint64);

    function balanceOfRelayer(
        address relayerAddress
    ) external;

    function setPriceGETUSD(
        uint256 newGETPrice)
        external;
    
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) external;

    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns(uint256);

    function fuelBackpackTicketBackfill(
        uint256 nftIndex,
        address relayerAddress,
        uint256 baseGETFee
        ) external returns(bool);


    function calcBackpackValue(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    function calcBackpackGET(
        uint256 baseTicketPrice,
        uint256 percetageCut
    ) external view returns(uint256);

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint256 indexed amountPacked
    );

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

}

// File: contracts/interfaces/IticketFuelDepotGET.sol

pragma solidity >=0.5.0 <0.7.0;

interface IticketFuelDepotGET {

    function getActiveFuel() 
    external view returns(address);

    function calcNeededGET(
         uint256 dollarvalue)
         external view returns(uint256);

    function chargeProtocolTax(
        uint256 nftIndex
    ) external returns(uint256); 

    function fuelBackpack(
        uint256 nftIndex,
        uint256 amountBackpack
    ) external returns(bool);

    function swipeCollected() 
    external returns(uint256);

    function deductNFTTankIndex(
        uint256 nftIndex,
        uint256 amountDeduct
    ) external;

    event BackPackFueled(
        uint256 nftIndexFueled,
        uint256 amountToBackpack
    );

    event statechangeTaxed(
        uint256 nftIndex,
        uint256 GETTaxedAmount
    );

}

// File: contracts/interfaces/IgetNFT_ERC721.sol

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
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function editTokenURI(
        uint256 nftIndex,
        string calldata _newTokenURI
        ) external;
    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);
}

// File: contracts/utils/SafeMathUpgradeable.sol

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

// File: contracts/economicsGET.sol

pragma solidity >=0.5.0 <0.7.0;
pragma experimental ABIEncoderV2;









/** GET Protocol CORE contract
- contract that defines for different ticketeers how much is paid in GET 'gas' per statechange type
- contract/proxy will act as a prepaid bank contract.
- contract will be called using a proxy (upgradable)
- relayers are ticketeers/integrators
- contract is still WIP
 */
contract economicsGET is Initializable, ContextUpgradeable {
    IGETAccessControl public GET_BOUNCER;
    IERC20 public FUELTOKEN;
    IEconomicsGET private ECONOMICS;
    IticketFuelDepotGET private DEPOT;
    IGET_ERC721 private GET_ERC721;

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;

    string public constant contractName = "economicsGET";
    string public constant contractVersion = "1";

    bytes32 private constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 private constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 private constant GET_ADMIN = keccak256("GET_ADMIN");
    bytes32 private constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    function _initialize_economics(
        address address_bouncer,
        address depot_address,
        address erc721_address,
        uint64 price_getusd
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(address_bouncer);
            DEPOT = IticketFuelDepotGET(depot_address);
            GET_ERC721 = IGET_ERC721(erc721_address);
            priceGETUSD = price_getusd;

            FUELTOKEN = IERC20(DEPOT.getActiveFuel());

            freeEventRate = 100;
        }

    // address that will receive all the GET on the contract
    address private emergencyAddress;

    // flat rate in usd that will be used for free events (as these have a base price of 0)
    uint256 private freeEventRate;

    // temporary static value of GET denominated in USD, used for the calculation on how much GET is required on a certain ticket/NFT
    uint256 private priceGETUSD;

    // baseRate is a percentage amount that needs to be provided in GET to fuel a complete event cycle in infinity.
    struct EconomicsConfig { 
        string ticketeerName;
        address ticketeerMasterWallet;
        uint256 baseRate; // 1000 -> 1%
        bool isConfigured;
    }

    // mapping from relayer address to economics configs (that are active)
    mapping(address => EconomicsConfig) private allConfigs;

    // mapping from relayer address to GET/Fuel balance (internal fuel balance)
    mapping(address => uint256) private relayerBalance;
    
    // EVENTS ECONOMICS GET

    event ticketeerCharged(
        address indexed ticketeerRelayer, 
        uint64 indexed chargedFee
    );

    event configChanged(
        address relayerAddress
    );

    event feeToTreasury(
        uint64 feeToTreasury,
        uint64 remainingBalance
    );

    event feeToBurn(
        uint64 feeToTreasury,
        uint64 remainingBalance
    );

    event relayerToppedUp(
        address relayerAddress,
        uint64 amountToppedUp,
        uint64 newBalanceRelayer
    );

    event allFuelPulled(
        address receivedByAddress,
        uint64 amountPulled
    );

    event coreAddressesEdit(
        address newBouncerSet,
        address newFuelSet,
        address newDepotSet,
        address newERC721
    );

    event priceGETChanged(
        uint64 newGETUSDPrice
    );

    event BackpackFilled(
        uint256 indexed nftIndex,
        uint64 indexed amountPacked
    );

    event freeEventSet(
        uint64 newFreeEventRate
    );

    event fuelTokenSynced(
        address fuelTokenAddress
    );


    // MODIFIERS ECONOMICSGET //

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyAdmin() {
        require(
            GET_BOUNCER.hasRole(GET_ADMIN, msg.sender), "ECONOMICS_CALLER_NOT_ADMIN");
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol admin account.
     */
    modifier onlyRelayer() {
        require(
            GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "ECONOMICS_CALLER_NOT_RELAYER");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyGovernance() {
        require(
            GET_BOUNCER.hasRole(GET_GOVERNANCE, msg.sender), "ECONOMICS_CALLER_NOT_GOVERNANCE");
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol governance address.
     */
    modifier onlyFactory() {
        require(
            GET_BOUNCER.hasRole(FACTORY_ROLE, msg.sender), "ECONOMICS_CALLER_NOT_FACTORY");
        _;
    }


    /**
     * @dev Throws if called by a relayer/ticketeer that has not been registered.
     */
    modifier onlyKnownRelayer() {
        require(
            allConfigs[msg.sender].isConfigured == true, "ECONOMICS_RELAYER_NOT_REGISTERED");
        _;
    }

    // CONFIGURATION

    function editCoreAddresses(
        address newBouncerAddress,
        address newDepotAddress,
        address newERC721Address
    ) external onlyAdmin {
        GET_BOUNCER = IGETAccessControl(newBouncerAddress);
        DEPOT = IticketFuelDepotGET(newDepotAddress);
        GET_ERC721 = IGET_ERC721(newERC721Address);

        FUELTOKEN = IERC20(DEPOT.getActiveFuel());

        emit coreAddressesEdit(
            newBouncerAddress,
            address(FUELTOKEN),
            newDepotAddress,
            newERC721Address
        );
    }

    /** set the price used by the contract to price GET in usd
    @param newGETPrice new GETUSD price used to calculate amont of GET needed in the rucksack of an NFT
     */
    function setPriceGETUSD(
        uint64 newGETPrice
    ) public onlyAdmin {
        priceGETUSD = newGETPrice;
        
        emit priceGETChanged(
            newGETPrice
        );
    }

    /**
    @param depotAddress the contract address of the depot contract that needs to be approved for token transfer
    this function allows to let the depot contract move tokens owned by the econimics address.
    @param approvalAmount ERC20 approval amount
    @notice this function will allow the depot contract to move/subtract tokens from the ticketeers that is topped up on the economics contract
     */
    function setContractAllowance(
        address depotAddress,
        uint256 approvalAmount
    ) public onlyAdmin {
        FUELTOKEN.approve(depotAddress, approvalAmount);
    }

    function setFreeEventRate(
        uint64 newFreeEventRate
    ) public onlyAdmin {
        freeEventRate = newFreeEventRate;

        emit freeEventSet(
            newFreeEventRate
        );

    }

    // technically function could be public
    function syncFuelToken() public onlyAdmin {
        FUELTOKEN = IERC20(DEPOT.getActiveFuel());

        emit fuelTokenSynced(
            address(FUELTOKEN)
        );

    }

    /** Example config
    relayerAddress: "0x123", This is the address the ticketeer is identified by.
    timestampStarted: 2311222, Blockheight start of config
    timestampEnded: none, Blockheight end of config
    treasuryL: 0.03 = 3% of the primary value in USD is put in the GET backpack
    isConfigured: bool tracking if a certain relayers GET usage contract are configured
     */


    /**
    @param relayerAddress address the ticketeer sends transcations, used for identifiaction and billing
    @param newTicketeerName the slug/brand name the ticketeer is known by publically, for easy lookup
    @param masterWallet if an relayeraddress is seeded from a 'masterRelayer' this variable is populated, otherwise it will have the burn address
    @param newBaseRate the ratio that will be used to calculate the GET backpack from the basePrice of an getNFT
     */
    function setEconomicsConfig(
        address relayerAddress,
        string memory newTicketeerName,
        address masterWallet,
        uint256 newBaseRate
    ) public onlyAdmin {

        // store config in mapping, this will overwrite previously stored configurations by the same relayerAddress
        allConfigs[relayerAddress] = EconomicsConfig(
            newTicketeerName,
            masterWallet,
            newBaseRate,
            true
        );

        emit configChanged(
            relayerAddress
        );

    }

    // OPERATIONAL FUNCTION GET ECONOMICS 

    /**
    @notice this contract can only be called by baseNFT contract via the primarySale function
    @dev it is not allowed for an getNFT ticket to not use any GET. If an event is free, a extremely low basePrice should be used. The contract handles this edgecase by replacing the basePrice of a free event with a standard rate.
    @notice will only run if a ticketeer has sufficient GET balance - otherwise will fail
    @param nftIndex unique indentifier of getNFT as 'to be minted' by baseNFT contract
    @param relayerAddress address of the ticketeer / integrator that is requesting this NFT mint, note that this is the address of the relayer that has called the baseNFT contract, this function is called by 
    @param basePrice base value in USD of the NFT that is going to be minted
    @dev the edgecase of an free event is handled by adding
     */
    function fuelBackpackTicket(
        uint256 nftIndex,
        address relayerAddress,
        uint256 basePrice
        ) external returns (uint256) 
        { 
            // check if nftIndex exists
            require(GET_ERC721.isNftIndex(nftIndex), "ECONOMICS_INDEX_UNKNOWN");

            // check if relayer is registered in economics contracts
            require(checkIfRelayer(relayerAddress), "ECONOMICS_UNKNOWN_RELAYER");

            if (basePrice == 0) { // free event, replace with freeEventRate in USD
                basePrice = freeEventRate;
            }

            // check if baseprice is valid (non negative, not zero)
            require(basePrice > 0, "ECONOMICS_BASEPRICE_ZERO");

            // calculate amount of GET required for the tickets backpack starting balance
            uint256 _getamount = calcBackpackGET(
                basePrice,
                allConfigs[relayerAddress].baseRate
            );

            // check if calculated amount is higher than zero, statechanges cannot be free
            require(_getamount > 0, "FUEL_ZERO_AMOUNT");

            // check if integrator has sufficient GET to perform fueling action
            require( 
                _getamount < relayerBalance[relayerAddress],
            "GET_BALANCE_INSUFFICIENT"
            );

            // deduct the GET that will be sent to the depot from the ticketeers balance
            relayerBalance[relayerAddress] -= _getamount;

            // call depot contract to transfer the GET and register the NFT in the depot proxy
            require(
                DEPOT.fuelBackpack(
                    nftIndex,
                    _getamount
                ),
                "DEPOT_TRANSFER_FAILED");

            // return to the base contract the amount of GET added to the fuel cotract

            // emit BackpackFilled(
            //     nftIndex,
            //     uint64(_getamount)
            // );

            return _getamount;
    }
   

    // OPERATIONAL FUNCTION GET ECONOMICS 

    /**
    @notice this contract can only be called by baseNFT contract via the primarySale function
    @dev it is not allowed for an getNFT ticket to not use any GET. If an event is free, a extremely low basePrice should be used. The contract handles this edgecase by replacing the basePrice of a free event with a standard rate.
    @notice will only run if a ticketeer has sufficient GET balance - otherwise will fail
    @param nftIndex unique indentifier of getNFT as 'to be minted' by baseNFT contract
    @param relayerAddress address of the ticketeer / integrator that is requesting this NFT mint, note that this is the address of the relayer that has called the baseNFT contract, this function is called by 
    @param baseGETFee base value in USD of the NFT that is going to be minted
    @dev the edgecase of an free event is handled by adding
     */
    function fuelBackpackTicketBackfill(
        uint256 nftIndex,
        address relayerAddress,
        uint256 baseGETFee
        ) external returns (bool) 
        { 
            // check if nftIndex exists
            require(GET_ERC721.isNftIndex(nftIndex), "ECONOMICS_INDEX_UNKNOWN");

            // check if relayer is registered in economics contracts
            require(checkIfRelayer(relayerAddress), "ECONOMICS_UNKNOWN_RELAYER");

            // check if integrator has sufficient GET to perform fueling action
            require( 
                baseGETFee < relayerBalance[relayerAddress],
            "GET_BALANCE_INSUFFICIENT"
            );

            // deduct the GET that will be sent to the depot from the ticketeers balance
            relayerBalance[relayerAddress] -= baseGETFee;

            // call depot contract to transfer the GET and register the NFT in the depot proxy
            require(
                DEPOT.fuelBackpack(
                    nftIndex,
                    baseGETFee
                ),
                "DEPOT_TRANSFER_FAILED");

            // return to the base contract the amount of GET added to the fuel cotract

            // emit BackpackFilled(
            //     nftIndex,
            //     uint64(_getamount)
            // );

            return true;
    }   

    // ticketeer adds GET to their balance
    /** function that tops up the relayer account
    @dev note that relayerAddress does not have to be msg.sender
    @dev so it is possible that an address tops up an account that is not itself
    @param relayerAddress address of the ticketeer / integrator
    @param amountTopped amount of GET that is added to the balance of the integrator
     */
    function topUpGet(
        address relayerAddress,
        uint256 amountTopped
    ) public onlyRelayer returns (uint256){

        require(amountTopped > 0, "ZERO_TOPPED_UP");

        // Check if the relayer is known
        require(checkIfRelayer(relayerAddress) == true, "TOPUP_ECON_RELAYER_UNKNOWN");

        // check if msg.sender has allowed contract to spend/send tokens on the callers behalf
        require(
            FUELTOKEN.allowance(
                relayerAddress, 
                address(this)) >= amountTopped,
            "ALLOWANCE_FAILED_TOPUPGET"
        );

        // tranfer tokens from msg.sender to this contract address (economicsGET proxy)
        require(
            FUELTOKEN.transferFrom(
                relayerAddress, 
                address(this),
                amountTopped),
            "TRANSFER_FAILED_TOPUPGET"
        );

        // add the sent tokens to the balance
        relayerBalance[relayerAddress] += amountTopped;

        emit relayerToppedUp(
            relayerAddress,
            uint64(amountTopped),
            uint64(relayerBalance[relayerAddress])
        );

        return relayerBalance[relayerAddress];
    }


  function withdrawFuel(
      address _token, 
      address _toAddress, 
      uint256 _amount) external onlyAdmin {
    IERC20(_token).transfer(_toAddress, _amount);
  }


    /**
    @param baseTicketPrice base amount in USD of the ticket being minted - scaled x1000
    @param percetageCut percentage scaled - 100 000
     */
    function calcBackpackGET(
        uint256 baseTicketPrice, 
        uint256 percetageCut 
    ) public view returns(uint256) {
        uint256 get_amount = baseTicketPrice.mul(percetageCut).div(priceGETUSD).mul(10000000000000);

        require(get_amount > 0, "CANNOT_BE_LOWER");

        return get_amount; // return in wei
    }


    /** returns the GET balance of a certain integrator address
    @param relayerAddress address of integrator/ticketeer
     */
    function balanceOfRelayer(
        address relayerAddress
    ) public view returns (uint256) 
    {   
        require(checkIfRelayer(relayerAddress), "RELAYER_NOT_REGISTERED");
        return relayerBalance[relayerAddress];
    }

    /** returns the GET balance of the calling address
    @notice should be called by relayer
     */
    function balancerOfCaller() public view
    returns (uint64) 
        {
            return uint64(relayerBalance[msg.sender]);
        }
    
    /**  returns bool if a address is an known relayer
    @param relayerAddress address of integrator/ticketeer
     */
    function checkIfRelayer(
        address relayerAddress
    ) public view returns (bool) 
    {   
        return allConfigs[relayerAddress].isConfigured;
    }

    function getGETPrice() public view returns(uint256) {
        return priceGETUSD;
    }



}