/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.4.17;

contract Student_Residence {
  uint public queue_benefits_count = 0;
  uint public queue_count = 0;
  
  address private owner = 0x86FC5459d90880857d69db2E2C3053b2A5fF4759;


  struct Node_pub {
    uint id;
    string first_name_less;
    string second_name;
    string third_name_less;
    
    bool benefits;
    
    bool documents;
    
    bool completed;
    uint room_number;
  }
  
  struct Node_private {
    uint id;
    string first_name;
    string second_name;
    string third_name;
    
    bool benefits;
    
    string documents;
    
    bool completed;
    uint room_number;
  }

  mapping(uint => Node_pub) public queue_pub;
  mapping(uint => Node_private) private queue_private;
  
  mapping(uint => Node_pub) public queue_benefits_pub;
  mapping(uint => Node_private) private queue_benefits_private;
  
  event QueueElementCreated(
    uint id,
    string first_name_less,
    string second_name,
    string third_name_less,
    bool benefits,
    bool documents,
    bool completed,
    uint room_number
  );

  event QueueElementCompleted(
    uint id,
    bool completed,
    uint room_number
  );

  constructor() public {
  }
  
  function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string) {
        bytes memory a = new bytes(end - begin + 1);
        for(uint i = 0; i <= end - begin; i++){
            a[i] = bytes(text)[i + begin - 1];
        }
        return string(a);    
    }

  function createNode(string memory first_name, string memory second_name, string memory third_name, bool benefits, string documents) public {
    if (benefits == true) {
        queue_benefits_private[queue_benefits_count] = Node_private(queue_benefits_count, first_name, second_name, third_name, benefits, documents, false, 0);
        queue_benefits_pub[queue_benefits_count] = Node_pub(queue_benefits_count, getSlice(1, 2, first_name), second_name, getSlice(1, 2, third_name), benefits, true, false, 0);
        
        emit QueueElementCreated(queue_benefits_count, getSlice(1, 2, first_name), second_name, getSlice(1, 2, third_name), benefits, true, false, 0);
        
        queue_benefits_count++;
        
    } else {
        queue_private[queue_count] = Node_private(queue_benefits_count, first_name, second_name, third_name, benefits, documents, false, 0);
        queue_pub[queue_count] = Node_pub(queue_benefits_count, getSlice(1, 2, first_name), second_name, getSlice(1, 2, third_name), benefits, true, false, 0);
        
        emit QueueElementCreated(queue_count, getSlice(1, 2, first_name), second_name, getSlice(1, 2, third_name), benefits, true, false, 0);

        queue_count++;
    }
    
  }
  
  function getStudentFromQueueBenefits(uint _id) public returns (uint, string, string, string, bool, string, bool) {
    require(msg.sender == owner, "Only admin can call this method");
        
    return (queue_benefits_private[_id].id, queue_benefits_private[_id].first_name, queue_benefits_private[_id].second_name, queue_benefits_private[_id].third_name, queue_benefits_private[_id].benefits, queue_benefits_private[_id].documents, queue_benefits_private[_id].completed);
  }
  
  function getStudentFromQueue(uint _id) public returns (uint, string, string, string, bool, string, bool) {
    require(msg.sender == owner, "Only admin can call this method");
        
    return (queue_private[_id].id, queue_private[_id].first_name, queue_private[_id].second_name, queue_private[_id].third_name, queue_private[_id].benefits, queue_private[_id].documents, queue_private[_id].completed);
  }

  function toggleCompletedNode(uint _id, uint room_number, uint queue) public {
    require(msg.sender == owner, "Only admin can call this method");
    
    if (queue == 1) {
        Node_pub memory _task = queue_benefits_pub[_id];
        Node_private memory _task_private = queue_benefits_private[_id];
        
        _task.completed = !_task.completed;
        _task.room_number = room_number;
        
        _task_private.completed = !_task_private.completed;
        _task_private.room_number = room_number;

        queue_benefits_pub[_id] = _task;
        queue_benefits_private[_id] = _task_private;
        
        emit QueueElementCompleted(_id, _task.completed, room_number);
    } else {
        Node_pub memory _task_ = queue_pub[_id];
        Node_private memory _task_private_ = queue_private[_id];
        
        _task_.completed = !_task_.completed;
        _task_.room_number = room_number;
        
        _task_private_.completed = !_task_private_.completed;
        _task_private_.room_number = room_number;

        queue_benefits_pub[_id] = _task_;
        queue_benefits_private[_id] = _task_private_;
        
        emit QueueElementCompleted(_id, _task_.completed, room_number);
    }
    }
    

}