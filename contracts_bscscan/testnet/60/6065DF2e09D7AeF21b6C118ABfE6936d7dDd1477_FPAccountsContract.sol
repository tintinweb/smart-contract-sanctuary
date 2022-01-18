pragma solidity >= 0.5.17;

import "./math.sol";
import "./IERC20.sol";

contract Manager{
    address public superManager = 0xE34BdA906dDfa623a388bCa0BD343B764187f325;
    address public manager;

    constructor() public{
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager || msg.sender == superManager, "Is not manager");
        _;
    }

    function changeManager(address _new_manager) public {
        require(msg.sender == superManager, "Is not superManager");
        manager = _new_manager;
    }

    function withdraw() external onlyManager{
        (msg.sender).transfer(address(this).balance);
    }

    function withdrawfrom(uint amount) external onlyManager{
	    require(address(this).balance >= amount, "Insufficient balance");
        (msg.sender).transfer(amount);
    }

    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
}

library useDecimal{
    using uintTool for uint;

    function m278(uint n) internal pure returns(uint){
        return n.mul(278)/1000;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
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

interface ISwap{
    function getOracle() external view returns (uint[] memory);
}

contract cFPAccountsContract is Manager{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

	uint public RegMTC = 1000 * 10 ** uint(18);
	uint public RegFPD = 10000 * 10 ** uint(18);

    address _dexAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;     //PancakeRouter address.
	address _secretary = 0x3C7Ba96F1F62081Fcb7AF0bFF4583d198ed660d6;   //Secretary address.
    address _MTCAddr = 0x4603b8d2e98B8Fbafe8A0CDe4F4381bBAB345c8b;     //MTC token contract address.
    address _FPDAddr = 0xa42bDcdfb8c717a9E8b58131640F2661Bf81620E;     //FPD token contract address.
	
	
	function() external payable{}

	function DexAddr() public view returns(address){
        require(_dexAddr != address(0), "It's a null address");
        return _dexAddr;
    }
	
	function setDexAddr(address addr) public onlyManager{
        _dexAddr = addr;
    }

	function Secretary() public view returns(address){
        require(_secretary != address(0), "It's a null address");
        return _secretary;
    }
	
	function setSecretary(address addr) public onlyManager{
        _secretary = addr;
    }

	function MTCAddr() public view returns(address){
        require(_MTCAddr != address(0), "It's a null address");
        return _MTCAddr;
    }
	
	function setMTCAddr(address addr) public onlyManager{
        _MTCAddr = addr;
    }

	function FPDAddr() public view returns(address){
        require(_FPDAddr != address(0), "It's a null address");
        return _FPDAddr;
    }
	
	function setFPDAddr(address addr) public onlyManager{
        _FPDAddr = addr;
    }

    function setRegGift(uint amountMTC, uint amountFPD) public onlyManager{
        RegMTC = amountMTC * 10 ** uint(18);
        RegFPD = amountFPD * 10 ** uint(18);
    }

	function regCitizens() public view returns(uint256){
        return EnumerableSet.length(_whitelist);
    }

    modifier onlySecretary{
        require(msg.sender == manager || msg.sender == Secretary(), "You are not Secretary.");
        _;
    }

    function SetupAll(address _sDEXAddr, address _sSecretaryAddr, address _sMTCAddr, address _sFPDAddr) public onlyManager{
        setDexAddr(_sDEXAddr);
		setSecretary(_sSecretaryAddr);
		setMTCAddr(_sMTCAddr);
		setFPDAddr(_sFPDAddr);
    }
    //----------------Whitelist Token----------------------------
    function addWhitelistManager(address _addToken)  external onlyManager {
        require(_addToken != address(0), "Freeport: token is the zero address");
            addWhitelist(_addToken);
    }

    function addWhitelist(address _addToken) internal returns(bool) {
        require(_addToken != address(0), "Freeport: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) internal returns(bool) {
        require(_delToken != address(0), "Freeport: token is the zero address");
        return EnumerableSet.remove(_whitelist, _delToken);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _token) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _token);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLength() - 1, "index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }
}

contract FPAccountsContract is cFPAccountsContract, math{
    using Address for address;
    function() external payable{}
	
	uint RegFee;                //The registration fee.

    struct CitizenInfo {
        uint IsReg;
        uint RegTime;
        uint Gender;
        uint Avatar;
        uint ActionPoint;
        uint Skill;
        uint Health;
        uint HealthMax;
        uint Stamina;
    }

    mapping(address => CitizenInfo) public citizenInfos;

    event RegFreeportResult(address _userAddr, bool result);
    //event withdrawHarvest(uint _withdrawETHAmount, bool result);
	
	//----------------Freeport Function----------------------------
	
	//--Reg to Freeport contract--//
    function RegFreeport(uint _Gender, uint _Avatar, uint _Skill) external payable{
		address Useradder = msg.sender;
		require(citizenInfos[Useradder].IsReg == 0, "Freeport : This address has been registered.");
		uint _RegAmount = msg.value;
		require(_RegAmount == RegFee, "Freeport : Fee error.");
		require(isWhitelist(Useradder), "Freeport : This address is not in list.");
		

		citizenInfos[Useradder].IsReg = 1;
		citizenInfos[Useradder].RegTime = now;
		citizenInfos[Useradder].Gender = _Gender;
		citizenInfos[Useradder].Avatar = _Avatar;
		citizenInfos[Useradder].ActionPoint = 24;
		citizenInfos[Useradder].Skill = _Skill;
		citizenInfos[Useradder].Health = 100;
		citizenInfos[Useradder].HealthMax = 100;
		citizenInfos[Useradder].Stamina = 2000;
		
		require(IERC20(MTCAddr()).transfer(Useradder, RegMTC));
		require(IERC20(FPDAddr()).transfer(Useradder, RegFPD));
		
		delWhitelist(Useradder);
		emit RegFreeportResult(Useradder, true);
    }

	//--Check input Player Info--//
    function checkAddressInfo(address inputAddr) public view returns(uint[] memory){
		require(citizenInfos[inputAddr].IsReg == 1, "Freeport : This this address is not player.");

		uint[] memory returnint = new uint[](9);
		returnint[0] = citizenInfos[inputAddr].IsReg;
		returnint[1] = citizenInfos[inputAddr].RegTime;
		returnint[2] = citizenInfos[inputAddr].Gender;
		returnint[3] = citizenInfos[inputAddr].Avatar;
		returnint[4] = citizenInfos[inputAddr].ActionPoint;
		returnint[5] = citizenInfos[inputAddr].Skill;
		returnint[6] = citizenInfos[inputAddr].Health;
		returnint[7] = citizenInfos[inputAddr].HealthMax;
		returnint[8] = citizenInfos[inputAddr].Stamina;
		
        return returnint;
    }
}