/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

//SPDX-License-Identifier: MIT License
pragma solidity >=0.8.4;
/**
 * Created by Solidity Works
 * thelambodan
 * Big Bo
 */
// 0x5EA925605C436Be2204e00f613a48D3369c21504
// 0x39E5f20C8dCA7df1E954350cf717d7A9aCc1F52D
//  affiliate addresses implemented
// 0xe6f1C4c08f7C7e5f9C20F82aC2b772c121D5DFD5
//  affiliate payout fixed and working
// 0x54FBE586Bf2328CA54284cE70C5bc71c702e9d4f
// fixed affiliate payout
// updated user order tracking
// 0xab6c79355A4F107F6F5bae4F926321Dd47024498
// changed function name no overloading sendOrderRef
// 0x32D877e1eB7849b74f25Da79D20221974299E943
// changed userOrders into mapping with tail counter
// 0x84de4779ca9B85b5De6DFa8Af583BEBe0af90f97
// list of each user's orders instead of event emitted
// 0x34B68E99e6c726f4ec6Ee5BEC1520A70FEbac686
// made index uint256 variable public
// 0x47F99AfB8B279aafE17616ebEc83b8a6841662Fe >> BSC TESTNET
// 0x6CEF3A89371b8D39A11C5c897D65dcC2726A5671 >> BSC MAINNET
// 0xDFb5Ed022d286570B37bD954fFDcc8d4c02026C7
contract AmazonOrder{
    //order struct for all order data
    struct order{
      uint256 refundTime;//time order can be refunded if not processed
      address sender;//order creator
      string key;////AES key encoded with RSA using platform public key
      address token;//token sent as payment busd/dai/usdc/usdt
      uint256 amount;//amount of token payment
      string info;//encrypted AES ciphertext of shipping info separated by semicolons
      string update;//"rejected / order ID"
      uint256 fee;//processing fee
      address affiliate;//affiliate
      uint256 saleCommission;//affliate fee
      uint256 rejectionFee;//affiliate gets paid on rejected orders
    }
    uint40 public index;//index of last order starting from 1
    mapping(uint40=>order) public orders;
    uint24 public processingTime=259200;//user can only cancel order after (3 days) this amount of time has relapsed
    address public bank;//where processing fee is sent
    uint256 public balance;//total fiat balance
    mapping(address=>uint256) public fees;//non-refundable processing fee default $5
    bool paused;//sending new orders is paused
    mapping(address=>bool) public admins;
    mapping(address=>bool) public approvedTokens;
    uint256 saleCommission = 1000000000000000000;//base affiliate fee $1 to start
    mapping(address=>uint256) public fee;//affiliate promo fee order confirmed
    mapping(address=>uint256) public rejectionFee;//affiliate promo fee order processed and rejected
    mapping(address=>mapping(uint40=>uint40)) public userOrders; //stores orders for each user
    mapping(address=>uint40) public userOrderHeads; // tail of linked list position
    constructor(){
        bank=msg.sender;
        admins[msg.sender]=true;
    }
    ////////////    functions
    function changeAdmin(address a) external {
        if(admins[msg.sender]==true){
            admins[a]=!admins[a];
        }
    }
    function changeToken(address a) external {
        if(admins[msg.sender]==true){
            approvedTokens[a]=!approvedTokens[a];
            fees[a]=5000000000000000000;
        }
    }
    function changeTime(uint24 t) external {
        if(admins[msg.sender]==true){
            processingTime=t;
        }
    }
    function changeBank(address a) external {
        if(admins[msg.sender]==true){
            bank=a;
        }
    }
    function changeFee(address a,uint256 f) external {
        require(admins[msg.sender]==true&&approvedTokens[a]==true);
        fees[a]=f;
    }
    function changeBalance(uint256 x) external {
        require(admins[msg.sender]==true);
        balance=x;
    }
    function stopStart()external{
        if(admins[msg.sender]==true){
            paused=!paused;
        }
    }
    function changeAffliate(address a,uint256 f,uint256 r)external{
      if(admins[msg.sender]==true){
        fee[a]=f;
        rejectionFee[a]=r;
      }
    }
    function initAffliate()external{
      fee[msg.sender]=saleCommission;
      rejectionFee[msg.sender]=0;
    }
    function sendOrder(address token, uint256 amount, string memory info, string memory key)external returns(bool){
        require(amount<balance,"fiat balance low");
        require(paused==false,"orders paused");
        require(approvedTokens[token]==true,"invalid token");
        require(index<uint40(index+1),"orders full");//uint40 max value
        require(amount>fees[token],"insufficient payment");
        (bool b,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,address(this),amount));
        require(b==true,"transferFrom");
        index++;
        orders[index].refundTime=block.timestamp+processingTime;
        orders[index].sender=msg.sender;
        orders[index].key=key;
        orders[index].token=token;
        orders[index].amount=amount;
        orders[index].info=info;
        orders[index].fee=fees[token];
        balance-=amount;
        userOrderHeads[msg.sender]++;
        userOrders[msg.sender][userOrderHeads[msg.sender]]=index;
        return true;
    }
    function sendOrderRef(address token, uint256 amount, string memory info, string memory key,address promoter)external returns(bool){
        require(amount<balance,"fiat balance low");
        require(paused==false,"orders paused");
        require(approvedTokens[token]==true,"invalid token");
        require(index<uint40(index+1),"orders full");//uint40 max value
        require(amount>fees[token],"insufficient payment");
        require(fee[promoter]!=0);
        (bool b,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,address(this),amount));
        require(b==true,"transferFrom");
        index++;
        orders[index].refundTime=block.timestamp+processingTime;
        orders[index].sender=msg.sender;
        orders[index].key=key;
        orders[index].token=token;
        orders[index].amount=amount;
        orders[index].info=info;
        orders[index].fee=fees[token];
        orders[index].affiliate=promoter;
        orders[index].saleCommission=fee[promoter];
        orders[index].rejectionFee=rejectionFee[promoter];
        balance-=amount;
        userOrderHeads[msg.sender]++;
        userOrders[msg.sender][userOrderHeads[msg.sender]]=index;
        return true;
    }
    function updateOrder(uint40 orderIndex,string memory update)external{
        //only admin can call function
        require(admins[msg.sender]==true);
        //can't update to blank string
        if(keccak256(bytes(update)) != keccak256(bytes(""))){
            //if order hasn't been updated yet then run the token payment
            if(keccak256(bytes(orders[orderIndex].update)) == keccak256(bytes(""))){
                //if order is rejected as update
                if(keccak256(bytes(update)) == keccak256(bytes("rejected"))){
                    //if the affiliate is initialized with nonzero rejection fee
                    if(orders[orderIndex].affiliate!=address(0)&&orders[orderIndex].rejectionFee!=0){
                        orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",orders[orderIndex].affiliate,orders[orderIndex].rejectionFee));
                        orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",bank,orders[orderIndex].fee-orders[orderIndex].rejectionFee));
                     }
                     //else pay platform the entire fee
                     else{
                        orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",bank,orders[orderIndex].fee));
                     }
                     orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",orders[orderIndex].sender,orders[orderIndex].amount-orders[orderIndex].fee));
                }
                //else order is confirmed and processed
                else{
                  //if order has valid affiliate then pay affiliate and bank
                  if(orders[orderIndex].affiliate!=address(0)&&orders[orderIndex].saleCommission!=0){
                    orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",orders[orderIndex].affiliate,orders[orderIndex].saleCommission));
                    orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",bank,orders[orderIndex].amount-orders[orderIndex].saleCommission));
                  }
                  //else pay the playform everything
                  else{
                    orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",bank,orders[orderIndex].amount));
                  }
                }
            }
            orders[orderIndex].update=update;
        }
    }
    function refund(uint40 orderIndex)external{
        require(orders[orderIndex].sender==msg.sender,"unauthorized");
        require(block.timestamp>orders[orderIndex].refundTime,"too soon");
        require(keccak256(bytes(orders[orderIndex].update)) == keccak256(bytes("")),"processed/refunded");
        orders[orderIndex].update="refund";
        orders[orderIndex].token.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,orders[orderIndex].amount));
    }
    receive()external payable{
        payable(bank).transfer(msg.value);
    }
}