pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "./utils/Initializable.sol";
import "./interfaces/IERC20.sol";

contract IGETAccessControl {
    function hasRole(bytes32, address) public view returns (bool) {}
}


/** GET Protocol CORE contract
- contract that defines for different ticketeers how much is paid in GET 'gas' per statechange type
- contract/proxy will act as a prepaid bank contract.
- contract will be called using a proxy (upgradable)
- relayers are ticketeers/integrators
- contract is still WIP
 */
contract economicsGET is Initializable {
    IGETAccessControl public GET_BOUNCER;
    IERC20 public FUELTOKEN;

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant GET_TEAM_MULTISIG = keccak256("GET_TEAM_MULTISIG");
    bytes32 public constant GET_GOVERNANCE = keccak256("GET_GOVERNANCE");

    address public treasuryAddress;
    address public burnAddress;

    /**
    struct defines how much GET is sent from relayer to economcs per type of contract interaction
    - treasuryFee amount of wei GET that is sent to primary
    [0 setAsideMint, 1 primarySaleMint, 2 secondarySale, 3 Scan, 4 Claim, 6 CreateEvent, 7 ModifyEvent]
    - burnFee amount of wei GET that is sent to burn adres
    [0 setAsideMint, 1 primarySaleMint, 2 secondarySale, 3 Scan, 4 Claim, 6 CreateEvent, 7 ModifyEvent]
    */
    struct EconomicsConfig {
        address relayerAddress;
        uint timestampStarted; // blockheight of when the config was set
        uint timestampEnded; // is 0 if economics confis is still active
        uint256[] treasuryFee;
        uint256[] burnFee;
        bool isConfigured;
    }


    // mapping from relayer address to configs (that are active)
    mapping(address => EconomicsConfig) public allConfigs;

    // storage of old configs
    EconomicsConfig[] public oldConfigs;

    // mapping from relayer address to GET/Fuel balance
    mapping(address => uint256) public relayerBalance;

    // TODO check if it defaults to false for unknwon addresses.
    mapping(address => bool) public relayerRegistry;
    
    event ticketeerCharged(
        address indexed ticketeerRelayer, 
        uint256 indexed chargedFee
    );

    event configChanged(
        address adminAddress,
        address relayerAddress,
        uint timestamp
    );

    event feeToTreasury(
        uint256 feeToTreasury,
        uint256 remainingBalance
    );

    event feeToBurn(
        uint256 feeToTreasury,
        uint256 remainingBalance
    );

    event relayerToppedUp(
        address relayerAddress,
        uint256 amountToppedUp,
        uint timeStamp
    );

    event allFuelPulled(
        address requestAddress,
        address receivedByAddress,
        uint256 amountPulled
    );

    function initialize_economics(
        address _address_bouncer
        ) public initializer {
            GET_BOUNCER = IGETAccessControl(_address_bouncer);
            treasuryAddress = 0x0000000000000000000000000000000000000000;
            burnAddress = 0x0000000000000000000000000000000000000000;
        }
    
    function editCoreAddresses(
        address _address_burn_new,
        address _address_treasury_new
    ) external {
        // check if sender is admin
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "setEconomicsConfig: must have admin role to charge");

        treasuryAddress = _address_treasury_new;
        burnAddress = _address_burn_new;
    }


    function setEconomicsConfig(
        address relayerAddress,
        EconomicsConfig memory EconomicsConfigNew
    ) public {

        // check if sender is admin
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "setEconomicsConfig: must have admin role to charge");

        // check if relayer had a previously set economic config
        // if so, the config that is replaced needs to be stored
        // otherwise it will be lost and this will make tracking usage harder for those analysing
        if (allConfigs[relayerAddress].isConfigured == true) {  // if storage occupied
            // add the old econmic config to storage
            oldConfigs.push(allConfigs[relayerAddress]);
        }

        // store config in mapping
        allConfigs[relayerAddress] = EconomicsConfigNew;

        // set the blockheight of starting block
        allConfigs[relayerAddress].timestampStarted = block.timestamp;
        allConfigs[relayerAddress].isConfigured = true;

        emit configChanged(
            msg.sender,
            relayerAddress,
            block.timestamp
        );

    }

    function balanceOfRelayer(
        address _relayerAddress
    ) public returns (uint256 balanceRelayer) 
    {
        balanceRelayer = relayerBalance[_relayerAddress];
    }

    function balancerOfCaller() public 
    returns (uint256 balanceCaller) 
        {
            balanceCaller = relayerBalance[msg.sender];
        }
    
    // TOD) check if this works / can work
    function checkIfRelayer(
        address _relayerAddress
    ) public returns (bool isRelayer) 
    {
        isRelayer = relayerRegistry[_relayerAddress];
    }
    
    function chargePrimaryMint(
        address _relayerAddress
        ) external returns (bool) { // TODO check probably external
        
        // check if call is coming from protocol contract
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "chargePrimaryMint: must have factory role to charge");

        // how much GET needs to be sent to the treasury
        uint256 _feeT = allConfigs[_relayerAddress].treasuryFee[1];
        // how much GET needs to be sent to the burn
        uint256 _feeB = allConfigs[_relayerAddress].burnFee[1];

        uint256 _balance = relayerBalance[_relayerAddress];

        // check if balance sufficient
        require(
            (_feeT + _feeB) <= _balance,
        "chargePrimaryMint balance low"
        );

        if (_feeT > 0) {
            
            // deduct from balance
            relayerBalance[_relayerAddress] =- _feeT;

            require( // transfer to treasury
            FUELTOKEN.transferFrom(
                address(this),
                treasuryAddress,
                _feeT),
                "chargePrimaryMint _feeT FAIL"
            );

            emit feeToTreasury(
                _feeT,
                relayerBalance[_relayerAddress]
            );
        }

        if (_feeB > 0) {

            // deduct from balance 
            relayerBalance[_relayerAddress] =- _feeB;

            require( // transfer to treasury
            FUELTOKEN.transferFrom(
                address(this),
                burnAddress,
                _feeB),
                "chargePrimaryMint _feeB FAIL"
            );

            emit feeToBurn(
                _feeB,
                relayerBalance[_relayerAddress]
            );

        }

        return true;
    }


    // function chargeSecondaryMint(
            

    //     returns 
    // )

    // ticketeer adds GET 
    /** function that tops up the relayer account
    @dev note that _relayerAddress does not have to be msg.sender
    @dev so it is possible that an address tops up an account that is not itself
    @param _relayerAddress TODO ADD SOME TEXT
    @param amountTopped TODO ADD SOME TEXT
    
     */
    function topUpGet(
        address _relayerAddress,
        uint256 amountTopped
    ) public {

        // TODO maybe add check if msg.sender is real/known/registered

        // check if msg.sender has allowed contract to spend/send tokens
        require(
            FUELTOKEN.allowance(
                msg.sender, 
                address(this)) >= amountTopped,
            "topUpGet - ALLOWANCE FAILED - ALLOW CONTRACT FIRST!"
        );

        // tranfer tokens from msg.sender to contract
        require(
            FUELTOKEN.transferFrom(
                msg.sender, 
                address(this),
                amountTopped),
            "topUpGet - TRANSFERFROM STABLES FAILED"
        );

        // add the sent tokens to the balance
        relayerBalance[_relayerAddress] += amountTopped;

        emit relayerToppedUp(
            _relayerAddress,
            amountTopped,
            block.timestamp
        );
    }

    // emergency function pulling all GET to admin address
    function emergencyPull(address pullToAddress) 
        public {

        // check if sender is admin
        require(GET_BOUNCER.hasRole(RELAYER_ROLE, msg.sender), "emergencyPull: must have admin role to charge");

        uint256 _balanceAll = FUELTOKEN.balanceOf(address(this));

        // add loop that sets all balances to zero
        // set balance to zero

        emit allFuelPulled(
            msg.sender,
            pullToAddress,
            _balanceAll
        );

    }



}

pragma solidity ^0.6.2;

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

pragma solidity ^0.6.2;

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}