/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-26
*/

pragma solidity ^0.5.11;

// ----------------------------------------------------------------------------
// forgivenet 1st phase contract
// Request forgiveness and receive an FRGVN token in return
// More info @ forgivenet.co.uk
//
//
// (c) Nandi Niramisa & Co Limited 2019. The MIT Licence. https://opensource.org/licenses/MIT
// ----------------------------------------------------------------------------


contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        _notEntered = true;
    }
}



contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address _from, address _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract ERC20TokenInterface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract RequestForForgiveness is Owned, ReentrancyGuard {

    ERC20TokenInterface private token;

    // receiving account
    address payable private receivingAccount;

    // Owner adds receiving account for accounting purposes
    function addEthReceivingAccount(address addr) public onlyOwner {
        require(addr != address(0));
        receivingAccount = address(uint160(addr));
    }

    // Owner adds ForgivenetToken address
    function addToken(address ercTokenAddress) public onlyOwner {
        require(ercTokenAddress != address(0));
        token = ERC20TokenInterface(ercTokenAddress);
    }



    // A minimum value for a request for forgiveness transaction may disincentivize bad behaviour
    uint private disincentive;
    
    function setDisincentiveInWei(uint number) public onlyOwner {
        disincentive = number;
    }

    function getDisincentive() public view returns (uint) {
        return disincentive;
    }
    
    
    
    // Make Ether payment into receiving account and call withdrawToken with the request
    function requestForgiveness(string memory forgiveness_request) public payable nonReentrant {
        
        uint256 length = bytes(forgiveness_request).length;
        require(length > 500 && length < 2000);
        require(msg.sender != address(0));
        require(msg.value > disincentive);
        receivingAccount.transfer(msg.value);
        withdrawToken(msg.sender, msg.value, forgiveness_request);
    }

    
    // Send 1 FRGVN token to recipient
    function withdrawToken(address recipient, uint256 amount, string memory requestString) internal {
        // placeholder variable for request
        string memory data = requestString;
        require(recipient != address(0));
        require(bytes(data).length > 0);
        token = ERC20TokenInterface(token);
        require(token.transfer(recipient, 1000000000000000000) == true);
        emit RequestMade(recipient, data, amount, now);
    }
    
    // events
    event RequestMade(address indexed from, string data, uint256 donation, uint256 timestamp);

}