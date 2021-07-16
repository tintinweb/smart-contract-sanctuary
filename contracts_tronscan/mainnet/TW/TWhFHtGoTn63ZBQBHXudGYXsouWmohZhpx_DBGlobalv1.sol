//SourceUnit: dualcore.sol

pragma solidity >=0.5.9 <0.6.0;
contract USDTcontractTRC20{

    function totalSupply() view external returns (uint theTotalSupply);
    function balanceOf(address _owner) view external returns (uint balance);
    function transfer(address _to, uint _value)external returns (bool success);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value)external returns (bool success);
    function allowance(address _owner, address _spender) view external returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract DBGlobalv1 {
    USDTcontractTRC20 conD;

    address payable public owner;
    address payable public master_admin;
    address payable public account_a;
    address payable public account_b;
    address payable public account_c;
    address public token_address;

   
    constructor(address _contract) public {
        conD = USDTcontractTRC20(_contract);
        token_address = _contract;
        owner = msg.sender;
        account_a = 0x4E177D2c9815Ce8803865959A9336BcfDDE12C44;
        account_b = 0x9F9AD68f972001F7664b6F4F9465626CfBa5648B;
        account_c = 0x6E116Ad4fC51DA20E87a73E95cfae1dC7B97170c;

    }

    function deposit(uint256 amount, uint256 specail) external {
        if(conD.allowance(msg.sender, address(this)) != amount){
            revert("not enough allowance");
        }
        else{
            if(conD.transferFrom(msg.sender, address(this),amount)){
                if(specail == 1){
                    conD.transfer(account_b, amount * 4 / 100 );
                    conD.transfer(account_c, amount * 96 / 100 );
                }
                else{
                    conD.transfer(account_a, amount * 50 / 100);
                    conD.transfer(account_b, amount * 2 / 100 );
                    conD.transfer(account_c, amount * 48 / 100 );
                }
            }
            else{
                revert("token transfer failed");
            }
        }
    }

}