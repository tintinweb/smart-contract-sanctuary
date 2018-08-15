pragma solidity ^0.4.24;

contract IERC20Token {
    function name() public view returns (string) ;
    function symbol() public view returns (string); 
    function decimals() public view returns (uint8); 
    function totalSupply() public view returns (uint256); 
    function balanceOf(address _owner) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


contract BREBuy_ERC20 {
    
    struct ContractParam {
        uint32  totalSize ; 
        uint256 singlePrice;
        uint8  pumpRate;
        bool hasChange;
    }
    uint256 public constant PRICE = 1;
    address owner = 0x0;
    uint32  gameIndex = 0;
    uint256 totalPrice= 0;
    ContractParam public setConfig;
    ContractParam public curConfig;
    IERC20Token public token;
    address[] public addressArray = new address[](0);

    event addPlayerEvent(uint32,address);
    event GameOverEvent(uint32,uint32,uint256,uint8,address,uint);
 
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor ( uint32 _totalSize,
                  uint256 _singlePrice,
                  address tokenAddr
    )  public payable  {
        owner = msg.sender;
        setConfig = ContractParam(_totalSize,_singlePrice * PRICE ,5,false);
        curConfig = ContractParam(_totalSize,_singlePrice * PRICE ,5,false);
        token = IERC20Token(tokenAddr);
        startNewGame();
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    

     
    
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
       
        IERC20Token t = IERC20Token(_token);
        
        require(_token == address(token) );
        require(_value == curConfig.singlePrice );
        require(t.transferFrom(_from, this, _value));
        addPlayer(_from);
    }
    
    function changeConfig( uint32 _totalSize,uint256 _singlePrice,uint8 _pumpRate) onlyOwner public payable {
    
        curConfig.hasChange = true;
        if(setConfig.totalSize != _totalSize) {
            setConfig.totalSize = _totalSize;
        }
        if(setConfig.pumpRate  != _pumpRate){
            setConfig.pumpRate  = _pumpRate;
        }
        if(setConfig.singlePrice != _singlePrice * PRICE){
            setConfig.singlePrice = _singlePrice * PRICE;
        }
    }
    
    function startNewGame() private {
        
        gameIndex++;
        if(curConfig.hasChange) {
            if(curConfig.totalSize   != setConfig.totalSize) {
                curConfig.totalSize   = setConfig.totalSize;
            }
            if(curConfig.singlePrice != setConfig.singlePrice){
               curConfig.singlePrice = setConfig.singlePrice; 
            }
            if( curConfig.pumpRate    != setConfig.pumpRate) {
                curConfig.pumpRate    = setConfig.pumpRate;
            }
            curConfig.hasChange = false;
        }
        addressArray.length=0;
    }
     
  
    function addPlayer(address player) private  {
    
        totalPrice = totalPrice + curConfig.singlePrice;
        addressArray.push(player);
       
        emit addPlayerEvent(gameIndex,player);
        if(addressArray.length >= curConfig.totalSize) {
            gameResult();
            startNewGame();
        }
    } 
    
    function getGameInfo() public view returns  (uint256,uint32,uint256,uint8,address[],uint256,uint256)  {
        return (gameIndex,
                curConfig.totalSize,
                curConfig.singlePrice,
                curConfig.pumpRate,
                addressArray,
                totalPrice,
                token.balanceOf(msg.sender));
    }
    
    function gameResult() private {
            
      uint index  = getRamdon();
      address lastAddress = addressArray[index];
      uint256 totalBalace = token.balanceOf(this);
      uint256 giveToOwn   = totalBalace * curConfig.pumpRate / 100;
      uint256 giveToActor = totalBalace - giveToOwn;
      
      token.transfer(owner,giveToOwn);
      token.transfer(lastAddress,giveToActor);
 
      emit GameOverEvent(
                    gameIndex,
                    curConfig.totalSize,
                    curConfig.singlePrice,
                    curConfig.pumpRate,
                    lastAddress,
                    now);
    }
    
    function getRamdon() private view returns (uint) {
      bytes32 ramdon = keccak256(abi.encodePacked(ramdon,now,blockhash(block.number-1)));
      for(uint i = 0; i < addressArray.length; i++) {
         ramdon = keccak256(abi.encodePacked(ramdon,now, addressArray[i]));
      }
      uint index  = uint(ramdon) % addressArray.length;
      return index;
    }
    
    function () payable public {
       require(msg.value == 0);
    }
}