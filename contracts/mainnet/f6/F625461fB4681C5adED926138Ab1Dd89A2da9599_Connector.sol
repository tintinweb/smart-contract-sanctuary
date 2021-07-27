/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// File: browser/NyanFundInterface.sol

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

interface NFund {
    function approveSpendERC20(address, uint256) external;
    
    function approveSpendETH(address, uint256) external;
    
    function newVotingRound() external;
    
    function setVotingAddress(address) external;
    
    function setConnectorAddress(address) external;
    
    function setNewFundAddress(address) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function setBalanceLimit(uint256) external;
    
    function sendToNewContract(address) external;
}

interface NVoting {
    function setConnector(address) external;
    
    function setFundAddress(address) external;
    
    function setRewardsContract(address) external;
    
    function setIsRewardingCatnip(bool) external;
    
    function setVotingPeriodBlockLength(uint256) external;
    
    function setNyanAddress(address) external;
    
    function setCatnipAddress(address) external;
    
    function setDNyanAddress(address) external;
    
    function distributeFunds(address, uint256) external;
    
    function burnCatnip() external;
}

interface NConnector {
    function executeBid(
        string calldata, 
        string calldata, 
        address[] calldata , 
        uint256[] calldata, 
        string[] calldata, 
        bytes[] calldata) external;
}

interface NyanV2 {
    
    function swapNyanV1(uint256) external;
    
    function stakeNyanV2LP(uint256) external;
    
    function unstakeNyanV2LP(uint256) external;
    
    function stakeDNyanV2LP(uint256) external;
    
    function unstakeDNyanV2LP(uint256) external;
    
    function addNyanAndETH(uint256) payable external;
    
    function claimETHLP() external;
    
    function initializeV2ETHPool() external;
}


// File: browser/UniswapV2Interface.sol

pragma solidity ^0.6.6;


// File: browser/ERC20Interface.sol

pragma solidity ^0.6.6;

contract ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256) {}

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256) {}

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {}

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256) {}

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool) {}

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: browser/Connector.sol



pragma solidity ^0.6.6;





contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

contract LibraryLockDataLayout {
  bool public initialized = false;
}

contract LibraryLock is LibraryLockDataLayout {
    // Ensures no one can manipulate the Logic Contract once it is deployed.
    // PARITY WALLET HACK PREVENTION

    modifier delegatedOnly() {
        require(initialized == true, "The library is locked. No direct 'call' is allowed");
        _;
    }
    function initialize() internal {
        initialized = true;
    }
}

contract DataLayout is LibraryLock {
    struct bid {
        address bidder;
        uint256 votes;
        address[] addresses;
        uint256[] integers;
        string[] strings;
        bytes[] bytesArr;
    }
    
    address public votingAddress;
    address public fundAddress;
    address public nyanV2;
    address public owner;
    // address public uniswapRouterAddress;
    // IUniswapV2Router02 public uniswapRouter;
    
    
    address[] public tokenList;
    mapping(address => bool) public whitelist;
    
    
    modifier _onlyOwner() {
        require((msg.sender == votingAddress) || (msg.sender == owner)  || (msg.sender == address(this)));
        _;
    }

    address public easyBid;
    address public registry;
    address public contractManager;
    uint256[] public fundHistory;
    address[] public historyManager;
    string[] public historyReason;
    address[] public historyRecipient;
    
}

contract Connector is DataLayout, Proxiable  {

    function connectorConstructor(address _votingAddress, address _nyan2) public {
        require(!initialized, "Contract is already initialized");
        owner = msg.sender;
        votingAddress = _votingAddress;
        nyanV2 = _nyan2;
        initialize();
    }
    
    receive() external payable {
        
    }
    
    function relinquishOwnership()public _onlyOwner delegatedOnly {
        require(contractManager != address(0));
        owner = address(0);
    } 
    
    /** @notice Updates the logic contract.
      * @param newCode  Address of the new logic contract.
      */
    function updateCode(address newCode) public delegatedOnly  {
        if (owner == address(0)) {
            require(msg.sender == contractManager);
        } else {
            require(msg.sender == owner);
        }
        updateCodeAddress(newCode);
        
    }
    
    function setVotingAddress(address _addr) public _onlyOwner delegatedOnly {
        votingAddress = _addr;
    }
    
    function setRegistry(address _registry) public _onlyOwner delegatedOnly {
        registry = _registry;
    }
    
    function setContractManager(address _contract) public _onlyOwner delegatedOnly {
        contractManager = _contract;
    }
    
    function setOwner(address _owner) public _onlyOwner delegatedOnly {
        owner = _owner;
    }
    
    function transferToFund() public delegatedOnly {
        for (uint256 i = 0; i < tokenList.length; i++) {
            ERC20 erc20 = ERC20(tokenList[0]);
            uint256 balance = erc20.balanceOf(address(this));
            erc20.transfer(fundAddress, balance);
        }
    }
    
    function fundLog(address manager, string memory reason, address recipient) public delegatedOnly payable {
        //must be from registered contract
        Registry(registry).checkRegistry(msg.sender);
        fundHistory.push(fundAddress.balance);
        historyManager.push(manager);
        historyReason.push(reason);
        historyRecipient.push(recipient);
    }
    
    function getFundHistory() public view returns(uint256[] memory, address[] memory, string[] memory, address[] memory) {
        return (
            fundHistory,
            historyManager,
            historyReason,
            historyRecipient
        );
    }
    
    function getFundETH(uint256 amount) public delegatedOnly {
        NFund fund = NFund(fundAddress);
        require(msg.sender == registry);
        fund.approveSpendETH(registry, amount);
    }

    
    function returnFundETH() public payable delegatedOnly {
        require(msg.sender == registry);
        fundAddress.call{value: msg.value}("");
    }
     
    function withdrawDeposit(uint256 amount, address depositor) public delegatedOnly {
        NFund fund = NFund(fundAddress);
        require(msg.sender == registry);
        fund.approveSpendETH(depositor, amount);
    }
     
    function setEasyBidAddress(address _easyBid) public _onlyOwner delegatedOnly {
        easyBid = _easyBid;
    }

    function getEasyBidETH(uint256 amount) public delegatedOnly {
        NFund fund = NFund(fundAddress);
        require(msg.sender == easyBid);
        fund.approveSpendETH(easyBid, amount);

    }

    function sendMISCETH(address _address, uint256 _amount, string memory reason) public delegatedOnly {
        NFund fund = NFund(fundAddress);
        require(msg.sender == owner);
        fund.approveSpendETH(_address, _amount);
        fundLog(owner, reason, owner);
    }

    function sendMISCERC20(address _address, uint256 _amount, string memory reason) public delegatedOnly {
        NFund fund = NFund(fundAddress);
        require(msg.sender == owner);
        fund.approveSpendERC20(_address, _amount);
        ERC20 erc20 = ERC20(_address);
        erc20.transfer(msg.sender, _amount);
        fundLog(owner, reason, owner);
    }

}

interface Registry {
    function checkRegistry(address _contract) external view returns(bool);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}