/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-13
*/

/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Treasury - Test 3
----------------------------------------------------------------------------------------------------
*/

// File: ITTTT2.sol


pragma solidity ^0.8.0;

abstract contract TomorrowTreeTestToken2 {

    function balanceOf(address account) external view virtual returns (uint256);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function burnFrom(address account, uint256 amount) public virtual;

}
// File: Treasury3.sol



/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Treasury - Test 3
----------------------------------------------------------------------------------------------------
*/

pragma solidity ^0.8.0;


contract TomorrowTreeTreasury {

    address TomorrowTree; //admin and owner
    address TestTokenContractAddress; //Address of Tomorrow Tree Test Token
    address TreasuryContractAddress;
    address ProjectVotingContractAddress; // Smart Contract that votes on project proposals
    address TreasuryVotingContractAddress;  //Smart Contract where the community votes on transfers or burns
    address payable TomorrowTreeDestroy; //for destroying the Test Token contract
    
    TomorrowTreeTestToken2 token = TomorrowTreeTestToken2(TestTokenContractAddress);

    address ProjectVoter; //Voter from ProjectVoting Smart Contract
    uint projectVoterReward; //how much voters in ProjectVoting Smart Contract are rewarded

    constructor() {
        TomorrowTree = msg.sender;
        TreasuryVotingContractAddress = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == TomorrowTree);
        _;
    }

    modifier onlyTreasuryVoter {
        require(msg.sender == TreasuryVotingContractAddress);
        _;
    }

    modifier onlyProjectVoter {
        require(msg.sender == ProjectVotingContractAddress);
        _;
    }

   event OwnershipTransferred(address indexed _oldOwner, address indexed _newOwner);
   event VoterRewarded(address indexed ProjectVoter, uint projectVoterReward);

    function donateAVAX() external payable {
   
    }

    function AVAXBalance() external view returns(uint) {
    return address(this).balance;
    }

    function TTTTBalance() external view returns(uint) {
    return token.balanceOf(TreasuryContractAddress);
    }

//Question to consider: do we make balance mappings address => uint to keep track of the donors ?

    function sendAVAX(address payable recipient, uint amount) onlyTreasuryVoter external {  //consider adding modifiers i.e. onlyTOmorrowTree ? ; community vote required, Tomorrow Tree vote required, maybe someone can override ? etc. etc. override community vote ? which community ? hero community ? or general public ? how many voting systems ? founder vote ? etc. etc.
    recipient.transfer(amount);
    }

    function sendTTTT(address payable recipient, uint amount) onlyTreasuryVoter external {
    token.approve(TreasuryVotingContractAddress, amount);
    token.transferFrom(TreasuryContractAddress, recipient, amount);
    }

    function burnTTTT(uint amount) onlyTreasuryVoter external {
    token.approve(TreasuryVotingContractAddress, amount);
    token.burnFrom(TreasuryContractAddress ,amount);
    }

    function setProjectVoterPay(uint newProjectVoterReward) onlyTreasuryVoter external {
        projectVoterReward = newProjectVoterReward;
    }

    function rewardVoter(address _ProjectVoter) onlyProjectVoter external {
        token.approve(ProjectVotingContractAddress, projectVoterReward);
        token.transferFrom(TreasuryContractAddress, _ProjectVoter, projectVoterReward);
        emit VoterRewarded(_ProjectVoter, projectVoterReward);
    }


    function changeOwner(address _newOwner) external onlyOwner {
        address _oldOwner = TomorrowTree;
        TomorrowTree = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }


    function setTestTokenContractAddress(address _TestTokenContractAddress) onlyOwner external {
        TestTokenContractAddress = _TestTokenContractAddress;
    }

    function setTreasuryContractAddress(address _TreasuryContractAddress) onlyOwner external {
        TreasuryContractAddress = _TreasuryContractAddress;
    }

    function setProjectVotingContractAddress(address _ProjectVotingContractAddress) onlyOwner external {
        ProjectVotingContractAddress = _ProjectVotingContractAddress;
    }

    function setTreasuryVotingContractAddress(address _TreasuryVotingContractAddress) onlyOwner external {
        TreasuryVotingContractAddress = _TreasuryVotingContractAddress;
    }

    //must transfer ownership to TomorrowTreeDestroy before evoking
    function destroyContract() public onlyOwner { 
    selfdestruct(TomorrowTreeDestroy);
    }
}