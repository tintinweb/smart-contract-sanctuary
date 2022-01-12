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

contract cDPSContract is Manager{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

	uint public distLine = 10 * 10 ** uint(18); // Interest will only be distribution for deposits greater than 10 GET.

    address _dexAddr = 0xcbC886a48686A6b0A8Af922Be3CE5E2b8E1B856f;     //Oracle Addr
    address _treasury = 0x95c2c45245A52b4703B4470848E843Fe07C19312;
	address _secretary = 0x3C7Ba96F1F62081Fcb7AF0bFF4583d198ed660d6;
	
	
	function() external payable{}

	function Treasury() public view returns(address){
        require(_treasury != address(0), "It's a null address");
        return _treasury;
    }
	
	function setTreasury(address addr) public onlyManager{
        _treasury = addr;
    }

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

    function setdistLine(uint amountGET) public onlyManager{
        distLine = amountGET * 10 ** uint(18);
    }

    modifier onlySecretary{
        require(msg.sender == manager || msg.sender == Secretary(), "You are not Secretary.");
        _;
    }

    //----------------Whitelist Token----------------------------
	
    function addWhitelist(address _addToken) internal returns(bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) internal returns(bool) {
        require(_delToken != address(0), "SwapMining: token is the zero address");
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

contract DPSContract is cDPSContract, math{
    using Address for address;
    function() external payable{}
	
	uint RegFee;
	uint LastTimestamp;
	uint CalculationTimes;
	uint TotalContValue;
	uint UpdateTimes;
	uint TotalGETOut;         //Total ETH pay out
	uint DPSPayAmounts;
	
    struct DepositInfo {
        uint RegTime;
        uint timestamp;
        uint ContributionValue;
        uint UnclaimedIncome;
    }

    mapping(address => DepositInfo) public depositInfos;

    event RegDPSResult(address _userAddr, bool result);
    event withdrawHarvest(uint _withdrawETHAmount, bool result);
	
	//----------------DPS Function----------------------------
	
	//--Reg to DPS contract--//
    function RegDPS() external payable{
		uint _RegAmount = msg.value;
		require(_RegAmount == RegFee, "DPS : Fee error.");
		require(!isWhitelist(msg.sender), "DPS : This address is in user list.");
		
		address Useradder = msg.sender;
		depositInfos[Useradder].RegTime = now;
		depositInfos[Useradder].timestamp = now;
		depositInfos[Useradder].ContributionValue = 0;
		depositInfos[Useradder].UnclaimedIncome = 0;
		addWhitelist(Useradder);
		emit RegDPSResult(Useradder, true);
    }

	//--Harvest Earnings from DPS contract--//
    function harvestEarnings() external{
		require(isWhitelist(msg.sender), "DPS : This address is not in user list");
		uint _withdrawETHAmount = depositInfos[msg.sender].UnclaimedIncome;	
		require(_withdrawETHAmount >= 0, "DPS : You have not yet earned.");

		(msg.sender).transfer(_withdrawETHAmount);
		
		depositInfos[msg.sender].timestamp = now;
		depositInfos[msg.sender].UnclaimedIncome = 0;
		TotalGETOut = TotalGETOut.add(_withdrawETHAmount);
			
		emit withdrawHarvest(_withdrawETHAmount, true);
    }
	
	//--DPS income to DPS contract--//
    function incomeDPS() external payable{
		uint _incomeAmount = msg.value;
		require(_incomeAmount != 0, "DPS : Did not send GET in!");
		uint amountUsers = getWhitelistLength();
		
        for (uint i = 0; i < amountUsers; i++) {
            ContributionDPS(getWhitelist(i), _incomeAmount);
        }
		
		DPSPayAmounts = _incomeAmount;
		TotalContValue = 0;
    }

	//--Contribution DPS to a user--//
    function ContributionDPS(address userAddr, uint _totalDPSincome) private {
		uint _DPSIncome = depositInfos[userAddr].ContributionValue.mul(_totalDPSincome).div(TotalContValue);
	
		depositInfos[userAddr].timestamp = now;
		depositInfos[userAddr].ContributionValue = 0;
		depositInfos[userAddr].UnclaimedIncome = depositInfos[userAddr].UnclaimedIncome.add(_DPSIncome);
    }

	//--DPS income to DPS contract(Not Contribution DPS to users.)--//
    function incomeDPSPayAmounts() external payable{
		require(msg.value != 0, "DPS : Did not send GET in!");
		DPSPayAmounts = msg.value;
    }

	//--DPS income to DPS contract by sort--//
    function incomeDPSSort(uint minSort, uint maxSort) external onlySecretary{
		uint amountUsers = getWhitelistLength();
		require(maxSort < amountUsers, "DPS : maxSort error.");

		uint amountUpdate = maxSort - minSort + 1;
		
        for (uint i = 0; i < amountUpdate; i++) {
            ContributionDPS(getWhitelist(minSort.add(i)), DPSPayAmounts);
        }
		
		if(maxSort == amountUsers.sub(1)){
            TotalContValue = 0;
		}
    }

	//--Update income to users every hour--//
    function UpdateContribution() external onlySecretary{
		uint amountUsers = getWhitelistLength();
		uint _timeUpdate = 0;
		if(LastTimestamp == 0){
            _timeUpdate = 0;
		}else{
            _timeUpdate = now.sub(LastTimestamp);
		}

		CalculationTimes = CalculationTimes.add(_timeUpdate);
		LastTimestamp = now;
		UpdateTimes = UpdateTimes.add(1);
		
        for (uint i = 0; i < amountUsers; i++) {
            UpdateUserCon(getWhitelist(i));
        }
    }
	
	//--Update income to users every hour by Sort--//
    function UpdateContributionSort(uint minSort, uint maxSort) external onlySecretary{
		uint amountUsers = getWhitelistLength();
		require(maxSort < amountUsers, "DPS : maxSort error.");
		uint _timeUpdate = 0;
		if(LastTimestamp == 0){
            _timeUpdate = 0;
		}else{
            _timeUpdate = now.sub(LastTimestamp);
		}

		CalculationTimes = CalculationTimes.add(_timeUpdate);
		LastTimestamp = now;
		if(maxSort == amountUsers.sub(1)){
			UpdateTimes = UpdateTimes.add(1);
		}
		uint amountUpdate = maxSort - minSort + 1;
        for (uint i = 0; i < amountUpdate; i++) {
            UpdateUserCon(getWhitelist(minSort.add(i)));
        }
    }
	
	//--Update Contribution to a user--//
    function UpdateUserCon(address userAddr) private {
		uint userBalance = (userAddr).balance;
		if(userBalance >= distLine){
			uint _addCon = userBalance.div(1 * 10 ** uint(18));
			depositInfos[userAddr].timestamp = now;
			depositInfos[userAddr].ContributionValue = depositInfos[userAddr].ContributionValue.add(_addCon);
			TotalContValue = TotalContValue.add(_addCon);
		}
    }

	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }

	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}

	//--Manager only--//
    function SetupAll(address _sDEXAddr, address _sTreasury, address _sSecretaryAddr) public onlyManager{
        setDexAddr(_sDEXAddr);
		setTreasury(_sTreasury);
		setSecretary(_sSecretaryAddr);
    }
	
	
	//----------------inquiry----------------------------
	//--Check state of the DPS--//
    function inqDPS() public view returns(uint[] memory){
	
		uint[] memory returnint = new uint[](7);
		returnint[0] = RegFee;
		returnint[1] = LastTimestamp;
		returnint[2] = CalculationTimes;
		returnint[3] = TotalContValue;
		returnint[4] = UpdateTimes;
		returnint[5] = TotalGETOut;
		returnint[6] = getWhitelistLength();
		
        return returnint;
    }

	//--Check input address Info--//
    function checkAddressInfo(address inputAddr) public view returns(uint[] memory){
		require(isWhitelist(inputAddr), "DPS : This this address is not in user list");
		uint[] memory returnint = new uint[](4);
		returnint[0] = depositInfos[inputAddr].RegTime;
		returnint[1] = depositInfos[inputAddr].timestamp;
		returnint[2] = depositInfos[inputAddr].ContributionValue;
		returnint[3] = depositInfos[inputAddr].UnclaimedIncome;
		
        return returnint;
    }

	
	//--Calculate Total Deposited Value--//
    function inqTotalGETOutValue() public view returns(
        uint _TDV){

		uint GETTokenPrice = inqGETTokenBuyPrice();
		uint AmountInGET = uint(1 * 10 ** uint(22)).div(GETTokenPrice);
		uint ECOPoolGETValue = TotalGETOut.div(AmountInGET).mul(10000);
        return ECOPoolGETValue;
    }

	//--Calculate GETToken buy price in Oracle by GET value--//
    function inqGETTokenBuyPrice() public view returns(
        uint _tokenPrice){

		uint amountsOut = 1*10**18;
		uint[] memory _amountsINToken = new uint[](7);
		_amountsINToken = ISwap(_dexAddr).getOracle();
		uint _xtokenPrice = amountsOut.div(_amountsINToken[0]).mul(10000);
		
        return _xtokenPrice;
    }
}