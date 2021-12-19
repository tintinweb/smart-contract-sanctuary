/**
 *Submitted for verification at polygonscan.com on 2021-12-18
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Fakhama is IERC20
{
    mapping(address => uint256) private _balances;

    mapping(uint=>User) public map_Users;
    mapping(address=>uint) public map_UserIds;
    mapping(uint=>Rank) public map_ranks;
    mapping(uint8=>uint) LevelPercentage;

    address public owner;
    address public marketingAddress;
    address public vipCommunity;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

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
        uint ROIDividend;
        uint LevelDividend;
        uint DividendWithdrawn;
    }

    struct Rank
    {
        uint Id;
        string Name;
        uint Business;
        uint RequiredRankQualifiers;
    }

    struct UserInfo
    {
        User UserInfo;
        string CurrentRankName;
        string NextRankName;
        uint RequiredBusinessForNextRank;
        uint CoinRate;
        uint CoinsHolding;
        uint CurrentRankId;
    }

    uint TotalUser = 0;
    uint VIPCommunityPercentage = 1;
    uint MarketingFeePercentage = 2;
    uint _initialCoinRate = 100000000;
    uint public coinsPerMatic=0;
    uint public TotalHoldings=0;

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
    }

    constructor(address _owner, address _marketingAddress, address _vipCommunity)
    {
        _name = "Fakhama";
        _symbol = "FKT";

        owner = _owner;
        marketingAddress = _marketingAddress;
        vipCommunity = _vipCommunity;

        LevelPercentage[1] = 90;
        LevelPercentage[2] = 30;
        LevelPercentage[3] = 20;
        LevelPercentage[4] = 15;//Decimal values cannot be stored. So, later on, divide by 10.
        LevelPercentage[5] = 15;
        LevelPercentage[6] = 20;

        map_ranks[1] = Rank({
            Id:1,
            Name:"Executive",
            Business:0,
            RequiredRankQualifiers:0
        });

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
            RankId:1,
            DirectIds:new uint[](0),
            ROIDividend:0,
            LevelDividend:0,
            DividendWithdrawn:0
        });
        
        map_Users[Id]=u;
        map_UserIds[_owner] = Id;
        _balances[msg.sender] = 10**18;

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
                ROIDividend:0,
                LevelDividend:0,
                DividendWithdrawn:0
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
        uint tokens = (amount*60*getCoinRate(memberId))/(100*10**18);

        map_Users[memberId].Investment+=amount;

        _mint(map_Users[memberId].Address, tokens);
        
        TotalHoldings+=amount;

        updateCoinRate();

        uint8 level=1;
        uint _spId = map_Users[memberId].SponsorId;

        while(_spId>0){
            map_Users[_spId].Business+=amount;
            map_Users[_spId].NextRankBusiness+=amount;

            updateRank(_spId);

            if(level>=1 && level<=6)
            {
                uint _levelIncome = (amount*LevelPercentage[level])/(100*10);

                if(map_Users[_spId].RankId>=level)
                {
                    map_Users[_spId].LevelDividend+=_levelIncome;
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
        uint _rate = _amt/_totalSupply;

        if(_rate>0)
        {
            uint currentId=1;
            
            while(currentId<=TotalUser)
            {
                if(currentId!=onMemberId)
                {
                    uint _divs = _balances[map_Users[currentId].Address]*_rate;
                    map_Users[currentId].ROIDividend+=_divs;
                }
                currentId++;
            }
            
            /*
            while(currentId<=29000)
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
        uint totalDividend = map_Users[memberId].ROIDividend + map_Users[memberId].LevelDividend;
        require(memberId>0, "Invalid user!");
        require(totalDividend-map_Users[memberId].DividendWithdrawn>=amount);

        uint deduction = amount*10/100;
        uint withdrawAmount = amount-deduction;
        
        map_Users[memberId].DividendWithdrawn+=amount;

        uint roi = amount*9/100;
        distributeROI(memberId, roi);

        payable(msg.sender).transfer(withdrawAmount);
        payable(marketingAddress).transfer(deduction-roi);//1% to marketing address
    }

    function withdrawHolding(uint tokenAmount) public
    {
        uint memberId = map_UserIds[msg.sender];
        require(memberId>0, "Invalid user!");
        require(_balances[msg.sender]>=tokenAmount, "Insufficient token balance!");

        uint maticAmount = tokenAmount/getCoinRate(memberId);

        uint deduction = maticAmount*10/100;
        uint withdrawAmount = maticAmount-deduction;
        
        _burn(msg.sender, tokenAmount);

        TotalHoldings-=maticAmount;

        updateCoinRate();

        payable(msg.sender).transfer(withdrawAmount);
        payable(owner).transfer(deduction);
    }

    function updateCoinRate() internal
    {
        coinsPerMatic=TotalHoldings>=(10**18)?_initialCoinRate*(10**18)/TotalHoldings:_initialCoinRate;
    }

    function getCoinRate(uint memberId) public view returns(uint)
    {
        return (TotalHoldings-(map_Users[memberId].Investment))>=(10**18)?_initialCoinRate*(10**18)/(TotalHoldings-(map_Users[memberId].Investment)):_initialCoinRate;
    }

    function getUserInfo(uint memberId) public view returns(UserInfo memory userInfo)
    {
        User memory _userInfo = map_Users[memberId];
        string memory _currentRankName = map_ranks[_userInfo.RankId].Name;
        string memory _nextRankName = _userInfo.RankId<6?map_ranks[_userInfo.RankId+1].Name:"";
        uint _requiredBusinessForNextRank = map_ranks[_userInfo.RankId+1].Business;
        uint _coinRate = getCoinRate(memberId);
        uint _coinsHolding = _balances[_userInfo.Address];

        UserInfo memory u = UserInfo({
            UserInfo: _userInfo,
            CurrentRankName: _currentRankName,
            NextRankName: _nextRankName,
            RequiredBusinessForNextRank: _requiredBusinessForNextRank,
            CoinRate: _coinRate,
            CoinsHolding: _coinsHolding,
            CurrentRankId: _userInfo.RankId
        });

        return (u);
    }

    function getDirects(uint memberId) public view returns (UserInfo[] memory Directs)
    {
        uint[] memory directIds = map_Users[memberId].DirectIds;
        UserInfo[] memory _directsInfo=new UserInfo[](directIds.length);

        for(uint i=0; i<directIds.length; i++)
        {
            _directsInfo[i] = getUserInfo(directIds[i]);
        }
        return _directsInfo;
    }

    struct RankInfo
    {
        uint Id;
        string RankName;
        uint ReqBusiness;
        uint UserBusiness;
        uint ReqDirects;
        uint UserDirects;
        string Status;
    }

    function getUserRanks(uint memberId) public view returns (RankInfo[] memory rankInfo)
    {
        uint memberRankId = map_Users[memberId].RankId;
        uint memberBusiness = map_Users[memberId].Business;

        RankInfo[] memory _rankInfo = new RankInfo[](6);

        for(uint i=1;i<=6;i++)
        {
            Rank memory r = map_ranks[i];
            RankInfo memory temp_RankInfo = RankInfo({
                Id:i,
                RankName:r.Name,
                ReqBusiness:r.Business,
                UserBusiness:memberBusiness>r.Business?r.Business:memberBusiness,
                ReqDirects:r.RequiredRankQualifiers,
                UserDirects:getDirectsCountByRank(memberId, i),
                Status:memberRankId>=i?"Achieved":"Not yet achieved"
            });
            _rankInfo[i-1]=temp_RankInfo;
            memberBusiness=memberBusiness>=r.Business?memberBusiness-r.Business:0;
        }
        return _rankInfo;
    }
}