/**
 *Submitted for verification at Etherscan.io on 2020-05-30
*/

pragma solidity 0.5.16;


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        if (a == 0) { return 0; }
        c = a * b;
        require(c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        require(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
    }
}




//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned
{
    address payable internal owner;
    address payable internal newOwner;
    address payable public signer;

    event OwnershipTransferred(address payable _from, address payable _to);

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

 interface paxInterface
 {
    function transfer(address _to, uint256 _amount) external returns (bool);
 }


contract divDistribution is owned
{
    using SafeMath for uint256;
    address paxContractAddress;
    uint256[] public distributionAmount;

    mapping(address => bool) public eligibleUser;
    mapping(address => uint) public eligibleFrom;
    mapping(address => mapping(uint => bool)) public paidIndex;
    uint totalEligible;

    function setPaxAddress(address paxAddress) public onlyOwner returns(bool)
    {
        paxContractAddress = paxAddress;
        return true;
    }

    function setDistributionAmount(uint _distributionAmount) public onlyOwner returns(bool)
    {
        distributionAmount.push(_distributionAmount);
        return true;
    }

    constructor() public {
        distributionAmount.push(0);
    }

    function addNewAddress(address[] memory users) public onlySigner returns(bool)
    {
        for(uint i =0;i<users.length;i++)
        {
            eligibleUser[users[i]] = true;
            eligibleFrom[users[i]] = distributionAmount.length;
            totalEligible++;
        }
    }

    event getDividendEv(address user, uint amount);
    function getDividend() public returns (bool)
    {
        require(eligibleUser[msg.sender],"not eligible");
        uint totalAmount=0;
        for(uint i = eligibleFrom[msg.sender];i<distributionAmount.length;i++)
        {
            if(!paidIndex[msg.sender][i])
            {
                totalAmount += distributionAmount[i].div(totalEligible);
                paidIndex[msg.sender][i] = true;
            } 
        }
        if(totalAmount > 0 ) require(paxInterface(paxContractAddress).transfer(msg.sender, totalAmount ),"token transfer failed");
        emit getDividendEv(msg.sender, totalAmount);
        return true;
    }

    function withdrawExtraFund(uint amount) public onlyOwner returns(bool)
    {
        require(paxInterface(paxContractAddress).transfer(msg.sender, amount ),"token transfer failed");
        return true;
    }

}