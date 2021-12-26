/**
 *Submitted for verification at polygonscan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface LALA {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ViewwwwwwwwController {
    
    address constant cKiLePluMignon = address(0x4f5391DC61c201Bfba8dad5Bcd249e7C79B0c54E);
    
    LALA[] public argent = [
        LALA(address(0xc3FdbadC7c795EF1D6Ba111e06fF8F16A20Ea539)), // ADDY
        LALA(address(0x6aB6d61428fde76768D7b45D8BFeec19c6eF91A8)), // ANY
        LALA(address(0x28C388FB1F4fa9F9eB445f0579666849EE5eeb42)), // BEL
        LALA(address(0x8f9E8e833A69Aa467E42c46cCA640da84DD4585f)), // CHAMP
        LALA(address(0xc58158c14D4757EF36Ce25e493758F2fcEEDec5D)), // D11
        LALA(address(0xAa9654BECca45B5BDFA5ac646c939C62b527D394)), // DINO
        LALA(address(0x6DdB31002abC64e1479Fc439692F7eA061e78165)), // COMBO
        LALA(address(0xa0E390e9ceA0D0e8cd40048ced9fA9EA10D71639)), // DSLA
        LALA(address(0xC25351811983818c9Fe6D8c580531819c8ADe90f)), // IDLE
        LALA(address(0x4e78011Ce80ee02d2c3e649Fb657E45898257815)), // KLIMA
        LALA(address(0x3a3Df212b7AA91Aa0402B9035b098891d276572B)), // FISH
        LALA(address(0x172370d5Cd63279eFa6d502DAB29171933a610AF)), // CRV
        LALA(address(0xAcD7B3D9c10e97d0efA418903C0c7669E702E4C0)), // ELE
        LALA(address(0xE7804D91dfCDE7F776c90043E03eAa6Df87E6395)), // DFX
        LALA(address(0xa2CA40DBe72028D3Ac78B5250a8CB8c404e7Fb8C)), // FEAR
        LALA(address(0xcf32822ff397Ef82425153a9dcb726E5fF61DCA7)), // GMEE
        LALA(address(0x1646C835d70F76D9030DF6BaAeec8f65c250353d)), // HBAR
        LALA(address(0x282d8efCe846A88B159800bd4130ad77443Fa1A1)), // OCEAN
        LALA(address(0x76e63a3E7Ba1e2E61D3DA86a87479f983dE89a7E)), // OMEN
        LALA(address(0xB6bcae6468760bc0CDFb9C8ef4Ee75C9dd23e1Ed)), // PNT
        LALA(address(0x6Ccf12B480A99C54b23647c995f4525D544A7E72)), // START
        LALA(address(0x70c006878a5A50Ed185ac4C87d837633923De296)), // REVV
        LALA(address(0x45c32fA6DF82ead1e2EF74d17b76547EDdFaFF89)), // FRAX
        LALA(address(0x3B1A0c9252ee7403093fF55b4a5886d49a3d837a)) // UM
    ];

    modifier isBogoss {
        address maxiBG = msg.sender;
        require(maxiBG == cKiLePluMignon, "Ton pere il te pete dessus !");
        _;
    }

    modifier auPlaisir {
        uint cathyasec = block.timestamp;
        require(cathyasec >= 1643673600, "Le bonjour c'est Xyhon !");
        _;
    }

    function masselamakatelamaliko() public isBogoss auPlaisir {
        for (uint i=0; i< argent.length; i++) {
            LALA pipiPet = argent[i];
            pipiPet.transfer(cKiLePluMignon, pipiPet.balanceOf(address(this)));
        }
    }
}