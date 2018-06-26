pragma solidity 0.4.24;


interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


contract IKyberNetwork{
    /*
    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    */                   
    function trade(address source, 
                  uint256 srcAmount, 
                  address dest, 
                  address destAddress,
                  uint256 maxDestAmount, 
                  uint256 minConversionRate, 
                  address walletId);                   
}





contract TokenConversion {

  IKyberNetwork tokenConvertor = IKyberNetwork(0xd19559b3121c1b071481d8813d5dbcdc5869e2e8);
  address constant ETH_TOKEN_ADDRESS = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
  address constant BAT_TOKEN_ADDRESS = 0x04A34c8f5101Dcc50bF4c64D1C7C124F59bb988c;
  address outWallet = 0xC87e2242A7fC5328bf1f32016F43496c10bBC4D4;   
  
  function convertToInd() payable {
        tokenConvertor.trade(ETH_TOKEN_ADDRESS,
                             msg.value,
                             BAT_TOKEN_ADDRESS,
                             outWallet,
                             1100000000000,
                             0,
                             0);    
  }
  

  function () payable {
      convertToInd();
  }
}



/*
interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


interface IKyberNetwork{
    function trade(address source,uint srcAmount,
                   ERC20 dest,address destAddress,
                   int maxDestAmount,uint minConversionRate, 
                   address walletId);
}


contract Main {
  event GasLeft(uint256 gasamount);
  event randomDetails(address sender,address argsend ,uint256 value);  

  address kyberConveter;
  IKyberNetwork tokenConvertor;
  ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  ERC20 constant internal BAT_TOKEN_ADDRESS = ERC20(0x04A34c8f5101Dcc50bF4c64D1C7C124F59bb988c);
  address outWallet = 0xC87e2242A7fC5328bf1f32016F43496c10bBC4D4;    
  address [] stuff; 
    
  constructor (){
      tokenConvertor = IKyberNetwork(0xd19559b3121c1b071481d8813d5dbcdc5869e2e8);
  }

  
  function handlePayment(address senderAddress) payable public {
     emit GasLeft(gasleft());
     emit randomDetails(msg.sender,senderAddress,msg.value);
     
     for(uint i = 0 ; i < 10 ; ++i)
        stuff.push(msg.sender);
     
     /*
     tokenConvertor.trade(ETH_TOKEN_ADDRESS,msg.value,
                          BAT_TOKEN_ADDRESS,outWallet,
                          1,0,0);
     

     
     
  }
}
*/