// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./StringPlay.sol";
interface FromContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
interface ToContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Exchange  is Ownable,StringPlay{
    using SafeMath for uint256;

    address private fromCoinAddress;
    address private toCoinAddress;

    struct ExchangePair {
      uint id;
      address from;
      address to;
      uint rate;
      uint fee;
      uint createTime;
      uint updateTime;
      bool scale;
    }
    mapping(uint => ExchangePair) public signExchangePair;
    ExchangePair[] private ExchangePairList;
    uint ExchangePairId = 0;

    struct ExchangeRecord {
      uint id;
      address from;
      address to;
      address exchanger;
      uint rate;
      uint fee;
      uint fromAmount;
      uint toAmount;
      uint createTime;
    }
    mapping(uint => ExchangeRecord) public signExchangeRecord;
    ExchangeRecord[] private ExchangeRecordList;
    uint ExchangeId = 0;

    uint decimals = 10 ** 18;
    uint[] public tmpID;

    event AddPair(uint _id,address _from,address _to,uint _rate,uint _fee,bool _scale);
    event ExchangeFinash(address _exchanger,uint _amount,uint _pairid,uint _exchangeId);
    event Withdraw(address _to,uint _amount);
    modifier exitPair (uint _pairid) {
        bool exist = false;
        for(uint i = 0; i < ExchangePairList.length; i++){
          if(ExchangePairList[i].id == _pairid){
            exist = true;
          }
        }
        require(exist);
        _;
    }
    constructor () public {

    }
    function setExchangePair(uint _id,address _from,address _to,uint _rate,uint _fee,bool _scale) public onlyOwner{
       ExchangePairList[_id].from = _from;
       ExchangePairList[_id].to = _to;
       ExchangePairList[_id].rate = _rate;
       ExchangePairList[_id].fee = _fee;
       ExchangePairList[_id].updateTime = block.timestamp;
       ExchangePairList[_id].scale = _scale;
       signExchangePair[_id].from = _from;
       signExchangePair[_id].to = _to;
       signExchangePair[_id].rate = _rate;
       signExchangePair[_id].fee = _fee;
       signExchangePair[_id].updateTime = block.timestamp;
       signExchangePair[_id].scale = _scale;
    }
    function addExchangePair(address _from,address _to,uint _rate,uint _fee,bool _scale) public onlyOwner returns (uint){
       ExchangePair memory Pair = ExchangePair({
          id:ExchangePairId,
          from:_from,
          to:_to,
          rate:_rate,
          fee:_fee,
          createTime:block.timestamp,
          updateTime:block.timestamp,
          scale:_scale
        });
        ExchangePairList.push(Pair);
        signExchangePair[ExchangePairId] = Pair;
        emit AddPair(ExchangePairId,_from,_to,_rate,_fee,_scale);
        ExchangePairId = ExchangePairId.add(1);
        return ExchangePairId.sub(1);
    }
    function withdraw(address coin,uint _amount) public onlyOwner{
        FromContract formPlay = FromContract(coin);
        require(formPlay.balanceOf(address(this)) >= _amount);
        formPlay.transfer(msg.sender,_amount);
        emit Withdraw(msg.sender,_amount);
    }
    function FlashExchange(uint _amount,uint _pairid) public exitPair(_pairid) returns (uint){
        FromContract formPlay = FromContract(signExchangePair[_pairid].from);
        ToContract toPlay = ToContract(signExchangePair[_pairid].to);
        uint _toAmount;
        uint _feeAmount;
        uint _realAmount;
        if(signExchangePair[_pairid].scale){
            _feeAmount = _amount*signExchangePair[_pairid].fee/decimals;
        }else{
            _feeAmount = signExchangePair[_pairid].fee;
        }
        _realAmount = _amount - _feeAmount;
        _toAmount = _realAmount*signExchangePair[_pairid].rate/decimals;
        formPlay.transferFrom(msg.sender,address(this),_amount);
        toPlay.transfer(msg.sender,_toAmount);
        ExchangeRecord memory Record = ExchangeRecord({
          id:ExchangeId,
          from:signExchangePair[_pairid].from,
          to:signExchangePair[_pairid].to,
          fromAmount:_amount,
          toAmount:_toAmount,
          exchanger:msg.sender,
          rate:signExchangePair[_pairid].rate,
          fee:_feeAmount,
          createTime:block.timestamp
        });
        ExchangeRecordList.push(Record);
        signExchangeRecord[ExchangeId] = Record;
        emit ExchangeFinash(msg.sender,_amount,_pairid,ExchangeId);
        ExchangeId = ExchangeId.add(1);
        return ExchangeId.sub(1);
    }
    function pairDetail(uint _pairId) public view returns (address,address,uint,uint,bool){
      return (signExchangePair[_pairId].from,signExchangePair[_pairId].to,signExchangePair[_pairId].rate,signExchangePair[_pairId].fee,signExchangePair[_pairId].scale);
    }
    function getPairs() external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < ExchangePairList.length; i++){
            ids.push(ExchangePairList[i].id);
        }
        return ids;
    }

    function exchangeDetail(uint _Id) public view returns (address,address,address,uint,uint,uint,uint){
      return (signExchangeRecord[_Id].from,signExchangeRecord[_Id].to,signExchangeRecord[_Id].exchanger,signExchangeRecord[_Id].fee,signExchangeRecord[_Id].rate,signExchangeRecord[_Id].fromAmount,signExchangeRecord[_Id].toAmount);
    }
    function getExchangeRecord(address _owner) external returns (uint[]){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < ExchangeRecordList.length; i++){
          if(_owner == ExchangeRecordList[i].exchanger){
            ids.push(ExchangeRecordList[i].id);
          }
        }
        return ids;
    }
}