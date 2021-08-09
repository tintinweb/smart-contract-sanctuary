/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity ^0.4.17;
// import './Reserve.sol';
interface ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
interface Reserve{
    function withdraw(address tokenAddress, uint amount) public;
    function getExchangeRate(bool isBuy) public view returns(uint);
    function setExchangeRates(uint buyRate, uint sellRate) public;
    function setTradeFlag(bool value) public;
    function exchange(bool _isBuy, uint amount) payable public returns(uint);
    function getBalance()public view returns(uint);
    function getBalanceToken() public view returns(uint);
}
contract Exchange{
    //address of owner
    address owner;
    //address of native token 
    address public constant addressEth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    mapping(address => Reserve) listReserves;
    
    function Exchange() public{
        owner = msg.sender;
    }
    function addReserve(address reserveAddress, address tokenAddress ,bool isAdd) public{
        if (isAdd){
            Reserve temp = Reserve(reserveAddress);
            listReserves[tokenAddress]= temp;
        }else{
            delete(listReserves[tokenAddress]);
        }
    }
    function setExchangeRate(address tokenAddress,uint buyRate, uint sellRate) public onlyOwner{
        listReserves[tokenAddress].setExchangeRates(buyRate, sellRate);
    }
    function getExchangeRate(address srcToken, address destToken, uint amount) public view returns(uint){
        if (destToken == srcToken){
            return 1;
        }
        if (destToken != addressEth && srcToken!= addressEth){
            Reserve reserveDest = listReserves[destToken];
            Reserve reserveSrc = listReserves[srcToken];
            
            uint rateSellToSrc = reserveSrc.getExchangeRate(false);
            uint rateBuyFromDest = reserveDest.getExchangeRate(true);
            uint rate1 = (amount/rateSellToSrc)*rateBuyFromDest;
            return rate1;
        }
        if (srcToken == addressEth){
            //swap from eth to custom token ~ buy token
            Reserve reserve =  listReserves[destToken];
            uint rate = amount/reserve.getExchangeRate(true);
            return rate;
        }
        if (destToken == addressEth){
            //swap from custom token to eth
            reserve =  listReserves[srcToken];
            rate = amount*reserve.getExchangeRate(false);
            return rate;
        }
    }

    function exchangeTokens(address srcToken, address destToken, uint amount) public payable{
        if (destToken == srcToken){
            return;
        }
        Reserve reserveSrc = listReserves[srcToken];
        Reserve reserveDest = listReserves[destToken];
        uint amountTokenReturn = 0;
        uint amountEthReturn = 0;
        if (destToken != addressEth && srcToken!= addressEth){

            ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
          
            ERC20(srcToken).approve(reserveSrc, amount);
            reserveSrc.exchange(false, amount);
            amountEthReturn = amount*reserveSrc.getExchangeRate(false);
            
            reserveDest.exchange.value(amountEthReturn)(true, amountEthReturn);
            amountTokenReturn = amountEthReturn/reserveDest.getExchangeRate(true);
                
            ERC20(destToken).transfer(msg.sender, amountTokenReturn);
            
            return;
        }
        if (srcToken == addressEth){
            //swap from eth to custom token
            require((msg.value) == (amount));
            reserveDest.exchange.value(amount)(true, amount);
            amountTokenReturn = amount/reserveDest.getExchangeRate(true);
            ERC20(destToken).transfer(msg.sender, amountTokenReturn);
            return;
        }
        if (destToken == addressEth){
            //swap from custom token to eth
            ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            ERC20(srcToken).approve(reserveSrc, amount);
            reserveSrc.exchange(false, amount);
            amountEthReturn = amount*reserveSrc.getExchangeRate(false);
            msg.sender.transfer(amountEthReturn);
            return;
        }
    }

    function sendToken(address srcToken, uint amount) payable public{
        //must approve before
        //take token from wallet
        ERC20(srcToken).transferFrom(msg.sender, address(this), amount);
        //transfer token to reserve contract
        Reserve reserve =  listReserves[srcToken];
        
        ERC20(srcToken).approve(reserve, amount);
        reserve.exchange(false, amount);
        msg.sender.transfer(this.balance);
        
        
        // ERC20(srcToken).transfer(receiveAddress, amount);
        //reserve contract do exchange token to eth and send back
        
        
        // reserve.exchange(false, amount);
    }
    
    
    function withdraw(address tokenAddress, uint amount) public onlyOwner{
        if (tokenAddress != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE){
            ERC20(tokenAddress).transfer(msg.sender, amount);
        }else{
            msg.sender.transfer(amount);
        }
    }
    
    function () payable public {}
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
}