pragma solidity ^0.4.20;

library SafeMath // 오버플로우를 방지하기 위한 SafeMath 함수, mul,div,sub,add 총 4개의 함수가 정의되어 있다.
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper // public으로 공개되어 있는 함수 중에 관리자만 접근 가능한 함수를 만드는 것
{
    address public owner; // 이 계약을 생성한 사람의 주소

    event OwnerTransferPropose(address indexed _from, address indexed _to); // 관리자를 변경할 경우를 대비해 OwnerTransferPropose 이벤트 정의

    modifier onlyOwner // onlyOwner가 임의의 function 함수에 접미사로 붙이게 될 경우 해당 function을 실행 하기 전에 modifier onlyOwner로 선언된 내용이 실행

    {
        require(msg.sender == owner); // 이 함수를 owner(관리자)만 사용할 수 있도록 설정
        _; // onlyOwner함수가 실행이 안되면 즉 해당 함수 function 를 실행하는 사람이 관리자가 아니면 function 함수로 접근이 불가능하게 막아 놈
    }

    function OwnerHelper () public // 생성자 
    {
        owner = msg.sender; 
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);  // 관리자를 변경하려는 대상이 이미 관리자이면 안되기 때문에 require로 검사 
        require(_to != address(0x0)); 
        owner = _to;
        OwnerTransferPropose(owner, _to);
    }
}

contract ERC20Interface // 새로운 컨트랙트인 ERC20Interface 컨트랙트 주어지는 이벤트와 함수는 이더리움에서 제공하는 함수 
			// event는 트랜잭션 내용 안에 log를 남기는 함수 
			// 컨트랙트를 실행한 사람(msg.sender)와 owner가 같은 경우는 특정 함수를 관리자만 사용 하도록 설정할 때 이다.
{
    event Transfer( address indexed _from, address indexed _to, uint _value); // Transfer는 토큰이 이동이 있을 때마다 남기는 로그
    event Approval( address indexed _owner, address indexed _spender, uint _value); // Approval는 approve함수에 대해 실행이 될 때 남기는 로그
    event Burn ( address indexed _from, uint _value);    

    function totalSupply() constant public returns (uint _supply); // 해당 스마트 컨트랙트 기반 ERC-20 토큰의 총 발행량 확인
    function balanceOf( address _who ) constant public returns (uint _value); // owner가 가지고 있는 토큰의 보유량 확인 
    function transfer( address _to, uint _value) public returns (bool _success); // 토큰을 전송 
    function approve( address _spender, uint _value ) public returns (bool _success); // 토큰을 전송 가능 하도록 spender(거래소)에게 양도할 토큰의 양을 설정
    function allowance( address _owner, address _spender ) constant public returns (uint _allowance); // owner가 spender(거래소)에게 양도 설정한 토큰의 양을 확인
    function transferFrom( address _from, address _to, uint _value) public returns (bool _success); // spender(거래소)가 거래 가능하도록 양도 받은 토큰을 _to(상대방)에게 전송
}

contract SimpleToken is ERC20Interface, OwnerHelper // SimpleToken이 ERC20Interface 및 OwnerHelper를 상속하여 ERC20Interface 및 OwnerHelper 함수를 사용가능하게 함
{
    using SafeMath for uint256; // SafeMath 라이브러리 함수를 쓰기 위한 작성문
    
    string public name; // 컨트랙트로 선언할 토큰의 이름
    uint public decimals; // 토큰의 소숫점 아래 자리수
    string public symbol; // 토큰 이름의 줄임말
    uint public totalSupply; // 토큰의 총 발행량
    address public wallet; // 0x로 시작하는 42자리의 String인 지갑의 주소
    
    uint public maxSupply = 100000000 * E18;
    uint public mktSupply =  20000000 * E18;
    uint public developmentSupply = 20000000 * E18;
    uint public saleSupply = 60000000 * E18;

    uint public saleEtherRecived;

    uint private E18 = 1000000000000000000; // 소수점 아래 자리수를 간단히 사용하기 위한 0이 18개 들어간 형식
    // 코인을 최대 소수점 아래로 18개의 0을 붙인만큼 쪼개서 교환할 수 있기 때문이다.

    uint public ethPerToken = 4000; // 1이더당 지급할 최소의 토큰의 양 

    uint public privateSaleBonus = 50;
    
    uint public preSalePrimaryBonus = 30;
    uint public presaleSecondBonus = 20;
    
    uint public crowdSalePrimaryBonus = 10;
    uint public crowdSaleSecondBonus = 0;

    uint public privateSaleStartDate = 1528070400; // 2018-06-04
    uint public privateSaleEndDate = 1528588800; // 2018-06-10
    
    uint public preSalePrimaryStartDate = 1528675200; // 2018-06-11
    uint public preSalePrimaryEndDate = 1528934400; // 2018-06-14
    
    uint public preSaleSecondStartDate = 1529020800; // 2018-06-15
    uint public preSaleSecondEndDate = 1529280000; // 2018-06-18
    
    uint public crowdSalePrimaryStartDate = 1529366400; // 2018-06-19
    uint public crowdSalePrimaryEndDate = 1529625600; // 2018-06-22
    
    uint public crowdSaleSecondStartDate = 1529712000; // 2018-06-23
    uint public crowdSaleSecondEndDate = 1529971200; // 2018-06-26
    
    bool public tokenLock; // 토큰의 생성 때 토큰의 이동을 제한하여 이동을 불가능 하도록 합니다.
    
    uint public icoIssuedMkt = 0; // 회사 마케팅 비용
    uint public icoIssuedSale = 0; // ICO를 통해 판매한 토큰의 양
    
    mapping (address => uint) internal balances; // 해당 토큰을 소유하고 있는 지갑의 수 또는 지갑들의 토큰 개수가 몇개인지 확인하는데 사용  Key : address, Value : uint
    mapping (address => mapping ( address => uint )) internal approvals; // Key : Owner의 address, Value(Key : Spender(거래소)의 address, Value : 거래소에 맡겨둔 Token의 개수)

    mapping (address => bool) internal personalLocks; // 개인 락 
    mapping (address => bool) public   personalTokenLock;
    mapping (address => uint) internal icoEtherContributeds; // 개인이 ICO에 참여한 이더의 개수
    
    event RemoveLock(address indexed _who); // 락 제거 이벤트
    event WithdrawMkt(address indexed _to, uint _value); // 회사 출금 이벤트

    function SimpleToken () public
    {
        name = &quot;PinkCherryToken&quot;; // 토큰의 이름 PinkCherryToken
        decimals = 18; // 토큰의 소숫점 아래 자리 수는 18자리
        symbol = &quot;PCT&quot;; // 토큰 이름의 줄임말은 PCT
        totalSupply = 0; // 토큰의 총발행량을 0으로 초기화
	
    	owner = msg.sender; //saleEtherReceived 컨트래트를 실행하는 사람이 관리자
    	wallet = msg.sender; // 컨트랙트를 실행하는 사람의 주소를 저장
	
	    saleEtherRecived = 0; // 판매로 수집된 이더의 개수를 저장
    
        tokenLock = true;
    }
    
    function atNow() private constant returns(uint) 
    {
        return now; // 솔리디티 내부에서는 현재시간을 now로 받아올 수 있음
    }
    
    function () payable public // 함수 호출을 통해서 이더를 보내는 것을 가능케 함
    {
        buyToken();
    }
    
    function buyToken() private
    {
        require(saleSupply > icoIssuedSale); // 판매를 할 토큰 물량과 판매된 토큰 물량을 검사 즉 판매를 할 토큰의 양이 판매된 양의 토큰보다 같아서도 안되고 					     // 무조건 커야된다. require 함수를 통과 했다는 것은 판매할 수 있는 토큰의 양이 존재한다는 것을 의미
        
        uint saleType = 0;   // 1 : Private , 2 : 1차 Pre  , 3 : 2차 Pre  , 4 : 1차 Crowd , 5 : 2차 Crowd
        uint saleBonus = 0;  // 프라이빗, 프리, 크라우드 각 시간에 맞는 판매 보너스 저장

    	uint minEth = 0; // 거래에 참여하기 위한 사용자가 갖고있어야 할 최소 이더의 수: 0
    	uint maxEth = 300 ether; // 거래에 참여해 사용할수 있는 개인의 최대 이더의 수 : 300ether
        
        uint nowTime = atNow(); // 현재 시간을 저장

        if(nowTime >= privateSaleStartDate && nowTime < privateSaleEndDate)
        {
            saleType = 1;
            saleBonus = privateSaleBonus;
        }
        else if(nowTime >= preSalePrimaryStartDate && nowTime < preSalePrimaryEndDate)
        {
            saleType = 2;
            saleBonus = preSalePrimaryBonus;
        }
        else if(nowTime >= preSaleSecondStartDate && nowTime < preSaleSecondEndDate)
        {
            saleType = 3;
            saleBonus = presaleSecondBonus;
        }
         else if(nowTime >= crowdSalePrimaryStartDate && nowTime < crowdSalePrimaryEndDate)
        {
            saleType = 4;
            saleBonus = crowdSalePrimaryBonus;
        }
        else if(nowTime >= crowdSaleSecondStartDate && nowTime < crowdSaleSecondEndDate)
        {
            saleType = 5;
            saleBonus = crowdSaleSecondBonus;
        }
        
        require (saleType >= 1 && saleType <= 5);	/* 위 코드는 지금 시간에 맞는 세일 종류(프라이빗,프리,크라우드) 및 판매 보너스 저장*/

        require (msg.value >= minEth && icoEtherContributeds[msg.sender].add(msg.value) <= maxEth); 	// 컨트랙트를 실행한 사람의 이더의 양이 최소의 이더양(0)보다 많고 개인이 ICO에 참여한 이더의 개수가 최대이더의 양(300)보다 작거나 같은지 확인
	
        uint tokens = ethPerToken.mul(msg.value); // 컨트랙트 실행한 사람이 지급한 이더(msg.value)의 개수에 맞는 토큰의 개수 저장
        tokens = tokens.mul(100 + saleBonus) / 100; // 토큰의 개수 * 거래에 참여한 시간대의 판매 보너스 
        
        require (saleSupply >= icoIssuedSale.add(tokens)); // 판매를 할 토큰의 양과 판매할 토큰의 양을 비교

        icoIssuedSale = icoIssuedSale.add(tokens); // 판매한 토큰의 양을 저장
    	totalSupply = totalSupply.add(tokens); // 토큰의 총 발행량에 판매한 토큰의 양을 저장
    	saleEtherRecived = saleEtherRecived.add(msg.value); // 받은 이더의 양을 저장 
       
	    balances[msg.sender] = balances[msg.sender].add(tokens); // 컨트랙트를 실행한 사람의 토큰의 개수를 늘려줌(토큰 발행)
	    icoEtherContributeds[msg.sender] = icoEtherContributeds[msg.sender].add(msg.value); // 컨트랙트를 실행한 개인이 ICO에 참여한 이더의 수를 더해줌
	    personalLocks[msg.sender] = true; // 개인락을 걸어줌

        Transfer(0x0, msg.sender, tokens); // 토큰의 이동이 있으면 이벤트(로그)를 기록
        
        owner.transfer(address(this).balance);   // 둘 중에 뭐가 맞을까?

    }

    function isTokenLock(address _from, address _to) public constant returns (bool lock) 
    {
    	lock = false;
	
    	if (tokenLock == true)
    	{
    	   lock = true;
    	}
	
    	if (personalTokenLock[_from] == true || personalTokenLock[_to] == true )
    	{
	       lock = true;
    	}
	
	    return lock;
    }

    function removeTokenLock() onlyOwner public
    {
        require(tokenLock == true);
        
        tokenLock = false;

    	RemoveLock(0x0);
    }

    function removePersonalTokenLock(address _who) onlyOwner public 
    {
    	require(personalTokenLock[_who] == true);
	
    	personalTokenLock[_who] = false;
	
	    RemoveLock(0x0);
    }

    function totalSupply() constant public returns (uint)
    { 
        return totalSupply; // 총 발행량 값을 반환만 함 	
    }
    
    function balanceOf(address _who) constant public returns (uint) 
    {
        return balances[_who]; // mapping 된 값인 balances에서 입력한 address인 _who가 가지고 있는 토큰의 수를 리턴함
    }
    
    function transfer(address _to, uint _value) public returns (bool) 
    {
        require(balances[msg.sender] >= _value); // 토큰 이동을 실행한 사람(msg.sender)이 이동을 신청한 값(_value)보다 많은 토큰을 가지고 있어야 함(require로 검사)
        require(tokenLock == false);
        
        balances[msg.sender] = balances[msg.sender].sub(_value); // 내가 가진 토큰의 지갑에서 토큰을 개수만큼 빼줌
        balances[_to] = balances[_to].add(_value); // 상대방의 토큰 지갑에 개수만큼 더해준다.
        
        Transfer(msg.sender, _to, _value); // event함수인 Transfer를 기록
        
        return true;
    }
    
    function approve(address _spender, uint _value) public returns (bool)
    {
        require(balances[msg.sender] >= _value); // 실행한 사람(_msg.sender)의 토큰 개수는 맡길 값보다 많이 가지고 있어야 함(require로 검사)
        
        approvals[msg.sender][_spender] = _value; // 내가 돈을 맡길 상대방(_spender)에게 맡길 값(_value)를 approvals에 값을 적용
        
        Approval(msg.sender, _spender, _value); // event함수인 Approval를 기록
        
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint) 
    {
        return approvals[_owner][_spender]; // 입력한 두개의 주소값에 대한 approvals를 리턴
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns (bool) // 거래 대행자(spender)가 Owner(_from)가 허락해준 만큼 Buyer(_to)에게 토큰을 지급
    {
        require(balances[_from] >= _value); // Owner(_from)가 가지고 있는 토큰의 개수가 입력한 토큰의 개수보다 많아야함(require로 검사)
        require(approvals[_from][msg.sender] >= _value); // 대행자에게 Owner가 허락해준 토큰의 개수 또한 입력한 토큰의 개수보다 많아야 함(require로 검사)    
        require(tokenLock == false); 
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value); // 대행자에게 허락한 토큰의 개수를 입력한 토큰의 개수에서 빼줌
        balances[_from] = balances[_from].sub(_value); // 내가 가지고 있는 토큰의 개수를 입력한 토큰의 개수에서 빼줌
        balances[_to]  = balances[_to].add(_value); // 상대방의 토큰 지갑에 입력한 토큰의 개수만큼 더해줌
        
        Transfer(_from, _to, _value); // event함수인 Transfer를 기록
        
        return true;
    }
    
    function withdrawMkt(address _to, uint _value) public onlyOwner // 회사 보유 토큰 출금
    {
        require(mktSupply > icoIssuedMkt); // 회사가 가지고 있는 토큰의 물량이 출금할 토큰의 물량보다 많아야 함
        require(mktSupply > icoIssuedMkt.add(_value));
        
        uint tokens = _value * E18; 
        
        balances[_to] = balances[_to].add(tokens); // 상대방에게 토큰을 지급함
        icoIssuedMkt = icoIssuedMkt.add(tokens); // 회사가 판매한 토큰의 양을 저장
        totalSupply = totalSupply.add(tokens); 
        
        Transfer(0x0, _to, tokens);
    }

    function airdrop(address[] _to, uint[] value) public onlyOwner 
    {
        uint valueSum=0;

        for(uint i=0; i<= value.length; i++){
            valueSum +=  value[i];
        }

        require(saleSupply >= valueSum);

        for(uint j=0; j<= _to.length; j++) {
            transfer(_to[j], value[j]);
            Transfer(owner,_to[j], value[j]);
        }
    }

    function burn(uint256 _value) public returns (bool _success)
    {
       	require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        Burn(msg.sender, _value);

        return true;
    }


}