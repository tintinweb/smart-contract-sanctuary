/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// @whoismbm

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


contract Supply{


    struct Transit{
        uint bagNo;
        string location;
        string checkin;
        string checkout;
    }

    struct Commodity{
        uint bagNo;
        uint orderId;
        string commodityName;
        uint categoryId;
        string origin;
        uint quantity;
        string packingDate;
        
    }

    struct Order{
        string desination;
        string dateOfPurchase;
        uint orderId;
        uint[] bagNos;
    }

    uint bagcount;
    uint ordercount;
    address public owner;
    uint[] bags; 
    uint size_bags;
    
    mapping(uint => Commodity) commodities;
    mapping(uint => Order) orders;

    mapping(uint => uint[])  bagsCategory;
    mapping(uint => Transit[]) transitHistory;

    constructor() public{
        owner = msg.sender;
        bagcount = 0;
    }
    
    
    modifier onlyOwner() {
        require(owner == msg.sender ,"You are not authorized");
        _;
    }


    function createCommodity(string calldata _commodityName, uint _categoryId, string  calldata _origin, uint _quantity, string calldata _packingDate) onlyOwner() external {
        bagcount++;
        Transit memory _genesis;
        

         _genesis.bagNo = bagcount;
        _genesis.location = _origin;
        _genesis.checkin = 'Generation';
        _genesis.checkout = 'Generation';
        transitHistory[bagcount].push(_genesis);

       Commodity memory temp = Commodity(bagcount, 0, _commodityName, _categoryId, _origin, _quantity, _packingDate);
        commodities[bagcount] = temp;
        bagsCategory[_categoryId].push(bagcount); 
    }

    function createOrder(uint _qty0, uint _qty1, uint _qty2, uint _qty3, string calldata _destination, string calldata _dateOfPurchase) external returns(uint){
        
        require(bagsCategory[0].length >= _qty0, "Not enough supply of category 0 for placing the order");
        require(bagsCategory[1].length >= _qty1, "Not enough supply of category 1 for placing the order");
        require(bagsCategory[2].length >= _qty2, "Not enough supply of category 2 for placing the order");
        require(bagsCategory[3].length >= _qty3, "Not enough supply of category 3 for placing the order");

        ordercount++ ;
       
    
        for (uint i = 0; i < _qty0 ; i++){
            uint tmp = bagsCategory[0][bagsCategory[0].length - 1];
            commodities[tmp].orderId = ordercount;
            bagsCategory[0].pop();
            bags.push(tmp);
        }

        for (uint i = 0; i < _qty1 ; i++){
            uint tmp = bagsCategory[1][bagsCategory[1].length - 1];
            commodities[tmp].orderId = ordercount;
            bagsCategory[1].pop();
            bags.push(tmp);
        }
        
        for (uint i = 0; i < _qty2 ; i++){
            uint tmp = bagsCategory[2][bagsCategory[2].length - 1];
            commodities[tmp].orderId = ordercount;
            bagsCategory[2].pop();
            bags.push(tmp);
        }

        for (uint i = 0; i < _qty3 ; i++){
            uint tmp = bagsCategory[3][bagsCategory[3].length - 1];
            commodities[tmp].orderId = ordercount;
            bagsCategory[3].pop();
            bags.push(tmp);
        }

        Order memory tmpOrder = Order(_destination, _dateOfPurchase, ordercount, bags);
        orders[ordercount] = tmpOrder;
        
        size_bags = bags.length;
        
       uint tot = _qty0 + _qty1 + _qty2 + _qty3;
        
        for (uint i = 0; i< tot; i++){
           bags.pop();
        }

        return ordercount;

     }     

    
    function getCommodity(uint _bagno) public view returns(Commodity memory){
        Commodity memory TempCommodity = commodities[_bagno];
        return TempCommodity;
        

    }

    function getOrder(uint _orderno) public view returns(Order memory){
        Order memory tempOrder = orders[_orderno];
        return tempOrder;
    }

    function logTransit(uint _bagno, string calldata _location, string calldata _checkin, string calldata _checkout) external{
        Transit memory tmpTransit = Transit(_bagno,_location, _checkin, _checkout);
        transitHistory[_bagno].push(tmpTransit);

    }

    function getTransitHistory(uint _bagno) public  view returns(Transit[] memory){
      return transitHistory[_bagno];
    }

}