/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity >=0.8.0 <0.9.0;



/**
 * 基于以以太坊的双色球彩票
 */
contract DoubleColorBall {
    
    struct PersonNumberInfo{
        string number;
        uint256 totalAmount;
    }
    
    struct PersonInfo{
        address buyer;
        uint256 totalAmount;
        PersonNumberInfo [] numbers;
    }
    
    
    
    mapping(address => PersonInfo) private _ticketsPool;
    
    address [10] buyersAddress;
    
    int private currentBuyers;
    
    address owner;
    
    constructor() public {
        currentBuyers = 0;
        owner = msg.sender;
    }
    
    function buyTicket(string memory number, uint256 amount) public {
      PersonInfo storage p = _ticketsPool[msg.sender];
      
      if(p.totalAmount > 0) {
          
        PersonNumberInfo[] storage numbers = p.numbers;
        
        PersonNumberInfo storage pni;
        string memory tmpNumber;
        for(uint index = 0;index < numbers.length; index++) {
            pni = numbers[index];
            tmpNumber = pni.number;
            if(keccak256(bytes(number)) == keccak256(bytes(tmpNumber))) {
                pni.totalAmount += amount;
            }
        }
        p.totalAmount += amount;
        _ticketsPool[msg.sender] = p;
        currentBuyers ++;
      } else {
         p.totalAmount += amount;
         p.buyer = msg.sender;
         PersonNumberInfo memory pnis = PersonNumberInfo(number, amount);
         p.numbers[0] = pnis;
         _ticketsPool[msg.sender] = p;
      }
    }


    function getTicket() public view returns(address,uint256) {
        address addr = _ticketsPool[msg.sender].buyer;
        uint256 totalAmount = _ticketsPool[msg.sender].totalAmount;
        return(addr, totalAmount);
    }
    
    function getTicketByAddress(address buyerAddr) public view returns(address,uint256) {
        address addr = _ticketsPool[buyerAddr].buyer;
        uint256 totalAmount = _ticketsPool[addr].totalAmount;
        return (addr, totalAmount);
    }

}