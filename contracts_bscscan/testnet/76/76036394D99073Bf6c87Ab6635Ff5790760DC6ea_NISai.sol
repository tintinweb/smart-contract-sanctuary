/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.5.16; /* maybe need to change to 0.4.18*/

contract NISai{
    
    uint convertRate;
    //contract_address
    //NISai dai_contract = NISai(_daiToken); 
    
    //address private constant _daiToken = 0x6b175474e89094c44da98b954eedeac495271d0f;
   // NISai dai_contract = NISai(0x6b175474e89094c44da98b954eedeac495271d0f); 

    NISai public dai_contract = NISai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // --- ERC20 Data ---
    string  public constant name     = "NISai Stablecoin";
    string  public constant symbol   = "NISAI";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint totalSupply_;

    mapping (address => uint)                      public balances;
    mapping (address => uint)                      public daiCashed;
    mapping (address => mapping (address => uint)) public allowed;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    
    // --- ERC20 Functions ---
    function totalSupply() public view returns (uint) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint){
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint){
        return allowed[tokenOwner][spender];
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

   function tryMul(uint a, uint b) internal pure returns (uint) {
       
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (0);
            uint c = a * b;
            if (c / a != b) return (0);
            return (c);
        
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint a, uint b) internal pure returns (uint) {
       
            if (b == 0) return ( 0);
            return ( a / b);
       
    }

    constructor(uint amount) public {
        totalSupply_ = amount;
        balances[msg.sender] = totalSupply_;
    }

    // --- Token ---
    function transfer(address receiver,
                     uint numTokens) public returns (bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = sub(balances[msg.sender], numTokens);
      balances[receiver] = add(balances[receiver], numTokens);
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
    }
    
    function transferFrom(address owner, address buyer,
                     uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      balances[owner] = sub(balances[owner], numTokens);
      allowed[owner][msg.sender] = sub(
            allowed[owner][msg.sender], numTokens);
      balances[buyer] = add(balances[buyer], numTokens);
      emit Transfer(owner, buyer, numTokens);
      return true;
    }

    function approve(address delegate,
                    uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply_ = add(totalSupply_, amount);
        balances[account] = add(balances[account], amount);
        
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        balances[account] = sub(balances[account], amount);
        totalSupply_ = sub(totalSupply_, amount);
    }
    
    function buy(address owner, uint amount) public returns (bool){
        uint convertedAmount = tryDiv(tryMul(amount,convertRate),(1));
        dai_contract.transferFrom(owner,address(this), amount); //add check here
        daiCashed[owner] += amount;
        _mint(owner, convertedAmount);
    }
    
    function sell(address owner, uint amount) public returns (bool){
       uint convertedAmount = tryDiv(tryMul(amount,convertRate),(1));
        if (daiCashed[owner] >= convertedAmount){
            dai_contract.transferFrom(address(this),owner, convertedAmount);
            daiCashed[owner] -= convertedAmount;
            _burn(owner, amount);
        }
    }
}