/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

pragma solidity 0.8.9;  

contract Escrow {  
    Deal[] private deals;           // по id сделки

    // для удобства просмотра с 2-ух сторон 
    mapping(address => uint256[]) private custDeals;  // сделки по адресу клиента
    mapping(address => uint256[]) private exDeals;    // сделки по адресу исполнителя

    enum State {created, inProgress, done, confirm, cancel}

    struct Deal {
        address executor;
        address customer;
        string name;
        string description;
        uint256 deposit;  
        uint256 deadline;
        State currentState;  
    }                                      
      
    modifier instate(uint256 id, State expected_state) { 
        require(deals[id].currentState == expected_state,
            "Unappropriate state of service for function"); 
        _; 
    } 

    modifier onlyCustomer(uint256 id) { 
        require(deals[id].customer == msg.sender,
            "Only customer is allowed to call function");  
        _; 
    } 

    modifier onlyExecutor(uint256 id) { 
        require(deals[id].executor == msg.sender,
            "Only customer is allowed to call function"); 
        _; 
    } 

    modifier checkDeadline(uint256 id) { 
        require(deals[id].deadline >= block.timestamp,
            "Deadline for this service is over");
        _; 
    } 

    function createDeal(
        address payable executor,
        address payable customer, 
        string memory name,
        string memory description,
        uint256 deposit,
        uint256 deadline
        ) 
        public payable
    {  
        require(deposit == msg.value,"Inappropriate amount of funds");
        require(deadline > block.timestamp);

        deals.push(Deal(executor,customer,name,description,deposit,deadline,State.created));
        custDeals[customer].push(deals.length - 1);   // id сделки
        exDeals[executor].push(deals.length - 1);     
    } 

    function setInProgress(uint256 id) public onlyExecutor(id) checkDeadline(id) 
        instate(id,State.created) 
    {
        deals[id].currentState = State.inProgress;
    }

    function submitDeal(uint256 id) public onlyExecutor(id) checkDeadline(id) 
        instate(id,State.inProgress) 
    {
        deals[id].currentState = State.done;
    }
    
    // перевод с контракта на адрес исполнителя
    function confirmDeal(uint256 id) public onlyCustomer(id) checkDeadline(id)
        instate(id, State.done) 
    {  
        deals[id].currentState = State.confirm;
        (bool success,) = payable(deals[id].executor).call{value: deals[id].deposit}(""); 

        require(success, "Failed to transfer Ether to executor");
    } 
    
    // возврат покупателю с контракта (суммы, равной deposit)
    function cancelDeal(uint256 id) public onlyExecutor(id) onlyCustomer(id) checkDeadline(id)
        instate(id,State.inProgress)
    { 
        deals[id].currentState = State.cancel;
        (bool success, ) = payable(deals[id].customer).call{value: deals[id].deposit}("");  

        require(success, "Failed to transfer Ether to customer");
    }   

    
    function getDeals() public view returns (Deal[] memory, Deal[] memory) {         // от  custDeals и exDeals 
        uint256[] memory numbers1 = custDeals[msg.sender];
        uint256[] memory numbers2 = exDeals[msg.sender];
        
        Deal[] memory dl1 = new Deal[](numbers1.length);
        Deal[] memory dl2 = new Deal[](numbers2.length);
        
        for(uint256 i=0;i<numbers1.length;i++) {
          Deal memory struc1 = deals[numbers1[i]];
          dl1[i]=Deal(struc1.executor,struc1.customer,struc1.name,struc1.description,struc1.deposit,struc1.deadline,struc1.currentState);
        }    
        
        for(uint256 i=0;i<numbers2.length;i++) {
          Deal memory struc2 = deals[numbers2[i]];
          dl2[i]=Deal(struc2.executor,struc2.customer,struc2.name,struc2.description,struc2.deposit,struc2.deadline,struc2.currentState);
        }    
        
        return (dl1,dl2);
    }  

    function getDeal(uint256 id) public view returns (Deal memory) {
        return deals[id];
    }  

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }  
}