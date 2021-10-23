//SourceUnit: DappWithdrawal.sol

pragma solidity 0.5.10;



/**
 * @title TRC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract  DappWithdrawal {


      address public _owner;
      ITRC20 Token;
    
   
   ITRC20 _WYZTH;
   
   constructor(ITRC20 _tokenaddress) public
   {
       _WYZTH = _tokenaddress;
       _owner = msg.sender;
   }

    
           modifier onlyOwner()
    {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    

    function register()public view returns(address)
    {
        return msg.sender;
    }
    
    function multisendToken( address[] calldata _contributors, uint256[] calldata _balances) external onlyOwner  
    {
            uint8 i = 0;
            for (i; i < _contributors.length; i++) {
            _WYZTH.transfer(_contributors[i], _balances[i]);
            
            }
    }
        
          function sendMultiEth(address payable [] calldata userAddress,uint256[] calldata _amount) payable external  onlyOwner {
        uint256 totalPayout;
        uint256 j;
        for(j=0;j<_amount.length;j++){
            totalPayout+=_amount[j];
        }
        require(msg.value==totalPayout,"Invalid Value Given!");
        uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(_amount[i]);
        
        }
}

    function sell(uint256 _token)external{
        require(_token>0,"Select amount first");
        _WYZTH.transferFrom(msg.sender,address(this),_token);
    }
    
    function withDraw(uint256 _amount) onlyOwner external{
        msg.sender.transfer(_amount*1000000);
    }
    function getTokens(uint256 _amount) onlyOwner external {
        _WYZTH.transfer(msg.sender,_amount);
    }
        
}