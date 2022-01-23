/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
 
 
 
pragma solidity ^0.8.0;



interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**

    * @dev Multiplies two unsigned integers, reverts on overflow.

    */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the

        // benefit is lost if 'b' is also tested.

        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    /**

    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.

    */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0

        require(b > 0);

        uint256 c = a / b;

        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**

    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).

    */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    /**

    * @dev Adds two unsigned integers, reverts on overflow.

    */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    /**

    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),

    * reverts when dividing by zero.

    */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**

     * @dev Initializes the contract setting the deployer as the initial owner.

     */

    constructor()  {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    /**

     * @dev Returns the address of the current owner.

     */

    function owner() public view returns (address) {
        return _owner;
    }

    /**

     * @dev Throws if called by any account other than the owner.

     */

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }

    /**

     * @dev Transfers ownership of the contract to a new account (`newOwner`).

     * Can only be called by the current owner.

     */

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}



        contract CardGame is Ownable {


        mapping(address => mapping(uint256 => uint256)) public pools;   
        mapping(uint256=>uint256) public poolamounts;
        
        mapping(address=>uint256) public rewarded;

        address[] public usersarray1;
        address[] public usersarray2;
        address[] public usersarray3;
        address[] public usersarray4;
        address[] public usersarray5;
        address[] public usersarray6;
        address[] public usersarray7;
        address[] public usersarray8;
        address[] public usersarray9;
        address[] public usersarray10;

        mapping(address => mapping(uint256 => address)) public userexit;
        mapping(address => mapping(uint256 => uint256)) public userexit1;
        IBEP20 public Token;
        
        constructor(IBEP20 _Token)  
    {
        Token = _Token;
    }

        uint256 public startTime;
        bool public Start;


            function start() external onlyOwner
            {
             startTime = block.timestamp; 
             Start = true;
            }



        function bet(uint256 pool, uint256 _amount) external {

        require(block.timestamp < startTime+8 minutes ,"time end" );
        require(Start == true ,"try again" );
        
      
        pools[msg.sender][pool]+=_amount;
        poolamounts[pool]+=_amount;
        
        

        Token.transferFrom(msg.sender,address(this),_amount);

        if(pool == 1 && userexit1[userexit[msg.sender][1]][startTime] != pool)
        {
            usersarray1.push(msg.sender);
            userexit[msg.sender][1]=msg.sender;
            userexit1[userexit[msg.sender][1]][startTime]  = pool;
        }
        else if(pool == 2 && userexit1[userexit[msg.sender][2]][startTime] != pool)
        {
            usersarray2.push(msg.sender);
            userexit[msg.sender][2]=msg.sender;
            userexit1[userexit[msg.sender][2]][startTime]  = pool;
        }
        else if(pool == 3 && userexit1[userexit[msg.sender][3]][startTime]  != pool)
        {
            usersarray3.push(msg.sender);
            userexit[msg.sender][3]=msg.sender;
            userexit1[userexit[msg.sender][3]][startTime]  = pool;
        }
        else if(pool == 4 && userexit1[userexit[msg.sender][4]][startTime] != pool)
        {
            usersarray4.push(msg.sender);
            userexit[msg.sender][4]=msg.sender;
            userexit1[userexit[msg.sender][4]][startTime]  = pool;
        }
        else if(pool == 5 && userexit1[userexit[msg.sender][5]][startTime] != pool)
        {
            usersarray5.push(msg.sender);
            userexit[msg.sender][5]=msg.sender;
            userexit1[userexit[msg.sender][5]][startTime]  = pool;
        }
        else if(pool == 6 && userexit1[userexit[msg.sender][6]][startTime] != pool)
        {
            usersarray6.push(msg.sender);
            userexit[msg.sender][6]=msg.sender;
            userexit1[userexit[msg.sender][6]][startTime]  = pool;
        }
        else if(pool == 7 && userexit1[userexit[msg.sender][7]][startTime] != pool)
        {
            usersarray7.push(msg.sender);
            userexit[msg.sender][7]=msg.sender;
            userexit1[userexit[msg.sender][7]][startTime]  = pool;
        }
        else if(pool == 8 && userexit1[userexit[msg.sender][8]][startTime] != pool)
        {
            usersarray8.push(msg.sender);
            userexit[msg.sender][8]=msg.sender;
            userexit1[userexit[msg.sender][8]][startTime]  = pool;
        }
        else if(pool == 9 && userexit1[userexit[msg.sender][9]][startTime]  != pool)
        {
            usersarray9.push(msg.sender);
            userexit[msg.sender][9]=msg.sender;
            userexit1[userexit[msg.sender][9]][startTime]  = pool;
        }
        else if(pool == 10 && userexit1[userexit[msg.sender][10]][startTime] != pool)
        {
            usersarray10.push(msg.sender);
            userexit[msg.sender][10]=msg.sender;
            userexit1[userexit[msg.sender][10]][startTime]  = pool;
        }
        }
        function checkwinnerpool() public view returns(uint256){

                uint256 min ;
                uint256 pool;

             if(poolamounts[1]  > 0)
             {
                min = poolamounts[1] ;
                pool = 1;
             }
             else if(poolamounts[2]  > 0)
             {
                   min = poolamounts[2] ;
                 pool = 2;
             }
             else if(poolamounts[3]  > 0)
             {
                   min = poolamounts[3] ;
                 pool = 3;
             }
             else if(poolamounts[4]  > 0)
             {
                   min = poolamounts[4] ;
                   pool = 4;
             }
             else if(poolamounts[5]  > 0)
             {
                   min = poolamounts[5] ;
                   pool = 5;
             }
             else if(poolamounts[6]  > 0)
             {
                   min = poolamounts[6] ;
                   pool = 6;
             }
             else if(poolamounts[7]  > 0)
             {
                   min = poolamounts[7] ;
                   pool = 7;
             }
             else if(poolamounts[8]  > 0)
             {
                   min = poolamounts[8] ;
                   pool = 8;
             }
             else if(poolamounts[9]  > 0)
             {
                   min = poolamounts[9] ;
                   pool = 9;
             }
             else if(poolamounts[10]  > 0)
             {
                   min = poolamounts[10] ;
                   pool = 10;
             }
                         

        if(min > poolamounts[2] && poolamounts[2] != 0 ){
        min = poolamounts[2]; 
        pool = 2;   
         } 

        if(min > poolamounts[3] && poolamounts[3] != 0 ){
        min = poolamounts[3]; 
        pool = 3;   
         }  

         if(min > poolamounts[4] && poolamounts[4] != 0 ){
        min = poolamounts[4]; 
        pool = 4;   
         }
         if(min  > poolamounts[5] && poolamounts[5] != 0 ){
        min = poolamounts[5]; 
        pool = 5;   
         }  
         if(min > poolamounts[6] && poolamounts[6] != 0 ){
        min = poolamounts[6]; 
        pool = 6;   
         }  
         if(min > poolamounts[7] && poolamounts[7] != 0 ){
        min = poolamounts[7]; 
        pool = 7;   
         }     
         if(min > poolamounts[8] && poolamounts[8] != 0 ){
        min = poolamounts[8]; 
        pool = 8;   
         }  
         if(min > poolamounts[9] && poolamounts[9] != 0 ){
        min = poolamounts[9]; 
        pool = 9;   
         }  
         if(min > poolamounts[10] && poolamounts[10] != 0 ){
        min = poolamounts[10]; 
        pool = 10;   
         }  
        return pool; 

         }


         
        function Calculate_reward() external onlyOwner{

        require(block.timestamp > startTime+10 minutes ,"time end" );

         uint256 winnerpool= checkwinnerpool();
  

        if(winnerpool == 1){
         for(uint256 i = 0; i < usersarray1.length ; i++)
         {
            rewarded[usersarray1[i]] = pools[usersarray1[i]][winnerpool]*8;
            pools[usersarray1[i]][1] = 0;
         }
        }
        else if(winnerpool == 2){
         for(uint256 i = 0; i < usersarray2.length ; i++)
         {
            rewarded[usersarray2[i]] = pools[usersarray2[i]][winnerpool]*8;
            pools[usersarray2[i]][2] = 0;
         }
        } else if(winnerpool == 3){
         for(uint256 i = 0; i < usersarray3.length ; i++)
         {
            rewarded[usersarray3[i]] = pools[usersarray3[i]][winnerpool]*8;
            pools[usersarray3[i]][3] = 0;
         }
        }
        else if(winnerpool == 4){
         for(uint256 i = 0; i < usersarray4.length ; i++)
         {
            rewarded[usersarray4[i]] = pools[usersarray4[i]][winnerpool]*8;
            pools[usersarray4[i]][4] = 0;
         }
        }
        else if(winnerpool == 5){
         for(uint256 i = 0; i < usersarray5.length ; i++)
         {
            rewarded[usersarray5[i]] = pools[usersarray5[i]][winnerpool]*8;
            pools[usersarray5[i]][5] = 0;
         }
        }
        else if(winnerpool == 6){
         for(uint256 i = 0; i < usersarray6.length ; i++)
         {
            rewarded[usersarray6[i]] = pools[usersarray6[i]][winnerpool]*8;
            pools[usersarray6[i]][6] = 0;
         }
        }
        else if(winnerpool == 7){
         for(uint256 i = 0; i < usersarray7.length ; i++)
         {
            rewarded[usersarray7[i]] = pools[usersarray7[i]][winnerpool]*8;
            pools[usersarray7[i]][7] = 0;
         }
        }
        else if(winnerpool == 8){
         for(uint256 i = 0; i < usersarray8.length ; i++)
         {
            rewarded[usersarray8[i]] = pools[usersarray8[i]][winnerpool]*8;
            pools[usersarray8[i]][8] = 0;
         }
        }
        else if(winnerpool == 9){
         for(uint256 i = 0; i < usersarray9.length ; i++)
         {
            rewarded[usersarray9[i]] = pools[usersarray9[i]][winnerpool]*8;
            pools[usersarray9[i]][9] = 0;
         }
        }
        else if(winnerpool == 10){
         for(uint256 i = 0; i < usersarray10.length ; i++)
         {
            rewarded[usersarray10[i]] = pools[usersarray10[i]][winnerpool]*8;
            pools[usersarray10[i]][10] = 0;
         }
        }
        delete usersarray1;
        delete usersarray2;
        delete usersarray3;
        delete usersarray4;
        delete usersarray5;
        delete usersarray6;
        delete usersarray7;
        delete usersarray8;
        delete usersarray9;
        delete usersarray10;

           for(uint8 i=1;i<=10;i++)
           {
               poolamounts[i]=0;
           }

           startTime = block.timestamp;
        }


         function withDraw_Reward() public 
         {
             require(rewarded[msg.sender] > 0 , "reward not found");
             Token.transfer(msg.sender,rewarded[msg.sender]);
             rewarded[msg.sender] = 0;
         }



        function withDraw (uint256 _amount) onlyOwner public
        {
             payable(msg.sender).transfer(_amount);
        }
    
    
    
        function getTokens (uint256 _amount) onlyOwner public
        {
            Token.transfer(msg.sender,_amount);
        }   


        }


        //     Arbi token address          0x948b2e1F5E2Ed40AbABfB77029AF73717356fb47