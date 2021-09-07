/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity >=0.7.0;

interface Erc20
{
    function symbol() view external returns (string memory _symbol);
    function decimals() view external returns (uint8 _decimals);
    
    function balanceOf(address _owner) 
        view
        external
        returns (uint256 _balance);
        
    event Transfer(address indexed from, address indexed to, uint256 value);
    function transfer(address _to, uint256 _amount) 
        external
        returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _amount)
        external
        returns (bool _success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approve(address _spender, uint256 _amount) 
        external
        returns (bool _success);
}

contract TokenTransferer {
    function transfer(Erc20 _token, address _target, uint256 _wad)
        external
    {
        bool success = _token.transfer(_target, _wad);
        require(success, "ABQDAO/could-not-transfer");
    }
}