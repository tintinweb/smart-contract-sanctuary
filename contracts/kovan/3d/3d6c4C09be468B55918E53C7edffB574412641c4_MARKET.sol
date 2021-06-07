/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.8.0;

contract MARKET{
    using SafeMath for uint256;
    address public owner;
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
        uint256 paytogopriceperday;
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
    constructor (){
        owner = msg.sender;
    }
    
    modifier onlyowner(){
        require(msg.sender == owner , " UnAuthorized ");
        _;
    }
    modifier isavailable(uint256 item_id){
        require(users[msg.sender].userperoducts[item_id].subcriber || users[msg.sender].userperoducts[item_id].paytogo,"subscribe again to get access");
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
        user.userperoducts[item_id].paytogopriceperday = products[item_id].paytogopriceperday;
        user.userperoducts[item_id].remainingbalance = products[item_id].remainingbalance;
        user.userperoducts[item_id].item_id = products[item_id].item_id;
        user.userpurchases[user.purchasecount].item_id = item_id;
        user.userpurchases[user.purchasecount].depositedamount += msg.value ;
        user.userpurchases[user.purchasecount].usedamount += msg.value;
        user.userperoducts[item_id].purhcasehistoryid++;
        user.purchasecount++;
        return true;
    }
    function PurchasePayToGo(uint256 item_id) public payable returns(bool success)
    {
        User storage user = users[msg.sender];
        require(user.isregistered ,"Not Registered");
        require(products[item_id].isproduct,"enter the valid product id");
        require(products[item_id].paytogopriceperday >= msg.value , "Invalid amount");
        user.userperoducts[item_id].paytogocheckpoint = block.timestamp;
        user.userperoducts[item_id].duration += 1 days;
        user.userperoducts[item_id].paytogo = true;
        user.userperoducts[item_id].operatingsystem = products[item_id].operatingsystem;
        user.userperoducts[item_id].vcpus = products[item_id].vcpus;
        user.userperoducts[item_id].meromrycapicity = products[item_id].meromrycapicity;
        user.userperoducts[item_id].storagecapacity = products[item_id].storagecapacity;
        user.userperoducts[item_id].pricefor1month = products[item_id].pricefor1month;
        user.userperoducts[item_id].pricefor3month = products[item_id].pricefor3month;
        user.userperoducts[item_id].paytogopriceperday = products[item_id].paytogopriceperday;
        user.userperoducts[item_id].remainingbalance = msg.value;
        user.userperoducts[item_id].item_id = products[item_id].item_id;
        user.userpurchases[user.purchasecount].item_id = item_id;
        user.userpurchases[user.purchasecount].depositedamount += msg.value ;
        user.userpurchases[user.purchasecount].remainingamount = user.userperoducts[item_id].remainingbalance;
        user.userperoducts[item_id].purhcasehistoryid++;
        user.purchasecount++;
        return true;
    }
    function usepurchasedproduct(uint256 item_id) public isavailable(item_id) returns(string memory operatingsystem,
        uint256 vcpus,
        uint256 meromrycapicity,
        uint256 storagecapacity){
        User storage user = users[msg.sender];
        if(block.timestamp <= user.userperoducts[item_id].subcriptioncheckpoint+user.userperoducts[item_id].duration || block.timestamp <= user.userperoducts[item_id].paytogocheckpoint+user.userperoducts[item_id].duration)
        {
            if(user.userperoducts[item_id].paytogo){
                while(user.userperoducts[item_id].paytogocheckpoint<block.timestamp)
                {
                    user.userperoducts[item_id].subcriptioncheckpoint+= 1 days;
                    if(user.userperoducts[item_id].paytogopriceperday > user.userperoducts[item_id].remainingbalance)
                    {
                    user.userperoducts[item_id].remainingbalance = (user.userperoducts[item_id].remainingbalance).sub(user.userperoducts[item_id].paytogopriceperday);
                    user.userpurchases[user.userperoducts[item_id].purhcasehistoryid].usedamount += user.userperoducts[item_id].paytogopriceperday;
                    user.userpurchases[user.userperoducts[item_id].purhcasehistoryid].remainingamount -= user.userperoducts[item_id].paytogopriceperday;
                    }
                    else
                    {
                        user.userperoducts[item_id].paytogo = false;
                        break;
                    }
                }
                return(user.userperoducts[item_id].operatingsystem,
        user.userperoducts[item_id].vcpus,
        user.userperoducts[item_id].meromrycapicity,
        user.userperoducts[item_id].storagecapacity);
            }
            else if(user.userperoducts[item_id].subcriber){
                return(user.userperoducts[item_id].operatingsystem,
        user.userperoducts[item_id].vcpus,
        user.userperoducts[item_id].meromrycapicity,
        user.userperoducts[item_id].storagecapacity);
            }
        }
        else
        {
            user.userperoducts[item_id].subcriber = false;
            user.userperoducts[item_id].paytogo = false;
            user.userperoducts[item_id].duration = 0;
            
            revert("you need to purchase again");
        }
    }
    function GetCustomerPurchaseHistory(address _customer) public view returns(uint256 [] memory a,uint256 [] memory b,uint256 [] memory c,uint256 [] memory d)
    {
        User storage user = users[_customer];
        for(uint256 i ; i <=user.purchasecount;i++)
        {
            a[i] = user.userpurchases[i].item_id;
            b[i] = (user.userpurchases[i].remainingamount);
            c[i] = (user.userpurchases[i].usedamount);
            d[i] = (user.userpurchases[i].depositedamount);
            
        }
        return(a,b,c,d);
    }
    function AddProduct(string memory operatingsystem,
        uint256 vcpus,
        uint256 meromrycapicity,
        uint256 storagecapacity,
        uint256 pricefor1month,
        uint256 pricefor3month,
        uint256 paytogopriceperday,
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
        products[item_id].paytogopriceperday = paytogopriceperday;
        return true;
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