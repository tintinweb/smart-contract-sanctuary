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
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    mapping (address => uint256) public balanceOf;
}

contract Escrow is arbitrated {

    enum StepState {Placed, AcceptedByDoctor, ConfirmedByPatient, Disputed, Closed }
    enum ArbitratorDecision {None, Patient, Doctor}

    event OrderPlaced(
        bytes16 id,
        address client, 
        address doctor,
        uint256 amount
    );

    event OrderConfirmed(
        bytes16 id
    );

    event OrderAccepted(
        bytes16 id
    );

    event OrderCompletedByDoctor(
        bytes16 id,
        bool completion
    );
    
    event OrderCompletedByClient(
        bytes16 id,
        bool completion
    );

    event OrderCompletionAgreement(
        bytes16 id,
        bool completion
    );

    event OrderCompletionRequiresDispute(
        bytes16 id
    );

    event OrderCompletedAndPaid(
        bytes16 id
    );

    event OrderNotCompletedAndRefund (
        bytes16 id
    );

    event OrderDisputeResolved (
        bytes16 id,
        bool resolution
    );

    struct Step {
        address patient;
        address doctor;
        uint256 amount;
        uint256 feeAmount;
        
        bool completionConfirmedByDoctor;
        bool completionConfirmedByPatient;
        bool requiresArbitration;
        ArbitratorDecision disputeResult;
        StepState state;
    }

    mapping(bytes16 => Step) steps;

    doccoin coin;
    address feeAccount;
    uint256 feeAmount;

    uint numberOfSuccessfulSteps;
    uint numberOfOpenSteps;
    uint numberOfDisputedStepsProDoctor;
    uint numberOfDisputedStepsProPatient;

    uint sumAmountOfSuccessfulSteps;
    uint sumAmountOfDisputedStepsProDoctor;
    uint sumAmountOfDisputedStepsProPatient;
    uint sumAmountOfOpenSteps;

    constructor(address coinAddress, address feeAccount_, uint256 feeAmount_) public {
        coin = doccoin(coinAddress);
        feeAccount = feeAccount_;
        feeAmount = feeAmount_;
    }

    function setFeeAccount(address feeAccount_) onlyOwner public {
        feeAccount = feeAccount_;
    }

    function setFeeAmount(uint256 feeAmount_) onlyOwner public {
        feeAmount = feeAmount_;
    }

    function getStep(bytes16 orderId) view private returns (Step storage step1) {
        Step storage step = steps[orderId];
        require(step.patient != 0x0 && step.doctor != 0x0);
        return step;
    }

    function withdrawFee(address to) onlyOwner public {
        require(coin.transferFrom(feeAccount, to, coin.balanceOf(feeAccount)));
    }

    function placeOrder(bytes16 orderId, address patient, address doctor, uint256 amount) onlyOwner public
    {
        require(patient != address(0));
        require(doctor != address(0));
        Step storage step = steps[orderId];
        require(step.patient == 0x0 && step.doctor == 0x0);
        steps[orderId] = Step(patient, doctor, amount, feeAmount, false, false, false, ArbitratorDecision.None, StepState.Placed);
        emit OrderPlaced(orderId, patient, doctor, amount);
    }

    function acceptOrder(bytes16 orderId) public {
        Step storage step = getStep(orderId);
        require(msg.sender == step.doctor);
        require(step.state == StepState.Placed);
        step.state = StepState.AcceptedByDoctor;
        emit OrderAccepted(orderId);
    }

    function confirmOrder(bytes16 orderId) public {
        Step storage step = getStep(orderId);
        require(msg.sender == step.patient);
        require(step.state == StepState.AcceptedByDoctor);
        uint256 balanceOfPatient = coin.balanceOf(step.patient);
        require(balanceOfPatient > step.amount + step.feeAmount);
        step.state = StepState.ConfirmedByPatient;
        emit OrderConfirmed(orderId);
        numberOfOpenSteps += 1;
        sumAmountOfOpenSteps += step.amount;
        //Transfer from client&#39;s account to escrow account
        coin.transferFrom(msg.sender, this, step.amount);
        //Transfer of fee
        coin.transferFrom(msg.sender, feeAccount, step.feeAmount);
    }    

    function confirmOrderCompletionByDoctor(bytes16 orderId, bool completed) public {
        Step storage step = getStep(orderId);
        require(msg.sender == step.doctor);
        require(step.state == StepState.ConfirmedByPatient);
        step.completionConfirmedByDoctor = completed;
        emit OrderCompletedByDoctor(orderId, completed);
    }

    function confirmOrderCompletionByPatient(
        bytes16 orderId, 
        bool completed
    ) public {
        Step storage step = getStep(orderId);
        require(msg.sender == step.patient);
        require(step.state == StepState.ConfirmedByPatient);
        step.completionConfirmedByPatient = completed;

        if (step.completionConfirmedByPatient) {
            step.state = StepState.Closed;
            numberOfSuccessfulSteps += 1;
            sumAmountOfSuccessfulSteps += step.amount;
            numberOfOpenSteps -= 1;
            sumAmountOfOpenSteps -= step.amount;
            pay(orderId, step);
        } else {
            step.state = StepState.Disputed;
            emit OrderCompletionRequiresDispute(orderId);
        }
    }

    function resolveDispute(bytes16 orderId, bool patientWon) onlyArbitrator public {
        Step storage step = getStep(orderId);
        require(step.state == StepState.Disputed);
        require(step.disputeResult == ArbitratorDecision.None);
        require(!step.completionConfirmedByPatient);
        numberOfOpenSteps -= 1;
        sumAmountOfOpenSteps -= step.amount;
        step.state = StepState.Closed;
        if (patientWon) {
            step.disputeResult = ArbitratorDecision.Patient;
            numberOfDisputedStepsProPatient += 1;
            sumAmountOfDisputedStepsProPatient += step.amount;
            refund(orderId, step);
        } else {
            step.disputeResult = ArbitratorDecision.Doctor;
            numberOfDisputedStepsProDoctor += 1;
            sumAmountOfDisputedStepsProDoctor += step.amount;
            pay(orderId, step);
        }
    }

    function pay(bytes16 orderId, Step step) private {
        emit OrderCompletedAndPaid(orderId);
        removeStep(orderId);
        coin.transfer(step.doctor, step.amount);
    }

    function refund(bytes16 orderId, Step step) private {
        emit OrderNotCompletedAndRefund(orderId);
        removeStep(orderId);
        coin.transfer(step.patient, step.amount);
    }

    function removeStep(bytes16 orderId) private {
        delete steps[orderId];
    }

    function getNumberOfSuccessfulSteps() view public returns(uint number) {
        return numberOfSuccessfulSteps;
    }

    function getNumberOfOpenSteps() view public returns(uint number) {
        return numberOfOpenSteps;
    }

    function getNumberOfDisputedStepsProDoctor() view public returns(uint number) {
        return numberOfDisputedStepsProDoctor;
    }

    function getNumberOfDisputedStepsProPatient() view public returns(uint number) {
        return numberOfDisputedStepsProPatient;
    }

    function getSumAmountOfSuccessfulSteps() view public returns(uint number) {
        return sumAmountOfSuccessfulSteps;
    }

    function getSumAmountOfDisputedStepsProDoctor() view public returns(uint number) {
        return sumAmountOfDisputedStepsProDoctor;
    }

    function getSumAmountOfDisputedStepsProPatient() view public returns(uint number) {
        return sumAmountOfDisputedStepsProPatient;
    }

    function getSumAmountOfOpenSteps() view public returns(uint number) {
        return sumAmountOfOpenSteps;
    }

}