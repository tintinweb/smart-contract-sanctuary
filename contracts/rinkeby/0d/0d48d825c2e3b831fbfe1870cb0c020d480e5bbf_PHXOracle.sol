/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// File: contracts/PhoenixModules/modules/Operator.sol

pragma solidity =0.5.16;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * each operator can be granted exclusive access to specific functions.
 *
 */
contract Operator {
    mapping(uint256=>address) internal _operators;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator,uint256 indexed index);
    constructor()  public{
        _operators[0] = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _operators[1] = tx.origin;
        emit OriginTransferred(address(0), tx.origin);
    }
    /**
     * @dev modifier, Only indexed operator can be granted exclusive access to specific functions. 
     *
     */
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _operators[0];
    }
        /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Operator: caller is not the owner");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == _operators[2], "Operator: caller is not the manager");
        _;
    }
    modifier onlyOrigin() {
        require(msg.sender == _operators[1], "Operator: caller is not the origin");
        _;
    }
    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _operators[0];
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_operators[0], address(0));
        _operators[0] = address(0);
    }
    function renounceOrigin() public onlyOrigin {
        emit OriginTransferred(_operators[1], address(0));
        _operators[1] = address(0);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function transferOrigin(address newOrigin) public onlyOrigin {
        require(newOrigin != address(0), "Operator: new origin is the zero address");
        emit OwnershipTransferred(_operators[1], newOrigin);
        _operators[1] = newOrigin;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Operator: new owner is the zero address");
        emit OwnershipTransferred(_operators[0], newOwner);
        _operators[0] = newOwner;
    }
    modifier onlyOperator(uint256 index) {
        require(_operators[index] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator2(uint256 index1,uint256 index2) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender,"Operator: caller is not the eligible Operator");
        _;
    }
    modifier onlyOperator3(uint256 index1,uint256 index2,uint256 index3) {
        require(_operators[index1] == msg.sender || _operators[index2] == msg.sender || _operators[index3] == msg.sender,
            "Operator: caller is not the eligible Operator");
        _;
    }
    function setManager(address newManager) public onlyOwner{
        emit OperatorTransferred(_operators[2], newManager,2);
        _operators[2] = newManager;
    }
    /**
     * @dev modify indexed operator by owner. 
     *
     */
    function setOperator(uint256 index,address newAddress)public onlyOperator2(0,1) {
        require(index>2, "Index must greater than 2");
        emit OperatorTransferred(_operators[index], newAddress,index);
        _operators[index] = newAddress;
    }
    function getOperator(uint256 index)public view returns (address) {
        return _operators[index];
    }
}

// File: contracts/PHXOracle.sol

pragma solidity =0.5.16;

contract PHXOracle is Operator {
    mapping(uint256 => uint256) internal priceMap;
    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param price the Asset's price
      */    
    function setPrice(address asset,uint256 price) public onlyOperator(3) {
        priceMap[uint256(asset)] = price;

    }
    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param price the underlying's price
      */  
    function setUnderlyingPrice(uint256 underlying,uint256 price) public onlyOperator(3) {
        require(underlying>0 , "underlying cannot be zero");
        priceMap[underlying] = price;
    }
    /**
    * @notice set a group of prices for assets and a group of prices for underlying
    * @dev function to set a group of prices for assets and a group of prices for underlying
    * @param assets a set of asset for which to set the price
    * @param assetPrices  a set of the Asset's price
    * @param underlyings a set of underlyings for which to set the price
    * @param ulPrices  a set of the underlyings's price
    */    
    function setPriceAndUnderlyingPrice(address[] memory assets,uint256[] memory assetPrices,uint256[] memory underlyings,uint256[] memory ulPrices) public onlyOperator(3) {
        require(assets.length == assetPrices.length,"assets and assetPrices are not of the same length");
        require(underlyings.length == ulPrices.length,"underlyings and ulPrices are not of the same length");
        uint i = 0;
        for (;i<assets.length;i++) {
            priceMap[uint256(assets[i])] = assetPrices[i];
        }
        for (i = 0;i<underlyings.length;i++) {
            priceMap[underlyings[i]] = ulPrices[i];
        }
    }
    /**
      * @notice set price of an options token sell price
      * @dev function to set an options token sell price
      * @param optoken options token for which to set the sell price
      * @param price the options token sell price
      */     
    function setSellOptionsPrice(address optoken,uint256 price) public onlyOperator(3) {
        uint256 key = uint256(optoken)*10+1;
        priceMap[key] = price;
    }
    /**
      * @notice set price of an options token buy price
      * @dev function to set an options token buy price
      * @param optoken options token for which to set the buy price
      * @param price the options token buy price
      */      
    function setBuyOptionsPrice(address optoken,uint256 price) public onlyOperator(3) {
        uint256 key = uint256(optoken)*10+2;
        priceMap[key] = price;
    }
    /**
      * @notice set price of a group of option tokens buy and sell prices
      * @dev function to set price of a group of option tokens buy and sell prices
      * @param optokens a group of option tokens for which to set the buy and sell price
      * @param buyPrices a group of buy prices
      * @param SellPrices a group of sell prices
      */    
    function setOptionsBuyAndSellPrice(address[] memory optokens,uint256[] memory buyPrices,uint256[] memory SellPrices) public onlyOperator(3) {
        require(optokens.length == buyPrices.length,"optokens and buyPrices are not of the same length");
        require(optokens.length == SellPrices.length,"optokens and SellPrices are not of the same length");
        uint i=0;
        for (; i<optokens.length; i++) {
            uint256 sellkey = uint256(optokens[i])*10+1;
            priceMap[sellkey] = SellPrices[i];
        }
        for (i=0; i<optokens.length; i++) {
            uint256 buykey = uint256(optokens[i])*10+2;
            priceMap[buykey] = buyPrices[i];
        }
    }
    /**
  * @notice retrieves price of an asset
  * @dev function to get price for an asset
  * @param asset Asset for which to get the price
  * @return uint mantissa of asset price (scaled by 1e8) or zero if unset or contract paused
  */
    function getPrice(address asset) public view returns (uint256) {
        return _getPriceInfo(uint256(asset));
    }
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        return _getPriceInfo(underlying);
    }
    function getAssetAndUnderlyingPrice(address asset,uint256 underlying) public view returns (uint256,uint256) {
        return (_getPriceInfo(uint256(asset)),_getPriceInfo(underlying));
    }
    function getPrices(uint256[]memory assets) public view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = new uint256[](len);
        for (uint i=0;i<len;i++){
            prices[i] = _getPriceInfo(assets[i]);
        }
        return prices;
    }
    function getSellOptionsPrice(address oToken) public view returns (uint256) {
        uint256 key = uint256(oToken)*10+1;
        return _getPriceInfo(key);

    }
    function getBuyOptionsPrice(address oToken) public view returns (uint256) {
        uint256 key = uint256(oToken)*10+2;
        return _getPriceInfo(key);
    }
    function _getPriceInfo(uint256 key) internal view returns (uint256) {
        return priceMap[key];
    }

/*
    function getPriceDetail(address asset) public view returns (uint256,uint256) {
        return _getPriceDetail(uint256(asset));
    }
    function getUnderlyingPriceDetail(uint256 underlying) public view returns (uint256,uint256) {
        return _getPriceDetail(underlying);
    }

    function getSellOptionsPriceDetail(address oToken) public view returns (uint256,uint256) {
        uint256 key = uint256(oToken)*10+1;
        return _getPriceDetail(key);

    }
    function getBuyOptionsPriceDetail(address oToken) public view returns (uint256,uint256) {
        uint256 key = uint256(oToken)*10+2;
        return _getPriceDetail(key);
    }
    function _getPriceDetail(uint256 key) internal view returns (uint256,uint256) {
        return (priceMap[key].price,priceMap[key].inptutTime);
    }
    */
}