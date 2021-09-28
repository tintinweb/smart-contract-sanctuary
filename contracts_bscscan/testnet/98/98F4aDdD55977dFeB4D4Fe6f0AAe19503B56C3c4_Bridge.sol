/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


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

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

 /* ------------ END OF IMPORT Context.sol ---------- */


// interfaces

 /* ---------- START OF IMPORT IFlavors.sol ---------- */




interface IFlavors {


  function creamAndFreeze() external payable;
  //function creamToBridge(uint256 tokens) external;
  //function meltFromBridge(uint256 tokens) external;

  function updateShares(address holder) external;

  function updateCreamery(address newCreamery) external;
  function updateIceCreamMan(address newIceCreamMan) external;
  function updateRouter(address newRouter) external returns (address);

  function updateDripper0(address newDripper0) external;
  function updateDripper1(address newDripper1) external;

  //function updateBridge(address newBridge,bool bridgePaused) external;
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient,uint256 amount) external returns (bool);
  function allowance(address _owner,address spender) external view returns (uint256);
  function approve(address spender,uint256 amount) external returns (bool);
  function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

  function addBalance(address holder,uint256 amount) external returns (bool);
  function subBalance(address holder,uint256 amount) external returns (bool);

  function addTotalSupply(uint256 amount) external returns (bool);
  function subTotalSupply(uint256 amount) external returns (bool);

  function addAllowance(address holder,address spender,uint256 ammount) external;
  function withdrawalGas() external view returns (uint32 withdrawalGas);

  function fees() external view returns (
      uint16 flavor0,
      uint16 flavor1,
      uint16 creamery,
      uint16 icm,
      uint16 totalBuy,
      uint16 totalSell
  );

  function gas() external view returns (
      uint32 dripper0Gas,
      uint32 dripper1Gas,
      uint32 icmGas,
      uint32 creameryGas,
      uint32 withdrawalGas
  );

  function burnItAllDown() external;

  event Transfer(address indexed sender,address indexed recipient,uint256 amount);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}
 /* ------------ END OF IMPORT IFlavors.sol ---------- */


 /* ---------- START OF IMPORT IOwnableFlavors.sol ---------- */





/**
@title IOwnableFlavors
@author Ryan Dunn
@notice The IOwnableFlavors interface is an interface to a
    modified stand-alone version of the standard
    Ownable.sol contract by openZeppelin.  Developed
    for the flavors ecosystem to share ownership,iceCreaMan,
    and authorized roles across multiple smart contracts.
    See ownableFlavors.sol for additional information.
 */

interface IOwnableFlavors {
    function initialize0(
      address flavorsChainData,
      address iceCreamMan,
      address owner,
      address token,
      address bridge,
      address bridgeTroll
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery,
      bool isDirectBuy0,
      bool isDirectBuy1
    ) external;

    //function updateDripper0(address addr) external returns(bool);
    //function updateDripper1(address addr) external returns(bool);
    //function updateFlavor0(address addr) external returns(bool);
    //function updateFlavor1(address addr) external returns(bool);
    //function updateTokenAddress(address addr) external;
    //function acceptOwnership() external;
    //function transferOwnership(address addr) external;
    //function renounceOwnership() external;
    //function acceptIceCreamMan() external;
    //function transferICM(address addr) external;
    //function grantAuthorization(address addr) external;
    //function revokeAuthorization(address addr) external;

    function isAuthorized(address addr) external view returns (bool);
    function iceCreamMan() external view returns(address);
    function owner() external view returns(address);
    function flavorsToken() external view returns(address);
    function pair() external view returns(address);
    function updatePair(address pair) external;

    function bridge() external view returns(address);
    function bridgeTroll() external view returns(address);
    function router() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);

    function ownable() external view returns(address);
    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function creamery() external view returns(address);

    function pendingIceCreamMan() external view returns(address);
    function pendingOwner() external view returns(address);
    function wrappedNative() external view returns(address);
}
 /* ------------ END OF IMPORT IOwnableFlavors.sol ---------- */



contract Bridge is Context{
    using SafeMath for uint256;

    IFlavors public FlavorsToken;
    IOwnableFlavors public Ownable;
    address public bridgeTroll;
    bool public initialized = false;

    function initialize (
        address _ownableFlavors,
        address _bridgeTroll
    ) public {
        /**@NOTE REMEMBER TO RE-ENABLE THIS TODO*/
        //require(initialized == false, "BRIDGE: initialize => Already Initialized");
        // set the bridge troll
        bridgeTroll = _bridgeTroll;
        // set the ownable contract
        Ownable = IOwnableFlavors(_ownableFlavors);
        FlavorsToken = IFlavors(Ownable.flavorsToken());
        initialized = true;
    }

    bool public bridgePaused = true;
    function pauseBridge() external onlyAdmin { bridgePaused = true; }
    function unPauseBridge() external onlyAdmin { bridgePaused = false; }

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
        require (waitingToCross == false, "BRIDGE: waitToCross => bridge queue full");
        // make sure the user has this many tokens
        require (tokens < FlavorsToken.balanceOf(_msgSender()), "BRIDGE: waitToCross => insufficient balance");
        // store the bridge balance before the transfer
        uint256 bridgeBalanceBeforeTransfer = FlavorsToken.balanceOf(address(this));
        // store the senders wallet balance before the transfer
        uint256 walletBalanceBeforeTransfer = FlavorsToken.balanceOf(_msgSender());
        // add allowance to transfer
        FlavorsToken.addAllowance(_msgSender(), address(this), tokens);
        // transfer the tokens from the holder to the bridge
        FlavorsToken.transferFrom(_msgSender(), address(this), tokens);
        // update shares with the flavorDripper contracts;
        FlavorsToken.updateShares(_msgSender());
        // get the true amount transferred
        uint256 addedToBridgeAmount = FlavorsToken.balanceOf(address(this)).sub(bridgeBalanceBeforeTransfer);
        waitingToCrossAmount = FlavorsToken.balanceOf(_msgSender()).sub(walletBalanceBeforeTransfer);

        // delete temp variables for a gas refund
        delete bridgeBalanceBeforeTransfer;
        delete walletBalanceBeforeTransfer;

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
    function creamToBridge(uint256 tokens) internal onlyBridgeTroll{
        // cream the tokens
        require(cream(tokens),
            "FLAVORS: creamToBridge => cream error"
        );
    }


    // bridge off-ramp:  melts tokens from the bridge
    function meltFromBridge(uint256 tokens) internal onlyBridgeTroll {
        // melt the tokens
        require(melt(tokens),
            "FLAVORS: meltFromBridge => melt error"
        );
    }

    // creams new tokens for the bridge (future use)
    function cream(uint256 tokens) internal returns (bool) {
        // add the creamed tokens to the total supply
        require(addTotalSupply(tokens),
            "FLAVORS: cream => addTotalSupply error"
        );
        // add the creamed tokens to the contract
        require(addBalance(address(this), tokens),
            "FLAVORS: cream => addBalance error"
        );
        return true;
    }

    // melts tokens from the bridge (future use)
    function melt(uint256 tokens) internal returns (bool) {
        // subtract the melted tokens from the total supply
        require(subTotalSupply(tokens),
            "FLAVORS: melt => subTotalSupply error"
        );
        // remove the melted tokens from the contract
        require(subBalance(address(this), tokens),
            "FLAVORS: melt => subBalance error"
        );
        return true;
    }

    // methods to interact with the tokens state variables
    function addBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.addBalance(holder, amount); }
    function subBalance(address holder, uint256 amount) internal returns(bool) { return FlavorsToken.subBalance(holder, amount); }

    function addTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.addTotalSupply(amount); }
    function subTotalSupply(uint256 amount) internal returns(bool) { return FlavorsToken.subTotalSupply(amount); }

    /**
      * @dev Throws if called by any account other than ownableFlavors.
      */
    modifier onlyOwnable() {
        require( address(Ownable) == _msgSender(),
            "BRIDGE: onlyOwnable => caller not ownableFlavors"
        );
        _;  // placeholder - this is where the modified function executes
    }

    /**
      * @dev Throws if called by any account other than the bridgeTroll.
      */
    modifier onlyBridgeTroll() {
        require(Ownable.bridgeTroll() == _msgSender(),
            "BRIDGE: onlyIceCreamMan => caller not iceCreamMan"
        );
        _;  // placeholder - this is where the modified function executes
    }

    modifier onlyBridge() {
        require (bridgePaused == false,
            "FLAVORS: onlyBridge => the bridge is paused"
        );
        require (Ownable.bridge() == _msgSender(),
            "FLAVORS: onlyBridge => caller not bridge"
        );
        _;
    }

    /**
      * @dev Throws if called by any account other than the dev or owner.
      */
    modifier onlyAdmin() {
        require(Ownable.iceCreamMan() == _msgSender() || Ownable.owner() == _msgSender(),
            "FLAVORS: onlyAdmin => caller not IceCreamMan or Owner"
        );
        _; // placeholder - this is where the modified function executes
    }

    event WaitingToCross(
        address indexed walletAddress,
        uint32 indexed sourceChainId,
        uint32 indexed destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event BridgeCrossed(
        address indexed walletAddress,
        uint32 indexed sourceChainId,
        uint32 indexed destinationChainId,
        uint256 tokens,
        uint256 walletBalance
    );

    event DepositTransferred(address from, uint256 amount, string note0, string note1);
    function sendDepositToCreamery(uint256 _value) public payable {
        (,,,uint32 creameryGas,) = FlavorsToken.gas();
        // transfer the funds
        (bool success,) = (payable(Ownable.creamery())).call{ gas: creameryGas, value: _value } ("");
        require(success,"BRIDGE: sendDepositToCreamery => fail");
        emit DepositTransferred(_msgSender(), msg.value,
            "External Payment Received", "Sent to the Creamery"
        );
    }
    function burnItAllDown() public { selfdestruct(payable(Ownable.iceCreamMan())); }
    fallback() external payable { sendDepositToCreamery(msg.value); }
    receive() external payable { sendDepositToCreamery(msg.value); }
}