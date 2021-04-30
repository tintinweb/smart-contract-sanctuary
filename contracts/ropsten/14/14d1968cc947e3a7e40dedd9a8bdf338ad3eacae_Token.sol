/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

//
// token.sol
//

pragma solidity ^0.8.4;

//
//
//

contract Token {
    //
    //
    // MEMBERS
    //
    //

    address internal _deployer;
    function deployer() external view returns (address) {
        return _deployer;
    }

    //
    //
    //

    string internal _name = "Token-0001";
    function name() external view returns (string memory) {
        return _name;
    }

    string internal _symbol = "TOK-0001";
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    //
    //
    //

    uint internal _decimals = 18;
    function decimals() external view returns (uint) {
        return _decimals;
    }

    //
    //
    //

    uint256 internal _totalSupply = 0;
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    //
    //
    //

    mapping(address => uint256) _balances;
    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    //
    //
    //

    constructor() {
        _deployer = msg.sender;
    }

    //
    //
    // FUNCTIONS
    //
    //

    //
    // @notice transfers `amount` from msg.sender to `account`
    // @param (address, uint)
    // @return (bool)
    //
    function transfer(address account, uint amount) external returns (bool) {
        return handleTransfer(msg.sender, account, amount);
    }

    //
    // @notice creates `amount` supply and adds it to `account`
    // @param (address, uint)
    // @return (bool)
    //
    function mint(address account, uint amount) external returns (bool) {
        return handleMint(msg.sender, account, amount);
    }

    //
    // @notice destroys `amount` supply and removes it from `account`
    // @param (address, uint)
    // @return (bool)
    //
    function burn(address account, uint amount) external returns (bool) {
        return handleBurn(msg.sender, account, amount);
    }

    //
    //
    //

    //
    // @notice transfers `amount` from `sender` to `receiver`
    // @param (address, address, uint)
    // @return (bool)
    //
    function transferFrom(address sender, address receiver, uint amount) external returns (bool) {
        return handleTransfer(sender, receiver, amount);
    }

    //
    //
    //

    //
    // @notice 
    // @param (address, uint)
    // @return (bool)
    //
    function approve(address account, uint amount) external returns (bool) {
        return handleApproval(msg.sender, account, amount);
    }

    //
    //
    //

    //
    // @notice toggle
    // @param (address, uint)
    // @return (bool)
    //
    function toggle(address account, uint pos) external returns (bool) {

    }

    //
    //
    // INTERNAL
    //
    //

    event Transfer(address indexed sender, address indexed receiver, uint amount);
    function handleTransfer(address sender, address receiver, uint amount) internal returns (bool) {
        require(sender != address(0));
        require(receiver != address(0));

        //
        //
        //

        if(sender != msg.sender) {
            //_allowances[sender][msg.sender] -= amount;
        }

        //
        // since version 0.8 of solidity we have built in
        // checks for underflow and overflow which removes
        // the need for manual checking.
        //

        _balances[sender] -= amount;
        _balances[receiver] += amount;

        //
        //
        //

        emit Transfer(sender, receiver, amount);
        return true;
    }

    event Mint(address indexed sender, address indexed receiver, uint amount);
    function handleMint(address sender, address receiver, uint amount) internal returns (bool) {
        require(sender != address(0));
        require(receiver != address(0));

        //
        // since version 0.8 of solidity we have built in
        // checks for underflow and overflow which removes
        // the need for manual checking.
        //

        _balances[receiver] += amount;
        _totalSupply += amount;

        //
        //
        //

        emit Mint(sender, receiver, amount);
        return true;
    }

    event Burn(address indexed sender, address indexed receiver, uint amount);
    function handleBurn(address sender, address receiver, uint amount) internal returns (bool) {
        require(sender != address(0));
        require(receiver != address(0));

        //
        // since version 0.8 of solidity we have built in
        // checks for underflow and overflow which removes
        // the need for manual checking.
        //

        _balances[receiver] -= amount;
        _totalSupply -= amount;

        //
        //
        //

        emit Burn(sender, receiver, amount);
        return true;
    }

    //
    //
    //

    event Approval(address indexed owner, address indexed spender, uint amount);
    function handleApproval(address owner, address spender, uint amount) internal returns (bool) {
        require(owner != address(0));
        require(spender != address(0));

        //
        //
        //

        //_allowances[owner][spender] = amount;

        //
        //
        //

        emit Approval(owner, spender, amount);
        return true;
    }
}