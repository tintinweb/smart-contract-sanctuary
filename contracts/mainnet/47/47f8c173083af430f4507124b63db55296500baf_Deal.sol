pragma solidity ^0.4.21;

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function transfer(address to, uint value) public returns (bool success);
    function transfer(address to, uint value, bytes data) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

contract Deal {

    enum Status { created, destroyed, finished }

    event CreateCampaign(bytes32 campaignId);
    event SendCoinForCampaign(bytes32 campaignId);

    struct Campaign {
        address creator;
        uint tokenAmount;
        uint currentBalance;
        Status status;
    }

    address public owner;

    address public fee;

    ERC223Interface public token;

    mapping (bytes32 => Campaign) public campaigns;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Deal(address tokenAddress, address _owner, address _fee) {
      owner = _owner;
      fee = _fee;
      token = ERC223Interface(tokenAddress);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

    function safeMul(uint a, uint b) internal returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
      assert(b <= a);
      return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
      uint c = a + b;
      assert(c>=a && c>=b);
      return c;
    }

    function sum(uint[] array) public returns (uint) {
        uint summa;
        for (uint i; i < array.length; i++) {
            summa += array[i];
        }
        return summa;
    }

    function changeFeeAddress(address newFee) onlyOwner {
        fee = newFee;
    }

    function createCampaign(bytes32 id, uint value, address campaignCreator) onlyOwner returns (uint) {
       require(getAddressCreatorById(id) == address(0));
       token.transferFrom(campaignCreator, this, value);
       campaigns[id] = Campaign(campaignCreator, value, value, Status.created);
       CreateCampaign(id);
    }

    function addTokensToCampaign(bytes32 id, uint value) onlyOwner returns (bool success) {
        token.transferFrom(getAddressCreatorById(id), this, value);
        campaigns[id].tokenAmount += value;
        campaigns[id].currentBalance += value;
    }

    function updateTokenAddress(address newAddr) onlyOwner {
        token = ERC223Interface(newAddr);
    }

    function destroyCampaign(bytes32 id) onlyOwner returns (bool success) {
        token.transfer(campaigns[id].creator, campaigns[id].tokenAmount);
        campaigns[id].status = Status.destroyed;
        campaigns[id].currentBalance = 0;
    }

    function checkStatus(bytes32 id) public constant returns (Status status) {
        return campaigns[id].status;
    }

    function getAddressCreatorById(bytes32 id) public constant returns(address) {
        return campaigns[id].creator;
    }

    function getTokenAmountForCampaign(bytes32 id) public constant returns (uint value) {
        return campaigns[id].tokenAmount;
    }

    function getCurrentBalanceForCampaign(bytes32 id) public constant returns (uint value) {
        return campaigns[id].currentBalance;
    }

    function finishCampaign(bytes32 id) onlyOwner returns (bool success) {
        campaigns[id].status = Status.finished;
        token.transfer(campaigns[id].creator, campaigns[id].currentBalance);
        campaigns[id].currentBalance = 0;
    }

    function sendCoin(address[] _routerOwners, uint[] amount, bytes32 id) onlyOwner {
        require(campaigns[id].status == Status.created);
        require(amount.length == _routerOwners.length);
        require(sum(amount) <= campaigns[id].tokenAmount);

        for (var i = 0; i < amount.length; i++) {
           token.transfer(_routerOwners[i], safeDiv(safeMul(amount[i], 95), 100)); 
        }
        token.transfer(fee, safeDiv(safeMul(sum(amount), 5), 100) );
        campaigns[id].currentBalance = safeSub(campaigns[id].currentBalance, sum(amount));
        SendCoinForCampaign(id);
    }
}