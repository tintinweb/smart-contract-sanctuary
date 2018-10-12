pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
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


interface LVECoin {
    function transfer(address _to, uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns (uint256);
}


/**
 * @title LVEPay
 */
contract LVEPay {

    using SafeMath for uint256;
    // token contract
    LVECoin private tokenContr;

    event WithdrawalEther(address indexed _to, uint256 _amount);
    event Pay(address indexed _from, address indexed _to, uint256 _amount);

    // PayOrder
    struct PayOrder {
        // payOrder id
        string payID;
        // payOrder token amount
        uint256 payAmt;
    }

    // receive token wallet
    address public walletAddr;
    // payOrder mapping
    // mapping(string => PayOrder) public payOrderMap;
    mapping(string => PayOrder) payOrderMap;
    // payOrder list
    string[] public payOrders;
   

    constructor(address _tokenAddr, address _walletAddr) public{
        require(_tokenAddr != address(0), "");
        require(_walletAddr != address(0), "");
        walletAddr = _walletAddr;
        tokenContr = LVECoin(_tokenAddr);
    }


    // is correct payOrder format
    modifier isCORRFormat(string _arg) {
        require(bytes(_arg).length > 0, "");
        _;
    }

    // TODO: 忘了加進去
    // 排除重複payOrder
    modifier excludeRepeatOrder(string _payOrderKey){
        PayOrder memory payOrder;
        payOrder = payOrderMap[_payOrderKey];
        require(bytes(_payOrderKey).length > 0, "");
        require(bytes(payOrder.payID).length == 0, "");
        _;
    }

    // have enough token amount
    modifier enoughTokenAmt(uint256 _payAmt){
        uint256 tokenAmt = tokenContr.balanceOf(msg.sender);
        if (tokenAmt >= _payAmt) {
            _;
        }
    }


    // LVEPay
    function lvePay(string _payOrderKey, string _payID, uint256 _payAmt) public enoughTokenAmt(_payAmt) isCORRFormat(_payOrderKey) isCORRFormat(_payID) returns(bool){
        require(msg.sender != address(0), "");
        require(_payAmt > 0, "");

        // PayOrder memory payOrder;
        // payOrder.payID = _payID;
        // payOrder.payAmt = _payAmt;
        // payOrderMap[_payOrderKey] = payOrder;

        // payOrders.push(_payOrderKey);
        // paid product and transfer token
        tokenContr.transfer(walletAddr, _payAmt);

        emit Pay(msg.sender, walletAddr, _payAmt);
        return true;
    }

   
    // returns all payOrder numbers
    function countPayOrder() public view returns(uint256 _orderNums){
        return payOrders.length;
    }

    // get index payOrder key
    function getPayOrderKey(uint256 _index) public view returns(string _payOrderKey) {
        return payOrders[_index];
    }

    // get paid infomation
    function getPaidInfo(string _payOrderKey) public view isCORRFormat(_payOrderKey) returns(string _payID, uint256 _payAmt){
        PayOrder memory payOrder;
        payOrder = payOrderMap[_payOrderKey];
        return (payOrder.payID, payOrder.payAmt);
    }

    // if send ether then send ether to owner
    function() public payable {
        require(msg.value > 0, "");
        walletAddr.transfer(msg.value);
        emit WithdrawalEther(walletAddr, msg.value);
    }

}