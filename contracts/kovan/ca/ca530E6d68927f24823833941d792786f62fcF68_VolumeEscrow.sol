// SPDX-License-Identifier: GPLV3
// contracts/VolumeEscrow.sol
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./utils/VolumeOwnable.sol";
import "./token/IBEP20.sol";
import "./token/SafeBEP20.sol";
import "./interfaces/IVolumeBEP20.sol";
import "./interfaces/IBakeryRouter.sol";
import "./interfaces/IBakerySwapFactory.sol";
import "./interfaces/IBakerySwapPair.sol";

contract VolumeEscrow is VolumeOwnable , ReentrancyGuard  {
    uint256 constant BASE = 10**18;

    using Address for address payable;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address immutable wbnb; // WBNB contract address 
    address immutable bakeryRouter;   // bakryRouter address 
    address lpPool; // VOL-BNB bakery pool 
    address volume; // the Vol token address   
    
    uint256 private _nicknamePrice = 2000 * BASE;

    /**
     * allocations for each purpose 
     * 0 => IDO only used for the bakery IDO 
     * 1 => LP 
     * 2 => LP Rewards 
     * 3 => Team 
     * 5 => Marketing
     */ 
    uint256[] private _allocations;
    
    // STATE    
    uint8 private _rugpulled = 0;

    uint256 private _totalVolLeft; // VOL tokens left in the users wallets 
    uint256 private _totalBNBLeft; // the BNB amount that was in the BNB
    
    mapping (address => uint8) private _lpCreators;

    mapping (address => string) private _addressesNicknames;

    mapping (string => address) private _nicknamesAddresses;

    /**
     * @dev Constructor.
     */
    constructor(address multisig_, address wbnb_ , address bakeryRouter_) VolumeOwnable(multisig_) {
        require(wbnb_ != address(0) , "wbnb can't be address zero");
        require(bakeryRouter_ != address(0) , "BakeryRouter can't be address zero");
        bakeryRouter = bakeryRouter_;
        wbnb = wbnb_;
        _lpCreators[multisig_] = 1;
    }

    modifier onlyByLPCreators() {
        require(_lpCreators[_msgSender()] == 1 );
        _;
    }

    modifier onlyForLPCreation () {
        require(volume != address(0) , 'volume is not set yet ');
        require(lpPool == address(0), 'pool is already set');
        require(_allocations[1] > 0, 'no allocation left');
        require(_allocations[1] <= IBEP20(volume).balanceOf(address(this)), 'Allocation is bigger than the balance');
        _;
    } 

    /**
     * 
     *  @dev initialize the allocations for the volume bep20 token 
     *  look at the allocation enum to see which index is wich 
     *  allocations_
     *  0 IDO 
     *  1 LP providing
     *  2 LP Rewards
     *  3 Team
     *  4 Marketing
     *  ["375000000000000000000000000","375000000000000000000000000","100000000000000000000000000","100000000000000000000000000","50000000000000000000000000"],0x511839A0C9676171CF858F52cD1050b22A080CD8
     */
    function initialize ( uint256[] memory allocations_ , address volumeAddress_) external onlyOwner {
        require(volumeAddress_ != address(0), "volumeAddress can't be address zero");
        require(allocations_.length == 5 , "allocations need to be 5 length");
        require(volume == address(0) , "already initialized");
        _allocations = allocations_;
      
        volume = volumeAddress_;
    }


    /*
    Use this to send VOL from the escrow for a purpose 
    TODO : needs more restrictions on the receiver 
    ex 0 can send only to bakery 
        1 can only send to bakryROuter etc ...
    */
    function sendVolForPorpuse (uint id_ , uint256 amount_, address to_) external onlyOwner {
        require(_allocations[id_] >= amount_ , 'VolumeEscrow: amount is bigger than allocation');
        uint currentBalance = IBEP20(volume).balanceOf(address(this));
        require(currentBalance >= amount_, 'amount is more than the available balance');
        // send the amount 
        IBEP20(volume).safeTransfer(to_, amount_);
        _subAllocation(id_, amount_);
    }

    function addLPCreator(address newLpCreator_) external onlyOwner {
        _lpCreators[newLpCreator_] = 1;
    }

    function removeLPCreator(address lpCreatorToRemove_) external onlyOwner {
        require(lpCreatorToRemove_ != owner() , "can't remove the owner from lp creators");
        _lpCreators[lpCreatorToRemove_] = 0;
    }

    /**
        creates bakry LP using WBNB fron the sender's balance need to be approved
        can be called by the owner or by any address in the lpCreators mapping
     */
    function createLPWBNBFromSender ( uint256 amount_ , uint slipage_) external onlyByLPCreators nonReentrant onlyForLPCreation {
        require(amount_ > 0 , "amount can't be 0");
        IBEP20(wbnb).safeTransferFrom(_msgSender(), address(this), amount_);

        _createLP(amount_, _allocations[1], slipage_);
    }

    /*
        creates bakery LP from this contracts balance
    */
    function createLPFromWBNBBalance (uint slipage_) external onlyByLPCreators nonReentrant onlyForLPCreation {
        // check the balance
        uint256 wbnbBalance = IBEP20(wbnb).balanceOf(address(this));
        require(wbnbBalance > 0 , 'wbnbBalance == 0');

        _createLP(wbnbBalance, _allocations[1], slipage_);
    }

    /**
        Claims a nikname for a the caller , niknake has to be unique
     */
    function claimNickname (string memory nikname_) external {
        require(volume != address(0) , "not initialized yet");
        require(_nicknamesAddresses[nikname_] == address(0) , "Nickname already claimed");
        require(keccak256(abi.encodePacked(_addressesNicknames[_msgSender()])) 
        != keccak256(abi.encodePacked(nikname_)),
        "You already claimed a nikname"
        );

        IBEP20(volume).safeTransferFrom(_msgSender() , address(this) , _nicknamePrice); // take the price of the nickname
        IVolumeBEP20(volume).directBurnFromEscrow(_nicknamePrice); // burn the amount emidiatly 

        _addressesNicknames[_msgSender()] = nikname_;
        _nicknamesAddresses[ nikname_] = _msgSender();
    }

    /**
        Sets a new price for nickname claiming
     */
    function changeNicknamePrice (uint256 newPrice_) onlyOwner external {
        _nicknamePrice = newPrice_;
    }

    /**
    If we crash this function can be called to widraw the liquidity and make it available to all the holders to redeem
    the price will be determinned at the crash and each volume token not held by this contract will be able to be redeemed for a portion 
    of the underlaying BNB
     */
    function rugPullSimulation (uint slipage_) external onlyOwner nonReentrant {
        require(IVolumeBEP20(volume).getFuel() == 0, "There is still fuel can't rug pull");
        require(slipage_ > 0 && slipage_ < 1000, "Slipage is between 1-1000 ");
        require(_rugpulled == 0, "You can't rug pull twice :^)");
        uint256 volPoolBalance = IBEP20(volume).balanceOf(lpPool);
        uint256 wbnbPoolBalance = IBEP20(wbnb).balanceOf(lpPool);
        uint256 escrowlpBlance = IBEP20(lpPool).balanceOf(address(this));
        uint256 totalLpSupply = IBEP20(lpPool).totalSupply();

        uint256 minVolOut = volPoolBalance.mul(escrowlpBlance) / totalLpSupply;
        uint256 minWBNBOut = wbnbPoolBalance.mul(escrowlpBlance) / totalLpSupply;
        uint256 minVolOutWithSlipage = minVolOut - (minVolOut.mul(slipage_)/1000);
        uint256 minWBNBOutWithSlipage = minWBNBOut - (minWBNBOut.mul(slipage_)/1000);
        // approve the right amount of LP tokens 
        IBEP20(lpPool).safeApprove( bakeryRouter, escrowlpBlance);

        (uint256 volumeOut , uint256 wbnbOut) = IBakerySwapRouter(bakeryRouter).removeLiquidity(
                                                            volume,
                                                            wbnb,
                                                            escrowlpBlance,
                                                            minVolOutWithSlipage ,
                                                            minWBNBOutWithSlipage,
                                                            address(this),
                                                            block.timestamp + 1000*60*60*5 // 5 minutes more than enough 
                                                        );

        // this should never happen unless something malicious is going on so lets useup all gas left and revert 
        assert(
                volumeOut >= minVolOutWithSlipage
                && wbnbOut >=  minWBNBOutWithSlipage
                );

        // the only redeamable vol left is the one in all user's wallets and the team allocation 
        IVolumeBEP20(volume).directBurnFromEscrow(_allocations[4] + _allocations[2] + volumeOut);
        _allocations[4] = 0;
        _allocations[2] = 0;
        _totalVolLeft = IBEP20(volume).totalSupply();
        _totalBNBLeft = wbnbOut;
        _rugpulled = 1;

        // Rats are first to abandon ship so let's redeem any left over VOL for the team
        IBEP20(volume).safeApprove(address(this), _allocations[3]);
        _redeemVolAfterRugPull(_allocations[3] , owner() , address(this));
        _allocations[3] = 0;
    }

    /**
     *  REDEEM AFTER RUG PULL
     */
    function redeemVolAfterRugPull (uint256 amount_ , address to_) external nonReentrant nonReentrant{
            _redeemVolAfterRugPull(amount_ , to_ , _msgSender());
    }

    /**
        We use this to transfer any BEP20 that got sent to the escrow
        can't send VOL BNB or LP token 
     */
    function transferToken (address token_ , uint256 amount_ , address to_) external onlyOwner{
        require(token_ != lpPool && token_ != volume && token_ != wbnb, "can't transfer those from here");
        IBEP20(token_).safeTransfer(to_ , amount_);
    }

    /**
     * set the LP token manually in case bakry is the one who creates it after the IDO
     */
    function setLPAddress (address poolAddress_) external onlyOwner {
        require(poolAddress_ != address(0), "poolAddress_: can't be zero address"); // if it was set then fail 
        require(lpPool == address(0) , "LP was already set");
        lpPool = poolAddress_;
    }

    /**
     * returns the address for the LP pool Bakery Pair
     */
    function getLPAddress () external view returns (address) {
        return lpPool;
    }
    
    /**
        returns the nickname linked the the given address
     */
    function getNicknameForAddress (address address_) external view returns (string memory)  {
        return _addressesNicknames[address_];
    }

    /**
        returns the address linked the the given nickname
     */
    function getAddressForNickname (string memory nickname_) external view returns (address ) {
        return _nicknamesAddresses[nickname_];
    }

    /**
     * Returns the Address where Volume BEP20 was deployed
     */
    function getVolumeAddress () external view returns (address) {
        return volume;
    }

    
    function getAllocation (uint id_) external view returns (uint256) {
        return _allocations[id_];
    }

    function estimateRedeamOutForIn(uint256 amountIn_) external view returns (uint){
        return (_totalBNBLeft * amountIn_) / _totalVolLeft;
    }

    function _redeemVolAfterRugPull (uint256 amount_ , address to_ , address from_) internal {
        require(_rugpulled == 1, "You can't redeem before rug pull");
        assert(_totalBNBLeft > 0 && _totalVolLeft > 0);

        uint256 out = (_totalBNBLeft * amount_) / _totalVolLeft;

        IBEP20(volume).safeTransferFrom(from_ , address(this) , amount_);
        IBEP20(wbnb).safeTransfer(to_ , out);

        // burn what we just received
        IVolumeBEP20(volume).directBurnFromEscrow(amount_);

        _totalBNBLeft = _totalBNBLeft.sub(out);
        _totalVolLeft = _totalVolLeft.sub(amount_);
    }

    function _subAllocation(uint id_ , uint256 amount_) internal {
        _allocations[id_] = _allocations[id_].sub(amount_);
    }

    /**
        Will use the WBNB in this contract balance and The 
    */
    function _createLP (uint256  wbnbAmount_ ,uint256 volumeAmount_ , uint slipage_) internal {
        lpPool = IBakerySwapFactory(IBakerySwapRouter(bakeryRouter).factory()).getPair(volume, wbnb);
        require(lpPool == address(0) , 'already created');

        // Approve the tokens for bakry router
        IBEP20(wbnb).safeApprove(bakeryRouter, wbnbAmount_);
        IBEP20(volume).safeApprove(bakeryRouter, volumeAmount_);
                
        // Add liquidity 
        IBakerySwapRouter(bakeryRouter).addLiquidity(
            volume,
             wbnb,
            volumeAmount_,
            wbnbAmount_,
            volumeAmount_ - ( volumeAmount_.mul(slipage_) /1000 ), // slipage /1000 so every 1 in slipage is 0.1%
            wbnbAmount_ - ( wbnbAmount_.mul(slipage_) / 1000 ), // slipage /1000 so every 1 in slipage is 0.1%
            address(this),
            block.timestamp + 120000
        );

        // get the pool address 
        lpPool = IBakerySwapFactory(IBakerySwapRouter(bakeryRouter).factory()).getPair(volume , wbnb);
        // last check need to get an actuall address otherwise it might mean something happened that shouldn't 
        require(lpPool != address(0) , 'lpPair not created');
        // remove this volume from allocation 
        _subAllocation(1, volumeAmount_);
    }
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

interface IBakerySwapRouter {
    function factory() external pure returns (address);

    function WBNB() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityBNB(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountBNB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityBNB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountBNB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityBNBWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountBNB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactBNB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForBNB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapBNBForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountBNB);

    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountBNB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPLV3
pragma solidity >=0.8.4;

interface IBakerySwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPLV3
pragma solidity >=0.8.4;

interface IBakerySwapPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

import "../token/IBEP20.sol";

interface IVolumeBEP20 {
    
    struct UserFuel {
        address user;
        uint256 fuelAdded;
    }

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function directRefuel(uint256 fuel) external returns (bool);

    function directBurnFromEscrow(uint256 amount) external;

    function getFuel() external view returns (uint256);

    function getTotalFuelAdded() external view returns (uint256);

    function getUserFuelAdded(address account) external view returns (uint256);

    function getAllUsersFuelAdded(uint256 start , uint end) external view returns (UserFuel[] memory _array);

    function getAllUsersLength() external view returns (uint256);

    function _getLPAddress() external view returns (address);
}

// SPDX-License-Identifier: GPLV3
pragma solidity ^0.8.4;

/**
 * As defined in the ERC20 EIP
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract VolumeOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the provided multisig as the initial owner.
     */
    constructor (address multiSig_) {
        require(multiSig_ != address(0), "multisig_ can't be address zero");
        _owner = multiSig_;
        emit OwnershipTransferred(address(0), multiSig_);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

