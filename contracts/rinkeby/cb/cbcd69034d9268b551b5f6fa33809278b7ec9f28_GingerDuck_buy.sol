/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.4.25;
contract GingerDuck_buy {
    address public owner; //老闆
    uint public shoppingcart; //購物車金額

    struct Goods {
        string classification; // 品項
        string name; // 商品名稱
        uint count; // 商品數量
    }
    
    Goods[] public goods; // 商品清單

    // 初始化
    constructor() public {
        owner = msg.sender;
        shoppingcart = 0;
        goods.push(Goods({
            classification : "主菜",
            name : "薑母鴨",
            count : 0
        }));
        goods.push(Goods({
            classification : "主菜",
            name : "九尾雞",
            count : 0
        }));
        goods.push(Goods({
            classification : "主菜",
            name : "菜脯雞",
            count : 0
        }));
        goods.push(Goods({
            classification : "加點30",
            name : "麵線",
            count : 0
        }));
        goods.push(Goods({
            classification : "加點30",
            name : "鴨肉丸",
            count : 0
        }));
        goods.push(Goods({
            classification : "加點50",
            name : "高麗菜",
            count : 0
        }));
        goods.push(Goods({
            classification : "加點50",
            name : "A菜",
            count : 0
        }));
    }

    // 判斷是否是老闆？
    modifier isBoss() {
        require(msg.sender == owner, "權限不足");
        _;
    }    
    
    // 判斷字串，若 a, b 長度相同且雜湊值相同 => return "true"
    function hashCompare(string a, string b) internal returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(a) == keccak256(b);
    }
    
    // 取得合約餘額
    function get_ContractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // 取得 id 餘額
    function get_MemberBalance(address id) public view returns(uint) {
        return address(id).balance;
    }
    
    // 商品加入購物車
    function addCart(uint index) public {
        goods[index].count++;
    }
    
    // 結帳
    function checkout() public {
        for(uint i = 0; i < goods.length; i++) {
            if(hashCompare(goods[i].classification, "主菜")) {
                shoppingcart += goods[i].count * 0.1 ether;
            }else if(hashCompare(goods[i].classification, "加點30")) {
                shoppingcart += goods[i].count * 0.01 ether;
            }else if(hashCompare(goods[i].classification, "加點50")) {
                shoppingcart += goods[i].count * 0.02 ether;
            }else {
                shoppingcart = 0;
                break;
            }
            goods[i].count = 0;
        }
    }
    
    // 取得商品名稱
    function getGoodsName(uint index) view public returns(string memory) {
        return goods[index].name;
    }
    
    // 取得商品個數
    function getGoodsCount(uint index) view public returns(uint) {
        return goods[index].count;
    }
    
    // 删除 contract => 是否是老闆？ => 歸還 owner 合約剩餘金額
    function kill() public isBoss() {
        selfdestruct(owner);
    }
}