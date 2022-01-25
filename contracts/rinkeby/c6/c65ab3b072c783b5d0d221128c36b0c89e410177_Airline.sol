pragma solidity ^0.4.24;

contract Airline {

  address public owner;

  struct Customer {
      uint loyaltyPoints;
      uint totalFlights;
  }  

  struct Flight {
      string name;
      uint256 price;
  }

  uint etherPerPoint = 0.5 ether;

  Flight[] public flights;

  mapping(address => Customer) public customers;
  mapping(address => Flight[]) public customerFlights;
  mapping(address => uint) public customerTotalFlights;
  
  event FlightPurchased(address indexed customer, uint price, string flight);

  constructor() {
      owner = msg.sender;   
      flights.push(Flight('Tokio', 4 ether));
      flights.push(Flight('Germany', 3 ether));
      flights.push(Flight('Madrid', 3 ether));
  }   

  function buyFlight(uint flightIndex) public payable {
      Flight flight = flights[flightIndex];
      require(msg.value == flight.price);

      Customer storage customer = customers[msg.sender];
      customer.loyaltyPoints += 5;
      customer.totalFlights += 1;
      customerFlights[msg.sender].push(flight);
      customerTotalFlights[msg.sender] ++;

      FlightPurchased(msg.sender, flight.price, flight.name);
  }

  function totalFlights() public view returns (uint) {
      return flights.length;
  }

  function redeemLoyaltyPoints() public {
      Customer storage customer = customers[msg.sender];
      uint etherToRefund = etherPerPoint * customer.loyaltyPoints;
      msg.sender.transfer(etherToRefund);
      customer.loyaltyPoints = 0;
  }

  function getRefundableEther() public view returns (uint) {
      return etherPerPoint * customers[msg.sender].loyaltyPoints;
  }

  function getAirlineBalance() public isOwner view returns (uint) {
      address airlineAddress = this;
      return airlineAddress.balance;
  }

  modifier isOwner() {
      require(msg.sender == owner);
      _;
  }
}