/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity ^0.8.0;

struct accountData {
	bool clientCheck;

	address referrerOneLvl;
	address referrerTwoLvl;
	address referrerThreeLvl;

	uint lvl1Income;
	uint lvl2Income;
	uint lvl3Income;

	mapping(address => bool) referrals_map;
    address[] referrals_list;
    
    bool mentorCheck;
    
}
abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
    return msg.sender;
}

function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract PuzzleNetwork is Context{
    mapping (address => accountData) private profile;
    address public controlContract;
    address public mentorsContract;
    address public owner;

    constructor(address _owner) public payable{
    	owner = _owner;
    	
    	profile[owner].referrerOneLvl = owner;
    	profile[owner].referrerTwoLvl = owner;
    	profile[owner].referrerThreeLvl = owner;
    	profile[owner].clientCheck = true;
    }
  	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	modifier onlyOwner() {
    	require(msg.sender == owner);
   		_;
  	}
  	modifier onlyCtrlContract() {
  		require(msg.sender == controlContract);
   		_;

  	}
 
  	function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  	}
  	function setMentorsContract(address mContract) public onlyOwner {
  		mentorsContract = mContract;
  	}
  	function setControlContract(address ctrlContract) public onlyOwner {
  		controlContract = ctrlContract;
  	}
  	function setMentorStatus(address mentor) public onlyCtrlContract returns (bool) {
  		profile[mentor].mentorCheck = true;
  		return profile[mentor].mentorCheck;
  	}
  	function getMentorStatus(address mentor) public view returns(bool){
  		return profile[mentor].mentorCheck;
  	}
	function setReferrers(address client, address referrer1, address referrer2, address referrer3) private {
		profile[client].referrerOneLvl = referrer1;
		profile[client].referrerTwoLvl = referrer2;
		profile[client].referrerThreeLvl = referrer3;
	}
	function getReferrOne(address client) public view returns(address) {
		return profile[client].referrerOneLvl;
	}
	function getReferrTwo(address client) public view returns(address) {
		return profile[client].referrerTwoLvl;
	}
	function getReferrThree(address client) public view returns(address) {
		return profile[client].referrerThreeLvl;
	}
	function recordIncome(address client, uint percent) public onlyCtrlContract returns (bool) {
		profile[client].lvl1Income = profile[client].lvl1Income + (percent * 5);
		profile[client].lvl2Income = profile[client].lvl2Income + (percent * 3);
		profile[client].lvl3Income = profile[client].lvl3Income + (percent * 2);
		return true;
	}
	function readIncome1(address client) public view returns (uint) {
		return profile[client].lvl1Income;
	}
	function readIncome2(address client) public view returns (uint) {
		return profile[client].lvl2Income;
	}
	function readIncome3(address client) public view returns (uint) {
		return profile[client].lvl3Income;
	}
	function getClientStatis(address client) public view returns (bool) {
		return profile[client].clientCheck;
	}
	function registration(address client, address referrer) external onlyCtrlContract returns (bool) {
			 
		require ( profile[client].clientCheck != true, "PZL: You are already registered");
		require ( profile[referrer].clientCheck == true, "PZL: Invalid referrer address");
		setReferrers(client, referrer, profile[referrer].referrerOneLvl, profile[referrer].referrerTwoLvl);
		profile[client].clientCheck = true;
		return profile[client].clientCheck;
	}
	

}