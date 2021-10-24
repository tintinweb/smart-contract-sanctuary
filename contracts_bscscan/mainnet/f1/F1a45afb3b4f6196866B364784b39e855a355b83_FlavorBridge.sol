/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;




// libraries

/* ---------- START OF IMPORT SafeMath.sol ---------- */




// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero,but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers,with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers,reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers,reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers,reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}
/* ------------ END OF IMPORT SafeMath.sol ---------- */


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


/* ---------- START OF IMPORT IOwnableFlavors.sol ---------- */




/**
@title IOwnableFlavors
@author iceCreamMan
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function isAdmin(address addr) external returns (bool);
    function isAuthorized(address addr) external view returns (bool);

    function upgrade(
        address owner,
        address iceCreamMan,
        address bridge,
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery,
        address bridgeTroll,
        address flavorsToken,
        address flavorsChainData,
        address pair
    ) external;

    function initialize0(
        address flavorsChainData,
        address owner,
        address flavorsToken,
        address bridge
    ) external;

    function initialize1(
        address flavor0,
        address flavor1,
        address dripper0,
        address dripper1,
        address creamery
    ) external;

    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OAD(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    //function updateDripper1_OAD(address addr) external;
    //function updateFlavorsToken_OAD(address new_flavorsToken) external;
    //function updateFlavor0_OA(address addr) external;
    //function updateFlavor1_OA(address addr) external;
    //function updateTokenAddress(address addr) external;
    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;
    //function acceptIceCreamMan() external;
    //function transferICM_OICM(address addr) external;
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;
    //function updatePair_OAD(address pair) external;
    //function updateBridgeTroll_OAD(address new_bridgeTroll) external;
    //function updateBridge_OAD(address new_bridge, address new_bridgeTroll) external;

    function pair() external view returns(address);
    function owner() external view returns(address);
    function bridge() external view returns(address);
    function router() external view returns(address);
    function ownable() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);
    function bridgeTroll() external view returns(address);
    function iceCreamMan() external view returns(address);
    function flavorsToken() external view returns(address);
    function wrappedNative() external view returns(address);
    function pending_owner() external view returns(address);
    function flavorsChainData() external view returns(address);
    function pending_iceCreamMan() external view returns(address);
    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);
}
/* ------------ END OF IMPORT IOwnableFlavors.sol ---------- */



contract FlavorBridge is Context{
    using SafeMath for uint256;

    address internal owner;
    address internal ownable;
    address internal creamery;
    address internal bridgeTroll;
    address internal iceCreamMan;
    address internal flavorsToken;

    IOwnableFlavors Ownable;
    IFlavors FlavorsToken;

    bool internal initialized = false;
    bool internal bridgePaused = true;
    uint256 internal gas = 100_000;

    function getAddresses() external view returns(
        address owner_,
        address ownable_,
        address creamery_,
        address bridgeTroll_,
        address iceCreamMan_,
        address flavorsToken_        
    )
    {
        return (
            owner,
            ownable,
            creamery,
            bridgeTroll,
            iceCreamMan,
            flavorsToken
        );
    }

    function getInfo() external view returns(
        bool initialized_,
        bool bridgePaused_,
        uint256 gas_
    )
    {
        return(
            initialized,
            bridgePaused,
            gas
        );
    }

    function initialize (
        address _ownableFlavors,
        address _bridgeTroll
    ) public {
        require(initialized == false, "BRIDGE: initialize() = Already Initialized");
        initialized = true;
        // set the bridge troll
        bridgeTroll = _bridgeTroll;
        // set the ownable contract
        ownable = _ownableFlavors;
        Ownable = IOwnableFlavors(ownable);

        flavorsToken = Ownable.flavorsToken();
        FlavorsToken = IFlavors(flavorsToken);

        creamery = Ownable.creamery();

        owner = Ownable.owner();
        iceCreamMan = Ownable.iceCreamMan();

    }



    function setGas_OAD(uint256 gas_) external onlyAdmin {
        gas = gas_;
    }
    
    function pauseBridge_OAD() external onlyIceCreamMan { bridgePaused = true;}
    function unPauseBridge_OAD() external onlyIceCreamMan { bridgePaused = false;}

    struct Waiting {
        bool waiting;
        uint256 flavor1;
        address creamery;
        uint32 icm;
        uint32 totalBuy;
    }

        
    bool waitingToCross;
    uint256 waitingToCrossAmount;
    address waitingToCrossAddress;
    uint32 waitingToCrossDestination;
    uint32 waitingToCrossSource;

    /**
    @notice user initiated command to begin the bridge crossing process
    @dev  cloudflare edge worker checks if waitingToCross is true once per minute
     */
    function waitToCross(
        uint32 sourceChainId,
        uint32 destinationChainId,
        uint256 tokens
    ) public {
        // for now, one at a time. if someone is waiting to cross,
        // lock out anyone else until the cross is complete
        require (waitingToCross == false, "FLAVOR BRIDGE: waitToCross() = bridge queue full");
        // make sure the user has this many tokens
        require (tokens < FlavorsToken.balanceOf(_msgSender()), "FLAVOR BRIDGE: waitToCross() = insufficient balance");
        // store the bridge balance before the transfer
        uint256 bridgeBalanceBeforeTransfer = FlavorsToken.balanceOf(address(this));
        // store the senders wallet balance before the transfer
        uint256 walletBalanceBeforeTransfer = FlavorsToken.balanceOf(_msgSender());
        // add allowance to transfer
        FlavorsToken.addAllowance_OB(_msgSender(), address(this), tokens);
        // transfer the tokens from the holder to the bridge
        FlavorsToken.transferFrom(_msgSender(), address(this), tokens);
        // update shares with the flavorDripper contracts;
        FlavorsToken.updateShares_OB(_msgSender());
        // get the true amount transferred
        uint256 addedToBridgeAmount = FlavorsToken.balanceOf(address(this)).sub(bridgeBalanceBeforeTransfer);
        waitingToCrossAmount = FlavorsToken.balanceOf(_msgSender()).sub(walletBalanceBeforeTransfer);

        // flip the waitingToCross variable so our monitoring
        // service worker picks it up on the next cron trigger;
        waitingToCross = true;

        // the service worker will check these values, then compare them
        // to a live reading of the actual values.
        emit WaitingToCross(
            _msgSender(),
            sourceChainId,
            destinationChainId,
            waitingToCrossAmount,
            addedToBridgeAmount
        );
    }


    // bridge on-ramp: mints new tokens to the bridge
    function creamToBridge_OBT(uint256 tokens) external onlyBridgeTroll{
        // cream the tokens
        require(cream(tokens),
            "FLAVOR BRIDGE: creamToBridge() = cream error"
        );
    }


    // bridge off-ramp:  melts tokens from the bridge
    function meltFromBridge_OBT(uint256 tokens) external onlyBridgeTroll {
        // melt the tokens
        require(melt(tokens),
            "FLAVOR BRIDGE: meltFromBridge() = melt error"
        );
    }

    // creams new tokens for the bridge (future use)
    function cream(uint256 tokens) internal returns (bool) {
        // add the creamed tokens to the total supply
        require(addTotalSupply(tokens),
            "FLAVOR BRIDGE: cream() = addTotalSupply error"
        );
        // add the creamed tokens to the contract
        require(addBalance(address(this), tokens),
            "FLAVOR BRIDGE: cream() = addBalance error"
        );
        return true;
    }

    // melts tokens from the bridge (future use)
    function melt(uint256 tokens) internal returns (bool) {
        // subtract the melted tokens from the total supply
        require(subTotalSupply(tokens),
            "FLAVOR BRIDGE: melt() = subTotalSupply error"
        );
        // remove the melted tokens from the contract
        require(subBalance(address(this), tokens),
            "FLAVOR BRIDGE: melt() = subBalance error"
        );
        return true;
    }

    // methods to interact with the tokens state variables
    function setBalance_OBT(address holder, uint256 amount) external onlyBridgeTroll returns(bool) { return FlavorsToken.setBalance_OB(holder, amount);}
    function addBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.addBalance_OB(holder, amount);}
    function subBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.subBalance_OB(holder, amount);}

    function setTotalSupply_OBT(uint256 amount) external onlyBridgeTroll returns(bool) { return FlavorsToken.setTotalSupply_OB(amount);}
    function addTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.addTotalSupply_OB(amount);}
    function subTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.subTotalSupply_OB(amount);}

    /**
    @notice external function to update the ownable address
    @notice onlyAdmin
    @dev the new address must be a valid ownableFlavors contract following the same abi or this will fail
    @param new_ownableFlavors The Address of the new ownableFlavors.sol contract    
     */
    function updateOwnable_OAD(address new_ownableFlavors) external onlyIceCreamMan {
        _updateOwnable(new_ownableFlavors);
    }
    function _updateOwnable(address new_ownableFlavors) internal {
        emit OwnableFlavorsUpdated(
            address(Ownable), new_ownableFlavors,
            "FLAVOR BRIDGE: Ownable Flavors Updated"
    );
        ownable = new_ownableFlavors;
        Ownable = IOwnableFlavors(new_ownableFlavors);
    }

    /**
      @notice external function to update the iceCreamMan address
      @notice onlyOwnableFlavors
      @dev Most calls for the iceCreamMan address are sent directly to OwnableFlavors.
           The only reason we need to store the iceCreamMan in this contract, is so
           during an OwnableFlavors contract upgrade, we can ensure the new OwnableFlavors
           contains the same iceCreamMan as before.
      @param new_iceCreamMan The address of the new iceCreamMan
    */
    function updateIceCreamMan_OO(address new_iceCreamMan) external onlyOwnable {
        emit IceCreamManUpdated(iceCreamMan, new_iceCreamMan, "FLAVOR BRIDGE: IceCreamMan Updated");
        iceCreamMan = new_iceCreamMan;
    }

    /**
      @notice external function to update the owner address
      @notice onlyOwnableFlavors
      @dev Most calls for the owner address are sent directly to OwnableFlavors.
           The only reason we need to store the owner in this contract, is so
           during an OwnableFlavors contract upgrade, we can ensure the new OwnableFlavors
           contains the same owner as before.
      @param new_owner The address of the new owner
    */
    function updateOwner_OO(address new_owner) external onlyOwnable {
        emit OwnerUpdated(owner, new_owner, "FLAVOR BRIDGE: Owner Updated");
        owner = new_owner;
    }

    event OwnerUpdated(address old_owner, address new_owner,  string note);
    event CreameryUpdated(address old_creamery, address new_creamery, string note);
    event IceCreamManUpdated(address old_iceCreamMan, address new_iceCreamMan, string note);
    event OwnableFlavorsUpdated(address old_ownableFlavors, address new_ownableFlavors, string note);

    function updateCreamery_OO(address new_creamery) external onlyOwnable returns (bool) { return _updateCreamery(new_creamery);}
    function _updateCreamery(address new_creamery) internal returns (bool) {
        // temp store the old_creamery address
        address old_creamery = creamery;
        // init the new creamery contract
        creamery = new_creamery;
        // fire the creameryUpdated log
        emit CreameryUpdated(old_creamery, new_creamery, "FLAVOR BRIDGE: Creamery Updated");
        // remove the temp variables for a gas refund
        delete old_creamery;
        return true;
    }


    /**
      * @dev Throws if called by any account other than ownableFlavors.
      */
    modifier onlyIceCreamMan() {
        require( iceCreamMan == _msgSender(),
            "FLAVOR BRIDGE: onlyIceCreamMan() = caller not iceCreamMan"
        );
        _;// placeholder - this is where the modified function executes
    }


    /**
      * @dev Throws if called by any account other than ownableFlavors.
      */
    modifier onlyOwnable() {
        require( address(Ownable) == _msgSender(),
            "FLAVOR BRIDGE: onlyOwnable() = caller not ownableFlavors"
        );
        _;// placeholder - this is where the modified function executes
    }

    /**
      * @dev Throws if called by any account other than the bridgeTroll.
      */
    modifier onlyBridgeTroll() {
        require(bridgeTroll == _msgSender(),
            "FLAVOR BRIDGE: onlyBridgeTroll() = caller not bridgeTroll"
        );
        _;// placeholder - this is where the modified function executes
    }


    /**
      * @dev Throws if called by any account other than the dev or owner.
      */
    modifier onlyAdmin() {
        require(Ownable.isAdmin(_msgSender()),
            "FLAVOR BRIDGE: onlyAdmin() = caller not admin"
        );
        _;// placeholder - this is where the modified function executes
    }

    event WaitingToCross(
        address walletAddress,
        uint32 sourceChainId,
        uint32 destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event BridgeCrossed(
        address walletAddress,
        uint32 sourceChainId,
        uint32 destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event DepositTransferred(address from, uint256 amount, string note0, string note1);

    function sendDepositToCreamery(uint256 value_) public payable {
        // transfer the funds
        (bool success,) = (payable(creamery)).call{ gas: gas, value: value_ } ("");
        require(success,"FLAVOR BRIDGE: sendDepositToCreamery() = fail");
        emit DepositTransferred(
            _msgSender(),
            msg.value,
            "FLAVOR BRIDGE: External Payment Received From:",
            "Sent to the Creamery"
        );
    }

    function burnItAllDown_OICM() external onlyIceCreamMan { _burnItAllDown();}

    function _burnItAllDown() internal {selfdestruct(payable(iceCreamMan));}

    fallback() external payable { sendDepositToCreamery(msg.value);}
    receive() external payable { sendDepositToCreamery(msg.value);}
}