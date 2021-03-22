/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.5.1;

contract ERC20Token{
    
    string name;
    mapping (address=>uint256) public balance;
    
    function mint() public{
        balance[tx.origin]++;
    }
}

contract Mycontract{
    address public token;
    address payable wallet;
    
    event Purchese(
        address indexed _buyer,
        uint256 _wallet
    );
    
    constructor(address payable _wallet, address  _token)public{
       wallet= _wallet;
       token= _token;
       
    }
    
    function() external payable {
       buyToken();
     }
    
    function buyToken() public payable{
        ERC20Token _token= ERC20Token(address(token));
        _token.mint();
        wallet.transfer(msg.value);
        emit Purchese(msg.sender,1);
    }
    
    
}