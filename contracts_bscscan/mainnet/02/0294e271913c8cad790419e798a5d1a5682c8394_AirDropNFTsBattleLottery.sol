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

contract cAirDropNFTBatch is Manager{
    using Address for address;
    address _BNBAddr;
    address _USDTAddr;
    address _PKQTAddr;
	
	function() external payable{}

    function BNBAddr() public view returns(address){
        return _BNBAddr;
    }
	
	function setBNBAddr(address addr) public onlyManager{
        _BNBAddr = addr;
    }

    function USDTAddr() public view returns(address){
        return _USDTAddr;
    }
	
	function setUSDTAddr(address addr) public onlyManager{
        _USDTAddr = addr;
    }
	
    function pokeQAddr() public view returns(address){
        return _PKQTAddr;
    }
	
	function setPKQTAddr(address addr) public onlyManager{
        _PKQTAddr = addr;
    }
}

contract AirDropNFTsBattleLottery is cAirDropNFTBatch, math{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;
	
    function() external payable{}

	address[] participantList;
	address[] winnerList;

	function checkParticipantList(uint sort) public view returns(address){
        return participantList[sort];
    }
	
	function checkWinnerList(uint sort) public view returns(address){
        return winnerList[sort];
    }

    function getParticipantListLength() public view returns (uint256) {
        return participantList.length;
    }

    function getWinnerListLength() public view returns (uint256) {
        return winnerList.length;
    }
	
    function isparticipantList(address _youAddress) public view returns (bool) {
        uint _addressAmount = participantList.length;
		bool _IsParticipantList = false;
        for (uint i = 0; i < _addressAmount; i++){
			if(_youAddress == participantList[i]){
				_IsParticipantList = true;
			}
        }
        return _IsParticipantList;
    }
	
    function iswinnerList(address _youAddress) public view returns (bool) {
        uint _addressAmount = winnerList.length;
		bool _IsWinnerList = false;
        for (uint i = 0; i < _addressAmount; i++){
			if(_youAddress == winnerList[i]){
				_IsWinnerList = true;
			}
        }
        return _IsWinnerList;
    }
	
    function checkWinnerIndex(address _youAddress) public view returns (uint256) {
        require(iswinnerList(_youAddress), "AirDropNFTLottery : You are not winner.");
        uint _addressAmount = winnerList.length;
		uint _WinnerIndex = 0;
        for (uint i = 0; i < _addressAmount; i++){
			if(_youAddress == winnerList[i]){
				_WinnerIndex = i;
			}
        }
        return _WinnerIndex;
    }

    //----------------Whitelist----------------------------
	
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

    event lotteryResult(uint _Sort, uint _drawNO, address _winnerAddr);
    event AirDropNFTResult(uint _mareId, uint _stallionId, address _winnerAddr);

	//----------------Air Drop NFT Lottery----------------------------

	//--Add participant address Manager only--//
    function Addparticipant(address[] memory _ParticipantAddrs) public onlyManager returns (bool) {
        uint _addressAmount = _ParticipantAddrs.length;
        for (uint i = 0; i < _addressAmount; i++){
			if(!isWhitelist(_ParticipantAddrs[i])){
				participantList.push(_ParticipantAddrs[i]);
				addWhitelist(_ParticipantAddrs[i]);
			}
        }
        return true;
    }

	//--Draw Winners Manager only--//
    function drawWinnerXTimes(uint _drawTimes) public onlyManager{
        for (uint i = 0; i < _drawTimes; i++){
		    drawWinner();
        }
    }

	//--Draw Winners From WhiteList Manager only--//
    function drawWinner() public onlyManager{
        uint winnerLength = winnerList.length;
		require(winnerLength < 300, "AirDropNFTLottery : Length error.");
        uint _WhitelistAmount = getWhitelistLength();
        bytes memory seed = abi.encodePacked(_WhitelistAmount);
        uint drawNO = rand(seed, 0, _WhitelistAmount.sub(1));

		address _winner = getWhitelist(drawNO);
        emit lotteryResult(winnerLength, drawNO, _winner);
		
		if(winnerLength == 0){
			require(IERC20(BNBAddr()).transfer(_winner, 1*10**18));
		}else if(winnerLength > 0 && winnerLength <= 4){
			require(IERC20(USDTAddr()).transfer(_winner, 100*10**18));
		}else if(winnerLength > 4 && winnerLength <= 49){
			require(IERC20(pokeQAddr()).transfer(_winner, 600*10**18));
		}else if(winnerLength > 49 && winnerLength <= 299){
			require(IERC20(pokeQAddr()).transfer(_winner, 300*10**18));
		}

        winnerList.push(_winner);
        delWhitelist(_winner);
    }

	//--Manager only--//
	function destroy() external onlyManager{ 
        selfdestruct(msg.sender); 
	}
	
	//--Manager only--//
    function takeTokensToManager(address tokenAddr) external onlyManager{
        uint _thisTokenBalance = IERC20(tokenAddr).balanceOf(address(this));
        require(IERC20(tokenAddr).transfer(msg.sender, _thisTokenBalance));
    }
}