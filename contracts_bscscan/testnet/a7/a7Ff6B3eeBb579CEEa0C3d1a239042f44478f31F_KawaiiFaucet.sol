interface IERC1155 {
    function mint(address to, uint256 tokenId, uint256 value) external;
}

interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

}

contract KawaiiFaucet {
    IERC1155 public nft1155;
    IBEP20 public bep20;
    constructor(IERC1155 _nft1155, IBEP20 _bep20) public {
        nft1155 = _nft1155;
        bep20 = _bep20;
    }
    function claimFaucet(address sender) public {
        bep20.transfer(sender, bep20.balanceOf(address(this)) / 1000000);
        nft1155.mint(sender, 205001, 10);
        for (uint256 i = 201001; i < 201012; i++) {
            nft1155.mint(sender, i, 2);
        }
        for (uint256 i = 206001; i < 206011; i++) {
            nft1155.mint(sender, i, 2);
        }
    }
}

