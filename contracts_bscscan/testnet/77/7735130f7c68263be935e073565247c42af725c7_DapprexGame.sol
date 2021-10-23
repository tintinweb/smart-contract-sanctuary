/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT
// dapprex.com dApp Creator

pragma solidity ^0.8.9;

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

interface IERC1155 {
    function randomrunn() external returns (uint);
    function randomxbet(uint runner) external returns (uint);
}

contract DapprexGame {

    address public creator;
    IERC1155 public randcontract;
    
    uint public gid = 0;
    
    mapping (address => uint256) balance;
    
    mapping (uint => uint) g_run;
    
    mapping (uint => uint) g_bet;
    
    mapping (uint => uint) g_win;
    
    mapping (uint => uint) g_ern;
    
    mapping (uint => address) g_ply;
    
    mapping (uint => uint) g_res;

    constructor(
        address _creator
        ) public {
            creator = _creator;
        }

        modifier onlyCreator() {
            require(msg.sender == creator); _;
        }

        function _safeTransferFrom(IERC20 token, address sender, address recipient, uint amount) private {bool sent = token.transferFrom(sender, recipient, amount);
            require(sent, "dapprex.com: Token transfer failed");
        }

        function _safeTransfer(IERC20 token, address recipient, uint amount) private {bool sent = token.transfer(recipient, amount);
            require(sent, "dapprex.com: Token transfer failed");
        }

        function clearStuckBnb(uint256 amount, address receiveAddress) external onlyCreator() {
            payable(receiveAddress).transfer(amount);
        }

        function clearStuckTOK(IERC20 token, address receiveAddress, uint256 balance) external onlyCreator() {
            _safeTransfer(token, receiveAddress, balance);
        }
        
        function _setrandCont(IERC1155 _randcontract) public onlyCreator() {
             randcontract = _randcontract;
        }
        
        function showBalance(address winner) public view returns (uint) {
             return balance[winner];
        }
        
        function showGameDetails(uint game) public view returns (uint, uint, uint, uint, uint, address) {
             return (g_res[game],g_run[game],g_win[game],g_bet[game],g_ern[game],g_ply[game]);
        }
        
        function claimbalance() public returns (bool) {
            
            address payable earner = payable(msg.sender);
            
            earner.transfer(balance[msg.sender]);
            
            balance[msg.sender]=0;
            
             return true;
        }
    
        function playgame(uint runner) public payable returns (uint) {
             require(msg.value >= 2000000000000000, "dapprex.com: Min amount 0.002 BNB");

            uint winner = randcontract.randomrunn();
             
            uint xbet = randcontract.randomxbet(winner);
            
            if(winner==0){ winner = 1; }
            
            if(xbet==0 || xbet==1){ xbet = 2; }
            
            uint betearn = msg.value * xbet;
            
            uint add_balance = balance[msg.sender] + betearn;
            
            gid=gid + 1;
            g_run[gid]=runner;
            g_win[gid]=winner;
            g_bet[gid]=xbet;
            g_ern[gid]=betearn;
            g_ply[gid]=msg.sender;

            if(winner==runner){
                g_res[gid]=1;
                balance[msg.sender]=add_balance;
                
                return gid;
                
            }else{
                g_res[gid]=0;
                
                return gid;
            }
            
        }

}