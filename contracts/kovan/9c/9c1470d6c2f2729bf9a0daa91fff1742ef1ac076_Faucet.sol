/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _amt) external;
    function transfer(address _to, uint256 _amt) external;
    function balanceOf(address _user) external view returns (uint256);
    function approve(address _user, uint256 _amt) external;
}

contract Faucet {
    address public developer;

    struct Token {
        address token;
        uint256 amount;
    }

    mapping(uint256 => Token) public tokens;

    uint256 public totalTokens;
    uint256 public timelimit = 86400000;
    
    uint256 public numberOfETH;

    mapping(address => uint256) public lastClaim;

    modifier onlyDev() {
        require(msg.sender == developer, "RESTRICTED");
        _;
    }

    constructor(address _developer) {
        developer = _developer;
        numberOfETH = 20000000000000000;
    }

    function releaseAll(address payable _user) external {
        
        if(msg.sender != developer) {
            require(
                lastClaim[msg.sender] + timelimit < block.timestamp,
            "try after some time"
        );
                lastClaim[msg.sender] = block.timestamp;

        }
        else {
           require( lastClaim[_user] + timelimit < block.timestamp, "try after some time");
                           lastClaim[_user] = block.timestamp;

        }

        for (uint256 i = 0; i < totalTokens; i++) {
            Token storage token = tokens[i];
            IERC20(token.token).transfer(_user, token.amount);
        }
        
        if(numberOfETH > 0) {
           _user.transfer(numberOfETH);
        }
        
    }

    function removeAll(address payable _to) external onlyDev {
        for (uint256 i = 0; i < totalTokens; i++) {
            Token storage token = tokens[i];
            IERC20(token.token).transfer(
                _to,
                IERC20(token.token).balanceOf(address(this))
            );
            totalTokens = totalTokens - 1;
        }
        if(numberOfETH > 0) {
           _to.transfer(numberOfETH);
        }
    }

    function addToken(
        address _token,
        uint256 _amount,
        uint256 _totalAmount
    ) external onlyDev {
        Token storage token = tokens[totalTokens];
        token.token = _token;
        token.amount = _amount;
        totalTokens = totalTokens + 1;
        IERC20(_token).transferFrom(msg.sender, address(this), _totalAmount);
    }
 

    function removeToken(address _to, uint256 _index) external onlyDev {
        Token storage token = tokens[_index];
        token.token = address(0);
        token.amount = 0;
        totalTokens = totalTokens - 1;
        IERC20(token.token).transfer(
            _to,
            IERC20(token.token).balanceOf(address(this))
        );
    }
    
    function changeDeveloper(address _developer) external onlyDev {
        developer = _developer;
    }
    
    function changeNumberOfETH(uint256 _numberOfETH) external onlyDev {
        numberOfETH = _numberOfETH;
    }
    
receive () external payable {}

fallback () external payable {}

    
}