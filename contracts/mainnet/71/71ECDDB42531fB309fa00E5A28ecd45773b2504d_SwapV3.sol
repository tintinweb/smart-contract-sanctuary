/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
}

contract SwapV3 {

    // The WETH contract.
    IWETH private immutable WETH;
    address private immutable owner;

    constructor() {
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        owner = msg.sender;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    //only owner function
    modifier onlyOwner(){
        require(owner == msg.sender, "ONLY FOR OWNER");
        _;
    }

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount)
        external onlyOwner
    {
        if(amount == 0){
            amount = token.balanceOf(address(this));
        }
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH(uint256 amount)
        external onlyOwner
    {
        msg.sender.transfer(amount);
    }

    // Transfer ETH into this contract and wrap it into WETH.
    function depositETH()
        external
        payable
        onlyOwner
    {
        WETH.deposit{value: msg.value}();
    }

    struct Tokens{
        address token;
        uint256 amount;
        bytes data;
    }

    function xSwap(Tokens[] memory tokens, address _proxy) public 
                    onlyOwner {
        for(uint i = 0; i < tokens.length; i++){
            IERC20 ierc = IERC20(tokens[i].token);
            ierc.approve(_proxy, tokens[i].amount);
            (bool success, bytes memory data) = _proxy.call(tokens[i].data);
            // require(success, "SWAP_CALL_FAILED");
            emit Log(tokens[i]);
        }
    }

    event Log(Tokens tokens);

}