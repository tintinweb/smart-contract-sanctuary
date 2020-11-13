pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Sonergy_Survey_System_v1 is Ownable{
address private sonergyTokenAddress;
address private messenger;
enum ChangeTypes{ SURVEY, REGISTRATION, ADVERT, FEE }
mapping (uint256 => uint256) private surveyPlans;
mapping (uint256 => uint256) private advertPlans;
mapping(address => bool) isAValidator;

uint public fees;
uint public validatorRegistrationFee;

     struct ValidatedAnswers{
      uint participantID;
      uint[] validators;
      uint surveyID;
      address messenger;
    }
ValidatedAnswers[] validatedAns; 
mapping(uint => ValidatedAnswers[]) listOfValidatedAns;
using SafeMath for uint256;

constructor(address _sonergyTokenAddress, uint _fee, uint _validatorRegistrationFee) public{
   sonergyTokenAddress = _sonergyTokenAddress;
   fees = _fee;
   validatorRegistrationFee = _validatorRegistrationFee;
   
}
event PriceChanged(address initiator, uint _from, uint _to, uint _duration, ChangeTypes _type);
event NewValidator(uint _userID, address _validator);
event ValidatedQuestionByUser(uint[] _validators, uint _participantID, uint _survey_id, uint _newID);
event Paid(address creator, uint amount, uint fee, uint _duration, uint survey_id, ChangeTypes _type);
event MessengerChanged(address _from, address _to);
modifier onlyMessenger() {
        require(msg.sender == messenger, "caller is not a messenger");
        _;
}


function payForSurvey(uint256 survey_id, uint _duration) public {
IERC20 sonergyToken = IERC20(sonergyTokenAddress);
uint amount = surveyPlans[_duration];
require(amount > 0, "Invalid plan");
uint fee = uint(int256(amount) / int256(10000) * int256(fees));
require(sonergyToken.allowance(msg.sender, address(this)) >= amount.add(fee), "Non-sufficient funds");
require(sonergyToken.transferFrom(msg.sender, address(this), amount.add(fee)), "Fail to tranfer fund");
emit Paid(msg.sender, amount, fee, _duration, survey_id,  ChangeTypes.SURVEY);

}

function payForAdvert(uint256 advert_id, uint _duration) public {
IERC20 sonergyToken = IERC20(sonergyTokenAddress);
uint amount = advertPlans[_duration];
require(amount > 0, "Invalid plan");

require(sonergyToken.allowance(msg.sender, address(this)) >= amount, "Non-sufficient funds");
require(sonergyToken.transferFrom(msg.sender, address(this), amount), "Fail to tranfer fund");
emit Paid(msg.sender, amount,0, _duration, advert_id, ChangeTypes.ADVERT);

}


function updateSurveyfee(uint256 _fee) public onlyOwner{
    uint256 currentSurveyFee = fees;
    fees = _fee;
    emit PriceChanged(msg.sender, currentSurveyFee, _fee, 0, ChangeTypes.FEE);
}

function updateRegistrationFee(uint256 _fee) public onlyOwner{
    uint256 currentRegistrationFee = validatorRegistrationFee;
    validatorRegistrationFee = _fee;
    emit PriceChanged(msg.sender, currentRegistrationFee, _fee, 0, ChangeTypes.REGISTRATION);
}

function updateSurveyPlan(uint256 _price, uint _duration) public onlyOwner{
    uint256 currentSurveyPlanPrice = surveyPlans[_duration];
    surveyPlans[_duration] = _price;
    emit PriceChanged(msg.sender, currentSurveyPlanPrice, _price, _duration, ChangeTypes.SURVEY);
}

function updateAdvertPlan(uint256 _price, uint _duration) public onlyOwner{
    uint256 currentAdvertPlanPrice = advertPlans[_duration];
     advertPlans[_duration] = _price;
     emit PriceChanged(msg.sender, currentAdvertPlanPrice, _price, _duration, ChangeTypes.ADVERT);
   
}


function setMessenger(address _messenger) public onlyOwner{
    address currentMessenger = messenger;
    messenger = _messenger;
    emit MessengerChanged(currentMessenger, _messenger);
}

function withdrawEarning() public onlyOwner{
    IERC20 sonergyToken = IERC20(sonergyTokenAddress);
    require(sonergyToken.transfer(owner(), sonergyToken.balanceOf(address(this))), "Fail to empty vault");
}

function becomeAValidator(uint _userID) public{
     require(!isAValidator[msg.sender], "Already a validator");
     IERC20 sonergyToken = IERC20(sonergyTokenAddress);
     require(sonergyToken.allowance(msg.sender, address(this)) >= validatorRegistrationFee, "Non-sufficient funds");
     require(sonergyToken.transferFrom(msg.sender, address(this), validatorRegistrationFee), "Fail to tranfer fund");
     isAValidator[msg.sender] = true;
     emit NewValidator(_userID, msg.sender);
}


function validatedAnswers(uint _participantID, uint[] memory _validators, uint _surveyID) public onlyMessenger{
    ValidatedAnswers memory _validatedAnswers = ValidatedAnswers({
      participantID: _participantID,
      validators: _validators,
      surveyID: _surveyID,
      messenger: msg.sender
    });
    
    validatedAns.push(_validatedAnswers);
    uint256 newID = validatedAns.length - 1;
   emit ValidatedQuestionByUser(_validators, _participantID, _surveyID, newID);
}

  function getvalidatedAnswersByID(uint _id) external view returns(uint _participantID, uint[] memory _validators, uint _surveyID,  address _messenger){
         ValidatedAnswers memory _validatedAnswers = validatedAns[_id];
         return (_validatedAnswers.participantID, _validatedAnswers.validators,_validatedAnswers.surveyID, _validatedAnswers.messenger);
     }

function getPriceOfPlan(uint _duration) public view returns (uint256 _price) {
   return surveyPlans[_duration];
}

function getFees() public view returns (uint256 _reg, uint256 _survey) {
   return (validatorRegistrationFee, fees);
}


function getPriceOfAdevert(uint _duration) public view returns (uint256 _price) {
   return advertPlans[_duration];
}
function setSonergyTokenAddress(address _sonergyTokenAddress) public onlyOwner{
     sonergyTokenAddress = _sonergyTokenAddress;
    }

   

    function getSonergyTokenAddress() public view returns (address _sonergyTokenAddress) {
        return(sonergyTokenAddress);
    }

}