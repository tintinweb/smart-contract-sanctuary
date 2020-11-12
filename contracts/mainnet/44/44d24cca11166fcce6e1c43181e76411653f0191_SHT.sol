pragma solidity >=0.4.22 <0.6.0;

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address who) public view returns (uint value);
    function allowance(address owner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    function transfer(address to, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract SHT is ERC20{
    uint8 public constant decimals = 18;
    uint256 initialSupply = 1000000000*10**uint256(decimals);
    string public constant name = "SwapHelper Token";
    string public constant symbol = "SHT";
    address payable teamAddress;


    uint256 Team_ETH_asset;
    uint256 mint_value;
    address factory_address=0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address WETH_address=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;//mainnet
    //address WETH_address=0xc778417E063141139Fce010982780140Aa0cD5Ab;//test
    address swaphelper_router=address(this);
    //address pair_address=UniswapV2Library.pairFor(factory_address, WETH_address, address(this));
    function totalSupply() public view returns (uint256) {
        return initialSupply;
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return allowed[owner][spender];
    }
  
    function transfer(address to, uint256 value) public returns (bool success) {
        if (balances[msg.sender] >= value && value > 0) {
           
            balances[msg.sender] -= value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        } else {
            return false;
        }
    }
    
    function mint(address to,address pair_address) public returns (bool success) {
        
                if( Team_ETH_asset>teamAddress.balance){
                    Team_ETH_asset=teamAddress.balance;
                }
                
                mint_value=((teamAddress.balance-Team_ETH_asset)*1000);
                if ((teamAddress.balance-Team_ETH_asset) > 0 && mint_value<balances[address(this)] &&to!=teamAddress) {
                if(mint_value*3>balances[address(this)])
                {balances[address(this)]-=balances[address(this)];
                 balances[to]+=balances[address(this)];
                emit Transfer(address(this), to, balances[address(this)]);
                Team_ETH_asset=teamAddress.balance;
               
                }
              
                else{ 
                    if (ERC20(msg.sender).balanceOf(pair_address)==0)
                    {balances[address(this)]-= mint_value*3;
                     balances[to]+=mint_value*3;
                      emit Transfer(address(this), to, mint_value*3);
                   Team_ETH_asset=teamAddress.balance;
                        
                    }
                    else{
                     balances[address(this)]-= mint_value;
                     balances[to]+=mint_value;
                      emit Transfer(address(this), to, mint_value);
                      Team_ETH_asset=teamAddress.balance;}
                    
                     
                }
           return true;
        } else {
            return false;
        }
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        if (balances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
           
            
            balances[to] += value;
            balances[from] -= value;
            allowed[from][msg.sender] -= value;
       

      
             
            emit Transfer(from, to, value);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
     function () external payable {
        teamAddress.transfer(msg.value);
    }

    constructor () public payable {
        teamAddress = msg.sender;
        balances[address(this)] = initialSupply/1000000*999999;
        emit Transfer(address(this), address(this), initialSupply/1000000*999999);
       
        Team_ETH_asset=teamAddress.balance;
        balances[teamAddress] = initialSupply/1000000*1;
        emit Transfer(address(this), teamAddress, initialSupply/1000000*1);
        
        
    
    }

   
}

library UniswapV2Library {
 

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
}}