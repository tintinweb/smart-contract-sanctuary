/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.4.19;

contract ERC20Basic {

    string public constant name = "Lava Network";
    string public constant symbol = "LAVA";
    uint8 public constant decimals = 18;  

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    uint public liquidityFee = 10; //0.1% divisor 100
    address public _liquidityPoolAddress;
    address public _Owner;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 1000000 * 10**3 * 10**18;

   constructor() public {  
	   balances[msg.sender] = totalSupply_;
	   _Owner = msg.sender;

	   emit Transfer(address(0), msg.sender, totalSupply_);
    }  

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        uint256 tokenToTransfer = numTokens - calculateLiquidityFee(numTokens);
        balances[receiver] += tokenToTransfer;
        balances[_liquidityPoolAddress] += calculateLiquidityFee(numTokens);
        
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        uint256 tokenToTransfer = numTokens - calculateLiquidityFee(numTokens);
        balances[buyer] += tokenToTransfer;
        balances[_liquidityPoolAddress] += calculateLiquidityFee(numTokens);
        
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function SetLiquidityPairAddressAndFee(address liquidityPairAddress, uint LPfee) public onlyOwner{
        _liquidityPoolAddress = liquidityPairAddress;
        liquidityFee = LPfee;
    }
    
    modifier onlyOwner{
        require(msg.sender == _Owner, 'Only Owner Can Call This Function');
        _;
    }
    
    function calculateLiquidityFee(uint256 _amount) internal view returns (uint256) {
        return ((_amount * liquidityFee) / 10**4);
    }
}