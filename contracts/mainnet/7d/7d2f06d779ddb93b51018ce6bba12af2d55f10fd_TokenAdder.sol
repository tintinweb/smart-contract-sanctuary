pragma solidity ^0.4.18;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
}

interface TokenConfigInterface {
    function admin() public returns(address);
    function claimAdmin() public;
    function transferAdminQuickly(address newAdmin) public;

    // network
    function listPairForReserve(address reserve, address src, address dest, bool add) public;
}


contract TokenAdder {
    TokenConfigInterface public network = TokenConfigInterface(0xD2D21FdeF0D054D2864ce328cc56D1238d6b239e);
    address public reserveKY;
    address public reservePR;

    address public ETH = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    ERC20 public ADX = ERC20(0x4470BB87d77b963A013DB939BE332f927f2b992e);
    ERC20 public AST = ERC20(0x27054b13b1B798B345b591a4d22e6562d47eA75a);
    ERC20 public RCN = ERC20(0xF970b8E36e23F7fC3FD752EeA86f8Be8D83375A6);
    ERC20 public RDN = ERC20(0x255Aa6DF07540Cb5d3d297f0D0D4D84cb52bc8e6);
    ERC20 public OMG = ERC20(0xd26114cd6EE289AccF82350c8d8487fedB8A0C07);
    ERC20 public KNC = ERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
    ERC20 public EOS = ERC20(0x86Fa049857E0209aa7D9e616F7eb3b3B78ECfdb0);
    ERC20 public SNT = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
    ERC20 public ELF = ERC20(0xbf2179859fc6D5BEE9Bf9158632Dc51678a4100e);
    ERC20 public POWR = ERC20(0x595832F8FC6BF59c85C527fEC3740A1b7a361269);
    ERC20 public MANA = ERC20(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
    ERC20 public BAT = ERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
    ERC20 public REQ = ERC20(0x8f8221aFbB33998d8584A2B05749bA73c37a938a);
    ERC20 public GTO = ERC20(0xC5bBaE50781Be1669306b9e001EFF57a2957b09d);
    ERC20 public ENG = ERC20(0xf0Ee6b27b759C9893Ce4f094b49ad28fd15A23e4);
    ERC20 public ZIL = ERC20(0x05f4a42e251f2d52b8ed15E9FEdAacFcEF1FAD27);
    ERC20 public LINK = ERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);

    address[] public reservePRNewTokens = [REQ, ENG, ADX, AST, RCN];
    address[] public reserveKYNewTokens = [ZIL, LINK, AST];

    function TokenAdder(TokenConfigInterface _network, address _reserveKY, address _reservePR) public {
        network = _network;
        reserveKY = _reserveKY;
        reservePR = _reservePR;
    }

    function listPairs() public {
        address orgAdmin = network.admin();
        network.claimAdmin();
        uint i;

        for (i = 0; i < reservePRNewTokens.length; i++) {
            network.listPairForReserve(reservePR, ETH, reservePRNewTokens[i], true);
            network.listPairForReserve(reservePR, reservePRNewTokens[i], ETH, true);
        }

        for (i = 0; i < reserveKYNewTokens.length; i++) {
            network.listPairForReserve(reserveKY, ETH, reserveKYNewTokens[i], true);
            network.listPairForReserve(reserveKY, reserveKYNewTokens[i], ETH, true);
        }

        network.transferAdminQuickly(orgAdmin);
        require(orgAdmin == network.admin());
    }
}