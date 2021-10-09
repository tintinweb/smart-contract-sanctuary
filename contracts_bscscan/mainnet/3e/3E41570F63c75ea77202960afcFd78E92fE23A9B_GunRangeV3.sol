pragma solidity >=0.6.0;
//SPDX-License-Identifier: UNLICENSED
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract GunRangeV3 is Ownable, ReentrancyGuard {
    string public name = "GunRange V3";
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address payable private ReceiveToken;

    struct IDOPool {
        uint256 Id;
        uint256 Begin;
        uint256 End;
        uint256 Type; //1: comminity round, 3: whitelist round
        IBEP20 IDOToken;
        IBEP20 INPUTToken;
        uint256 MaxPurchaseTier2; //==comminity tier
        uint256 MaxPurchaseTier3;
        uint256 TotalCap;
        uint256 MinimumTokenSoldout;
        uint256 TotalToken; //total sale token for this pool
        uint256 RatePerBUSD;
        uint256 TotalSold; //total number of token sold
    }

    struct ClaimInfo {
        uint256 ClaimTime1;
        uint256 PercentClaim1;
        uint256 ClaimTime2;
        uint256 PercentClaim2;
        uint256 ClaimTime3;
        uint256 PercentClaim3;
        uint256 ClaimTime4;
        uint256 PercentClaim4;
        uint256 ClaimTime5;
        uint256 PercentClaim5;
        uint256 ClaimTime6;
        uint256 PercentClaim6;
    }

    struct User {
        uint256 Id;
        address UserAddress;
        bool IsWhitelist;
        bool IsBlacklist;
        uint256 TotalTokenPurchase;
        uint256 TotalBUSDPurchase;
        uint256 PurchaseTime;
        uint256 LastClaimed;
        uint256 TotalPercentClaimed;
        uint256 NumberClaimed;
        bool IsActived;
    }

    mapping(uint256 => mapping(address => User)) public users; //poolid - listuser

    IDOPool[] pools;

    mapping(uint256 => ClaimInfo) public claimInfos; //pid

    constructor(address payable receiveTokenAdd) public {
        ReceiveToken = receiveTokenAdd;
    }

    function addMulWhitelist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            users[pid][user[i]].Id = pid;
            users[pid][user[i]].UserAddress = user[i];
            users[pid][user[i]].IsWhitelist = true;
            users[pid][user[i]].IsActived = true;
        }
    }

    function updateWhitelist(
        address user,
        uint256 pid,
        bool isWhitelist,
        bool isActived
    ) public onlyOwner {
        users[pid][user].IsWhitelist = isWhitelist;
        users[pid][user].IsActived = isActived;
    }

    function IsWhitelist(
        address user,
        uint256 pid
    ) public view returns (bool) {
        uint256 poolIndex = pid.sub(1);
        if (pools[poolIndex].Type == 1) // community round
        {
            return true;
        }  else if (pools[poolIndex].Type == 3) //whitelist round
        {
            if (users[poolIndex][user].IsWhitelist) return true;
            return false;
        } else {
            return false;
        }
    }

    function addPool(
        uint256 begin,
        uint256 end,
        uint256 _type,
        IBEP20 idoToken,
        IBEP20 inputtoken,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerBUSD,
        uint256 minimumTokenSoldout
    ) public onlyOwner {
        uint256 id = pools.length.add(1);
        pools.push(
            IDOPool({
                Id: id,
                Begin: begin,
                End: end,
                Type: _type,
                IDOToken: idoToken,
                INPUTToken: inputtoken,
                MaxPurchaseTier2: maxPurchaseTier2,
                MaxPurchaseTier3: maxPurchaseTier3,
                TotalCap: totalCap,
                TotalToken: totalToken,
                RatePerBUSD: ratePerBUSD,
                TotalSold: 0,
                MinimumTokenSoldout: minimumTokenSoldout
            })
        );
    }

    function addClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 percentClaim4,
        uint256 claimTime4,
        uint256 percentClaim5,
        uint256 claimTime5,
        uint256 percentClaim6,
        uint256 claimTime6,
        uint256 pid
    ) public onlyOwner {
        claimInfos[pid].ClaimTime1 = claimTime1;
        claimInfos[pid].PercentClaim1 = percentClaim1;
        claimInfos[pid].ClaimTime2 = claimTime2;
        claimInfos[pid].PercentClaim2 = percentClaim2;
        claimInfos[pid].ClaimTime3 = claimTime3;
        claimInfos[pid].PercentClaim3 = percentClaim3;
        claimInfos[pid].ClaimTime4 = claimTime4;
        claimInfos[pid].PercentClaim4 = percentClaim4;
        claimInfos[pid].ClaimTime5 = claimTime5;
        claimInfos[pid].PercentClaim5 = percentClaim5;
        claimInfos[pid].ClaimTime6 = claimTime6;
        claimInfos[pid].PercentClaim6 = percentClaim6;
    }

    function updateClaimInfo(
        uint256 percentClaim1,
        uint256 claimTime1,
        uint256 percentClaim2,
        uint256 claimTime2,
        uint256 percentClaim3,
        uint256 claimTime3,
        uint256 percentClaim4,
        uint256 claimTime4,
        uint256 percentClaim5,
        uint256 claimTime5,
        uint256 percentClaim6,
        uint256 claimTime6,
        uint256 pid
    ) public onlyOwner {
        if (claimTime1 > 0) {
            claimInfos[pid].ClaimTime1 = claimTime1;
        }
        if (percentClaim1 > 0) {
            claimInfos[pid].PercentClaim1 = percentClaim1;
        }
        if (claimTime2 > 0) {
            claimInfos[pid].ClaimTime2 = claimTime2;
        }
        if (percentClaim2 > 0) {
            claimInfos[pid].PercentClaim2 = percentClaim2;
        }
        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime3 = claimTime3;
        }
        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim3 = percentClaim3;
        }
        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime4 = claimTime4;
        }
        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim4 = percentClaim4;
        }
        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime5 = claimTime5;
        }
        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim5 = percentClaim5;
        }
        if (claimTime3 > 0) {
            claimInfos[pid].ClaimTime6 = claimTime6;
        }
        if (percentClaim3 > 0) {
            claimInfos[pid].PercentClaim6 = percentClaim6;
        }
        
    }

    function updatePool(
        uint256 pid,
        uint256 begin,
        uint256 end,
        uint256 maxPurchaseTier2,
        uint256 maxPurchaseTier3,
        uint256 totalCap,
        uint256 totalToken,
        uint256 ratePerBUSD,
        IBEP20 idoToken,
        uint256 minimumTokenSoldout,
        uint256 pooltype
    ) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        if (begin > 0) {
            pools[poolIndex].Begin = begin;
        }
        if (end > 0) {
            pools[poolIndex].End = end;
        }
        if (maxPurchaseTier2 > 0) {
            pools[poolIndex].MaxPurchaseTier2 = maxPurchaseTier2;
        }
        if (maxPurchaseTier3 > 0) {
            pools[poolIndex].MaxPurchaseTier3 = maxPurchaseTier3;
        }
        if (totalCap > 0) {
            pools[poolIndex].TotalCap = totalCap;
        }
        if (totalToken > 0) {
            pools[poolIndex].TotalToken = totalToken;
        }
        if (ratePerBUSD > 0) {
            pools[poolIndex].RatePerBUSD = ratePerBUSD;
        }
        if (minimumTokenSoldout > 0) {
            pools[poolIndex].MinimumTokenSoldout = minimumTokenSoldout;
        }
        if (pooltype > 0) {
            pools[poolIndex].Type = pooltype;
        }
        pools[poolIndex].IDOToken = idoToken;
    }

    function withdrawBEP20(IBEP20 token) public onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    //withdraw BUSD after IDO
    function withdrawOneIDOFunds(IBEP20 token, uint256 pid) public onlyOwner {
        uint256 poolIndex = pid.sub(1);
        require(pools[poolIndex].TotalSold > 0, "not enough fund");
        uint256 balance = pools[poolIndex].TotalSold / pools[poolIndex].RatePerBUSD;
        require(balance > 0, "not enough fund");
        token.transfer(owner(), balance);
    }
    
    function rescueBUSD(IBEP20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "not enough fund");
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function purchaseIDO(uint256 _amount, uint256 pid) public nonReentrant {
        uint256 poolIndex = pid.sub(1);
        require(
            block.timestamp >= pools[poolIndex].Begin &&
                block.timestamp <= pools[poolIndex].End,
            "invalid time"
        );
        

        //check amount
        uint256 busdAmount = _amount;
        users[pid][msg.sender].TotalBUSDPurchase = users[pid][msg.sender]
        .TotalBUSDPurchase
        .add(busdAmount);
        if (pools[poolIndex].Type == 2) {
            //check user
        require(IsWhitelist(msg.sender, pid), "invalid user");
            //private
            require(
                users[pid][msg.sender].TotalBUSDPurchase <=
                    pools[poolIndex].MaxPurchaseTier3,
                "invalid maximum contribute"
            );
        } else {
            //public
            require(
                users[pid][msg.sender].TotalBUSDPurchase <=
                    pools[poolIndex].MaxPurchaseTier2,
                "invalid maximum contribute"
            );
        }

        uint256 tokenAmount = busdAmount.mul(pools[poolIndex].RatePerBUSD).div(
            1e18
        );

        uint256 remainToken = getRemainIDOToken(pid);
        require(
            remainToken > pools[poolIndex].MinimumTokenSoldout,
            "IDO sold out"
        );
        require(remainToken >= tokenAmount, "IDO sold out");

        users[pid][msg.sender].TotalTokenPurchase = users[pid][
            msg.sender
        ]
        .TotalTokenPurchase
        .add(tokenAmount);

        pools[poolIndex].TotalSold = pools[poolIndex].TotalSold.add(
            tokenAmount
        );
        IBEP20(pools[poolIndex].INPUTToken).transferFrom(msg.sender,address(this), _amount);
    }

    function addMulBlacklist(address[] memory user, uint256 pid)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < user.length; i++) {
            users[pid][user[i]].Id = pid;
            users[pid][user[i]].UserAddress = user[i];
            users[pid][user[i]].IsBlacklist = true;
            users[pid][user[i]].IsActived = true;
        }
    }

    function updateBlacklist(
        address user,
        uint256 pid,
        bool isBlacklist,
        bool isActived
    ) public onlyOwner {
        users[pid][user].IsBlacklist = isBlacklist;
        users[pid][user].IsActived = isActived;
    }

    function IsBlacklist(
        address user,
        uint256 pid
    ) public view returns (bool) {
           uint256 poolIndex = pid.sub(1);
            if (users[poolIndex][user].IsBlacklist) return true;
            return false;
        
    }

    function claimToken(uint256 pid) public nonReentrant {
        require(!IsBlacklist(msg.sender, pid), "invalid user");
        require(
            users[pid][msg.sender].TotalPercentClaimed < 100,
            "you have claimed enough"
        );
        uint256 userBalance = getUserTotalPurchase(pid);
        require(userBalance > 0, "invalid claim");

        uint256 poolIndex = pid.sub(1);
        if (users[pid][msg.sender].NumberClaimed == 0) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime1,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim1).div(100)
            );
          users[pid][msg.sender].TotalPercentClaimed=  users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim1
            );
        } else if (users[pid][msg.sender].NumberClaimed == 1) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime2,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim2).div(100)
            );
            users[pid][msg.sender].TotalPercentClaimed=users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim2
            );
        } else if (users[pid][msg.sender].NumberClaimed == 2) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime3,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim3).div(100)
            );
           users[pid][msg.sender].TotalPercentClaimed= users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim3
            );
        } else if (users[pid][msg.sender].NumberClaimed == 3) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime4,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim4).div(100)
            );
           users[pid][msg.sender].TotalPercentClaimed= users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim4
            );
        } else if (users[pid][msg.sender].NumberClaimed == 4) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime5,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim5).div(100)
            );
           users[pid][msg.sender].TotalPercentClaimed= users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim5
            );
        } else if (users[pid][msg.sender].NumberClaimed == 5) {
            require(
                block.timestamp >= claimInfos[poolIndex].ClaimTime6,
                "invalid time"
            );
            pools[poolIndex].IDOToken.transfer(
                msg.sender,
                userBalance.mul(claimInfos[poolIndex].PercentClaim6).div(100)
            );
           users[pid][msg.sender].TotalPercentClaimed= users[pid][msg.sender].TotalPercentClaimed.add(
                claimInfos[poolIndex].PercentClaim6
            );
        } 

        users[pid][msg.sender].LastClaimed = block.timestamp;
        users[pid][msg.sender].NumberClaimed.add(1);
    }

    function getUserTotalPurchase(uint256 pid) public view returns (uint256) {
        return users[pid][msg.sender].TotalTokenPurchase;
    }

    function getRemainIDOToken(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        uint256 tokenBalance = getBalanceTokenByPoolId(pid);
        if (pools[poolIndex].TotalSold > tokenBalance) {
            return 0;
        }

        return tokenBalance.sub(pools[poolIndex].TotalSold);
    }

    function getBalanceTokenByPoolId(uint256 pid)
        public
        view
        returns (uint256)
    {
        uint256 poolIndex = pid.sub(1);

        return pools[poolIndex].TotalToken;
    }

    function getPoolInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            IBEP20
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            pools[poolIndex].Begin,
            pools[poolIndex].End,
            pools[poolIndex].Type,
            pools[poolIndex].RatePerBUSD,
            pools[poolIndex].TotalSold,
            pools[poolIndex].IDOToken
        );
    }

    function getClaimInfo(uint256 pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 poolIndex = pid.sub(1);
        return (
            claimInfos[poolIndex].ClaimTime1,
            claimInfos[poolIndex].PercentClaim1,
            claimInfos[poolIndex].ClaimTime2,
            claimInfos[poolIndex].PercentClaim2,
            claimInfos[poolIndex].ClaimTime3,
            claimInfos[poolIndex].PercentClaim3,
            claimInfos[poolIndex].ClaimTime4,
            claimInfos[poolIndex].PercentClaim4,
            claimInfos[poolIndex].ClaimTime5,
            claimInfos[poolIndex].PercentClaim5,
            claimInfos[poolIndex].ClaimTime6,
            claimInfos[poolIndex].PercentClaim6
        );
    }

    function getPoolSoldInfo(uint256 pid) public view returns (uint256) {
        uint256 poolIndex = pid.sub(1);
        return (pools[poolIndex].TotalSold);
    }

    function getWhitelistfo(uint256 pid)
        public
        view
        returns (
            address,
            bool,
            uint256,
            uint256
        )
    {
        return (
            users[pid][msg.sender].UserAddress,
            users[pid][msg.sender].IsWhitelist,
            users[pid][msg.sender].TotalTokenPurchase,
            users[pid][msg.sender].TotalBUSDPurchase
        );
    }

    function getUserInfo(uint256 pid, address user)
        public
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[pid][user].IsWhitelist,
            users[pid][user].TotalTokenPurchase,
            users[pid][user].TotalBUSDPurchase,
            users[pid][user].TotalPercentClaimed
        );
    }
}