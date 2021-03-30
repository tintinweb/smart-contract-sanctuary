/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.11;
contract NameRegistry1 {

	// 컨트랙트를 나타낼 구조체
	struct Contract {
		address owner;
		address addr;
		bytes32 description;
	}

	// 등록된 레코드 수
	uint public numContracts;

	// 컨트랙트를 저장할 매핑
	mapping (bytes32  => Contract) public contracts;
    
	/// 생성자
	function NameRegistry() {
		numContracts = 0;
	}

	/// 컨트랙트 등록
	function register(bytes32 _name) public returns (bool){
		// 아직 사용되지 않은 이름이면 신규 등록
		if (contracts[_name].owner == 0) {
			Contract con = contracts[_name];
			con.owner = msg.sender;
			numContracts++;
			return true;
		} else {
			return false;
		}
	}

	/// 컨트랙트 삭제
	function unregister(bytes32 _name) public returns (bool) {
		if (contracts[_name].owner == msg.sender) {
			contracts[_name].owner = 0;
 			numContracts--;
 			return true;
		} else {
			return false;
		}
	}
	
	/// 컨트랙트 소유자 변경
	function changeOwner(bytes32 _name, address _newOwner) public {
		contracts[_name].owner = _newOwner;
	}
	
	/// 컨트랙트 소유자 정보 확인
	function getOwner(bytes32 _name) constant public returns (address) {
		return contracts[_name].owner;
	}
    
	/// 컨트랙트 어드레스 변경
	function setAddr(bytes32 _name, address _addr) public onlyOwner(_name) {
		contracts[_name].addr = _addr;
    }
    
	/// 컨트랙트 어드레스 확인
	function getAddr(bytes32 _name) constant public returns (address) {
		return contracts[_name].addr;
	}
        
	/// 컨트랙트 설명 변경
	function setDescription(bytes32 _name, bytes32 _description) public onlyOwner(_name) {
		contracts[_name].description = _description;
	}

	/// 컨트랙트 설명 확인
	function getDescription(bytes32 _name) constant public returns (bytes32)  {
		return contracts[_name].description;
	}
    
	/// 함수를 호출 전 먼저 처리되는 modifier를 정의
	modifier onlyOwner(bytes32 _name) {
	    require(contracts[_name].owner == msg.sender);
		_;
	}
}