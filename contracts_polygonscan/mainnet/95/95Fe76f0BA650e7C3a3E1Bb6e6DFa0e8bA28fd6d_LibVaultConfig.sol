/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// File: vaultfix/polycrystal-vaults/contracts/libs/LibMagnetite.sol



pragma solidity ^0.8.4;






//The bulk of the magnetite code is here

library LibMagnetite {

    using LibMagnetite for address[];

    

    struct PairData {

        address token;

        address lp;

        uint liquidity;

    }

    

    address constant private WNATIVE_DEFAULT = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    bytes constant private COMMON_TOKENS = abi.encode([

        address(0), //slot for wnative

        0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174, //usdc

        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, //weth

        0x831753DD7087CaC61aB5644b308642cc1c33Dc13, //quick

        0xc2132D05D31c914a87C6611C10748AEb04B58e8F, //usdt

        0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063  //dai

    ]);



    uint constant private NUM_COMMON = 6;

    uint constant private WNATIVE_MULTIPLIER = 3; // Wnative weighted 3x

    uint constant private B_MULTIPLIER = 10; // Token B direct swap weighted 10x



    enum AutoPath { MANUAL, SUBPATH, AUTO }

    event SetPath(AutoPath indexed _auto, address router, address[] path);



    function _setPath(mapping(bytes32 => address[]) storage _paths, address router, address[] memory _path, AutoPath _auto) public { 

        uint len = _path.length;



        bytes32 hashAB = keccak256(abi.encodePacked(router,_path[0], _path[len - 1]));

        bytes32 hashBA = keccak256(abi.encodePacked(router,_path[len - 1], _path[0]));

        address[] storage pathAB = _paths[hashAB];

        if (pathAB.length > 0 && _auto != AutoPath.MANUAL) return;

        address[] storage pathBA = _paths[hashBA];

        

        for (uint i; i < len; i++) {

            pathAB.push() = _path[i];

            pathBA.push() = _path[len - i - 1];

        }

            

        emit SetPath(_auto, router, pathAB);

        emit SetPath(_auto, router, pathBA);

        

        //fill sub-paths

        if (len > 2) {

            assembly { 

                mstore(_path, sub(len,1)) //reduce length by 1 (_we want _path[:len-1])

            } 

            _setPath(_paths, router, _path, AutoPath.SUBPATH);

            address path0 = _path[0]; //temp to restore array after slicing

            assembly {

                _path := add(0x20,_path) // shift right in memory (we want _path[1:])

                mstore(_path, sub(len,1))

            }

            _setPath(_paths, router, _path, AutoPath.SUBPATH);

            assembly {

                mstore(_path, path0) //restore path[0]

                _path := sub(_path,0x20) //shift to initial start

                mstore(_path, len) //correct length

            }

        }

    }

    

    function generatePath(address router, address a, address b) public view returns (address[] memory path) {

    

        address[] memory _b = new address[](2);

        _b[0] = b;

        address c = findPair(router, a, _b);

        _b[0] = a;

        address d = findPair(router, b, _b);

        

        path = new address[](5);

        path[0] = a;

        

        if (c == b || d == a) {

            path[1] = b;

            return path;

        } else if (c == d) {

            path[1] = c;

            path[2] = b;

            return path.setlength(3);

        }

        _b[1] = c;

        address e0 = findPair(router, d, _b);

        if (e0 == a) {

            path[1] = d;

            path[2] = b;

            return path.setlength(3);

        }

        path[1] = c;

        if (e0 == c) {

            path[2] = d;

            path[3] = b;

            return path.setlength(4);

        }

        _b[0] = b;

        _b[1] = d;

        address e1 = findPair(router, c, _b);

        if (e1 == b) {

            path[2] = b;

            return path.setlength(3);

        }

        if (e1 == d) {

            path[2] = d;

            path[3] = b;

            return path.setlength(4);

        }

        require (e1 == e0, "no path found");

        path[2] = e0;

        path[3] = d;

        path[4] = b;

        return path;

    }   

    function findPair(address router, address a, address[] memory b) public view returns (address) {

        IUniFactory factory = IUniFactory(IUniRouter02(router).factory());

        

        PairData[] memory pairData = new PairData[](NUM_COMMON + b.length);



        address[NUM_COMMON] memory allCom = allCommons(router);

        

        //populate pair tokens

        for (uint i; i < b.length; i++) {

            pairData[i].token = b[i];   

        }

        for (uint i; i < NUM_COMMON; i++) {

            pairData[i+b.length].token = allCom[i];

        }

        

        //calculate liquidity

        for (uint i; i < pairData.length; i++) {

            address pair = factory.getPair(a, pairData[i].token);

            if (pair != address(0)) {

                uint liq = IERC20(a).balanceOf(pair);

                if (liq > 0) {

                    pairData[i].lp = pair;

                    pairData[i].liquidity = liq;

                }

            }

        }

        //find weighted most liquid pair

        for (uint i; i < pairData.length; i++) {

            pairData[i].liquidity = pairData[i].liquidity * B_MULTIPLIER;

        }

        uint best;

        for (uint i = 1; i < pairData.length; i++) {

            if (compare(router, pairData[best], pairData[i])) best = i;

        }

        require(pairData[best].liquidity > 0, "no liquidity");

        

        return pairData[best].token;

    }

    

    function compare(address router, PairData memory x, PairData memory y) private pure returns (bool yBetter) {

        address wNative = wnative(router);

        uint xLiquidity = x.liquidity * (x.token == wNative ? WNATIVE_MULTIPLIER : 1);

        uint yLiquidity = y.liquidity * (y.token == wNative ? WNATIVE_MULTIPLIER : 1);

        return yLiquidity > xLiquidity;

    }



    function allCommons(address router) private pure returns (address[NUM_COMMON] memory tokens) {

        tokens = abi.decode(COMMON_TOKENS,(address[6]));

        tokens[0] = wnative(router);

    }

    function wnative(address router) private pure returns (address) {

        try IUniRouter02(router).WETH() returns (address weth) {

            return weth;

        } catch {

            return WNATIVE_DEFAULT;

        }

    }

    function getPathFromStorage(mapping(bytes32 => address[]) storage _paths, address router, address a, address b) private view returns (address[] storage path) {

        path = _paths[keccak256(abi.encodePacked(router, a, b))];

    }

    function setlength(address[] memory array, uint n) internal pure returns (address[] memory) {

        assembly { mstore(array, n) }

        return array;

    }

}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: vaultfix/polycrystal-vaults/contracts/Magnetite.sol



pragma solidity ^0.8.4;







//Automatically generates and stores paths

contract Magnetite is Ownable {

    

    mapping(bytes32 => address[]) private _paths;



    //Adds or modifies a swap path

    function overridePath(address router, address[] calldata _path) external onlyOwner {

        LibMagnetite._setPath(_paths, router, _path, LibMagnetite.AutoPath.MANUAL);

    }



    function setAutoPath_(address router, address[] calldata _path) external {

        require(msg.sender == address(this));

        LibMagnetite._setPath(_paths, router, _path, LibMagnetite.AutoPath.AUTO);

    }

    function _setPath(address router, address[] calldata _path, LibMagnetite.AutoPath _auto) internal { 

        LibMagnetite._setPath(_paths, router, _path, _auto);

    }

    function getPathFromStorage(address router, address a, address b) public view returns (address[] memory path) {

        if (a == b) {

            path = new address[](1);

            path[0] = a;

            return path;

        }

        path = _paths[keccak256(abi.encodePacked(router, a, b))];

    }

    function findAndSavePath(address router, address a, address b) public returns (address[] memory path) {

        path = getPathFromStorage(router, a, b); // [A C E D B]

        if (path.length == 0) {

            path = LibMagnetite.generatePath(router, a, b);



            if (pathAuth()) LibMagnetite._setPath(_paths, router, path, LibMagnetite.AutoPath.AUTO);

        }

    }

    function viewPath(address router, address a, address b) external view returns (address[] memory path) {

        path = getPathFromStorage(router, a, b); // [A C E D B]

        if (path.length == 0) {

            path = LibMagnetite.generatePath(router, a, b);

        }

    }

    function pathAuth() internal virtual view returns (bool) {

        return msg.sender == tx.origin || msg.sender == owner();

    }

}
// File: vaultfix/polycrystal-vaults/contracts/libs/IUniRouter.sol



pragma solidity ^0.8.4;



interface IUniRouter01 {

    function factory() external pure returns (address);



    function WETH() external pure returns (address);



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



    function addLiquidityETH(

        address token,

        uint256 amountTokenDesired,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    )

        external

        payable

        returns (

            uint256 amountToken,

            uint256 amountETH,

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



    function removeLiquidityETH(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountToken, uint256 amountETH);



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



    function removeLiquidityETHWithPermit(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountToken, uint256 amountETH);



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



    function swapExactETHForTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



    function swapTokensForExactETH(

        uint256 amountOut,

        uint256 amountInMax,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapExactTokensForETH(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external returns (uint256[] memory amounts);



    function swapETHForExactTokens(

        uint256 amountOut,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable returns (uint256[] memory amounts);



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



    function getAmountsOut(uint256 amountIn, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);



    function getAmountsIn(uint256 amountOut, address[] calldata path)

        external

        view

        returns (uint256[] memory amounts);

}



interface IUniRouter02 is IUniRouter01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline

    ) external returns (uint256 amountETH);



    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(

        address token,

        uint256 liquidity,

        uint256 amountTokenMin,

        uint256 amountETHMin,

        address to,

        uint256 deadline,

        bool approveMax,

        uint8 v,

        bytes32 r,

        bytes32 s

    ) external returns (uint256 amountETH);



    function swapExactTokensForTokensSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;



    function swapExactETHForTokensSupportingFeeOnTransferTokens(

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external payable;



    function swapExactTokensForETHSupportingFeeOnTransferTokens(

        uint256 amountIn,

        uint256 amountOutMin,

        address[] calldata path,

        address to,

        uint256 deadline

    ) external;

}

interface IUniFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);



    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);



    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);



    function createPair(address tokenA, address tokenB) external returns (address pair);



    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

}
// File: vaultfix/polycrystal-vaults/contracts/libs/LibVaultConfig.sol



pragma solidity ^0.8.4;





struct VaultSettings {

    IUniRouter02 router; //UniswapV2 compatible router

    uint16 slippageFactor; // sets a limit on losses due to deposit fee in pool, reflect fees, rounding errors, etc.

    uint16 tolerance; // "Hidden Gem", "Premiere Gem", etc. frontend indicator

    uint64 minBlocksBetweenEarns; //Prevents token waste, exploits and unnecessary reverts

    uint88 dust; //min token amount to swap/deposit. Prevents token waste, exploits and unnecessary reverts

    bool feeOnTransfer;

    Magnetite magnetite;

}



struct VaultFees {

    VaultFee withdraw;

    VaultFee earn; //rate paid to user who called earn()

    VaultFee reward; //"reward" fees on earnings are sent here

    VaultFee burn; //burn address for CRYSTL

}

struct VaultFee {

    IERC20 token;

    address receiver;

    uint96 rate;

}



library LibVaultConfig {

    

    uint256 constant FEE_MAX_TOTAL = 10000; //hard-coded maximum fee (100%)

    uint256 constant FEE_MAX = 10000; // 100 = 1% : basis points

    uint256 constant WITHDRAW_FEE_MAX = 100; // means 1% withdraw fee maximum

    uint256 constant WITHDRAW_FEE_LL = 0; //means 0% withdraw fee minimum

    uint256 constant SLIPPAGE_FACTOR_UL = 9950; // Must allow for at least 0.5% slippage (rounding errors)

    

    function check(VaultFees memory _fees) external pure {

        

        require(_fees.reward.receiver != address(0), "Invalid reward address");

        require(_fees.burn.receiver != address(0), "Invalid buyback address");

        require(_fees.earn.rate + _fees.reward.rate + _fees.burn.rate <= FEE_MAX_TOTAL, "Max fee of 100%");

        require(_fees.withdraw.rate >= WITHDRAW_FEE_LL, "_withdrawFeeFactor too low");

        require(_fees.withdraw.rate <= WITHDRAW_FEE_MAX, "_withdrawFeeFactor too high");

    }

    

    function check(VaultSettings memory _settings) external pure {

        try IUniRouter02(_settings.router).factory() returns (address) {}

        catch { revert("Invalid router"); }

        require(_settings.slippageFactor <= SLIPPAGE_FACTOR_UL, "_slippageFactor too high");

    }

    

}