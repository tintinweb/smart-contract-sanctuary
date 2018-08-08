pragma solidity ^0.4.11;


contract ScamStampToken {
    //The Scam Stamp Token is intended to mark an address as SCAM.
    //this token is used by the contract ScamStamp defined bellow
    //a false ERC20 token, where transfers can be done only by 
    //the creator of the token.

    string public constant name = "SCAM Stamp Token";
    string public constant symbol = "SCAM_STAMP";
    uint8 public constant decimals = 0;
    uint256 public totalSupply;

    // Owner of this contract
    address public owner;
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    // Balances for each account
    mapping(address => uint256) balances;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function balanceOf(address _owner) constant returns (uint balance){
        return balances[_owner];
    }
    //Only the owner of the token can transfer.
    //tokens are being generated on the fly,
    //tokenSupply increases with double the amount that is required to be transfered 
    //if the amount isn&#39;t available to transfer
    //newly generated tokens are never burned.
    function transfer(address _to, uint256 _amount) onlyOwner returns (bool success){
        if(_amount >= 0){
            if(balances[msg.sender] >= _amount){
                balances[msg.sender] -= _amount;
                balances[_to] += _amount;
                Transfer(msg.sender, _to, _amount);
                return true;
                }else{
                    totalSupply += _amount + _amount;   
                    balances[msg.sender] += _amount + _amount;
                    balances[msg.sender] -= _amount;
                    balances[_to] += _amount;
                    Transfer(msg.sender, _to, _amount);
                    return true;
                }
            }
    }
    function transferBack(address _from, uint256 _amount) onlyOwner returns (bool success){
        if(_amount >= 0){
            if(balances[_from] >= _amount){
                balances[_from] -= _amount;
                balances[owner] += _amount;
                Transfer(_from, owner, _amount);
                return true;
            }else{
                _amount = balances[_from];
                balances[_from] -= _amount;
                balances[owner] += _amount;
                Transfer(_from, owner, _amount);
                return true;
            }
            }else{
                return false;
            }
    }


    function ScamStampToken(){
        owner = msg.sender;
        totalSupply = 1;
        balances[owner] = totalSupply;

    }
}


contract ScamStamp{
//the contract is intended as a broker between a scammer address and the scamee
modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}
modifier hasMinimumAmountToFlag(){
    require(msg.value >= pricePerUnit);
    _;
}

function mul(uint a, uint b) internal returns (uint) {
uint c = a * b;
require(a == 0 || c / a == b);
return c;
}

function div(uint a, uint b) internal returns (uint) {
require(b > 0);
uint c = a / b;
require(a == b * c + a % b);
return c;
}

function sub(uint a, uint b) internal returns (uint) {
require(b <= a);
return a - b;
}

function add(uint a, uint b) internal returns (uint) {
uint c = a + b;
require(c >= a);
return c;
}


address public owner;
//the address of the ScamStampToken created by this contract
address public scamStampTokenAddress;
//the actual ScamStampToken
ScamStampToken theScamStampToken; 
//the contract has a brokerage fee applied to all payable function calls
//the fee is 2% of the amount sent.
//the fee is directly sent to the owner of this contract
uint public contractFeePercentage = 2;

//the price for 1 ScamStapToken is 1 finney
uint256 public pricePerUnit = 1 finney;
//for a address to lose the ScamStampTokens it must pay a reliefRatio per token
//for each 1 token that it holds it must pay 10 finney to make the token dissapear from they account
uint256 public reliefRatio = 10;
//how many times an address has been marked as SCAM
mapping (address => uint256) public scamFlags;
//contract statistics.
uint public totalNumberOfScammers = 0;
uint public totalScammedQuantity = 0;
uint public totalRepaidQuantity = 0;

mapping (address => mapping(address => uint256)) flaggedQuantity;
mapping (address => mapping(address => uint256)) flaggedRepaid;
//the address that is flagging an address as scam has an issurance
//when the scammer repays the scammed amount, the insurance will be sent
//to the owner of the contract
mapping (address => mapping(address => uint256)) flaggerInsurance;

mapping (address => mapping(address => uint256)) contractsInsuranceFee;
mapping (address => address[]) flaggedIndex;
//how much wei was the scammer been marked for.
mapping (address => uint256) public totalScammed;
//how much wei did the scammer repaid
mapping (address => uint256) public totalScammedRepaid;

function ScamStamp() {
owner = msg.sender;
scamStampTokenAddress = new ScamStampToken();
theScamStampToken = ScamStampToken(scamStampTokenAddress);

}
event MarkedAsScam(address scammer, address by, uint256 amount);
//markAsSpam: payable function. 
//it flags the address as a scam address by sending ScamStampTokens to it.
//the minimum value sent with this function call must be  pricePerUnit - set to 1 finney
//the value sent to this function will be held as insurance by this contract.
//it can be withdrawn by the calee anytime before the scammer pays the debt.

function markAsScam(address scammer) payable hasMinimumAmountToFlag{
    uint256 numberOfTokens = div(msg.value, pricePerUnit);
    updateFlagCount(msg.sender, scammer, numberOfTokens);

    uint256 ownersFee = div( mul(msg.value, contractFeePercentage), 100 );//mul(msg.value, div(contractFeePercentage, 100));
    uint256 insurance = msg.value - ownersFee;
    owner.transfer(ownersFee);
    flaggerInsurance[msg.sender][scammer] += insurance;
    contractsInsuranceFee[msg.sender][scammer] += ownersFee;
    theScamStampToken.transfer(scammer, numberOfTokens);
    uint256 q = mul(reliefRatio, mul(msg.value, pricePerUnit));
    MarkedAsScam(scammer, msg.sender, q);
}
//once an address is flagged as SCAM it can be forgiven by the flagger 
//unless the scammer already started to pay its debt

function forgiveIt(address scammer) {
    if(flaggerInsurance[msg.sender][scammer] > 0){
        uint256 insurance = flaggerInsurance[msg.sender][scammer];
        uint256 hadFee = contractsInsuranceFee[msg.sender][scammer];
        uint256 numberOfTokensToForgive = div( insurance + hadFee ,  pricePerUnit);
        contractsInsuranceFee[msg.sender][scammer] = 0;
        flaggerInsurance[msg.sender][scammer] = 0;
        totalScammed[scammer] -= flaggedQuantity[scammer][msg.sender];
        totalScammedQuantity -= flaggedQuantity[scammer][msg.sender];
        flaggedQuantity[scammer][msg.sender] = 0;
        theScamStampToken.transferBack(scammer, numberOfTokensToForgive);

        msg.sender.transfer(insurance);
        Forgived(scammer, msg.sender, insurance+hadFee);
    }
}
function updateFlagCount(address from, address scammer, uint256 quantity) private{
    scamFlags[scammer] += 1;
    if(scamFlags[scammer] == 1){
        totalNumberOfScammers += 1;
    }
    uint256 q = mul(reliefRatio, mul(quantity, pricePerUnit));
    flaggedQuantity[scammer][from] += q;
    flaggedRepaid[scammer][from] = 0;
    totalScammed[scammer] += q;
    totalScammedQuantity += q;
    addAddressToIndex(scammer, from);
}



function addAddressToIndex(address scammer, address theAddressToIndex) private returns(bool success){
    bool addressFound = false;
    for(uint i = 0; i < flaggedIndex[scammer].length; i++){
        if(flaggedIndex[scammer][i] == theAddressToIndex){
            addressFound = true;
            break;
        }
    }
    if(!addressFound){
        flaggedIndex[scammer].push(theAddressToIndex);
    }
    return true;
}
modifier toBeAScammer(){
    require(totalScammed[msg.sender] - totalScammedRepaid[msg.sender] > 0);
    _;
}
modifier addressToBeAScammer(address scammer){
    require(totalScammed[scammer] - totalScammedRepaid[scammer] > 0);
    _;
}
event Forgived(address scammer, address by, uint256 amount);
event PartiallyForgived(address scammer, address by, uint256 amount);
//forgiveMe - function called by scammer to pay any of its debt
//If the amount sent to this function is greater than the amount 
//that is needed to cover or debt is sent back to the scammer.
function forgiveMe() payable toBeAScammer returns (bool success){
    address scammer = msg.sender;

    forgiveThis(scammer);
    return true;
}
//forgiveMeOnBehalfOf - somebody else can pay a scammer address debt (same as above)
function forgiveMeOnBehalfOf(address scammer) payable addressToBeAScammer(scammer) returns (bool success){

        forgiveThis(scammer);

        return true;
    }
    function forgiveThis(address scammer) private returns (bool success){
        uint256 forgivenessAmount = msg.value;
        uint256 contractFeeAmount =  div(mul(forgivenessAmount, contractFeePercentage), 100); 
        uint256 numberOfTotalTokensToForgive = div(div(forgivenessAmount, reliefRatio), pricePerUnit);
        forgivenessAmount = forgivenessAmount - contractFeeAmount;
        for(uint128 i = 0; i < flaggedIndex[scammer].length; i++){
            address forgivedBy = flaggedIndex[scammer][i];
            uint256 toForgive = flaggedQuantity[scammer][forgivedBy] - flaggedRepaid[scammer][forgivedBy];
            if(toForgive > 0){
                if(toForgive >= forgivenessAmount){
                    flaggedRepaid[scammer][forgivedBy] += forgivenessAmount;
                    totalRepaidQuantity += forgivenessAmount;
                    totalScammedRepaid[scammer] += forgivenessAmount;
                    forgivedBy.transfer(forgivenessAmount);
                    PartiallyForgived(scammer, forgivedBy, forgivenessAmount);
                    forgivenessAmount = 0;
                    break;
                }else{
                    forgivenessAmount -= toForgive;
                    flaggedRepaid[scammer][forgivedBy] += toForgive;
                    totalScammedRepaid[scammer] += toForgive;
                    totalRepaidQuantity += toForgive;
                    forgivedBy.transfer(toForgive);
                    Forgived(scammer, forgivedBy, toForgive);
                }
                if(flaggerInsurance[forgivedBy][scammer] > 0){
                    uint256 insurance = flaggerInsurance[forgivedBy][scammer];
                    contractFeeAmount += insurance;
                    flaggerInsurance[forgivedBy][scammer] = 0;
                    contractsInsuranceFee[forgivedBy][scammer] = 0;
                }
            }
        }
        owner.transfer(contractFeeAmount);
        theScamStampToken.transferBack(scammer, numberOfTotalTokensToForgive);

        if(forgivenessAmount > 0){
            msg.sender.transfer(forgivenessAmount);
        }
        return true;
    }
    event DonationReceived(address by, uint256 amount);
    function donate() payable {
        owner.transfer(msg.value);
        DonationReceived(msg.sender, msg.value);

    }
    function () payable {
        owner.transfer(msg.value);
        DonationReceived(msg.sender, msg.value);        
    }
    

}