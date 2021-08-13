// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// import "./Context.sol"; // pulled in by Ownable.sol and Pausable.sol
import "./Ownable.sol";
import "./Pausable.sol";

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract GroguFaucet is Ownable, Pausable {
   // uint256 constant public tokenAmount = 100000000000000000000; // @dev if you want fixed distribution
    uint256 public tokenAmount = 200000000000000000000;
    uint256 public waitTime = 1 minutes;

    ERC20 public tokenInstance;

    mapping(address => uint256) lastAccessTime;

    event tokenAmountUpdated(address indexed _owner, uint256 previousRate, uint256 newRate);
    event waitTimeUpdated(address indexed _owner, uint256 previouswaitTime, uint256 newwaitTime);
    event WithdrawTokensSentHere(address token, address _operator, uint256 amount);

    constructor(address _tokenInstance) {
       // emit TokenAddressTransferred(address(0), tokenInstance);
        require(_tokenInstance != address(0));
        tokenInstance = ERC20(_tokenInstance);
        // initialize the number of participants as zero
        numParticipants = 0;
    }

    struct Participant {
        bool registered;  // if true, that person already registered
    }

    mapping(address => Participant) public participants;
    uint public numParticipants;

    modifier onlyOnce() {
        if (participants[msg.sender].registered) {
            revert("GROGU::MultiSig::Transfers to non-whitelisted contracts declined");
        }
        _;
    }

     /**
     * @dev Update the charity rate.
     * Can only be called by the current operator.
     */
    function updateTokenAmount(uint16 _tokenAmount) public onlyOwner whenNotPaused {
        require(_tokenAmount >= 1000000000000000000,"updateTokenAmount::Too Low");
        emit tokenAmountUpdated(msg.sender, tokenAmount, _tokenAmount);
        tokenAmount = _tokenAmount;
    }


    function updatewaitTime(uint256 _waitTime) public onlyOwner whenNotPaused {
        require(_waitTime >= 1 minutes,"updatewaitTime::Too Short");
        emit waitTimeUpdated(msg.sender, waitTime, _waitTime);
        waitTime = _waitTime;
    }

    // @dev -- public views of state variables
    function Participants() public view returns (uint256) {
        return numParticipants;
    }

    function TokenAmounts() public view returns (uint256) {
        return tokenAmount;
    }

    function waitTimes() public view returns (uint256) {
        return waitTime;
    }
    // @dev -- ends public views of state variables

    function requestTokens() public onlyOnce() whenNotPaused {
        require(allowedToWithdraw(msg.sender));
        tokenInstance.transfer(msg.sender, tokenAmount);
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
        Participant storage p = participants[msg.sender];
        p.registered = true;
        numParticipants++;
    }

    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }

        // @dev owner can drain tokens that are sent here by mistake
    function withdrawTokensSentHere(ERC20 token, uint256 amount)
        public
        onlyOwner
    {
        emit WithdrawTokensSentHere(address(token), owner(), amount);
        token.transfer(owner(), amount);
    }
}