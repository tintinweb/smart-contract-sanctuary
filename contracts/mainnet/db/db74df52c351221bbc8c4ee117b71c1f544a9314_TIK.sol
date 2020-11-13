pragma solidity ^0.6.1;

contract TIK {
    address payable private manager;
    address payable private EOA;

    event Received(address sender, uint amount);
    event UniswapEthBoughtActual(uint256 amount);
    event UniswapTokenBoughtActual(uint256 amount);
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier restricted() {
        require(msg.sender == manager, "manager allowed only");
        _;
    }

    function setManagerContract(address payable _manager) public {
        manager = _manager;
    }
    function setEOA(address payable _eoa) public {
        EOA = _eoa;
    }
    constructor() public {
        manager = msg.sender;
    }
    function ethToToken(uint256 minTokens, uint256 deadline, address payable _uni) external restricted {
        Uniswap uni = Uniswap(_uni);
        uint256 ethBalance = address(this).balance;
        uint256 tokensBoughtActual = uni.ethToTokenSwapInput.value(ethBalance)({ min_tokens: minTokens, deadline: deadline });
        emit UniswapTokenBoughtActual(tokensBoughtActual);
    }

    function tokenToEth(uint256 tokensToSell, uint256 minEth, uint256 deadline, address payable _uni) external restricted {
        Uniswap uni = Uniswap(_uni);
        uint256 actualEthBought = uni.tokenToEthSwapInput({ tokens_sold: tokensToSell, min_eth: minEth, deadline: deadline });
        emit UniswapEthBoughtActual(actualEthBought);
    }

    function kill() external restricted {
        selfdestruct(EOA);
    }
    
    function approve(ERC20 _token, address payable _uni) external restricted {
        ERC20 token = ERC20(_token);
        token.approve(_uni, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }
    
    function drainToken(ERC20 _token) external restricted {
        ERC20 token = ERC20(_token);
        uint tokenBalance = token.balanceOf(address(this));
        token.transfer(EOA, tokenBalance);
    }
}
    abstract contract ERC20 {
        function balanceOf(address account) external virtual view returns (uint256);
        function transfer(address recipient, uint256 amount) external virtual returns (bool);
        function approve(address spender, uint tokens) public virtual returns (bool success);
    }
    
    abstract contract Uniswap {
        function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external virtual payable returns (uint256  tokens_bought);
        function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external virtual returns (uint256  eth_bought);
    }