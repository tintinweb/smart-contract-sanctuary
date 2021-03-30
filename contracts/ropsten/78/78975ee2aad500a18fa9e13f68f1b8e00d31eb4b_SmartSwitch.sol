/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.11;

contract SmartSwitch {
	
	// 스위치가 사용할 구조체
	struct Switch {
		address addr;	// 이용자 어드레스
		uint	endTime;	// 이용 종료 시각 (UnixTime)
		bool 	status;	// true이면 이용 가능
	}
	
	address public owner;	// 서비스 소유자 어드레스
	address public iot;	// IoT 장치의 어드레스
	mapping (uint => Switch) public switches;	// Switch 구조체를 담을 매핑	
	uint public numPaid;			// 결제 횟수
	
	/// 서비스 소유자 권한 체크
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	
	/// IoT 장치 권한 체크
	modifier onlyIoT() {
		require(msg.sender == iot);
		_;
	}
	
	/// 생성자
	/// IoT 장치의 어드레스를 인자로 받음
	function SmartSwitch(address _iot) {
		owner = msg.sender;
		iot = _iot;
		numPaid = 0;
	}

	/// 이더를 지불할 때 호출되는 함수
	function payToSwitch() public payable {
		// 1 ETH가 아니면 처리 종료
		//require(msg.value == 1000000000000000000);
		
		// Switch 생성
		Switch s = switches[numPaid++];
		s.addr = msg.sender;
		s.endTime = now + 240;
		s.status = true;
	}
	
	/// 스테이터스를 변경하는 함수
	/// 이용 종료 시각에 호출됨
	/// 임자는 switches의 키 값
	function updateStatus(uint _index) public onlyIoT {
		// 인덱스 값에 해당하는 Switch 구조체가 없으면 종료
		require(switches[_index].addr != 0);
		
		// 이용 종료 시각이 되지 않았으면 종료
		require(now > switches[_index].endTime);
		
		// 스테이터스 변경
		switches[_index].status = false;
	}

	/// 지불된 이더를 인출하는 함수
	function withdrawFunds() public onlyOwner {
		if (!owner.send(this.balance)) 
			throw;
	}
	
	/// 컨트랙트를 소멸시키는 함수
	function kill() public onlyOwner {
		selfdestruct(owner);
	}
}