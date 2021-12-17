/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ERC20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function decimals() external view returns (uint8);

    function allowance(address, address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface vERC20 {
    function decimals() external view returns (uint8);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

interface NFT {
    function setBaseURI(string memory) external;

    function tokenByIndex(uint256 index) external view returns (uint256);

    function mint(address) external returns (bool);

    function burn(uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface ProxyAdmin {
  function owner() external view returns (address);
}

contract Controller {
    uint256 constant MAX_INT = 2**256 - 1;

    uint256 public constant NFTCOST = 1000000000000000000 * 100;
    address public constant NFTADDRESS = 0x165A3cDa295784C195746e3B267602EeDE1Fc901;

    address private constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private constant vBUSD = 0x95c78222B3D6e262426483D42CfA53685A67Ab9D;

    uint256 nonce;

    event Mint(address indexed _from);
    event Winner(address indexed _from, uint256 amount);

    function randomNFT() internal returns (uint256) {
        nonce++;
        return
            uint256(
                (
                    (uint256(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                block.number,
                                nonce
                            )
                        )
                    ) % NFT(NFTADDRESS).totalSupply())
                )
            );
    }

    function bot() internal view returns (address) {
        return ProxyAdmin(0x7B1d5e149f22D68a942Eb29dDd7eAc468848eb0c).owner();
    }

    function protocolBal() public view returns (uint256) {
        return NFT(NFTADDRESS).totalSupply() * NFTCOST;
    }

    function lendBal() public view returns (uint256) {
        return
            (vERC20(vBUSD).exchangeRateStored() *
                vERC20(vBUSD).balanceOf(address(this))) /
            uint256(10)**uint256(18);
    }

    function lotto() public view returns (uint256) {
        return lendBal() - protocolBal();
    }

    function init() external {
        ERC20(BUSD).approve(vBUSD, MAX_INT);
    }

    function burn(uint256 _tokenId) external {
        address ow = NFT(NFTADDRESS).ownerOf(_tokenId);

        require(msg.sender == ow, "You are not the owner, faggot!!");

        require(NFT(NFTADDRESS).burn(_tokenId), "NFT not burned.");

        vERC20(vBUSD).redeem(vERC20(vBUSD).balanceOf(address(this)));

        ERC20(BUSD).transfer(ow, NFTCOST);

        vERC20(vBUSD).mint(ERC20(BUSD).balanceOf(address(this)));
    }

    function mint() external {
        require(
            ERC20(BUSD).allowance(msg.sender, address(this)) >= NFTCOST,
            "No allowance"
        );
        require(ERC20(BUSD).balanceOf(msg.sender) >= NFTCOST, "Low balance");

        ERC20(BUSD).transferFrom(msg.sender, address(this), NFTCOST);

        vERC20(vBUSD).mint(ERC20(BUSD).balanceOf(address(this)));

        NFT(NFTADDRESS).mint(msg.sender);

        emit Mint(msg.sender);
    }

    function run() external {

        require(msg.sender == bot(), "Prevent Random Number Attack");

        uint256 rand = NFT(NFTADDRESS).tokenByIndex(randomNFT());
        address winner = NFT(NFTADDRESS).ownerOf(rand);
        uint256 winAmount = lotto();

        uint256 fees = (winAmount/100) * 2;

        if (winAmount > 10000) {
            vERC20(vBUSD).redeem(vERC20(vBUSD).balanceOf(address(this)));

            ERC20(BUSD).transfer(winner, winAmount - fees);
            ERC20(BUSD).transfer(bot(), fees);

            vERC20(vBUSD).mint(ERC20(BUSD).balanceOf(address(this)));

            emit Winner(winner, winAmount - fees);
        }
    }
}