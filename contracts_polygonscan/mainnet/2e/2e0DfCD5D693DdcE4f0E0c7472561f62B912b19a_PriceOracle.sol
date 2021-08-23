/**
 *Submitted for verification at polygonscan.com on 2021-08-23
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/interfaces/OZ_IERC20.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZ_IERC20 {
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


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function HOLDING_ADDRESS() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function destroy(uint value) external returns(bool);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function handleEarnings() external returns(uint amount);
}


// File contracts/DeFi/uniswapv2/libraries/UQ112x112.sol

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/core/PriceOracle.sol




contract PriceOracle is Ownable{
    using UQ112x112 for uint224;
    uint8 public constant RESOLUTION = 112;
    struct uq112x112 {
        uint224 _x;
    }

    struct oracle {
        uint[2] price0Cumulative;
        uint[2] price1Cumulative;
        uint32[2] timeStamp;
        uint8 index; // 0 or 1
    }

    mapping(address => oracle) public priceOracles; // Maps a pair address to a price oracle


    uint public priceValidStart;
    uint public priceValidEnd;

    /**
    * @dev emitted when owner calls setTimingReq
    * @param priceValidStart how long it takes for a price to become valid from when it is logged
    * @param priceValidEnd how long it takes for the price to expire from when it is logged
    **/
    event priceWindowChanged(uint priceValidStart, uint priceValidEnd);



    constructor(uint _priceValidStart, uint _priceValidEnd) {
        _checkSuggestedPriceWindow(_priceValidStart, _priceValidEnd);
        priceValidStart = _priceValidStart;
        priceValidEnd = _priceValidEnd;
    }

    /**
    * @dev called by owner to change the price valid window
    * @param _priceValidStart how many seconds it takes for the price to become valid
    * @param _priceValidEnd hwo many seconds it takes for a price to expire from when it is logged
    **/
    function setTimingReq(uint _priceValidStart, uint _priceValidEnd) external onlyOwner{
        _checkSuggestedPriceWindow(_priceValidStart, _priceValidEnd);
        priceValidStart = _priceValidStart; 
        priceValidEnd = _priceValidEnd;
        emit priceWindowChanged(priceValidStart, priceValidEnd);
    }

    function _checkSuggestedPriceWindow(uint _priceValidStart, uint _priceValidEnd) internal pure {
        require(_priceValidStart >= 300, "Price maturity must be greater than 300 seconds");
        require(_priceValidStart <= 3600, "Price maturity must be less than 3600 seconds");
        require(_priceValidStart * 2 == _priceValidEnd, "Price expiration must be equal to 2x price maturity");
    }

    /** 
    * @dev called to get the current prices for a swap pair, if not valid, then it logs the current price so that it can become valid
    * @param pairAddress the pair address caller wants the pair prices for
    * @return price0Average , price1Average, timeTillValid 3 uints the average price for asset 0 to asset 1 and vice versa, and the timeTillValid which is how many seconds until prices are valid
    **/
    function getPrice(address pairAddress) public returns (uint price0Average, uint price1Average, uint timeTillValid) {
        uint8 index = priceOracles[pairAddress].index;
        uint8 otherIndex;
        uint8 tempIndex;
        if (index == 0){
            otherIndex = 1;
        }
        else {
            otherIndex = 0;
        }
        //Check if current index is expired
        if (priceOracles[pairAddress].timeStamp[index] + priceValidEnd < currentBlockTimestamp()) {
            (
                priceOracles[pairAddress].price0Cumulative[index],
                priceOracles[pairAddress].price1Cumulative[index],
                priceOracles[pairAddress].timeStamp[index]
            ) = currentCumulativePrices(pairAddress);   
            //Check if other index isnt expired
            if(priceOracles[pairAddress].timeStamp[otherIndex] + priceValidEnd > currentBlockTimestamp()){
                //If it hasn't expired, switch the indexes
                tempIndex = index;
                index = otherIndex;
                otherIndex = tempIndex;
            }
            //Now look at the current index, and figure out how long it is until it is valid
            require(priceOracles[pairAddress].timeStamp[index] + priceValidEnd > currentBlockTimestamp(), "Logic error index assigned incorrectly!");
            if (priceOracles[pairAddress].timeStamp[index] + priceValidStart > currentBlockTimestamp()){
                //Current prices have not matured, so wait until they do
                timeTillValid = (priceOracles[pairAddress].timeStamp[index] + priceValidStart) - currentBlockTimestamp();
            }
            else{
                timeTillValid = 0;
            } 
        }
        else {
            if (priceOracles[pairAddress].timeStamp[index] + priceValidStart > currentBlockTimestamp()){
                //Current prices have not matured, so wait until they do
                timeTillValid = (priceOracles[pairAddress].timeStamp[index] + priceValidStart) - currentBlockTimestamp();
            }
            else{
                timeTillValid = 0;
            } 
            if(priceOracles[pairAddress].timeStamp[otherIndex] + priceValidEnd < currentBlockTimestamp() && priceOracles[pairAddress].timeStamp[index] + priceValidStart < currentBlockTimestamp()){
                //If the other index is expired, and the current index is valid, then set other index = to current info
                (
                priceOracles[pairAddress].price0Cumulative[otherIndex],
                priceOracles[pairAddress].price1Cumulative[otherIndex],
                priceOracles[pairAddress].timeStamp[otherIndex]
            ) = currentCumulativePrices(pairAddress);
            }
        }
        if (timeTillValid == 0){//If prices are valid, set price0Average, and price1Average
            (uint256 price0Cumulative, uint256 price1Cumulative, uint32 timeStamp) =
            currentCumulativePrices(pairAddress);
            uint32 timeElapsed = timeStamp - priceOracles[pairAddress].timeStamp[index];
            price0Average = uint256((10**18 *uint224((price0Cumulative - priceOracles[pairAddress].price0Cumulative[index]) /timeElapsed)) / 2**112);
            price1Average =  uint256((10**18 *uint224((price1Cumulative - priceOracles[pairAddress].price1Cumulative[index]) /timeElapsed)) / 2**112);
        }
    }

    /**
    * @dev get the current timestamp from the price oracle, as well as the alternate timestamp
    * @param pairAddress the pair address you want to check the timestamps for
    * @return currentTimestamp otherTimestamp, the current and the alternate timestamps
    **/
    function getOracleTime(address pairAddress) external view returns(uint currentTimestamp, uint otherTimestamp){
        oracle memory tmp = priceOracles[pairAddress];
        if (tmp.index == 0){
            currentTimestamp = tmp.timeStamp[0];
            otherTimestamp = tmp.timeStamp[1];
        }
        else {
            currentTimestamp = tmp.timeStamp[1];
            otherTimestamp = tmp.timeStamp[0];
        }
    }

    /**
    * @dev used to calculate the minimum amount to recieve from a swap
    * @param from the token you want to swap for another token
    * @param slippage number from 0 to 100 that represents a percent, will revert if greater than 100
    * @param amount the amount of from tokens you want swapped into the other token
    * @param pairAddress the pairAddress you want to use for swapping
    * @return minAmount timeTillValid the minimum amount to expect for a trade, and the time until the price is valid. If timeTillValid is greater than 0 DO NOT USE THE minAmount variable, it will be 0
    **/
    function calculateMinAmount(
        address from,
        uint256 slippage,
        uint256 amount,
        address pairAddress
    ) public returns (uint minAmount, uint timeTillValid) {
        require(pairAddress != address(0), "Pair does not exist!");
        require(slippage <= 100, "Slippage should be a number between 0 -> 100");
        (,, timeTillValid) = getPrice(pairAddress);
        if (timeTillValid == 0){
            uint8 index = priceOracles[pairAddress].index;
            uint256 TWAP;
            IUniswapV2Pair Pair = IUniswapV2Pair(pairAddress);
            (uint256 price0Cumulative, uint256 price1Cumulative, uint32 timeStamp) =
                currentCumulativePrices(pairAddress);
            uint32 timeElapsed = timeStamp - priceOracles[pairAddress].timeStamp[index];
            if (Pair.token0() == from) {
                TWAP = uint256((10**18 *uint224((price0Cumulative - priceOracles[pairAddress].price0Cumulative[index]) /timeElapsed)) / 2**112);
                minAmount = (slippage * TWAP * amount) / 10**20; //Pair price must be within slippage req
            } else {
                TWAP = uint256((10**18 *uint224((price1Cumulative - priceOracles[pairAddress].price1Cumulative[index]) /timeElapsed)) / 2**112);
                minAmount = (slippage * TWAP * amount) / 10**20; //Pair price must be within slippage req
            }
        }
    }

    /** 
    * @dev internal function used to make the block.timestamp into a uint32
    **/
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    /**
    * @dev produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    * @param pair the pair address you want the prices for
    **/
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
            IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) *
                timeElapsed;
            price1Cumulative +=
                uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) *
                timeElapsed;
        }
    }

}