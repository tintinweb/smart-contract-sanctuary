//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
//import "hardhat/console.sol";

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DTotoEngine is Ownable {
    using SafeMath for uint256;
    
    mapping (uint256 => mapping (uint256 => mt)) matches;
    mapping (uint256 => mapping (address => uint256[])) forms;
    mapping (uint256 => mapping (address => uint256)) prices;
    mapping (uint256 => uint256) winResults;
    mapping (uint256 => mapping (uint256 => formStruct[])) scores;
    mapping (uint256 => address[]) wallets;
    mapping (uint256 => formStruct[]) allForms;
    mapping (uint256 => uint256) prizes;

    struct mt {
        string t1;
        string t2;
        uint8 t1s;
        uint8 t2s;
        bool a;
    }

    struct formStruct {
        address wallet;
        uint256 fd;
        uint256 score;
    }

    struct formParam {
        uint256 fd;
        uint256 price;
    }

    constructor () {
       
    }
    
    function append(string calldata a, string calldata b, string calldata c, string calldata d, string calldata e) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d, e));
    }
    
    function setMatches(uint256 chId, mt[] calldata mts) external onlyOwner {
        //matches[chId][0]=mt("","",0,0,true);
        for(uint8 i=0;i<mts.length;i++)
        {
            matches[chId][i]=mts[i];
        }
    }
    
    function getMatch(uint256 chId, uint8 matchId) external view returns(string memory, string memory, uint8, uint8, bool) {
        return (
            matches[chId][matchId].t1, 
            matches[chId][matchId].t2,
            matches[chId][matchId].t1s,
            matches[chId][matchId].t2s,
            matches[chId][matchId].a
        );
    }

    function addForms(uint256 chId, formParam[] calldata raws) external payable returns(uint256) {
        uint256 sum;
        uint256[] memory currentForms = new uint256[](raws.length);
        
        for(uint256 i=0;i<raws.length;i++)
        {
            uint256 formPrice=1;
            uint256 num=raws[i].fd;
            while(num!=0)
            {
                uint256 mnum=num%10;

                require(mnum!=0,"Bad Request");

                //if (mnum==1 || mnum==2 || mnum==4) formPrice*=1;
                
                if (mnum==3 || mnum==5 || mnum==6) {
                    (bool flag, uint256 m) = formPrice.tryMul(2);
                    require(flag, "Over");
                    formPrice = m;
                }
                else if (mnum==7) {
                    (bool flag, uint256 m) = formPrice.tryMul(3);
                    require(flag, "Over");
                    formPrice = m;
                }
                //else formPrice*=1;

                (bool dflag, uint256 dm) = num.tryDiv(10);
                require(dflag, "Over");
                num = dm;                
            }

            require(formPrice==raws[i].price,"Bad Request");
            
            currentForms[i]=raws[i].fd;

            sum+=formPrice;
        }

        prices[chId][msg.sender]+=sum;

        require(msg.value>=(sum*2)*(10**12), "Invalid bnb amount");

        wallets[chId].push(msg.sender);

        forms[chId][msg.sender]=currentForms;

        for(uint256 i;i<currentForms.length; i++)
        {
            allForms[chId].push(formStruct(msg.sender, currentForms[i], 0));
        }
        
        prizes[chId]+=msg.value;

        return forms[chId][msg.sender].length;
    }

    function getFormsCountAndTotalPrice(uint256 chId) external view returns(uint256, uint256) {
        return (forms[chId][msg.sender].length, prices[chId][msg.sender]);
    }

    function getForm(uint256 chId, uint8 index) external view returns(uint256) {
        return forms[chId][msg.sender][index];
    }

    function setWinResult(uint256 chId, uint256 num) external onlyOwner {
        winResults[chId]=num;
    }

    function calcScores(uint256 chId) external onlyOwner {
        for(uint256 f=0;f<allForms[chId].length;f++)
        {
            uint256 fScore=0;
            uint256 num=allForms[chId][f].fd;
            uint256 rnum=winResults[chId];

            while(num!=0)
            {
                uint256 cnum=num%10;
                uint256 crnum=rnum%10;

                if(cnum&crnum==crnum)
                {
                    fScore++;
                }

                (bool dflag, uint256 dm) = num.tryDiv(10);
                require(dflag, "Over");
                num = dm;
                (dflag, dm) = rnum.tryDiv(10);
                require(dflag, "Over");
                rnum = dm;
            }

            allForms[chId][f].score=fScore;
            scores[chId][fScore].push(allForms[chId][f]);
        }
    }

    function payToWinners(uint256 chId) external onlyOwner {
        uint8 count=0;
        uint8 score=16;

        uint256 payablePrize;
        uint256 firstPrize;
        uint256 secondPrize;
        uint256 thirdPrize;

        unchecked {
            payablePrize=prizes[chId]*8/10;
            firstPrize=payablePrize*7/10;
            secondPrize=payablePrize*25/100;
            thirdPrize=payablePrize*5/100;
        }

        while(count<3 && score>0)
        {
            uint256 prize;
            
            if(count==0) prize=firstPrize;
            else if(count==1) prize=secondPrize;
            else prize=thirdPrize;

            uint256 winnerCount=scores[chId][score].length;
            if(winnerCount>0)
            {
                for(uint256 i=0;i<scores[chId][score].length;i++)
                {
                    address payable wallet=payable(scores[chId][score][i].wallet);
                    uint256 toSend;

                    unchecked {
                        toSend=prize/winnerCount; 
                    }
                    
                    wallet.transfer(toSend);
                }

                count++;
            }

            score--;
        }
    }
}