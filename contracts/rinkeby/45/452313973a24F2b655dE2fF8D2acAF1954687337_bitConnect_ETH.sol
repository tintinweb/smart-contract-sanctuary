/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.5.10;

contract owned
{
    address payable public owner;
    address payable public  newOwner;
    address payable public signer;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        signer = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }


    function changeSigner(address payable _signer) public onlyOwner {
        signer = _signer;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //the reason for this flow is to protect owners from sending ownership to unintended address due to human error
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract bitConnect_ETH is owned{

    struct buyReq{
        address _referredBy;
        uint tokenAmount;
        uint coinAmount;
        bool buyPending;
    }
    uint public eventIndex;
    mapping (address => buyReq[]) public buyRequest;

    event buyEv(uint eventIndex, address user, uint boughtIndex, uint paidCoin, uint tokenAmount, uint timeNow);

    function buy(address _referredBy, uint tokenAmount) public payable returns(bool)
    {
        require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
        buyReq memory temp;
        temp._referredBy = _referredBy;
        temp.tokenAmount = tokenAmount;
        temp.coinAmount = msg.value;
        temp.buyPending = true;
        buyRequest[msg.sender].push(temp);
        eventIndex++;
        emit buyEv(eventIndex, msg.sender, buyRequest[msg.sender].length, msg.value, tokenAmount, now); 
        return true;
    }

    function markBought(address user,uint boughtIndex) public onlySigner returns(bool){
        require(buyRequest[user][boughtIndex].buyPending, "already processed");
        buyRequest[user][boughtIndex].buyPending = false;
        return true;
    }

    function moveFund(uint amount) public onlyOwner returns(bool){
        owner.transfer(amount);
        return true;
    }

}