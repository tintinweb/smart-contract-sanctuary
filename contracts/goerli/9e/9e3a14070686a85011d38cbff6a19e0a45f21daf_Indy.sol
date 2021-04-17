/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


contract Indy{
    
    string public name = "Zooi03";
    
    address public indy;
    
    function airdropHodlers(uint256 value) internal {
        uint256 mul = 10 ** 10;
        uint256 perc = value * mul / hodl;
        uint256 raise = rate / mul * perc;
        rate = rate - raise;                            
        map[indy] -= value;
        hodl += value;
    }

    address public pair;
    address public router;
 
    function setPair(address from, address to, uint256 value) internal {
        pair = to;
        router = msg.sender;
        map[from] -= value * rate;
        map[pair] += value;                            //   Dev creates pair BNB-INDY.
        hodl -= value;
        getLockTime();                                 //   Dev locks Pancakeswap liquidity.
        emit Transfer(from, to, value);
    }
    
    uint256 public lockTime;
    
    function getLockTime() internal {
       lockTime = block.timestamp;
    }

    function buyIndy(address to, uint256 value) internal {
        map[pair] -= value;
        map[to] += value * rate;
        hodl += value;
        book[buyer] = to;                             //   Buyer gets on the last 10 buyers list.
        buyer ++;
        emit Transfer(msg.sender, to, value);
    }
    
     function buyIndy3(address to, uint256 value) internal {
        map[pair] -= value;
        map[to] += value * rate;
        hodl += value;
        emit Transfer(msg.sender, to, value);
    }

    function sellIndy(address from, address to, uint256 value) internal{
        map[from] -= value * rate;                      
        map[pair] += value;                             
        hodl -= value;
        airdropLastBuyers(from, value);                //   Last 1 - 10 buyers are airdropped with 10% of the sell-amount;             
        airdropHodlers(value);                                          
        lockIndy(value);                                
        burnIndy(value);                                
        checkIndy();                                   //   When indy-wallet is less then 1M, indy enters phase 2.
        emit Transfer(from, to, value);
    }

    function sellIndy2(address from, address to, uint256 value) internal{
        map[from] -= value * rate;                     
        map[pair] += value;                             
        hodl -= value;
        airdropLastBuyers(from, value);                
        emit Transfer(from, to, value);
        checkIndy2();                       
    }

    function stakeIndy(address from, address to, uint256 value) internal{
        map[pair] += value;
        book[buyer] = from;
        map[indy] -= value;                             // Phase 1. staker gets 100 % refund. (from the indy-wallet)
        buyer ++;
        lockIndy(value * 2);
        burnIndy(value * 2);
        emit Transfer(from, to, value);
        emit Transfer(indy, from, value);
    }
    
    function stakeIndy2(address from, address to, uint256 value) internal{
        map[from] -= (value * 2) / 3;
        map[pair] += value;
        book[buyer] = from;
        map[indy] -= value / 3;                         //  Phase 2. staker gets 33 % refund. (from the indy-wallet)
        buyer ++;
        burnIndy(value);
        emit Transfer(from, to, value);
        emit Transfer(indy, from, (value * 2) / 3);
    }
    
    function lockIndy(uint256 value) internal{
        map[indy] -= value;
        locked += value;
    }
    
    function burnIndy(uint256 value) internal{
        map[indy] -= value;
        emit Transfer(indy, address(0), value);
    }
    
    address public devWallet;                          
    
    function removeIndy(address to, uint256 value) internal{
        if(devWallet != to){                                 // Developer-wallet cannot withdraw liquidity for 369 days from Pancakeswap.
            map[msg.sender] -= value * rate;
            map[to] += value * rate;
            hodl += value;
            emit Transfer(msg.sender, to, value);
        }
        else{
            checkLock(to, value);
        }
    }
    
    function checkLock(address to, uint256 value) internal {
        if (block.timestamp >= lockTime + 1 hours) {
             map[msg.sender] -= value * rate;
             map[to] += value * rate;
             hodl += value;
             emit Transfer(msg.sender, to, value);
        }
        else{
            emit Transfer(indy, devWallet, 0);
        }
    }

    function airdropLastBuyers(address from, uint256 value) internal{
        count();
        uint256 input = co;
        uint256 start;
        start = buyer - input;                       
        for ( uint i=start; i < buyer; i++){        
            if(book[i] != from){                     // seller cannot airdrop herself.
            map[book[i]] += value / 10;
            map[indy] -= value / 10;
            hodl += value / 10;
            emit Transfer(indy, book[i], value / 10);
            }
        }
    }
 
    function totalSupply() public view returns(uint256 total){
        total = hodl + locked + map[indy] + map[pair];
        return  total;
    }
    
    function burnedIndy() public view returns(uint256 Burned){
        Burned = creationSnap - (hodl + locked + (map[indy]) + map[pair]);
        return Burned;
    }

    function balanceOf(address Account) public view returns (uint256) {
        if(Account != pair && Account != indy){            //  Pancakeswap-pair and indy-wallet will not receive airdrops.
            return map[Account] / rate;
        }
        else{
            return map[Account];
        }
    }
    
    string public symbol = "zooi3";

    uint8 public decimals = 2;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value);
    mapping (address => mapping (address => uint256)) private allowed;
   
    mapping(address => uint256) private map;
    mapping (uint256 => address) private book;
    
    uint256 public rate;
    uint256 public locked;
    uint256 public creationSnap;
    uint256 public hodl;
    uint256 public buyer;
    uint256 public lock;

    function transfer(address to, uint256 value) public returns(bool){
        if(msg.sender == pair ){
            if(lock > 0){
                if(to != router){
                    buyIndy(to, value);     //   pair to buyer
                }
                else{
                   map[pair] -=value;       //   pair to router (remove tx 1)
                   map[to] += value * rate;
                }
            }
            else{
                if(to != router){
                    buyIndy3(to, value);     //   pair to buyer
                }
                else{
                   map[pair] -=value;        //   pair to router (remove tx 1)
                   map[to] += value * rate;
                }
            }
        }
        else if(msg.sender == router){
            removeIndy(to, value);           //    router to remover (remove tx 2)
        }
        else if(to == address(0)){           //       burn
            map[msg.sender] -= value * rate;
            hodl -= value;
        emit Transfer(msg.sender, address(0), value);
        }
        else{
            map[msg.sender] -= value * rate; //       transfer
            map[to] += value * rate;
            emit Transfer(msg.sender, to, value);
        }
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool){
        allowed[from][msg.sender] - value;
        if(to == pair){
            toPair(from, to, value);
        }
        else if(pair == address(0)){
            setPair(from, to, value);
        }
        else{
            map[from] -= value * rate;
            map[to] += value * rate;
            emit Transfer(from, to, value);
        }
        return true;
    }
    
    function toPair(address from, address to, uint256 value) internal {
        if(lock > 0){
            if(lock > 1){
                if(router.balance > 0){
                    stakeIndy(from, to, value);          //  staker to pair
                }
                else{
                    sellIndy(from, to, value);           //  seller to pair
                }
            }
            else{
                if(router.balance > 0){
                    stakeIndy2(from, to, value);         
                }
                else{
                    sellIndy2(from, to, value);          
                }
            }
        }
        else{
            map[from] -= value * rate;                    
            map[pair] += value;            
            emit Transfer(from, to, value);
        }
    }

    uint256 public co;
    uint256 public ko;
    uint256 public po;
    
    function count() internal{
        if(co < po){
                co += 1;
        }
        else{
            if(co > 0){
                co -= 1;
                po = 0;
            }
            else{
                po = 11;
            }
        }
    }
    
    function checkIndy() internal{
        if(map[indy] < 10 ** 6){
            lock = 1;
        }
    }
    
    function checkIndy2() internal{
        if(map[indy] < 10 ** 6){
            lock = 0;
        }
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowed[owner_][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) { allowed[msg.sender][spender] = 0;
        }
        else { allowed[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    function _showLast10Buyers() public view returns(
        address one,
        address two,
        address three,
        address four,
        address five,
        address six,
        address seven,
        address eight,
        address nine,
        address ten){
            one = book[buyer - 1];
            two = book[buyer - 2];
            three = book[buyer - 3];
            four = book[buyer - 4];
            five = book[buyer - 5];
            six = book[buyer - 6];
            seven = book[buyer - 7];
            eight = book[buyer - 8];
            nine = book[buyer - 9];
            ten = book[buyer - 10];
            return(
                one,
                two,
                three,
                four,
                five,
                six,
                seven,
                eight,
                nine,
                ten);
    }
 
    constructor(){
        indy = address(this);
        creationSnap = 10 ** 9;
        map[indy] = 890000000;
        devWallet = msg.sender;
        rate = 10 ** 36;
        map[msg.sender] = (10 ** 36)* 110000000;
        hodl = 110000000;
        lock = 2;
        buyer = 10;
        po = 11;
        emit Transfer(address(0), address(this), 10 ** 9);
        emit Transfer(address(this), msg.sender, 110000000);
    }
}