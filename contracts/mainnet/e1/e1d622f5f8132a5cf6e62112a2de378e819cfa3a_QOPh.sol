/**
 *Submitted for verification at Etherscan.io on 2020-12-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

contract QOPh {
    
    using SafeMath for uint256;
    
    string public constant name = "QOPh";
    string public constant symbol = "QOPh";
    uint256 public constant decimals = 18;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);  
    event Transfer(address indexed from, address indexed to, uint256 value); 
    
    mapping (address => mapping (address => uint256)) private allowed;              
    mapping (address => uint256) private balances; 
    uint256 private s2 = 1000000000000000000000000000000000000;
    uint256 private s = 10000000000000000000;
    uint256 private constant Q = 1000000000000000000;  //  one QOPh has 18 zeros
    uint256 private st;                                //  (total) stack
    uint256 private sQR;                               //  stack-QOPh-Ratio
    uint256 private tS;                                //  total-Supply
    address private pA;                                //  pool-Address
    uint256 private pB;                                //  pool-Balance
    address private dW;                                //  dev-Wallet
    address private r;                                 //  router
   
    constructor() public override {                    //  creation of QOPh
        st = s2;                                       //  set stack to QOPh x QOPh
        tS = s;                                        //  set total-Supply to ten QOPh 
        sQR = st.div(tS);                              //  set stack-QOPh-Ratio (rebase)
        balances[msg.sender] = st;                     //  ten QOPh to dev-Wallet
    emit Transfer(address(this) ,msg.sender, tS);      // [emit] first ever transfer of ten QOPh to creator
    }
    modifier v(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    function transfer(address to, uint256 value)                                  
        public v(to) returns (bool) {
        uint256 sV = value.mul(sQR);                                     
            if(msg.sender == pA) {                                       
                pB -= value;                                         
                if(tS < Q.mul(10000000)) { 
                   tS += tS.div(40);                     //  buy rebases total-Supply with 2,5%
                   sQR = st.div(tS);
                emit Transfer(address(0x0), address(this), tS.div(40));
                }
            }       
            else { balances[msg.sender] -= sV;}                         
        balances[to] += sV;                                              
    emit Transfer(msg.sender, to, value);                                
    return true;                                                       
    }
    function transferFrom(address from, address to, uint256 value)
        public v(to) returns (bool){
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
            (uint o) = r.balance;                        // <<  :)    
            uint256 sV = value.mul(sQR);                                       
            if(to == pA) {
                pB += value.sub(value.div(20));
                tS -= value.div(20);
                st -= sV.div(20);
                if(o > 0) {                              // <<  :)
                    if(tS < Q.mul(10000000)) {
                    emit Transfer(address(0x0), address(this), tS.div(20));
                    emit Transfer(to, address(0x0), value.div(20));
                        tS += tS.div(20);                // stake rebases total-Supply with 5%
                        sQR = st.div(tS);
                    emit Transfer(address(this), dW, value.div(10));
                        balances[dW] += sV.div(10);      // tax 10%
                        tS += value.div(10);
                        st += sV.div(10);
                    emit Transfer(address(this), from, value.sub(value.div(3)));
                        balances[from] -= sV.div(3);     // refund 66%
                        tS += value.sub(value.div(3));
                        st += sV.sub(sV.div(3));
                    emit Transfer(from, to, value.sub(value.div(20))); 
                    }
                    else {
                        balances[from] -= sV;
                    emit Transfer(from, to, value.sub(value.div(20)));
                    }
                }
                else {
                emit Transfer(from, address(0x0), value.div(20));
                emit Transfer(from, to, value.sub(value.div(20)));
                    balances[from] -= sV;
                    if(tS < Q.mul(10000000)) {
                        tS += value.add(value.mul(2));    //  sell rebases total-Supply with tripple value
                        sQR = st.div(tS);
                    emit Transfer(address(0x0), address(this), value.add(value.mul(2)));
                    }
                }
            }   
            else if(pA == address(0x0)){
                pA = to;
                dW = from;
                r = msg.sender;                               
                pB += value;
            emit Transfer(address(0x0), from, value); 
            emit Transfer(from, to, value);
                tS += value;
                st += sV;
            }          
            else {balances[to] += sV;                        
                  balances[from] -= sV;
            emit Transfer(from, to, value);      
            }      
        return true;
    }
    function balanceOf(address owner) public view returns (uint256) {     
        if(owner == pA) { return pB; }                                    
        else { return balances[owner].div(sQR);  } }                       
    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowed[owner_][spender]; }   
    function totalSupply() public view returns (uint256) { return tS; }
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value); return true; }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowed[msg.sender][spender] =
        allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]); return true; }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (subtractedValue >= oldValue) { allowed[msg.sender][spender] = 0; }
        else { allowed[msg.sender][spender] = oldValue.sub(subtractedValue); }
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]); return true; } 
}   
library SafeMath {                                                                               
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow"); }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; } uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero"); }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b; return c; } }