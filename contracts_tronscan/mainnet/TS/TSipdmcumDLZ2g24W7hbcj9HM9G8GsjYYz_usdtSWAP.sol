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
    //  baseUserId, user, parentId, referrerId, childCount, lastBoughtLevel, referralCount, levelExpiry
    function userInfos(uint256 _networkId,uint256 _planIndex,bool mainTree, uint256 _userId) external view returns(uint256,address payable,uint256,uint256,uint256,uint256,uint256,uint256);
    function withdrawBoosterAndAutoPoolGain(uint _userId,uint j) external returns (bool);
    function withdrawTeamActivationGain(uint _userId) external returns (bool);
    function withdrawTeamBonusGain(uint _userId) external returns (bool);
    function withdrawMegaPoolGain(uint _userId) external returns (bool); 
}


contract usdtSWAP is owned
{
    address public lmxTokenAddress;
    address public usdtTokenAddress;
    address public hookContractAddress;
    address public mscContractAddress;
    bool public allowWithdrawInTrx;
    uint public networkId;



    function() external payable
    {

    }


    event swapLmxToUsdtEv(uint timeNow, address user, uint amount);
    function swapLmxToUsdt(uint amount) public returns(bool)
    {
        require(swapInterface(lmxTokenAddress).burnSpecial(msg.sender, amount),"burn of lmx fail");
        amount = amount - (amount / 20);
        require(swapInterface(usdtTokenAddress).transferFrom( address(this), msg.sender, amount),"transfer of lmx fail");
        emit swapLmxToUsdtEv(now,msg.sender, amount);
        return true;
    }

    event swapLmxToTrxEv(uint tomeNow,address user,uint amount,uint trxAmount );
    function swapLmxToTrx(uint amount) public returns (bool)
    {
        require(allowWithdrawInTrx, "now allowed");
        require(swapInterface(lmxTokenAddress).burnSpecial(msg.sender, amount),"burn of lmx fail");
        amount = amount - (amount / 20);
        uint trxAmount = amount * swapInterface(hookContractAddress).oneTrxToDollarPercent() / 100000000;
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

    function setTokenAddress( address _lmxTokenAddress , address _usdtTokenAddress, address _hookContractAddress, address _mscContractAddress,uint _networkId ) public onlyOwner returns (bool)
    {
        lmxTokenAddress = _lmxTokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
        hookContractAddress = _hookContractAddress;
        mscContractAddress = _mscContractAddress;
        networkId = _networkId;
        return true;        
    }

    function withdraw(uint256 _userId) public returns(bool)
    {
        uint lastLevel =0;
        for(uint256 j=0; j<6;j++)
        { 
            ( ,,,,,lastLevel,,) = swapInterface(mscContractAddress).userInfos(networkId,0,true, _userId);           
            if(j < lastLevel)  swapInterface(hookContractAddress).withdrawBoosterAndAutoPoolGain(_userId,j);
        }
        swapInterface(hookContractAddress).withdrawTeamActivationGain(_userId);
        swapInterface(hookContractAddress).withdrawTeamBonusGain(_userId);
        swapInterface(hookContractAddress).withdrawMegaPoolGain(_userId); 
        return true; 
        
    }



}