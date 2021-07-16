//SourceUnit: usdt_swap.sol

pragma solidity 0.5.9; 

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
    }
}


contract owned
{
    address payable internal owner;
    address payable internal newOwner;
    address payable internal signer;


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

    function transferOwnership(address payable  _newOwner) public onlyOwner {
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



interface swapInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function burnSpecial(address user, uint256 _value) external returns (bool);  
    function oneTrxToDollarPercent() external view returns(uint256); 
}


contract usdtSWAP is owned
{
    address lmxTokenAddress;
    address usdtTokenAddress;
    bool public allowWithdrawInTrx;



    function() external payable
    {

    }


    event swapLmxToUsdtEv(uint timeNow, address user, uint amount);
    function swapLmxToUsdt(uint amount) public returns(bool)
    {
        amount = amount - (amount / 20);
        require(swapInterface(lmxTokenAddress).burnSpecial(msg.sender, amount),"burn of lmx fail");
        require(swapInterface(usdtTokenAddress).transferFrom( address(this), msg.sender, amount),"transfer of lmx fail");
        emit swapLmxToUsdtEv(now,msg.sender, amount);
        return true;
    }

    event swapLmxToTrxEv(uint tomeNow,address user,uint amount,uint trxAmount );
    function swapLmxToTrx(uint amount) public returns (bool)
    {
        require(allowWithdrawInTrx, "now allowed");
        amount = amount - (amount / 20);
        require(swapInterface(lmxTokenAddress).burnSpecial(msg.sender, amount),"burn of lmx fail");
        uint trxAmount = amount * 100000000 / swapInterface(lmxTokenAddress).oneTrxToDollarPercent();
        msg.sender.transfer(trxAmount);
        emit swapLmxToTrxEv(now,msg.sender, amount, trxAmount );
        return true;        
    }

    function withdrawUsdtAdmin(uint amount) public onlyOwner returns (bool)
    {
        require(swapInterface(usdtTokenAddress).transfer( owner, amount),"transfer usdt to owner fail");
        return true;
    }


    function withdrawTrxAdmin(uint amount) public onlyOwner returns (bool)
    {
        owner.transfer(amount);
        return true;
    }

    function setAllowWithdrawInTrx(bool _value) public onlyOwner returns (bool)
    {
        allowWithdrawInTrx = _value;
        return true;
    }

    function setTokenAddress( address _lmxTokenAddress , address _usdtTokenAddress ) public onlyOwner returns (bool)
    {
        lmxTokenAddress = _lmxTokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
        return true;        
    }


}