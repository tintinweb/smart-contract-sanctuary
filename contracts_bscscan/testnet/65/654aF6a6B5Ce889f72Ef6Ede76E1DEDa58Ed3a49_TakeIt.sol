/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.7.6;

interface OtherInterface {
    function claim() external;
    function distributeBusdDividends(uint256 amount) external payable;
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    

}

contract TakeIt {
    function claims(address _contract) public {
        OtherInterface otherContract = OtherInterface(_contract);
        otherContract.claim();
    }
    
    function callDistributeBusdDividends(address _contract, uint256 amount) public payable {
        OtherInterface otherContract = OtherInterface(_contract);
        otherContract.distributeBusdDividends(amount);
    }
    
    function transferForeignToken(address _token, address _to) external returns(bool _sent){
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}