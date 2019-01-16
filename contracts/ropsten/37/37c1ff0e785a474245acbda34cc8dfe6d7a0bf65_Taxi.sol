pragma solidity 0.4.25;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public manager;
  
  event OwnershipTransferred(address indexed previousManager, address indexed newManager);

  /**
   * @dev The Ownable constructor sets the original `manager` of the contract to the sender
   * account.
   */
   constructor() public payable {
    manager = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the manager.
   */
  modifier onlyManager() {
    require(msg.sender == manager);
    _;
  }


  /**
   * @dev Allows the current manager to transfer control of the contract to a newManager.
   * @param newManager The address to transfer ownership to.
   */
  function transferOwnership(address newManager) onlyManager public {
    require(newManager != address(0));
    emit OwnershipTransferred(manager, newManager);
    manager = newManager;
  }

}


contract Taxi is Ownable{
    using SafeMath for uint256;
   
    
    
    //state variables
    address public taxi_driver;
    address public car_dealer;
    uint public contract_balance=0;
    uint256 public fixed_expenses;
    uint256 public participation_fee=1;
    uint256 public count_participant=0;
 
    uint256 public count_car_propose=0;
    uint256 public total_participant=3;
    uint256 public count_approve_sell_proposal=0;
    uint256 public last_date_salary_driver=0;
    uint256 public last_date_expense=0;
    uint256 public last_date_dividend=0;
    uint256 public taxi_driver_salary=0;
   
    struct OwnedCar {  
        uint256   CarID;  
    }
    
    struct  ProposedCar {  
        uint256  CarID;
        uint256  price; 
        uint256  offer_valid_time;
    }
    
    struct ProposedPurchase{
        uint256 CarID;
        uint256 price;
        uint256 offer_valid_time;
        uint256 approval_state;
    }
   
    mapping(address=>uint256) participants;
    mapping(uint256=>ProposedCar) proposedcar;
    mapping(address=>uint256) approve_sell_proposal_participants;
    mapping(uint256=>ProposedPurchase) proposedpurchases;
    mapping(address => uint256) accountBalances;
    mapping (uint => address) accountIndex;
    

    constructor() public payable {
        manager = msg.sender;
       
    }
    
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return accountBalances[tokenOwner];
     }

    // my custom functions
    
    
    //join funciton
    function joinFunction() public payable returns(bool success){
        require(count_participant<=total_participant);
        require(msg.value>0);
        require(msg.value>=participation_fee);
        if(participants[msg.sender]==1){
            revert();
        }
        msg.sender.transfer(participation_fee);
        contract_balance+=msg.value;
        participants[msg.sender]+=1;
        accountBalances[msg.sender]=0;
        accountIndex[count_participant]=msg.sender;
        count_participant+=1;
        return true; 
        
    }
     
    
    // set car car_dealer
    function set_car_dealer(address _car_dealer) public onlyManager payable {
        car_dealer=_car_dealer;
    }
    
    //set car ProposedCar 
    //call by only car_dealer
    function car_propose(uint256 _car_id,uint256 _price,uint256 _offer_valid_time) public payable{
        require (msg.sender==car_dealer);
        proposedcar[count_car_propose].CarID=_car_id;
        proposedcar[count_car_propose].price=_price;
        proposedcar[count_car_propose].offer_valid_time=_offer_valid_time;
        count_car_propose+=1;
     
    }
    //get car propose
    function get_car_propse(uint256 _index) public constant returns(uint256 CarID,uint256 price,uint256 offer_valid_time) {
        return (proposedcar[_index].CarID,proposedcar[_index].price,proposedcar[_index].offer_valid_time);
    }
    
    
    //purchase car 
    function purchase_car(uint256 _index) public onlyManager payable {
        require(now <=proposedcar[_index].offer_valid_time);
        require(count_car_propose>=_index && count_car_propose>0);
        require(address(this).balance>=proposedcar[_index].price);
   
       car_dealer.transfer(proposedcar[_index].price);
    }
    
    // Purchase propose 
    //only car dealer call this
    function purchase_propose(uint256 _index) public payable   returns(bool status){
        require (msg.sender==car_dealer);
        require(now <=proposedcar[_index].offer_valid_time);
        require(count_car_propose>=_index && count_car_propose>0);
        proposedpurchases[0].CarID=proposedcar[_index].CarID;
        proposedpurchases[0].price=proposedcar[_index].price;
        proposedpurchases[0].offer_valid_time=proposedcar[_index].offer_valid_time;
        proposedpurchases[0].approval_state=0;
        return true;
    }
    
    //approve sell proposal
    function approve_sell_proposal() public payable{
         require(participants[msg.sender]==1);
         if(approve_sell_proposal_participants[msg.sender]==1){
             revert();
         }
         approve_sell_proposal_participants[msg.sender]=1;
         count_approve_sell_proposal+=1;
         proposedpurchases[0].approval_state+=1;
    }
    
    // only car dealer call this 
    function sell_car(uint256 _index) public payable returns(bool sell_status){
        
        require(msg.sender==car_dealer);
        require(count_participant.div(2)<count_approve_sell_proposal);
        require(now <=proposedcar[_index].offer_valid_time);
        require(msg.value>=proposedcar[_index].price);
        return true;
       
    }
    
    // set taxi_driver
    function set_taxi_driver(address _taxi_driver) public onlyManager payable {
        taxi_driver=_taxi_driver;
    }
   
    //get charge from pasangers
    function get_charge() public payable returns (bool status){
        return true;
    }
    
    // pay salary to taxi_driver
    //only manager after 6 month
    function pay_salary(uint256 _salary) public onlyManager payable returns(bool _salary_status) {
        require(address(this).balance>=_salary);
        if(last_date_salary_driver==0){
            last_date_salary_driver=now;
            taxi_driver_salary=taxi_driver_salary.add(_salary);
            
            return true;
        }
        require(now>last_date_salary_driver*30 days);
        last_date_salary_driver=now;
        taxi_driver_salary=taxi_driver_salary.add(_salary);
        return true;
        
    }
    
    // get salary for dirver 
    function get_salary() public payable returns(bool _salary_status){
        require(taxi_driver_salary>0);
         taxi_driver.transfer(taxi_driver_salary);
         taxi_driver_salary=0;
         return true;
    }
    
    // car expenses call by onlyManager
    function car_expense(uint256 _expense) public onlyManager payable returns(bool _expense_status) {
        require(address(this).balance>=_expense);
        if(last_date_expense==0){
            last_date_expense=now;
            car_dealer.transfer(_expense);
            return true;
        }
        require(now>last_date_expense*180 days);
        last_date_expense=now;
        car_dealer.transfer(_expense);
        return true;
    }
   
   
    // car pay  Dividend call by 
    function pay_dividended() public onlyManager payable returns(bool _expense_status) {
        require(address(this).balance>=0);
        uint256 per_balance=address(this).balance.div(count_participant);
        uint256 profit=per_balance.sub(3000000);
        if(last_date_dividend==0){
            last_date_dividend=now;
            for(uint i=0;i<count_participant;i++)
            {
              accountIndex[i].transfer(profit);
            } 
            return true;
        }
        require(now>last_date_dividend*180 days);
        last_date_dividend=now;
       
        for(uint j=0;j<count_participant;j++)
            {
              accountIndex[j].transfer(profit);
            } 
        return true;
    }
     
    // get Dividend 
     function get_dividend() public payable returns(bool _salary_status){
        require(accountBalances[msg.sender]>0);
         msg.sender.transfer(accountBalances[msg.sender]);
         accountBalances[msg.sender]=0;
         return true;
    }
    
    
    
    
    
}