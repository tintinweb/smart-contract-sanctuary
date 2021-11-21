/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

pragma solidity ^0.8.9;      

contract TaskManager {
    Task[] private _tasks;          
    mapping(address => uint256[]) private _employee;
    mapping(address => uint256[]) private _manager;

    enum State {created, inProgress, done, checking, confirmed, canceled}

    struct Task {
    address manager;
    address employee;
    uint256 id;
    string name;
    string description;
    uint256 price;     
    uint256 deadline;
    State state;
    }  

    modifier onlyManager(uint256 id) { 
        require(_tasks[id].manager == msg.sender,
            "Only manager is allowed to call function");  
        _; 
    } 

    modifier onlyEmployee(uint256 id) { 
        require(_tasks[id].employee == msg.sender,
            "Only employee is allowed to call function"); 
        _; 
    }                                  

    modifier onlyEmployeeOrManager(address empl, address manag) { 
        require(empl == msg.sender || manag == msg.sender,
            "Only manager or employee is allowed to call function"); 
        _; 
    }  

    modifier instate(uint256 id, State expected_state) { 
        require(_tasks[id].state == expected_state,
            "Unappropriate state of task for function"); 
        _; 
    } 

    modifier checkDeadline(uint256 id) { 
        require(_tasks[id].deadline >= block.timestamp,
            "Deadline for this task is over");
        _; 
    } 

    function createTask(
        address manager,
        address employee, 
        string memory name,
        string memory description,
        uint256 price,
        uint256 deadline
        ) 
        public
        onlyEmployeeOrManager(employee,manager)
    {  
        require(deadline > block.timestamp);
        
        uint256 len = _tasks.length;
        _tasks.push(Task(manager,employee,len,name,description,price,deadline,State.created));   
        _employee[employee].push(len);
        _manager[manager].push(len);
    } 

    function setInProgress(uint256 id) public onlyEmployee(id) checkDeadline(id) 
        instate(id,State.created) 
    {
        _tasks[id].state = State.inProgress;
    }

    function submitTask(uint256 id) public onlyEmployee(id) checkDeadline(id) 
        instate(id,State.inProgress) 
    {
        _tasks[id].state = State.done;
    }
    
    function checkTask(uint256 id) public onlyManager(id) checkDeadline(id)
        instate(id, State.done) 
    {  
        _tasks[id].state = State.checking;
    } 
    
    function confirmTask(uint256 id) public onlyManager(id) checkDeadline(id)
        instate(id, State.checking) 
    {  
        _tasks[id].state = State.confirmed;
    } 
    
    function cancelTask(uint256 id) public 
        onlyEmployeeOrManager(_tasks[id].employee, _tasks[id].manager) checkDeadline(id)
    { 
        require(_tasks[id].state != State.confirmed,"Task is already confirmed");
        _tasks[id].state = State.canceled;
    }   

    
    function getTasks() public view returns (Task[] memory, Task[] memory) {        
        uint256[] memory numbers1 = _employee[msg.sender];
        uint256[] memory numbers2 = _manager[msg.sender];
        uint256 len1 = numbers1.length;
        uint256 len2 = numbers2.length;

        Task[] memory t1 = new Task[](len1);
        Task[] memory t2 = new Task[](len2);
        
        for(uint256 i=0;i<len1;i++) {
            Task memory struc1 = _tasks[numbers1[i]];
            t1[i]=Task(struc1.manager,struc1.employee,struc1.id,struc1.name,struc1.description,struc1.price,struc1.deadline,struc1.state);
        }    
        
        for(uint256 i=0;i<len2;i++) {
            Task memory struc2 = _tasks[numbers2[i]];
            t2[i]=Task(struc2.manager,struc2.employee,struc2.id,struc2.name,struc2.description,struc2.price,struc2.deadline,struc2.state);
        }    
          
        return (t1,t2);
    }  

    function getTask(uint256 id) public view returns (Task memory) {
        return _tasks[id];
    } 
}