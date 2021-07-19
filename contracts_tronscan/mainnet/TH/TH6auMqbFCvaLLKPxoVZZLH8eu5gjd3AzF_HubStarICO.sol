//SourceUnit: HubStarICO.sol

pragma solidity >=0.5.0 <0.6.0;


contract Token {
    function transferFrom(address from, address to, uint256 value) public returns (bool){}

    function transfer(address to, uint256 value) public returns (bool){}

    function balanceOf(address who) public view returns (uint256){}

    function burn(uint256 _value) public {}

    function decimals() public view returns(uint8){}
}

contract HubStarICO  {
    
    Token token;
    uint tokensSold = 0;
    uint trxRaised = 0;

    uint timeToClose = 1630407600;
    address payable public adminAddr;
    uint[] price;
    uint[] trxVals;
	event saleMade(uint256 amount, uint256 tokensTransactionSold, address purchaseAddress);
    constructor(address payable admin, address tokenaddr) public{
        trxVals.push(501); //compare value 1
        trxVals.push(5001); // val2
        trxVals.push(30000); //val3
        trxVals.push(10000000000); //val4
        
        price.push(100); 
        price.push(200); 
        price.push(400); 
        price.push(800); 
        
       
        token = Token(tokenaddr);
        adminAddr = admin;
    }
    function buyToken() payable external{
        require(now < timeToClose, "contract is closed");
        for(uint8 i = 0; i<trxVals.length;i++){
            if(msg.value<(trxVals[i]*1000000)){
                require(token.transferFrom(adminAddr, msg.sender, ((price[i]*(10**uint256(token.decimals())))*(msg.value))/(10**6)), "Sending Failed");
                tokensSold +=  ((price[i]*(10**uint256(token.decimals())))*(msg.value))/(10**6);
                trxRaised += msg.value;
				emit saleMade(msg.value, ((price[i]*(10**uint256(token.decimals())))*(msg.value))/(10**6),msg.sender);
                break;
            }
        }

    }
    function withdraw() external{
        require(msg.sender == adminAddr);
        adminAddr.transfer(address(this).balance);
    }
    function changeTime(uint256 time) external{
        require(msg.sender == adminAddr);
        timeToClose = time;
    }
    function TrxRaised() external view returns(uint256){
        return(trxRaised);
    }
    function TokensSold() external view returns(uint256){
        return(tokensSold);
    }
}