/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: NONE
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



interface ILastPrice{
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

interface IDecimals{
    function decimals() external view returns (uint8) ;
}
contract ChainlinkToOracle is Ownable{
    
    constructor(){
        isStable[0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = true;//usdc
        isStable[0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = true;//usdt
        isStable[0xdAb529f40E671A1D4bF91361c21bf9f0C9712ab7] = true;//busd
        isStable[0xb8ab048D6744a276b2772dC81e406a4b769A5c3D] = true;//wusd
        isStable[0x692597b009d13C4049a947CAB2239b7d6517875F] = true;//ust
        isStable[0x2e1AD108fF1D8C782fcBbB89AAd783aC49586756] = true;//tusd
        isStable[0xD86b5923F3AD7b585eD81B448170ae026c65ae9a] = true;//iron    
        isStable[0x9aF3b7DC29D3C4B1A5731408B6A9656fA7aC3b72] = true;//pusd
    }

    mapping(address=>bool) public isStable;

    struct OracleItem{
        address oracleAddress;
        uint8 ftokenDecs;
        uint8 oracleDecimals;
    }

    mapping(address=>OracleItem) public priceFeed;


    function changeStable(address _add, bool _bool) external onlyOwner{
        isStable[_add] = _bool;
    }

    function create(address _oracleAddress, address _fToken) external onlyOwner{
        OracleItem memory oracle = OracleItem(_oracleAddress,IDecimals(_fToken).decimals(),IDecimals(_oracleAddress).decimals());
        priceFeed[_fToken] = oracle;
    }

    /**
     * Returns the latest price
     */
     
    function getPrice(address token0, address token1) external view returns (uint price, uint lastUpdate){
      address usd;
      address fToken;
      
      if(isStable[token0]) (usd, fToken) = (token0,token1);
      else (usd, fToken) = (token1,token0);

      OracleItem memory oracle = priceFeed[fToken];
      
      uint8 oracleDecimals = oracle.oracleDecimals;
      uint8 decimalsusd = IDecimals(usd).decimals();
      uint8 decimalsFToken = oracle.ftokenDecs;
      
      (,int answer,,uint time,) = ILastPrice(priceFeed[fToken].oracleAddress).latestRoundData();
      uint fPrice = usd > fToken ? uint(answer)*1e18/10**oracleDecimals*10**decimalsusd/10**decimalsFToken : 1e18*10**oracleDecimals/uint(answer)*10**decimalsFToken/10**decimalsusd;
      return (uint(fPrice),time);
    }
}