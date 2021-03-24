/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

pragma solidity ^0.4.24;

contract TraceSource {

      address public owner;
      address public sender;

      constructor(address _sender) public {
        owner = msg.sender;
        if(_sender!= address(0))
            sender = _sender;
        else
            sender = msg.sender;
      }

      modifier onlyOwner() {
        require(msg.sender == owner);
        _;
      }

      modifier onlySender() {
        require(msg.sender == owner||msg.sender == sender);
        _;
      }


      function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
          owner = newOwner;
        }
      }

      function transferSendership(address newSender) public onlyOwner {
        if (newSender != address(0)) {
          sender = newSender;
        }
      }

    struct TraceData{
        uint256 dataId;
        address send_address;
        string content;
    }
    mapping (uint256=>TraceData) traceDatabase;


    //发送溯源申请信息
    function sendTraceData(uint256 _dataId,string _content) public onlySender{
        if(msg.sender==owner){
            traceDatabase[_dataId] = TraceData(
                _dataId,
                msg.sender,
                _content
            );
        }
        else if(msg.sender==sender){
            TraceData memory _traceData = traceDatabase[_dataId];
            if(_traceData.dataId==0){
                traceDatabase[_dataId] = TraceData(
                    _dataId,
                    msg.sender,
                    _content
                );
            }
            else{
                revert();
            }
        }

    }

    function getTraceData(uint256 dataId) view public returns(address send_address,string content){
        TraceData memory _traceData = traceDatabase[dataId];
        return(_traceData.send_address,_traceData.content);
    }

}