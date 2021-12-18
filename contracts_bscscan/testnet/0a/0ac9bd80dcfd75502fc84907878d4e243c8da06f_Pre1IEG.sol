// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./SafeMath.sol";
import "./IERC20.sol";

contract Pre1IEG{

    uint public surplus = 1000000*10**18;
    uint public usdtPrice = 2*10**17;
    uint public maxUsdt = 6000*10**18;
    uint public minUsdt = 10*10**18;
    uint public countAmount = 1000000*10**18;
    uint32 public startTime = 1639094888;
    uint32 public t = 3600*24;
    uint16 private base = 10000;
    uint16 public release = 1000;
    uint16 public arrival = 2000;

    address public usdtWallet = 0x9d9167F5722F734d340733aa65964a81cBfA967D;
    address public owner = 0x9d9167F5722F734d340733aa65964a81cBfA967D;
    address private robot = 0x9d9167F5722F734d340733aa65964a81cBfA967D;

    address[] players;

    IERC20 USDT = IERC20(0x195E7EAFA28E4652F208F7Ffc5db6d43cca571d8);
    IERC20 IEG = IERC20(0x271E675D40757ad1E41373aE563da2cd4c9ac31C);

    mapping(address=>uint) usdtAmount;
    mapping(address=>saleLog[]) saleList;

    using SafeMath for uint;
    
    struct saleLog{
        uint usdt;
        uint amount;
        uint surplusAmount;
        uint32 startTime;
        uint32 preTime;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "onlyOwner err");
        _;
    }
    modifier onlyRobot(){
        require(msg.sender == robot, "only robot err");
        _;
    }

    function getInfo()view public returns(uint, uint, uint, uint, uint32){
        return(countAmount, usdtPrice, minUsdt, maxUsdt, startTime);
    }

    function preSale(address _address, uint _amount) public onlyRobot{
        require(block.timestamp > startTime, "startTime err");
        require(_amount>=minUsdt, "usdt lt 10 err");
        uint allUsdt = usdtAmount[_address].add(_amount);
        require(allUsdt<= maxUsdt, "usdt gt 6000 err");

        //USDT.transferFrom(msg.sender, usdtWallet, _amount);

        usdtAmount[_address] = allUsdt;
        uint tokenAmount = _amount.div(usdtPrice)*10**18;

        if(surplus<tokenAmount){
            tokenAmount = surplus;
        }

        surplus = surplus.sub(tokenAmount);
        uint toNow = tokenAmount.mul(arrival).div(base);
        uint surplusAmount = tokenAmount.sub(toNow);

        IEG.transfer(_address, toNow);
        uint32 nowTime = uint32(block.timestamp);
        saleList[_address].push(saleLog(_amount, surplusAmount, surplusAmount, nowTime, nowTime));
        if(!isPlayer(_address)){
            players.push(_address);
        }
    }

    function preSale(address[] memory _address, uint _amount) public onlyRobot{
        require(block.timestamp > startTime, "startTime err");
        require(_amount>=minUsdt, "usdt lt 10 err");

        uint _len = _address.length;

        for(uint i=0; i<_len; i++){
            uint allUsdt = usdtAmount[_address[i]].add(_amount);
            if(allUsdt<= maxUsdt){
                usdtAmount[_address[i]] = allUsdt;
                uint tokenAmount = _amount.div(usdtPrice)*10**18;
                if(surplus<tokenAmount){
                    tokenAmount = surplus;
                }
                if(surplus == 0){
                    break;
                }
                surplus = surplus.sub(tokenAmount);
                uint toNow = tokenAmount.mul(arrival).div(base);
                uint surplusAmount = tokenAmount.sub(toNow);
                IEG.transfer(_address[i], toNow);
                uint32 nowTime = uint32(block.timestamp);
                saleList[_address[i]].push(saleLog(_amount, surplusAmount, surplusAmount, nowTime, nowTime));
                if(!isPlayer(_address[i])){
                    players.push(_address[i]);
                }
            }
        }
    }

    function preSale(uint _amount)public {
        require(block.timestamp > startTime, "startTime err");
        require(_amount>=minUsdt, "usdt lt 10 err");
        uint allUsdt = usdtAmount[msg.sender].add(_amount);
        require(allUsdt<= maxUsdt, "usdt gt 6000 err");

        

        usdtAmount[msg.sender] = allUsdt;
        uint tokenAmount = _amount.div(usdtPrice)*10**18;

        require(tokenAmount<= surplus, "surplus lt err");
        surplus = surplus.sub(tokenAmount);
        USDT.transferFrom(msg.sender, usdtWallet, _amount);

        uint toNow = tokenAmount.mul(arrival).div(base);
        uint surplusAmount = tokenAmount.sub(toNow);

        IEG.transfer(msg.sender, toNow);
        uint32 nowTime = uint32(block.timestamp);
        saleList[msg.sender].push(saleLog(_amount, surplusAmount, surplusAmount, nowTime, nowTime));
        if(!isPlayer(msg.sender)){
            players.push(msg.sender);
        }
    }

    function releaseIEG()public{
        uint _len = saleList[msg.sender].length;
        uint _amount = 0;
        uint32 nowTime= uint32(block.timestamp);
        uint32 _month = 0;
        for(uint i=0; i<_len; i++){
            if(saleList[msg.sender][i].surplusAmount>0){
                _month = (nowTime - saleList[msg.sender][i].preTime)/t;
                if(_month>0){
                    uint tmpAmount = saleList[msg.sender][i].amount.mul(release).div(base).mul(_month);
                    if(tmpAmount>saleList[msg.sender][i].surplusAmount){
                        tmpAmount = saleList[msg.sender][i].surplusAmount;
                    }

                    if(tmpAmount > 0){
                        _amount = _amount.add(tmpAmount);
                        saleList[msg.sender][i].surplusAmount = saleList[msg.sender][i].surplusAmount.sub(tmpAmount);
                        saleList[msg.sender][i].preTime = saleList[msg.sender][i].preTime + _month * t;
                    }
                }
                
            }
        }

        IEG.transfer(msg.sender, _amount);
    }

    function getReleaseAmount(address _owner)public view returns(uint256){
        uint _len = saleList[_owner].length;
        uint _amount = 0;
        uint32 nowTime= uint32(block.timestamp);
        uint32 _month = 0;
        for(uint i=0; i<_len; i++){
            if(saleList[_owner][i].surplusAmount>0){
                _month = (nowTime - saleList[_owner][i].preTime)/t;
                if(_month>0){
                    uint tmpAmount = saleList[_owner][i].amount.mul(release).div(base).mul(_month);
                    if(tmpAmount>saleList[_owner][i].surplusAmount){
                        tmpAmount = saleList[_owner][i].surplusAmount;
                    }

                    _amount = _amount.add(tmpAmount);

                }
                
            }
        }

        return _amount;
    }

    function isPlayer(address _player)public view returns(bool){
        uint _len = players.length;
        for(uint i=0; i<_len; i++){
            if(players[i] == _player){
                return true;
            }
        }

        return false;
    }

    function getPlayerSaleInfo(address _player, uint _index)public view returns(uint, uint, uint, uint32, uint32){
        return(saleList[_player][_index].usdt, saleList[_player][_index].amount, saleList[_player][_index].surplusAmount, saleList[_player][_index].startTime, saleList[_player][_index].preTime);
    }
    function getPlayerSaleCount(address _player)public view returns(uint){
        return saleList[_player].length;
    }

    function getPlayers()public view returns(address[] memory){
        return players;
    }

    function changeOwner(address _address)public onlyOwner{
        owner = _address;
    }
    function setUsdtWallet(uint _usdtPrice)public onlyOwner{
        usdtPrice = _usdtPrice;
    }
    function setStartTime(uint32 _startTime)public onlyOwner{
        startTime = _startTime;
    }
    function setRobot(address _address)public onlyOwner{
        robot = _address;
    }
}