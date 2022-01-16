/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-16
*/

pragma solidity ^0.8.3;
//jbp-Bournvita "Licensed"

contract multiSigTester{
    //A class to test multi-signature wallets.
    //contract will store ether and owner addressess


    //logging ether payments
    event receiveTrigger(address indexed from, uint amount);
    event fallbackTrigger(address indexed from, uint amount, bytes data);
    event Message(bytes data);
    event LogRequest(bytes data, uint amount, address payee);
    event LogDeny(bytes data, uint amount, address payee);

    //owners
    address public initialOwner;
    address public secondOwner;
    mapping(address => bool) internal status;
    mapping(address => uint) internal personalBalance;
    uint internal requestValue = 0;
    address private payee;
    address private requester;
    address private denier;
    bytes internal data;


    constructor(address _secondOwner)
    {
        initialOwner = msg.sender;
        secondOwner = _secondOwner;
    }

    modifier onlyOwners()
    {
        require((msg.sender == initialOwner) || (msg.sender == secondOwner), "not an owner");
        _;
    }

    modifier statusApproved()
    {
        require(status[initialOwner] == true && status[secondOwner] == true, "Transaction not approved");
        _;
    }

    function addEther() public payable returns (bool)
    {
        personalBalance[msg.sender] += msg.value;
        return true;
    }

    function getPersonalBalance() public view returns (uint)
    {
        return personalBalance[msg.sender];
    }

    function getContractBalance() public view returns (uint)
    {
        return address(this).balance;
    }

    function requestAmount(uint _amount, address payable _to, bytes memory _data) public onlyOwners returns (bool)
    {
        requestValue = _amount;
        payee = _to;
        status[msg.sender] = true;
        emit LogRequest("requesting", _amount, _to);
        requester = msg.sender;
        data = _data;
        return true;
        
    }

    function denyAmount() public onlyOwners returns (bool)
    {
        uint toDeny = requestValue;
        requestValue = 0;
        status[msg.sender] = false;
        emit LogDeny("deny", toDeny, payee);
        denier = msg.sender;
        delete data;
        payee = address(0);
        return true;
    }

    function getRequestAmount() public onlyOwners view returns (uint)
    {
        return requestValue;
    }

    function getRequestedPayee() public onlyOwners view returns (address)
    {
        return payee;
    }

    function approveAmount() public onlyOwners payable returns(bool success)
    {
        status[msg.sender] = true;
        success = false;
        if(status[initialOwner] == true && status[secondOwner] == true)
        {
            success = spend(requestValue, payable(payee), data);
            require(success == true, "failed transfer");
            status[initialOwner] = false;
            status[secondOwner] = false;
            requestValue = 0;
            delete payee;
            delete requester;
            delete denier;
            emit Message("Transaction Sent");
        }
        else
        {
            emit Message("waiting for owners");
        }

        return success;

    }

    function spend(uint _amount, address payable _to, bytes memory _data) internal statusApproved returns (bool)
    {
        (bool success, ) = _to.call{value: _amount}(_data);
        require(success == true, "failed to send ether");
        return true; 
    }


    receive() external payable
    {
        emit receiveTrigger(msg.sender, msg.value);   
    }

    fallback() external payable
    {
        emit fallbackTrigger(msg.sender, msg.value, msg.data);
    }
}