/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// File: contracts/AggregatorV3Interface.sol

pragma solidity 0.4.24;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/EIP20Interface.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity 0.4.24;

contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    // total amount of tokens
    uint256 public totalSupply;
    // token decimals
    uint8 public decimals; // maximum is 18 decimals

    /**
     * @param _owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address _owner) public view returns (uint256 balance);

    /**
     * @notice send `_value` token to `_to` from `msg.sender`
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    /**
     * @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    /**
     * @notice `msg.sender` approves `_spender` to spend `_value` tokens
     * @param _spender The address of the account able to transfer the tokens
     * @param _value The amount of tokens to be approved for transfer
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    /**
     * @param _owner The address of the account owning tokens
     * @param _spender The address of the account able to transfer the tokens
     * @return Amount of remaining tokens allowed to spent
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// File: contracts/Chainlink.sol

pragma solidity 0.4.24;



contract ChainLink {
    mapping(address => AggregatorV3Interface) internal priceContractMapping;
    address public admin;
    bool public paused = false;
    address public wethAddressVerified;
    address public wethAddressPublic;
    AggregatorV3Interface public USDETHPriceFeed;
    uint256 constant expScale = 10**18;
    uint8 constant eighteen = 18;

    /**
     * Sets the admin
     * Add assets and set Weth Address using their own functions
     */
    constructor() public {
        admin = msg.sender;
    }

    /**
     * Modifier to restrict functions only by admins
     */
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only the Admin can perform this operation"
        );
        _;
    }

    /**
     * Event declarations for all the operations of this contract
     */
    event assetAdded(
        address indexed assetAddress,
        address indexed priceFeedContract
    );
    event assetRemoved(address indexed assetAddress);
    event adminChanged(address indexed oldAdmin, address indexed newAdmin);
    event verifiedWethAddressSet(address indexed wethAddressVerified);
    event publicWethAddressSet(address indexed wethAddressPublic);
    event contractPausedOrUnpaused(bool currentStatus);

    /**
     * Allows admin to add a new asset for price tracking
     */
    function addAsset(address assetAddress, address priceFeedContract)
        public
        onlyAdmin
    {
        require(
            assetAddress != address(0) && priceFeedContract != address(0),
            "Asset or Price Feed address cannot be 0x00"
        );
        priceContractMapping[assetAddress] = AggregatorV3Interface(
            priceFeedContract
        );
        emit assetAdded(assetAddress, priceFeedContract);
    }

    /**
     * Allows admin to remove an existing asset from price tracking
     */
    function removeAsset(address assetAddress) public onlyAdmin {
        require(
            assetAddress != address(0),
            "Asset or Price Feed address cannot be 0x00"
        );
        priceContractMapping[assetAddress] = AggregatorV3Interface(address(0));
        emit assetRemoved(assetAddress);
    }

    /**
     * Allows admin to change the admin of the contract
     */
    function changeAdmin(address newAdmin) public onlyAdmin {
        require(
            newAdmin != address(0),
            "Asset or Price Feed address cannot be 0x00"
        );
        emit adminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * Allows admin to set the weth address for verified protocol
     */
    function setWethAddressVerified(address _wethAddressVerified) public onlyAdmin {
        require(_wethAddressVerified != address(0), "WETH address cannot be 0x00");
        wethAddressVerified = _wethAddressVerified;
        emit verifiedWethAddressSet(_wethAddressVerified);
    }

    /**
     * Allows admin to set the weth address for public protocol
     */
    function setWethAddressPublic(address _wethAddressPublic) public onlyAdmin {
        require(_wethAddressPublic != address(0), "WETH address cannot be 0x00");
        wethAddressPublic = _wethAddressPublic;
        emit publicWethAddressSet(_wethAddressPublic);
    }

    /**
     * Allows admin to pause and unpause the contract
     */
    function togglePause() public onlyAdmin {
        if (paused) {
            paused = false;
            emit contractPausedOrUnpaused(false);
        } else {
            paused = true;
            emit contractPausedOrUnpaused(true);
        }
    }

    /**
     * Returns the latest price scaled to 1e18 scale
     */
    function getAssetPrice(address asset) public view returns (uint256, uint8) {
        // Return 1 * 10^18 for WETH, otherwise return actual price
        if (!paused) {
            if ( asset == wethAddressVerified || asset == wethAddressPublic ){
                return (expScale, eighteen);
            }
        }
        // Capture the decimals in the ERC20 token
        uint8 assetDecimals = EIP20Interface(asset).decimals();
        if (!paused && priceContractMapping[asset] != address(0)) {
            (
                uint80 roundID,
                int256 price,
                uint256 startedAt,
                uint256 timeStamp,
                uint80 answeredInRound
            ) = priceContractMapping[asset].latestRoundData();
            startedAt; // To avoid compiler warnings for unused local variable
            // If the price data was not refreshed for the past 1 day, prices are considered stale
            // This threshold is the maximum Chainlink uses to update the price feeds
            require(timeStamp > (now - 86500 seconds), "Stale data");
            // If answeredInRound is less than roundID, prices are considered stale
            require(answeredInRound >= roundID, "Stale Data");
            if (price > 0) {
                // Magnify the result based on decimals
                return (uint256(price), assetDecimals);
            } else {
                return (0, assetDecimals);
            }
        } else {
            return (0, assetDecimals);
        }
    }

    function() public payable {
        require(
            msg.sender.send(msg.value),
            "Fallback function initiated but refund failed"
        );
    }
}