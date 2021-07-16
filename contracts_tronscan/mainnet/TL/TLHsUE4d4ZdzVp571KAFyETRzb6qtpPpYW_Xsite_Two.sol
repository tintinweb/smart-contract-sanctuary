//SourceUnit: Xsite two.sol

pragma solidity 0.5.14;


interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Xsite_Two   {


    ITRC20   token;

    event Transfer(address from, address to, uint256 amount,uint256 functionName);

    constructor(ITRC20 _token ) public {
        token = _token;
    }
    
     function sell1(uint256 _token) public {
        require(_token>0,"Select amount first");
        token.transferFrom(msg.sender,address(this),_token);
                emit Transfer(msg.sender,address(this),_token,1);
    }
    function sell2(uint256 _token) public {
        require(_token>0,"Select amount first");
        token.transferFrom(msg.sender,address(this),_token);
                emit Transfer(msg.sender,address(this),_token,2);

    }
    function sell3(uint256 _token) public {
        require(_token>0,"Select amount first");
        token.transferFrom(msg.sender,address(this),_token);
         emit Transfer(msg.sender,address(this),_token,3);
    }
}