/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-26
*/

pragma solidity 0.5.16; 


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}


contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface tokenInterface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function burn(uint amount) external returns(bool);
}

interface dividendInterface 
{
   function directDistribute(address _token, uint _amount) external returns(bool);
   function addToRegular(address _token, uint _amount) external returns(bool);
   function withdrawMyDividend(address _token, bool _reInvest) external returns (bool);
   function distributedTotalAmountTillNow_E(address _token) external view returns(uint);
   function distributedTotalAmountTillNow_T(address _token) external view returns(uint);
   function resetUserDatas(address _token, address _user) external returns(bool);
}



contract UTOPIA_Staking is owned 
{
    using SafeMath for uint256;

    bool public safeGuard;
    
    mapping(address => bool) public authorisedToken;
    mapping(address => uint8) public burnMethod;
    uint public unStakeBurnCut; // 0% default
    uint public deflateBurnCutIn = 1000000; // 1% default
    uint public deflateBurnCutOut = 1000000; // 1% defualt


    // token => user => stakedAmount
    mapping(address => mapping(address => uint)) public userStakedAmount;
    mapping(address => mapping(address => bool)) public blackListedUser;

    // token => totalStakedAmount
    mapping(address => uint) public totalStakedAmount;

    address public dividendContract;


    function setAuthorisedToken(address _token, bool _authorise, uint8 _burnMethod ) public onlyOwner returns(bool)
    {
        authorisedToken[_token] = _authorise;
        burnMethod[_token] = _burnMethod;
        return true;
    }

    function setDividendContract(address _dividendContract) public onlyOwner returns(bool)
    {
        dividendContract = _dividendContract;
        return true;
    }

    function setUnStakeBurnCut(uint _unStakeBurnCut) public onlyOwner returns(bool)
    {
        unStakeBurnCut = _unStakeBurnCut;
        return true;
    }    

    function setDeflateBurnCutIn(uint _deflateBurnCutIn) public onlyOwner returns(bool)
    {
        deflateBurnCutIn = _deflateBurnCutIn;
        return true;
    }    

    function setDeflateBurnCutOut(uint _deflateBurnCutOut) public onlyOwner returns(bool)
    {
        deflateBurnCutOut = _deflateBurnCutOut;
        return true;
    }  

    function setUserToBlackList(address _token, address _user) public onlyOwner returns(bool)
    {
        blackListedUser[_token][_user] = true;
        return true;
    }

    function removeUserFromBlackList(address _token, address _user) public onlyOwner returns(bool)
    {
        blackListedUser[_token][_user] = false;
        return true;
    }
    event stakeMyTokenEv(address token, address user, uint amount,uint remaining, uint InBurnCut );
    function stakeMyToken(address _token, uint _amount) public returns(bool)
    {
        require(!safeGuard, "Paused by admin");
        require(authorisedToken[_token] , "token not authorised");
        require(tokenInterface(_token).transferFrom(msg.sender, address(this), _amount),"token transfer failed");

        uint usrAmount = userStakedAmount[_token][msg.sender];
        require(dividendInterface(dividendContract).withdrawMyDividend(_token,false), "withdraw fail");

        uint burnCut = _amount * deflateBurnCutIn / 100000000;
        uint remaining = _amount - burnCut;
        if(burnCut > 0) 
        {
            if(burnMethod[_token] == 1 ) require(tokenInterface(_token).transfer(address(0), burnCut ), "token in burn failed");
            else if(burnMethod[_token] == 2 ) require(tokenInterface(_token).burn(burnCut), "token in burn failed");
            else if(burnMethod[_token] == 3) 
            {
                require(tokenInterface(_token).transfer(dividendContract, burnCut),"token transfer failed" );
                require(dividendInterface(dividendContract).directDistribute(_token,burnCut), "stake update fail");
            } 
            else if(burnMethod[_token] == 4) 
            {
                require(tokenInterface(_token).transfer(dividendContract, burnCut),"token transfer failed" );
                require(dividendInterface(dividendContract).addToRegular(_token,burnCut), "stake update fail");                
            }           
        }

        userStakedAmount[_token][msg.sender] = usrAmount.add(remaining);
        totalStakedAmount[_token] = totalStakedAmount[_token].add(remaining);


        emit stakeMyTokenEv(_token, msg.sender,_amount, remaining, burnCut);
        return true;
    }

    event reInvestMyTokenEv(address token, address user, uint amount,uint remaining, uint InBurnCut );
    function reInvestMyToken(address _token, uint _amount) public returns(bool)
    {
        require(authorisedToken[_token] , "token not authorised");
        require(msg.sender == dividendContract, "Invalid caller");

        uint usrAmount = userStakedAmount[_token][tx.origin];
        //require(dividendInterface(dividendContract).withdrawMyDividend(_token), "withdraw fail");

        uint burnCut = _amount * deflateBurnCutIn / 100000000;
        uint remaining = _amount - burnCut;
        if(burnCut > 0) 
        {
            if(burnMethod[_token] == 1 ) require(tokenInterface(_token).transfer(address(0), burnCut ), "token in burn failed");
            else if(burnMethod[_token] == 2 ) require(tokenInterface(_token).burn(burnCut), "token in burn failed");
            else if(burnMethod[_token] == 3) 
            {
                require(tokenInterface(_token).transfer(dividendContract, burnCut),"token transfer failed" );
                require(dividendInterface(dividendContract).directDistribute(_token,burnCut), "stake update fail");
            } 
            else if(burnMethod[_token] == 4) 
            {
                require(tokenInterface(_token).transfer(dividendContract, burnCut),"token transfer failed" );
                require(dividendInterface(dividendContract).addToRegular(_token,burnCut), "stake update fail");                
            }           
        }

        userStakedAmount[_token][tx.origin] = usrAmount.add(remaining);
        totalStakedAmount[_token] = totalStakedAmount[_token].add(remaining);


        emit stakeMyTokenEv(_token, tx.origin,_amount, remaining, burnCut);
        return true;
    }


    event unStakeMyTokenEv(address token, address user, uint amount,uint remaining, uint unStakeAndOutBurnCut );
    function unStakeMyToken(address _token, uint _amount) public returns(bool)
    {
        require(!safeGuard, "Paused by admin");
        require(authorisedToken[_token] , "token not authorised");
        require(!blackListedUser[_token][msg.sender], "this user is not allowed");
        uint usrAmount = userStakedAmount[_token][msg.sender];
        require(usrAmount >= _amount && _amount > 0 ,"Not enough token");
        if(usrAmount > 0 ) require(dividendInterface(dividendContract).withdrawMyDividend(_token, false), "withdraw fail");

        userStakedAmount[_token][msg.sender] = usrAmount.sub(_amount);
        totalStakedAmount[_token] = totalStakedAmount[_token].sub(_amount);



        uint burnCut = _amount * (deflateBurnCutOut + unStakeBurnCut)/ 100000000;
        uint remaining = _amount - burnCut;
        if(burnCut > 0) 
        {
            if(burnMethod[_token] == 1) require(tokenInterface(_token).transfer(address(0), burnCut ), "token our and unStake burn failed");
            else if(burnMethod[_token] == 2) require(tokenInterface(_token).burn(burnCut), "token our and unStake burn failed");
            else if(burnMethod[_token] == 3) 
            {
                require(tokenInterface(_token).transfer(dividendContract, burnCut),"token transfer failed" );
                require(dividendInterface(dividendContract).directDistribute(_token,burnCut), "stake update fail");
            }
        }

        if(burnMethod[_token] == 0) require(tokenInterface(_token).transfer(msg.sender, _amount ), "token transfer failed 1");
        else require(tokenInterface(_token).transfer(msg.sender, remaining ), "token transfer failed 2");
        emit unStakeMyTokenEv(_token, msg.sender,_amount, remaining, burnCut);
        return true;
    }


    event unStakeBlackListedEv(address tokenaddress, address _user, address _owner, uint amount);
    function unStakeBlackListed(address _token,address _user) public onlyOwner returns(bool)
    {
        require(authorisedToken[_token] , "token not authorised");
        uint usrAmount = userStakedAmount[_token][_user];
        require(usrAmount > 0 , "not stake amount found");
        require(dividendInterface(dividendContract).resetUserDatas(_token,_user), "withdraw fail");

        userStakedAmount[_token][_user] = 0;
        totalStakedAmount[_token] = totalStakedAmount[_token].sub(usrAmount);
        require(tokenInterface(_token).transfer(owner, usrAmount ), "token transfer failed 2");
        emit unStakeBlackListedEv(_token,_user, owner,usrAmount);
        return true;
    }

    function emergencyWithdrawEth(uint _amount) public onlyOwner returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

    function emergencyWithdrawToken(address _token, uint _amount) public onlyOwner returns (bool)
    {
        require(tokenInterface(_token).transfer(owner, _amount ), "token transfer failed");
        return true;
    }


    function changeSafeGuardStatus() public onlyOwner returns(bool)
    {
        safeGuard = !safeGuard;
        return true;
    }

}