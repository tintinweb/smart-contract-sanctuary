// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
interface FromContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function decimals() external pure returns (uint8);
    function approve(address spender, uint value) external returns (bool);
}
interface ToContract{
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function decimals() external pure returns (uint8);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}
contract Exchange  is Ownable,ReentrancyGuard{
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
      bool status;
    }
    mapping(uint => ExchangePair) public signExchangePair;
    ExchangePair[] private ExchangePairList;
    uint ExchangePairId = 1;

    uint ExchangeId = 0;

    uint decimals = 10 ** 18;
    uint[] public tmpID;

    event AddPair(uint _id,address _from,address _to,uint _rate,uint _fee,bool _scale);
    event ExchangeFinash(address _exchanger,uint _amount,uint _pairid,uint _exchangeId,uint _rate,uint _feeAmount,uint _toAmount);
    event Withdraw(address _to,uint _amount);
    event OnOff(uint _id,bool _status);
    modifier exitPair (uint _pairid) {
        bool exist = false;
        if(signExchangePair[_pairid].status){
            exist = true;
        }
        require(exist,'non-exit pair');
        _;
    }
    function setExchangePair(uint _id,address _from,address _to,uint _rate,uint _fee,bool _scale) public onlyOwner{
       ExchangePairList[_id-1].from = _from;
       ExchangePairList[_id-1].to = _to;
       ExchangePairList[_id-1].rate = _rate;
       ExchangePairList[_id-1].fee = _fee;
       ExchangePairList[_id-1].updateTime = block.timestamp;
       ExchangePairList[_id-1].scale = _scale;
       signExchangePair[_id].from = _from;
       signExchangePair[_id].to = _to;
       signExchangePair[_id].rate = _rate;
       signExchangePair[_id].fee = _fee;
       signExchangePair[_id].updateTime = block.timestamp;
       signExchangePair[_id].scale = _scale;
    }
    function PairOnOff(uint _id,bool _status) public onlyOwner{
       signExchangePair[_id].status = _status;
       emit OnOff(_id,_status);
    }
    function addExchangePair(address _from,address _to,uint _rate,uint _fee,bool _scale,bool _status) public onlyOwner returns (uint){
       ExchangePair memory Pair = ExchangePair({
          id:ExchangePairId,
          from:_from,
          to:_to,
          rate:_rate,
          fee:_fee,
          createTime:block.timestamp,
          updateTime:block.timestamp,
          scale:_scale,
          status:_status
        });
        ExchangePairList.push(Pair);
        signExchangePair[ExchangePairId] = Pair;
        emit AddPair(ExchangePairId,_from,_to,_rate,_fee,_scale);
        ExchangePairId = ExchangePairId.add(1);
        return ExchangePairId.sub(1);
    }
    function withdraw(address receiver,address coin,uint _amount) public onlyOwner{
        _otherTransfer(receiver,coin,_amount);
        emit Withdraw(receiver,_amount);
    }
    function _otherTransfer(address receiver,address coin,uint _amount) private {
        FromContract formPlay = FromContract(coin);
        require(formPlay.balanceOf(address(this)) >= _amount,'Sorry, your credit is running low');
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(receiver);
        formPlay.transfer(receiver,_amount);
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(receiver);
        require(oldFromBalance == newFromBalance + _amount,'tranfer fail');
        require(newSenderFromBalance == oldSenderFromBalance + _amount,'tranfer fail');
    }
    function checkToken(address _address, uint amount) public returns (bool){
        FromContract formPlay = FromContract(_address);
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(msg.sender);
        formPlay.transferFrom(msg.sender,address(this), amount);
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(newFromBalance == oldFromBalance + amount,'tranfer fail');
        require(oldSenderFromBalance == newSenderFromBalance + amount,'tranfer fail');
        _otherTransfer(msg.sender,_address,amount);
        return true;
    }
    function exchangeComput(uint _amount,uint _pairid) public view returns (uint) {
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
        uint fromDecimals = 10 ** uint256(formPlay.decimals());
        uint toDecimals = 10 ** uint256(toPlay.decimals());
        return _toAmount*toDecimals/fromDecimals;
    }
    function _computFee(uint _amount,uint _pairid) private view returns(uint){
        uint _feeAmount;
        if(signExchangePair[_pairid].scale){
            _feeAmount = _amount*signExchangePair[_pairid].fee/decimals;
        }else{
            _feeAmount = signExchangePair[_pairid].fee;
        }
        return _feeAmount;
    }
    function _computExchange(uint _amount,uint _pairid) private view returns(uint){
        FromContract formPlay = FromContract(signExchangePair[_pairid].from);
        ToContract toPlay = ToContract(signExchangePair[_pairid].to);
        uint _toAmount;
        uint _realAmount;
        uint _feeAmount = _computFee(_amount,_pairid);
        _realAmount = _amount - _feeAmount;
        _toAmount = _realAmount*signExchangePair[_pairid].rate/decimals;
        uint fromDecimals = 10 ** uint256(formPlay.decimals());
        uint toDecimals = 10 ** uint256(toPlay.decimals());
        return _toAmount*toDecimals/fromDecimals;
    }
    function _FlashExchangeIn(uint _amount,uint _pairid) private {
        FromContract formPlay = FromContract(signExchangePair[_pairid].from);
        uint oldFromBalance = formPlay.balanceOf(address(this));
        uint oldSenderFromBalance = formPlay.balanceOf(msg.sender);
        formPlay.transferFrom(msg.sender,address(this),_amount);
        uint newFromBalance = formPlay.balanceOf(address(this));
        uint newSenderFromBalance = formPlay.balanceOf(msg.sender);
        require(newFromBalance == oldFromBalance + _amount,'exchange fail');
        require(oldSenderFromBalance == newSenderFromBalance + _amount,'exchange fail');
    }
    function _FlashExchangeOut(uint _amount,uint _pairid) private {
        ToContract toPlay = ToContract(signExchangePair[_pairid].to);
        uint _toAmount = _computExchange(_amount,_pairid);
        uint oldToBalance = toPlay.balanceOf(address(this));
        uint oldSenderToBalance = toPlay.balanceOf(msg.sender);
        toPlay.transfer(msg.sender,_toAmount);
        uint newSenderToBalance = toPlay.balanceOf(msg.sender);
        uint newToBalance = toPlay.balanceOf(address(this));
        require(oldToBalance == newToBalance + _toAmount,'exchange fail');
        require(newSenderToBalance == oldSenderToBalance + _toAmount,'exchange fail');
    }
    function FlashExchange(uint _amount,uint _pairid) public nonReentrant exitPair(_pairid){
        uint _toAmount = _computExchange(_amount,_pairid);
        _FlashExchangeIn(_amount,_pairid);
        _FlashExchangeOut(_amount,_pairid);
        emit ExchangeFinash(msg.sender,_amount,_pairid,ExchangeId,signExchangePair[_pairid].rate,_computFee(_amount,_pairid),_toAmount);
        ExchangeId.add(1);
    }
    function pairDetail(uint _pairId) public view returns (address,address,uint,uint,bool,bool){
      return (signExchangePair[_pairId].from,signExchangePair[_pairId].to,signExchangePair[_pairId].rate,signExchangePair[_pairId].fee,signExchangePair[_pairId].scale,signExchangePair[_pairId].status);
    }
    function getPairs() external returns (uint[] memory){
        uint[] storage ids = tmpID;
        for(uint i = 0; i < ExchangePairList.length; i++){
            ids.push(ExchangePairList[i].id);
        }
        return ids;
    }
}