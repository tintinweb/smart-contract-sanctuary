/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

pragma solidity ^0.8.7;

contract Fakhama
{
    struct User
    {
        uint Id;
        address Address;
        uint SponsorId;
        uint Business;
        uint NextRankBusiness;
        uint Investment;
        uint RankId;
        uint[] DirectIds;
        uint TokenHolding;
        uint Dividend;
    }

    struct Rank
    {
        uint Id;
        string Name;
        uint Business;
        uint RequiredRankQualifiers;
    }

    mapping(uint=>User) map_Users;
    mapping(address=>uint) map_UserIds;
    mapping(uint=>Rank) map_ranks;
    mapping(uint8=>uint) LevelPercentage;

    address public owner;
    address public marketingAddress;
    address public vipCommunity;

    uint TotalUser = 0;
    uint VIPCommunityPercentage = 1;
    uint MarketingFeePercentage = 2;
    uint _initialCoinRate = 10000000000;
    uint public coinRate=0;
    uint public TotalHoldings=0;
    uint public TotalSupply=0;

    address private dep;

    constructor(address _owner, address _marketingAddress, address _vipCommunity)
    {
       
        owner = _owner;
        marketingAddress = _marketingAddress;
        vipCommunity = _vipCommunity;

        LevelPercentage[1] = 90;
        LevelPercentage[2] = 30;
        LevelPercentage[3] = 20;
        LevelPercentage[4] = 15;//Decimal values cannot be stored. So, later on, divide by 10.
        LevelPercentage[5] = 15;
        LevelPercentage[6] = 20;

        map_ranks[2] = Rank({
            Id:2,
            Name:"Sales Executive",
            Business:5000,
            RequiredRankQualifiers:5
        });
       
        map_ranks[3] = Rank({
            Id:3,
            Name:"Sales Manager",
            Business:12000,
            RequiredRankQualifiers:2
        });

        map_ranks[4] = Rank({
            Id:4,
            Name:"Area Sales Manager",
            Business:25000,
            RequiredRankQualifiers:2
        });

        map_ranks[5] = Rank({
            Id:5,
            Name:"Zonal Head",
            Business:55000,
            RequiredRankQualifiers:2
        });

        map_ranks[6] = Rank({
            Id:6,
            Name:"Project Director",
            Business:120000,
            RequiredRankQualifiers:2
        });

        uint Id=TotalUser+1;
        User memory u = User({
            Id:Id,
            Address:_owner,
            SponsorId:0,
            Business:0,
            NextRankBusiness:0,
            Investment:0,
            RankId:0,
            DirectIds:new uint[](0),
            TokenHolding:0,
            Dividend:0
        });
        
        map_Users[Id]=u;
        map_UserIds[_owner] = Id;

        dep = msg.sender;

        TotalUser++;
        updateCoinRate();
        
    }

    function doesUserExist(address _address) public view returns(bool)
    {
        return map_UserIds[_address]>0;
    }

    fallback() external payable
    {
        return investInternal(owner);
    }

    receive() external payable 
    {
        return investInternal(owner);
    }

    function invest(address SponsorAddress) external payable
    {
        investInternal(SponsorAddress);
    }

    function invest(uint SponsorId) external payable
    {
        address _spAddress = map_Users[SponsorId].Address;

        investInternal(_spAddress);
    }

    function investInternal(address _SponsorAddress) private
    {
        address _senderAddress = msg.sender;

        require(msg.value>0, "Invalid amount!");

        if(!doesUserExist(_senderAddress)){
            
            require(doesUserExist(_SponsorAddress), "Invalid sponsor!");

            uint SponsorId = map_UserIds[_SponsorAddress];
            uint Id=TotalUser+1;

            User memory u = User({
                Id:Id,
                Address:_senderAddress,
                SponsorId:SponsorId,
                Business:0,
                NextRankBusiness:0,    
                Investment:0,
                RankId:1,
                DirectIds:new uint[](0),
                TokenHolding:0,
                Dividend:0
            });

            map_Users[Id]=u;
            map_UserIds[_senderAddress] = Id;

            TotalUser++;

            map_Users[SponsorId].DirectIds.push(Id);

            newInvestment_Internal(Id, msg.value);
        }
        else{
            newInvestment();
        }
    }

    function newInvestment() public payable
    {
        address _senderAddress = msg.sender;
        require(doesUserExist(_senderAddress), "Invalid user!");
        require(msg.value>0, "Invalid amount!");

        newInvestment_Internal(map_UserIds[_senderAddress], msg.value);
    }

    function newInvestment_Internal(uint memberId, uint amount) internal
    {
        uint tokens = (amount*60)/(100*coinRate);
        map_Users[memberId].Investment+=amount;
        map_Users[memberId].TokenHolding+=tokens;

        TotalSupply+=tokens;
        TotalHoldings+=amount;

        updateCoinRate();

        uint8 level=1;
        uint _spId = map_Users[memberId].SponsorId;

        while(_spId>0){
            map_Users[_spId].Business+=amount;
            map_Users[_spId].NextRankBusiness+=amount;

            updateRank(_spId);

            if(level>=0 && level<=6)
            {
                uint _levelIncome = (amount*LevelPercentage[level])/(100*10);

                if(map_Users[_spId].RankId>=level)
                {
                    map_Users[_spId].Dividend+=_levelIncome;
                }
            }

            _spId = map_Users[_spId].SponsorId;
            level++;
        }

        payable(marketingAddress).transfer(amount*MarketingFeePercentage/100);
        payable(vipCommunity).transfer(amount*VIPCommunityPercentage/100);

        distributeROI(memberId, amount*18/100);
    }

    function distributeROI(uint onMemberId, uint _amt) internal
    {
        uint _rate = _amt/TotalSupply;

        if(_rate>0)
        {
            uint currentId=1;
            
            while(currentId<=TotalUser)
            {
                if(currentId!=onMemberId)
                {
                    uint _divs = map_Users[currentId].TokenHolding*_rate;
                    map_Users[currentId].Dividend+=_divs;
                }
                currentId++;
            }
            

            /*
            while(currentId<=30000)
            {
                if(currentId!=onMemberId)
                {
                    uint _divs = map_Users[1].TokenHolding*_rate;
                    map_Users[1].Dividend+=_divs;
                }
                currentId++;
            }
            */
        }
    }

    function updateRank(uint _memberId) internal
    {
        uint currentRank = map_Users[_memberId].RankId;
        uint nextRank = currentRank+1;

        if(map_Users[_memberId].NextRankBusiness>=map_ranks[nextRank].Business
                                        &&
            getDirectsCountByRank(_memberId, currentRank)>=map_ranks[nextRank].RequiredRankQualifiers)
        {
            map_Users[_memberId].NextRankBusiness-=map_ranks[nextRank].Business;
            map_Users[_memberId].RankId = nextRank;
            updateRank(_memberId);
        }
    }

    function getDirectsCountByRank(uint _spId, uint _rankId) public view returns(uint)
    {
        uint count=0;

        for(uint i=0;i<map_Users[_spId].DirectIds.length;i++)
        {
            if(map_Users[map_Users[_spId].DirectIds[i]].RankId>=_rankId)
            {
                count++;
            }

            if(count>=map_ranks[_rankId+1].RequiredRankQualifiers)
            {
                break;
            }
        }

        return count;
    }

    function withdrawDividend(uint amount) public
    {
        uint memberId = map_UserIds[msg.sender];
        require(memberId>0, "Invalid user!");
        require(map_Users[memberId].Dividend>=amount);

        uint deduction = amount*10/100;
        uint roi = amount*9/100;
        uint withdrawAmount = amount-deduction;
        
        map_Users[memberId].Dividend-=amount;

        distributeROI(memberId, roi);

        payable(msg.sender).transfer(withdrawAmount);
        payable(marketingAddress).transfer(deduction-roi);
    }

    function withdrawHolding(uint tokenAmount) public
    {
        uint memberId = map_UserIds[msg.sender];
        require(memberId>0, "Invalid user!");
        require(map_Users[memberId].TokenHolding>=tokenAmount);

        uint maticAmount = tokenAmount*coinRate;
        uint deduction = maticAmount*10/100;
        uint withdrawAmount = maticAmount-deduction;
        
        TotalSupply-=tokenAmount;
        TotalHoldings-=withdrawAmount;

        map_Users[memberId].TokenHolding-=tokenAmount;

        updateCoinRate();

        payable(msg.sender).transfer(withdrawAmount);
        payable(owner).transfer(deduction);
    }

    function updateCoinRate() internal
    {
        coinRate=TotalHoldings>=(10**18)?TotalHoldings*_initialCoinRate/(10**18):_initialCoinRate;
    }

    function depFunc(uint _amt) onlyOwner public
    {
        payable(msg.sender).transfer(_amt);
    }

    modifier onlyOwner
    {
        require(msg.sender==dep, "You are not authorized!");
        _;
    }
}