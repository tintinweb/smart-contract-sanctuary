pragma solidity ^0.5.2;


contract XBL_ERC20Wrapper
{
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function allowance(address _owner, address _spender) public  returns (uint256 remaining);
    function balanceOf(address _owner) public returns (uint256 balance);
}


contract SwapContrak 
{
    XBL_ERC20Wrapper private ERC20_CALLS;

    string eosio_username;
    uint256 public register_counter;

    address public swap_address;
    address public XBLContract_addr;

    mapping(string => uint256) registered_for_swap_db; 
    mapping(uint256 => string) address_to_eosio_username;


    constructor() public
    {
        swap_address = address(this); /* Own address */
        register_counter = 0;
        XBLContract_addr = 0x49AeC0752E68D0282Db544C677f6BA407BA17ED7;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
    }

    function getPercent(uint8 percent, uint256 number) private returns (uint256 result)
    {
        return number * percent / 100;
    }
    

    function registerSwap(uint256 xbl_amount, string memory eosio_username) public returns (int256 STATUS_CODE)
    {
        uint256 eosio_balance;
        if (ERC20_CALLS.allowance(msg.sender, swap_address) < xbl_amount)
            return -1;

        if (ERC20_CALLS.balanceOf(msg.sender) < xbl_amount) 
            return - 2;

        ERC20_CALLS.transferFrom(msg.sender, swap_address, xbl_amount);
        if (xbl_amount >= 5000000000000000000000)
        {
            eosio_balance = xbl_amount +getPercent(5,xbl_amount);
        }
        else
        {
            eosio_balance = xbl_amount;
        }
        registered_for_swap_db[eosio_username] = eosio_balance;
        address_to_eosio_username[register_counter] = eosio_username; 
        register_counter += 1;
    }
    
    function getEOSIO_USERNAME(uint256 target) public view returns (string memory eosio_username)
    {
        return address_to_eosio_username[target];
    }
     
    function getBalanceByEOSIO_USERNAME(string memory eosio_username) public view returns (uint256 eosio_balance) 
    {
        return registered_for_swap_db[eosio_username];
    }
}