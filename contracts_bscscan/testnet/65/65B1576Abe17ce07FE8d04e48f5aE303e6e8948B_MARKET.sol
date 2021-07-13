/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract MARKET{
    using SafeMath for uint256;
    address public owner;
    uint256 public ownerbalance;
    struct Purachsed{
        uint256 item_id;
        uint256 remainingamount;
        uint256 usedamount;
        uint256 depositedamount;
    }
    struct Product{
        string operatingsystem;
        uint256 vcpus;
        uint256 meromrycapicity;
        uint256 storagecapacity;
        uint256 pricefor1month;
        uint256 pricefor3month;
        uint256 subcriptioncheckpoint;
        uint256 paytogocheckpoint;
        uint256 paytogopricepermin;
        uint256 remainingbalance;
        uint256 duration;
        uint256 item_id;
        uint256 purhcasehistoryid;
        bool subcriber;
        bool paytogo;
        bool isproduct;
    }
    struct User {
        uint256 totalpurchasedamount;
        uint256 regcheckpoint;
        bool isregistered;
        uint256 purchasecount;
        mapping(uint256 => Purachsed) userpurchases;
        mapping(uint256 => Product) userperoducts;
    }
    mapping (address => User) public users;
    mapping (uint256 => Product) internal products;
    uint256 [] internal idds;
    uint256 public productcount = 0;
    event PAYEVENT(string OS,uint256 CPU,uint256 MEM,uint256 STOR);
    constructor (address _owner){
        owner = _owner ;
    }
    
    modifier onlyowner(){
        require(msg.sender == owner , " UnAuthorized ");
        _;
    }
    function Register() public returns(bool success)
    {
        User storage user = users[msg.sender];
        require(!user.isregistered ,"Already Registered");
        user.isregistered = true;
        user.regcheckpoint = block.timestamp;
        return(true);
    }
    function Subscribe(uint256 item_id,uint256 duration) public payable returns(bool success)
    {
        User storage user = users[msg.sender];
        require(user.isregistered ,"Not Registered");
        require(products[item_id].isproduct,"enter the valid product id");
        require(duration == 1 || duration == 3,"invalid duration put either 1 or 3 as duration");
        
        if(duration == 1){
         require(products[item_id].pricefor1month == msg.value , "Invalid amount");
         user.userperoducts[item_id].duration += 30 days;
         
        }
        else if(duration == 3)
        {
            require(products[item_id].pricefor3month == msg.value , "Invalid amount");
            user.userperoducts[item_id].duration += 90 days;
        }
        user.totalpurchasedamount += msg.value;
        user.userperoducts[item_id].subcriptioncheckpoint = block.timestamp;
        user.userperoducts[item_id].subcriber = true;
        user.userperoducts[item_id].operatingsystem = products[item_id].operatingsystem;
        user.userperoducts[item_id].vcpus = products[item_id].vcpus;
        user.userperoducts[item_id].meromrycapicity = products[item_id].meromrycapicity;
        user.userperoducts[item_id].storagecapacity = products[item_id].storagecapacity;
        user.userperoducts[item_id].pricefor1month = products[item_id].pricefor1month;
        user.userperoducts[item_id].pricefor3month = products[item_id].pricefor3month;
        user.userperoducts[item_id].paytogopricepermin = products[item_id].paytogopricepermin;
        user.userperoducts[item_id].remainingbalance = products[item_id].remainingbalance;
        user.userperoducts[item_id].item_id = products[item_id].item_id;
        user.userpurchases[user.purchasecount].item_id = item_id;
        user.userpurchases[user.purchasecount].depositedamount += msg.value ;
        user.userpurchases[user.purchasecount].usedamount += msg.value;
        ownerbalance+=msg.value;
        user.userperoducts[item_id].purhcasehistoryid++;
        user.purchasecount++;
        return true;
    }
    function PurchasePayToGo(uint256 item_id) public payable returns(bool success)
    {
        User storage user = users[msg.sender];
        require(user.isregistered ,"Not Registered");
        require(products[item_id].isproduct,"enter the valid product id");
        require(products[item_id].paytogopricepermin <= msg.value , "Invalid amount");
        user.userperoducts[item_id].paytogocheckpoint = block.timestamp;
        user.userperoducts[item_id].paytogo = true;
        user.userperoducts[item_id].operatingsystem = products[item_id].operatingsystem;
        user.userperoducts[item_id].vcpus = products[item_id].vcpus;
        user.userperoducts[item_id].meromrycapicity = products[item_id].meromrycapicity;
        user.userperoducts[item_id].storagecapacity = products[item_id].storagecapacity;
        user.userperoducts[item_id].pricefor1month = products[item_id].pricefor1month;
        user.userperoducts[item_id].pricefor3month = products[item_id].pricefor3month;
        user.userperoducts[item_id].paytogopricepermin = products[item_id].paytogopricepermin;
        user.userperoducts[item_id].remainingbalance = msg.value.sub(products[item_id].paytogopricepermin);
        user.userperoducts[item_id].item_id = products[item_id].item_id;
        user.userpurchases[user.purchasecount].item_id = item_id;
        user.userpurchases[user.purchasecount].depositedamount += msg.value ;
        user.userpurchases[user.purchasecount].usedamount += products[item_id].paytogopricepermin ;
        user.userpurchases[user.purchasecount].remainingamount = user.userperoducts[item_id].remainingbalance;
        user.userperoducts[item_id].purhcasehistoryid++;
        user.purchasecount++;
        ownerbalance+=products[item_id].paytogopricepermin;
        return true;
    }
    function YOURPRODUCTPAYTOGO(uint256 item_id) public  returns(bool){
        User storage user = users[msg.sender];
        require(user.userperoducts[item_id].paytogo,"you are not a paytogo customer");
        require(calculations(item_id,msg.sender),"you need to pay again");
                
                emit PAYEVENT(user.userperoducts[item_id].operatingsystem,
                user.userperoducts[item_id].vcpus,
                user.userperoducts[item_id].meromrycapicity,
                user.userperoducts[item_id].storagecapacity);
                return true;
    }
    function calculations(uint256 item_id,address add) internal returns(bool){
        User storage user = users[add];
        uint256 time =  block.timestamp- user.userperoducts[item_id].paytogocheckpoint;
        user.userperoducts[item_id].paytogocheckpoint = block.timestamp;
        time = time.div(60);
        user.userperoducts[item_id].remainingbalance -= time.mul(user.userperoducts[item_id].paytogopricepermin);
        user.userpurchases[item_id].usedamount += time.mul(user.userperoducts[item_id].paytogopricepermin);
        user.userpurchases[item_id].remainingamount -= time.mul(user.userperoducts[item_id].paytogopricepermin);
        ownerbalance += time.mul(user.userperoducts[item_id].paytogopricepermin);
        if(user.userperoducts[item_id].remainingbalance > 0)
        {
        return(true);
        }
        else
        {
            return (false);
        }
    }
    function getbackamount(uint256 item_id) public returns (bool){
        User storage user = users[msg.sender];
        address payable add = payable(msg.sender);
        if(user.userperoducts[item_id].remainingbalance>0 && user.userperoducts[item_id].remainingbalance<=address(this).balance){
        add.transfer(user.userperoducts[item_id].remainingbalance);
        user.userperoducts[item_id].remainingbalance = 0;
        
        return true;
        }
         else{
             return false;
         }   
        }
    
    function YOURPRODUCTSUBCRIBED(uint256 item_id) public view returns(string memory operatingsystem,
        uint256 vcpus,
        uint256 meromrycapicity,
        uint256 storagecapacity){
        User storage user = users[msg.sender];
        require(user.userperoducts[item_id].subcriber,"you are not a subcriber");
        require(block.timestamp <= (user.userperoducts[item_id].subcriptioncheckpoint+user.userperoducts[item_id].duration),"subscribe again");
                return(user.userperoducts[item_id].operatingsystem,
                       user.userperoducts[item_id].vcpus,
                       user.userperoducts[item_id].meromrycapicity,
                       user.userperoducts[item_id].storagecapacity);
    }
    function GetCustomerPurchaseHistory(address _customer) public view returns(uint256 [10] memory id,uint256 [10] memory remain,uint256 [10] memory used,uint256 [10] memory deposit)
    {
        User storage user = users[_customer];
        for(uint256 i ; i <=user.purchasecount;i++)
        {
            id[i] = user.userpurchases[i].item_id;
            remain[i] = (user.userpurchases[i].remainingamount);
            used[i] = (user.userpurchases[i].usedamount);
            deposit[i] = (user.userpurchases[i].depositedamount);
            
        }
        return(id,remain,used,deposit);
    }
    function AddProduct(string memory operatingsystem,
        uint256 vcpus,
        uint256 meromrycapicity,
        uint256 storagecapacity,
        uint256 pricefor1month,
        uint256 pricefor3month,
        uint256 paytogopricepermin,
        uint256 item_id
    ) public onlyowner() returns(bool success)
    {
        products[item_id].isproduct = true;
        products[item_id].item_id = item_id;
        products[item_id].operatingsystem = operatingsystem;
        products[item_id].vcpus = vcpus;
        products[item_id].meromrycapicity = meromrycapicity;
        products[item_id].storagecapacity = storagecapacity;
        products[item_id].pricefor1month = pricefor1month;
        products[item_id].pricefor3month = pricefor3month;
        products[item_id].paytogopricepermin = paytogopricepermin;
         idds.push(item_id);
         productcount++;
        return true;
    }
    function getavailableproducts() public view returns(uint256[10]memory id,uint256[10]memory onemonth,uint256[10]memory threemonth,uint256[10]memory paytogo,string [10] memory name,uint256[10]memory vcpu,uint256[10]memory mem)
    {
        for(uint256 i ; i < productcount;i++)
        {
            id[i] = idds[i];
            onemonth[i] = products[id[i]].pricefor1month;
            threemonth[i] = products[id[i]].pricefor3month;
            paytogo[i] = products[id[i]].paytogopricepermin ;
            name[i] = products[id[i]].operatingsystem ;
            vcpu[i] = products[id[i]].vcpus ;
            mem[i] = products[id[i]].meromrycapicity ;
        }
    }
    function calaimfeeforowner(uint256 amount) public onlyowner returns (bool)
    {
        if(amount <= ownerbalance && amount <= address(this).balance)
        {
        payable(owner).transfer(amount);
        return true;
        }
        else
        {
            return false;
        }
    }
    function DetailsOfSpecificPurchase(address _customer,uint256 id) public view returns
    (uint256 item_id,
        uint256 remainingamount,
        uint256 usedamount,
        uint256 depositedamount)
    {
        return (users[_customer].userpurchases[id].item_id,users[_customer].userpurchases[id].remainingamount,users[_customer].userpurchases[id].usedamount,users[_customer].userpurchases[id].depositedamount);
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    
}