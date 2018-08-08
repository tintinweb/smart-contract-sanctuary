pragma solidity ^0.4.23;
// import "./doccoin.sol";
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract arbitrated is owned {
    mapping(address => bool) public arbitrators;

    constructor() public {
        arbitrators[msg.sender];
    }

    modifier onlyArbitrator {
        require(arbitrators[msg.sender]);
        _;
    }

    function addArbitrator(address newArbitrator) onlyOwner public {
        require(!arbitrators[newArbitrator]);
        arbitrators[newArbitrator] = true;
    }

    function removeArbitrator(address arbitrator) onlyOwner public {
        require(arbitrators[arbitrator]);
        delete arbitrators[arbitrator];
    }
}

contract doccoin {
    function transfer(
        address _to, 
        uint256 _value
    ) 
        public;

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool success);
    
    mapping (address => uint256) public balanceOf;
}

contract Escrow is arbitrated {

    enum DealState {
        Placed, 
        AcceptedByDoctor, 
        ConfirmedByPatient, 
        Disputed, 
        Closed
    }
    enum ArbitratorDecision {
        None, 
        Patient, 
        Doctor
    }
    enum FeeCalculationMethod { 
        PlusPercent, 
        MinusPercent, 
        PlusFixedAmount, 
        MinusFixedAmount
    }

    event DealPlaced(
        bytes16 id,
        address client, 
        address doctor,
        uint256 amount
    );

    event DealConfirmed(
        bytes16 id
    );

    event DealAccepted(
        bytes16 id
    );

    event DealCompletedByDoctor(
        bytes16 id,
        bool completion
    );
    
    event DealCompletedByClient(
        bytes16 id,
        bool completion
    );

    event DealCompletionAgreement(
        bytes16 id,
        bool completion
    );

    event DealCompletionRequiresDispute(
        bytes16 id
    );

    event DealCompletedAndPaid(
        bytes16 id
    );

    event DealNotCompletedAndRefund (
        bytes16 id
    );

    event DealDisputeResolved (
        bytes16 id,
        bool resolution
    );

    struct Deal {
        address patient;
        address doctor;
        uint256 amount;
        uint256 feeAmount;
        FeeCalculationMethod feeCalculationMethod;
        
        bool completionConfirmedByDoctor;
        bool completionConfirmedByPatient;
        bool requiresArbitration;
        ArbitratorDecision disputeResult;
        DealState state;
    }

    mapping(bytes16 => Deal) deals;

    doccoin coin;
    address feeAccount;
    uint256 feeAmount;
    FeeCalculationMethod feeCalculationMethod;

    uint numberOfSuccessfulDeals;
    uint numberOfOpenDeals;
    uint numberOfDisputedDealsProDoctor;
    uint numberOfDisputedDealsProPatient;

    uint sumAmountOfSuccessfulDeals;
    uint sumAmountOfDisputedDealsProDoctor;
    uint sumAmountOfDisputedDealsProPatient;
    uint sumAmountOfOpenDeals;

    constructor(
        address _coinAddress, 
        address _feeAccount, 
        uint256 _feeAmount, 
        FeeCalculationMethod _feeCalculationMethod
    ) 
        public 
    {
        coin = doccoin(_coinAddress);
        feeAccount = _feeAccount;
        feeAmount = _feeAmount;
        feeCalculationMethod = _feeCalculationMethod;
    }

    function setFeeAccount(address _feeAccount) public onlyOwner  {
        feeAccount = _feeAccount;
    }

    function setFeeCalculationParameters(
        uint256 _feeAmount, 
        FeeCalculationMethod _feeCalculationMethod
    ) 
        public 
        onlyOwner 
    {
        if (
            _feeCalculationMethod == FeeCalculationMethod.PlusPercent || 
            _feeCalculationMethod == FeeCalculationMethod.MinusPercent
        ) {
            require(_feeAmount <= 100);
        }
        feeCalculationMethod = _feeCalculationMethod;
        feeAmount = _feeAmount;
    }

    function withdrawFee(address _to) onlyOwner public {
        require(coin.transferFrom(
            feeAccount, 
            _to, 
            coin.balanceOf(feeAccount)
        ));
    }

    function placeDeal(
        bytes16 _dealId, 
        address _patient, 
        address _doctor, 
        uint256 _amount
    ) 
        onlyOwner 
        public 
        returns (uint256 _userExpense) 
    {
        require(_patient != address(0));
        require(_doctor != address(0));
        Deal storage deal = deals[_dealId];
        require(deal.patient == 0x0 && deal.doctor == 0x0);
        deals[_dealId] = Deal(
            _patient, _doctor, 
            _amount, feeAmount, feeCalculationMethod, 
            false, false, false, 
            ArbitratorDecision.None, DealState.Placed
        );
        (_userExpense,) = calculateUserExpense(
            _amount, 
            feeAmount, 
            feeCalculationMethod
        );
        emit DealPlaced(_dealId, _patient, _doctor, _amount);
    }

    function acceptDeal(bytes16 _dealId) public {
        Deal storage deal = getDeal(_dealId);
        require(msg.sender == deal.doctor);
        require(deal.state == DealState.Placed);
        deal.state = DealState.AcceptedByDoctor;
        emit DealAccepted(_dealId);
    }

    function confirmDeal(bytes16 _dealId) public {
        Deal storage deal = getDeal(_dealId);
        require(msg.sender == deal.patient);
        require(deal.state == DealState.AcceptedByDoctor);
        uint256 balanceOfPatient = coin.balanceOf(deal.patient);
        require(balanceOfPatient > deal.amount + deal.feeAmount);
        deal.state = DealState.ConfirmedByPatient;
        emit DealConfirmed(_dealId);
        numberOfOpenDeals += 1;
        sumAmountOfOpenDeals += deal.amount;
        (
            uint256 userExpense, 
            uint256 calculatedFee
        ) = calculateUserExpense(
            deal.amount, 
            deal.feeAmount, 
            deal.feeCalculationMethod
        );
        //Transfer from client&#39;s account to escrow account
        require(coin.transferFrom(
            msg.sender, 
            this, 
            userExpense - calculatedFee
        ));
        //Transfer of fee
        require(coin.transferFrom(
            msg.sender, 
            feeAccount, 
            calculatedFee
        ));
    }    

    function confirmDealCompletionByDoctor(
        bytes16 _dealId, 
        bool _completed
    ) 
        public 
    {
        Deal storage deal = getDeal(_dealId);
        require(msg.sender == deal.doctor);
        require(deal.state == DealState.ConfirmedByPatient);
        deal.completionConfirmedByDoctor = _completed;
        emit DealCompletedByDoctor(_dealId, _completed);
    }

    function confirmDealCompletionByPatient(
        bytes16 _dealId, 
        bool _completed
    ) 
        public 
    {
        Deal storage deal = getDeal(_dealId);
        require(msg.sender == deal.patient);
        require(deal.state == DealState.ConfirmedByPatient);
        deal.completionConfirmedByPatient = _completed;

        if (deal.completionConfirmedByPatient) {
            deal.state = DealState.Closed;
            numberOfSuccessfulDeals += 1;
            sumAmountOfSuccessfulDeals += deal.amount;
            numberOfOpenDeals -= 1;
            sumAmountOfOpenDeals -= deal.amount;
            pay(_dealId, deal);
        } else {
            deal.state = DealState.Disputed;
            emit DealCompletionRequiresDispute(_dealId);
        }
    }

    function resolveDispute(
        bytes16 _dealId, 
        bool _patientWon
    ) 
        onlyArbitrator 
        public 
    {
        Deal storage deal = getDeal(_dealId);
        require(deal.state == DealState.Disputed);
        require(deal.disputeResult == ArbitratorDecision.None);
        require(!deal.completionConfirmedByPatient);
        numberOfOpenDeals -= 1;
        sumAmountOfOpenDeals -= deal.amount;
        deal.state = DealState.Closed;
        if (_patientWon) {
            deal.disputeResult = ArbitratorDecision.Patient;
            numberOfDisputedDealsProPatient += 1;
            sumAmountOfDisputedDealsProPatient += deal.amount;
            refund(_dealId, deal);
        } else {
            deal.disputeResult = ArbitratorDecision.Doctor;
            numberOfDisputedDealsProDoctor += 1;
            sumAmountOfDisputedDealsProDoctor += deal.amount;
            pay(_dealId, deal);
        }
    }

    function removeDeal(bytes16 _dealId) public onlyOwner {
        Deal storage deal = getDeal(_dealId);
        require(
            deal.state == DealState.Placed || 
            deal.state == DealState.AcceptedByDoctor || 
            deal.state == DealState.Closed
        );
        removeDealInternal(_dealId);
    }

    function getNumberOfSuccessfulDeals() 
        view 
        public
        onlyOwner
        returns (uint _number) 
    {
        return numberOfSuccessfulDeals;
    }

    function getNumberOfOpenDeals() 
        view 
        public
        onlyOwner
        returns (uint _number) 
    {
        return numberOfOpenDeals;
    }

    function getNumberOfDisputedDealsProDoctor() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return numberOfDisputedDealsProDoctor;
    }

    function getNumberOfDisputedDealsProPatient() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return numberOfDisputedDealsProPatient;
    }

    function getSumAmountOfSuccessfulDeals() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return sumAmountOfSuccessfulDeals;
    }

    function getSumAmountOfDisputedDealsProDoctor() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return sumAmountOfDisputedDealsProDoctor;
    }

    function getSumAmountOfDisputedDealsProPatient() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return sumAmountOfDisputedDealsProPatient;
    }

    function getSumAmountOfOpenDeals() 
        view 
        public 
        onlyOwner
        returns (uint _number) 
    {
        return sumAmountOfOpenDeals;
    }

    function getDeal(bytes16 _dealId) 
        view 
        private 
        returns (Deal storage _deal) 
    {
        Deal storage deal = deals[_dealId];
        require(deal.patient != 0x0 && deal.doctor != 0x0);
        return deal;
    }

    function pay(
        bytes16 _dealId, 
        Deal _deal
    ) 
        private 
    {
        emit DealCompletedAndPaid(_dealId);
        removeDealInternal(_dealId);
        coin.transfer(_deal.doctor, _deal.amount);
    }

    function refund(
        bytes16 _dealId, 
        Deal _deal
    ) 
        private 
    {
        emit DealNotCompletedAndRefund(_dealId);
        removeDealInternal(_dealId);
        coin.transfer(_deal.patient, _deal.amount);
    }

    function removeDealInternal(bytes16 _dealId) private {
        delete deals[_dealId];
    }
    
    function calculateUserExpense(
        uint256 _amount, 
        uint256 _feeAmount, 
        FeeCalculationMethod _feeCalculationMethod
    ) 
        pure 
        private 
        returns (
            uint256 _userExpense, 
            uint256 _calculatedFee
        ) 
    {
        if (
            _feeCalculationMethod == FeeCalculationMethod.MinusPercent || 
            _feeCalculationMethod == FeeCalculationMethod.PlusPercent
        ) {
            _calculatedFee = (_amount * _feeAmount) / 100;
        } else {
            _calculatedFee = _feeAmount;
        }
        if (
            _feeCalculationMethod == FeeCalculationMethod.MinusPercent || 
            _feeCalculationMethod == FeeCalculationMethod.MinusFixedAmount
        ) {
            _userExpense = _amount;
        } else {
            _userExpense = _amount + _calculatedFee;
        }
    }

}