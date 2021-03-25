/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity 0.5.10;

contract ERC20 {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);

    function decimals() public view returns (uint256 digits);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract AQNBatchProcess
{
    address payable public token_address;
    address payable public owner;
    address public companyaddress;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);

    constructor() public{

        token_address = 0xC209830C10D1d7aA4Ba54a7C6Ac63e7084e8c004;

        owner = msg.sender;

    }

    function addCompanyAddress(address _addr) external {
        require(msg.sender == owner, "OWNER ONLY");

        companyaddress = _addr;
    }
    
    
    function processTransfer(address[] memory _contributors, uint256[] memory _balances) public {
        
        require(
            msg.sender == owner || msg.sender == companyaddress,
            "PRIVILAGED USER ONLY"
        );
        
        uint256 total = 0;
        
        uint8 j = 0;
        for(j; j < _contributors.length; j++)
        {
            total += _balances[j];
        }
    
        
        ERC20 erc20token = ERC20(token_address);
        
        require(erc20token.balanceOf(address(this)) >= total , "Didnt Have enough Token");
        
        
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            erc20token.transfer(_contributors[i], _balances[i]);
            
        }
        

    }
    
}