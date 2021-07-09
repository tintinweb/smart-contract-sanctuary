/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

//SPDX-License-Identifier: MIT License
pragma solidity >=0.8.4;
/**
 * Created by Solidity Works
 * thelambodan
 * Big Bo
 * for use with Moon Battle @ MoonBattle.finance
 * 0x7aB57116a73086C6AD266FCa4DaA5d7dBd585BB0 << BSC Testnet
 * 0x839C76BBd03e02c629Cf4CaAD392c2FF8bdEA52A << BSC Mainnet
 */
contract vpn
{
    //event orderCreated(address indexed sender, uint256 index);
    //order can be cancelled at any time and refunded
    struct order{
        string email;//pgp-encrypted email ciphertext
        bool pending;//order pending refund or delivery
        address token;//token used as payment
        uint256 payment;//amount of payment
        address affiliate;//affiliate to pay upon delivery confimation instantly
        address sender;//order sender
    }
    mapping(address=>bool) admins;
    mapping(address=>uint256) public prices;//cost for each token used as payment
    uint256 public ethPrice;//cost for BNB as payment
    uint8 public affiliateReward;// % split affiliates get for each order confirmed
    mapping(uint256=>order) public orders;
    uint256 public index;
    mapping(address=>uint256[]) public userOrders;
    address bank;
    constructor(){
        admins[msg.sender]=true;
        bank =msg.sender;
    }
    
    function changeBank(address a)external {
        require(admins[msg.sender]==true);
        bank=a;
    }
    function adminAdd(address a)external {
        require(admins[msg.sender]==true);
        admins[a]=true;
    }
    function adminRevoke()external {
        //admins can only remove themselves
        admins[msg.sender]=false;
    }
    function changeReward(uint8 reward)external{
        //admin can change percentage within valid range
        require(admins[msg.sender]==true&&reward<=100);
        affiliateReward=reward;
    }
    function changePrice(address token,uint256 amount)external{
        //admin can change prices for each token or BNB as 0x address
        require(admins[msg.sender]==true);
        prices[token]=amount;
    }
    function confirmDelivered(uint256 i)external {
        //order must be unrefunded or previously claimed
        require(admins[msg.sender]==true&&orders[i].pending==true);
        orders[i].pending=false;
        uint256 payment = orders[i].payment;
        if(orders[i].token!=address(0)){
            if(orders[i].affiliate!=address(0)){
                orders[i].token.call(abi.encodeWithSignature("transfer(address,uint256)",orders[i].affiliate,orders[i].payment*affiliateReward/100));
                payment-=orders[i].payment*affiliateReward/100;
            }
            orders[i].token.call(abi.encodeWithSignature("transfer(address,uint256)",bank,payment));
        }
        else{
            if(orders[i].affiliate!=address(0)){
                payable(orders[i].affiliate).transfer(orders[i].payment*affiliateReward/100);
                payment-=orders[i].payment*affiliateReward/100;
            }
            payable(bank).transfer(payment);
        }
    }
    function buy(address token, string memory email)payable external{
        require(prices[token]!=0);
        //to pay in native coin ETH / BNB
        //require order will not overrite pending, so overflow cannot overwrite unprocessed orders
        require(orders[index].pending==true);
        if(msg.value>0){
            //require sufficient payment
            require(msg.value>=prices[address(0)]);
            orders[index]= order(email,true,address(0),msg.value,address(0),msg.sender);
        }
        else{
            (,bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)",address(this)));
            uint256 balance = bytesToUint(data);
            (bool b,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",address(msg.sender),address(this),prices[token]));
            require(b==true);
            (,data) = token.call(abi.encodeWithSignature("balanceOf(address)",address(this)));
            balance=bytesToUint(data)-balance;
            orders[index]= order(email,true,token,balance,address(0),msg.sender);
        }
        userOrders[msg.sender].push(index);
        //emit orderCreated(msg.sender,index);
        index++;
    }
    function affiliateBuy(address token, string memory email,address affiliate)payable public{
        require(prices[token]!=0);
        //to pay in native coin ETH / BNB
        //require order will not overrite pending, so overflow cannot overwrite unprocessed orders
        require(orders[index].pending==true);
        if(msg.value>0){
            //require sufficient payment
            require(msg.value>=prices[address(0)]);
            orders[index]= order(email,true,address(0),msg.value,affiliate,msg.sender);
        }
        else{
            (,bytes memory data) = token.call(abi.encodeWithSignature("balanceOf(address)",address(this)));
            uint256 balance = bytesToUint(data);
            (bool b,) = token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",address(msg.sender),address(this),prices[token]));
            require(b==true);
            (,data) = token.call(abi.encodeWithSignature("balanceOf(address)",address(this)));
            balance=bytesToUint(data)-balance;
            orders[index]= order(email,true,token,balance,affiliate,msg.sender);
        }
        userOrders[msg.sender].push(index);
        //emit orderCreated(msg.sender,index);
        index++;
    }
    function refund(uint256 i)external{
        //order must be unprocessed and requested by sender or admin
        require(orders[i].pending==true&&(address(msg.sender)==orders[i].sender||admins[msg.sender]==true));
        //separate function call prevents receive / fallback function from reverting and causing 
        //address(this).call(abi.encodeWithSignature("processOrder(uint256)",i));
        //processOrder(i);
        orders[i].pending=false;
        if(orders[i].token==address(0)){
            //pay BNB back
            payable(orders[i].sender).transfer(orders[i].payment);
        }
        else{
            //pay token back
            orders[i].token.call(abi.encodeWithSignature("transfer(address,uint256)",orders[i].sender,orders[i].payment));
        }
    }
    /*function processOrder(uint256 i)internal{
        //function to prevent double spending by (ensuring order[i].pending) == false even if reverting
        orders[i].pending=false;
    }*/
    function bytesToUint(bytes memory b) internal pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint256(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
    receive()external payable{
        payable(bank).transfer(msg.value);
    }
}