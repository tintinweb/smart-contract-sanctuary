/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
   @title OwnableFlavors
   @author iceCreamMan
 * @dev Holds all the addresses and authorized roles for the flavors ecosystem
 *       Addresses are updatable by the iceCreamMan or owner. Additional required functions
 *       for certain address updates are executed from this contract to the respectful
 *       contract such as flavor changes
 *
 *          Upgraded to 0.8.9
 *          Adds 'iceCreamMan' role
 *          Adds 'authorized' roles
 *          Adds 'onlyIceCreamMan' modifier
 *          Adds 'onlyAdmin' modifier
 *          Adds 'onlyAuthorized' modifier
 *          Adds 'onlyPendingIceCreamMan' modifier
 *          Adds 'onlyPendingOwner' modifier
 *
 *          Tiers of Roles that can be accessed from from any flavors contract
 *          to apply privledged access to certain functions
 *
 *          iceCreamMan: The developer account with full access to any function that
 *                requires it. role cannot be revoked and must be transferred with
 *                transfer confirmation. role cannot be renounced
 *          owner:  All the same access as the iceCreamMan except for functions that
 *                could break the contract if used without proper knowledge of how they
 *                operate. role cannot be revoked and must be transferred with
 *                transfer confirmation. Role can be renounced, at which point is transferred
 *                to iceCreamMan.
 *          admin: addresses can be added or removed to this list by iceCreamMan or Owner.
 *                Admin has power over lower roles but not iceCreamMan or Owner
 *          authorized: addresses can be added or removed to this list by admin or higher
 *                authorized has power over lower roles but not admin, iceCreamMan or Owner
 *          teamMember: addresses can be added or removed to this list by authorized or higher
 *
 *          Replaces constructor with initialize():
 *              - To be called immediatly upon deployment. This is
 *                required for deployment to a deterministic address,
 *                as no msg.sender may be used in the constructor
 *          Adds a 2 step process for major role transfers:
 *              - When the 'owner' or 'iceCreamMan' roles are transferred to a
 *                new address,the new address must claim the roll
 *                before the transfer is finalized. This will prevent
 *                a non-reversable mistake of entering the wrong address
 *          Stand-Alone: To reduce contract code size, seperate functionality,
 *                and not require keeping multiple inherited Ownable contracts
 *                in sync with one another this contract has been redesigned
 *                to be used as an externally referrenced & upgradable contract.
 *                This contract is to be deployed and immediatly initialized
 *                by the main token contract, then this contract initializes all others
 *      Modifiers: creates modifiers:
 *            onlyIceCreamMan - may only be called by iceCreamMan
 *            onlyOwner - may only be called by owner
 *            onlyAdmin - may only be called by iceCreamMan or owner
 *            onlyAuthorized - may only be called by iceCreamMan or owner
 *            onlyPendingOwner - may only be called by pending_owner
 *            onlyPendingIceCreamMan - may only be called by pending_iceCreamMan
 *            authorized - may only be called by accounts on the authorized list
 *            NOTE As modifiers are not transferable through interfaces the
 *                  modifiers used in this contract are to protect external state
 *                  changing calls. To apply the roles in external contracts the
 *                  modifiers must be restated and set to reference this contract's values.
 *
 *
 *  -theIceCreamMan
 */


// libraries

/* ---------- START OF IMPORT Address.sol ---------- */





library Address {

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others,`isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived,but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052,0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code,i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`,forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes,possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`,making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`,care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient,uint256 amount/*,uint256 gas*/) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls,avoid-call-value
        (bool success,) = recipient.call{ value: amount/* ,gas: gas*/}("");
        require(success,"Address: unable to send value");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason,it is bubbled up by this
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
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
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
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`],but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }

    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
/* ------------ END OF IMPORT Address.sol ---------- */


// extensions

/* ---------- START OF IMPORT Context.sol ---------- */




abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    
    // @dev Returns information about the value of the transaction.
    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;// silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/* ------------ END OF IMPORT Context.sol ---------- */


// interfaces

/* ---------- START OF IMPORT ICreamery.sol ---------- */




interface ICreamery {
    function initialize(address ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;

    // onlyFlavorsToken
    function launch_OFT() external;
    function weSentYouSomething_OFT(uint256 amount) external;

    // onlyAdmin
    function updateOwnable_OAD(address new_ownableFlavors) external;

    function deposit(string memory note) external payable;
    // authorized
    function spiltMilk_OAUTH(uint256 value) external;
}
/* ------------ END OF IMPORT ICreamery.sol ---------- */


/* ---------- START OF IMPORT IFlavorDripper.sol ---------- */




interface IFlavorDripper {

    // public
    function claimDividend() external;
    //function deposit(string memory note) external payable;

    // onlyCustomBuyer
    function customBuyerContractCallback_OCB(uint256 balanceBefore) external;

    // onlyAdmin
    function setFlavorDistCriteria_OAD(uint256 minPeriod,uint256 minDistribution) external;
    function updateOwnableFlavors_OAD(address new_ownableFlavors) external;

    // onlyFlavorsToken
    function process_OFT() external;
    function setShare_OFT(address shareholder,uint256 amount) external;
    function deposit_OFT(uint256 valueSent, string memory note) external;

    // onlyOwnable
    function updateFlavorsToken_OO(address new_flavorsToken) external;
    function updateFlavor_OO(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract
    ) external;
    function updateRouter_OO(address new_router) external;

    // onlyInitializer
    function initialize(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
    ) external;
}
/* ------------ END OF IMPORT IFlavorDripper.sol ---------- */


/* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {

  function isLiquidityPool(address holder) external returns (bool);

  function presaleClaim(address presaleContract, uint256 amount) external returns (bool);
  function spiltMilk_OC(uint256 amount) external;
  function creamAndFreeze_OAUTH() external payable;

  //onlyBridge
  function setBalance_OB(address holder, uint256 amount) external returns (bool);
  function addBalance_OB(address holder, uint256 amount) external returns (bool);
  function subBalance_OB(address holder, uint256 amount) external returns (bool);

  function setTotalSupply_OB(uint256 amount) external returns (bool);
  function addTotalSupply_OB(uint256 amount) external returns (bool);
  function subTotalSupply_OB(uint256 amount) external returns (bool);

  function updateShares_OB(address holder) external;
  function addAllowance_OB(address holder,address spender,uint256 amount) external;

  //onlyOwnableFlavors
  function updateBridge_OO(address new_bridge) external;
  function updateRouter_OO(address new_router) external returns (address);
  function updateCreamery_OO(address new_creamery) external;
  function updateDripper0_OO(address new_dripper0) external;
  function updateDripper1_OO(address new_dripper1) external;
  function updateIceCreamMan_OO(address new_iceCreamMan) external;

  //function updateBridge_OAD(address new_bridge,bool bridgePaused) external;
  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function symbol() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function getFees() external view returns (
      uint16 fee_flavor0,
      uint16 fee_flavor1,
      uint16 fee_creamery,
      uint16 fee_icm,
      uint16 fee_totalBuy,
      uint16 fee_totalSell,
      uint16 FEE_DENOMINATOR
  );

  function getGas() external view returns (
      uint32 gas_dripper0,
      uint32 gas_dripper1,
      uint32 gas_icm,
      uint32 gas_creamery,
      uint32 gas_withdrawa
  );

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender, uint256 value);
}
/* ------------ END OF IMPORT IFlavors.sol ---------- */


/* ---------- START OF IMPORT IBridge.sol ---------- */




/**
@title IBridge
@author iceCreamMan
@notice The IBridge interface is an interface to
    interact with the flavors token bridge
 */

interface IBridge {
    function initialize(address ownableFlavors,address bridgeTroll) external;

    // onlyAdmin
    function pauseBridge_OAD() external;
    function unPauseBridge_OAD() external;
    function updateOwnable_OAD(address new_ownableFlavors) external;

    // onlyOwnable
    function burnItAllDown_OO() external;
    function updateOwner_OO(address new_owner) external;
    function updateIceCreamMan_OO(address new_iceCreamMan) external;

    // public functions
    function sendDepositToCreamery(uint256 value) external;
    function waitToCross(uint32 sourceChainId, uint32 destinationChainId, uint256 tokens) external;

    // public addresses
    function owner() external returns (address);
    function Ownable() external returns (address);
    function bridgeTroll() external returns (address);
    function iceCreamMan() external returns (address);
    function initialized() external returns (address);
    function FlavorsToken() external returns (address);
    function bridgePaused() external returns (address);
}
/* ------------ END OF IMPORT IBridge.sol ---------- */


/* ---------- START OF IMPORT IFlavorsChainData.sol ---------- */




interface IFlavorsChainData {
    function chainId() external view returns (uint chainId);
    function router() external view returns (address router);
    function tokenName() external view returns (string memory name);
    function tokenSymbol() external view returns (string memory symbol);
    function wrappedNative() external view returns (address wrappedNative);
}
/* ------------ END OF IMPORT IFlavorsChainData.sol ---------- */



contract OwnableFlavors is Context {
    using Address for address;

    ///@dev addresses
    address public pair;
    address public owner;
    address public router;
    address public flavor0;
    address public flavor1;
    address public dripper0;
    address public dripper1;
    address public creamery;
    address public iceCreamMan;
    address public flavorsToken;
    address public wrappedNative;
    address public flavorsChainData;
    address public ownable = address(this);
        // Assigning the pending role addresses to the dead address
        // Why? An unassigned address defaults to 0x0..00 and in some
        // cases other addresses default to 0x0..00. If a future
        // vulnverability is discovered allowing a function to execute
        // with msg.sender resetting to the zero address this will 
        // protect the onlypendingOwner and onlyPendingIceCreamMan modifiers.
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public bridge = DEAD;
    address public bridgeTroll = DEAD;
    address public pending_owner = DEAD;
    address public pending_iceCreamMan = DEAD;
    address public customBuyerContract0 = DEAD;
    address public customBuyerContract1 = DEAD;


    ///@dev contracts
    IBridge internal Bridge;
    ICreamery internal Creamery;
    IFlavors internal FlavorsToken;
    IFlavorDripper internal Dripper0;
    IFlavorDripper internal Dripper1;
    IFlavorsChainData internal FlavorsChainData;

    // mapping for additional authorized management roles
    // all authorized roles have the same permissions
    // and share a single modifier 'authorized'
    mapping(address => bool) internal authorizations;
    mapping(address => bool) internal admins;
    mapping(address => bool) internal teamMembers;

    ///@dev The state of initialization
    bool public initialized0 = false;
    bool public initialized1 = false;

    /**
        @notice Initializer Function 1 of 2 for OwnableFlavors.Sol
        @dev The main flavors token begins the initialization process, it sends
         addresses and other information to this contract. Then this contract
         relays the data to initialize all the other Flavors ecosystem contracts
        @param _flavorsChainData Address of the flavors multi-chain naming contract
        @param _owner Address of the owner
        @param _flavorsToken Address of the main flavors token contract
        @param _bridge Address of the flavors token Bridge
     */
        //@param _iceCreamMan Address of the ice cream man
        //@param _bridgeTroll Address of the flavors token Bridge troll (Bridge operator is a custom cloudflare service worker)    
    
    function initialize0(
      address _flavorsChainData,
      address _owner,
      address _flavorsToken,
      address _bridge
    ) public {
        require(initialized0 == false,"OWNABLE FLAVORS: initialize0() = Already Initialized");
        initialized0 = true;
        flavorsChainData = _flavorsChainData;
        FlavorsChainData = IFlavorsChainData(_flavorsChainData);
        wrappedNative = FlavorsChainData.wrappedNative();

        // transfer iceCreamMan role, also grants authorizations
        _transferICM(_owner,false);
        // transfer ownership, also grants authorizations
        _transferOwnership(_owner,false);

        flavorsToken = _flavorsToken;
        FlavorsToken = IFlavors(flavorsToken);

        router = FlavorsChainData.router();
        // update Bridge & Bridge Troll address
        if(_bridge!=DEAD){
            _updateBridge(_bridge, _owner);
        }
        emit Initialized0(
            block.number,
            block.timestamp,
            _owner,
            _owner,
            _flavorsToken,
            router,
            _flavorsChainData
        );
    }

   /**
    @notice Initializer Function 2 of 2 for OwnableFlavors.Sol
    @dev The main flavors token begins the initialization process, it sends
         addresses and other information to this contract. Then this contract
         relays the data to initialize all the other Flavors ecosystem contracts
    @param _flavor0 Address of the Flavor1 reward token
    @param _flavor1 Address of the Flavor1 reward token
    @param _dripper0 Address of the Flavor Dripper0 contract
    @param _dripper1 Address of the Flavor Dripper1 contract
    @param _creamery Address of the Flavors Creamery
     */
    //@param _isDirectBuy0 Set to true if the Flavor0 reward token is purchased by sending the native coin direct to a contract instead of a liquidity pool
    //@param _isDirectBuy1 Set to true if the Flavor1 reward token is purchased by sending the native coin direct to a contract instead of a liquidity pool
    function initialize1(
      address _flavor0,
      address _flavor1,
      address _dripper0,
      address _dripper1,
      address _creamery

    ) public {
        require(initialized1 == false,"OWNABLE FLAVORS: initialize1() = Already Initialized");
        initialized1 = true;

        // update Dripper0
        _updateDripper0(_flavor0, false, _dripper0, address(0));
        // update Dripper1
        _updateDripper1(_flavor1, false, _dripper1, address(0));
        // update the flavors token address
        _updateFlavorsToken(address(FlavorsToken));

        // update the router address
        _updateRouter(router);

        // update the creamery
        _updateCreamery(_creamery);

        // initialize the creamery
        Creamery.initialize(address(this));

        emit Initialized1(
            flavor0,
            false, //_isDirectBuy0,
            flavor1,
            false, //_isDirectBuy1,
            address(Dripper0),
            address(Dripper1),
            address(Creamery),
            wrappedNative
        );
    }
             
    function upgrade(
            address owner_,
            address iceCreamMan_,
            address bridge_,

            address flavor0_,
            address flavor1_,
            address dripper0_,
            address dripper1_,

            address creamery_,
            address bridgeTroll_,
            address flavorsToken_,
            address flavorsChainData_,
            address pair_
    ) external {
        require(initialized0 == false,"OWNABLE FLAVORS: initialize0() = Already Initialized");
        require(initialized1 == false,"OWNABLE FLAVORS: initialize1() = Already Initialized");
        upgrade0(
            owner_,
            iceCreamMan_,
            bridge_,
            bridgeTroll_,
            flavorsToken_,
            flavorsChainData_,
            pair_
        );
        upgrade1(
            flavor0_,
            flavor1_,
            dripper0_,
            dripper1_,
            creamery_
        );
    }

    function upgrade0(
        address owner_,
        address iceCreamMan_,
        address bridge_,
        address bridgeTroll_,
        address flavorsToken_,
        address flavorsChainData_,
        address pair_
    )
        internal
    {


        // transfer iceCreamMan role, also grants authorizations
        _transferICM(iceCreamMan_, false);
        // transfer ownership, also grants authorizations
        _transferOwnership(owner_, false);

        flavorsToken = flavorsToken_;
        FlavorsToken = IFlavors(flavorsToken_);
        
        flavorsChainData = flavorsChainData_;
        FlavorsChainData = IFlavorsChainData(flavorsChainData_);

        router = FlavorsChainData.router();
        
        wrappedNative = FlavorsChainData.wrappedNative();
    
        bridgeTroll = bridgeTroll_;
        bridge = bridge_;
        Bridge = IBridge(bridge);
        pair = pair_;

        initialized0 = true;
    }

    function upgrade1(
        address flavor0_,
        address flavor1_,
        address dripper0_,
        address dripper1_,
        address creamery_
    )
        internal
    {
        flavor0 = flavor0_;
        flavor1 = flavor1_;
        dripper0 = dripper0_;
        Dripper0 = IFlavorDripper(dripper0_);
        dripper1 = dripper1_;
        Dripper1 = IFlavorDripper(dripper1_);
        creamery = creamery_;
        Creamery = ICreamery(creamery_);
        _addAuthorized(creamery);
        initialized1 = true;
    }



    /**
     * @dev Throws if called by any account other than the owner.
     * @notice If ownership is rounounced via the renounceOwnership() method,
               the owner role falls back to the iceCreamMan. The iceCreamMan may re-assign the
               owner role after ownership has been renounced in this manor.
     * @notice If ownership is renounced by transferreing to an unreachable non-zero
               address,owner roles do not fall back to the iceCreamMan,and the iceCreamMan may
               not re-assign the ownership role.
     */
    modifier onlyOwner() {
        if(owner == address(0)) {
            require(iceCreamMan == _msgSender(), "OWNABLE FLAVORS: onlyOwner() = ownership renounced,caller not iceCreamMan");
        } else { require(owner == _msgSender(), "OWNABLE FLAVORS: onlyOwner() = caller not Owner" );} _;}
    //modifier onlyFlavorsToken() {require(address(FlavorsToken) == _msgSender(),"OWNABLE FLAVORS: onlyFlavorsToken() = caller not FlavorsToken");_;}
    modifier onlyIceCreamMan() {require(iceCreamMan == _msgSender(),"OWNABLE FLAVORS: onlyIceCreamMan() = caller not iceCreamMan");_;}
    modifier onlyPendingOwner() {require(pending_owner == _msgSender(),"OWNABLE FLAVORS: onlyPendingOwner() = caller not pending_owner");_;}
    modifier onlyPendingIceCreamMan() {
        require(
            pending_iceCreamMan == _msgSender(),
            "OWNABLE FLAVORS: onlyPendingIceCreamMan() = caller not pending_iceCreamMan"
          );
          _;
    }

    modifier onlyIceCreamManOrOwner() {
        require(
            iceCreamMan == _msgSender() ||
            owner == _msgSender(),
            "OWNABLE FLAVORS: onlyIceCreamManOrOwner() = caller not iceCreamMan or Owner"
        );
        _;
    }
    modifier onlyAdmin() {require(admins[_msgSender()],"OWNABLE FLAVORS: onlyAdmin() = caller not admin");_;}
    modifier onlyAuthorized() {require(authorizations[_msgSender()],"OWNABLE FLAVORS: onlyAuthorized() = caller not authorized");_;}
    modifier onlyTeam() {require(teamMembers[_msgSender()],"OWNABLE FLAVORS: onlyAuthorized() = caller not authorized");_;}
    
    /*TODO AFTER BRUTE FORCING THE OWNABLE CONTRACT's ADDRESS IT MUST BE INSERTED HERE TODO*/
    //modifier onlyInitializer() { require(_msgSender() == address(0), "OWNABLE FLAVORS: onlyAdmin() = caller not IceCreamMan or Owner" );_;}
    /*TODO IF NOT, THEN ANYONE CAN LAUNCH OUR CONTRACTS TO ANY CHAIN AND GAIN OWNERSHIP TODO*/



    /**
     * @notice Internally called function to add admin.
     * @dev May be called by iceCreamMan or Owner
     * @dev also grants lower roles
     * @dev Forwards to the internal state changing function.
     * @param addr the address to add admin
     */
    function addAdmin_OICMO(address addr) external onlyIceCreamManOrOwner {
        _addAdmin(addr);
     }
    /**
     * @notice Internally called function to add admin.
     * @dev May be called by any internal function.
     * @param addr the address to add admin
     */
    function _addAdmin(address addr) internal {
        admins[addr] = true;
        _addAuthorized(addr);
        emit AdminAdded(_msgSender(),address(addr));
     }

    /**
     * @notice Externally called function to remove admin.
     * @dev May be called by admin
     * @dev Forwards to the internal state changing function.
     @param addr the address to remove admin
     */
    function removeAdmin_OICMO(address addr) external onlyIceCreamManOrOwner {
        require(addr != iceCreamMan && addr != owner,
            "OWNABLE FLAVORS: owner/iceCreamMan role can't be revoked, only transferred"
        );
        _removeAdmin(addr);
     }

    /**
     @notice Internally called function to remove admin.
     @dev May be called by any internal function.
     @param addr the address to remove admin
     */
    function _removeAdmin(address addr) internal {
        authorizations[addr] = false;
        _removeAuthorized(addr);
        emit AdminRemoved(_msgSender(),address(addr));
     }
    /**
     * @notice Internally called function to add authorization.
     * @dev May be called by admins
     * @dev also grants lower roles
     * @dev Forwards to the internal state changing function.
     * @param addr the address to add authorization
     */
    function addAuthorized_OAD(address addr) external onlyAdmin {
        // relay the function to the internal function,revert if it fails
        _addAuthorized(addr);
     }
    /**
     * @notice Internally called function to add authorization.
     * @dev May be called by any internal function.
     * @param addr the address to add authorization
     */
    function _addAuthorized(address addr) internal {
        authorizations[addr] = true;
        _addTeamMember(addr);
        emit AuthorizationGranted(_msgSender(),address(addr));
     }

    /**
     * @notice Externally called function to remove authorization.
     * @dev May be called by admin
     * @dev Forwards to the internal state changing function.
     @param addr the address to remove authorization
     */
    function removeAuthorized_OAD(address addr) external onlyAdmin {
        require(
            !admins[addr],
            "OWNABLE FLAVORS: address has higher privledge. use removeAdmin()"
        );
        _removeAuthorized(addr);
     }

    /**
     @notice Internally called function to remove authorization.
     @dev May be called by any internal function.
     @param addr the address to remove authorization
     */
    function _removeAuthorized(address addr) internal {
        authorizations[addr] = false;
        _removeTeamMember(addr);
        emit AuthorizationRevoked(_msgSender(),address(addr));
     }
    /**
     * @notice Externally called function to add teamMember.
     * @dev May be called by authorized or higher roles
     * @dev Forwards to the internal state changing function.
     * @param addr the address of which you wish to add teamMember
     */
    function addTeamMember_OAUTH(address addr) external onlyAuthorized {
        _addTeamMember(addr);
     }

    /**
     * @notice Internally called function to add team member.
     * @dev May be called by any internal function.
     * @param addr the address of the team member to add
     */
    function _addTeamMember(address addr) internal {
        teamMembers[addr] = true;
        emit TeamMemberAdded(_msgSender(), addr);
     }

    /**
     * @notice Externally called function to remove team member
     * @notice teamMember must be the addreses highest role
     * @dev May be called by authorized
     * @dev Forwards to the internal state changing function.
     * @param addr the address of which you wish to remove
     */
    function removeTeamMember_OAUTH(address addr) external onlyAuthorized {
        require(
            !authorizations[addr],
            "OWNABLE FLAVORS: address has higher privledge. use removeAuthorized()"
        );
        _removeTeamMember(addr);
     }

    /**
     @notice Internally called function to remove team member.
     @dev May be called by any internal function.
     @param addr the address of the team member to remove
     */
    function _removeTeamMember(address addr) internal {
        teamMembers[addr] = false;
        emit TeamMemberRemoved(_msgSender(), addr);
     }


    function removeAllCredentials(address addr) external onlyIceCreamManOrOwner {
        require(addr != iceCreamMan && addr != owner,
            "OWNABLE FLAVORS: owner/iceCreamMan role can't be revoked, only transferred"
        );
        admins[addr] = false;
        authorizations[addr] = false;
        teamMembers[addr] = false;
     }

    function getCredentials(address addr) external view returns (
        bool isOwner,
        bool isIceCreamMan,
        bool isAdmin_,
        bool isAuthorized_,
        bool isTeamMember_
    )
    {
        return (
            addr == owner,
            addr == iceCreamMan,
            admins[addr],
            authorizations[addr],
            teamMembers[addr]
        );
    }

    /**
      @notice Returns address' team member status
      @param addr the address to check the team member status of
      @return bool. true if the address is team member and vice versa
     */
    function isTeamMember(address addr) external view returns (bool) {
        return teamMembers[addr];
    }

    /**
      @notice Returns address' authorization status
      @param addr the address to check the authorization status of
      @return bool. true if the address is authorized and vice versa
     */
    function isAuthorized(address addr) external view returns (bool) {
        return authorizations[addr];
    }

    /**
      @notice Returns address' admin status
      @param addr the address to check the admin status of
      @return bool. true if the address is admin and vice versa
     */
    function isAdmin(address addr) external view returns (bool) {
        return admins[addr];
    }

    /**
      @notice Externally called function to renounce ownership.
      @dev May be called by Owner
      @dev Forwards to the internal state changing function.
     */
    function renounceOwnership_OO() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @notice Internally called function to renounce ownership.
     * @dev May be called by any internal function.
     */
    function _renounceOwnership() internal {
        owner = address(0);
        emit OwnershipTransferred(owner,address(0));
    }

    /**
     * @notice Externally called function to transfer ownership.
     * @dev May be called by iceCreamMan Or Owner
     * @dev Forwards to the internal state changing function.
     * @dev Reverts if internal function fails.
     * @dev Ownership Transfer must be accepted by the new owner.
     * @param addr the address of the new owner
     */
    function transferOwnership_OO(address addr) external onlyOwner {
        _transferOwnership(addr,true);
    }

    /**
     * @dev Internally called function to transfer ownership.
     * @dev May be called by any internal function.
     * @param addr the new owners address
     * @param requireConfirmation confirmation is always required for a new external wallet to accept the role. The new owner must call the 'acceptIceCreamMan' function from the new wallet address to finalize the transfer. The internal initializer, however, does not require confirmation
     */
    function _transferOwnership(address addr, bool requireConfirmation) internal {
        // if confirmation from the new owner is required
        if(requireConfirmation) {
            // update the pending owner
            pending_owner = addr;
            emit OwnershipTransferPending(_msgSender(),pending_owner);
            // if no confirmation from the new owner is required
        } else {
            // update the owner
            owner = addr;
            _addAdmin(owner);
            emit OwnershipTransferred(owner,addr);
        }
    }


    /**
     * @dev External call to accept the transferred ownership.
     * @dev Forwards to the internal state changing function.
     * @dev May be called by the pending owner.
     */
    function acceptOwnership_OPO() external onlyPendingOwner {
        _acceptOwnership();
    }

    /**
     * @notice Internal call to accept the transferred Ownership.
     * @dev Forwards to the internal state changing function.
     * @dev May be called by any internal function
     * @dev Returns 'true' if successful.
     */
    function _acceptOwnership() internal {
        address old_owner = owner;
        // set the current owner to the new owner
        owner = pending_owner;
        // grant the admin, authorized, and teamMember roles
        _addAdmin(owner);
        // reset the pending owner back to the dead address
        pending_owner = DEAD;
        // fire the ownership transferred event log
        emit OwnershipTransferred(old_owner,owner);
    }

    /**
     * @dev Externally called function to transfer iceCreamMan role.
     * @dev must be called by iceCreamMan
     * @dev Forwards to the internal state changing function.
     * @dev Reverts if internal function fails.
     * @dev iceCreamMan role must be accepted by the new iceCreamMan.
     */
    function transferICM_OICM(address new_iceCreamMan) external onlyIceCreamMan {
        _transferICM(new_iceCreamMan, true);
    }

    /**
     * @dev Internally called function to transfer iceCreamMan role.
     * @dev May be called by any internal function.
     * @dev Returns 'true' if successful.
     * @param new_iceCreamMan the new ice cream mans address
     * @param requireConfirmation confirmation is always required for a new external wallet to accept the role. The new ice cream man must call the 'acceptIceCreamMan' function from the new wallet address to finalize the transfer. The internal initializer, however, does not require confirmation
     */
    function _transferICM(address new_iceCreamMan, bool requireConfirmation) internal {
        
        // if confirmation from the new iceCreamMan is required
        if(requireConfirmation) {
            // update the pending iceCreamMan
            pending_iceCreamMan = new_iceCreamMan;
            // fire the pending iceCreamMan event log
            emit IceCreamManTransferPending(_msgSender(), pending_iceCreamMan);
            // if no confirmation from the new iceCreamMan is required
        } else {
            // grant the new iceCreamMan admin, authorized, and teamMember roles
            _addAdmin(new_iceCreamMan);
            // update the iceCreamMan
            iceCreamMan = new_iceCreamMan;
            emit IceCreamManTransferred(iceCreamMan, new_iceCreamMan);
        }
    }

    
    /**
     * @notice External call to accept the transferred iceCreamMan role.
     * @dev Forwards to the internal state changing function.
     * @dev May be called by the pending iceCreamMan.
     */
    function acceptIceCreamMan_OPI() external onlyPendingIceCreamMan {
        _acceptIceCreamMan();
    }

    /**
     * @notice Internal call to accept the transferred iceCreamMan role. 
     * @dev Forwards to the internal state changing function.
     * @dev May be called by any internal function
     */
    function _acceptIceCreamMan() internal {
        // temporarily store the old_ceCreamMan
        address old_iceCreamMan = iceCreamMan;
        // set the current iceCreamMan to the new iceCreamMan
        iceCreamMan = pending_iceCreamMan;
        // grant the new iceCreamMan admin, authorized, and teamMember roles
        _addAdmin(iceCreamMan);
        // reset the pending iceCreamMan back to the dead address
        pending_iceCreamMan = DEAD;
        // fire the iceCreamMan role transferred event log
        emit IceCreamManTransferred(old_iceCreamMan,iceCreamMan);
    }

    /**
     * @dev externally called function to update token address.
     * @dev must be called by iceCreamMan or owner.
     * @dev Forwards to the internal state changing function.
     * @dev Reverts if internal function fails.
     */
    function updateFlavorsToken_OICM(address new_flavorsToken) external onlyIceCreamMan {
        _updateFlavorsToken(new_flavorsToken);
    }

    /**
     * @dev Internally called function to update token address.
     * @dev May be called by any internal function.
     */
    function _updateFlavorsToken(address new_flavorsToken) internal {
        address old_flavorsToken = address(FlavorsToken);
        flavorsToken = new_flavorsToken;
        FlavorsToken = IFlavors(new_flavorsToken);
        Dripper0.updateFlavorsToken_OO(new_flavorsToken);
        Dripper1.updateFlavorsToken_OO(new_flavorsToken);

        // fire the updated token address log
        emit TokenUpdated(old_flavorsToken, new_flavorsToken);
    }

    /**
     * @dev externally called function to update Bridge address.
     * @dev must be called by iceCreamMan or owner.
     * @dev Forwards to the internal state changing function.
     * @dev Reverts if internal function fails.
     * @param new_bridge new Bridge address
     */
    function updateBridge_OICM(address new_bridge, address new_bridgeTroll) external onlyIceCreamMan {
        _updateBridge(new_bridge, new_bridgeTroll);
    }

    /**
     * @dev Internally called function to update Bridge address.
     * @dev May be called by any internal function.
     * @param new_bridge new Bridge address
     * @param new_bridgeTroll the Bridge operator address
     */
    function _updateBridge(address new_bridge, address new_bridgeTroll) internal {
        // temp store the old Bridge address
        address old_bridge = address(Bridge);
        
        if(new_bridge == address(0)){
            bridge == DEAD;
            new_bridgeTroll == DEAD;
            FlavorsToken.updateBridge_OO(DEAD);
            _updateBridgeTroll(DEAD);
        } else {
            _updateBridgeTroll(new_bridgeTroll);
            // create the Bridge contract instance
            bridge = new_bridge;
            Bridge = IBridge(new_bridge);
            // initialize the Bridge        
            Bridge.initialize(address(this), new_bridgeTroll);
            FlavorsToken.updateBridge_OO(new_bridge);
        }
        // fire the updated Bridge address log
        emit BridgeUpdated(old_bridge, new_bridge);
    }


    /**
     * @notice externally called function to update Bridge Operator address.
     * @dev must be called by iceCreamMan or owner.
     * @dev Forwards to the internal state changing function.
     * @dev Reverts if internal function fails.
     * @param new_bridgeTroll new Bridge operator address
     */
    function updateBridgeTroll_OICM(address new_bridgeTroll) external onlyIceCreamMan {
        _updateBridgeTroll(new_bridgeTroll);
    }

    /**
     * @dev Internally called function to update Bridge Operator address.
     * @dev May be called by any internal function.
     * @param new_bridgeTroll new Bridge Operator address
     */
    function _updateBridgeTroll(address new_bridgeTroll) internal {
        // temp store the old bridgeTroll address
        address oldBridgeTroll = bridgeTroll;
        // store the new bridgeTroll address
        bridgeTroll = new_bridgeTroll;
        // fire the bridgeTrroll update log
        emit BridgeTrollUpdated(oldBridgeTroll,new_bridgeTroll);
    }

    /**
     * @notice externally called function to update Dripper0 address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_flavor0 the new reward token address
     * @param new_isCustomBuy0 set to true for non-standard purchases of the token with custom contract
     * @param new_dripper0 new Dripper0 address
     * @param new_customBuyerContract0 for customBuy tokens, address of the custom logic purchasing contract
     */
    function updateDripper0_OICM(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    )
        external
        onlyIceCreamMan
    {
        _updateDripper0(
            new_flavor0,
            new_isCustomBuy0,
            new_dripper0,
            new_customBuyerContract0
        );
    }

    /**
     * @notice Internally called function to update Dripper0 address.
     *  May be called by any internal function.
     * @param new_flavor0 the new reward token address
     * @param new_isCustomBuy0 set to true for non-standard purchases of the token with custom contract
     * @param new_dripper0 new Dripper0 address
     * @param new_customBuyerContract0 for customBuy tokens, address of the custom logic purchasing contract
     */
    function _updateDripper0(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    )
        internal
    {
        // temp store the old Dripper0;
        address old_dripper0 = address(Dripper0);
        // grant authorization to the new Dripper0 address
        _addAuthorized(new_dripper0);
        // initialize the new Dripper0 contract
        // update flavor0;
        flavor0 = new_flavor0;
        dripper0 = new_dripper0;
        Dripper0 = IFlavorDripper(new_dripper0);
        // update the address with the flavors token
        FlavorsToken.updateDripper0_OO(new_dripper0);
        // initialize flavor Dripper0
        Dripper0.initialize(
            new_flavor0,
            new_isCustomBuy0,
            new_customBuyerContract0,
            address(this)
        );
        // update Dripper0 with the FlavorsToken
        // FlavorsToken.updateDripper0(new_dripper0);
        // fire the updated Dripper0 address log
        emit Dripper0Updated(old_dripper0, new_dripper0);
    }

    /**
     * @notice externally called function to update Dripper1 address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_flavor1 the new reward token address
     * @param new_isCustomBuy1 set to true for non-standard purchases of the token with custom contract
     * @param new_dripper1 new Dripper1 address
     * @param new_customBuyerContract1 for customBuy tokens, address of the custom logic purchasing contract
     */
    function updateDripper1_OICM(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    )
        external
        onlyIceCreamMan
    {
        _updateDripper1(
            new_flavor1,
            new_isCustomBuy1,
            new_dripper1,
            new_customBuyerContract1
        );
    }

    /**
     * @notice Internally called function to update Dripper1 address.
     *  May be called by any internal function.
     * @param new_flavor1 the new reward token address
     * @param new_isCustomBuy1 set to true for non-standard purchases of the token with custom contract
     * @param new_dripper1 new Dripper1 address
     * @param new_customBuyerContract1 for customBuy tokens, address of the custom logic purchasing contract
     */
    function _updateDripper1(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    )
        internal
    {
        // temp store the old Dripper1;
        address old_dripper1 = address(Dripper1);
        // grant authorization to the new Dripper1 address
        _addAuthorized(new_dripper1);
        // initialize the new Dripper1 contract
        // update flavor1;
        flavor1 = new_flavor1;
        dripper1 = new_dripper1;
        Dripper1 = IFlavorDripper(new_dripper1);
        // update the address with the flavors token
        FlavorsToken.updateDripper1_OO(new_dripper1);
        // initialize flavor Dripper1
        Dripper1.initialize(
            new_flavor1,
            new_isCustomBuy1,
            new_customBuyerContract1,
            address(this)
        );
        // update Dripper1 with the FlavorsToken
        // FlavorsToken.updateDripper1(new_dripper1);
        // fire the updated Dripper1 address log
        emit Dripper1Updated(old_dripper1, new_dripper1);
    }

    /**
     * @notice externally called function to update flavor0 address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_flavor0 new flavor0 address
     * @param new_isCustomBuy0 set to 'true' if the new token is purchased by sending the native coin
              direct to the contract. Or if the native coin must be relayed through a custom
              purchasing contract. This would be for situations when the token is obtained through
       @param new_customBuyerContract0 the custom logic token purchasing contract address for non-standard situations
     */
    function updateFlavor0_OAD(address new_flavor0,bool new_isCustomBuy0,address new_customBuyerContract0) external onlyAdmin {
        _updateFlavor0(new_flavor0, new_isCustomBuy0, new_customBuyerContract0);
    }

    /**
     * @notice Internally called function to update flavor0 address.
     *  May be called by any internal function.
     * @param new_flavor0 new flavor0 address
     * @param new_isCustomBuy0 set to 'true' if the new token is purchased by sending the native coin
              direct to the contract. Or if the native coin must be relayed through a custom
              purchasing contract. This would be for situations when the token is obtained through
       @param new_customBuyerContract0 the custom logic token purchasing contract address for non-standard situations
     */
    function _updateFlavor0(address new_flavor0, bool new_isCustomBuy0, address new_customBuyerContract0) internal {
        // fire the updated Flavor0 address log before we overright the previous address
        emit Flavor0Updated(flavor0, new_flavor0, new_isCustomBuy0, new_customBuyerContract0);
        flavor0 = new_flavor0;
        Dripper0.updateFlavor_OO(
            new_flavor0,
            new_isCustomBuy0,
            new_customBuyerContract0
        );
    }

    /**
     * @notice externally called function to update flavor1 address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_flavor1 new flavor1 address
     * @param new_isCustomBuy1 set to 'true' if the new token is purchased by sending the native coin
              direct to the contract. Or if the native coin must be relayed through a custom
              purchasing contract. This would be for situations when the token is obtained through
       @param new_customBuyerContract1 the custom logic token purchasing contract address for non-standard situations
     */
    function updateFlavor1_OAD(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_customBuyerContract1
    )
        external
        onlyAdmin
    {
        _updateFlavor1(new_flavor1, new_isCustomBuy1, new_customBuyerContract1);
    }

    /**
     * @notice Internally called function to update flavor1 address.
     *  May be called by any internal function.
     * @param new_flavor1 new flavor1 address
     * @param new_isCustomBuy1 set to 'true' if the new token is purchased by sending the native coin
              direct to the contract. Or if the native coin must be relayed through a custom
              purchasing contract. This would be for situations when the token is obtained through
       @param new_customBuyerContract1 the custom logic token purchasing contract address for non-standard situations
     */
    function _updateFlavor1(address new_flavor1, bool new_isCustomBuy1, address new_customBuyerContract1) internal {
        // fire the updated Flavor1 address log before we overright the previous address
        emit Flavor1Updated(flavor1, new_flavor1, new_isCustomBuy1, new_customBuyerContract1);
        flavor1 = new_flavor1;
        Dripper1.updateFlavor_OO(
            new_flavor1,
            new_isCustomBuy1,
            new_customBuyerContract1
        );
    }

    /**
     * @notice externally called function to update Creamery address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_creamery new Creamery address
     */
    function updateCreamery_OICM(address new_creamery) external onlyIceCreamMan {
        _updateCreamery(new_creamery);
    }

    /**
     * @notice Internally called function to update Creamery address.
     *  May be called by any internal function.
     * @param new_creamery new Creamery address
     */
    function _updateCreamery(address new_creamery) internal {
        // temp store the old_creamery address
        address old_creamery = address(Creamery);
        // init the new Creamery contract
        creamery = new_creamery;
        Creamery = ICreamery(new_creamery);
        // update the Creamery with the main flavors token contract
        FlavorsToken.updateCreamery_OO(new_creamery);
        // grant authorization to the Creamery
        // authorization required so the creamery can run creamAndFreeze + spiltMilk
        _addAuthorized(new_creamery);
        // fire the creameryUpdated log
        emit CreameryUpdated(old_creamery, new_creamery);
    }

    /**
     * @notice Externally called function to update Router address.
     *  must be called by iceCreamMan or owner.
     *  Forwards to the internal state changing function.
     *  Reverts if internal function fails.
     * @param new_router new Router address
     */
    function updateRouter_OAD(address new_router) external onlyAdmin {
        _updateRouter(new_router);
    }

    /**
     * @notice Internally called function to update Router address.
     *  May be called by any internal function.
     * @param new_router new Router address
     */
    function _updateRouter(address new_router) internal {
        // temp store the old router address
        address oldRouter = router;
        // update the router Address
        router = new_router;
        // update the Router with the main flavors token contract
        // also creates a new liquidity pool
        // returns the pair address to updatePair(address pair)
        pair = FlavorsToken.updateRouter_OO(new_router);
        // update the Router with the Dripper0 contract
        Dripper0.updateRouter_OO(new_router);
        // update the Router with the Dripper1 contract
        Dripper1.updateRouter_OO(new_router);
        // fire the RouterUpdated log
        emit RouterUpdated(oldRouter,new_router);
    }

    function updatePair_OAD(address _pair) external onlyIceCreamMan { pair = _pair;}

    // event logs,indexed
    event Initialized0(
        uint256 blockNumber,
        uint256 blockTimestamp,
        address iceCreamMan,
        address owner,
        address token,
        address router,
        address flavorsChainData
    );

    event Initialized1(
        address flavor0,
        bool _isDirectBuy0,
        address flavor1,
        bool _isDirectBuy1,
        address dripper0,
        address drippper1,
        address creamery,
        address wrappedNative
    );

    event BridgeUpdated(address old_bridge, address new_bridge);
    event RouterUpdated(address old_router, address new_router);
    event AdminAdded(address authorizedBy, address addedAdmin);
    event AdminRemoved(address authorizedBy, address removedAdmin);
    event OwnershipTransferred(address old_owner, address new_owner);
    event CreameryUpdated(address old_creamery, address new_creamery);
    event Dripper1Updated(address old_dripper1, address new_dripper1);
    event Dripper0Updated(address old_dripper0, address new_dripper0);
    event TeamMemberAdded(address authorizedBy, address addedTeamMember);
    event TokenUpdated(address old_flavorsToken, address new_flavorsToken);
    event OwnershipTransferPending(address authorizedBy, address new_owner);
    event TeamMemberRemoved(address authorizedBy, address removedTeamMember);
    event BridgeTrollUpdated(address old_bridgeTroll, address new_bridgeTroll);
    event AuthorizationGranted(address authorizedBy, address authorizedAccount);
    event AuthorizationRevoked(address authorizedBy, address unauthorizedAccount);
    event IceCreamManTransferred(address old_iceCreamMan, address new_iceCreamMan);
    event IceCreamManTransferPending(address authorizedBy, address new_iceCreamMan);
    event DepositTransferred(address from, uint256 amount, string note0, string note1);
    event Flavor0Updated(address old_flavor0, address new_flavor0, bool new_isCustomBuy0, address new_customBuyerContract0);
    event Flavor1Updated(address old_flavor1, address new_flavor1, bool new_isCustomBuy1, address new_customBuyerContract1);
    
    function sendDepositToCreamery(uint256 _value) public payable {
       // (,,,uint32 creameryGas,) = FlavorsToken.gas();
        // transfer the funds
        Address.sendValue(payable(address(Creamery)), _value);
        emit DepositTransferred(_msgSender(), msg.value,
            "External Payment Received", "Sent to the Creamery"
        );
    }

    fallback() external payable { sendDepositToCreamery(msg.value);}
    receive() external payable { sendDepositToCreamery(msg.value);}
}