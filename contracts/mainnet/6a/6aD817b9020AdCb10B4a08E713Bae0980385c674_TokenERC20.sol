pragma solidity ^0.4.20;
//**양종만**정병두**//180419~
/*모든 행위는 1wei단위로 되기때문에 주의해야됨
ex :
총 발행 토큰 111
소수점18자리로 했을때 토탈 토큰 111 000 000 000 000 000 000(wei단위임)
1토큰 전송
남은 토큰 110999999999999999999
토큰Value * 10 ** uint256(소수점자리수)로 미리 계산하면 1토큰 전송시 110 000 000 000 000 000 000
*/
//기본 소수점 자리 18 / 변경되면 payable , transfer에서 달라질수 있으니 주의
//들어오는 이더리움 단위는 1ETH=1000000000000000000Wei 이더 소수점 단위18이기 때문에 소수점 단위가18이 아니면 payable, transfer 함수 주의 해야됨
//** public이 들어간 변수,함수는 일반 사용자들도 볼수있음**//
contract TokenERC20
{
  //토큰 이름
  string public name;
  //토큰 심볼(단위)
  string public symbol;
  //토큰 단위 소수점 표현
  uint8 public decimals;
  //wei 단위를 편하게 하기 위한 변수
  uint256 _decimals;
  //이더*2=토큰
  uint256 public tokenReward;
  //총 토큰 발행 갯수
  uint256 public totalSupply;
  //토큰 admin
  address public owner;
  //토큰 상태 (text로 보여주기 위한것) ex :  private ,  public , test , demo
  string public status;
  //이더 입금 제한 타임스탬프 (시작시간) // http://www.4webhelp.net/us/timestamp.php 에서 확인가능
  uint256 public start_token_time;
  //이더 입금 제한 타임스탬프 (종료시간)
  uint256 public stop_token_time;
  ///////GMB 토큰은 3자끼리 토큰 이동을 미지원 할것이기 때문에 추가함!!
  uint256 public transferLock;

  //owner인지 검사하는 부분
  modifier isOwner
  {
    assert(owner == msg.sender);
    _;
  }

  //외부에서 호출할수 있게 하는것(MIST UI로 확인가능)
  mapping (address => uint256) public balanceOf;

  //이벤트 기록을 위한것
  event Transfer(address indexed from, address indexed to, uint256 value);
  event token_Burn(address indexed from, uint256 value);
  event token_Add(address indexed from, uint256 value);
  event Deposit(address _sender, uint amount ,string status);
  event change_Owner(string newOwner);
  event change_Status(string newStatus);
  event change_Name(string newName);
  event change_Symbol(string newSymbol);
  event change_TokenReward(uint256 newTokenReward);
  event change_Time_Stamp(uint256 change_start_time_stamp,uint256 change_stop_time_stamp);

  //토큰 초기화 함수
  function TokenERC20() public
  {
    //토큰 이름 초기화
    name = "GMB";
    //토큰 심볼(단위) 초기화
    symbol = "MAS";
    //소수점 자리 초기화
    decimals = 18;
    //wei 단위를 편하게 하기 위한 변수
    _decimals = 10 ** uint256(decimals);
    //ETH , 토큰 환산비율
    tokenReward = 0;
    //토큰 발행 갯수 초기화
    totalSupply =  _decimals * 10000000000; //1백억개
    //토큰 상태 초기화
    status = "Private";
    //타임스탬프 초기화 (시작시간) 2018.1.1 00:00:00 (Gmt+9)
    start_token_time = 1514732400;
    //타임스탬프 초기화 (종료시간)  2018.12.31 23:59:59 (Gmt+9)
    stop_token_time = 1546268399;
    //토큰 관리자 지갑 주소 초기화
    owner = msg.sender;
    //발행된 토큰갯수를 토큰생성지갑에 입력
    balanceOf[msg.sender] = totalSupply;
    ///////GMB 토큰은 제3자끼리 토큰 이동을 미지원 할것이기 때문에 추가함!!
    transferLock = 1; //0일때만 transfer 가능
  }
  //*이더 받으면 토큰 전송*//
  function() payable public
  {
    //환산값 변수
    uint256 cal;
    //이더 입금 제한 타임스탬프 (시작시간)
    require(start_token_time < block.timestamp);
    //이더 입금 제한 타임스탬프 (종료시간)
    require(stop_token_time > block.timestamp);
    //ETH보낸사람,ETH코인수 이벤트에 기록
    emit Deposit(msg.sender, msg.value, status);
    //토큰=이더*2
    cal = (msg.value)*tokenReward;
    //토큰 지갑에서 남아있는 토큰수가 보내려는 토큰보다 많은지 검사
    require(balanceOf[owner] >= cal);
    //오버플로어 검사
    require(balanceOf[msg.sender] + cal >= balanceOf[msg.sender]);
    //토큰지갑에서 차감
    balanceOf[owner] -= cal;
    //받는 사람지갑에 토큰 저장
    balanceOf[msg.sender] += cal;
    //이벤트 기록을 남김
    emit Transfer(owner, msg.sender, cal);
  }
  //*토큰 전송*// ex : 1토큰 추가시 1 000 000 000 000 000 000(Mist UI 관리자 페이지에서도 동일, Mist UI 일반 사용자 보내기에서는 1)
  function transfer(address _to, uint256 _value) public
  {
    ///////GMB 토큰은 제3자끼리 토큰 이동을 미지원 할것이기 때문에 추가함!!
    require(transferLock == 0); //0일때만 transfer 가능
    //토큰 지갑에서 남아있는 토큰수가 보내려는 토큰보다 많은지 검사
    require(balanceOf[msg.sender] >= _value);
    //오버플로어 검사
    require((balanceOf[_to] + _value) >= balanceOf[_to]);
    //토큰지갑에서 차감
    balanceOf[msg.sender] -= _value;
    //받는 사람지갑에 토큰 저장
    balanceOf[_to] += _value;
    //이벤트 기록을 남김
    emit Transfer(msg.sender, _to, _value);
  }
  //*토큰 전송 geth에서 편하게 보내기위해 __decimals을 붙여줌*// ex : 1토큰 전송시 1
  function admin_transfer(address _to, uint256 _value) public isOwner
  {
    //tokenValue = _value;
    //토큰 지갑에서 남아있는 토큰수가 보내려는 토큰보다 많은지 검사
    require(balanceOf[msg.sender] >= _value*_decimals);
    //오버플로어 검사
    require(balanceOf[_to] + (_value *_decimals)>= balanceOf[_to]);
    //토큰지갑에서 차감
    balanceOf[msg.sender] -= _value*_decimals;
    //받는 사람지갑에 토큰 저장
    balanceOf[_to] += _value*_decimals;
    //이벤트 기록을 남김
    emit Transfer(msg.sender, _to, _value*_decimals);
  }
  //*지갑에서 지갑으로 토큰 이동* 회수용// ex : 1토큰 회수시 1
  function admin_from_To_transfer(address _from, address _to, uint256 _value) public isOwner
  {
    //tokenValue = _value;
    //토큰 지갑에서 남아있는 토큰수가 보내려는 토큰보다 많은지 검사
    require(balanceOf[_from] >= _value*_decimals);
    //오버플로어 검사
    require(balanceOf[_to] + (_value *_decimals)>= balanceOf[_to]);
    //토큰지갑에서 차감
    balanceOf[_from] -= _value*_decimals;
    //받는 사람지갑에 토큰 저장
    balanceOf[_to] += _value*_decimals;
    //이벤트 기록을 남김
    emit Transfer(_from, _to, _value*_decimals);
  }
  //*총 발행 토큰 소각*// ex : 1토큰 소각시 1
  function admin_token_burn(uint256 _value) public isOwner returns (bool success)
  {
    //남아있는 토큰수보다 소각하려는 토큰수가 많은지 검사
    require(balanceOf[msg.sender] >= _value*_decimals);
    //토큰 지갑에서 차감
    balanceOf[msg.sender] -= _value*_decimals;
    //총 발행 토큰에서 차감
    totalSupply -= _value*_decimals;
    //이벤트 기록을 남김
    emit token_Burn(msg.sender, _value*_decimals);
    return true;
  }
  //*총 발행 토큰 추가*// ex : 1토큰 추가시 1
  function admin_token_add(uint256 _value) public  isOwner returns (bool success)
  {
    require(balanceOf[msg.sender] >= _value*_decimals);
    //토큰 지갑에서 더함
    balanceOf[msg.sender] += _value*_decimals;
    //총 발행 토큰에서 더함
    totalSupply += _value*_decimals;
    //이벤트 기록을 남김
    emit token_Add(msg.sender, _value*_decimals);
    return true;
  }
  //*이름 변경*//  ***토큰으로 등록된 후에는 이더스캔에서 반영이 안됨(컨트랙트 등록 상태에서는 괜찮음)***
  function change_name(string _tokenName) public isOwner returns (bool success)
  {
    //name 변경해준다
    name = _tokenName;
    //이벤트 기록을 남김
    emit change_Name(name);
    return true;
  }
  //*심볼 변경*//  ***토큰으로 등록된 후에는 이더스캔에서 반영이 안됨(컨트랙트 등록 상태에서는 괜찮음)***
  function change_symbol(string _symbol) public isOwner returns (bool success)
  {
    //symbol 변경해준다
    symbol = _symbol;
    //이벤트 기록을 남김
    emit change_Symbol(symbol);
    return true;
  }
  //*status변경*//
  function change_status(string _status) public isOwner returns (bool success)
  {
    //status 변경해준다
    status = _status;
    //이벤트 기록을 남김
    emit change_Status(status);
    return true;
  }
  //*배율 변경*//
  function change_tokenReward(uint256 _tokenReward) public isOwner returns (bool success)
  {
    //tokenReward 변경해준다
    tokenReward = _tokenReward;
    //이벤트 기록을 남김
    emit change_TokenReward(tokenReward);
    return true;
  }
  //*ETH출금*//
  function ETH_withdraw(uint256 amount) public isOwner returns(bool)
  {
    //소수점까지 출금해야되기 때문에 wei단위로 출금 //1ETH 출금시 1 000 000 000 000 000 000 입력 해야됨
    owner.transfer(amount);
    //출금하는건 일반 사용자가 알아야될 필요가 없기때문에 emit 이벤트를 실행하지 않음
    return true;
  }
  //*time_stamp변경*//
  function change_time_stamp(uint256 _start_token_time,uint256 _stop_token_time) public isOwner returns (bool success)
  {
    //start_token_time을 변경해준다
    start_token_time = _start_token_time;
    //stop_token_time을 변경해준다
    stop_token_time = _stop_token_time;

    //이벤트 기록을 남김
    emit change_Time_Stamp(start_token_time,stop_token_time);
    return true;
  }
  //*owner변경*//
  function change_owner(address to_owner) public isOwner returns (bool success)
  {
    //owner를 변경해준다
    owner = to_owner;
    //이벤트 기록을 남김
    emit change_Owner("Owner_change");
    return true;
  }
  //*transferLock변경*// 0일때만 lock 풀림
  function setTransferLock(uint256 transferLock_status) public isOwner returns (bool success)
  {
    //transferLock 변경해준다
    transferLock = transferLock_status;
    //transferLock은 일반 사용자가 알아야될 필요가 없기때문에 emit 이벤트를 실행하지 않음
    return true;
  }
  //*time_stamp변경,status 변경*//
  function change_time_stamp_status(uint256 _start_token_time,uint256 _stop_token_time,string _status) public isOwner returns (bool success)
  {
    //start_token_time을 변경해준다
    start_token_time = _start_token_time;
    //stop_token_time을 변경해준다
    stop_token_time = _stop_token_time;
    //status 변경해준다
    status = _status;
    //이벤트 기록을 남김
    emit change_Time_Stamp(start_token_time,stop_token_time);
    //이벤트 기록을 남김
    emit change_Status(status);
    return true;
  }
}