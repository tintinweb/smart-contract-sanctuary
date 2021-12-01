/**
 *Submitted for verification at polygonscan.com on 2021-11-30
*/

pragma solidity 0.8.7;

interface ERC20Like {
    function burn(address from, uint256 amount) external;
}

interface EtherOrcLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
}


contract HallOfChampionsPolygon {

    address        implementation_;
    address public admin; 
    address public updater;
        
	// Name Storage Slots - Not the most efficient way to store it, but it works well enough
	mapping (uint256 => string)  private _firstNames;
	mapping (uint256 => string)  private _lastNames;
	mapping (uint256 => uint256) public  joined;


	/*///////////////////////////////////////////////////////////////
                    VIEW FUNCTIONS 
    //////////////////////////////////////////////////////////////*/
 
	function getName(uint256 orcId) public view returns(string memory){
		// If not joined, return the boring name
		if (joined[orcId] == 0) return string(abi.encodePacked("Orc #", _toString(orcId)));

		// If Orc has only a fisrt name 
		if (bytes(_firstNames[orcId]).length > 0 && bytes(_lastNames[orcId]).length == 0) 
			return _firstNames[orcId];
		
		// Ir Orc has only a last name
		if (bytes(_firstNames[orcId]).length == 0 && bytes(_lastNames[orcId]).length > 0) 
			return _lastNames[orcId];

		return string(abi.encodePacked(_firstNames[orcId], " ", _lastNames[orcId]));
	}

	/*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function updateName(uint256 orcId, string calldata firstName_, string memory lastName_, uint256 joined_) public {
        require(msg.sender == updater);
        _firstNames[orcId] = firstName_;
		_lastNames[orcId]  = lastName_;
        joined[orcId]      = joined_;
    }

    function updateNames(uint256[] calldata ids, string[] calldata fNames_, string[] calldata lNames_, uint256[] calldata joined_) external {
        require(msg.sender == updater);
        for (uint256 i = 0; i < ids.length; i++) {
            updateName(ids[i], fNames_[i], lNames_[i], joined_[i]);
        }
    }

    function setUpdater(address up_) external {
        require(msg.sender == admin);
        updater = up_;
    }

	function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}