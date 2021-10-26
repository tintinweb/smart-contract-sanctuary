/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity 0.8.7;      

contract Escrow {  
    enum State {created, inProgress, done, cancel}

    Deal[] private deals;           // по id сделки

    // для удобства просмотра с 2-ух сторон 
    mapping(address => uint256[]) private custDeals;  // сделки по адресу клиента
    mapping(address => uint256[]) private exDeals;    // сделки по адресу исполнителя

    struct Deal {
        address executor;
        address customer;
        string name;
        string description;
        uint256 sum;         // оставшаяся сумма
        uint256 deposited;   // внесенная сумма
        uint256 deadline;
        State currentState;  // enum
    }                                      
      
    modifier instate(uint256 id, State expected_state) { 
        require(deals[id].currentState == expected_state,
            "Unappropriate state of service for function"); 
        _; 
    } 

    modifier instateInProcess(uint256 id) { 
        require(deals[id].currentState == State.created || deals[id].currentState == State.inProgress,
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

    function addDeal(
        address payable _executor,
        address payable _customer, 
        string memory _name,
        string memory _description,
        uint256 _sum,
        uint256 _deadline
        ) 
        public
    {  
        deals.push(Deal(_executor,_customer,_name,_description,_sum,0,_deadline,State.created));
        custDeals[_customer].push(deals.length - 1);   // id сделки
        exDeals[_executor].push(deals.length - 1);     
    } 
    
    // перевод на контракт
    function pay(uint256 id) onlyCustomer(id) checkDeadline(id) instateInProcess(id) public payable {        
        if (deals[id].currentState == State.created)
            setState(id, State.inProgress);
        deals[id].deposited += msg.value;
    } 
    
    // перевод с контракта на адрес исполнителя
    // изменение состояния, суммы
    function deliverToExecutor(uint256 id) onlyCustomer(id) checkDeadline(id)
        instate(id, State.inProgress) 
        public
    {  
        uint256 toSend = deals[id].deposited;
        if (deals[id].sum < toSend) 
            toSend = deals[id].sum;
        deals[id].deposited -= toSend;
        deals[id].sum -= toSend;
        if (deals[id].sum == 0) 
            setState(id,State.done);
        (bool success,) = payable(deals[id].executor).call{value: toSend}("");  
            require(success, "Failed to transfer Ether to executor");
    } 
    
    // возврат покупателю с контракта (суммы, равной его deposited)
    function returnPayment(uint256 id) onlyExecutor(id) checkDeadline(id)
        instate(id,State.inProgress)
        public
    { 
        setState(id,State.cancel);
        uint256 toSend = deals[id].deposited;
        deals[id].deposited = 0;
        (bool success, ) = payable(deals[id].customer).call{value: toSend}("");  
            require(success, "Failed to transfer Ether to customer");
    }   

    
    function getCustDeals() public view returns (uint256[] memory) {
        return custDeals[msg.sender];
    }  

    function getExDeals() public view returns (uint256[] memory) {
        return exDeals[msg.sender];
    }  

    function getDeal(uint256 id) public view returns (Deal memory) {
        return deals[id];
    }  

    function getNameDesc(uint256 id) public view returns (string memory, string memory) {
        return (deals[id].name, deals[id].description);
    }

    function getRemainingSum(uint256 id) public view returns (uint256) {
        return deals[id].sum;
    }

    function getDeposited(uint256 id) public view returns (uint256) {
        return deals[id].deposited;
    }

    function getDeadline(uint256 id) public view returns (uint256) {
        return deals[id].deadline;
    }

    function getState(uint256 id) public view returns (State) {
        return deals[id].currentState;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }  


    function setState(uint256 id, State expected_state) private {
        deals[id].currentState = expected_state;  
    }
}