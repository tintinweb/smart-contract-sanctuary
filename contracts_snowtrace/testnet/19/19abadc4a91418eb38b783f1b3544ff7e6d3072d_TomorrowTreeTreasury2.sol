/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-11
*/

/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Test Token version 2 - Test 2
----------------------------------------------------------------------------------------------------
*/
// File: Interfaces.sol


pragma solidity ^0.8.0;

interface TomorrowTreeTestToken2 {

    function transfer(address recipient, uint256 amount) external returns (bool);

}

interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
}
// File: Treasury.sol




pragma solidity ^0.8.0;


contract TomorrowTreeTreasury2 {

    address TomorrowTree; //admin and default owner - later can be changed to multi - sig - voting contract
    address Owner; //owner of ... what exactly ??? Check Ownable.sol and think about compatibility, note on paper
    address TestTokenAddress;
    address TreasuryAddress;
    //address CommunityVoterAddress  //if time: smart contract where the community votes on transfers or burns

    TomorrowTreeTestToken2 token = TomorrowTreeTestToken2(TestTokenAddress);

    uint voterReward;

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }

constructor() {
        TomorrowTree = msg.sender;
        Owner = TomorrowTree;
    }

/*function donateAVAX() external payable {
    //return bytes32 or string: "thank you" ?
}

function donateTTTT() external payable {
 //token.transferFrom?
}*/

function AVAXBalance() external view returns(uint) {
    return address(this).balance;
}

function TTTTBalance() external view returns(uint) {
    ERC20 erc20 = ERC20(TestTokenAddress);
    return erc20.balanceOf(TreasuryAddress);
}

//Question to consider: do we make balance mappings address => uint to keep track of the donors ?

function sendAVAX(address payable recipient, uint amount) onlyOwner external {  //consider adding modifiers i.e. onlyTOmorrowTree ? ; community vote required, Tomorrow Tree vote required, maybe someone can override ? etc. etc. override community vote ? which community ? hero community ? or general public ? how many voting systems ? founder vote ? etc. etc.
    recipient.transfer(amount);
}

function sendTTTT(address payable recipient, uint amount) onlyOwner external {
    token.transfer(recipient, amount);
}

function burnTTTT(uint amount) onlyOwner external {
     token.transfer(address(0),amount);
}

function setVoterPay(uint newVoterReward) onlyOwner external {
    voterReward = newVoterReward;
}

//what arguments are needed ? does private work or does it need to be internal, or modifier that only voting contract can call it  or other necessity ?
//we need to make sure noone can call this function 
function payVoter(address payable voter) private {
    //require(thatVoterVoted); how do we do this ?
    token.transfer(voter, voterReward);
    //emit event which voter was paid
}


function setTomorrowTreeAddress(address _TomorrowTree) onlyOwner external {
    TomorrowTree = _TomorrowTree;
}

function setOwnerAddress(address _Owner) onlyOwner external {
    Owner = _Owner;
}

function setTestTokenAddress(address _TestTokenAddress) onlyOwner external {
    TestTokenAddress = _TestTokenAddress;
}

function setTreasuryAddress(address _TreasuryAddress) onlyOwner external {
    TreasuryAddress = _TreasuryAddress;
}

/*function setCommunityVoterAddress(address _CommunityVoterAddress) onlyOwner external {
    CommunityVoterAddress = _CommunityVoterAddress;
}*/

}