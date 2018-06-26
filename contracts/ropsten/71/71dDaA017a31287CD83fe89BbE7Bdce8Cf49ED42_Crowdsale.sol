pragma solidity ^0.4.14;

interface token { 
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary; // 최종적으로 ICO를 통해 모인 이더리움을 받게 될 주소
    uint public fundingGoal; // 모아야 하는 이더리움의 양
    uint public amountRaised; // 현재까지 모아진 이더리움의 양
    uint public deadline; // ICO 투자 마감 deadline
    uint public price; // 이더리움 1 wei당 코인 가격
    token public tokenReward; // ICO하는 코인 주소
    Funder[] public funders; // 지금까지 투자한 투자자들
 
    struct Funder { // 투자자들 정보는 그들의 주소와 투자 금액만 기록합니다.
        address addr;
        uint amount;
    }
 
    // 투자가 일어났을 때 발생시킬 로그기록입니다.
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    constructor(address _beneficiary, uint _fundingGoal, uint _duration, uint _price, address _reward) public {
        beneficiary = _beneficiary; // 최종 수혜자를 지정합니다.
        fundingGoal = _fundingGoal; // 목표 이더리움을 설정합니다.
        deadline = now + _duration * 1 minutes; // deadline은 현재에서 duration 분만큼 후로 설정합니다.
        price = _price; // 코인 가격(이더리움 대비)을 설정. price를 10 으로 하면 코인가격이 10eth라는 뜻
        tokenReward = token(_reward); // 생성된 코인을 불러옵니다.
    }
    
    function () payable public {
        uint amount = msg.value; // 투자된 이더리움을 변수로 받아옵니다.
        // 투자자 리스트에 주소와 투자금액을 추가합니다.
        funders[funders.length++] = Funder({addr: msg.sender, amount: amount});
        // 현재까지 총 투자된 금액에 투자금을 더합니다.
        amountRaised += amount;
        // 투자자한테 코인을 환산해서 보냅니다.
        tokenReward.transfer(msg.sender, amount / price);
        // 투자되었다는 이벤트를 발생시킵니다.
        emit FundTransfer(msg.sender, amount, true);
    }
    
    modifier afterDeadline() { if (now >= deadline) _; }
 
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){ // 만약 목표 투자금 이상을 모았을 때
            beneficiary.transfer(amountRaised); // 수혜자에게 투자금을 보냅니다.
            emit FundTransfer(beneficiary, amountRaised, false); // 로그 기록으로 남깁니다.
        } else { // 목표 투자금을 채우지 못했을 경우,
            // 각 투자자에게 투자금을 돌려줍니다. 각각의 로그기록도 발생시킵니다.
            for (uint i = 0; i < funders.length; ++i) {
              funders[i].addr.transfer(funders[i].amount);
              emit FundTransfer(funders[i].addr, funders[i].amount, false);
            }
        }
        // deadline이 지났으니 계약은 파기합니다.
        selfdestruct(beneficiary);
    }
    
    
    
}