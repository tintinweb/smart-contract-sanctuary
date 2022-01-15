/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-14
*/

/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Treasury - Test 4
----------------------------------------------------------------------------------------------------
*/

// File: Remix2/IERC20Burnable.sol


pragma solidity ^0.8.0;

abstract contract ERC20Burnable {

    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

}
// File: Remix2/IERC20.sol


pragma solidity ^0.8.0;

abstract contract ERC20 {

    function balanceOf(address account) external view virtual returns (uint256);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool);

}
// File: Remix2/ITTTT2.sol


pragma solidity ^0.8.0;

abstract contract TomorrowTreeTestToken2 {

    function mint(address to, uint256 amount) public virtual;

    function balanceOf(address account) external view virtual returns (uint256);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    function burnFrom(address account, uint256 amount) public virtual;

}
// File: Remix2/Treasury.sol



/*
----------------------------------------------------------------------------------------------------
Tomorrow Tree Treasury - Test 4
----------------------------------------------------------------------------------------------------
*/

pragma solidity ^0.8.0;




contract TomorrowTreeTreasury {

    address TomorrowTree; //admin and owner
    address TestTokenContractAddress; //Address of Tomorrow Tree Test Token
    address TreasuryContractAddress; //This Smart Contract's address
    address ProjectVotingContractAddress; //Address of the Smart Contract that votes on afforestation projects
    address TreasuryVotingContractAddress;  //Address of the Smart Contract where the community votes on transfers or burns
    address payable TomorrowTreeDestroy; //Address used for destroying the Treasury Test contract
    
    address ProjectVoter; //Voter from ProjectVoting Smart Contract
    uint projectVoterReward; //Reward for ProjectVoting Smart Contract voters

    constructor() {
        TomorrowTree = msg.sender;
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
   event TreasuryVotingContractAddressChanged(address indexed oldTVCAddress, address indexed newTVCAddress);

    function donateAVAX() external payable {
   
    }

    function AVAXBalance() external view returns(uint) {
    return address(this).balance;
    }

    function TTTTBalance() external view returns(uint) {
    ERC20 erc20 = ERC20(TestTokenContractAddress);
    return erc20.balanceOf(TreasuryContractAddress);
    }

//Question to consider: do we make a balance mapping address => uint to keep track of the donors ?

    function sendAVAX(address payable recipient, uint amount) onlyTreasuryVoter external payable { 
    recipient.transfer(amount);
    }

    function sendTTTT(address payable recipient, uint amount) onlyTreasuryVoter external payable {
    ERC20 erc20 = ERC20(TestTokenContractAddress);
    erc20.transfer(recipient, amount);
    }

    function burnTTTT(uint amount) onlyTreasuryVoter external payable {
    ERC20Burnable erc20burnable = ERC20Burnable(TestTokenContractAddress);
    erc20burnable.burn(amount);
    }

    function setProjectVoterPay(uint newProjectVoterReward) onlyTreasuryVoter external {
        projectVoterReward = newProjectVoterReward;
    }

    function rewardVoter(address payable _ProjectVoter) onlyProjectVoter external payable {
        ERC20 erc20 = ERC20(TestTokenContractAddress);
        erc20.transfer(_ProjectVoter, projectVoterReward);
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

    function setTreasuryVotingContractAddress(address newTVCAddress) onlyOwner external {
        address oldTVCAddress = TreasuryVotingContractAddress; 
        TreasuryVotingContractAddress = newTVCAddress;
        emit TreasuryVotingContractAddressChanged(oldTVCAddress, newTVCAddress);
    }

    function setDestroyAddress(address payable _DestroyAddress) onlyOwner external {
        TomorrowTreeDestroy = _DestroyAddress;
    }

    //must transfer ownership to TomorrowTreeDestroy before evoking
    function destroyContract() public onlyOwner { 
    selfdestruct(TomorrowTreeDestroy);
    }
}