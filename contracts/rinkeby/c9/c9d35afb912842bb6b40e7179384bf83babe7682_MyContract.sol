/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.4.24;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}


interface IERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);
}


contract MyContract {
    
    
    function send(address _token, address _to, uint256 _amount) external {
        IERC20 token = IERC20(address(_token));
        token.transferFrom(msg.sender, _to , _amount);
    }
    
    function get_balance(address _token, address _user)public view returns(uint) {
        IERC20 token = IERC20(address(_token));
        return token.balanceOf(_user);
    }
    
    
     function get_supply(address _token)public view returns(uint) {
        IERC20 token = IERC20(address(_token));
        return token.totalSupply();
    }
    
    
    function transfer_send(address _token, address to, uint value) external {
        IERC20 token = IERC20(address(_token));
        token.transfer( to , value);
    }
    
    
    function get_price(address _assets)public view returns(int){
        AggregatorInterface token_price = AggregatorInterface(address(_assets));
        int price = token_price.latestAnswer();
        return price;
    }
    
    
    
    
    
    
    
}