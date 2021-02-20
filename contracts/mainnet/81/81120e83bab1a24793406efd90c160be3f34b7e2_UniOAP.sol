/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

pragma solidity ^0.4.18;

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface UniswapV2Pair {
    function token0() external returns(address _token0);
    function token1() external returns(address _token1);
    function mint(address to) external returns (uint liquidity);
}

contract UniOAP {
    
    address owner;
    mapping(address => bool) public authorized;
    
     modifier onlyAuth() {
        require(authorized[msg.sender] == true, "Sender must be authorized.");
        _;
    }
    
    constructor() 
        public 
    {
        authorized[msg.sender] = true;
    }

    function() public payable {
       revert("Invalid Transaction");
    }
    
    function mintProxy(address _uniPair) onlyAuth external{

        UniswapV2Pair pair = UniswapV2Pair(_uniPair);

        ERC20 tokenA = ERC20(pair.token0() );
        ERC20 tokenB = ERC20(pair.token1() );
        
        tokenA.transfer(_uniPair, tokenA.balanceOf(address(this)));
        tokenB.transfer(_uniPair, tokenB.balanceOf(address(this)));
        
        pair.mint(msg.sender);
        
    }
    
     function failSafe(address _toUser, uint _amount) public returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(address(this).balance >= _amount, "Insufficient balance");
        (_toUser).transfer(_amount);
        return true;
    }
    
     function claimTokens(address _toUser, address _token) public {
        if (_token == address(0)) {
            address(uint160(_toUser)).transfer(address(this).balance);
            return;
        }
        ERC20 _erc20token = ERC20(_token);
        uint256 balance = _erc20token.balanceOf(address(this));
        _erc20token.transfer(_toUser, balance);
    }
    
    function addAuth(address _newowner, bool status) onlyAuth public  {
       authorized[_newowner] = status;
    }
}