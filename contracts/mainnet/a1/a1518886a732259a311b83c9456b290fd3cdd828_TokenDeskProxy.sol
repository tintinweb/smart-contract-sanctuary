pragma solidity 0.4.19;

contract TokenDeskProxySupport {
    function buyTokens(address sender_, address benefeciary_, uint256 tokenDeskBonus_) external payable;
}

contract TokenDeskProxy {
    TokenDeskProxySupport private tokenDeskProxySupport;
    uint256 public bonus;

    function TokenDeskProxy(address _tokenDeskProxySupport, uint256 _bonus) public {
        require(_tokenDeskProxySupport != address(0));
        tokenDeskProxySupport = TokenDeskProxySupport(_tokenDeskProxySupport);
        bonus = _bonus;
    }

    function () public payable {
        tokenDeskProxySupport.buyTokens.value(msg.value)(msg.sender, msg.sender, bonus);
    }
}