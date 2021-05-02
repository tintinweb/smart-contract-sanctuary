// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract ESSToken is ERC20("Essential Shelf", "ESS") {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    uint8 public constant DECIMALS=8;
    uint256 public constant INITIAL_SUPPLY=180000000*(10**uint256(DECIMALS));
    address public project=msg.sender;
    bool public mintingFinished=false;
    uint256 public deposit;
    mapping (address=>uint256) private deposit_amount;

    constructor () {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function changeDeposit(uint256 ndeposit) public onlyOwner{
        deposit=ndeposit;
    }

    function mint(uint256 amount) onlyOwner canMint public{
        uint256 amount2=amount*(10**uint256(DECIMALS));
        _mint(msg.sender,amount2);
    }

    function burn(uint256 amount) onlyOwner public {
        uint256 amount2=amount*(10**uint256(DECIMALS));
        _burn(msg.sender,amount2);
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==project);
        _;
    }

    function finishingMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function createStoreFactory(uint256 minimum) public returns(Store Store_address) {
        require(balanceOf(msg.sender)>=deposit*(10**uint256(DECIMALS)));
        uint256 _deposit=deposit*(10**uint256(DECIMALS));
        deposit_amount[msg.sender]=deposit;
        transfer(project, _deposit);
        return new Store(minimum, msg.sender);
    }

    function getDeposit(address user) public view returns (uint256) {
        return deposit_amount[user];
    }

}

contract Store {
    struct Request {
        string description;
        uint256 value;
        address payable recipient;
        bool complete;
        uint256 approvalCount;
        mapping(address => bool) approvals;
    }

    address public manager;
    uint256 public minimumContribution;
    mapping(address => bool) public approvers;
    uint256 public approversCount;
    uint256 public numRequests;
    mapping (uint256=>Request) public request;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor (uint256 minimum, address creator) {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);

        approvers[msg.sender] = true;
        approversCount++;
    }

    function CreatRequest(string memory description, uint256 value, address payable recipient) public restricted returns (uint256 IDRequest) {
        IDRequest=numRequests++;
        Request storage c = request[IDRequest];
        c.description=description;
        c.value=value;
        c.recipient=recipient;
        c.complete=false;
        c.approvalCount=0;
    }

    function approveRequest(uint256 index) public {
        Request storage c = request[index];

        require(approvers[msg.sender]);
        require(!c.approvals[msg.sender]);

        c.approvals[msg.sender] = true;
        c.approvalCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage c = request[index];

        require(c.approvalCount > (approversCount / 2));
        require(!c.complete);

        c.recipient.transfer(c.value);
        c.complete = true;
    }
}