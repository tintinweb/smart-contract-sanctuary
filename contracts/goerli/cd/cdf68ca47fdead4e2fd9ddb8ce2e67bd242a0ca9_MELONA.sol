/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;

contract MELONA {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // user balances
    // using public variable means getters are automatically generated
    mapping(address => uint256) public balances;
    
    uint256 public totalSupply;
    
    /** allowances
        how can this be implemented using a mapping?
        we need to know the allowance for a specific user, in the context of a 
        specific spender. We want this in O(1) time.
        tip: you can chain mapping together, for example
        mapping(address => mapping(uint => uint)) simpleMap would return
        a mapping from uint to uint, for every address provided to it.
    */
    mapping(address => mapping(address => uint256)) public allowances;
    //allowances(address spender, address owner) =>
    
    /** our token only takes in an initial supply. You may provide arguments for:
        name
        decimals
        initial token holder
        symbol
    */
    string public constant name = "Melona";
    
    constructor(uint256 initialSupply) {
        // set total supply to initialSupply
        totalSupply = initialSupply;
        // send initial supply to the msg.sender
        balances[msg.sender] = totalSupply;
        // tip: this can be done by simply updating the msg.sender
        // balance in the balance mapping
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        // does this user have enough tokens to transfer?
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= amount, "Melona: transfer amount exceeds balance");

        _transfer(msg.sender, to, amount);
        return true;
    }

    /* define a transferFrom(from, to, amount) function.
        how is this logic similar to transfer? How is it different?
        tip: you can use an internal _transfer function to share logic between trasnfer and transferFrom
    */
    function transferFrom(address from, address to, uint256 amount)
        public
        returns
        (bool)
    {
        uint256 spendable = allowances[from][msg.sender];
        require(spendable <= amount, "Melona: transfer amount exceeds allowance");
        _transfer(from, to, amount);
        
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        // return the allowance a specific owner has granted (using approve) to a specific spender
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * Internal function that can be used to share logic between transfer and transferFrom
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        //update balances
        balances[from] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        
        // emit the transfer event
        emit Transfer(msg.sender, to, amount);
        
    }
}