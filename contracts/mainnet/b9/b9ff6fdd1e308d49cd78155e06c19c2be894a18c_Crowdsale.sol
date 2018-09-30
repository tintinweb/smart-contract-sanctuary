pragma solidity ^0.4.0;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


interface token {
    function transfer(address to, uint tokens) external;
    function balanceOf(address tokenOwner) external returns(uint balance);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event tokensBought(address _addr, uint _amount);
    event tokensCalledBack(uint _amount);
    event privateSaleEnded(uint _time);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }

}


contract Crowdsale is Owned{
    using SafeMath for uint;
    uint public endDate;
    address public developer;
    address public marketing;
    address public kelly;
    address public company;
    uint public phaseOneEnd;
    uint public phaseTwoEnd;
    uint public phaseThreeEnd;
    token public CCC;
    
    event tokensBought(address _addr, uint _amount);
    constructor() public{
    phaseOneEnd = now + 3 days;
    phaseTwoEnd = now + 6 days;
    phaseThreeEnd = now + 29 days;
    CCC = token(0x4446B2551d7aCdD1f606Ef3Eed9a9af913AE3e51);
    developer = 0x215c6e1FaFa372E16CfD3cA7D223fc7856018793;
    company = 0x49BAf97cc2DF6491407AE91a752e6198BC109339;
    kelly = 0x36e8A1C0360B733d6a4ce57a721Ccf702d4008dE;
    marketing = 0x4DbADf088EEBc22e9A679f4036877B1F7Ce71e4f;
    }
    
    function() payable public{
        require(msg.value >= 0.3 ether);
        require(now < phaseThreeEnd);
        uint tokens;
        if (now <= phaseOneEnd) {
            tokens = msg.value * 6280;
        } else if (now > phaseOneEnd && now <= phaseTwoEnd) {
            tokens = msg.value * 6280;
        }else if( now > phaseTwoEnd && now <= phaseThreeEnd){
            tokens = msg.value * 6280;
        }
        CCC.transfer(msg.sender, tokens);
        emit tokensBought(msg.sender, tokens);
    }
    
    function safeWithdrawal() public onlyOwner {
        require(now >= phaseThreeEnd);
        uint amount = address(this).balance;
        uint devamount = amount/uint(100);
        uint devamtFinal = devamount*5;
        uint marketamtFinal = devamount*5;
        uint kellyamtFinal = devamount*5;
        uint companyamtFinal = devamount*85;
        developer.transfer(devamtFinal);
        marketing.transfer(marketamtFinal);
        company.transfer(companyamtFinal);
        kelly.transfer(kellyamtFinal);

        
    }
    

    function withdrawTokens() public onlyOwner{
        require(now >= phaseThreeEnd);
        uint Ownerbalance = CCC.balanceOf(this);
    	CCC.transfer(owner, Ownerbalance);
    	emit tokensCalledBack(Ownerbalance);

    }
    
}