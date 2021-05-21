/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_17 {
    /*
    uint lottoNum = 123456;
    mapping(uint => uint) myLotto;
    uint myLottoindex;
    
    uint winprice;
    uint public Lottobalance = 10000000;
    
    event checkLottoPrice(string a);
    
    function buyLotto(uint n) public returns(string memory) payable {
        
        require(n >= 100000);
        
        myLottoindex++;
        
        if(msg.value != 7500){
            emit checkLottoPrice("Invalid amount");
            return "Fail";
        }
        
        Lottobalance += msg.value;
        uint winNumCnt;
        if(lottoNum / 100000 % 100000 == n / 100000 % 100000){
            winNumCnt++;
            winprice += 50000;
        }
        if(lottoNum / 10000 % 10000 == n / 10000 % 10000){
            winNumCnt++;
            winprice += 30000;
        }
        if(lottoNum / 1000 % 1000 == n / 1000 % 1000){
            winNumCnt++;
            winprice += 10000;
        }
        if(lottoNum / 100 % 100 == n / 100 % 100){
            winNumCnt++;
            winprice += 5000;
        }
        if(lottoNum / 10 == n / 10){
            winNumCnt++;
            winprice += 2500;
        }
        
        myLotto[myLottoindex] = winNumCnt;
        winNumCnt = 0;
        return "Complete";
    }  
    
    function checkmyLotto(uint n) public view returns(uint) {
        return myLotto[n];
    }
    
    function get_LottoBalance() public payable {
        Lottobalance -= winprice;
        msg.sender += winprice;
        winprice = 0;
    }*/
}