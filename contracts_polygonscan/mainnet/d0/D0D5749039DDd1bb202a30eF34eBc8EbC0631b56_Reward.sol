/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

abstract contract StakeContract {
    struct ParticipantInfo {
        uint deposits;
        uint withdrawals;
        uint stakes;
        uint unstakes;
        uint claims;
    }

    //function feeTo() external view virtual returns (address);
    //function owner() external view virtual returns (address);
    function participants(address player) external view virtual returns (ParticipantInfo memory);
}

contract Reward
{
    uint256 ONE_HUNDRED     = 100000000000000000000;

    struct RewardModel {
        uint code;
        uint frequencyinseconds;
        uint mindeposittimes;
        uint minwithdrawtimes;
        uint minstaketimes;
        uint minunstaketimes;
        uint minbalanceincoin;
        address coinaddresstocheckbalance;
        uint256 maxprizeinpercent;
        uint256 minprizeinpercent;
        address coinprizeaddress;
        uint256 bag;
        uint active;
    }

    struct PrizeModel{
        uint code;
        uint256 value;
        uint time;
    }

    //Reward records code => RewardModel
    mapping(uint => RewardModel) internal records;

    //Player prize address => code => PrizeModel
    mapping(address => mapping(uint => PrizeModel)) public lastprize;

    event OnPrize(address player, uint code, uint time, uint256 value, uint256 bag);

    address public owner;
    address public stakecontract;

    constructor(address _stakecontract) {
        owner = msg.sender;
        stakecontract = _stakecontract;
    }

    function setOwner(address _newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        owner = _newValue;
        return true;
    }

    function setReward(uint _code, uint _frequencyinseconds, uint _mindeposittimes, uint _minwithdrawtimes, uint _minstaketimes, uint _minunstaketimes,
                        uint _minbalanceincoin, address _coinaddresstocheckbalance, uint256 _maxprizeinpercent, uint256 _minprizeinpercent,
                        address _coinprizeaddress) external returns (bool success)
    {

        require(_minprizeinpercent <= ONE_HUNDRED, "IP"); //Invalid percent value
        require(_maxprizeinpercent <= ONE_HUNDRED, "IP"); //Invalid percent value

        records[_code].code                         = _code;
        records[_code].frequencyinseconds           = _frequencyinseconds;
        records[_code].mindeposittimes              = _mindeposittimes;
        records[_code].minwithdrawtimes             = _minwithdrawtimes;
        records[_code].minstaketimes                = _minstaketimes;
        records[_code].minunstaketimes              = _minunstaketimes;
        records[_code].minbalanceincoin             = _minbalanceincoin;
        records[_code].coinaddresstocheckbalance    = _coinaddresstocheckbalance;
        records[_code].maxprizeinpercent            = _maxprizeinpercent;
        records[_code].minprizeinpercent            = _minprizeinpercent;
        records[_code].coinprizeaddress             = _coinprizeaddress;
        //records[_code].bag                          = 0;
        records[_code].active                       = 1;

        return true;
    }

    function getReward(uint _code) external view returns (RewardModel memory result)
    {
        return records[_code];
    }

    function setRewardActiveValue(uint _code, uint _newValue) public returns (bool success)
    {
        require(msg.sender == owner, 'Forbidden');

        records[_code].active = _newValue;
        return true;
    }

    function setStakeContract(address _stakecontract) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        stakecontract = _stakecontract;
    }

    function setBagValue(uint _code, uint256 _value) external returns (bool success)
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        records[_code].bag = _value;

        return true;
    }

    function depositTokenToBag(uint _code, uint256 _value) external returns (bool success)
    {
        require(records[_code].coinprizeaddress != address(0), 'IA'); //Invalid Contract Address

        //Receive token for bag
        ERC20(records[_code].coinprizeaddress).transferFrom(msg.sender, address(this), _value);
        records[_code].bag = safeAdd(records[_code].bag, _value);

        return true;
    }

    function getStakeParticipantInfo(address _player) public view returns(StakeContract.ParticipantInfo memory result)
    {
        StakeContract.ParticipantInfo memory info = StakeContract(stakecontract).participants(_player);
        return info;
    }

    function checkAvailability(address _player, uint _code) public view returns (uint success)
    {
        //Check is active
        if(records[_code].active == 0)
        {
            return 0;
        }

        //Check has any activated trigger
        if(records[_code].frequencyinseconds == 0 &&
            records[_code].mindeposittimes == 0 &&
            records[_code].minwithdrawtimes == 0 &&
            records[_code].minstaketimes == 0 &&
            records[_code].minunstaketimes == 0 &&
            records[_code].minbalanceincoin == 0)
        {
            return 2;
        }

        //Check data consistency
        if(records[_code].coinaddresstocheckbalance == address(0))
        {
            if(records[_code].minbalanceincoin > 0)
            {
                return 3; //Has min balance but undefined coin address 
            }
        }

        if(records[_code].maxprizeinpercent == 0 && records[_code].minprizeinpercent == 0)
        {
            return 4; //No prize percent
        }

        if(records[_code].maxprizeinpercent < records[_code].minprizeinpercent)
        {
            return 4; //Inconsistent prize percent Max less than Min
        }

        if(records[_code].coinprizeaddress == address(0))
        {
            return 5; //Undefined coin prize
        }

        //Check bag balance
        if(records[_code].bag == 0)
        {
            return 6; //Empty bag
        }

        if(ERC20(records[_code].coinprizeaddress).balanceOf(address(this)) == 0)
        {
            return 7; //Empty balance for prize
        }

        //Check parameters
        StakeContract.ParticipantInfo memory playerInfo = StakeContract(stakecontract).participants(_player);
        
        if(playerInfo.deposits < records[_code].mindeposittimes)
        {
            return 8; //Deposit requirements
        }

        if(playerInfo.withdrawals < records[_code].minwithdrawtimes)
        {
            return 9; //Withdraw requirements
        }

        if(playerInfo.stakes < records[_code].minstaketimes)
        {
            return 10; //Stakes requirements
        }

        if(playerInfo.unstakes < records[_code].minunstaketimes)
        {
            return 11; //Unstakes requirements
        }

        if(records[_code].minbalanceincoin > 0)
        {
            uint256 playerBalance = ERC20(records[_code].coinaddresstocheckbalance).balanceOf(_player);
            if(playerBalance < records[_code].minbalanceincoin)
            {
                return 12; //Minimum balance requirements
            }
        }

        //Check time
        uint secPassed = block.timestamp - lastprize[_player][_code].time;
        if(secPassed < records[_code].frequencyinseconds)
        {
            return 100; //Time-lock
        }


        return 1;
    }

    function getPrizeValue(uint _code) external view returns (uint256 result)
    {
        uint256 bagPercent = rgn(records[_code].minprizeinpercent ,records[_code].maxprizeinpercent); //Eg 10 (10000000000000000000)
        
        require(bagPercent > 0, 'IBP'); //Invalid bag percentage
        require(bagPercent <= ONE_HUNDRED, "IP");  //Invalid percent value

        uint256 prizevalue = safeDiv(safeMul(records[_code].bag, bagPercent), ONE_HUNDRED);

        return prizevalue;
    }

    function claim(address _player, uint _code, uint256 prizevalue) external returns (bool success)
    {
        require( checkAvailability(_player, _code) == 1, 'NA' ); //Prize not available

        require(records[_code].maxprizeinpercent > 0, 'IBP'); //Invalid bag percentage
        require(records[_code].maxprizeinpercent <= ONE_HUNDRED, "IP");  //Invalid percent value
        require(prizevalue > 0, 'ZV'); //Zero value
        require(prizevalue <= records[_code].bag, 'OB'); //Over bag value

        uint256 maxprizevalue = safeDiv(safeMul(records[_code].bag, records[_code].maxprizeinpercent), ONE_HUNDRED);
        require(prizevalue <= maxprizevalue, 'OP'); //Over prize
        
        require(records[_code].coinprizeaddress != address(0), 'IA'); //Invalid Contract Address

        require(ERC20(records[_code].coinprizeaddress).balanceOf(address(this)) >= prizevalue, 'NB'); //No Balance

        //Pay the prize
        ERC20(records[_code].coinprizeaddress).transfer(msg.sender, prizevalue);

        //Write event log
        emit OnPrize(_player, _code, block.timestamp, prizevalue, records[_code].bag);

        //Update bag
        records[_code].bag = safeSub(records[_code].bag, prizevalue);

        //Update prize record
        lastprize[_player][_code].time = block.timestamp;
        lastprize[_player][_code].value = prizevalue;

        return true; 
    }

    function rgn(uint256 min, uint256 max) internal view returns (uint256) 
    {
        if(min > max)
        {
            return 0;
        }

        if(min == max)
        {
            return min;
        }

        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % (safeSub(max, min));
        randomnumber = safeAdd(randomnumber, min);
        return randomnumber;
    }
    

    /*
    function getStakeFeeTo() public view returns(address result) 
    {
        address sfeeTo = StakeContract(stakecontract).feeTo();
        return sfeeTo;
    }

    function getStakeOwner() public view returns(address result) 
    {
        address sOwner = StakeContract(stakecontract).owner();
        return sOwner;
    }
    */

    //Safe Math Functions
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }

}