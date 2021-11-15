/**
 *Submitted for verification at snowtrace.io on 2021-11-15
*/

// File: contracts/modules/IERC20.sol

pragma solidity >=0.7.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
     * EXTERNAL FUNCTION
     *
     * @dev change token name
     * @param _name token name
     * @param _symbol token symbol
     *
     */
    function changeTokenName(string calldata _name, string calldata _symbol)external;

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

// File: contracts/defrostOracle/AggregatorV3Interface.sol

pragma solidity >=0.7.0 <0.8.0;
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// File: contracts/modules/multiSignatureClient.sol

pragma solidity >=0.7.0 <0.8.0;

interface IMultiSignature{
    function getValidSignature(bytes32 msghash,uint256 lastIndex) external view returns(uint256);
}
contract multiSignatureClient{
    uint256 private constant multiSignaturePositon = uint256(keccak256("org.defrost.multiSignature.storage"));
    constructor(address multiSignature) {
        require(multiSignature != address(0),"multiSignatureClient : Multiple signature contract address is zero!");
        saveValue(multiSignaturePositon,uint256(multiSignature));
    }    
    function getMultiSignatureAddress()public view returns (address){
        return address(getValue(multiSignaturePositon));
    }
    modifier validCall(){
        checkMultiSignature();
        _;
    }
    function checkMultiSignature() internal {
        uint256 value;
        assembly {
            value := callvalue()
        }
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, address(this),value,msg.data));
        address multiSign = getMultiSignatureAddress();
        uint256 index = getValue(uint256(msgHash));
        uint256 newIndex = IMultiSignature(multiSign).getValidSignature(msgHash,index);
        require(newIndex > index, "multiSignatureClient : This tx is not aprroved");
        saveValue(uint256(msgHash),newIndex);
    }
    function saveValue(uint256 position,uint256 value) internal 
    {
        assembly {
            sstore(position, value)
        }
    }
    function getValue(uint256 position) internal view returns (uint256 value) {
        assembly {
            value := sload(position)
        }
    }
}

// File: contracts/modules/proxyOwner.sol

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title  proxyOwner Contract

 */

contract proxyOwner is multiSignatureClient{
    bytes32 private constant proxyOwnerPosition  = keccak256("org.defrost.Owner.storage");
    bytes32 private constant proxyOriginPosition0  = keccak256("org.defrost.Origin.storage.0");
    bytes32 private constant proxyOriginPosition1  = keccak256("org.defrost.Origin.storage.1");
    uint256 private constant oncePosition  = uint256(keccak256("org.defrost.Once.storage"));
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OriginTransferred(address indexed previousOrigin, address indexed newOrigin);
    constructor(address multiSignature,address origin0,address origin1) multiSignatureClient(multiSignature) {
        require(multiSignature != address(0) &&
        origin0 != address(0)&&
        origin1 != address(0),"proxyOwner : input zero address");
        _setProxyOwner(msg.sender);
        _setProxyOrigin(address(0),origin0);
        _setProxyOrigin(address(0),origin1);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */

    function transferOwnership(address _newOwner) public onlyOwner
    {
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        emit OwnershipTransferred(owner(),_newOwner);
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function owner() public view returns (address _owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            _owner := sload(position)
        }
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require (isOwner(),"proxyOwner: caller must be the proxy owner and a contract and not expired");
        _;
    }
    function transferOrigin(address _oldOrigin,address _newOrigin) public onlyOrigin
    {
        _setProxyOrigin(_oldOrigin,_newOrigin);
    }
    function _setProxyOrigin(address _oldOrigin,address _newOrigin) internal 
    {
        emit OriginTransferred(_oldOrigin,_newOrigin);
        (address _origin0,address _origin1) = txOrigin();
        if (_origin0 == _oldOrigin){
            bytes32 position = proxyOriginPosition0;
            assembly {
                sstore(position, _newOrigin)
            }
        }else if(_origin1 == _oldOrigin){
            bytes32 position = proxyOriginPosition1;
            assembly {
                sstore(position, _newOrigin)
            }            
        }else{
            require(false,"OriginTransferred : old origin is illegal address!");
        }
    }
    function txOrigin() public view returns (address _origin0,address _origin1) {
        bytes32 position0 = proxyOriginPosition0;
        bytes32 position1 = proxyOriginPosition1;
        assembly {
            _origin0 := sload(position0)
            _origin1 := sload(position1)
        }
    }
    modifier originOnce() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        uint256 key = oncePosition+uint32(msg.sig);
        require (getValue(key)==0, "proxyOwner : This function must be invoked only once!");
        saveValue(key,1);
        _;
    }
    function isOrigin() public view returns (bool){
        (address _origin0,address _origin1) = txOrigin();
        return  msg.sender == _origin0 || msg.sender == _origin1;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == owner() && isContract(msg.sender);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOrigin() {
        require (isOrigin(),"proxyOwner: caller is not the tx origin!");
        checkMultiSignature();
        _;
    }
    modifier OwnerOrOrigin(){
        if (isOwner()){
        }else if(isOrigin()){
            checkMultiSignature();
        }else{
            require(false,"proxyOwner: caller is not owner or origin");
        }
        _;
    }
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: contracts/defrostOracle/chainLinkOracle.sol

pragma solidity >=0.7.0 <0.8.0;



contract chainLinkOracle is proxyOwner {
    mapping(uint256 => AggregatorV3Interface) internal assetsMap;
    mapping(uint256 => uint256) internal decimalsMap;
    mapping(uint256 => uint256) internal assetPriceMap;
    event SetAssetsAggregator(address indexed sender,uint256 asset,address aggeregator);
    constructor(address multiSignature,address origin0,address origin1)
    proxyOwner(multiSignature,origin0,origin1) {
    } 
    /**
      * @notice set price of an asset
      * @dev function to set price for an asset
      * @param asset Asset for which to set the price
      * @param aggergator the Asset's aggergator
      */    
    function setAssetsAggregator(address asset,address aggergator) public onlyOrigin {
        _setAssetsAggregator(asset,aggergator);
    }
    function _setAssetsAggregator(address asset,address aggergator) internal {
        assetsMap[uint256(asset)] = AggregatorV3Interface(aggergator);
        uint8 _decimals = 18;
        if (asset != address(0)){
            _decimals = IERC20(asset).decimals();
        }
        uint8 priceDecimals = AggregatorV3Interface(aggergator).decimals();
        decimalsMap[uint256(asset)] = 36-priceDecimals-_decimals;
        emit SetAssetsAggregator(msg.sender,uint256(asset),aggergator);
    }
    /**
      * @notice set price of an underlying
      * @dev function to set price for an underlying
      * @param underlying underlying for which to set the price
      * @param aggergator the underlying's aggergator
      */  
    function setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) public onlyOrigin {
        _setUnderlyingAggregator(underlying,aggergator,_decimals);
    }
    function _setUnderlyingAggregator(uint256 underlying,address aggergator,uint256 _decimals) internal{
        require(underlying>0 , "underlying cannot be zero");
        assetsMap[underlying] = AggregatorV3Interface(aggergator);
        uint8 priceDecimals = AggregatorV3Interface(aggergator).decimals();
        decimalsMap[underlying] = 36-priceDecimals-_decimals;
        emit SetAssetsAggregator(msg.sender,underlying,aggergator);
    }
    function getAssetsAggregator(address asset) public view returns (address,uint256) {
        return (address(assetsMap[uint256(asset)]),decimalsMap[uint256(asset)]);
    }
    function getUnderlyingAggregator(uint256 underlying) external view returns (address,uint256) {
        return (address(assetsMap[underlying]),decimalsMap[underlying]);
    }
    function _getPrice(uint256 underlying) internal view returns (bool,uint256) {
        AggregatorV3Interface assetsPrice = assetsMap[underlying];
        if (address(assetsPrice) != address(0)){
            (, int price,,,) = assetsPrice.latestRoundData();
            uint256 tokenDecimals = decimalsMap[underlying];
            return (true,uint256(price)*(10**tokenDecimals));
        }else {
            uint256 price = assetPriceMap[underlying];
            if (price > 0){
                return (true,price);
            }
            return (false,0);
        }
    }
    function getUnderlyingPrice(uint256 underlying) public view returns (uint256) {
        (,uint256 price) = _getPrice(underlying);
        return price;
    }
    function getPriceInfo(address token) public virtual view returns (bool,uint256){
        return _getPrice(uint256(token));
    }
    function getPrice(address token) public view returns (uint256) {
        (,uint256 price) = getPriceInfo(token);
        return price;
    }
    function getPrices(address[]calldata assets) external view returns (uint256[]memory) {
        uint256 len = assets.length;
        uint256[] memory prices = new uint256[](len);
        for (uint i=0;i<len;i++){
            prices[i] = getPrice(assets[i]);
        }
        return prices;
    }
}

// File: contracts/uniswap/IUniswapV2Pair.sol

pragma solidity >=0.7.0 <0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

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
}

// File: contracts/defrostOracle/swapOracle.sol

pragma solidity >=0.7.0 <0.8.0;


abstract contract swapOracle is chainLinkOracle {
    function getUniswapPairPrice(address pair) public view returns (bool,uint256) {
        IUniswapV2Pair upair = IUniswapV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = upair.getReserves();
        (bool have0,uint256 price0) = _getPrice(uint256(upair.token0()));
        (bool have1,uint256 price1) = _getPrice(uint256(upair.token1()));
        uint256 totalAssets = 0;
        if(have0 && have1){
            price0 *= reserve0;  
            price1 *= reserve1;
            uint256 tol = price1/20;  
            bool inTol = (price0 < price1+tol && price0 > price1-tol);
            totalAssets = price0+price1;
            uint256 total = upair.totalSupply();
            if (total == 0){
                return (false,0);
            }
            return (inTol,totalAssets/total);
        }else{
            return (false,0);
        }
    }
    function getPriceInfo(address token) public override view returns (bool,uint256){
        (bool success,) = token.staticcall(abi.encodeWithSignature("getReserves()"));
        if(success){
            return getUniswapPairPrice(token);
        }else{
            return _getPrice(uint256(token));
        }
    }
}

// File: contracts/defrostOracle/avaxSwapOracle.sol

pragma solidity >=0.7.0 <0.8.0;

contract avaxSwapOracle is swapOracle {
    constructor(address multiSignature,address origin0,address origin1)
    chainLinkOracle(multiSignature,origin0,origin1) {
        assetPriceMap[uint256(0x1337BedC9D22ecbe766dF105c9623922A27963EC)] = 1e18;
        _setAssetsAggregator(address(0),0x0A77230d17318075983913bC2145DB16C7366156);
        _setAssetsAggregator(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7,0x0A77230d17318075983913bC2145DB16C7366156);//wavax
        //_setAssetsAggregator(ALPHA ,0x7B0ca9A6D03FE0467A31Ca850f5bcA51e027B3aF);
        _setAssetsAggregator(0x63a72806098Bd3D9520cC43356dD78afe5D386D9 ,0x3CA13391E9fb38a75330fb28f8cc2eB3D9ceceED);//aave
        _setAssetsAggregator(0x50b7545627a5162F82A992c33b87aDc75187B218 ,0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);//wbtc
        //_setAssetsAggregator(BUSD ,0x827f8a0dC5c943F7524Dda178E2e7F275AAd743f);
        //_setAssetsAggregator(CAKE ,0x79bD0EDd79dB586F22fF300B602E85a662fc1208);
        //_setAssetsAggregator(CHF ,0x3B37950485b450edF90cBB85d0cD27308Af4AB9A);
        _setAssetsAggregator(0xd586E7F844cEa2F87f50152665BCbc2C279D8d70 ,0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300); //dai
        //_setAssetsAggregator(EPS ,0xB3ace8467271D12D8216818Dd2E8F84Cb6F9c212);
        _setAssetsAggregator(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB ,0x976B3D034E162d8bD72D6b9C989d545b839003b0);//weth
        _setAssetsAggregator(0x5947BB275c521040051D82396192181b413227A3 ,0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a); //link
        //_setAssetsAggregator(LUNA ,0x12Fe6A4DF310d4aD9887D27D4fce45a6494D4a4a);
        //_setAssetsAggregator(MDX ,0x6131b26D4aD63004df7540a3B3031072273f003e);
        //_setAssetsAggregator(MIM ,0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
        //_setAssetsAggregator(OHM ,0x0c40Be7D32311b36BE365A2A220243B8A651df5E);
        _setAssetsAggregator(0xCE1bFFBD5374Dac86a2893119683F4911a2F7814 ,0x4F3ddF9378a4865cf4f28BE51E10AECb83B7daeE);//spell
        //_setAssetsAggregator(SUSHI ,0x449A373A090d8A1e5F74c63Ef831Ceff39E94563);
        //_setAssetsAggregator(TRY ,0xA61bF273688Ea095b5e4c11f1AF5E763F7aEEE91);
        //_setAssetsAggregator(TUSD ,0x9Cf3Ef104A973b351B2c032AA6793c3A6F76b448);
        _setAssetsAggregator(0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580 ,0x9a1372f9b1B71B3A5a72E092AE67E172dBd7Daaa); //uni
        _setAssetsAggregator(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664 ,0xF096872672F44d6EBA71458D74fe67F9a77a23B9);//usdc
        _setAssetsAggregator(0xc7198437980c041c805A1EDcbA50c1Ce5db95118 ,0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);//usdt
    }
}