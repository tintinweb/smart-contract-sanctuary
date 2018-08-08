pragma solidity ^0.4.24;

/**
* 基础合约
*/
contract Basic {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  /**
  * 判断是否为合约拥有者，否则抛出异常
  */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
  * 替换合约的拥有者
  */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
* 业务合约
*/
contract Moses is Basic{

  //参与竞猜HASH上链事件
  event Attend(uint32 id,string attentHash);
  //竞猜结果上链事件
  event PublishResult(uint32 id,string result);

  /**
  * 预测事件结构
  */
  struct MoseEvent {
    uint32 id;
    string attendHash;
    string result;
  }

  //存储每个预测事件的参与信息
  mapping (uint32 => MoseEvent) internal moseEvents;

  /**
  * 预测参与信息上链
  */
  function attend(uint32 _id,string _attendHash) public onlyOwner returns (bool) {
    moseEvents[_id] = MoseEvent({id:_id,attendHash:_attendHash,result: ""});
    emit Attend(_id, _attendHash);
    return true;
  }

  /**
  * 预测结果上链
  */
  function publishResult(uint32 _id,string _result) public onlyOwner returns (bool) {
    moseEvents[_id].result = _result;
    emit PublishResult(_id, _result);
    return true;
  }

  /**
  * 通过竞猜事件ID查询事件参与HASH
  */
  function showMoseEvent(uint32 _id) public view returns (uint32,string,string) {
    return (moseEvents[_id].id, moseEvents[_id].attendHash,moseEvents[_id].result);
  }


}