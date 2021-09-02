//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//                   Version 2, December 2004
// 
//Copyright (C) 2021 ins3project <[email protected]>
//
//Everyone is permitted to copy and distribute verbatim or modified
//copies of this license document, and changing it is allowed as long
//as the name is changed.
// 
//           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
//
// You just DO WHAT THE FUCK YOU WANT TO.
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;
import "./lib.sol";



struct CoinHolderV2 {
    uint256     principal;  


    uint256     beginTimestamp;
    address[]   pools;
}


contract StakingTokenHolderV2
{
    using SafeMath for uint256;
    mapping(uint256=>CoinHolderV2) public _coinHolders; 

    address _operator;

    function setOperator(address addr) public {
        require(_operator==address(0),"only once");
        _operator=addr;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    function canReleaseTokenHolder(uint256 tokenId) view public returns(bool/*,address [] memory*/){
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        for (uint256 i=0;i<holder.pools.length;++i){
            address poolAddr=holder.pools[i];
            require(poolAddr!=address(0),"Pool address should not be 0");
            IClaimPool pool=IClaimPool(poolAddr);
            if(!pool.isClosed()){
                if(pool.productTokenRemainingAmount() < holder.principal || now >= pool.productTokenExpireTimestamp()){
                    return false;
                }
            }
        }
        return true;

    }



    function coinHolderRemainingPrincipal(uint256 tokenId) view public returns(uint256){
        CoinHolderV2 storage holder = _coinHolders[tokenId];
        uint256 remainingPrincipal = holder.principal;
        for (uint256 i=0;i<holder.pools.length;++i){
            address addr=holder.pools[i];
            IClaimPool pool=IClaimPool(addr);
            uint256 totalNeedPayFromStaking = pool.totalNeedPayFromStaking();
            if(totalNeedPayFromStaking>0){
                uint256 totalStakingAmount = pool.totalStakingAmount();
                uint256 stakingAmount = holder.principal;
                uint256 userPayAmount = stakingAmount.mul(totalNeedPayFromStaking).div(totalStakingAmount);
                if(remainingPrincipal>=userPayAmount){
                    remainingPrincipal = remainingPrincipal.sub(userPayAmount);
                }else{
                    remainingPrincipal = 0;
                    break;
                }
            }
        }
        return remainingPrincipal;
    }

    function capitalTokenAddress(uint256 tokenId) view public returns(address){
        CoinHolderV2 storage holder = _coinHolders[tokenId];
        return IClaimPool(holder.pools[0]).tokenAddress();
    }

    function calcPremiumsRewards(uint256 tokenId) view public returns(uint256 rewards){
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        /*if(holder.haveHarvestPremiums){
            return 0;
        }*/
        rewards=0;
        for (uint256 i=0;i<holder.pools.length;++i){
            address poolAddr=holder.pools[i];
            IClaimPool pool=IClaimPool(poolAddr);
            if (pool.isNormalClosed()){
                rewards=rewards.add(pool.calcPremiumsRewards(holder.principal, holder.beginTimestamp));
            }
        }
        return rewards;
    }


    function isAllPoolsClosed(uint256 tokenId) view public returns(bool){
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        for (uint256 i=0;i<holder.pools.length;++i){
            IClaimPool pool=IClaimPool(holder.pools[i]);
            if (!pool.isClosed()){
                return false;
            }
        }
        return true;
    }

    function getTokenHolderAmount(uint256 tokenId,address/* poolAddr*/) view public returns(uint256){ //TODO
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        return holder.principal;
    }

    function getTokenHolder(uint256 tokenId) view public returns(uint256,uint256,uint256,uint256,address [] memory){   
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        uint256 remainingPrincipal = coinHolderRemainingPrincipal(tokenId);

        return (holder.principal,remainingPrincipal,0,holder.beginTimestamp,holder.pools);
    }

    function getTokenHolderV2(uint256 tokenId) view public returns(CoinHolderV2 memory){   
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        return holder;
    }

    function getTokenHolderPools(uint256 tokenId) view public returns(address [] memory){   
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        return holder.pools; 
    }

    function putTokenHolderInPool(address poolAddr,uint256 tokenId/*,uint256 amount*/) onlyOperator public {
        CoinHolderV2 storage holder=_coinHolders[tokenId];
        holder.pools.push(poolAddr);
    }


    function set(uint256 tokenId,uint256 principal,/*uint256 availableMarginAmount,*/uint256 beginTimestamp/*,bytes8 coinName*/) onlyOperator public{
        _coinHolders[tokenId]=CoinHolderV2(principal,/*availableMarginAmount,*/beginTimestamp,/*coinName,*/new address[](0));
    }

    function initSponsor() external {
        ISponsorWhiteListControl SPONSOR = ISponsorWhiteListControl(address(0x0888000000000000000000000000000000000001));
        address[] memory users = new address[](1);
        users[0] = address(0);
        SPONSOR.addPrivilege(users);
    }
}