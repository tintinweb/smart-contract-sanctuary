// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './access/Ownable.sol';
import "./token/BEP20/IBEP20.sol";
import "./interfaces/IPriceConsumerV3.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./libraries/Percentages.sol";
import "./interfaces/IRugZombieNft.sol";

struct NftInfo {
    bool isEnabled;
    uint256 price;
    PriceMode priceMode;
    uint maxMints;
    uint maxMintsPerUser;
    uint salesPerPrice;
    uint256 priceIncrease;
    mapping (address => uint) userMintCount;
}

enum PriceMode {
    BUSD,
    BNB
}

contract InstaBuy is Ownable {
    using Percentages for uint256;

    // Mapping for the storing the NftInfos
    mapping (address => NftInfo) public nftInfo;

    // Array to store the NftInfos for being iterated against
    address[] public nftAddresses;

    // Treasury address
    address payable treasury;

    // Burn address
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    // Zombie Token
    IBEP20 public zmbe;

    // DEX Router interface
    IUniswapV2Router02 public dexRouter;

    // Chainlink Price Oracle interface
    IPriceConsumerV3 public priceConsumer;

    // Constructor to initialize all the stuff
    constructor (address _treasury, address _zmbe, address _dexRouter, address _priceConsumer) {
        treasury = payable(_treasury);
        zmbe = IBEP20(_zmbe);
        dexRouter = IUniswapV2Router02(_dexRouter);
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Adds a NFT mapping
    function addNft(
        address _nftAddress, 
        uint256 _price, 
        uint _priceMode, 
        uint _maxMints, 
        uint _maxMintsPerUser, 
        uint _salesPerPrice, 
        uint256 _priceIncrease
    ) public onlyOwner() {
        nftInfo[_nftAddress].price = _price;
        nftInfo[_nftAddress].priceMode = PriceMode(_priceMode);
        nftInfo[_nftAddress].maxMints = _maxMints;
        nftInfo[_nftAddress].maxMintsPerUser = _maxMintsPerUser;
        nftInfo[_nftAddress].salesPerPrice = _salesPerPrice;
        nftInfo[_nftAddress].priceIncrease = _priceIncrease;
        nftAddresses.push(_nftAddress);
    }

    // Sets the enabled state of a NFT
    function setIsEnabled(address _nft, bool _enabled) public onlyOwner() {
        nftInfo[_nft].isEnabled = _enabled;
    }

    // Sets the price of a NFT
    function setPrice(address _nft, uint256 _price) public onlyOwner() {
        nftInfo[_nft].price = _price;
    }

    // Sets the price mode of a NFT
    function setPriceMode(address _nft, uint _priceMode) public onlyOwner() {
        nftInfo[_nft].priceMode = PriceMode(_priceMode);
    }

    // Function to set the sales per price
    function setSalesPerPrice(address _nft, uint _salesPerPrice) public onlyOwner() {
        nftInfo[_nft].salesPerPrice = _salesPerPrice;
    }

    // Function to set the price increase
    function setPriceIncrease(address _nft, uint256 _priceIncrease) public onlyOwner() {
        nftInfo[_nft].priceIncrease = _priceIncrease;
    }

    // Sets the maximum allowed mintings for a NFT
    function setMaxMints(address _nft, uint _maxMints) public onlyOwner() {
        nftInfo[_nft].maxMints = _maxMints;
    }

    // Set the max mints per user for a NFT
    function setMaxMintsPerUser(address _nft, uint _maxMintsPerUser) public onlyOwner() {
        nftInfo[_nft].maxMintsPerUser = _maxMintsPerUser;
    }

    // Sets the DEX router address
    function setRouter(address _dexRouter) public onlyOwner() {
        dexRouter = IUniswapV2Router02(_dexRouter);
    }

    // Sets the price consumer address
    function setPriceConsumer(address _priceConsumer) public onlyOwner() {
        priceConsumer = IPriceConsumerV3(_priceConsumer);
    }

    // Sets the treasury wallet address
    function setTreasury(address _treasury) public onlyOwner() {
        treasury = payable(_treasury);
    }

    // Gets the number of NFTs
    function nftLength() public view returns (uint) {
        return nftAddresses.length;
    }

    // Lets someone purchase an NFT for BNB
    function instaBuy(address _nft) public payable returns (uint) {
        require(nftInfo[_nft].isEnabled, 'NFT is not enabled.');
        require(nftInfo[_nft].price > 0, 'NFT price is not set.');
        require(msg.value >= priceInBnb(_nft), 'Insufficient BNB sent for purchase.');

        IRugZombieNft nft = IRugZombieNft(_nft);
        require(nftInfo[_nft].maxMints == 0 || nft.totalSupply() < nftInfo[_nft].maxMints, 'Maximum number of NFTs has already been minted.');
        require(nftInfo[_nft].maxMintsPerUser == 0 || nftInfo[_nft].userMintCount[msg.sender] < nftInfo[_nft].maxMintsPerUser, 'You have minted the maximum number of this NFT');

        uint _projectFunds = msg.value;
        uint _toTreasury = _projectFunds.calcPortionFromBasisPoints(5000);
        uint _buyBack = _projectFunds - _toTreasury;

        treasury.transfer(_toTreasury);
        _buyBackAndBurn(_buyBack);

        uint newItemId = nft.reviveRug(msg.sender);
        nftInfo[_nft].userMintCount[msg.sender] += 1;

        if (nftInfo[_nft].salesPerPrice != 0 && (nft.totalSupply() % nftInfo[_nft].salesPerPrice) == 0) {
            nftInfo[_nft].price += nftInfo[_nft].priceIncrease;
        }

        return newItemId;
    }

    // Uses ChainLink Oracle to convert from USD to BNB
    function priceInBnb(address _nft) public view returns(uint256) {
        if (nftInfo[_nft].priceMode == PriceMode.BUSD) {
            return priceConsumer.usdToBnb(nftInfo[_nft].price);
        } else {
            return nftInfo[_nft].price;
        }        
    }

    // Buys and burns zombie
    function _buyBackAndBurn(uint _bnbAmount) private {
        uint256 initialZombieBalance = zmbe.balanceOf(address(this));
        _swapZombieForBnb(_bnbAmount);
        uint256 zombieBoughtBack = zmbe.balanceOf(address(this)) - initialZombieBalance;
        zmbe.transfer(burnAddr, zombieBoughtBack);
    }

    // Buys Zombie with BNB
    function _swapZombieForBnb(uint256 _bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(zmbe);

        // make the swap
        dexRouter.swapExactETHForTokens{value: _bnbAmount} (
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/Context.sol";
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
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRugZombieNft {
    function totalSupply() external view returns (uint256);
    function reviveRug(address _to) external returns(uint);
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

