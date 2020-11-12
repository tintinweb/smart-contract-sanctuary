pragma solidity ^0.5.0;
import "./SafeMath.sol";

contract AffiliateStorage {
	using SafeMath for uint;

	mapping(uint=>address) public codeToAddressMap;
	mapping(address=>uint) public addressToCodeMap;
	mapping(address=>uint) public addressToFatherCode;
	uint private constant maxCode = 100000000;
	bytes public constant baseString = "0123456789abcdefghjklmnpqrstuvwxyz";


	/**
	* code is the last 6 digt of user
	**/
	function newCode(address user) public returns(uint) {
		require(addressToCodeMap[user] == 0, "user existed");

		uint code = uint(user);
		code = code.sub(code.div(maxCode).mul(maxCode));

		require(code !=0, "code must > 0");

		while(codeToAddressMap[code]!=address(0)) {
			code = code.add(7);
		}
		codeToAddressMap[code] = user;
		addressToCodeMap[user] = code;
		return code;

	}

	function getCode(address user) public view returns(uint) {
		uint code = addressToCodeMap[user];
		if(code != 0)
			return code;
	}

	function getUser(uint code) public view returns(address) {
		return codeToAddressMap[code];
	}
	
	function setFather(uint code) public {
	    require(codeToAddressMap[code] != address(0), "inviteCode not existed");
	    addressToFatherCode[msg.sender] = code;
	}
	
	function getFatherCode(address userAddress) public view returns (uint){
	    uint FatherCode = addressToFatherCode[userAddress];
	    return FatherCode;
	}
	
	function getFather(address userAddress) public view returns(address){
        uint FatherCode = addressToFatherCode[userAddress];
        if(FatherCode != 0 ){
        address FatherAddress = getUser(FatherCode);
        return  FatherAddress;
        }
        //require(addressToFatherCode[userAddress]!=0,"FatherCode not existed");
	}
	
} 