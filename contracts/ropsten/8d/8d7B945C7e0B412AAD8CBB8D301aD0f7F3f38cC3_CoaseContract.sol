/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

pragma solidity ^0.8.4;                      // this defines the version of Solidity we use
contract CoaseContract {
    // the state variables of the contract are declared below
    uint public abatementCost = 22 * 3e14;   // constant marginal cost (1 USD ~ 3e14 wei)
    uint public commitment;
    address public sattelite;
    address[] public participants;                           // array of addresses
    mapping (address => uint) public balances;               // every address has a balance
    mapping (address => bool) public isParticipant;
    mapping (address => uint) public socialCosts;
    mapping (address => uint) public abatementShares;
    mapping (address => bool) public sufficientBalance;
    
    constructor() {                 // executes only once, when the contract is deployed
        sattelite = msg.sender;     // for exposition: sattelite = whoever deploys contract
    }
    
    // anyone can add money to their balance and report their marginal social cost of carbon
    function participate(uint socialCost) public payable {
        balances[msg.sender] += msg.value;
        socialCosts[msg.sender] = socialCost;
        if (!isParticipant[msg.sender]) {
            participants.push(msg.sender);
            isParticipant[msg.sender] = true;
        }
    }
    
    // this allows anyone to withdraw from their balance at any time
    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount, "Withdrawal can't exceed balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    // this allows the sattelite to report the abatementShares (in integer % points)
    function reportAbatement(address government, uint abatementShare) public {
        require(msg.sender == sattelite, "Only sattelite can report abatement");
        abatementShares[government] = abatementShare;
    }
    
    // any government can request reimbursement proportional to their abatement
    function reimburse() public {
        uint reimbursement = abatementShares[msg.sender] * commitment / 100;
        abatementShares[msg.sender] = 0;
        payable(msg.sender).transfer(reimbursement);
    }

    // anyone can commit participants to an (additional) Pareto improving abatement
    function commit(uint abatement) public {
        uint totalSocialCost = 0;
        for (uint i=0; i<participants.length; i++) {
            sufficientBalance[participants[i]] = ((socialCosts[participants[i]] * abatement) <= balances[participants[i]]);
            if (sufficientBalance[participants[i]]) {
                totalSocialCost += socialCosts[participants[i]];
            }
        }
        require(totalSocialCost >= abatementCost, "Commitments must incentivize abatement");
        for (uint j=0; j<participants.length; j++) {
            if (sufficientBalance[participants[j]]) {
                commitment += abatement * socialCosts[participants[j]];
                balances[participants[j]] -= abatement * socialCosts[participants[j]];
            }
        }
    }
}