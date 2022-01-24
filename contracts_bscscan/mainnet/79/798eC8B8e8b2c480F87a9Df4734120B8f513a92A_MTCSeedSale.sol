pragma solidity >= 0.5.17;

import "./math.sol";
import "./IERC20.sol";

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library Address {
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

library EnumerableSet {

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {// Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract MTCSeedSale is math{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;
	
    function() external payable{}
	address manager;
	address LiquidityReserve;
	address _MTCAddr = 0x5F1D2cfDEB097B83eD2f35Cf3E827DE2b700F05a;
    address _treasury;
	uint swapMaximum = 10000 * 10 ** uint(18);
	uint swapMinimum = 100 * 10 ** uint(18);
	uint SeedSalePrice = 2000; //1BNB = 2000MTC | 1MTC = 0.0005BNB
	uint SeedSaleAmount = 0;
	uint MaxSeedSaleAmount = 100000000 * 10 ** uint(18);
	uint BounsSeedSale = 10000000 * 10 ** uint(18);
	uint256 public ClosingTime = 1646063999; //Closing at Mon Feb 28 2022 23:59:59 UTC+0800.
	
    struct WhitelistInfo {
        uint _buyAmount;
    }
	
    mapping(address => WhitelistInfo) public whitelistInfos;

    event SeedSaleMTC(uint _amountsIn, uint _amountsOut, bool result);
	
    constructor() public {
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager, "Not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == manager, "Not superManager");
        manager = _new_manager;
    }

    function withdraw() external onlyManager{
        (msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address tokenAddr) external onlyManager{
        require(tokenAddr != MTCAddr(), "MTC Seed Sale : MTC cannot be taken away.");
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

    //----------------Whitelist address----------------------------
	
    function addWhitelistBatch(address[] memory _wAddrs) public onlyManager returns (bool) {
        uint _addressAmount = _wAddrs.length;
        for (uint i = 0; i < _addressAmount; i++){
			addWhitelist(_wAddrs[i]);
        }
        return true;
    }

    function addWhitelistManager(address _wAddrs) external onlyManager {
        require(_wAddrs != address(0), "MTC Seed Sale : token is the zero address");
            addWhitelist(_wAddrs);
    }

    function addWhitelist(address _wAddrs) internal returns(bool) {
        require(_wAddrs != address(0), "MTC Seed Sale : token is the zero address");
        whitelistInfos[_wAddrs]._buyAmount = 0;
        return EnumerableSet.add(_whitelist, _wAddrs);
    }

    function delWhitelist(address _delAddrs) internal returns(bool) {
        require(_delAddrs != address(0), "MTC Seed Sale : token is the zero address");
        return EnumerableSet.remove(_whitelist, _delAddrs);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _Addrs) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _Addrs);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLength() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    //---------------------------------------------------------------------------------
	
    function isClosed() public view returns (bool) {
        return now >= ClosingTime;
    }

	function LRAddr() public view returns(address){
        require(LiquidityReserve != address(0), "It's a null address");
        return LiquidityReserve;
    }
	
	function setLRAddr(address addr) internal onlyManager{
        LiquidityReserve = addr;
    }

	function MTCAddr() public view returns(address){
        require(_MTCAddr != address(0), "It's a null address");
        return _MTCAddr;
    }

	function Treasury() public view returns(address){
        require(_treasury != address(0), "It's a null address");
        return _treasury;
    }
	
	function setTreasury(address addr) public onlyManager{
        _treasury = addr;
    }
	
	function getswapMaximum() public view returns (uint256) {
        return swapMaximum;
    }
	
	function getswapMinimum() public view returns (uint256) {
        return swapMinimum;
    }
	
	function setswapMinimum(uint _Amounts) public onlyManager{
        swapMinimum = _Amounts * 10 ** uint(18);
    }
	
	function getSeedSalePrice() public view returns (uint256) {
        return SeedSalePrice;
    }

	function getSeedSaleAmount() public view returns (uint256) {
        return SeedSaleAmount;
    }

	function getMaxSeedSaleAmount() public view returns (uint256) {
        return MaxSeedSaleAmount;
    }

	function getListbuyAmount(address inputAddr) public view returns (uint256) {
        return whitelistInfos[inputAddr]._buyAmount;
    }

	//--Swap Exact BNB to MTC SeedSale--//
    function SeedSale() external payable{
		require(isWhitelist(msg.sender), "MTC Seed Sale : This address is not in Whitelist.");
		require(!isClosed(), "MTC Seed Sale : Seed sale closed.");
		uint _tradeAmount = msg.value;
		require(SeedSaleAmount.add(_tradeAmount) <= MaxSeedSaleAmount, "MTC Seed Sale : Sold out.");
		require(_tradeAmount >= swapMinimum, "MTC Seed Sale : Subscription amount is too low.");
		require(_tradeAmount.add(whitelistInfos[msg.sender]._buyAmount) <= swapMaximum, "MTC Seed Sale : Subscription amount is is too high.");

		uint256 _tokenAmountsOut = _tradeAmount.mul(SeedSalePrice);
		if(SeedSaleAmount <= BounsSeedSale){
			uint _BounsAmount = _tokenAmountsOut.div(10);
			_tokenAmountsOut = _tokenAmountsOut.add(_BounsAmount);
		}
		require(IERC20(MTCAddr()).transfer(msg.sender, _tokenAmountsOut));
		SeedSaleAmount = SeedSaleAmount.add(_tradeAmount);
		Treasury().toPayable().transfer(_tradeAmount);
		whitelistInfos[msg.sender]._buyAmount = whitelistInfos[msg.sender]._buyAmount.add(_tradeAmount);
		emit SeedSaleMTC(_tradeAmount, _tokenAmountsOut, true);
    }

	//--Manager only--//
	function TransferMTCtoLR() public onlyManager{
		require(isClosed(), "MTC Seed Sale : Seed sale deadline has not yet arrived.");
		uint _thisTokenBalance = IERC20(MTCAddr()).balanceOf(address(this));
		require(IERC20(MTCAddr()).transfer(LRAddr(), _thisTokenBalance));
    }
	
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}