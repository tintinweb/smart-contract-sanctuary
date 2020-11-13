pragma solidity ^0.6.0;

abstract contract UniswapExchangeInterface {
    function getEthToTokenInputPrice(uint256 eth_sold)
        external virtual
        view
        returns (uint256 tokens_bought);

    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external virtual
        view
        returns (uint256 eth_sold);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external virtual
        view
        returns (uint256 eth_bought);

    function getTokenToEthOutputPrice(uint256 eth_bought)
        external virtual
        view
        returns (uint256 tokens_sold);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external virtual returns (uint256 eth_bought);

    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient)
        external virtual
        payable
        returns (uint256 tokens_bought);

    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external virtual returns (uint256 tokens_bought);

    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external virtual payable returns (uint256  eth_sold);

    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external virtual returns (uint256  tokens_sold);

    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external virtual returns (uint256  tokens_sold);

}
